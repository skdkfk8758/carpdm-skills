#!/usr/bin/env bash
# Shared helper for advisory (non-blocking) guards: deliver a nudge to the MODEL.
#
# Why: exit 0 + stderr from PreToolUse/PostToolUse/Stop lands in the transcript
# and debug log only — the model never sees it (measured 2026-09-11: 9 advisory
# guards fired 178 times in 7 days, 0 reached the model). JSON on stdout with
# hookSpecificOutput.additionalContext is what gets injected into the next call.
#
# Usage (message on stdin; empty input prints nothing):
#   . "$(dirname "${BASH_SOURCE[0]}")/lib-emit-context.sh"
#   printf '%s\n' "line 1" "line 2" | emit_context PostToolUse
#
#   once_per "<key>" || exit 0   # cap a nudge to one fire per key (per TMPDIR)

emit_context() { # $1 = hookEventName
  python3 -c 'import json, sys
msg = sys.stdin.read().rstrip("\n")
if msg:
    print(json.dumps({"hookSpecificOutput": {"hookEventName": sys.argv[1],
                      "additionalContext": msg}}, ensure_ascii=False))' "$1"
}

once_per() { # $1 = dedup key; returns 1 when the key already fired
  local k m
  k=$(printf '%s' "$1" | shasum 2>/dev/null | cut -c1-16)
  m="${TMPDIR:-/tmp}/cc-nudge-once.${k:-fallback}"
  [ -f "$m" ] && return 1
  : > "$m"
  return 0
}

hook_sid() { # $1 = hook stdin JSON -> session_id or "nosid"
  local s
  s=$(printf '%s' "$1" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 \
    | sed 's/.*:[[:space:]]*"//; s/"$//')
  printf '%s' "${s:-nosid}"
}
