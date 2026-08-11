#!/usr/bin/env bash
# PostToolUse hook (Bash): Nudge to VERIFY the linked issue's acceptance criteria
# (and tick the checkboxes only after verifying) at the PR boundary. NON-BLOCKING —
# exit 0 + stderr only (guard-linear-state-nudge pattern).
#
# Why: recurring miss (SUR-26, REV-13) — acceptance-criteria checkboxes get left
# unchecked / unverified while the issue is pushed to PR or flipped to Done, so an
# unmet criterion rides through as false completion. A hook CANNOT decide whether a
# criterion is actually met (that is contextual judgment — did the test pass? did
# the runtime/visual check happen?), so this only REMINDS at the PR boundary. It
# never blocks, never queries the tracker API (local git only, ≤5s) — matching
# every other guard's contract. Pairs with global CLAUDE.md §검증 (수용 기준 = 완료 게이트).
#
# Fires when the just-run command was a PR-stage boundary:
#   - gh pr create          → opening the PR        (verify criteria before review?)
#   - gh pr merge           → merging / closing      (all [AUTO] green + [HUMAN] walked?)
# and an issue id (e.g. ADT-196) is detectable in the branch name or command.
#
# Config:
#   GUARD_ACCEPTANCE_NUDGE_DISABLE=1   — turn off
#   GUARD_LINEAR_ISSUE_RE=<regex>      — issue-id pattern (shared default [A-Za-z]{2,10}-[0-9]+)

[ "${GUARD_ACCEPTANCE_NUDGE_DISABLE:-0}" = "1" ] && exit 0

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | python3 -c 'import json,sys
try:
    p=json.loads(sys.stdin.read() or "{}")
    print((p.get("tool_input") or {}).get("command") or "")
except Exception:
    print("")
' 2>/dev/null)

[ -z "$CMD" ] && exit 0

# Use the real system grep, not a wrapper alias (some envs shim grep to BRE).
GREP=/usr/bin/grep
[ -x "$GREP" ] || GREP=grep

# Boundary detection — quotes blanked so a `gh pr list --search="pr create"` style
# command does not false-trigger (same technique as guard-linear-state-nudge).
SANITIZED=$(printf '%s' "$CMD" | sed -E "s/'[^']*'/''/g" | sed -E 's/"[^"]*"/""/g')

BOUNDARY=""
if echo "$SANITIZED" | $GREP -qE 'gh[[:space:]]+pr[[:space:]]+create'; then
  BOUNDARY="pr_create"
elif echo "$SANITIZED" | $GREP -qE 'gh[[:space:]]+pr[[:space:]]+merge'; then
  BOUNDARY="merge"
fi
[ -z "$BOUNDARY" ] && exit 0

# Bounded interval — BSD grep rejects open-ended {2,}. Keep as plain assignment,
# not ${VAR:-default} — a `}` inside the default closes the expansion early.
ISSUE_RE="$GUARD_LINEAR_ISSUE_RE"
[ -z "$ISSUE_RE" ] && ISSUE_RE='[A-Za-z]{2,10}-[0-9]+'

# Primary signal: current branch name (deliberate, e.g. feat/adt-196-...).
# Fallback: the command text. Branch preferred (fewer incidental matches).
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
ISSUE=$(printf '%s' "$BRANCH" | $GREP -oiE "$ISSUE_RE" | head -1)
[ -z "$ISSUE" ] && ISSUE=$(printf '%s' "$CMD" | $GREP -oiE "$ISSUE_RE" | head -1)

[ -z "$ISSUE" ] && exit 0

ISSUE_UC=$(printf '%s' "$ISSUE" | tr '[:lower:]' '[:upper:]')

if [ "$BOUNDARY" = "pr_create" ]; then
  echo "[guard] NUDGE: $ISSUE_UC PR 생성 — 수용 기준 검증했나? (CLAUDE.md §검증)" >&2
  echo "각 항목을 관찰 가능하게 검증 후에만 체크: [AUTO]는 테스트, [HUMAN]은 런타임/시각 확인." >&2
  echo "검증 없이 [x] 금지(거짓 완료). 미검증 [HUMAN] 있으면 PR/Done 보류하고 사용자 안내." >&2
else
  echo "[guard] NUDGE: $ISSUE_UC 머지 — 수용 기준 100% 검증·체크됐나? (CLAUDE.md §검증)" >&2
  echo "모든 [AUTO] green AND 모든 [HUMAN] 사용자와 walk(pass/명시 수용)여야 Done." >&2
  echo "미검증·미체크 항목이 남았으면 Done 보류 — 거짓 완료가 회귀로 새어나간다(SUR-26)." >&2
fi

exit 0
