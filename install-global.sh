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
done < <(cd "$SRC" && find . -type f ! -name README.md ! -name settings.json \
           ! -path './skills-extra/*' ! -path './codex/*' ! -path './setup/*' | sed 's|^\./||')

# skills-extra → ~/.claude/skills/ — 서드파티·비배포 스킬 전수 (install.sh 와 동일한 in-place 덮어씀 정책)
if [ -d "$SRC/skills-extra" ]; then
  extra=0
  for d in "$SRC/skills-extra"/*/; do
    [ -d "$d" ] || continue
    n="$(basename "$d")"
    mkdir -p "$DEST/skills/$n"
    rsync -a --delete --exclude '__pycache__' "$d" "$DEST/skills/$n/"
    extra=$((extra+1))
  done
  echo "skills-extra: $extra skills installed to ~/.claude/skills/"
fi

# codex → ~/.codex/ — 스킬·에이전트·프롬프트는 미러, config.toml 은 없을 때만 설치(있으면 보존)
if [ -d "$SRC/codex" ]; then
  CODEX="$HOME/.codex"
  mkdir -p "$CODEX"
  rsync -a --exclude '__pycache__' "$SRC/codex/skills/"  "$CODEX/skills/"
  rsync -a "$SRC/codex/agents/"  "$CODEX/agents/"
  rsync -a "$SRC/codex/prompts/" "$CODEX/prompts/"
  [ -f "$CODEX/AGENTS.md" ] || cp "$SRC/codex/AGENTS.md" "$CODEX/AGENTS.md"
  if [ -f "$CODEX/config.toml" ]; then
    echo "codex: 기존 ~/.codex/config.toml 보존 — repo 판과 수동 대조 필요하면 global/codex/config.toml 참조"
  else
    cp "$SRC/codex/config.toml" "$CODEX/config.toml"
    echo "codex: config.toml 설치 — <FILL-ME> 값을 채우세요"
  fi
fi

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
echo "  1. ~/.claude/settings.json 과 ~/.codex/config.toml 의 '<FILL-ME>' 값을 채우세요."
echo "  2. ~/.claude/linear-repo-map.json 의 repo 경로를 자기 머신 경로로 수정하세요."
echo "  3. bash global/setup/replicate.sh 로 MCP·플러그인·codex 런타임을 등록하세요."
echo "  4. 자작 배포 스킬은 bash install.sh 로 별도 설치합니다 (skills/ → ~/.claude/skills/)."
echo "  5. Claude Code 를 재시작하면 rules·hooks·skills 가 로드됩니다."
