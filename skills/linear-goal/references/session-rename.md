# 세션 이름 설정 (background job rename)

linear-goal 이 티켓 착수(Phase 4 동기 블록)할 때, **백그라운드 잡으로 돌고 있으면**
이 세션 이름을 `[<issue-id>] <작업요약>` 으로 바꾼다. 잡 리스트에서 어떤 티켓을 굴리는
세션인지 한눈에 보이게 하는 용도.

## 적용 조건 (guard)

- **`$CLAUDE_JOB_DIR` 환경변수가 있을 때만.** 없으면(=백그라운드 잡 컨텍스트 아님)
  세션 이름 개념이 없으니 **조용히 생략**한다. 에러 아님.
- 티켓 ID 가 있을 때만(붙여넣은 텍스트 입력이라 ID 가 없으면 생략).

## 이름 포맷

`[<issue-id>] <작업요약>` — 작업요약은 이슈 제목을 짧게(≈50자 이내) 줄인 것. 티켓번호는
대괄호로 묶어 잡 리스트에서 눈에 띄게 한다.
- 예: `[ADT-272] persona POI z-order`
- 예: `[AUT-25] 비밀번호 정책 강화`
- 제목이 길면 핵심만 남기고 절단(말줄임표 불필요).

## 메커니즘 (검증됨 2026-06-30)

세션 이름은 `$CLAUDE_JOB_DIR/state.json` 의 `name` 필드에 저장된다. `nameSource` 를
`"user"` 로 같이 박아야 하니스의 auto-rename 이 덮어쓰지 않는다(`"auto"` 면 하니스가
재생성 가능). 다른 필드는 보존 — atomic write(temp → os.replace)로 동시쓰기 손상 방지.

```bash
ISSUE_NAME="[ADT-272] persona POI z-order"  # [<issue-id>] <작업요약> 로 치환
python3 - "$ISSUE_NAME" <<'PY'
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

- **비가역 아님 / 외부발신 아님** — 로컬 잡 메타데이터만 바꾼다. 그래서 별도 확인
  게이트 없이 Phase 4 동기 블록(사용자 승인 뒤) 안에서 실행한다.
- state.json 은 하니스 소유 파일이다. read-modify-write 로 **다른 필드를 절대 버리지
  말 것**(`tokens`/`updatedAt`/`children` 등 통째 보존). 위 snippet 이 그렇게 한다.
- 실패해도(파일 부재·권한 등) 티켓 작업 자체는 진행한다 — rename 은 편의 기능이라
  hard gate 아님. 실패 시 1줄 note 만 남기고 계속.
