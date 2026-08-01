#!/usr/bin/env bash
# UserPromptSubmit hook: auto-transition a Linear issue to In Progress when the
# prompt carries an Orca-injected banner ("Linked Linear issue: <ID>").
#
# Why: the banner is plain prompt text (measured — Orca prepends worktree
# metadata to the first prompt), so no session-start automation ever fires.
# This hook closes that gap deterministically via the Linear GraphQL API,
# without depending on the model calling save_issue.
#
# Safety contract:
#   - NON-BLOCKING: always exit 0; failures go to a log file only.
#   - No downgrade: transitions ONLY when current state type is
#     triage/backlog/unstarted. In Progress/In Review/Done are left alone.
#   - Dedup: one API attempt per (session, issue) via a marker file.
#
# Key resolution: $LINEAR_API_KEY, else ~/.claude/secrets/linear-api-key.
# Disable: LINEAR_AUTOSTART_DISABLE=1

[ "${LINEAR_AUTOSTART_DISABLE:-0}" = "1" ] && exit 0

# Heredoc occupies python's stdin, so the hook payload must travel via env.
HOOK_PAYLOAD=$(cat) || HOOK_PAYLOAD="{}"
export HOOK_PAYLOAD

exec python3 - <<'PYEOF'
import json, os, re, sys, urllib.request

LOG_DIR = os.path.expanduser("~/.claude/logs/linear-autostart")
API = "https://api.linear.app/graphql"

def log(msg):
    try:
        os.makedirs(LOG_DIR, exist_ok=True)
        with open(os.path.join(LOG_DIR, "hook.log"), "a") as f:
            f.write(msg + "\n")
    except Exception:
        pass

try:
    payload = json.loads(os.environ.get("HOOK_PAYLOAD") or "{}")
except Exception:
    sys.exit(0)

prompt = payload.get("prompt") or ""
session_id = payload.get("session_id") or "nosession"

m = re.search(r"Linked Linear issue:\s*([A-Za-z][A-Za-z0-9]{1,9}-\d+)", prompt)
if not m:
    sys.exit(0)
issue_id = m.group(1).upper()

# Dedup: one attempt per (session, issue)
marker = os.path.join(LOG_DIR, f"{session_id}-{issue_id}.done")
if os.path.exists(marker):
    sys.exit(0)

key = os.environ.get("LINEAR_API_KEY", "")
if not key:
    key_file = os.path.expanduser("~/.claude/secrets/linear-api-key")
    try:
        key = open(key_file).read().strip()
    except Exception:
        log(f"{issue_id}: no API key (env LINEAR_API_KEY / {key_file})")
        sys.exit(0)

def gql(query, variables=None):
    body = json.dumps({"query": query, "variables": variables or {}}).encode()
    req = urllib.request.Request(
        API, data=body,
        headers={"Content-Type": "application/json", "Authorization": key},
    )
    with urllib.request.urlopen(req, timeout=5) as r:
        out = json.loads(r.read())
    if out.get("errors"):
        raise RuntimeError(json.dumps(out["errors"])[:300])
    return out["data"]

try:
    data = gql(
        """query($id: String!) {
             issue(id: $id) {
               id
               state { name type }
               team { states { nodes { id name type position } } }
             }
           }""",
        {"id": issue_id},
    )
    issue = data["issue"]
    cur = issue["state"]

    # Mark attempted regardless of outcome — one shot per session.
    os.makedirs(LOG_DIR, exist_ok=True)
    open(marker, "w").close()

    if cur["type"] not in ("triage", "backlog", "unstarted"):
        log(f"{issue_id}: skip — already '{cur['name']}' ({cur['type']})")
        sys.exit(0)

    started = [s for s in issue["team"]["states"]["nodes"] if s["type"] == "started"]
    if not started:
        log(f"{issue_id}: no 'started' state on team")
        sys.exit(0)
    # Prefer a state literally named "In Progress", else lowest position.
    target = next(
        (s for s in started if s["name"].lower() == "in progress"),
        sorted(started, key=lambda s: s["position"])[0],
    )

    gql(
        """mutation($id: String!, $stateId: String!) {
             issueUpdate(id: $id, input: { stateId: $stateId }) { success }
           }""",
        {"id": issue["id"], "stateId": target["id"]},
    )
    # stdout is added to conversation context — inform Claude + user.
    print(f"[linear-autostart] {issue_id}: '{cur['name']}' → '{target['name']}' 자동 전이 완료")
    log(f"{issue_id}: {cur['name']} -> {target['name']} OK")
except Exception as e:
    log(f"{issue_id}: FAIL {e}")
sys.exit(0)
PYEOF
