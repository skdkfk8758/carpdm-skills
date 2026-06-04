#!/usr/bin/env python3
"""real-env skill-trigger probe.

Measures, in the ACTUAL installed ~/.claude/skills/ environment (siblings
present), two things skill-creator's run_eval.py cannot — because it injects
one isolated command:

  (a) trigger accuracy  — does the target skill fire on should-trigger queries?
  (b) sibling competition — which OTHER skills intercept a query?

For each query it runs `claude -p --output-format stream-json` and captures
every skill that fired (Skill tool -> input.skill, Read tool -> skill name
normalized from the file path). Outcomes are classified into distinct states so
infrastructure failures (timeout/error/parse) are never silently counted as
"did not trigger" — the artifact that produced false 0/100 in the first place.

Standalone: no dependency on skill-creator. Parser logic is fixture-tested in
test_parser.py so a CLI schema drift surfaces as a test failure, not a false score.
"""
import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
from collections import Counter
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path

SKILL_PATH_RE = re.compile(r"/skills/([^/]+)/")

# Outcome states. The {error, timeout, parse_error} group is INVALID — excluded
# from accuracy / sibling stats and reported separately (B7).
INVALID_STATES = {"error", "timeout", "parse_error"}


# ---------- parser (fixture-tested contract — B1/B6) ----------

def normalize_skill(file_path):
    """Extract skill name from a Read file_path, or None if not a skill path."""
    m = SKILL_PATH_RE.search(file_path or "")
    return m.group(1) if m else None


def extract_triggered_skills(lines):
    """Return (triggered_skills, unknown_skill_events, parse_error).

    Reads full `assistant` events (input is complete there, unlike partial
    stream_event blocks). Every Skill/Read tool_use that resolves to a skill
    name is recorded in order — so sibling hijacks are visible, not collapsed.
    """
    triggered = []
    unknown = []
    parse_error = False
    for line in lines:
        line = line.strip()
        if not line:
            continue
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            parse_error = True
            continue
        if event.get("type") != "assistant":
            continue
        for c in event.get("message", {}).get("content", []):
            if c.get("type") != "tool_use":
                continue
            name = c.get("name")
            inp = c.get("input", {}) or {}
            if name == "Skill":
                skill = inp.get("skill")
                if skill:
                    triggered.append(skill)
                else:
                    unknown.append(c)
            elif name == "Read":
                skill = normalize_skill(inp.get("file_path", ""))
                if skill:
                    triggered.append(skill)
                # a Read of a non-skill file is not a trigger — ignore
    return triggered, unknown, parse_error


def classify_state(triggered, target):
    """Classify a successful run by which skills fired relative to target."""
    if not triggered:
        return "none"
    has_target = target in triggered
    has_sibling = any(s != target for s in triggered)
    if has_target and has_sibling:
        return "target_plus_sibling"
    if has_target:
        return "target_only"
    return "sibling_only"


# ---------- environment snapshot (B4) ----------

def snapshot_skills(skills_dir):
    """Map installed skill name -> sha256 of its SKILL.md. Detects drift mid-run."""
    snap = {}
    base = Path(skills_dir)
    if not base.is_dir():
        return snap
    for skill_md in sorted(base.glob("*/SKILL.md")):
        snap[skill_md.parent.name] = hashlib.sha256(skill_md.read_bytes()).hexdigest()
    return snap


# ---------- single query (B7 — error states distinct from no-trigger) ----------

def run_single_query(query, target, timeout, model, workdir):
    cmd = ["claude", "-p", query, "--output-format", "stream-json", "--verbose"]
    if model:
        cmd += ["--model", model]
    # Drop CLAUDECODE so a nested claude -p is allowed; otherwise no env tampering.
    env = {k: v for k, v in os.environ.items() if k != "CLAUDECODE"}

    result = {
        "query": query, "target": target,
        "triggered_skills": [], "target_triggered": False,
        "sibling_triggered": [], "unknown_skill_events": [],
        "state": "none", "error": None,
    }
    try:
        proc = subprocess.run(
            cmd, capture_output=True, text=True, timeout=timeout,
            cwd=workdir, env=env,
        )
    except subprocess.TimeoutExpired:
        result["state"] = "timeout"
        return result
    except Exception as e:  # pragma: no cover - defensive
        result["state"] = "error"
        result["error"] = f"{type(e).__name__}: {e}"
        return result

    if proc.returncode != 0:
        result["state"] = "error"
        result["error"] = (proc.stderr or "")[:500]
        return result

    lines = proc.stdout.splitlines()
    triggered, unknown, parse_error = extract_triggered_skills(lines)
    # No recognizable assistant/result event at all -> schema drift, not a 0 score.
    recognizable = any(
        (json.loads(l).get("type") in ("assistant", "result"))
        for l in (x.strip() for x in lines) if l and _is_json(l)
    )
    if not recognizable:
        result["state"] = "parse_error"
        result["error"] = "no recognizable assistant/result events"
        return result

    result["triggered_skills"] = triggered
    result["unknown_skill_events"] = unknown
    result["target_triggered"] = target in triggered
    result["sibling_triggered"] = [s for s in triggered if s != target]
    result["state"] = classify_state(triggered, target)
    return result


