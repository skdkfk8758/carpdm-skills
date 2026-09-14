"""guard-fable-cost-gate.sh 회귀 테스트 — Fable 게이트 v2.

실행: python3 guard-fable-cost-gate.test.py
같은 디렉토리의 훅을 대상으로 하므로 경로 설정이 필요 없다.

주의: named agent 케이스는 임시 파일이 아니라 **실제 ~/.claude/agents/** 를
대상으로 한다 — 게이트 로직뿐 아니라 설치 상태를 함께 검증하는 것이 목적이다.
"""
import json, os, subprocess, sys, tempfile, shutil
from pathlib import Path

HOOK = str(Path(__file__).with_name("guard-fable-cost-gate.sh"))
NUDGE = str(Path(__file__).with_name("guard-fable-prompt-nudge.sh"))
HOME = os.path.expanduser("~")
FABLE = "claude-fable-5-1"


def run(payload, hook=HOOK):
    env = dict(os.environ)
    env.pop("FABLE_GATE_DISABLE", None)
    p = subprocess.run(["bash", hook], input=json.dumps(payload),
                       capture_output=True, text=True, env=env)
    return p.returncode, p.stdout


def pay(tool, tool_input, model=FABLE, **kw):
    d = {"model": model, "session_id": "t", "tool_name": tool, "tool_input": tool_input}
    d.update(kw)
    return d


# (설명, payload, 기대 종료코드) — 2 = 차단, 0 = 통과
CASES = [
    # --- v1 회귀 (문서 §4 a~f) ---
    ("a  Fable + 프로젝트 파일 Write",
     pay("Write", {"file_path": "/Users/me/proj/a.py"}), 2),
    ("b  Fable + ~/.claude 편집",
     pay("Edit", {"file_path": f"{HOME}/.claude/CLAUDE.md"}), 0),
    ("c1 읽기 Bash",
     pay("Bash", {"command": "ls -la"}), 0),
    ("c2 무거운 Bash",
     pay("Bash", {"command": "git commit -m x"}), 2),
    ("d1 Agent(model: sonnet)",
     pay("Agent", {"model": "sonnet", "prompt": "x"}), 0),
    ("d2 Agent(fork)",
     pay("Agent", {"subagent_type": "fork", "prompt": "x"}), 2),
    ("e  sonnet 세션은 무관",
     pay("Write", {"file_path": "/x"}, model="claude-sonnet-5"), 0),
    ("   Workflow 는 항상 차단",
     pay("Workflow", {"script": "x"}), 2),
    ("   스크래치패드 Write",
     pay("Write", {"file_path": "/private/tmp/claude-501/x/scratchpad/a.md"}), 0),
    # --- v2 신규: named agent 라우팅 ---
    ("v2 Agent(subagent_type: implementer) model 없음",
     pay("Agent", {"subagent_type": "implementer", "prompt": "x"}), 0),
    ("v2 Agent(subagent_type: scout) model 없음",
     pay("Agent", {"subagent_type": "scout", "prompt": "x"}), 0),
    ("v2 Agent(subagent_type: editor) model 없음",
     pay("Agent", {"subagent_type": "editor", "prompt": "x"}), 0),
    ("v2 Agent(subagent_type: reviewer) model 없음",
     pay("Agent", {"subagent_type": "reviewer", "prompt": "x"}), 0),
    ("v2 Agent(subagent_type: nonexistent)",
     pay("Agent", {"subagent_type": "nonexistent", "prompt": "x"}), 2),
    ("v2 Agent(subagent_type: general-purpose) model 없음",
     pay("Agent", {"subagent_type": "general-purpose", "prompt": "x"}), 2),
    ("v2 Agent(implementer + model fable) — 명시 fable 은 차단",
     pay("Agent", {"subagent_type": "implementer", "model": FABLE, "prompt": "x"}), 2),
    ("v2 Agent — 부모 model 은 통과권을 주지 않는다",
     pay("Agent", {"prompt": "x"}, model="claude-sonnet-5") | {"model": FABLE}, 2),
    ("v2 subagent_type 경로 탈출 시도",
     pay("Agent", {"subagent_type": "../agents/implementer", "prompt": "x"}), 2),
]


