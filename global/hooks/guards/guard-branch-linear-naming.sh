#!/usr/bin/env bash
# PreToolUse hook (Bash): Nudge to include a tracker issue-id in NEW branch names
# so Linear (or any tracker) auto-links the branch/PR. NON-BLOCKING — exit 0 +
# stderr only (guard-linear-state-nudge pattern). Never blocks the command.
#
# Why: recurring miss — a branch named `feat/admap-layer` (no issue-id) does not
# auto-link to its tracker issue, so the issue stays in Backlog and the PR is
# never attached. A name carrying the id (`feat/adt-182-…` or `carpdm/adt-182-…`)
# lets the integration match it. The hook only REMINDS at branch-creation time;
# the human picks the final name.
#
# Fires when the command CREATES a branch:
#   git checkout -b NAME | git switch -c NAME | git branch NAME
#   git worktree add … -b NAME …
# and NAME lacks an issue-id pattern.
#
# Config:
#   GUARD_BRANCH_LINEAR_DISABLE=1     — turn off
#   GUARD_LINEAR_ISSUE_RE=<regex>     — issue-id pattern (shared w/ state-nudge)

[ "${GUARD_BRANCH_LINEAR_DISABLE:-0}" = "1" ] && exit 0

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

# Only consider branch-creating git commands.
echo "$CMD" | $GREP -qE 'git[[:space:]]+(checkout[[:space:]]+-b|switch[[:space:]]+-c|branch[[:space:]]+[^-]|worktree[[:space:]]+add)' || exit 0

# Extract the new branch name. Try each creation form; first hit wins.
NAME=$(printf '%s' "$CMD" | $GREP -oE '(checkout[[:space:]]+-b|switch[[:space:]]+-c)[[:space:]]+[^[:space:]]+' | head -1 | awk '{print $NF}')
[ -z "$NAME" ] && NAME=$(printf '%s' "$CMD" | $GREP -oE 'worktree[[:space:]]+add([[:space:]]+[^[:space:]]+)*[[:space:]]+-b[[:space:]]+[^[:space:]]+' | $GREP -oE '\-b[[:space:]]+[^[:space:]]+' | head -1 | awk '{print $NF}')
[ -z "$NAME" ] && NAME=$(printf '%s' "$CMD" | $GREP -oE 'git[[:space:]]+branch[[:space:]]+[^-][^[:space:]]*' | head -1 | awk '{print $NF}')

[ -z "$NAME" ] && exit 0

ISSUE_RE="$GUARD_LINEAR_ISSUE_RE"
[ -z "$ISSUE_RE" ] && ISSUE_RE='[A-Za-z]{2,10}-[0-9]+'

# If the name already carries an issue-id, stay silent.
printf '%s' "$NAME" | $GREP -qiE "$ISSUE_RE" && exit 0

echo "[guard] NUDGE: 새 브랜치 '$NAME' 에 트래커 이슈ID 가 없다 — Linear 자동연동이 안 걸린다." >&2
echo "이슈ID 포함 권장: '<type>/<issue-id>-<topic>' (예: feat/adt-182-…) 또는 Linear 제안 '<user>/<issue-id>-<topic>'." >&2
echo "이슈가 없는 작업이면 무시. (GUARD_BRANCH_LINEAR_DISABLE=1 로 끔)" >&2

exit 0
