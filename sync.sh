#!/usr/bin/env bash
# Sync (publish) live skills from ~/.claude/skills/ into this repo's skills/.
# Mirrors each skill the repo already tracks — source of truth for the list is
# the directories under repo skills/. To start distributing a NEW skill, create
# its dir under skills/ once (even empty), then this script keeps it in sync.
#
# Usage:
#   bash sync.sh           # mirror files, stage, show status, print next steps
#   bash sync.sh --push    # also commit (timestamped) and push to origin
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$HOME/.claude/skills"
DST_DIR="$REPO_DIR/skills"

[ -d "$DST_DIR" ] || { echo "no skills/ dir in repo — nothing to sync"; exit 1; }

echo "Syncing  from: $SRC_DIR"
echo "           to: $DST_DIR"
echo

missing=0
for dst in "$DST_DIR"/*/; do
  name="$(basename "$dst")"
  src="$SRC_DIR/$name"
  if [ ! -d "$src" ]; then
    echo "  ! $name  (not found in $SRC_DIR — skipped)"
    missing=1
    continue
  fi
  # --delete so files removed from the live skill also disappear here (true mirror)
  rsync -a --delete "$src/" "$dst"
  echo "  = $name"
done

echo
cd "$REPO_DIR"
git add -A skills

if git diff --cached --quiet; then
  echo "No changes — repo already up to date."
  exit 0
fi

echo "=== staged changes ==="
git status --short skills
echo

if [ "${1:-}" = "--push" ]; then
  TS="$(date +%Y-%m-%d)"
  git commit -q -m "chore: 스킬 동기화 ($TS)"
  git push origin "$(git branch --show-current)"
  echo "committed & pushed."
else
  echo "Next: review, then commit & push —"
  echo "  git commit -m \"chore: 스킬 동기화\"  &&  git push"
  echo "Or re-run:  bash sync.sh --push"
fi

[ "$missing" = 1 ] && echo "(일부 스킬이 $SRC_DIR 에 없어 건너뜀 — 위 ! 표시 확인)"
exit 0
