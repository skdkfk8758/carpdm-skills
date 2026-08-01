#!/usr/bin/env bash
# PreToolUse hook (Edit|Write): advisory nudge when the FIRST file edit of a
# session lands in the MAIN worktree while sitting on a base/integration
# branch. This is the "lazy isolation" half of ADR-041 D9 — isolate per-topic
# into a worktree at the moment real work starts, when the topic is known so
# the branch name is meaningful (vs. blind branching at session launch).
#
# Complements guard-worktree-branch-nudge.sh (which fires on `git checkout -b`):
# this one catches the common case where a session edits files directly without
# ever creating a branch.
#
# Non-blocking by design — house posture is report-only (verify G16,
# large-file-read, branch nudge are all advisory; blocking worktree guards are
# explicitly forbidden). Exit 0 + stderr. Dedups to ONE nudge per
# (session, branch, repo) via a marker file so it never spams later edits.
#
#   Disable:        GUARD_WT_ISO_DISABLE=1
#   Extra bases:    GUARD_WT_ISO_BASES="develop main staging"

[ "${GUARD_WT_ISO_DISABLE:-0}" = "1" ] && exit 0

INPUT=$(cat)
SID=$(printf '%s' "$INPUT" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:[[:space:]]*"//; s/"$//')
[ -z "$SID" ] && SID="nosid"

# Must be inside a git work tree.
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
TOP=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0

# A linked worktree's top-level .git is a FILE (gitdir pointer); the main
# worktree's is a DIRECTORY. Already isolated → stay quiet.
[ -f "$TOP/.git" ] && exit 0

# Current branch (detached HEAD → skip silently).
BR=$(git symbolic-ref --quiet --short HEAD 2>/dev/null) || exit 0
[ -z "$BR" ] && exit 0

# Base/integration branches: repo default (origin/HEAD) + common names + override.
DEFAULT=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')
BASES="${GUARD_WT_ISO_BASES:-develop main master} $DEFAULT"
for b in $BASES; do
  [ "$BR" = "$b" ] && MATCH=1 && break
done
[ "${MATCH:-0}" = "0" ] && exit 0

# Dedup: one nudge per (session, branch, repo).
KEY=$(printf '%s' "$SID$TOP$BR" | shasum 2>/dev/null | cut -c1-16)
MARK="${TMPDIR:-/tmp}/cc-wt-iso.${KEY:-fallback}"
[ -f "$MARK" ] && exit 0
: > "$MARK"

echo "[nudge] 메인 워크트리·base 브랜치($BR)에서 첫 편집 감지 (ADR-041 D9 lazy 격리)." >&2
echo "  권고: 작업을 worktree 로 격리하고 메인은 $BR 에 둔다. 토픽이 잡힌 지금이 분기 적기." >&2
echo "  → EnterWorktree({ name: \"<type>/<topic>\" })  — typed 이름 명시 (feat/fix/refactor…), 자동명 지양" >&2
echo "  또는: git worktree add .claude/worktrees/<type>+<topic> -b <type>/<topic> HEAD" >&2
echo "  의도적으로 메인에서 진행하면 사유를 첫 응답에 명시. (끄기: GUARD_WT_ISO_DISABLE=1)" >&2
exit 0
