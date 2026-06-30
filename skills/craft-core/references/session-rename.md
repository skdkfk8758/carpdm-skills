# 세션 이름 설정 (background job rename)

`forge`/`renew`/`hunt` 가 **백그라운드 잡으로 돌고 있으면**, 이 세션 이름을 진행 중인
작업에 맞게 바꾼다. 잡 리스트에서 어떤 세션이 무슨 작업을 굴리는지 한눈에 보이게 하는
용도. 잡 컨텍스트가 아니면(=일반 세션) 세션 이름 개념이 없으니 **조용히 생략**한다.

## 적용 조건 (guard)

- **`$CLAUDE_JOB_DIR` 환경변수가 있을 때만.** 없으면(=백그라운드 잡 아님) 생략한다. 에러 아님.
- Phase 0 에서 worktype·한 줄 목표를 확정한 직후 1회 실행한다.

## 이름 포맷

**통일 규칙: `[<key>] <짧은 목표>` — 항상 대괄호 prefix.** `<key>` 만 분기한다:

- **Linear 이슈에 바인딩됐으면**(Phase 0 Linear binding 으로 issue-id 가 있으면):
  `<key>` = 이슈ID. 예: `[AUT-25] 비밀번호 정책 강화`, `[ADT-272] persona POI z-order`.
- **이슈 없으면**: `<key>` = worktype(`forge`/`renew`/`hunt`).
  - 예: `[forge] persona POI export`
  - 예: `[hunt] login null crash`
  - 예: `[renew] settings flow 개편`
- 짧은 목표는 Phase 0 의 한 줄 목표를 ≈50자 이내로 줄인 것(말줄임표 불필요).

## 메커니즘 (검증됨 2026-06-30)

세션 이름은 `$CLAUDE_JOB_DIR/state.json` 의 `name` 필드에 저장된다. `nameSource` 를
`"user"` 로 같이 박아야 하니스의 auto-rename 이 덮어쓰지 않는다(`"auto"` 면 하니스가
재생성 가능). 다른 필드는 보존 — atomic write(temp → os.replace)로 동시쓰기 손상 방지.

```bash
SESSION_NAME="[forge] persona POI export"  # 위 포맷으로 치환
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

- **비가역 아님 / 외부발신 아님** — 로컬 잡 메타데이터만 바꾼다. 그래서 별도 확인
  게이트 없이 Phase 0 안에서 실행한다.
- state.json 은 하니스 소유 파일이다. read-modify-write 로 **다른 필드를 절대 버리지
  말 것**(`tokens`/`updatedAt`/`children` 등 통째 보존). 위 snippet 이 그렇게 한다.
- 실패해도(파일 부재·권한 등) 작업 자체는 진행한다 — rename 은 편의 기능이라 hard gate
  아님. 실패 시 1줄 note 만 남기고 계속.
