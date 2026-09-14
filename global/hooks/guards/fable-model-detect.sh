#!/usr/bin/env bash
# Shared helper: detect the model driving the CURRENT session.
#
# Usage:  MODEL=$(printf '%s' "$INPUT" | bash fable-model-detect.sh)
#         printf '%s' "$INPUT" | bash fable-model-detect.sh --is-fable && echo yes
#
# Resolution order (first non-empty wins):
#   1. hook stdin JSON top-level `model` (if the harness provides one — never tool_input.model)
#   1b. agent definition — for a named-agent subagent whose meta.json has no
#                         usable `model`, ~/.claude/agents/<agentType>.md
#   2. transcript_path  — last assistant message's `model` (actual model in use;
#                         survives in-session /model switches)
#   3. ~/.claude/settings.json `model` (saved default; last resort)
#
# --is-fable exits 0 when the resolved model id contains "fable"
# (e.g. claude-fable-5-1, claude-fable-5-1[1m]), 1 otherwise.
# --with-source prints "<model>\t<source>" where source is one of
#   stdin | subagent | transcript | settings | none.
#   "settings" means no session evidence existed (typical on the very first
#   UserPromptSubmit of a session, before any assistant turn) — callers that
#   inject instructions should treat that as weak evidence, or a
#   `claude -p --model sonnet` session gets Fable instructions.

INPUT=$(cat)
MODE="${1:-}"

json_str() { # $1=json $2=key -> value or empty
  printf '%s' "$1" | grep -o "\"$2\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 \
    | sed 's/.*:[[:space:]]*"//; s/"$//'
}

# $1 = agent name -> `model:` from ~/.claude/agents/<name>.md frontmatter, or empty.
# Path characters are refused so a crafted subagent_type cannot escape the dir.
agent_def_model() {
  case "$1" in
    ""|*/*|*..*|.*) return ;;
  esac
  ADF="$HOME/.claude/agents/$1.md"
  [ -f "$ADF" ] || return
  sed -n '/^---$/,/^---$/p' "$ADF" 2>/dev/null | grep -m1 '^model:' \
    | sed 's/^model:[[:space:]]*//; s/[[:space:]]*$//'
}

SOURCE=none
# Top-level `model` only. The old flat grep also matched tool_input.model — the
# WORKER model of an Agent call — and judged an Opus session Fable (2026-09-11).
MODEL=$(printf '%s' "$INPUT" | python3 -c 'import json, sys
try:
    m = json.load(sys.stdin).get("model")
except Exception:
    m = None
if isinstance(m, dict):
    m = m.get("id")
print(m if isinstance(m, str) else "")' 2>/dev/null)
[ -n "$MODEL" ] && SOURCE=stdin

# Subagent calls carry the PARENT session's transcript_path plus an agent_id.
# Resolve the subagent's own model first, or a sonnet/haiku worker spawned from
# a Fable session would be judged as Fable and blocked.
#   <transcript_dir>/<session_id>/subagents/agent-<agent_id>.meta.json  {"model":"haiku"}
#   <transcript_dir>/<session_id>/subagents/agent-<agent_id>.jsonl      assistant lines
if [ -z "$MODEL" ]; then
  AID=$(json_str "$INPUT" agent_id)
  TP=$(json_str "$INPUT" transcript_path)
  if [ -n "$AID" ] && [ -n "$TP" ]; then
    SUBDIR="${TP%.jsonl}/subagents"
    META="$SUBDIR/agent-$AID.meta.json"
    SUBTP="$SUBDIR/agent-$AID.jsonl"
    [ -f "$META" ] && MODEL=$(json_str "$(cat "$META")" model)
    case "$MODEL" in
      ""|inherit|default) MODEL="" ;;
    esac
    # 1b. Named agents record agentType; their `model` may be absent or "inherit".
    # Resolve from the agent definition BEFORE falling back to the subagent
    # jsonl, which is still empty on the worker's very first tool call — without
    # this a named worker would be judged as the parent (Fable) and blocked.
    if [ -z "$MODEL" ] && [ -f "$META" ]; then
      MODEL=$(agent_def_model "$(json_str "$(cat "$META")" agentType)")
    fi
    if [ -z "$MODEL" ] && [ -f "$SUBTP" ]; then
      MODEL=$(tail -c 400000 "$SUBTP" 2>/dev/null \
        | grep '"type":"assistant"' | grep -o '"model":"[^"]*"' | tail -1 \
        | sed 's/^"model":"//; s/"$//')
    fi
    [ -n "$MODEL" ] && SOURCE=subagent
  fi
fi

if [ -z "$MODEL" ]; then
  TP=$(json_str "$INPUT" transcript_path)
  if [ -n "$TP" ] && [ -f "$TP" ]; then
    # Tail only — transcripts can be tens of MB. Assistant lines carry
    # "type":"assistant" ... "model":"claude-xxx".
    MODEL=$(tail -c 400000 "$TP" 2>/dev/null \
      | grep '"type":"assistant"' | grep -o '"model":"[^"]*"' | tail -1 \
      | sed 's/^"model":"//; s/"$//')
    [ -n "$MODEL" ] && SOURCE=transcript
  fi
fi

if [ -z "$MODEL" ] && [ -f "$HOME/.claude/settings.json" ]; then
  MODEL=$(json_str "$(cat "$HOME/.claude/settings.json")" model)
  [ -n "$MODEL" ] && SOURCE=settings
fi

if [ "$MODE" = "--is-fable" ]; then
  case "$MODEL" in
    *fable*) exit 0 ;;
    *) exit 1 ;;
  esac
fi

if [ "$MODE" = "--with-source" ]; then
  printf '%s\t%s\n' "$MODEL" "$SOURCE"
  exit 0
fi

printf '%s\n' "$MODEL"
