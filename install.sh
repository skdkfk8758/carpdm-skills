#!/usr/bin/env bash
# Install the carpdm-skills bundle into ~/.claude/skills/.
# Idempotent: existing same-named skills are backed up to <name>.bak-<timestamp>
# before being replaced. Safe to re-run.
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/skills" && pwd)"
DEST_DIR="$HOME/.claude/skills"
TS="$(date +%Y%m%d-%H%M%S)"

mkdir -p "$DEST_DIR"

echo "Installing skills from: $SRC_DIR"
echo "                   into: $DEST_DIR"
echo

for skill in "$SRC_DIR"/*/; do
  name="$(basename "$skill")"
  target="$DEST_DIR/$name"
  if [ -e "$target" ]; then
    backup="$target.bak-$TS"
    mv "$target" "$backup"
    echo "  ~ $name  (existing backed up -> $(basename "$backup"))"
  else
    echo "  + $name"
  fi
  cp -R "$skill" "$target"
done

echo
echo "Done. Installed: forge, hunt, renew, reshape, handoff, craft-core, sweep."
echo "Restart Claude Code (or start a new session) to load them."
echo
echo "Note: the forge/hunt/renew/reshape pipeline uses the 'codex:rescue'"
echo "plugin for its adversarial plan-review phase. If it is not installed,"
echo "that phase falls back to manual review. See README.md."
