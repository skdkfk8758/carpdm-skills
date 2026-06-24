#!/usr/bin/env bash
# PostToolUse hook (Bash): Nudge to transition the linked issue tracker state at
# work boundaries. NON-BLOCKING — exit 0 + stderr only (guard-file-size pattern).
#
# Why: recurring miss — "code done" gets treated as "task done", skipping the
# tracker boundary transition (착수→In Progress, 머지+검증→Done). A hook cannot
# compute the CORRECT target state (that is contextual judgment), so this only
# REMINDS at the moment a boundary command runs. It never blocks, never queries
# the tracker API (local git only, ≤5s) — matching every other guard's contract.
#
# Fires when the just-run command was a boundary:
#   - git commit            → progress checkpoint  (set In Progress?)
#   - gh pr create          → PR opened            (set In Progress + attach PR link?)
#   - gh pr merge           → merge                 (verify done → Done?)
# and an issue id (e.g. ADT-196) is detectable in the branch name or commit -m.
#
# Config:
#   GUARD_LINEAR_NUDGE_DISABLE=1   — turn off
#   GUARD_LINEAR_ISSUE_RE=<regex>  — issue-id pattern (default [A-Za-z]{2,10}-[0-9]+)

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
if echo "$SANITIZED" | $GREP -qE 'gh[[:space:]]+pr[[:space:]]+create'; then
  BOUNDARY="pr_create"
elif echo "$SANITIZED" | $GREP -qE 'gh[[:space:]]+pr[[:space:]]+merge'; then
  BOUNDARY="merge"
elif echo "$SANITIZED" | $GREP -qE 'git[[:space:]]+commit'; then
  BOUNDARY="commit"
fi
[ -z "$BOUNDARY" ] && exit 0

# Bounded interval — BSD grep rejects open-ended {2,}. NOTE: keep this as a plain
# assignment, not ${VAR:-default} — a `}` inside the default closes the parameter
# expansion early and mangles the regex.
ISSUE_RE="$GUARD_LINEAR_ISSUE_RE"
[ -z "$ISSUE_RE" ] && ISSUE_RE='[A-Za-z]{2,10}-[0-9]+'

# Primary signal: the current branch name (deliberate, e.g. feat/adt-196-...).
# Fallback: the commit message in the command itself. Branch is preferred because
# it rarely contains incidental matches (UTF-8, SHA-256, …) that a message might.
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
ISSUE=$(printf '%s' "$BRANCH" | $GREP -oiE "$ISSUE_RE" | head -1)
[ -z "$ISSUE" ] && ISSUE=$(printf '%s' "$CMD" | $GREP -oiE "$ISSUE_RE" | head -1)

[ -z "$ISSUE" ] && exit 0

ISSUE_UC=$(printf '%s' "$ISSUE" | tr '[:lower:]' '[:upper:]')

if [ "$BOUNDARY" = "commit" ]; then
  echo "[guard] NUDGE: 이 작업이 $ISSUE_UC 에 묶여 있다 — 이슈 트래커 상태 확인했나?" >&2
  echo "착수 경계면 In Progress 로 전이. (상태 값은 맥락 판단 — 미완이면 그대로 둬도 됨)" >&2
elif [ "$BOUNDARY" = "pr_create" ]; then
  echo "[guard] NUDGE: $ISSUE_UC PR 생성됨 — 트래커는 자동으로 안 바뀐다. 직접 갱신했나?" >&2
  echo "① 상태 In Progress 전이  ② PR 링크를 이슈 attachment 로 연결(save_issue links)." >&2
  echo "자동연동은 integration 설치 + 브랜치/PR 에 이슈ID 가 있어야 동작 — 둘 다 없으면 수동 필수." >&2
else
  echo "[guard] NUDGE: $ISSUE_UC 머지됨 — 이슈 트래커 상태 확인했나?" >&2
  echo "머지+검증 완료면 Done 으로 전이. 라이브 검증 등 잔여가 있으면 In Progress 유지." >&2
fi

exit 0
