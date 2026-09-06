#!/usr/bin/env bash
# PreToolUse hook (Bash): BLOCK commands that dump live secrets into the
# transcript. BLOCKING — exit 2 (guard-destructive-cmd pattern).
#
# Why: measured incidents — a Cloudflare Access service token (`cfast_`) and an
# sglang `--api-key` were printed raw by `docker inspect` / env dumps and had to
# be revoked and rotated. A leak is irreversible: once the value is in the
# transcript it is compromised, so PostToolUse is too late. This must be a
# PreToolUse block, not a nudge.
#
# Fires on the dump commands themselves:
#   docker inspect / docker service inspect
#   kubectl|k get secret ... -o yaml|json|jsonpath   (also `describe secret`)
#   bare `env` / `printenv` with no argument
#   terraform|tofu output   (without -json piped through a mask)
#
# Passes through when the command already routes output to a masker
# (sed/awk/mask/redact/jq with a masking del/gsub) or to a file.
#
# Config:
#   GUARD_SECRET_ECHO_DISABLE=1  — turn off (per-command escape hatch)

[ "${GUARD_SECRET_ECHO_DISABLE:-0}" = "1" ] && exit 0

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | python3 -c 'import json,sys
try:
    p=json.loads(sys.stdin.read() or "{}")
    print((p.get("tool_input") or {}).get("command") or "")
except Exception:
    print("")
' 2>/dev/null)

[ -z "$CMD" ] && exit 0

GREP=/usr/bin/grep
[ -x "$GREP" ] || GREP=grep

# Blank out quoted strings so `echo "run docker inspect later"` does not trip.
SANITIZED=$(printf '%s' "$CMD" | sed -E "s/'[^']*'/''/g" | sed -E 's/"[^"]*"/""/g')

HIT=""
echo "$SANITIZED" | $GREP -qE '(^|[|;&[:space:]])docker([[:space:]]+[a-z]+)?[[:space:]]+inspect([[:space:]]|$)' && HIT="docker inspect"
echo "$SANITIZED" | $GREP -qE '(kubectl|[[:space:]]k)[[:space:]]+(get|describe)[[:space:]]+(secret|secrets)([[:space:]]|$)' && HIT="kubectl get secret"
echo "$SANITIZED" | $GREP -qE '(^|[|;&[:space:]])(env|printenv)[[:space:]]*($|[|;&])' && HIT="env dump"
echo "$SANITIZED" | $GREP -qE '(^|[|;&[:space:]])(terraform|tofu)[[:space:]]+output([[:space:]]|$)' && HIT="terraform output"

[ -z "$HIT" ] && exit 0

# Already masked or redirected to a file? Let it through.
echo "$SANITIZED" | $GREP -qE '\|[[:space:]]*(sed|awk|perl)|mask|redact|>[[:space:]]*[^|&[:space:]]+' && exit 0

cat >&2 <<EOF
[guard-secret-echo] 차단: \`$HIT\` 은 실 시크릿을 트랜스크립트에 그대로 뱉는다.
유출은 비가역이다 — 값이 한 번 찍히면 로테이션 외에 되돌릴 방법이 없다(실사고 2회: cfast_ 토큰, sglang --api-key).
→ 필요한 필드만 뽑거나 마스크를 통과시킨다:
   docker inspect <c> --format '{{.Config.Image}}'
   kubectl get secret <s> -o jsonpath='{.data}' | sed -E 's/[A-Za-z0-9+\/=]{16,}/***/g'
   <명령> | sed -E 's/(cfast_|sk-|ghp_|glpat-|AKIA)[A-Za-z0-9_-]+/***/g'
값 자체가 정말 필요하면: GUARD_SECRET_ECHO_DISABLE=1 <명령>
EOF
exit 2
