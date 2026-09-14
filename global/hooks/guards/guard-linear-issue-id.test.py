"""Linear guard issue-id extraction regression test — lib-issue-id.sh + the three hooks using it.

Run: python3 guard-linear-issue-id.test.py   (from anywhere)
     GUARD_DIR=<dir> python3 ...             (run the same cases against another copy)
Builds a throwaway git repo and a synthetic repo map, then runs the real hooks.
Live ~/.claude/linear-repo-map.json is only read by the last case, never written.
"""
import json, os, subprocess, sys, tempfile
from pathlib import Path

DIR = Path(os.environ.get("GUARD_DIR") or Path(__file__).parent)
STATE = str(DIR / "guard-linear-state-nudge.sh")
ACCEPT = str(DIR / "guard-acceptance-criteria-nudge.sh")
NAMING = str(DIR / "guard-branch-linear-naming.sh")
REAL_MAP = str(Path.home() / ".claude" / "linear-repo-map.json")

MAP = {"teamRoutes": [{"teamKey": "ADT"}, {"teamKey": "DOPS"}, {"teamKey": "SUR"}],
       "labelRoutes": [{"teamKey": "SMF"}], "projectExceptions": [{"team": "ADT"}]}

HEREDOC_COMMIT = "git commit -F - <<'EOF'\nfix: DOPS-43 반영\nEOF"
HEREDOC_MENTION = "git commit -F - <<'EOF'\n브랜치는 git branch topic 으로 만든다\nEOF"
HEREDOC_THEN_REAL = "cat > f.md <<EOF\ngit branch ignored\nEOF\ngit checkout -b docs/baz"
HERESTRING_THEN_REAL = 'cat <<<"x"\ngit checkout -b docs/bar'

# (desc, hook, HEAD branch, command, map: "synthetic"|"missing"|"real", env, expected id|None)
# For NAMING the expected value is "FIRE" (nudges) or None (silent).
CASES = [
    ("promote branch + main-<sha> message",  STATE, "ci/adroute-collector-7d2422c0", 'git commit -m "chore: promote main-7d2422c0"', "synthetic", None, None),
    ("UTF-8 / SHA-256 in message",           STATE, "docs/refresh", 'git commit -m "fix: UTF-8 SHA-256 처리"', "synthetic", None, None),
    ("ADType path does not count",           STATE, "docs/refresh", "git -C ~/Workspace/ADType-Intelligence commit -m x", "synthetic", None, None),
    ("id from branch name",                  STATE, "feat/adt-196-layer", 'git commit -m "x"', "synthetic", None, "ADT-196"),
    ("id from heredoc commit message",       STATE, "docs/refresh", HEREDOC_COMMIT, "synthetic", None, "DOPS-43"),
    ("Korean particle after id",             STATE, "docs/refresh", 'git commit -m "ADT-196에서 이어서"', "synthetic", None, "ADT-196"),
    ("branch_create id from new name",       STATE, "main", "git worktree add -b feat/dops-12-foo ../x", "synthetic", None, "DOPS-12"),
    ("branch_create id only in path",        STATE, "main", "git worktree add -b docs/foo ../adt-9-old", "synthetic", None, None),
    ("labelRoutes key counts",               STATE, "feat/smf-3-fe", 'git commit -m "x"', "synthetic", None, "SMF-3"),
    ("map missing -> generic fallback",      STATE, "feat/xyz-5-foo", 'git commit -m "x"', "missing", None, "XYZ-5"),
    ("fallback still needs a boundary",      STATE, "ci/adroute-collector-7d2422c0", 'git commit -m "x"', "missing", None, None),
    ("GUARD_LINEAR_ISSUE_RE override",       STATE, "feat/abc-7-foo", 'git commit -m "x"', "synthetic", {"GUARD_LINEAR_ISSUE_RE": "ABC-[0-9]+"}, "ABC-7"),
    ("acceptance: promote branch silent",    ACCEPT, "ci/adroute-collector-7d2422c0", "gh pr create --title x", "synthetic", None, None),
    ("acceptance: id from branch",           ACCEPT, "feat/sur-26-x", "gh pr merge 5", "synthetic", None, "SUR-26"),
    ("naming: heredoc mention is text",      NAMING, "main", HEREDOC_MENTION, "synthetic", None, None),
    ("naming: real command after heredoc",   NAMING, "main", HEREDOC_THEN_REAL, "synthetic", None, "FIRE"),
    ("naming: here-string keeps next line",  NAMING, "main", HERESTRING_THEN_REAL, "synthetic", None, "FIRE"),
    ("naming: no id fires",                  NAMING, "main", "git checkout -b docs/foo", "synthetic", None, "FIRE"),
    ("naming: id silences",                  NAMING, "main", "git checkout -b feat/adt-1-foo", "synthetic", None, None),
    ("naming: collector-7 is not an id",     NAMING, "main", "git worktree add -b ci/adroute-collector-7d2422c0 ../x", "synthetic", None, "FIRE"),
    ("real map: DOPS key present",           STATE, "feat/dops-43-x", 'git commit -m "x"', "real", None, "DOPS-43"),
]


def git(repo, *args):
    subprocess.run(["git", "-C", repo, "-c", "user.name=t", "-c", "user.email=t@t", *args],
                   check=True, capture_output=True)


def run(hook, branch, command, map_kind, env_extra):
    with tempfile.TemporaryDirectory() as tmp:
        repo = os.path.join(tmp, "repo")
        os.mkdir(repo)
        git(repo, "init", "-q")
        git(repo, "commit", "-q", "--allow-empty", "-m", "init")
        git(repo, "checkout", "-q", "-B", branch)
        map_path = {"synthetic": os.path.join(tmp, "map.json"),
                    "missing": os.path.join(tmp, "absent.json"),
                    "real": REAL_MAP}[map_kind]
        if map_kind == "synthetic":
            Path(map_path).write_text(json.dumps(MAP))
        nudge_tmp = os.path.join(tmp, "t")
        os.mkdir(nudge_tmp)
        env = {"PATH": os.environ.get("PATH", ""), "HOME": tmp, "TMPDIR": nudge_tmp,
               "GUARD_LINEAR_REPO_MAP": map_path}
        env.update(env_extra or {})
        payload = json.dumps({"session_id": "s1", "tool_input": {"command": command}})
        p = subprocess.run(["bash", hook], input=payload, capture_output=True, text=True,
                           env=env, cwd=repo, timeout=15)
        return p.returncode, p.stdout


fail = 0
for desc, hook, branch, command, map_kind, env_extra, want in CASES:
    code, out = run(hook, branch, command, map_kind, env_extra)
    ctx = json.loads(out)["hookSpecificOutput"]["additionalContext"] if out.strip() else ""
    if want is None:
        ok = code == 0 and not ctx
    elif want == "FIRE":
        ok = code == 0 and "이슈ID 가 없다" in ctx
    else:
        ok = code == 0 and want in ctx
    fail += not ok
    print(f"{'PASS' if ok else 'FAIL'}  want={want}  {desc}")
    if not ok:
        print("       got:", (ctx or "<silent>").replace("\n", " | ")[:160])
print(f"\n{len(CASES) - fail}/{len(CASES)} passed")
sys.exit(1 if fail else 0)
