#!/usr/bin/env python3
"""UserPromptSubmit hook: measure prompt signals, and gate ambiguous dev work.

Two jobs, one file — deliberately, because both need the same signal extraction
and duplicating those regexes would let the log and the gate drift apart.

  1. INSTRUMENT (unchanged): one JSONL record per prompt.
  2. GATE (added 2026-09-01): when the prompt looks like development work AND
     carries an ambiguity signal, inject additionalContext telling the model to
     resolve the fork — from code/memory if it can, with one AskUserQuestion
     round if it cannot. Never blocks: exit 0 always, prompt never erased.

The original spec kept the gate out of scope so the base rate stayed
measurable. That measurement is over — 97 prompts over 16h gave 26 dev-ish
(27%), 16 of them ambiguous (61%), which is the number the gate was waiting on.
The `nudged` field now records whether the gate fired, so post-gate behaviour
stays measurable in the same log.

Safety contract:
  - NON-BLOCKING: always exit 0. Every failure path is swallowed. A crash here
    must never cost the user their prompt.
  - Nothing but the gate JSON is ever written to stdout.
  - No full prompt text: first 120 chars, secret-redacted. No hash of the rest.

Disable: PROMPT_INTAKE_DISABLE=1 (whole hook) · INTERVIEW_GATE_DISABLE=1 (gate only)
Log dir: PROMPT_INTAKE_LOG_DIR (default ~/.claude/logs/prompt-intake)
"""

import json
import os
import re
import sys
import time

DEFAULT_LOG_DIR = os.path.expanduser("~/.claude/logs/prompt-intake")
HEAD_CHARS = 120

# Signal extraction is capped, for latency not for storage. A pasted log dump
# is worthless as signal. The cap is cheap insurance rather than a fix for a
# live problem: with the current tokenised matching, lifting it measures
# 14-73ms on 100-400KB. (An earlier whole-string path alternation took 10.5s on
# 100KB — that quadratic backtracking is what the tokenised design removed.)
# prompt_len still records the true length, so oversized prompts stay
# identifiable in the readout.
ANALYZE_LIMIT = 20_000
MAX_TOKEN_LEN = 200

# Orca prepends worktree metadata to a session's first prompt as plain prompt
# text (documented in linear-banner-autostart.sh). Left in place it inflates
# specifics_count with URLs, issue ids and digits the user never typed, which
# would systematically deflate the base-rate numerator.
BANNER_RE = re.compile(
    r"\A[ \t]*Linked Linear issue:[ \t]*\S+[ \t]*\r?\n"
    r"(?:[ \t]*https?://\S+[ \t]*\r?\n)?"
    r"(?:[ \t]*\r?\n)*"
)

# First match wins — order is the priority (spec REQ-F-003).
#
# build/change deliberately outrank fix. The fix dictionary holds generic nouns
# (에러 · 오류 · error), so putting it first classified "에러 핸들링 추가해줘"
# as fix — dropping exactly the zero-specifics build requests the base rate is
# meant to count. An explicit add/change verb beats a mere mention of errors.
VERB_PATTERNS = [
    ("build", r"추가|만들|구현|생성|붙여|개발|세팅|도입|"
              r"\badd\b|\bbuild\b|\bimplement\b|\bcreate\b|\bscaffold\b"),
    ("change", r"바꿔|바꾸|변경|수정|개편|리뉴얼|고도화|옮겨|교체|정리해|"
               r"\bchange\b|\bupdate\b|\brefactor\b|\brename\b|\bmigrate\b"),
    ("fix", r"고쳐|고쳤|안\s?돼|안\s?되|에러|버그|오류|깨[졌지]|실패|크래시|먹통|"
            r"\bfix\b|\berror\b|\bbug\b|\bbroken\b|\bcrash"),
    ("explain", r"설명|알려줘|뭐야|무엇|어떻게\s?동작|왜\s|"
                r"\bexplain\b|\bwhat\s+is\b|\bhow\s+does\b|\bwhy\b"),
]

SCOPE_RE = re.compile(r"전부|전반|모두|일괄|싹\s|전체적|통째")
VAGUE_RE = re.compile(r"알아서|어떻게든|제대로|적당히|좀\s|싶은데|같은\s?거|뭔가")

