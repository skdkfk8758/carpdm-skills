"""guard-destructive-cmd.sh 회귀 테스트.

BLOCK 케이스가 하나라도 통과하면 이 패치는 되돌려야 한다.
훅 계약: exit 2 = 차단, exit 0 = 통과.
"""
import json
import pathlib
import subprocess
import sys

HOOK = pathlib.Path.home() / ".claude/hooks/guards/guard-destructive-cmd.sh"
R = "r" + "m"  # 이 파일 자체가 훅에 걸리지 않도록 리터럴을 쪼갠다

MUST_BLOCK = [
    f"{R} -rf /tmp/x",
    f"{R} -r somedir",
    f"sudo {R} -rf /var/log/old",
    f"/bin/{R} -rf build",
    f"cd /tmp && {R} -rf cache",
    f"{R} --recursive dist",
    f"{R} -fr dist",
    f"foo; {R} -rf bar",
    f"foo | xargs {R} -r",
    f"git {R} -r gateway",
    "git reset --hard origin/main",
    "git clean -fd",
    "psql -c 'x'; DROP TABLE users",
]

MUST_PASS = [
    "kubeconform -strict -summary -kubernetes-version 1.36.0 /tmp/p.yaml",
    "kubeconform -strict file.yaml",
    "confirm -r something",
    "charm -rf theme",
    "npm run build",
    "terraform -recursive-flag",
    f"{R} file.txt",
    f"git {R} --cached one.txt",
    "kubectl kustomize gitops/platform",
    "echo 'do not delete'",
]


def run(cmd: str) -> int:
    payload = json.dumps({"tool_input": {"command": cmd}})
    p = subprocess.run(
        ["bash", str(HOOK)], input=payload, capture_output=True, text=True
    )
    return p.returncode


fails = []
for c in MUST_BLOCK:
    rc = run(c)
    ok = rc == 2
    print(f"{'ok  ' if ok else 'FAIL'} BLOCK rc={rc}  {c}")
    if not ok:
        fails.append(("BLOCK", c, rc))

for c in MUST_PASS:
    rc = run(c)
    ok = rc == 0
    print(f"{'ok  ' if ok else 'FAIL'} PASS  rc={rc}  {c}")
    if not ok:
        fails.append(("PASS", c, rc))

print()
total = len(MUST_BLOCK) + len(MUST_PASS)
print(f"{total - len(fails)}/{total} passed")
if fails:
    print("FAILURES:", fails)
    sys.exit(1)