def _is_json(line):
    try:
        json.loads(line)
        return True
    except json.JSONDecodeError:
        return False


# ---------- artifact diagnostics (B3 — REQ-F-006) ----------

def detect_artifacts(results):
    """Flag suspicious patterns that mean 'do not trust the score', not a real 0."""
    flags = []
    n = len(results)
    if n == 0:
        return ["empty result set"]
    invalid = [r for r in results if r["state"] in INVALID_STATES]
    if len(invalid) == n:
        flags.append(f"all {n} runs invalid (infra failure: timeout/error/parse) — no valid score")
    parse_errs = [r for r in results if r["state"] == "parse_error"]
    if parse_errs:
        flags.append(f"{len(parse_errs)} run(s) had no recognizable stream events — possible CLI schema drift")
    valid_should = [r for r in results if r["state"] not in INVALID_STATES and r.get("should_trigger")]
    if valid_should and all(not r["target_triggered"] for r in valid_should):
        flags.append("every valid should-trigger query failed to fire the target — suspicious (check description/collision)")
    return flags


# ---------- aggregate + report ----------

def aggregate(results):
    valid = [r for r in results if r["state"] not in INVALID_STATES]
    invalid = [r for r in results if r["state"] in INVALID_STATES]
    should = [r for r in valid if r.get("should_trigger")]
    accuracy = (sum(1 for r in should if r["target_triggered"]) / len(should)) if should else None
    siblings = Counter()
    for r in valid:
        siblings.update(r["sibling_triggered"])
    states = Counter(r["state"] for r in results)
    return {
        "trigger_accuracy": accuracy,
        "valid_should_trigger": len(should),
        "sibling_competition": dict(siblings.most_common()),
        "state_counts": dict(states),
        "invalid_runs": len(invalid),
        "total_runs": len(results),
    }


def main():
    ap = argparse.ArgumentParser(description="Real-env skill-trigger probe")
    ap.add_argument("--eval-set", required=True, help="JSON list of {query, should_trigger, target?}")
    ap.add_argument("--target", default=None, help="Default target skill (item.target overrides)")
    ap.add_argument("--runs", type=int, default=3, help="Runs per query (variance)")
    ap.add_argument("--timeout", type=int, default=90, help="Per-query timeout (s)")
    ap.add_argument("--workers", type=int, default=3, help="Parallel workers (keep small — cost/rate-limit)")
    ap.add_argument("--model", default=None)
    ap.add_argument("--skills-dir", default=str(Path.home() / ".claude" / "skills"))
    ap.add_argument("--workdir", default=None, help="Harmless cwd for claude -p (default: a temp dir)")
    ap.add_argument("--dry-run", action="store_true", help="Print estimated session count and exit")
    args = ap.parse_args()

    eval_set = json.loads(Path(args.eval_set).read_text())
    total_sessions = len(eval_set) * args.runs
    print(f"# eval queries: {len(eval_set)} x runs {args.runs} = {total_sessions} claude -p sessions",
          file=sys.stderr)
    if args.dry_run:
        return
    if total_sessions > 60:
        print(f"WARNING: {total_sessions} sessions is expensive/slow.", file=sys.stderr)

    workdir = args.workdir
    tmp = None
    if not workdir:
        import tempfile
        tmp = tempfile.mkdtemp(prefix="probe-cwd-")
        workdir = tmp

    snap_start = snapshot_skills(args.skills_dir)

    jobs = []
    for item in eval_set:
        target = item.get("target") or args.target
        for _ in range(args.runs):
            jobs.append((item, target))

    results = []
    with ProcessPoolExecutor(max_workers=args.workers) as ex:
        fut = {
            ex.submit(run_single_query, item["query"], target, args.timeout, args.model, workdir):
                (item, target)
            for item, target in jobs
        }
        for f in as_completed(fut):
            item, target = fut[f]
            try:
                r = f.result()
            except Exception as e:
                r = {"query": item["query"], "target": target, "state": "error",
                     "error": str(e), "triggered_skills": [], "target_triggered": False,
                     "sibling_triggered": [], "unknown_skill_events": []}
            r["should_trigger"] = item.get("should_trigger")
            results.append(r)

    snap_end = snapshot_skills(args.skills_dir)
    drift = snap_start != snap_end

    report = {
        "summary": aggregate(results),
        "artifacts": detect_artifacts(results),
        "env_drift": drift,
        "snapshot_skills": sorted(snap_start.keys()),
        "results": results,
    }
    if drift:
        report["artifacts"].append("installed skill set changed during run — results INVALID")

    if tmp:
        import shutil
        shutil.rmtree(tmp, ignore_errors=True)

    print(json.dumps(report, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
