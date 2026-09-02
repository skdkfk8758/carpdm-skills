#!/usr/bin/env bash
# Block claude-in-chrome MCP tools; route browser work to aside MCP instead.
# Escape hatch: touch ~/.claude/.allow-chrome-mcp to bypass (only when the
# user explicitly asks for the Chrome extension, e.g. needs their real
# Chrome session's login state).
cat >/dev/null
if [ -f "$HOME/.claude/.allow-chrome-mcp" ]; then
  exit 0
fi
cat >&2 <<'EOF'
[aside 강제] claude-in-chrome MCP 는 차단됨. 브라우저 작업은 aside MCP 를 사용할 것:
  1) ToolSearch "select:mcp__aside__repl" 로 스키마 로드 (이미 로드했으면 생략)
  2) mcp__aside__repl 에서 Playwright API 사용 — openTab(url), snapshot(page), page.screenshot() 등
사용자가 명시적으로 Chrome extension(실제 로그인 세션)을 요구한 경우에만:
  touch ~/.claude/.allow-chrome-mcp  로 해제 후 재시도, 끝나면 rm.
EOF
exit 2
