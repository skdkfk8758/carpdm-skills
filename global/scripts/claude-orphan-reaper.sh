#!/bin/bash
# claude-orphan-reaper — reap orphaned Claude Code MCP/plugin node servers.
#
# When a `claude` CLI session dies, the stdio MCP/plugin node servers it spawned
# get reparented to launchd (ppid=1) and linger forever, leaking memory.
#
# SAFETY: only targets ppid==1 node processes that are plugin/MCP stdio servers
# (path under .claude/plugins/cache OR an npx MCP cache). Never touches:
#   - live sessions (ppid != 1)
#   - the claude daemon (`claude daemon run`)
#   - bg-pty-host
# Idempotent. Logs every run.

set -u
LOG_DIR="$HOME/.claude/logs"
LOG="$LOG_DIR/orphan-reaper.log"
mkdir -p "$LOG_DIR"
now="$(date '+%Y-%m-%d %H:%M:%S')"

reaped=0
# Emit "pid<TAB>command" for every ppid==1 (orphaned) process.
while IFS=$'\t' read -r pid cmd; do
  # must be an MCP/plugin stdio node server
  case "$cmd" in
    *"/.claude/plugins/cache/"*|*"/_npx/"*mcp*|*"/_npx/"*"@playwright/mcp"*) : ;;
    *) continue ;;
  esac
  # must be a node process
  case "$cmd" in *"/node "*|*"/node") : ;; *) continue ;; esac
  # never the daemon or pty host (defensive; they don't match above anyway)
  case "$cmd" in *" daemon "*|*"bg-pty-host"*) continue ;; esac
  kill -TERM "$pid" 2>/dev/null && reaped=$((reaped + 1))
done < <(ps axo pid=,ppid=,command= | awk '$2==1 { pid=$1; $1=""; $2=""; sub(/^ +/,""); print pid"\t"$0 }')

# KILL fallback for any orphan that ignored TERM.
if [ "$reaped" -gt 0 ]; then
  sleep 2
  ps axo pid=,ppid=,command= \
    | awk '$2==1 && /\.claude\/plugins\/cache/ && /node/ {print $1}' \
    | while read -r p; do kill -KILL "$p" 2>/dev/null; done
fi

echo "$now reaped=$reaped orphan MCP/plugin node servers" >> "$LOG"
