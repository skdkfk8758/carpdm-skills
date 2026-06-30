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
# Re-home hardcoded harness scriptPaths to THIS machine.
# The harness skills (harness-run/eval-generate/eval-check) pin CONCRETE absolute
# paths because a Workflow scriptPath must resolve cwd-independently (a relative
# '.claude/skills/...' would resolve against the project cwd, not the skills dir).
# The repo stores them under the maintainer's $HOME, so rewrite that prefix on
# install. No-op on the maintainer's own machine (prefix already == $HOME).
AUTHOR_HOME="/Users/carpdm"
if [ "$HOME" != "$AUTHOR_HOME" ]; then
  grep -rl "$AUTHOR_HOME/.claude/skills" "$DEST_DIR" 2>/dev/null | while read -r f; do
    sed "s#$AUTHOR_HOME/.claude/skills#$HOME/.claude/skills#g" "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    echo "  re-homed paths in ${f#"$DEST_DIR"/}"
  done
fi

# Derive the summary from what was actually installed - a hardcoded list drifts.
echo "Done. Installed ${#installed[@]} skills: ${installed[*]}."
echo "Restart Claude Code (or start a new session) to load them."
echo
echo "Note: the forge/hunt/renew pipeline uses the 'codex:rescue'"
echo "plugin for its adversarial plan-review phase. If it is not installed,"
echo "that phase falls back to manual review. See README.md."
