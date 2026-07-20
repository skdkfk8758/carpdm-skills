# 세션 이름 설정 (background job rename) — 전 스킬 공유 SSOT

백그라운드 잡으로 도는 스킬이 세션 이름을 작업에 맞게 바꾼다 — 잡 리스트에서 어떤
세션이 무슨 작업인지 한눈에 보이게. 잡 컨텍스트가 아니면(=일반 세션) 세션 이름
개념이 없으니 **조용히 생략**한다.

> 이 파일이 메커니즘·가드·포맷의 **단일 SSOT** 다 — craft(forge/renew/hunt)·
> linear-goal·land 가 전부 이 파일을 읽는다. 스킬별 사본을 만들지 말 것(과거
> 3사본이 존재해 메커니즘 갱신이 3곳 동기를 요구했다 — 2026-07-21 통합).

## 적용 조건 (guard — 공통)

- **`$CLAUDE_JOB_DIR` 환경변수가 있을 때만.** 없으면 생략한다. 에러 아님.
- 실행 시점·추가 조건은 호출 스킬별로 다르다(아래 표).

## 이름 포맷 — 호출 스킬별

**공통 규칙: ≈50자 이내, 길면 핵심만 남기고 절단(말줄임표 불필요).**

| 호출 스킬 | 시점 | 포맷 | 예 |
|---|---|---|---|
| forge/renew/hunt (craft Phase 0) | worktype·목표 확정 직후 1회 | `[<key>] <짧은 목표>` — key = Linear 이슈ID(바인딩 시) 또는 worktype | `[AUT-25] 비밀번호 정책 강화` / `[forge] persona POI export` |
| linear-goal (Phase 1, fetch 직후) | 티켓 ID 확보 즉시 (ID 없으면 생략) | `[<issue-id>] <작업요약>` | `[ADT-272] persona POI z-order` |
| land (Step 6, `result:` 직전) | **1건 이상 머지됐을 때만** — 0건이면 rename 금지(거짓 완료 이름 방지). 시작이 아니라 *결과*로 rename | 단일: `landed <식별자> <type(scope)>` (식별자 = 이슈ID `[ADT-33]` 우선, 없으면 `#451`) · 다수: `landed <N> PRs` (+대표 scope) | `landed [ADT-33] fix(make)` / `landed 3 PRs · make/api/ui` |

## 메커니즘 (검증됨 2026-06-30)

세션 이름은 `$CLAUDE_JOB_DIR/state.json` 의 `name` 필드에 저장된다. `nameSource` 를
`"user"` 로 같이 박아야 하니스의 auto-rename 이 덮어쓰지 않는다(`"auto"` 면 하니스가
재생성 가능). 다른 필드는 보존 — atomic write(temp → os.replace)로 동시쓰기 손상 방지.

```bash
SESSION_NAME="[forge] persona POI export"  # 위 표의 포맷으로 치환
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

## 주의 (공통)

- **비가역 아님 / 외부발신 아님** — 로컬 잡 메타데이터만 바꾼다. 별도 확인 게이트
  없이 각 스킬의 지정 시점에 실행한다.
- state.json 은 하니스 소유 파일이다. read-modify-write 로 **다른 필드를 절대 버리지
  말 것**(`tokens`/`updatedAt`/`children` 등 통째 보존). 위 snippet 이 그렇게 한다.
- 실패해도(파일 부재·권한 등) 작업 자체는 진행한다 — rename 은 편의 기능이라 hard
  gate 아님. 실패 시 1줄 note 만 남기고 계속. 단 land 는 "실패해도 됨"≠"안 해도 됨" —
  조건 충족 시 반드시 시도한다.
