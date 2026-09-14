#!/usr/bin/env bash
# SubagentStop hook — append one JSON line per finished subagent to
# ~/.claude/ledger/delegations.jsonl so delegation cost/mix is observable.
#
# NON-BLOCKING BY CONSTRUCTION: always exits 0, whatever the input. A broken
# ledger must never stop a session. All parsing happens in python3 inside a
# try/except; any failure is swallowed.
#
# SubagentStop payload keys (measured 2026-09-09, Claude Code 2.1.266):
#   session_id transcript_path cwd scratchpad_dir permission_mode
#   agent_id agent_type agent_transcript_path last_assistant_message
#   hook_event_name stop_hook_active background_tasks session_crons
# The subagent's meta.json sits beside its transcript:
#   <agent_transcript_path minus .jsonl>.meta.json
#   -> {"agentType","description","toolUseId","spawnDepth","model", ...}
# `model` there is an alias ("haiku"); the jsonl carries the full id
# ("claude-haiku-4-5-20251001").
#
# NOTE: the payload arrives via the INPUT_JSON env var, not a pipe — the
# heredoc that carries this python script already owns python's stdin.
#
# Read with: ~/.claude/bin/ledger-summary.sh [days]
# Debug: `touch /tmp/fable-gate-debug` to dump payloads to /tmp/fable-gate-debug.log

INPUT=$(cat 2>/dev/null)
[ -f /tmp/fable-gate-debug ] && printf '=== SubagentStop ===\n%s\n---\n' "$INPUT" >> /tmp/fable-gate-debug.log 2>/dev/null

INPUT_JSON="$INPUT" python3 - <<'PY' 2>/dev/null
import json, os, datetime

def main():
    raw = os.environ.get("INPUT_JSON", "")
    p = json.loads(raw) if raw.strip() else {}
    if not isinstance(p, dict):
        p = {}

    def g(*keys):
        for k in keys:
            v = p.get(k)
            if isinstance(v, str) and v:
                return v
        return None

    sid, aid, cwd = g("session_id"), g("agent_id", "subagent_id"), g("cwd")
    tp = g("transcript_path")
    # Nothing identifies this run (empty/garbage payload) — write no noise row.
    if not sid and not aid:
        return

    # Locate the subagent's own transcript + meta.
    sub_tp = g("agent_transcript_path", "subagent_transcript_path")
    if not sub_tp and tp and aid:
        base = (tp[:-6] if tp.endswith(".jsonl") else tp)
        sub_tp = os.path.join(base, "subagents", f"agent-{aid}.jsonl")
    meta_path = g("agent_meta_path")
    if not meta_path and sub_tp:
        meta_path = (sub_tp[:-6] if sub_tp.endswith(".jsonl") else sub_tp) + ".meta.json"

    meta = {}
    if meta_path and os.path.isfile(meta_path):
        try:
            meta = json.load(open(meta_path)) or {}
        except Exception:
            meta = {}

    agent_type = meta.get("agentType") or g("agent_type", "subagent_type")
    model = meta.get("model")
    if model in ("inherit", "default", "", None):
        model = None
    description = meta.get("description") or g("description")

    def scan(path):
        """Assistant lines are split per content block and share one message.id,
        so usage is counted once per id and tool calls once per tool_use id."""
        model_id = first = last = None
        tool_ids, seen_msgs = set(), set()
        itok = otok = 0
        seen_usage = False
        if not path or not os.path.isfile(path):
            return None, None, None, 0, None, None
        with open(path, errors="replace") as fh:
            for line in fh:
                try:
                    o = json.loads(line)
                except Exception:
                    continue
                t = o.get("timestamp")
                if isinstance(t, str):
                    if first is None:
                        first = t
                    last = t
                if o.get("type") != "assistant":
                    continue
                msg = o.get("message") if isinstance(o.get("message"), dict) else {}
                mm = o.get("model") or msg.get("model")
                if isinstance(mm, str) and mm:
                    model_id = mm
                for b in (msg.get("content") or []):
                    if isinstance(b, dict) and b.get("type") == "tool_use":
                        tool_ids.add(b.get("id") or len(tool_ids))
                mid = msg.get("id")
                if mid in seen_msgs:
                    continue
                if mid:
                    seen_msgs.add(mid)
                u = msg.get("usage") if isinstance(msg.get("usage"), dict) else o.get("usage")
                if isinstance(u, dict):
                    seen_usage = True
                    itok += (u.get("input_tokens") or 0) \
                        + (u.get("cache_read_input_tokens") or 0) \
                        + (u.get("cache_creation_input_tokens") or 0)
                    otok += u.get("output_tokens") or 0
        return model_id, first, last, len(tool_ids), \
            (itok if seen_usage else None), (otok if seen_usage else None)

    model_id, t0, t1, tools, itok, otok = scan(sub_tp)
    model = model or model_id

    def parse_ts(s):
        try:
            return datetime.datetime.fromisoformat((s or "").replace("Z", "+00:00"))
        except Exception:
            return None
    a, b = parse_ts(t0), parse_ts(t1)
    duration = round((b - a).total_seconds(), 1) if (a and b) else None

    parent_model = None
    if tp and os.path.isfile(tp):
        try:
            with open(tp, errors="replace") as fh:
                for line in fh:
                    if '"assistant"' not in line:
                        continue
                    try:
                        o = json.loads(line)
                    except Exception:
                        continue
                    if o.get("type") != "assistant":
                        continue
                    msg = o.get("message") if isinstance(o.get("message"), dict) else {}
                    mm = o.get("model") or msg.get("model")
                    if isinstance(mm, str) and mm:
                        parent_model = mm
        except Exception:
            pass

    rec = {
        "ts": datetime.datetime.now().astimezone().isoformat(timespec="seconds"),
        "session_id": sid, "agent_id": aid, "agent_type": agent_type,
        "model": model, "model_id": model_id, "description": description,
        "cwd": cwd, "parent_model": parent_model, "duration_s": duration,
        "tool_calls": tools or None, "input_tokens": itok, "output_tokens": otok,
    }
    d = os.path.join(os.path.expanduser("~"), ".claude", "ledger")
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, "delegations.jsonl"), "a") as fh:
        fh.write(json.dumps(rec, ensure_ascii=False) + "\n")

try:
    main()
except Exception:
    pass
PY

exit 0
