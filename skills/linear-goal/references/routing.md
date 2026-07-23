# Routing — repo 확정 + goal/harness 판정 (dispatch SSOT)

Phase 2 에서 읽는다. **이 파일이 linear-goal dispatch 라우팅의 SSOT 다** — 어느
repo 에서 작업할지(Step 0)와 이 티켓이 goal 로 굴려도 되는 crisp 한 것인지 harness 로
보낼 어려운 것인지(Step 1)의 로직 본체가 여기 있다. 단 repo↔team 매핑 **데이터**의
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

## Step 1 — goal/harness 판정

위에서 아래로 평가, 먼저 확정되는 곳에서 멈춤:

| 순위 | 신호 | 판정 |
|---|---|---|
| 1 (override) | 라벨 `agent:harness` | → **harness** |
| 1 (override) | 라벨 `agent:goal` | → **goal** |
| 2 (→harness) | estimate set 且 ≥ 5 | → harness |
| 2 (→harness) | `area:*` 라벨 2개 이상 (cross-cutting) | → harness |
| 2 (→harness) | 제목/본문 regex `(?i)renew|redesign|rework|overhaul|마이그|migration|전면|research|investigate|spike|epic` | → harness |
| 2 (→harness) | AC 없음 **且** 본문 빈약(~400자 미만, 스크린샷-only 포함) | → harness (underspecified) |
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
