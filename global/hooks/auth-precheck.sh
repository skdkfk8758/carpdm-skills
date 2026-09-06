#!/usr/bin/env bash
# SessionStart hook: report MISSING credentials up front, before 40 turns of
# work hit a wall. Local file/env checks only — no network calls, so it costs
# ~10ms and never stalls session start.
#
# Why: measured pattern — sessions stalled mid-flight on unauthenticated glab
# (an MR could not be opened after the branch was already pushed), on expired
# AWS SSO, and on missing Cloudflare Access tokens. Every one of those is
# knowable at t=0 from local state.
#
# Silent when everything present — only missing/expired items are injected.
#
# Config:
#   AUTH_PRECHECK_DISABLE=1  — turn off

[ "${AUTH_PRECHECK_DISABLE:-0}" = "1" ] && { printf '{}\n'; exit 0; }

miss=""
add(){ miss="${miss}- $1
"; }

# gh (GitHub)
[ -s "$HOME/.config/gh/hosts.yml" ] || [ -n "${GH_TOKEN:-}${GITHUB_TOKEN:-}" ] \
  || add 'gh: 미인증 — `gh auth login` (GITHUB_TOKEN 도 없음)'

# glab (GitLab)
[ -s "$HOME/.config/glab-cli/config.yml" ] || [ -n "${GITLAB_TOKEN:-}${GLAB_TOKEN:-}" ] \
  || add 'glab: 미인증 — `glab auth login` 또는 GITLAB_TOKEN (MR 생성이 막힌다)'

# AWS — static creds, or an SSO cache token that has not expired yet.
aws_ok=0
[ -s "$HOME/.aws/credentials" ] && aws_ok=1
[ -n "${AWS_ACCESS_KEY_ID:-}${AWS_PROFILE:-}" ] && aws_ok=1
if [ "$aws_ok" = 1 ] && [ -d "$HOME/.aws/sso/cache" ]; then
  exp=$(python3 - <<'PY' 2>/dev/null
import glob, json, datetime, sys
best = ""
for f in glob.glob(__import__("os").path.expanduser("~/.aws/sso/cache/*.json")):
    try:
        e = json.load(open(f)).get("expiresAt", "")
    except Exception:
        continue
    if e > best:
        best = e
if best:
    now = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    print("EXPIRED" if best < now else "OK")
PY
)
  [ "$exp" = "EXPIRED" ] && add 'AWS SSO: 토큰 만료 — `aws sso login` 먼저'
fi
[ "$aws_ok" = 1 ] || add 'AWS: 자격증명 없음 — ~/.aws/credentials·AWS_PROFILE·AWS_ACCESS_KEY_ID 전부 비어 있다'

# Cloudflare Access — only flagged when cloudflared is actually installed here.
if command -v cloudflared >/dev/null 2>&1; then
  [ -n "${CF_ACCESS_CLIENT_ID:-}${CLOUDFLARE_API_TOKEN:-}" ] || [ -d "$HOME/.cloudflared" ] \
    || add 'Cloudflare Access: 서비스 토큰 없음 — CF_ACCESS_CLIENT_ID/SECRET'
fi

[ -z "$miss" ] && { printf '{}\n'; exit 0; }

python3 - "$miss" <<'PY'
import json, sys
ctx = ("[auth-precheck] 아래 자격증명이 지금 없다. 이걸 쓰는 작업(PR/MR 생성, 배포, "
       "클러스터 조회)에 들어가기 전에 먼저 해결하거나 사용자에게 알린다 — "
       "40턴 들어가서 막히지 말 것.\n" + sys.argv[1] +
       "무관한 작업이면 무시. 끄기: AUTH_PRECHECK_DISABLE=1")
print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart",
                                         "additionalContext": ctx}}))
PY
exit 0
