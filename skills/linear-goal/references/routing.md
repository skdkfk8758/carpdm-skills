# Routing — repo 확정 + goal/harness 판정 (linear-dispatch Step 0/1 흡수)

Phase 2 에서 읽는다. `~/.claude/rules/linear-dispatch.md` 의 Step 0(이슈→repo)과
Step 1(goal/harness rubric)을 본 스킬 안에서 직접 돈다 — 룰이 갱신되면 이 파일도
맞춘다(룰이 SSOT). 목표: ① 어느 repo 에서 작업할지 확정, ② 이 티켓이 goal 로
굴려도 되는 crisp 한 것인지, harness 로 보내야 할 어려운 것인지 판정.

## Step 0 — repo 해소

1. fetch 한 이슈에서 `team.key`(+ `project.id`) 추출.
2. `~/.claude/linear-repo-map.json` 조회:
   - `projectExceptions[]` 의 `projectId` **우선** 매칭 (예 ad-simulator →
     ADSimulator_V2).
   - 없으면 `teamRoutes[]` 의 `teamKey`/`teamId` 매칭 → `repo`.
3. 예외 처리:
   - `repo: null` → **dispatch 거부** (코드 자동개발 대상 아님). 사용자 보고.
   - 진짜 외부(`ext:engine`) 또는 운영-요청(release·배포·AWS/IAM·DB 프로비저닝 등
     코드 산출물 없음) → **거부**, 사람에게 보고.
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
| 3 (→goal) | AC/체크리스트 有 **且** 단일 `area:*` **且** 구체 파일/엔드포인트/함수 명시 **且** (estimate unset 또는 ≤ 2) | → **goal** |
| 4 (uncertain) | 위 어디도 확정 안 됨 | → **harness** (안전 기본값) |

- **estimate 조건부**: estimate 를 안 쓰는 팀이면 순위2 estimate 행·순위3 estimate
  절을 건너뛰고 area/regex/AC/본문길이로만 판정.

### 핵심 비대칭 — uncertain → harness (goal 아님)

쉬운 이슈를 harness 보내면 오버헤드 낭비(쌈). **어려운 이슈를 goal 보내면
false-done PR** → 사람이 미묘한 오류 떠안음(비쌈). goal 은 **확신 crisp 일 때만**.
의심되면 강한 oracle(harness)로.

## 판정 결과 처리 (본 스킬의 행동)

- **goal** → Phase 3 으로 진행. 라우팅 한 줄 보고:
  `ADT-152 → repo: ADType-Intelligence / worker: goal (사유: 단일 area:map + AC 명시 + 파일 지정 + estimate 2)`.
- **harness** → **여기서 멈춘다**. 본 스킬은 goal 경로 전용이다. 출력:
  `ADT-152 → repo: <repo> / 판정: harness-class (사유: …) — goal 부적합. /harness-run ADT-152 권장.`
  사용자가 "그래도 goal 로 강행" 을 **명시**하면, 그 사실을 기록하고 Phase 3 진행
  (override). 명시 없이는 진행하지 않는다.
