"""guard-step-scope.sh / guard-step-scope-reset.sh / guard-step-plan-nudge.sh 회귀 테스트.

실행: python3 guard-step-scope.test.py
같은 디렉토리의 훅을 대상으로 하므로 경로 설정이 필요 없다.
상태 파일이 TMPDIR 에 쌓이므로 테스트마다 임시 TMPDIR 로 격리한다.
"""
import json, os, shutil, subprocess, sys, tempfile
from pathlib import Path

SCOPE = str(Path(__file__).with_name("guard-step-scope.sh"))
RESET = str(Path(__file__).with_name("guard-step-scope-reset.sh"))
NUDGE = str(Path(__file__).with_name("guard-step-plan-nudge.sh"))
HOME = os.path.expanduser("~")

results = []


def check(name, cond):
    results.append((name, bool(cond)))
    print(f"{'PASS' if cond else 'FAIL'}  {name}")


def run(hook, payload, tmp, **env_extra):
    env = dict(os.environ)
    env["TMPDIR"] = tmp
    env.pop("GUARD_STEP_DISABLE", None)
    env.pop("GUARD_STEP_MAX_FILES", None)
    env.update(env_extra)
    p = subprocess.run(["bash", hook], input=json.dumps(payload),
                       capture_output=True, text=True, env=env)
    return p.returncode, p.stdout, p.stderr


def edit(path, sid="s1", **kw):
    d = {"session_id": sid, "tool_name": "Edit", "tool_input": {"file_path": path}}
    d.update(kw)
    return d


TMP = tempfile.mkdtemp(prefix="step-scope-test-")
try:
    # --- 1~3번째 파일은 통과, 4번째는 차단 ---
    t = tempfile.mkdtemp(dir=TMP)
    for i in (1, 2, 3):
        rc, _, _ = run(SCOPE, edit(f"/proj/f{i}.py"), t)
        check(f"{i}번째 파일 편집 → exit 0", rc == 0)
    rc, _, err = run(SCOPE, edit("/proj/f4.py"), t)
    check("4번째 파일 편집 → exit 2", rc == 2)
    check("차단 메시지에 [step-scope] 포함", "[step-scope]" in err)
    check("차단 메시지에 4개째 경로 포함", "/proj/f4.py" in err)

    # --- 한도 도달 후에도 이미 기록된 파일 재편집은 통과 ---
    rc, _, _ = run(SCOPE, edit("/proj/f1.py"), t)
    check("기록된 파일 재편집 → exit 0", rc == 0)

    # --- 면제: ~/.claude 아래는 세지 않는다 (한도 도달 상태에서도 통과) ---
    rc, _, _ = run(SCOPE, edit(f"{HOME}/.claude/CLAUDE.md"), t)
    check("~/.claude/ 경로 면제 → exit 0", rc == 0)

    # --- 면제: 스크래치패드 ---
    rc, _, _ = run(SCOPE, edit("/private/tmp/claude-501/x/scratchpad/a.md"), t)
    check("스크래치패드 경로 면제 → exit 0", rc == 0)

    # --- 면제: 서브에이전트 (transcript_path 에 /subagents/) ---
    rc, _, _ = run(SCOPE, edit("/proj/f9.py",
                               transcript_path="/x/sess/subagents/agent-1.jsonl"), t)
    check("transcript_path 의 /subagents/ 면제 → exit 0", rc == 0)

    # --- 면제: GUARD_STEP_DISABLE=1 ---
    rc, _, _ = run(SCOPE, edit("/proj/f10.py"), t, GUARD_STEP_DISABLE="1")
    check("GUARD_STEP_DISABLE=1 면제 → exit 0", rc == 0)

    # --- 리셋 후 다시 3개 허용 ---
    rc, _, _ = run(RESET, {"session_id": "s1"}, t)
    check("UserPromptSubmit 리셋 → exit 0", rc == 0)
    codes = [run(SCOPE, edit(f"/proj/g{i}.py"), t)[0] for i in (1, 2, 3)]
    check("리셋 후 3개 다시 허용", codes == [0, 0, 0])
    rc, _, _ = run(SCOPE, edit("/proj/g4.py"), t)
    check("리셋 후 4번째는 다시 차단", rc == 2)

    # --- PostToolUse 리셋은 AskUserQuestion 일 때만 동작 ---
    t2 = tempfile.mkdtemp(dir=TMP)
    for i in (1, 2, 3):
        run(SCOPE, edit(f"/proj/h{i}.py", sid="s2"), t2)
    rc, _, _ = run(RESET, {"session_id": "s2", "tool_name": "Bash"}, t2)
    check("PostToolUse(Bash) 리셋 무시 → exit 0", rc == 0)
    rc, _, _ = run(SCOPE, edit("/proj/h4.py", sid="s2"), t2)
    check("Bash 뒤에도 4번째는 여전히 차단", rc == 2)
    rc, _, _ = run(RESET, {"session_id": "s2", "tool_name": "AskUserQuestion"}, t2)
    check("PostToolUse(AskUserQuestion) 리셋 → exit 0", rc == 0)
    rc, _, _ = run(SCOPE, edit("/proj/h4.py", sid="s2"), t2)
    check("AskUserQuestion 응답 뒤 편집 허용", rc == 0)

    # --- plan-nudge: 긴 프롬프트는 주입, 짧은 프롬프트는 무음 ---
    t3 = tempfile.mkdtemp(dir=TMP)
    rc, out, _ = run(NUDGE, {"session_id": "n1", "prompt": "가" * 301}, t3)
    ok = rc == 0 and "[step-plan]" in out
    if ok:
        try:
            ctx = json.loads(out)["hookSpecificOutput"]["additionalContext"]
            ok = "[step-plan]" in ctx
        except Exception:
            ok = False
    check("300자 초과 프롬프트 → stdout JSON 에 [step-plan]", ok)

    t4 = tempfile.mkdtemp(dir=TMP)
    rc, out, _ = run(NUDGE, {"session_id": "n2", "prompt": "이 파일 한 줄 고쳐줘"}, t4)
    check("짧은 프롬프트 → 빈 출력", rc == 0 and out.strip() == "")
finally:
    shutil.rmtree(TMP, ignore_errors=True)

fail = sum(1 for _, ok in results if not ok)
print(f"\n{len(results) - fail}/{len(results)} passed")
sys.exit(1 if fail else 0)
