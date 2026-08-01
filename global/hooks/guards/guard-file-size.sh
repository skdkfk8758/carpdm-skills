#!/usr/bin/env bash
# PostToolUse hook (Write|Edit): Warn on files exceeding line limit
# Configurable via env vars:
#   GUARD_SOURCE_EXTS  — regex of source extensions (default: ts|tsx|js|jsx)
#   GUARD_MAX_LINES    — hard limit (default: 300)
#   GUARD_WARN_LINES   — warning threshold (default: 250)

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"//' | sed 's/"$//')

[ -z "$FILE_PATH" ] && exit 0
[ ! -f "$FILE_PATH" ] && exit 0

# Skip docs, config, style files
if echo "$FILE_PATH" | grep -qE '\.(md|json|yaml|yml|css|svg|html)$'; then
  exit 0
fi

SOURCE_EXTS="${GUARD_SOURCE_EXTS:-ts|tsx|js|jsx}"
MAX_LINES="${GUARD_MAX_LINES:-300}"
WARN_LINES="${GUARD_WARN_LINES:-250}"

# Source files only
if ! echo "$FILE_PATH" | grep -qE "\\.(${SOURCE_EXTS})$"; then
  exit 0
fi

LINE_COUNT=$(wc -l < "$FILE_PATH" 2>/dev/null | tr -d ' ')
[ -z "$LINE_COUNT" ] && exit 0

if [ "$LINE_COUNT" -gt "$MAX_LINES" ]; then
  echo "[guard] WARNING: $FILE_PATH — ${LINE_COUNT} lines (exceeds ${MAX_LINES} limit)" >&2
  echo "ACTION REQUIRED: Split this file immediately." >&2
  echo "Strategies: by type (type/interface), by concern (handler/service/util), by layer (component/hook/helper)." >&2
elif [ "$LINE_COUNT" -gt "$WARN_LINES" ]; then
  echo "[guard] CAUTION: $FILE_PATH — ${LINE_COUNT} lines (approaching ${MAX_LINES} limit). Consider splitting." >&2
fi

exit 0
