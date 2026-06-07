#!/usr/bin/env bash
# Sync (publish) live skills from ~/.claude/ into this repo.
# Skills mirror per repo-tracked dir under skills/. Source of truth for the list
# is what the repo already tracks. To start distributing a NEW skill, create its
# dir under skills/ once (even empty) — then this script keeps them in sync.
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
git status --short -- skills
echo

if [ "${1:-}" = "--push" ]; then
  command -v gh >/dev/null 2>&1 || { echo "gh CLI 필요 (PR 자동화) — 설치 후 재시도"; exit 1; }
  BASE="$(git branch --show-current)"
  DATE="$(date +%Y-%m-%d)"
  BR="chore/sync-$(date +%Y%m%d-%H%M%S)"
  # 새 브랜치로 분기 (master 직접 push 우회). staged 변경은 그대로 따라옴.
  git checkout -q -b "$BR"
  git commit -q -m "chore: 스킬 동기화 ($DATE)"
  git push -q -u origin "$BR"
  gh pr create --base "$BASE" --head "$BR" \
    --title "chore: 스킬 동기화 ($DATE)" \
    --body "\`sync.sh --push\` 자동 생성 — \`~/.claude/skills/\` → repo \`skills/\` 미러링." >/dev/null
  gh pr merge "$BR" --merge --delete-branch
  git checkout -q "$BASE"
  git pull -q --ff-only origin "$BASE"
  git branch -d "$BR" >/dev/null 2>&1 || true
  echo "동기화 PR 생성·머지 완료. $BASE 최신."
else
  echo "Next: review, then publish —"
  echo "  bash sync.sh --push        # 브랜치+PR+머지 자동"
fi

[ "$missing" = 1 ] && echo "(일부 스킬이 $SRC_DIR 에 없어 건너뜀 — 위 ! 표시 확인)"
exit 0
