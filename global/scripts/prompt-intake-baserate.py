#!/usr/bin/env python3
"""Read the prompt-intake log and answer the one question the hook exists for:

    how often does a build/change request arrive with zero concrete referents?

That percentage — the base rate — decides the project's fate without needing
any ground-truth labels (docs/specs/prompt-intake-classifier.md §5):

    < 2%   the problem is rare        → retire the hook
    > 30%  the signal is too blunt    → a nudge would fire constantly; redesign
    5-15%  worth knowing if it's right → only now pay for manual labelling

Correction detection lives here rather than in the hook on purpose: several
sessions and background jobs append to one shared log, so "the previous line"
is usually somebody else's prompt. Grouping by session_id after the fact is
both correct and simpler than keeping per-session state at write time.

Log dir: PROMPT_INTAKE_LOG_DIR (default ~/.claude/logs/prompt-intake)
"""

import json
import os
import re
import sys
from collections import defaultdict

DEFAULT_LOG_DIR = os.path.expanduser("~/.claude/logs/prompt-intake")
BASE_RATE_VERBS = {"build", "change"}
CORRECTION_WINDOW_SEC = 120
CORRECTION_MAX_LEN = 60
CORRECTION_RE = re.compile(r"아니|그게\s?아니|다시|말고|취소|아까")


def load(path):
    rows = []
    try:
        with open(path) as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    rows.append(json.loads(line))
                except json.JSONDecodeError:
                    continue  # a torn line must not sink the whole readout
    except FileNotFoundError:
        pass
    return rows


def count_corrections(rows):
    by_session = defaultdict(list)
    for r in rows:
        by_session[r.get("session_id")].append(r)

    total = 0
    for session_rows in by_session.values():
        session_rows.sort(key=lambda r: r.get("ts") or 0)
        for prev, cur in zip(session_rows, session_rows[1:]):
            gap = (cur.get("ts") or 0) - (prev.get("ts") or 0)
            if gap > CORRECTION_WINDOW_SEC:
                continue
            if (cur.get("prompt_len") or 0) >= CORRECTION_MAX_LEN:
                continue
            if CORRECTION_RE.search(cur.get("prompt_head") or ""):
                total += 1
    return total


def verdict(pct):
    if pct < 2:
        return "< 2% — 문제가 드물다. 훅 폐기 권장(유지비 > 가치)."
    if pct > 30:
        return "> 30% — 신호가 너무 무디다. nudge 를 켜면 상시 발화. 휴리스틱 재설계."
    if 5 <= pct <= 15:
        return "5~15% — 여기서만 정확도가 의미를 갖는다. 수동 라벨 20~30건 지불 구간."
    return "2~5% / 15~30% — 경계 구간. 표본을 더 모으고 재판정 권장."


def main():
    log_dir = os.environ.get("PROMPT_INTAKE_LOG_DIR") or DEFAULT_LOG_DIR
    rows = load(os.path.join(log_dir, "records.jsonl"))

    if not rows:
        print(f"샘플 없음 — {log_dir}/records.jsonl 에 레코드가 0건입니다.")
        return 0

    hits = [
        r for r in rows
        if r.get("verb_class") in BASE_RATE_VERBS
        and (r.get("specifics_count") or 0) == 0
    ]
    # Round once so the printed figure and the branch below cannot disagree:
    # 1.96% prints as "2.0%" but would otherwise reach the "<2% retire" branch.
    pct = round(len(hits) / len(rows) * 100, 1)

    span = ""
    stamps = [r["ts"] for r in rows if isinstance(r.get("ts"), int)]
    if stamps:
        days = (max(stamps) - min(stamps)) / 86400
        span = f" · 수집 기간 {days:.1f}일"

    print(f"base rate: {len(hits)}건 / 전체 {len(rows)}건 = {pct:.1f}%{span}")
    print(f"판정: {verdict(pct)}")
    print(f"정정 발화: {count_corrections(rows)}건 (같은 세션 {CORRECTION_WINDOW_SEC}초 내)")

    agent_rows = sum(1 for r in rows if r.get("agent_id"))
    if agent_rows:
        print(f"주의: agent 발 프롬프트 {agent_rows}건 포함 — 사람 base rate 는 이를 제외해야 한다.")

    by_verb = defaultdict(int)
    for r in rows:
        by_verb[r.get("verb_class") or "?"] += 1
    breakdown = " · ".join(f"{k} {v}" for k, v in sorted(by_verb.items()))
    print(f"verb_class 분포: {breakdown}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
