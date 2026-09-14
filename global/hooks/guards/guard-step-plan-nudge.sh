#!/usr/bin/env bash
# UserPromptSubmit hook — advisory. When a prompt looks like multi-step work
# (long, an enumerated list, or a sweeping keyword), remind the model to put a
# 3-7 step plan on screen and get it approved BEFORE touching files, so it does
# not collide with guard-step-scope.sh mid-run.
#
# Fires at most once per session (once_per). Silent otherwise.
#
#   Disable: GUARD_STEP_DISABLE=1

INPUT=$(cat)

[ "${GUARD_STEP_DISABLE:-0}" = "1" ] && exit 0

MATCH=$(printf '%s' "$INPUT" | python3 -c '
import json, re, sys
try:
    d = json.load(sys.stdin)
except Exception:
    d = {}
p = (d.get("prompt") if isinstance(d, dict) else "") or ""
hit = (
    len(p) > 300
    or len(re.findall(r"\n\s*\d+\.", p)) >= 2
    or re.search(r"리뉴얼|리팩토링|전부|모두|마이그레이션|refactor|migrate|all of", p) is not None
)
sys.stdout.write("1" if hit else "0")
' 2>/dev/null)

[ "$MATCH" = "1" ] || exit 0

. "$(dirname "${BASH_SOURCE[0]}")/lib-emit-context.sh"
SID=$(hook_sid "$INPUT")
once_per "step-plan-$SID" || exit 0

printf '%s\n' "[step-plan] 복수 스텝 작업 신호. 착수 전에 3~7개 스텝 계획(스텝당 파일 ≤3·커밋 1)을 한 화면에 제시하고 AskUserQuestion 으로 승인받은 뒤 스텝 1만 실행하라. 각 스텝 끝에 §A 보고 + 다음 스텝 확인. 상세: ~/.claude/rules-ondemand/step-cadence.md" \
  | emit_context UserPromptSubmit

exit 0
