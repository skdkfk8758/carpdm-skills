#!/usr/bin/env bash
# PostToolUse hook (Bash): Nudge to transition the linked issue tracker state at
# work boundaries. NON-BLOCKING — exit 0 + additionalContext (lib-emit-context.sh),
# capped to one fire per (session, issue, boundary).
#
# Why: recurring miss — "code done" gets treated as "task done", skipping the
# tracker boundary transition (착수→In Progress, 머지+검증→Done). A hook cannot
# compute the CORRECT target state (that is contextual judgment), so this only
# REMINDS at the moment a boundary command runs. It never blocks, never queries
# the tracker API (local git only, ≤5s) — matching every other guard's contract.
#
# Fires when the just-run command was a boundary:
#   - branch create         → work started         (push -u + set In Progress?)
#   - git commit            → progress checkpoint  (set In Progress?)
#   - gh pr create          → PR opened            (set In Progress + attach PR link?)
#   - gh pr merge           → merge                 (verify done → Done?)
# and an issue id (e.g. ADT-196) is detectable in the branch name or commit -m.
#
# The branch-create boundary exists because a LOCAL branch emits no remote event —
# the tracker integration only reacts to branch push / PR open / PR merge, so an
# unpushed worktree branch leaves the issue sitting in Backlog (measured: ADT-313,
# branch created locally, 0 remote adt-* branches, state still Backlog).
#
# Config:
#   GUARD_LINEAR_NUDGE_DISABLE=1   — turn off
#   GUARD_LINEAR_ISSUE_RE=<regex>  — issue-id pattern (default: team keys, see lib-issue-id.sh)

[ "${GUARD_LINEAR_NUDGE_DISABLE:-0}" = "1" ] && exit 0

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | python3 -c 'import json,sys
try:
    p=json.loads(sys.stdin.read() or "{}")
    print((p.get("tool_input") or {}).get("command") or "")
except Exception:
    print("")
' 2>/dev/null)

[ -z "$CMD" ] && exit 0

# Use the real system grep, not whatever a wrapper function/alias on PATH resolves
# to (some envs shim `grep` to ugrep -G = BRE, which rejects {n,m} intervals).
GREP=/usr/bin/grep
[ -x "$GREP" ] || GREP=grep

# Boundary detection — quotes blanked so a `git log --grep="git commit"` style
# command does not false-trigger (same technique as guard-destructive-cmd).
SANITIZED=$(printf '%s' "$CMD" | sed -E "s/'[^']*'/''/g" | sed -E 's/"[^"]*"/""/g')

BOUNDARY=""
if echo "$SANITIZED" | $GREP -qE 'git[[:space:]]+(checkout[[:space:]]+-b|switch[[:space:]]+-c|worktree[[:space:]]+add)'; then
  BOUNDARY="branch_create"
elif echo "$SANITIZED" | $GREP -qE 'gh[[:space:]]+pr[[:space:]]+create'; then
  BOUNDARY="pr_create"
elif echo "$SANITIZED" | $GREP -qE 'gh[[:space:]]+pr[[:space:]]+merge'; then
  BOUNDARY="merge"
elif echo "$SANITIZED" | $GREP -qE 'git[[:space:]]+commit'; then
  BOUNDARY="commit"
fi
[ -z "$BOUNDARY" ] && exit 0

# Ids match only real tracker team keys, so UTF-8 or `collector-7` never fire.
. "$(dirname "${BASH_SOURCE[0]}")/lib-issue-id.sh"

# Primary signal: the current branch name (deliberate, e.g. feat/adt-196-...).
# Fallback: the commit message in the command itself (-m or heredoc).
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ "$BOUNDARY" = "branch_create" ]; then
  # The new branch lives in the command, not in HEAD — a `git worktree add` leaves
  # this checkout on the trunk, so reading HEAD would pick up the wrong (or no) id.
  # Only the new name counts when it is found: an id in the worktree path is not
  # this branch's issue.
  NEW_BRANCH=$(printf '%s' "$CMD" | $GREP -oE '(-b|-c)[[:space:]]+[^[:space:]]+' | head -1 | awk '{print $NF}')
  if [ -n "$NEW_BRANCH" ]; then
    ISSUE_UC=$(printf '%s' "$NEW_BRANCH" | issue_id_first)
  else
    ISSUE_UC=$(printf '%s' "$CMD" | issue_id_first)
  fi
else
  ISSUE_UC=$(printf '%s' "$BRANCH" | issue_id_first)
  [ -z "$ISSUE_UC" ] && ISSUE_UC=$(printf '%s' "$CMD" | issue_id_first)
fi

[ -z "$ISSUE_UC" ] && exit 0

. "$(dirname "${BASH_SOURCE[0]}")/lib-emit-context.sh"
once_per "linear-state|$(hook_sid "$INPUT")|$ISSUE_UC|$BOUNDARY" || exit 0

{
if [ "$BOUNDARY" = "branch_create" ]; then
  echo "[guard] NUDGE: $ISSUE_UC 착수 — 로컬 브랜치는 트래커에 아무 이벤트도 안 보낸다."
  echo "① git push -u origin ${NEW_BRANCH:-<branch>} (원격 브랜치 이벤트 발생 = 자동연동 진입점)"
  echo "② 상태를 In Progress 로 명시 전이 — 자동화 토글에 기대지 말 것(확정 경로)."
elif [ "$BOUNDARY" = "commit" ]; then
  echo "[guard] NUDGE: 이 작업이 $ISSUE_UC 에 묶여 있다 — 이슈 트래커 상태 확인했나?"
  echo "착수 경계면 In Progress 로 전이. (상태 값은 맥락 판단 — 미완이면 그대로 둬도 됨)"
elif [ "$BOUNDARY" = "pr_create" ]; then
  echo "[guard] NUDGE: $ISSUE_UC PR 생성됨 — 트래커는 자동으로 안 바뀐다. 직접 갱신했나?"
  echo "① 상태 In Progress 전이  ② PR 링크를 이슈 attachment 로 연결(save_issue links)."
  echo "자동연동은 integration 설치 + 브랜치/PR 에 이슈ID 가 있어야 동작 — 둘 다 없으면 수동 필수."
else
  echo "[guard] NUDGE: $ISSUE_UC 머지됨 — 이슈 트래커 상태 확인했나?"
  echo "머지+검증 완료면 Done 으로 전이. 라이브 검증 등 잔여가 있으면 In Progress 유지."
fi
} | emit_context PostToolUse

exit 0
