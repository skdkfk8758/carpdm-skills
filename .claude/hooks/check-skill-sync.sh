#!/usr/bin/env bash
# Stop hook — warn (non-blocking) at work-end if the global skills aren't
# published to this repo and pushed. Detect-only: never syncs, commits, or pushes.
#
# Checks:
#   (a) live ~/.claude/skills/ differs from repo skills/  → needs `bash sync.sh`
#   (b) repo skills/ has uncommitted changes              → needs commit
#   (c) local commits not on origin                       → needs push
#
# Exit 1 (non-2) on any finding: stderr is shown to the user, the stop proceeds.
# Exit 0 when clean.
set -uo pipefail

REPO_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
SRC_DIR="$HOME/.claude/skills"
DST_DIR="$REPO_DIR/skills"
msgs=()

# (a) live -> repo drift: rsync dry-run per repo-tracked skill dir (repo dir list is SSOT)
if [ -d "$DST_DIR" ] && [ -d "$SRC_DIR" ]; then
  for dst in "$DST_DIR"/*/; do
    name="$(basename "$dst")"
    src="$SRC_DIR/$name"
    [ -d "$src" ] || continue
    # -c: compare by checksum, not mtime — git checkout bumps mtimes and would
    # otherwise flag content-identical files as drift. Itemize real changes only.
    if rsync -ainc --delete --exclude '__pycache__' "$src/" "$dst" 2>/dev/null | grep -qE '^(\*deleting|[<>]f)'; then
      msgs+=("live ~/.claude/skills/$name 가 repo 에 미반영 — 'bash sync.sh' 필요")
    fi
  done
fi

cd "$REPO_DIR" 2>/dev/null || exit 0

# (b) uncommitted changes under skills/ (worktree or staged)
if ! git diff --quiet -- skills 2>/dev/null || ! git diff --cached --quiet -- skills 2>/dev/null; then
  msgs+=("repo skills/ 에 미커밋 변경 존재 — sync/commit 필요")
fi

# (c) local commits ahead of upstream
upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)"
if [ -n "$upstream" ]; then
  ahead="$(git rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)"
  [ "$ahead" -gt 0 ] && msgs+=("origin 에 미push 커밋 ${ahead}개 — 'bash sync.sh --push' 또는 git push 필요")
fi

if [ "${#msgs[@]}" -gt 0 ]; then
  {
    echo "⚠ 작업 종료 체크 — 글로벌 스킬 동기화/푸시 미완료:"
    for m in "${msgs[@]}"; do echo "  - $m"; done
  } >&2
  exit 1
fi
exit 0