# Path and identifier detection runs per whitespace token, never across the
# whole string: an alternation like [\w.-]+/ backtracks quadratically when the
# separator is absent, which is exactly what a long paste looks like.
PATH_TOKEN_RE = re.compile(
    r"\A(?:[\w.-]+/[\w./-]*"
    r"|[\w-]+\.(?:py|sh|js|ts|tsx|jsx|md|json|ya?ml|toml|txt|sql|css|html))\Z"
)
IDENT_TOKEN_RE = re.compile(r"\A[A-Z]{2,}[-_]\w+\Z")
NUMBER_RE = re.compile(r"(?<![\w-])\d+(?![\w-])")
ERROR_RE = re.compile(r"\b(?:Error|Exception|Traceback|ERR_[A-Z_]+)\b|\b[45]\d{2}\b")
BACKTICK_RE = re.compile(r"`[^`]+`")

# Redaction runs before anything is persisted. Order matters: the generic
# long-token rule is last so the specific prefixes keep their shape in the log.
#
# The catch-all covers the base64 alphabet (/ and +), without which the
# canonical AWS secret key wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY passed
# through untouched. The three lookaheads demand mixed case AND a digit so that
# ordinary long developer tokens survive — a 40-char git SHA (lowercase+digits)
# and a SCREAMING_SNAKE constant (uppercase only) stay readable, which matters
# because prompt_head is the only material the 5-15% labelling pass will have.
SECRET_RES = [
    re.compile(r"sk-[A-Za-z0-9_-]{8,}"),
    re.compile(r"ghp_[A-Za-z0-9]{16,}"),
    re.compile(r"admap_[A-Za-z0-9]{16,}"),
    re.compile(r"AKIA[0-9A-Z]{12,}"),
    re.compile(r"(?i)bearer\s+[A-Za-z0-9._-]{16,}"),
    re.compile(
        r"(?<![\w/+-])"
        r"(?=[A-Za-z0-9_/+-]*[a-z])(?=[A-Za-z0-9_/+-]*[A-Z])(?=[A-Za-z0-9_/+-]*\d)"
        r"[A-Za-z0-9_/+-]{40,}={0,2}(?![\w/+-])"
    ),
]
# Secrets that begin inside the stored head but end past it would be sliced
# below their pattern's minimum length and survive as raw fragments, so
# redaction runs over a wider window and the truncation happens after.
REDACT_SLACK = 256


def redact(text):
    for pattern in SECRET_RES:
        text = pattern.sub("[REDACTED]", text)
    return text


def strip_banner(prompt):
    stripped = BANNER_RE.sub("", prompt, count=1)
    return stripped, stripped != prompt


def classify_verb(text):
    for name, pattern in VERB_PATTERNS:
        if re.search(pattern, text):
            return name
    return "none"


def extract(prompt):
    """Raw signals only — no verdict, no label. See module docstring."""
    text, banner_stripped = strip_banner(prompt)
    full_len = len(text)
    scanned = text[:ANALYZE_LIMIT]

    tokens = [t for t in scanned.split() if len(t) <= MAX_TOKEN_LEN]
    paths = [t for t in tokens if PATH_TOKEN_RE.match(t)]
    idents = [t for t in tokens if IDENT_TOKEN_RE.match(t)]
    numbers = NUMBER_RE.findall(scanned)
    errors = ERROR_RE.findall(scanned)
    backticks = BACKTICK_RE.findall(scanned)

    return {
        "prompt_len": full_len,
        "prompt_head": redact(text[:HEAD_CHARS + REDACT_SLACK])[:HEAD_CHARS],
        "banner_stripped": banner_stripped,
        "verb_class": classify_verb(scanned),
        "specifics_count": len(paths) + len(numbers) + len(errors)
        + len(backticks) + len(idents),
        "has_path": bool(paths),
        "has_number": bool(numbers),
        "has_error_text": bool(errors),
        "has_backtick": bool(backticks),
        "scope_word_hits": len(SCOPE_RE.findall(scanned)),
        "vague_word_hits": len(VAGUE_RE.findall(scanned)),
        "is_question": "?" in scanned or bool(re.search(r"까요|나요|인가|건가", scanned)),
        # Slash commands often arrive on a line after the Orca banner, so
        # anchoring to the start of the whole prompt misses them.
        "is_slash_command": any(
            line.lstrip().startswith("/") for line in scanned.splitlines()
        ),
    }


