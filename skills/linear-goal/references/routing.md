# Routing — repo 확정 + goal/harness/spec-thin 판정 (dispatch SSOT)

Phase 2 에서 읽는다. **이 파일이 linear-goal dispatch 라우팅의 SSOT 다** — 어느
repo 에서 작업할지(Step 0)와 이 티켓이 goal 로 굴려도 되는 crisp 한 것인지 harness 로
보낼 어려운 것인지, 아니면 spec 보강이 선행돼야 하는지(Step 1)의 로직 본체가 여기
있다. `deep-plan` 도 Step 0 에서 입력이 Linear 이슈일 때 본 파일의 §goal-ready 를
읽는다(재플래닝 중복 차단 — 양방향 소비, 복제 금지). 단 repo↔team 매핑 **데이터**의
SSOT 는 `~/.claude/linear-repo-map.json` 이다(본 파일은 그걸 조회만 함).

> `~/.claude/rules-ondemand/linear-dispatch.md` 는 **별개 관심사**다 — 거기 `Step L` 은 이슈
> *조회·리스트업* 스코프(현재 repo 팀으로 좁히기)만 다루며 dispatch 라우팅을 정의하지
> 않는다. 둘은 같은 `linear-repo-map.json` 을 공유할 뿐, 서로의 단계를 흡수하지 않는다.

## Step 0 — repo 해소

1. fetch 한 이슈에서 `team.key`(+ `project.id`) 추출.
2. `~/.claude/linear-repo-map.json` 조회:
   - `projectExceptions[]` 의 `projectId` **우선** 매칭 (예 ad-simulator →
     ADSimulator_V2).
   - 없으면 `teamRoutes[]` 의 `teamKey`/`teamId` 매칭 → `repo`.
3. 예외 처리:
   - `repo: null` → **dispatch 거부** (코드 자동개발 대상 아님). 사용자 보고.
   - 본문/성격상 외부팀 소유(이 repo 코드 산출물 없음 — 외부 엔진·서비스 작업) 또는
     운영-요청(release·배포·AWS/IAM·DB 프로비저닝 등 코드 산출물 없음) → **거부**,
     사람에게 보고. (`ext:*` 라벨은 폐기됨 — 라벨이 아니라 본문 내용으로 판정.)
   - `note`/`uncertain` 필드 有 (예 ADM 팀 = team≠repo 혼재, ad-simulator) →
     그 사유를 출력하고 **repo 확정을 사용자에게 먼저 확인**.
   - team 미매칭 → `_fallbackRepo`(ADType-Intelligence) 후보로 제시하되 **반드시
     확인** (다른 repo 소속일 수 있음).
4. 텍스트 입력(ID 없음)이면 team/project 를 모르니 repo 를 사용자에게 확인.

## Step 1 — goal/harness/spec-thin 판정

위에서 아래로 평가, 먼저 확정되는 곳에서 멈춤:

| 순위 | 신호 | 판정 |
|---|---|---|
| 1 (override) | 라벨 `agent:harness` | → **harness** |
| 1 (override) | 라벨 `agent:goal` | → **goal** |
| 2 (→harness) | estimate set 且 ≥ 5 | → harness |
| 2 (→harness) | `area:*` 라벨 2개 이상 (cross-cutting) | → harness |
| 2 (→harness) | 제목/본문 regex `(?i)renew|redesign|rework|overhaul|마이그|migration|전면|research|investigate|spike|epic` | → harness |
| 2 (→harness) | 비가역 신호 — 본문이 테이블 DROP·대량 데이터 삭제·prod 스키마 apply·다중 env 동시 적용을 명시 | → harness |
| 2 (→spec-thin) | AC 없음 **且** 본문 빈약(~400자 미만, 스크린샷-only 포함) | → **spec-thin** (보강 선행) |
| 3 (→goal) | AC/체크리스트 有 **且** 단일 `area:*` **且** 대상 특정 가능(아래 ‡) **且** (estimate unset 또는 ≤ 2) | → **goal** |
| 4 (uncertain) | 위 어디도 확정 안 됨 | → **harness** (안전 기본값) |

- **estimate 조건부**: estimate 를 안 쓰는 팀이면 순위2 estimate 행·순위3 estimate
  절을 건너뛰고 area/regex/AC/본문길이로만 판정.
- **area 조건부**: `area:*` 라벨을 안 쓰는 팀(실측: SSO 는 Improvement/Bug/Feature
  3종만)이면 순위2 area 행·순위3 "단일 `area:*`" 절을 건너뛰고 regex/AC/대상특정/
  estimate 로만 판정한다. area 부재를 cross-cutting 또는 uncertain 신호로 오독하지
  말 것 — 그러면 그 팀의 모든 trivial 티켓이 harness 로 과라우팅된다.
