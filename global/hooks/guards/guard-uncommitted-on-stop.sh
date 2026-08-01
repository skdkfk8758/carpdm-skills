#!/usr/bin/env bash
# Stop hook: two jobs at turn end, both advisory (exit 0 always).
#
#   1) WARN when the current worktree has uncommitted files or commits that were
#      never pushed. Invariant asked for by the user (2026-07-30): "작업이 끝났는데
#      미커밋 파일들이 있으면 안 된다". Measured trigger: Intelligence-SSOT had 7
#      commits + no remote branch + no PR sitting idle for 22h — one `git reset` in
#      a parallel session away from total loss (commit-isolation.md).
#
#   2) SYNC the Orca card comment for LINKED worktrees so the workspace list shows
#      real progress instead of a stale "in-progress" for everything. Measured
#      trigger: all 8 live worktrees had comment="" and workspaceStatus=in-progress,
#      including idle and main checkouts, so the board carried zero signal.
#
# Non-blocking by house posture (guard-worktree-edit-isolation.sh precedent):
# stderr + exit 0, never exit 2. Dedups the warning per (session, state signature)
# so an unchanged state warns once, not every turn.
#
#   Disable both:      GUARD_UNCOMMITTED_DISABLE=1
#   Disable card sync: GUARD_ORCA_CARD_DISABLE=1
#   Retire when:       Orca ships native dirty/ahead badges on the workspace card,
#                      or 3 months pass with zero warnings fired (check the log).
#   Log:               ~/.claude/logs/uncommitted-on-stop.jsonl

[ "${GUARD_UNCOMMITTED_DISABLE:-0}" = "1" ] && exit 0

INPUT=$(cat 2>/dev/null)
SID=$(printf '%s' "$INPUT" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:[[:space:]]*"//; s/"$//')
CWD=$(printf '%s' "$INPUT" | grep -o '"cwd"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:[[:space:]]*"//; s/"$//')
[ -n "$CWD" ] && [ -d "$CWD" ] && cd "$CWD" 2>/dev/null
[ -z "$SID" ] && SID="nosid"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
TOP=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
BR=$(git symbolic-ref --quiet --short HEAD 2>/dev/null) || exit 0
[ -z "$BR" ] && exit 0

# A linked worktree's top-level .git is a FILE; the main worktree's is a DIRECTORY.
IS_LINKED=0
[ -f "$TOP/.git" ] && IS_LINKED=1

DIRTY=$(git status --porcelain 2>/dev/null | grep -c . | tr -d ' ')

# Unpushed commits: prefer the upstream, else the repo default base. No upstream at
# all on a topic branch is itself the risk (no remote copy of the work exists).
UPSTREAM=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)
if [ -n "$UPSTREAM" ]; then
  AHEAD=$(git rev-list --count "$UPSTREAM"..HEAD 2>/dev/null || echo 0)
  NO_REMOTE=0
else
  BASE=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)
  [ -z "$BASE" ] && for b in origin/develop origin/main origin/master; do
    git rev-parse --verify --quiet "$b" >/dev/null 2>&1 && BASE="$b" && break
  done
  if [ -n "$BASE" ]; then
    AHEAD=$(git rev-list --count "$BASE"..HEAD 2>/dev/null || echo 0)
  else
    AHEAD=0
  fi
  NO_REMOTE=1
fi
[ -z "$AHEAD" ] && AHEAD=0

