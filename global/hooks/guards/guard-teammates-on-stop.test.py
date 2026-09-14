"""guard-teammates-on-stop.sh 회귀 테스트 — 팀메이트가 남으면 1회 차단하는가 + 오탐이 없는가.

실행: python3 guard-teammates-on-stop.test.py   (어디서든)
합성 HOME 아래에 팀 config 를 만들어 실제 훅을 돌린다. 라이브 ~/.claude/teams 는 건드리지 않는다.
"""
import json, os, subprocess, sys, tempfile
from pathlib import Path

HOOK = str(Path(__file__).with_name("guard-teammates-on-stop.sh"))
SID = "abcd1234-1111-2222-3333-444444444444"

def lead():
    return {"agentId": "lead-1", "name": "team-lead", "agentType": "team-lead"}

def worker(name):
    return {"agentId": "a-" + name, "name": name, "agentType": "general-purpose"}

def run(config, payload, env_extra=None):
    """config: dict | str(raw) | None. 반환 (exit code, stderr)"""
    with tempfile.TemporaryDirectory() as tmp:
        if config is not None:
            d = Path(tmp) / ".claude" / "teams" / ("session-" + SID[:8])
            d.mkdir(parents=True)
            raw = config if isinstance(config, str) else json.dumps(config)
            (d / "config.json").write_text(raw)
        env = {"HOME": tmp, "PATH": os.environ.get("PATH", "")}
        if env_extra:
            env.update(env_extra)
        p = subprocess.run(["bash", HOOK], input=payload, capture_output=True,
                           text=True, env=env, timeout=10)
        return p.returncode, p.stderr

STOP = json.dumps({"session_id": SID, "stop_hook_active": False, "hook_event_name": "Stop"})
ACTIVE = json.dumps({"session_id": SID, "stop_hook_active": True, "hook_event_name": "Stop"})

# (설명, config, stdin, env, 기대 종료코드, stderr 에 있어야 하는 문자열들)
CASES = [
    ("config 없음",            None,                                     STOP,  None, 0, []),
    ("리드만 남음",             {"members": [lead()]},                    STOP,  None, 0, []),
    ("리드 + 워커 1",           {"members": [lead(), worker("impl-1")]},  STOP,  None, 2, ["impl-1", "shutdown_request"]),
    ("리드 + 워커 2",           {"members": [lead(), worker("impl-1"), worker("rev-1")]},
                                                                          STOP,  None, 2, ["impl-1", "rev-1"]),
    ("stop_hook_active true",  {"members": [lead(), worker("impl-1")]},  ACTIVE, None, 0, []),
    ("TEAMMATE_GUARD_DISABLE", {"members": [lead(), worker("impl-1")]},  STOP,
                                                        {"TEAMMATE_GUARD_DISABLE": "1"}, 0, []),
    ("깨진 JSON config",        '{"members": [',                          STOP,  None, 0, []),
    ("빈 stdin",               {"members": [lead(), worker("impl-1")]},  "",    None, 0, []),
    ("session_id 없음",         {"members": [lead(), worker("impl-1")]},
                                                    json.dumps({"hook_event_name": "Stop"}), None, 0, []),
    ("members 키 없음",         {"name": "t"},                            STOP,  None, 0, []),
]

fail = 0
for name, cfg, payload, env_extra, want, needles in CASES:
    got, err = run(cfg, payload, env_extra)
    ok = (got == want) and all(n in err for n in needles)
    if not ok:
        fail += 1
    print(f"{'PASS' if ok else 'FAIL'}  exit={got} (want {want})  {name}")
    if not ok and err:
        print("       stderr:", err.strip().replace("\n", " | ")[:200])
print(f"\n{len(CASES)-fail}/{len(CASES)} passed")
sys.exit(1 if fail else 0)
