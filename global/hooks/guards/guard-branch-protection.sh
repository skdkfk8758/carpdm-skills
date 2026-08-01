#!/usr/bin/env bash
# PreToolUse hook (Bash): Block direct push to main and force push
# exit 2 + stderr → blocks tool execution with reason

INPUT=$(cat)
CMD=$(echo "$INPUT" | sed 's/\\"/ESCAPED_QUOTE/g' | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"command"[[:space:]]*:[[:space:]]*"//' | sed 's/"$//' | sed 's/ESCAPED_QUOTE/"/g')

[ -z "$CMD" ] && exit 0

# Strip quoted regions so strings that merely MENTION "git push --force"
# (test payloads, commit messages, heredoc data) don't trigger false
# positives. Only the executable shell tokens remain.
#  1) single-quoted strings (cannot contain nested ')
#  2) double-quoted strings
#  3) here-string payloads (<<< '...' / <<< "...") are covered by 1/2
SANITIZED=$(printf '%s' "$CMD" | sed -E "s/'[^']*'/''/g" | sed -E 's/"[^"]*"/""/g')

# Only check git push commands (on the sanitized command line)
echo "$SANITIZED" | grep -qE 'git[[:space:]]+push' || exit 0

# --- force push ---
# Match the flags as standalone tokens so branch/path names containing
# `-f` substrings (e.g. "zoom-fade-opt-in") don't false-positive. A true
# force flag is preceded by whitespace and terminated by whitespace, `=`,
# or end-of-line. `--force-with-lease` is the safer alternative and is
# explicitly allowed.
if echo "$SANITIZED" | grep -qE '(^|[[:space:]])(-f|--force)([[:space:]]|=|$)' \
   && ! echo "$SANITIZED" | grep -qE '(^|[[:space:]])--force-with-lease([[:space:]]|=|$)'; then
  echo "[guard] BLOCKED: force push detected — $CMD" >&2
  echo "Consider --force-with-lease instead." >&2
  exit 2
fi

# --- direct push to main/master ---
if echo "$SANITIZED" | grep -qE 'git[[:space:]]+push[[:space:]]+\S+[[:space:]]+(main|master)\b'; then
  echo "[guard] BLOCKED: direct push to main detected — $CMD" >&2
  echo "Create a PR from a feature branch instead." >&2
  exit 2
fi

exit 0