# ---------------------------------------------------------------- Orca card sync
# Linked worktrees only — commenting on every main checkout is noise, and the main
# card belongs to the human. Best-effort: any failure is silent.
if [ "$IS_LINKED" = "1" ] && [ "${GUARD_ORCA_CARD_DISABLE:-0}" != "1" ] && command -v orca >/dev/null 2>&1; then
  TO=""
  command -v timeout >/dev/null 2>&1 && TO="timeout 6"
  PRTXT=""
  if command -v gh >/dev/null 2>&1; then
    PRTXT=$($TO gh pr list --head "$BR" --state open --json number --jq '"PR #\(.[0].number) 오픈"' 2>/dev/null | head -1)
    [ "$PRTXT" = "PR #null 오픈" ] && PRTXT=""
  fi
  if [ "$DIRTY" -gt 0 ]; then
    CMT="진행 중 · 미커밋 ${DIRTY}건"
  elif [ "$AHEAD" -gt 0 ] && [ "$NO_REMOTE" = "1" ]; then
    CMT="clean · ${AHEAD}커밋 unpushed(원격 브랜치 없음 — 유실 위험)"
  elif [ "$AHEAD" -gt 0 ]; then
    CMT="clean · ${AHEAD}커밋 unpushed"
  elif [ "$NO_REMOTE" = "1" ]; then
    CMT="clean · base 대비 커밋 0 · 원격 브랜치 없음"
  else
    CMT="clean · 로컬 커밋 전부 push 됨"
  fi
  [ -n "$PRTXT" ] && CMT="$CMT · $PRTXT"
  CMT="$CMT · ${BR} ⟨auto⟩"

  CUR_JSON=$($TO orca worktree current --json 2>/dev/null)
  CUR_STATUS=$(printf '%s' "$CUR_JSON" | grep -o '"workspaceStatus"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:[[:space:]]*"//; s/"$//')
  CUR_CMT=$(printf '%s' "$CUR_JSON" | grep -o '"comment"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:[[:space:]]*"//; s/"$//')

  # Never clobber a comment a human or an agent wrote by hand — those carry richer
  # context ([HUMAN] 잔여, blockers) than this hook can derive. Only an empty
  # comment or a previous ⟨auto⟩ one is ours to overwrite.
  COMMENT_ARG=1
  case "$CUR_CMT" in
    "") ;;
    *"⟨auto⟩") ;;
    *) COMMENT_ARG=0 ;;
  esac

  # Status is derived only where it is unambiguous, and never overwrites a card a
  # human already marked completed.
  STATUS_ARG=""
  if [ "$CUR_STATUS" != "completed" ]; then
    if [ -n "$PRTXT" ] && [ "$DIRTY" = "0" ]; then
      STATUS_ARG="--workspace-status in-review"
    elif [ "$DIRTY" -gt 0 ] || [ "$AHEAD" -gt 0 ]; then
      STATUS_ARG="--workspace-status in-progress"
    fi
  fi

  if [ "$COMMENT_ARG" = "1" ]; then
    # shellcheck disable=SC2086
    $TO orca worktree set --worktree active --comment "$CMT" $STATUS_ARG --json >/dev/null 2>&1 || :
  elif [ -n "$STATUS_ARG" ]; then
    # shellcheck disable=SC2086
    $TO orca worktree set --worktree active $STATUS_ARG --json >/dev/null 2>&1 || :
  fi
fi

# ------------------------------------------------------------------- Warning
[ "$DIRTY" = "0" ] && [ "$AHEAD" = "0" ] && exit 0

# Dedup: one warning per (session, repo, branch, dirty count, ahead count).
KEY=$(printf '%s' "$SID$TOP$BR$DIRTY$AHEAD" | shasum 2>/dev/null | cut -c1-16)
MARK="${TMPDIR:-/tmp}/cc-uncommitted.${KEY:-fallback}"
[ -f "$MARK" ] && exit 0
: > "$MARK"

LOG="$HOME/.claude/logs/uncommitted-on-stop.jsonl"
mkdir -p "$(dirname "$LOG")" 2>/dev/null
printf '{"ts":"%s","repo":"%s","branch":"%s","dirty":%s,"ahead":%s,"no_remote":%s,"linked":%s}\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$TOP" "$BR" "$DIRTY" "$AHEAD" "$NO_REMOTE" "$IS_LINKED" >> "$LOG" 2>/dev/null

echo "[nudge] 작업 종료 시점에 미반영 변경이 남아 있다 — $BR" >&2
[ "$DIRTY" -gt 0 ] && echo "  · 미커밋 ${DIRTY}건 — 의미 단위로 커밋하거나, 의도적으로 남기면 사유를 보고에 명시" >&2
if [ "$AHEAD" -gt 0 ] && [ "$NO_REMOTE" = "1" ]; then
  echo "  · ${AHEAD}커밋이 로컬에만 있고 원격 브랜치가 없다 — git push -u origin $BR (병렬 세션의 reset 한 번에 전부 손실)" >&2
elif [ "$AHEAD" -gt 0 ]; then
  echo "  · ${AHEAD}커밋 unpushed — git push" >&2
fi
echo "  (끄기: GUARD_UNCOMMITTED_DISABLE=1)" >&2
exit 0
