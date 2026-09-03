"""guard-branch-protection.sh 회귀 테스트 — 차단이 유지되는가 + 오탐이 없는가.

실행: python3 guard-branch-protection.test.py   (라이브·repo 어디서든)
같은 디렉토리의 훅을 대상으로 하므로 경로 설정이 필요 없다.
"""
import json, subprocess, sys
from pathlib import Path

HOOK = str(Path(__file__).with_name("guard-branch-protection.sh"))

def run(cmd):
    p = subprocess.run(["bash", HOOK], input=json.dumps({"command": cmd}),
                       capture_output=True, text=True)
    return p.returncode

# (설명, 명령, 기대 종료코드) — 2 = 차단, 0 = 통과
CASES = [
    # --- 반드시 계속 차단돼야 하는 것 ---
    ("main 직접 push",            "git push origin main", 2),
    ("master 직접 push",          "git push origin master", 2),
    ("force push",                "git push --force origin feat/x", 2),
    ("force push -f",             "git push -f origin feat/x", 2),
    ("복합 명령 속 main push",     "git add . && git commit -m 'x' && git push origin main", 2),
    ("heredoc 뒤의 진짜 main push",
     "cat > f.md <<'EOF'\nsome docs\nEOF\ngit push origin main", 2),
    # --- 통과해야 하는 것 ---
    ("feature 브랜치 push",       "git push -u origin docs/foo", 0),
    ("force-with-lease",          "git push --force-with-lease origin feat/x", 0),
    ("git push 아님",             "git log --oneline -5", 0),
    ("커밋 메시지 속 문구",        "git commit -m 'git push origin main 금지'", 0),
    ("heredoc 본문 속 문구 (오탐 회귀)",
     "cat > memo.md <<'EOF'\n훅이 git push origin main 을 차단한다\nEOF", 0),
    ("heredoc 본문 속 force push",
     "cat > memo.md <<'EOF'\ngit push --force 는 금지다\nEOF", 0),
    ("따옴표 없는 heredoc 델리미터",
     "cat > memo.md <<EOF\ngit push origin main\nEOF", 0),
    ("들여쓴 heredoc <<-",
     "cat > memo.md <<-EOF\n\tgit push origin main\n\tEOF", 0),
    ("python heredoc 안 문서화",
     "python3 - <<'PY'\nprint('git push origin main')\nPY", 0),
]
fail = 0
for name, cmd, want in CASES:
    got = run(cmd)
    ok = (got == want)
    if not ok: fail += 1
    print(f"{'PASS' if ok else 'FAIL'}  exit={got} (want {want})  {name}")
print(f"\n{len(CASES)-fail}/{len(CASES)} passed")
sys.exit(1 if fail else 0)
