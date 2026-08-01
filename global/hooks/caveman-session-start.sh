#!/usr/bin/env bash
# SessionStart wrapper — activate caveman mode.
# Resolves the plugin's cached activate.js at runtime so a plugin update
# (which changes the commit-sha cache dir) never breaks the hook.
# Silent no-op if caveman is not installed.
set -euo pipefail

CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

# Pick the newest matching activate.js across cached versions.
script=""
for f in "$CFG"/plugins/cache/caveman/caveman/*/src/hooks/caveman-activate.js; do
  [ -f "$f" ] || continue
  if [ -z "$script" ] || [ "$f" -nt "$script" ]; then
    script="$f"
  fi
done

[ -z "$script" ] && exit 0   # caveman not installed — nothing to inject
exec node "$script"
