# 세션 이름 설정 (background job rename)

land 가 **백그라운드 잡으로 돌고 있으면**, 머지가 끝난 뒤 이 세션 이름을 **랜딩한
결과**에 맞게 바꾼다. 형제 스킬(`forge`/`renew`/`hunt`/`harness-run`/`linear-goal`)은
작업을 *시작*할 때 "앞으로 할 일"로 rename 하지만, land 는 작업의 *끝*이라 "방금
무엇을 배에 실었는지"로 rename 한다. 잡 리스트에서 어떤 세션이 무엇을 랜딩했는지
한눈에 보이게 하는 용도. 잡 컨텍스트가 아니면(=일반 세션) 세션 이름 개념이 없으니
**조용히 생략**한다.

## 적용 조건 (guard)

- **`$CLAUDE_JOB_DIR` 환경변수가 있을 때만.** 없으면(=백그라운드 잡 아님) 생략한다. 에러 아님.
- **실제로 1건 이상 머지됐을 때만.** 머지 0건(전부 skip 됐거나 conflict 로 멈춤)이면
  랜딩한 게 없으니 rename 하지 않는다 — 세션 이름이 거짓 완료를 주장하면 안 된다.
- Step 6 Report 의 한 일 요약을 모은 직후, `result:` 줄을 내기 전에 1회 실행한다.

## 이름 포맷

머지 건수에 따라 graceful 하게 줄인다. Report 에서 이미 모은 데이터(이슈 ID·type/scope·
PR 번호)를 그대로 재사용한다 — 새로 긁지 않는다.

- **단일 PR** — `landed <식별자> <type(scope)>`:
  - 연결 Linear 이슈가 있으면 이슈 ID 를 식별자로(대괄호로 묶어 눈에 띄게):
    `landed [ADT-33] fix(make)`
  - 이슈가 없으면 PR 번호를 식별자로: `landed #451 fix(make)`
  - type(scope)·식별자 중 하나가 없으면 있는 것만 — `landed #451`, `landed [ADT-33]`.
- **다수 PR (2건+)** — `landed <N> PRs`, 대표 scope 를 알면 덧붙인다:
  - `landed 3 PRs · make/api/ui`
  - 대표가 모호하면 카운트만: `landed 3 PRs`
- 길면 핵심만 남기고 절단(말줄임표 불필요). ≈50자 이내 지향.

## 메커니즘 (검증됨 2026-06-30)

세션 이름은 `$CLAUDE_JOB_DIR/state.json` 의 `name` 필드에 저장된다. `nameSource` 를
`"user"` 로 같이 박아야 하니스의 auto-rename 이 덮어쓰지 않는다(`"auto"` 면 재생성
가능). 다른 필드는 보존 — atomic write(temp → os.replace)로 동시쓰기 손상 방지.

```bash
SESSION_NAME="landed #451 fix(make)"  # 위 포맷으로 치환
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
  게이트 없이 Step 6 안에서 실행한다(Step 3 Confirm 의 머지 승인과 무관).
- state.json 은 하니스 소유 파일이다. read-modify-write 로 **다른 필드를 절대 버리지
  말 것**(`tokens`/`updatedAt`/`children` 등 통째 보존). 위 snippet 이 그렇게 한다.
- 실패해도(파일 부재·권한 등) 보고/완료는 진행한다 — rename 은 편의 기능이라 hard
  gate 아님. 실패 시 1줄 note 만 남기고 계속.
