#!/usr/bin/env bash
# PreToolUse hook (Bash): Block direct push to main and force push
# exit 2 + stderr → blocks tool execution with reason
# Tests: python3 guard-branch-protection.test.py (same dir) — run after editing
# the sanitizer; it covers both the blocks and the false-positive regressions.

INPUT=$(cat)
CMD=$(echo "$INPUT" | sed 's/\\"/ESCAPED_QUOTE/g' | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"command"[[:space:]]*:[[:space:]]*"//' | sed 's/"$//' | sed 's/ESCAPED_QUOTE/"/g')

[ -z "$CMD" ] && exit 0

# Strip quoted regions so strings that merely MENTION "git push --force"
# (test payloads, commit messages, heredoc data) don't trigger false
# positives. Only the executable shell tokens remain.
#  1) heredoc bodies (cat > f <<'EOF' … EOF) — dropped whole; the opening
#     line is kept because it can carry real commands
#  2) single-quoted strings (cannot contain nested ')
#  3) double-quoted strings
#  4) here-string payloads (<<< '...' / <<< "...") are covered by 2/3
# The command arrives as one JSON string, so newlines are still the literal
# two characters \n — restore them first or the line-based pass below sees
# a single line and never enters a heredoc.
SANITIZED=$(printf '%s' "$CMD" | awk '{ gsub(/\\n/, "\n"); print }' | awk '
  inhd { if ($0 ~ delim_re) inhd = 0; next }
  {
    if (match($0, /<<-?[[:space:]]*("[A-Za-z_][A-Za-z0-9_]*"|'"'"'[A-Za-z_][A-Za-z0-9_]*'"'"'|[A-Za-z_][A-Za-z0-9_]*)/)) {
      d = substr($0, RSTART, RLENGTH)
      sub(/^<<-?[[:space:]]*/, "", d)
      gsub(/["'"'"']/, "", d)
      delim_re = "^[[:space:]]*" d "[[:space:]]*$"
      inhd = 1
    }
    print
  }' | sed -E "s/'[^']*'/''/g" | sed -E 's/"[^"]*"/""/g')

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
