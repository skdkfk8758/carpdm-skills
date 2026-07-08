#!/usr/bin/env bash
# PostToolUse hook (Bash): Warn when a verification-ish command swallows its
# exit code — the false-green trap. NON-BLOCKING — exit 0 + stderr only
# (guard-linear-state-nudge pattern).
#
# Why: measured incident — a `|| echo` after a test command swallowed a failing
# exit code and produced a false-green verify that only user pushback caught.
# A green gate you cannot trust is worse than no gate. This hook cannot know
# whether the swallow was intentional, so it only REMINDS right after such a
# command ran: re-run the check strictly before trusting the result.
#
# Fires when the just-run command BOTH:
#   1. looks like a verification (test / vitest / jest / pytest / tsc /
#      typecheck / lint / eslint / build / verify.sh), AND
#   2. contains an exit-code swallow: `|| echo`, `|| true`, `|| :`
#
# Config:
#   GUARD_VERIFY_SWALLOW_DISABLE=1  — turn off

[ "${GUARD_VERIFY_SWALLOW_DISABLE:-0}" = "1" ] && exit 0

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | python3 -c 'import json,sys
try:
    p=json.loads(sys.stdin.read() or "{}")
    print((p.get("tool_input") or {}).get("command") or "")
except Exception:
    print("")
' 2>/dev/null)

[ -z "$CMD" ] && exit 0

GREP=/usr/bin/grep
[ -x "$GREP" ] || GREP=grep

# Blank out quoted strings so `echo "pnpm test || true"` etc. does not
# false-trigger (same technique as guard-destructive-cmd).
SANITIZED=$(printf '%s' "$CMD" | sed -E "s/'[^']*'/''/g" | sed -E 's/"[^"]*"/""/g')

# 1. Verification-shaped command?
echo "$SANITIZED" | $GREP -qE '(pnpm|npm|yarn)[[:space:]]+(run[[:space:]]+)?(test|typecheck|lint|build)|vitest|jest|pytest|tsc([[:space:]]|$)|eslint|verify\.sh' || exit 0

# 2. Exit-code swallow present?
echo "$SANITIZED" | $GREP -qE '\|\|[[:space:]]*(echo|true|:)([[:space:]]|$|;)' || exit 0

cat >&2 <<'EOF'
[guard-verify-swallow] 검증 명령이 exit code 를 삼키고 있다 (`|| echo`/`|| true`/`|| :`).
실패해도 green 으로 보이는 false-green 트랩 — 이 출력만 보고 "통과"로 판정하지 말 것.
→ swallow 없이 strict 로 재실행해 exit code 를 직접 확인한 뒤에만 green 선언.
(의도된 swallow 면 무시. 끄기: GUARD_VERIFY_SWALLOW_DISABLE=1)
EOF
exit 0
