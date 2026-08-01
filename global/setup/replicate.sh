#!/usr/bin/env bash
# replicate.sh — 파일 미러 밖의 환경(MCP·플러그인·codex 런타임)을 명령으로 재현한다.
#
# install-global.sh / install.sh 가 파일을 깔고 난 뒤 1회 실행. 멱등 — 이미 등록된
# 항목은 각 CLI 가 무시하거나 갱신한다. 토큰은 여기 없다: MCP 는 각자 OAuth,
# secret 은 settings.json/config.toml 의 <FILL-ME> 를 직접 채운다.
set -uo pipefail

step() { echo; echo "== $*"; }

# ── Claude Code MCP (user scope) ─────────────────────────────────────────────
step "Claude Code MCP 서버"
claude mcp add --scope user --transport http linear https://mcp.linear.app/mcp \
  || echo "  (linear 이미 등록됨 — 스킵)"
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp \
  || echo "  (context7 이미 등록됨 — 스킵)"
echo "  Linear 는 첫 사용 시 브라우저 OAuth 가 뜬다 — 본인 계정으로 승인."

# ── Claude Code 플러그인 ─────────────────────────────────────────────────────
step "Claude Code 플러그인 마켓플레이스"
for repo in anthropics/claude-plugins-official forrestchang/andrej-karpathy-skills \
            JuliusBrussee/caveman DietrichGebert/ponytail Lum1104/Understand-Anything \
            warpdotdev/claude-code-warp nathankim0/clean-architecture-skills; do
  claude plugin marketplace add "$repo" || echo "  ($repo 이미 있음 — 스킵)"
done

step "Claude Code 플러그인 설치"
for p in typescript-lsp@claude-plugins-official pyright-lsp@claude-plugins-official \
         skill-creator@claude-plugins-official frontend-design@claude-plugins-official \
         claude-md-management@claude-plugins-official superpowers@claude-plugins-official \
         andrej-karpathy-skills@karpathy-skills caveman@caveman \
         understand-anything@understand-anything ponytail@ponytail \
         clean-architecture@clean-architecture-skills; do
  claude plugin install "$p" || echo "  ($p 설치 실패/이미 있음 — 확인)"
done

# ── codex 런타임 ─────────────────────────────────────────────────────────────
step "codex CLI + 글로벌 npm 패키지"
if ! command -v codex >/dev/null 2>&1; then
  npm install -g @openai/codex || echo "  (codex CLI 설치 실패 — npm 확인)"
fi
npm install -g oh-my-codex lazycodex-ai || echo "  (oh-my-codex/lazycodex 설치 실패 — 확인)"

step "codex MCP (Linear)"
if command -v codex >/dev/null 2>&1; then
  codex mcp add linear --url https://mcp.linear.app/mcp \
    || echo "  (codex linear 이미 등록됨 — 스킵)"
  echo "  등록 직후 OAuth 플로우가 뜬다(브라우저) — 승인하면 codex 에서 mcp__linear__* 사용 가능."
else
  echo "  codex CLI 없음 — 위 설치 후 재실행"
fi

echo
echo "완료. 재시작 후 확인:"
echo "  claude mcp list · claude plugin list · codex mcp get linear"
echo "남은 수동 항목: settings.json/config.toml 의 <FILL-ME>, Linear/context7 OAuth,"
echo "  ~/.claude/linear-repo-map.json 의 로컬 repo 경로를 자기 머신 경로로 수정."
