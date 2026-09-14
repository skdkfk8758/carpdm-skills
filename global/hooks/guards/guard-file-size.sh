#!/usr/bin/env bash
# PostToolUse hook (Write|Edit): Warn on files exceeding line limit.
# Delivered as additionalContext (lib-emit-context.sh), once per (session, file, level).
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

LEVEL=""
[ "$LINE_COUNT" -gt "$WARN_LINES" ] && LEVEL=caution
[ "$LINE_COUNT" -gt "$MAX_LINES" ] && LEVEL=warning
[ -z "$LEVEL" ] && exit 0
. "$(dirname "${BASH_SOURCE[0]}")/lib-emit-context.sh"
once_per "file-size|$(hook_sid "$INPUT")|$FILE_PATH|$LEVEL" || exit 0

{
if [ "$LINE_COUNT" -gt "$MAX_LINES" ]; then
  echo "[guard] WARNING: $FILE_PATH — ${LINE_COUNT} lines (exceeds ${MAX_LINES} limit)"
  echo "ACTION REQUIRED: Split this file immediately."
  echo "Strategies: by type (type/interface), by concern (handler/service/util), by layer (component/hook/helper)."
elif [ "$LINE_COUNT" -gt "$WARN_LINES" ]; then
  echo "[guard] CAUTION: $FILE_PATH — ${LINE_COUNT} lines (approaching ${MAX_LINES} limit). Consider splitting."
fi
} | emit_context PostToolUse

exit 0
