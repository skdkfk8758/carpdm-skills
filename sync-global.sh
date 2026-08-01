#!/usr/bin/env bash
# sync-global.sh — ~/.claude/ (SSOT) → repo global/ 미러. 수동 실행.
#
# skills 의 sync.sh 와 같은 방향(live → repo)의 글로벌판. rules·rules-ondemand·
# hooks/guards 는 rsync --delete strict 미러(live 에서 지운 룰은 repo 에서도 빠짐 —
# git history 가 안전망). settings.json 은 secret 마스킹 후 미러.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)/global"
LIVE="$HOME/.claude"

# strict 미러 디렉토리 (전수)
rsync -a --delete --exclude '__pycache__' "$LIVE/rules/"          "$REPO/rules/"
rsync -a --delete --exclude '__pycache__' "$LIVE/rules-ondemand/" "$REPO/rules-ondemand/"
rsync -a --delete --exclude '__pycache__' "$LIVE/hooks/guards/"   "$REPO/hooks/guards/"

# 개별 파일 (관리 목록)
for f in hooks/caveman-session-start.sh hooks/linear-banner-autostart.sh \
         hooks/prompt-intake.py statusline.sh linear-issue-goal-template.md CLAUDE.md; do
  cp "$LIVE/$f" "$REPO/$f"
done

# scripts — repo 가 이미 추적 중인 것만 갱신 (새 스크립트 편입은 수동 결정)
for f in "$REPO"/scripts/*; do
  base="$(basename "$f")"
  if [ -f "$LIVE/scripts/$base" ]; then cp "$LIVE/scripts/$base" "$f"
  else echo "WARN: live 에 없는 스크립트 — $base (repo 에서 수동 제거 판단)"; fi
done
new_scripts="$(cd "$LIVE/scripts" && ls | grep -v __pycache__ | while read -r s; do
  [ -f "$REPO/scripts/$s" ] || echo "$s"; done)"
[ -n "$new_scripts" ] && echo "NOTE: 미편입 live 스크립트 — $new_scripts (필요하면 global/scripts/ 에 수동 추가)"

# settings.json — secret 마스킹 미러
node - "$LIVE/settings.json" "$REPO/settings.json" <<'EOF'
const fs = require("fs");
const [src, dst] = process.argv.slice(2);
const s = JSON.parse(fs.readFileSync(src, "utf8"));
const masked = [];
if (s.env) {
  for (const k of Object.keys(s.env)) {
    const v = s.env[k];
    if (/(KEY|TOKEN|SECRET|PASSWORD|CREDENTIAL)/i.test(k) &&
        typeof v === "string" && v.length > 0 && !/^(0|1|true|false)$/.test(v) &&
        v !== "<FILL-ME>") {
      s.env[k] = "<FILL-ME>"; masked.push(k);
    }
  }
}
fs.writeFileSync(dst, JSON.stringify(s, null, 2) + "\n");
console.log("settings.json mirrored, masked:", masked.join(", ") || "(none)");
EOF

# 커밋 전 최종 secret 스캔 — 하나라도 잡히면 실패 (verification-safety V1: 판정 단계라 swallow 금지)
if grep -rn -iE "(api[_-]?key|token|secret|password)['\"]?\s*[:=]\s*['\"][A-Za-z0-9_-]{16,}" "$REPO" | grep -v FILL-ME; then
  echo "ERROR: secret 의심 패턴 발견 — 커밋 전 위 라인을 확인하세요" >&2
  exit 1
fi

echo "global/ mirrored. git status:"
git -C "$(dirname "$REPO")" status -s -- global/ | head -30
