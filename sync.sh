#!/usr/bin/env bash
# Sync (publish) live skills from ~/.claude/ into this repo.
# Skills mirror per repo-tracked dir under skills/. Source of truth for the list
# is what the repo already tracks. To start distributing a NEW skill, create its
# dir under skills/ once (even empty) — then this script keeps them in sync.
#
# Usage:
#   bash sync.sh           # mirror files, stage, show status, print next steps
#   bash sync.sh --push    # also commit (timestamped), push, PR, and merge
#   bash sync.sh --pr-only # mirror, commit, push, open PR — but DO NOT merge
#                          # (leaves the branch + PR for a CI-gated land; used by the ship skill)
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
  # --exclude __pycache__: python bytecode junk on either side is neither synced
  # nor counted as drift (a stray .pyc in the repo caused a false stop-hook warning)
  rsync -a --delete --exclude '__pycache__' "$src/" "$dst"
  echo "  = $name"
done

echo
cd "$REPO_DIR"

# 글로벌 덤프도 같은 배포 단위 — sync-global.sh 로 미러(내장 secret 마스킹+스캔 게이트,
# 스캔 hit 시 여기서 전체 중단). 팀원 이식 덤프의 신선도는 배포 경로가 하나여야 유지된다.
bash "$REPO_DIR/sync-global.sh"

git add -A skills global

if git diff --cached --quiet; then
  echo "No changes — repo already up to date."
  exit 0
fi

echo "=== staged changes ==="
git status --short -- skills global
echo

if [ "${1:-}" = "--push" ] || [ "${1:-}" = "--pr-only" ]; then
  command -v gh >/dev/null 2>&1 || { echo "gh CLI 필요 (PR 자동화) — 설치 후 재시도"; exit 1; }
  # 로컬 CI 게이트 — CI 에서만 보이는 red 는 왕복 비용(PR #159 실측). 서버와 같은 3종.
  if command -v node >/dev/null 2>&1; then
    for s in validate-skills.js check-invisible-chars.js catalog.js; do
      [ -f "$REPO_DIR/scripts/ci/$s" ] && node "$REPO_DIR/scripts/ci/$s"
    done
  fi
  BASE="$(git branch --show-current)"
  DATE="$(date +%Y-%m-%d)"
  BR="chore/sync-$(date +%Y%m%d-%H%M%S)"
  # 새 브랜치로 분기 (master 직접 push 우회). staged 변경은 그대로 따라옴.
  git checkout -q -b "$BR"
  git commit -q -m "chore: 스킬·글로벌 동기화 ($DATE)"
  git push -q -u origin "$BR"
  gh pr create --base "$BASE" --head "$BR" \
    --title "chore: 스킬·글로벌 동기화 ($DATE)" \
    --body "\`sync.sh\` 자동 생성 — \`~/.claude/skills/\` → \`skills/\` + 글로벌 환경(\`sync-global.sh\`) → \`global/\` 미러링." >/dev/null
  if [ "${1:-}" = "--pr-only" ]; then
    # 머지 보류 — CI 게이트 + land 는 ship 스킬이 처리. 브랜치는 로컬에 남겨 둔다.
    PR_URL="$(gh pr view "$BR" --json url -q .url)"
    git checkout -q "$BASE"
    echo "PR 생성 완료 (머지 보류). 브랜치: $BR"
    echo "PR: $PR_URL"
  else
    gh pr merge "$BR" --merge --delete-branch
    git checkout -q "$BASE"
    git pull -q --ff-only origin "$BASE"
    git branch -d "$BR" >/dev/null 2>&1 || true
    echo "동기화 PR 생성·머지 완료. $BASE 최신."
  fi
else
  echo "Next: review, then publish —"
  echo "  bash sync.sh --push        # 브랜치+PR+머지 자동"
  echo "  bash sync.sh --pr-only     # 브랜치+PR 까지만 (CI 후 land 는 ship 스킬)"
fi

[ "$missing" = 1 ] && echo "(일부 스킬이 $SRC_DIR 에 없어 건너뜀 — 위 ! 표시 확인)"
exit 0
