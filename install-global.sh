#!/usr/bin/env bash
# install-global.sh — repo global/ → ~/.claude/ 글로벌 셋업 설치.
#
# skills 와 별개 축: rules(상시)·rules-ondemand(JIT)·hooks/guards·settings·CLAUDE.md.
# 관리 목록(global/ 트리)만 복사한다 — ~/.claude/ 의 다른 파일(memory, projects,
# plugins, linear-repo-map.json 등)은 건드리지 않는다.
#
# 안전장치:
# - 내용이 다른 기존 파일은 ~/.claude/backups/global-install-<ts>/ 로 백업 후 덮어씀.
# - settings.json 의 "<FILL-ME>" placeholder 는 기존 로컬 값이 있으면 보존(머지) —
#   재실행이 실키를 placeholder 로 되돌리지 않는다.
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)/global"
DEST="$HOME/.claude"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP="$DEST/backups/global-install-$TS"

[ -d "$SRC" ] || { echo "ERROR: global/ not found next to this script" >&2; exit 1; }
mkdir -p "$DEST"

copied=0; backed=0
while IFS= read -r rel; do
  src="$SRC/$rel"; dst="$DEST/$rel"
  if [ -f "$dst" ] && ! cmp -s "$src" "$dst"; then
    mkdir -p "$BACKUP/$(dirname "$rel")"
    cp "$dst" "$BACKUP/$rel"
    backed=$((backed+1))
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  case "$rel" in *.sh|*.py) chmod +x "$dst";; esac
  copied=$((copied+1))
done < <(cd "$SRC" && find . -type f ! -name README.md ! -name settings.json | sed 's|^\./||')

# settings.json — placeholder 머지 설치 (node 필요; repo CI 와 같은 전제)
if command -v node >/dev/null 2>&1; then
  node - "$SRC/settings.json" "$DEST/settings.json" "$BACKUP" <<'EOF'
const fs = require("fs"), path = require("path");
const [src, dst, backup] = process.argv.slice(2);
const next = JSON.parse(fs.readFileSync(src, "utf8"));
if (fs.existsSync(dst)) {
  const cur = JSON.parse(fs.readFileSync(dst, "utf8"));
  // preserve local values where the repo copy is a sanitized placeholder
  if (next.env && cur.env) {
    for (const k of Object.keys(next.env)) {
      if (next.env[k] === "<FILL-ME>" && cur.env[k] && cur.env[k] !== "<FILL-ME>")
        next.env[k] = cur.env[k];
    }
  }
  fs.mkdirSync(path.join(backup), { recursive: true });
  fs.copyFileSync(dst, path.join(backup, "settings.json"));
}
fs.writeFileSync(dst, JSON.stringify(next, null, 2) + "\n");
console.log("settings.json installed (placeholder-merge)");
EOF
else
  echo "WARN: node not found — settings.json skipped. Install node and re-run," >&2
  echo "      or merge global/settings.json into ~/.claude/settings.json manually." >&2
fi

echo "Installed $copied files to $DEST ($backed backed up to $BACKUP)"
echo ""
echo "Post-install:"
echo "  1. ~/.claude/settings.json 의 '<FILL-ME>' 값을 채우거나 해당 env 를 제거하세요."
echo "  2. Linear 연동을 쓰면 ~/.claude/linear-repo-map.json 을 직접 작성하세요"
echo "     (머신 종속 — repo 에 포함되지 않음, 형식은 global/README.md 참조)."
echo "  3. Claude Code 를 재시작하면 rules·hooks 가 로드됩니다."
