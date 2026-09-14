#!/usr/bin/env bash
# Resets the per-step file budget kept by guard-step-scope.sh.
#
# Wired to two events, both of which mean "the user approved the next step":
#   UserPromptSubmit          — a new user turn
#   PostToolUse AskUserQuestion — the user answered a step-boundary question
#
# Truncates instead of deleting: `rm -f` on a $TMPDIR path can trip the
# destructive-command guard, and an empty file counts as zero either way.
# Always exits 0 — a reset must never block anything.

INPUT=$(cat)

FIELDS=$(printf '%s' "$INPUT" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    d = {}
if not isinstance(d, dict):
    d = {}
vals = [d.get("session_id") or "nosid", d.get("tool_name") or ""]
sys.stdout.write("\x1f".join(str(v).replace("\x1f", " ").replace("\n", " ") for v in vals))
' 2>/dev/null)

IFS=$'\037' read -r SID TOOL <<EOF
$FIELDS
EOF
[ -z "$SID" ] && SID="nosid"

# PostToolUse fires for every tool; only an AskUserQuestion answer is a boundary.
# UserPromptSubmit carries no tool_name, so an empty value falls through.
if [ -n "$TOOL" ] && [ "$TOOL" != "AskUserQuestion" ]; then
  exit 0
fi

TMPD="${TMPDIR:-/tmp}"
TMPD="${TMPD%/}"
SAFE_SID=$(printf '%s' "$SID" | tr -c 'A-Za-z0-9._-' '_')
: > "$TMPD/cc-step-scope.${SAFE_SID}" 2>/dev/null

exit 0
