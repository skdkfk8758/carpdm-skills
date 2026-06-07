#!/usr/bin/env bash
# Install the carpdm-skills bundle into ~/.claude/.
# Skills (dir-per-skill) -> ~/.claude/skills/.
# Idempotent: existing same-named skills are overwritten in place
# (git history is the safety net — no .bak files left behind). Safe to re-run.
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/skills" && pwd)"
DEST_DIR="$HOME/.claude/skills"

mkdir -p "$DEST_DIR"

echo "Installing skills from: $SRC_DIR"
echo "                   into: $DEST_DIR"
echo

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
done

echo
echo "Done. Installed skills: forge, hunt, renew, deep-interview, deep-plan, deep-prompt, handoff, sweep, land, imprint, craft-core."
echo "Restart Claude Code (or start a new session) to load them."
echo
echo "Note: the forge/hunt/renew pipeline uses the 'codex:rescue'"
echo "plugin for its adversarial plan-review phase. If it is not installed,"
echo "that phase falls back to manual review. See README.md."
