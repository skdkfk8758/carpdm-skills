#!/usr/bin/env bash
# PreToolUse hook (Bash): Nudge to include a tracker issue-id in NEW branch names
# so Linear (or any tracker) auto-links the branch/PR. NON-BLOCKING — exit 0 +
# additionalContext (lib-emit-context.sh), one fire per (session, name).
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
#   GUARD_LINEAR_ISSUE_RE=<regex>     — issue-id pattern (shared w/ state-nudge, see lib-issue-id.sh)

[ "${GUARD_BRANCH_LINEAR_DISABLE:-0}" = "1" ] && exit 0

INPUT=$(cat)
# Heredoc bodies are dropped: a commit message or script that merely mentions
# `git branch foo` is text, not a branch being created.
CMD=$(printf '%s' "$INPUT" | python3 -c 'import json, re, sys
try:
    p = json.loads(sys.stdin.read() or "{}")
    cmd = (p.get("tool_input") or {}).get("command") or ""
except Exception:
    cmd = ""
out, ends = [], []
for line in cmd.split("\n"):
    if ends:
        if line.strip() == ends[0]:
            ends.pop(0)
        continue
    out.append(line)
    ends += [m.group(2) for m in re.finditer(r"(?<!<)<<(?!<)-?\s*([\x27\x22]?)([A-Za-z_][A-Za-z0-9_]*)\1", line)]
print("\n".join(out))
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

. "$(dirname "${BASH_SOURCE[0]}")/lib-issue-id.sh"

# If the name already carries an issue-id, stay silent.
[ -n "$(printf '%s' "$NAME" | issue_id_first)" ] && exit 0

. "$(dirname "${BASH_SOURCE[0]}")/lib-emit-context.sh"
once_per "branch-naming|$(hook_sid "$INPUT")|$NAME" || exit 0

{
echo "[guard] NUDGE: 새 브랜치 '$NAME' 에 트래커 이슈ID 가 없다 — Linear 자동연동이 안 걸린다."
echo "이슈ID 포함 권장: '<type>/<issue-id>-<topic>' (예: feat/adt-182-…) 또는 Linear 제안 '<user>/<issue-id>-<topic>'."
echo "이슈가 없는 작업이면 무시. (GUARD_BRANCH_LINEAR_DISABLE=1 로 끔)"
} | emit_context PreToolUse

exit 0
