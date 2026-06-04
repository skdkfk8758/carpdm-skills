#!/usr/bin/env bash
# Install the carpdm-skills bundle into ~/.claude/.
# Skills (dir-per-skill) -> ~/.claude/skills/; agents (flat .md files) -> ~/.claude/agents/.
# Idempotent: existing same-named artifacts are backed up to <name>.bak-<timestamp>
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

# Agents are flat .md files (one per agent), not dir-per-artifact like skills.
SRC_AGENTS="$(dirname "$SRC_DIR")/agents"
DEST_AGENTS="$HOME/.claude/agents"
agent_count=0
if [ -d "$SRC_AGENTS" ]; then
  echo
  echo "Installing agents from: $SRC_AGENTS"
  echo "                   into: $DEST_AGENTS"
  mkdir -p "$DEST_AGENTS"
  for f in "$SRC_AGENTS"/*.md; do
    [ -e "$f" ] || continue
    name="$(basename "$f")"
    target="$DEST_AGENTS/$name"
    if [ -e "$target" ]; then
      mv "$target" "$target.bak-$TS"
      echo "  ~ $name  (existing backed up -> $name.bak-$TS)"
    else
      echo "  + $name"
    fi
    cp "$f" "$target"
    agent_count=$((agent_count + 1))
  done
fi

echo
echo "Done. Installed skills: forge, hunt, renew, deep-interview, deep-plan, deep-prompt, handoff, sweep, land, summon, imprint, craft-core."
echo "      Installed agents: $agent_count (executor, code-reviewer, test-engineer, security-reviewer, explore, debugger)."
echo "Restart Claude Code (or start a new session) to load them."
echo
echo "Note: the forge/hunt/renew pipeline uses the 'codex:rescue'"
echo "plugin for its adversarial plan-review phase. If it is not installed,"
echo "that phase falls back to manual review. See README.md."
