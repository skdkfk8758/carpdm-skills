#!/usr/bin/env bash
# PreToolUse hook (Edit|Write|NotebookEdit): BLOCKING cap on how many distinct
# files one step may touch. A "step" is bounded by user input — UserPromptSubmit
# and an AskUserQuestion answer both reset the counter (guard-step-scope-reset.sh),
# because either one is the user approving the next step.
#
# Why blocking: long unattended edit runs outrun the user's ability to review,
# and the rollback cost scales with the number of files changed since the last
# approval. Short breaths keep every step reviewable and revertable.
#
# State: ${TMPDIR:-/tmp}/cc-step-scope.<session_id> — one absolute path per line.
#
#   Disable:   GUARD_STEP_DISABLE=1
#   Limit:     GUARD_STEP_MAX_FILES (default 3)
#
# Exempt (never counted, never recorded):
#   - subagent calls (transcript_path contains /subagents/, or agent_id present)
#   - $HOME/.claude/**            harness config, not project work
#   - $TMPDIR/** and /private/tmp/claude-*   scratchpad
#   - a file already recorded in this step (re-edit is free)

INPUT=$(cat)

# (a) kill switch
[ "${GUARD_STEP_DISABLE:-0}" = "1" ] && exit 0

FIELDS=$(printf '%s' "$INPUT" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    d = {}
if not isinstance(d, dict):
    d = {}
ti = d.get("tool_input")
if not isinstance(ti, dict):
    ti = {}
vals = [d.get("session_id") or "nosid",
        d.get("transcript_path") or "",
        d.get("agent_id") or "",
        ti.get("file_path") or ""]
clean = [str(v).replace("\x1f", " ").replace("\n", " ") for v in vals]
sys.stdout.write("\x1f".join(clean))
' 2>/dev/null)

IFS=$'\037' read -r SID TP AID FP <<EOF
$FIELDS
EOF
[ -z "$SID" ] && SID="nosid"

# (b) subagents run their own budget; the main session's step cap does not apply.
case "$TP" in */subagents/*) exit 0 ;; esac
[ -n "$AID" ] && exit 0

[ -z "$FP" ] && exit 0

# (c) exempt paths — harness config and scratchpad are not step work.
TMPD="${TMPDIR:-/tmp}"
TMPD="${TMPD%/}"
case "$FP" in
  "$HOME/.claude/"*) exit 0 ;;
  "$TMPD"/*) exit 0 ;;
  /private/tmp/claude-*) exit 0 ;;
esac

SAFE_SID=$(printf '%s' "$SID" | tr -c 'A-Za-z0-9._-' '_')
STATE="$TMPD/cc-step-scope.${SAFE_SID}"

# (d) already touched in this step — free.
if [ -f "$STATE" ] && grep -Fxq "$FP" "$STATE" 2>/dev/null; then
  exit 0
fi

MAX="${GUARD_STEP_MAX_FILES:-3}"
COUNT=0
[ -f "$STATE" ] && COUNT=$(grep -c . "$STATE" 2>/dev/null | tr -d ' ')
[ -z "$COUNT" ] && COUNT=0

# (e) over the limit — block and hand the model the next move.
if [ "$COUNT" -ge "$MAX" ]; then
  LIST=$(tr '\n' ',' < "$STATE" | sed 's/,$//; s/,/, /g')
  printf '%s\n' "[step-scope] 이 스텝에서 이미 ${COUNT}개 파일을 편집했다(한도 ${MAX}): ${LIST}. $((COUNT + 1))개째(${FP})는 다음 스텝이다 — 지금까지 결과를 §A 로 보고하고 AskUserQuestion 으로 다음 스텝 확인을 받아라. 사용자 응답이 카운터를 리셋한다. 끄기: GUARD_STEP_DISABLE=1" >&2
  exit 2
fi

printf '%s\n' "$FP" >> "$STATE"
exit 0
