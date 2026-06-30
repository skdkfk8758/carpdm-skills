# 세션 이름 설정 (background job rename)

harness-run 이 **백그라운드 잡으로 돌고 있으면**, 이 세션 이름을 굴리는 이슈에 맞게
바꾼다. 잡 리스트에서 어떤 세션이 어떤 이슈를 하니스로 굴리는지 한눈에 보이게 하는
용도. 잡 컨텍스트가 아니면(=일반 세션) 세션 이름 개념이 없으니 **조용히 생략**한다.

## 적용 조건 (guard)

- **`$CLAUDE_JOB_DIR` 환경변수가 있을 때만.** 없으면(=백그라운드 잡 아님) 생략. 에러 아님.
- G0 에서 이슈 slug 를 확정한 직후 1회 실행한다.

## 이름 포맷

**통일 규칙: `[<issue-id>] <작업요약>` — 항상 대괄호 prefix**(forge/hunt/renew/linear-goal 과 동일 포맷).
- slug 에서 이슈ID 를 추출해 대괄호에 넣고 뒤에 짧은 요약. 예: `[ADT-183] layer mgmt`, `[AUT-25] password policy`.
- slug 에 이슈ID 가 없으면 `[<slug>]` 로 대체(예: `[refactor-toolbar]`).
- 요약이 길면 핵심만 남기고 절단(말줄임표 불필요).

## 메커니즘

세션 이름은 `$CLAUDE_JOB_DIR/state.json` 의 `name` 필드에 저장된다. `nameSource` 를
`"user"` 로 같이 박아야 하니스의 auto-rename 이 덮어쓰지 않는다(`"auto"` 면 재생성 가능).
다른 필드는 보존 — atomic write(temp → os.replace)로 동시쓰기 손상 방지.

```bash
SESSION_NAME="[ADT-183] layer mgmt"  # [<issue-id>] <작업요약> 로 치환
python3 - "$SESSION_NAME" <<'PY'
import json, os, sys, tempfile
job = os.environ.get("CLAUDE_JOB_DIR")
if not job:
    raise SystemExit(0)  # 잡 컨텍스트 아님 — 조용히 생략
p = os.path.join(job, "state.json")
d = json.load(open(p))
d["name"] = sys.argv[1]
d["nameSource"] = "user"
fd, tmp = tempfile.mkstemp(dir=os.path.dirname(p))
with os.fdopen(fd, "w") as f:
    json.dump(d, f, ensure_ascii=False)
os.replace(tmp, p)
PY
```

## 주의

- **비가역 아님 / 외부발신 아님** — 로컬 잡 메타데이터만. 별도 확인 게이트 없이 G0 직후 실행.
- state.json 은 하니스 소유 파일이다. read-modify-write 로 **다른 필드를 절대 버리지 말 것**.
- 실패해도(파일 부재·권한 등) 하니스 실행은 진행 — rename 은 편의 기능이라 hard gate 아님.
  실패 시 1줄 note 만 남기고 계속.
