#!/usr/bin/env bash
# PostToolUse hook (Write|Edit): Warn on CLAUDE.md exceeding line limit.
# Configurable via env vars:
#   GUARD_CLAUDE_MD_MAX  — hard limit (default: 100)
#   GUARD_CLAUDE_MD_WARN — warning threshold (default: 80)

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"//' | sed 's/"$//')

[ -z "$FILE_PATH" ] && exit 0
[ ! -f "$FILE_PATH" ] && exit 0

# Only target CLAUDE.md (any path)
case "$(basename "$FILE_PATH")" in
  CLAUDE.md|.claude.md|.claude.local.md) ;;
  *) exit 0 ;;
esac

MAX="${GUARD_CLAUDE_MD_MAX:-100}"
WARN="${GUARD_CLAUDE_MD_WARN:-80}"

LINE_COUNT=$(wc -l < "$FILE_PATH" 2>/dev/null | tr -d ' ')
[ -z "$LINE_COUNT" ] && exit 0

if [ "$LINE_COUNT" -gt "$MAX" ]; then
  echo "[guard] WARNING: $FILE_PATH — ${LINE_COUNT} lines (exceeds ${MAX} limit)" >&2
  echo "ACTION REQUIRED: Split CLAUDE.md. Move detail to a referenced file or trim." >&2
elif [ "$LINE_COUNT" -gt "$WARN" ]; then
  echo "[guard] CAUTION: $FILE_PATH — ${LINE_COUNT} lines (approaching ${MAX} limit). Consider splitting." >&2
fi

exit 0
