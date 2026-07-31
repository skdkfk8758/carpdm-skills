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

echo
# Derive the summary from what was actually installed - a hardcoded list drifts.
echo "Done. Installed ${#installed[@]} skills: ${installed[*]}."
echo "Restart Claude Code (or start a new session) to load them."
echo
echo "Note: the forge/hunt/renew Phase 4 correctness review uses '/code-review'."
echo "If it is unavailable, that phase falls back to an adversarial subagent"
echo "(craft-core/references/adversarial-review.md). See README.md."
