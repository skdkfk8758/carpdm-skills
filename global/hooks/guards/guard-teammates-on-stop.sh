#!/usr/bin/env bash
# Stop hook — BLOCKING ONCE (exit 2) when the lead session tries to end its turn
# while named teammates are still alive in the session team.
#
# Why: a worker spawned with Agent(name: …) is an in-process teammate and lives
# until the session ends. There is no auto-shutdown setting, and SubagentStop
# does NOT fire for teammates, so an abandoned teammate is invisible in the
# ledger and keeps burning its context. The only shutdown channel is
# SendMessage(to: <name>, message: {"type":"shutdown_request", "reason": …}).
#
# Team state (measured 2026-09-09, Claude Code 2.1.266):
#   ~/.claude/teams/session-<session_id first 8 chars>/config.json
#   {"name","createdAt","leadAgentId","leadSessionId","members":[{agentId,name,agentType,…}]}
#   The lead itself is the member with agentType == "team-lead".
#   After a shutdown_request the member disappears from `members`, so
#   (members - lead) is exactly the count of live teammates.
#
# Posture: ONE nudge, not a wall. `stop_hook_active` is true when the harness is
# already continuing the model because of a Stop hook — passing through then
# means the model can state a reason and stop on its second attempt. Anonymous
# background workers (no `name`) are never in `members`, so they never trip this.
#
#   Disable: TEAMMATE_GUARD_DISABLE=1

[ "${TEAMMATE_GUARD_DISABLE:-0}" = "1" ] && exit 0

INPUT=$(cat 2>/dev/null)

# Bail out before any parsing work if the harness is already re-running us.
case "$INPUT" in
  *'"stop_hook_active"'*)
    ACTIVE=$(printf '%s' "$INPUT" | grep -o '"stop_hook_active"[[:space:]]*:[[:space:]]*[a-z]*' | head -1 | sed 's/.*:[[:space:]]*//')
    [ "$ACTIVE" = "true" ] && exit 0
    ;;
esac

SID=$(printf '%s' "$INPUT" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:[[:space:]]*"//; s/"$//')
[ -z "$SID" ] && exit 0

CFG="$HOME/.claude/teams/session-${SID:0:8}/config.json"
[ -f "$CFG" ] || exit 0

command -v python3 >/dev/null 2>&1 || exit 0

# Any parse failure prints nothing and yields an empty list -> pass.
NAMES=$(python3 - "$CFG" <<'PY' 2>/dev/null
import json, sys
try:
    with open(sys.argv[1]) as f:
        cfg = json.load(f)
    out = []
    for m in cfg.get("members") or []:
        if not isinstance(m, dict):
            continue
        if m.get("agentType") == "team-lead":
            continue
        out.append(str(m.get("name") or m.get("agentId") or "?"))
    print("\n".join(out))
except Exception:
    pass
PY
)

[ -z "$NAMES" ] && exit 0

COUNT=$(printf '%s\n' "$NAMES" | grep -c .)
LIST=$(printf '%s\n' "$NAMES" | paste -sd ', ' - 2>/dev/null)
[ -z "$LIST" ] && LIST=$(printf '%s' "$NAMES" | tr '\n' ' ')

echo "[teammate-guard] 남은 팀메이트 ${COUNT}개: ${LIST}" >&2
echo "  · 쓸모를 다했으면 종료한다 — SendMessage(to: <이름>, message: {\"type\":\"shutdown_request\",\"reason\":\"<한 줄 사유>\"})" >&2
echo "  · 아직 실행 중인 background 워커가 필요 없어졌으면 TaskStop 으로 멈춘다" >&2
echo "  · 정말 계속 살려둬야 하면 이유를 한 줄 적어라 — 다음 정지 시도는 그대로 통과된다 (끄기: TEAMMATE_GUARD_DISABLE=1)" >&2
exit 2
