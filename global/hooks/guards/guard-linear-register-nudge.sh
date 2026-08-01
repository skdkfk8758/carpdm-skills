#!/usr/bin/env bash
# PreToolUse hook (mcp__linear__save_issue): Nudge to route Linear issue CREATION
# through the `linear-register` skill. NON-BLOCKING — exit 0 + stderr only
# (guard-linear-state-nudge pattern).
#
# Why: 이슈 등록은 linear-register 스킬(팀 라우팅 + 확인 게이트 + 적응형 추천 +
# 체인 전방 가이드)을 경유해야 한다. 그러나 save_issue 를 직접 호출하면 그 절차가
# 통째로 빠진다. 하드 블록은 불가 — linear-register 자신이 save_issue 를 호출하므로
# 차단하면 스킬도 깨진다. 그래서 생성 시점에 REMIND 만 한다(이미 스킬 경유 중이면 무시).
#
# Fires ONLY on CREATE: save_issue with NO `id` (id 있으면 update → state-nudge 담당).
#
# Config:
#   GUARD_LINEAR_REGISTER_NUDGE_DISABLE=1   — turn off

[ "${GUARD_LINEAR_REGISTER_NUDGE_DISABLE:-0}" = "1" ] && exit 0

INPUT=$(cat)

# Creation = save_issue without `id`. Inspect tool_input.id; if present → update → skip.
IS_CREATE=$(printf '%s' "$INPUT" | python3 -c 'import json,sys
try:
    p=json.loads(sys.stdin.read() or "{}")
    ti=p.get("tool_input") or {}
    print("0" if ti.get("id") else "1")
except Exception:
    print("0")
' 2>/dev/null)

[ "$IS_CREATE" = "1" ] || exit 0

echo "[guard] NUDGE: Linear 이슈 생성 감지 — linear-register 스킬 경유했나?" >&2
echo "필수 절차: ① repo→팀 라우팅(linear-repo-map) ② 생성 전 확인 게이트" >&2
echo "③ 이슈마다 '## 추천' 섹션 ④ 체인이면 관계+전방 kickoff 프롬프트. (이미 경유 중이면 무시)" >&2

exit 0