def synthetic_transcript_cases():
    """부모 transcript 가 Fable 인 서브에이전트 호출 — 감지 v1(i1/i2) + v2(1b)."""
    out = []
    T = tempfile.mkdtemp()
    sub = os.path.join(T, "sess", "subagents")
    os.makedirs(sub)
    tp = os.path.join(T, "sess.jsonl")
    with open(tp, "w") as f:
        # 실제 transcript 는 compact JSON 이다 — 공백이 있으면 감지기의 grep '"type":"assistant"' 가 못 잡는다
        f.write(json.dumps({"type": "assistant", "message": {}, "model": FABLE},
                           separators=(",", ":")) + "\n")
    # i1: meta.json 이 실제 모델(alias)을 들고 있다 → 통과
    with open(os.path.join(sub, "agent-abc.meta.json"), "w") as f:
        f.write(json.dumps({"model": "haiku"}))
    out.append(("i1 서브에이전트 meta.json model=haiku",
                {"session_id": "t", "agent_id": "abc", "transcript_path": tp,
                 "tool_name": "Write", "tool_input": {"file_path": "/x"}}, 0))
    # i2: agent_id 가 없으면 부모 자신(Fable) → 차단
    out.append(("i2 agent_id 없음 = 부모 Fable",
                {"session_id": "t", "transcript_path": tp,
                 "tool_name": "Write", "tool_input": {"file_path": "/x"}}, 2))
    # v2 1b: meta.json model 이 inherit → agentType 의 에이전트 정의로 해소
    with open(os.path.join(sub, "agent-def.meta.json"), "w") as f:
        f.write(json.dumps({"agentType": "implementer", "model": "inherit"}))
    out.append(("v2 meta model=inherit → agents/implementer.md 로 해소",
                {"session_id": "t", "agent_id": "def", "transcript_path": tp,
                 "tool_name": "Write", "tool_input": {"file_path": "/x"}}, 0))
    # v2 1b 음성: 정의가 없는 agentType 은 부모(Fable)로 남아 차단
    with open(os.path.join(sub, "agent-ghi.meta.json"), "w") as f:
        f.write(json.dumps({"agentType": "nonexistent", "model": "inherit"}))
    out.append(("v2 meta model=inherit + 정의 없는 agentType → 차단",
                {"session_id": "t", "agent_id": "ghi", "transcript_path": tp,
                 "tool_name": "Write", "tool_input": {"file_path": "/x"}}, 2))
    # v3: tool_input.model 은 워커 모델이지 세션 모델이 아니다 (2026-09-11 오탐 회귀)
    tp_opus = os.path.join(T, "opus.jsonl")
    with open(tp_opus, "w") as f:
        f.write(json.dumps({"type": "assistant", "message": {}, "model": "claude-opus-5"},
                           separators=(",", ":")) + "\n")
    out.append(("v3 Opus 세션 + Agent(model: fable) → 통과",
                {"session_id": "t", "transcript_path": tp_opus,
                 "tool_name": "Agent", "tool_input": {"model": "fable", "prompt": "x"}}, 0))
    out.append(("v3 Fable 세션 + Agent(model: fable) → 차단",
                {"session_id": "t", "transcript_path": tp,
                 "tool_name": "Agent", "tool_input": {"model": "fable", "prompt": "x"}}, 2))
    return out, T


fail = 0
extra, TMP = synthetic_transcript_cases()
try:
    for name, payload, want in CASES + extra:
        got, _ = run(payload)
        ok = got == want
        fail += not ok
        print(f"{'PASS' if ok else 'FAIL'}  exit={got} (want {want})  {name}")

    # nudge: Fable 이면 JSON 1줄, 그 외엔 무출력
    for name, model, want_out in [("g1 nudge Fable", FABLE, True),
                                  ("g2 nudge sonnet", "claude-sonnet-5", False)]:
        rc, out = run({"model": model, "session_id": "t"}, hook=NUDGE)
        ok = rc == 0 and bool(out.strip()) == want_out
        if ok and want_out:
            try:
                json.loads(out.strip())
            except Exception:
                ok = False
        fail += not ok
        print(f"{'PASS' if ok else 'FAIL'}  exit={rc} out={'있음' if out.strip() else '없음'}  {name}")

    # 설치 상태: 에이전트 4개와 필수 frontmatter 키
    for a, want_model in [("scout", "haiku"), ("editor", "sonnet"),
                          ("implementer", "opus"), ("reviewer", "opus")]:
        f = Path(HOME, ".claude", "agents", f"{a}.md")
        ok = f.is_file()
        if ok:
            head = f.read_text().split("---")[1]
            ok = all(f"\n{k}:" in "\n" + head for k in ("name", "description", "model")) \
                and f"model: {want_model}" in head
        fail += not ok
        print(f"{'PASS' if ok else 'FAIL'}  agents/{a}.md (model: {want_model})")
finally:
    shutil.rmtree(TMP, ignore_errors=True)

total = len(CASES) + len(extra) + 2 + 4
print(f"\n{total - fail}/{total} passed")
sys.exit(1 if fail else 0)
