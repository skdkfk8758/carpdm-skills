#!/usr/bin/env bash
# Install the carpdm-skills bundle into ~/.claude/.
# Skills (dir-per-skill) -> ~/.claude/skills/
# Shared reference material -> ~/.claude/references/craft/  (skills read it by absolute path)
# Idempotent: existing same-named skills are overwritten in place
# (git history is the safety net — no .bak files left behind). Safe to re-run.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$ROOT/skills"
DEST_DIR="$HOME/.claude/skills"
REF_SRC="$ROOT/global/references/craft"
REF_DEST="$HOME/.claude/references/craft"

mkdir -p "$DEST_DIR"

echo "Installing skills from: $SRC_DIR"
echo "                   into: $DEST_DIR"
echo

installed=()
for skill in "$SRC_DIR"/*/; do
  name="$(basename "$skill")"
  target="$DEST_DIR/$name"
  if [ -e "$target" ]; then
    rm -rf "$target"
    echo "  ~ $name  (replaced)"
  else
    echo "  + $name"
  fi
  cp -R "$skill" "$target"
  installed+=("$name")
done

# Shared references. Several skills read ~/.claude/references/craft/*.md by absolute
# path — installing skills without these leaves them pointing at nothing.
if [ -d "$REF_SRC" ]; then
  mkdir -p "$REF_DEST"
  cp -R "$REF_SRC"/. "$REF_DEST"/
  echo
  echo "  + references/craft  ($(ls -1 "$REF_DEST" | wc -l | tr -d ' ') files -> $REF_DEST)"
fi

echo
# Derive the summary from what was actually installed - a hardcoded list drifts.
echo "Done. Installed ${#installed[@]} skills: ${installed[*]}."
echo "Restart Claude Code (or start a new session) to load them."
echo
echo "Note: implementation/fix work is done by the main agent (plan mode -> build ->"
echo "'/code-review', '/security-review' when security-sensitive). Shared reference"
echo "material lives in ~/.claude/references/craft/. See README.md."