- **‡ 대상 특정 가능** = 구체 파일/엔드포인트/함수가 본문에 명시됨, **또는** 범위가
  좁고(estimate ≤2) AC 가 이분법적이라 worker 가 ground-first(grep/Read)로 대상을
  안전하게 특정 가능. 후자는 **ID 없는 붙여넣기·파일 미명시 소형 티켓**(예: "격자 셀
  hover 시 셀 id 툴팁")을 커버한다 — 파일 경로가 안 적혔다는 이유만으로 trivial 티켓을
  harness 로 보내지 않기 위함. **단 가드 필수**: estimate≥3·범위 모호·AC 비이분법 중
  하나라도면 후자 불성립 → 순위4 uncertain→harness. 즉 완화는 **좁은 범위 + 이분법
  AC 동시 충족** 일 때만이고, 안전 비대칭(의심 시 harness)은 그대로 유지된다.

### 핵심 비대칭 — uncertain → harness (goal 아님)

쉬운 이슈를 harness 보내면 오버헤드 낭비(쌈). **어려운 이슈를 goal 보내면
false-done PR** → 사람이 미묘한 오류 떠안음(비쌈). goal 은 **확신 crisp 일 때만**.
의심되면 강한 oracle(harness)로.

## goal-ready — 재플래닝 금지 신호 (deep-plan 공유 게이트)

위 rubric 이 **goal** 로 판정한 이슈 중 아래 4개를 **모두** 갖추면 **goal-ready** 다:

1. **재현/실측 증거 블록** — 에러 로그·네트워크 실측·검증 커맨드 출력이 verbatim 으로 박혀 있음
2. **측정 가능한 수용 기준** — `[AUTO]`/`[HUMAN]` 태그 또는 이분법 체크박스
3. **`## 범위 밖`** (또는 동등한 scope 경계 명시)
4. **해석 단일** — 설계 결정 갈래(옵션 A/B, 미확정 트레이드오프)가 본문에 남아 있지 않음

goal-ready 이슈에 `deep-plan`/`deep-interview` 를 다시 돌리는 것은 **중복 플래닝**
이다 — 이슈 본문이 이미 PLAN+Goal Prompt 역할을 한다(실측: 풍부한 이슈를 재플래닝해
낭비). `deep-plan` 은 Step 0 에서 입력이 Linear 이슈면 이 절로 판정하고, goal-ready
면 재플래닝 대신 `linear-goal`(또는 이슈 `## 추천` 의 실행 스킬) 직행을
`AskUserQuestion` 으로 제안한다 — 사용자 명시 override 시에만 plan 진행.

반대 방향은 위 rubric 그대로다: **harness/spec-thin 판정 이슈를 goal 로 강행하지
않는다** — 플랜 없는 실행이 불안정 작업의 원인. 4개 중 하나라도 빠지면 goal-ready
아님(goal 판정이어도 재플래닝 제안은 유효할 수 있음 — 그땐 게이트 없이 평소 플로우).

## 판정 결과 처리 (본 스킬의 행동)

- **goal** → Phase 3 으로 진행. 라우팅 한 줄 보고:
  `ADT-211 → repo: ADType-Intelligence / worker: goal (사유: 단일 area:map + AC 명시 + 파일 지정 + estimate 2)`.
- **harness** → **여기서 멈춘다**. 본 스킬은 goal 경로 전용이다. 출력:
  `ADT-300 → repo: <repo> / 판정: harness-class (사유: …) — goal 부적합. /harness-run ADT-300 권장.`
  단 `harness-run` 은 **프로젝트 로컬 스킬**이라 글로벌에 없다 — 대상 repo 에 깔려
  있으면 그대로 권장하고, 없으면 `loop-harness-setup`(하니스 설치) 또는 수동 분해를
  대신 제시한다.
  사용자가 "그래도 goal 로 강행" 을 **명시**하면, 그 사실을 기록하고 Phase 3 진행
  (override). 명시 없이는 진행하지 않는다.
- **spec-thin** → **여기서 멈춘다**. 실행이 아니라 **보강이 선행**돼야 한다. 출력:
  `ADT-xxx → 판정: spec-thin (AC 없음 + 본문 빈약) — 실행 전 보강 필요. /linear-groom (백로그 보강) 또는 /deep-plan (플랜 산출 후 이슈 갱신) 권장.`
  보강 후 재판정이 정경로 — goal 강행은 harness 와 동일하게 명시 override 시에만.