# ── gate ──────────────────────────────────────────────────────────────────────
# 발동 조건은 전부 위에서 이미 뽑은 신호다. 새 정규식을 만들지 않는다 — 로그가 재는 것과
# 게이트가 보는 것이 같아야 나중에 "게이트가 실제로 무엇에 반응했는가"를 로그로 되짚을 수 있다.
DEV_VERBS = ("build", "change", "fix")

GATE_TEXT = """[인터뷰 게이트] 이 요청은 개발 작업으로 보이는데 대상·범위를 특정할 신호가 약하다({why}).

비용이 큰 작업을 시작하기 전에:
1. 요청을 스스로 재진술하고 코드·기존 문서·메모리로 해소되는지 **먼저** 확인한다.
   해소되면 그대로 진행하고 이 블록을 언급하지 마라.
2. 그래도 결과가 갈리는 갈래가 남으면, **그 갈래만** AskUserQuestion 한 번으로 확정한 뒤
   착수한다. 권장안을 첫 옵션에 두고 왜 권장인지 적는다. 갈래가 3개 이상이거나 서로
   의존하면 단발 질문 대신 인터뷰 스킬 — 선택은 `~/.claude/rules-ondemand/interview-routing.md`.
3. 되돌리기 어려운 작업(배포·삭제·자격 변경·서비스 중단)이면 착수 전에 승인 패킷을 제시한다.

질문을 위한 질문은 하지 마라 — 답이 작업을 바꾸지 않는 질문은 묻지 않는다."""


def gate_reason(record):
    """Why the gate fired, or None if it should not. Order = report priority."""
    if os.environ.get("INTERVIEW_GATE_DISABLE") == "1":
        return None
    # 서브에이전트의 프롬프트는 사람이 쓴 것이 아니다 — 물어볼 상대가 없다.
    if record.get("agent_id") or record.get("agent_type"):
        return None
    # 슬래시 커맨드는 그 자체가 명시적 지시다.
    if record.get("is_slash_command"):
        return None
    if record.get("verb_class") not in DEV_VERBS:
        return None
    reasons = []
    if record.get("specifics_count", 0) == 0:
        reasons.append("파일·경로·식별자 등 구체적 참조 0건")
    if record.get("vague_word_hits", 0):
        reasons.append("모호 표현 %d건" % record["vague_word_hits"])
    if record.get("scope_word_hits", 0):
        reasons.append("전체 범위 표현 %d건" % record["scope_word_hits"])
    return " · ".join(reasons) or None


def emit_gate(reason):
    sys.stdout.write(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "UserPromptSubmit",
            "additionalContext": GATE_TEXT.format(why=reason),
        }
    }))


def append_record(log_dir, record):
    os.makedirs(log_dir, mode=0o700, exist_ok=True)
    try:
        os.chmod(log_dir, 0o700)
    except OSError:
        pass  # pre-existing dir we do not own the mode of; not fatal
    path = os.path.join(log_dir, "records.jsonl")
    # open(path, "a") would create 0644 under the usual umask — the mode has to
    # be requested explicitly for the 0600 contract to hold.
    fd = os.open(path, os.O_WRONLY | os.O_APPEND | os.O_CREAT, 0o600)
    with os.fdopen(fd, "a") as f:
        f.write(json.dumps(record, ensure_ascii=False) + "\n")


def main():
    if os.environ.get("PROMPT_INTAKE_DISABLE") == "1":
        return

    raw = sys.stdin.read()
    payload = json.loads(raw)
    prompt = payload.get("prompt") or ""

    record = {
        "ts": int(time.time()),
        "session_id": payload.get("session_id"),
        "cwd": payload.get("cwd"),
        # Present when the prompt originates from a subagent rather than a
        # person. Whether UserPromptSubmit fires on those paths at all is
        # undocumented — recording it lets the 4-week readout tell us.
        "agent_id": payload.get("agent_id"),
        "agent_type": payload.get("agent_type"),
    }
    record.update(extract(prompt))

    reason = gate_reason(record)
    record["nudged"] = bool(reason)

    # 로그를 먼저 쓴다. 게이트 출력이 실패해도 측정은 남는다.
    append_record(os.environ.get("PROMPT_INTAKE_LOG_DIR") or DEFAULT_LOG_DIR, record)

    if reason:
        emit_gate(reason)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        # A measurement hook must never interfere with the user's prompt.
        pass
    sys.exit(0)
