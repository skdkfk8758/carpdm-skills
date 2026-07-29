---
name: linear-prioritize
description: 현재 repo 의 Linear 미완 이슈를 한 화면에 모아 의존·병렬 분석 + 우선순위 정렬 + 순차 EPIC 체인의 project milestone 묶기까지 하는 스프린트 플래닝. "남은 이슈 정리해줘", "뭐부터 해야 돼", "우선순위 매겨줘", "병렬로 뭐 돌릴 수 있어", "스프린트 짜줘", "다음 작업 뭐야", "이슈 로드맵", "마일스톤으로 묶어줘" 에 — 'linear' 란 말이 없어도 — 적극 트리거. 단순 조회는 linear-dispatch 룰, 등록은 linear-register, 재배치·보강은 linear-groom, 단일 티켓 실행은 linear-goal. 이슈 생성·코드 구현은 하지 않는다.
---

# linear-prioritize

현재 작업 중인 repo 의 **미완 Linear 이슈**를 한 화면에 모아, 의존 관계와 병렬 가능성을 분석하고, 착수 우선순위를 정렬하고, 순차 EPIC 체인을 project milestone 으로 묶어 진척을 시각화한다.

이 스킬이 답하는 질문은 셋이다: **(1) 뭐가 남았나 (2) 무엇을 어떤 순서로 (3) 무엇을 동시에.** 코드를 짜거나 이슈를 새로 만들지 않는다 — 이미 보드에 있는 일감의 *실행 계획*만 낸다.

## 왜 이 워크플로인가

1인 운영 + 정기 릴리즈에서 백로그는 금세 흐른다. 이슈를 하나씩 까보며 "이거 지금 되나? 저거 막혔나?"를 매번 손으로 재구성하는 게 병목이다. 의존(parent/blockedBy)과 충돌 영역(같은 파일)을 한 번에 읽어 **지금 동시에 굴릴 수 있는 집합**을 뽑으면, 워크트리 N개로 병렬 착수가 바로 선다. 마일스톤은 그 덩어리의 진척을 한 줄로 답하게 해준다(`[[feedback-epic-chain-milestone-autobind]]`).

## 워크플로

### Step 1~2 — 팀 스코프 + 미완 이슈 전수 수집

`~/.claude/skills/linear-register/references/backlog-scan.md`(공유 SSOT — groom 과 공유)를
읽고 §A(repo→팀 스코프 해소)·§B(전수 수집 — 페이지네이션·대형 응답 jq 추출)·§C(상세
fetch 정책) 그대로 적용한다(복제 금지). 이 스킬 고유 사항만:

- repo 컨텍스트 스킬이므로 §A 는 **1번 경로(repo-map 역매핑)가 기본** — 맵에 없으면 사용자 확인.
- 의존 관계가 필요한 이슈는 §C 대로 `get_issue` 로 본문을 봐서 `blockedBy`/`blocks` 관계와
  "선행 의존" 서술을 확인한다 (parentId 만으론 cross-team 블록을 못 잡는다 — 예: 자식이
  다른 팀 이슈에 blockedBy).

### Step 3 — 의존 그래프 구성

세 종류의 엣지를 모은다:

- **parent/child** — `parentId`. EPIC → sub-issue 계층.
- **blockedBy/blocks** — Linear 관계. **cross-team 블록**(다른 팀 이슈가 막음)은 지금 착수 불가 신호. 본문의 "선행 의존" 서술도 같이 본다.
- **순차 체인** — 제목/본문의 `S1~Sn`·`Step N`·`P0/P1` 같은 단계 표기. 작성(코딩)은 독립 가능해도 실행은 순차인 경우가 흔하니 둘을 구분해 적는다.

### Step 4 — 병렬 가능 집합 계산

두 이슈가 **동시 착수 가능**하려면: ① 서로 의존 없음, ② 막혀있지 않음(cross-team 블록·선행 미완 없음), ③ **충돌 영역 없음**(같은 파일/모듈을 둘 다 수정하지 않음 — 본문의 "건드릴 파일" 로 판단).

충돌 영역이 겹치면 병렬 대신 "순서 권장"으로 분류한다(예: 두 이슈가 같은 UI 컴포넌트 공유). 워크트리 N개로 동시에 굴릴 수 있는 **충돌 없는 집합**을 명시적으로 뽑는 게 이 단계의 핵심 산출물이다.

### Step 5 — 우선순위 정렬

각 이슈를 세 축으로 평가해 정렬:

- **착수가능성** — 지금 막힘 없이 시작 가능한가 (블록·선행 미완이면 후순위).
- **가치** — Linear priority 필드 + 사용자 맥락.
- **언블락 효과** — 이걸 끝내면 다른 이슈가 풀리나 (head·공유 UI 선행 등은 가산).

`사용자 실행 필요`(온프레미스 배포·DB execute 등)·`외부 합의 대기` 는 별도 버킷으로 빼서 "지금 AI 가 굴릴 수 있는 것"과 섞지 않는다.

### Step 6 — 순차 EPIC 체인 → milestone 자동 묶기

순차 의존 체인(S1~Sn 류)을 발견하면 **project milestone 으로 묶어 진척 바를 켠다** (`[[feedback-epic-chain-milestone-autobind]]` 컨벤션의 사후 적용판).

- milestone 은 **이슈가 아니라 project 에 속한다.** parent EPIC 이슈가 아니라 그 이슈의 `project` 에 `mcp__linear__save_milestone(project, name, description)` 으로 생성.
- 기존 milestone 중복 확인: `mcp__linear__list_milestones(project)` 먼저.
- 자식 전원 `mcp__linear__save_issue(id, milestone=<milestoneId>)` 로 편입.
- **묶는 기준** — 1순위 순차 의존 체인, 2순위 같은 목표의 병렬 묶음(3개+). 단발 이슈·외부 대기·과거 Done 은 **묶지 않는다**(마일스톤 없는 게 기본값. 전부 묶기는 안티패턴 — 마일스톤이 프로젝트 복제가 되어 변별력 0). Done 소급 묶기는 cosmetic 이니 금지.
- **기존 milestone 재편(신규 묶기 전에).** `list_milestones` 결과와 각 이슈의 현재 `projectMilestone` 을 위 기준에 대조해 어긋난 구조를 먼저 바로잡는다 — 체인과 무관한 이슈가 편입돼 있으면 해제(`save_issue(id, milestone=null)`), 한 체인이 여러 milestone 에 분산돼 있으면 하나로 모으고, 소속이 0이 된 milestone 은 `save_milestone` 으로 이름/설명을 재정의해 재활용한다(**milestone 삭제 도구는 MCP 에 없다** — 비워두고 수동 삭제를 안내). 어긋난 구조 위에 신규 묶기를 얹으면 변별력이 죽는다.
- milestone 생성/편입/재편은 mutation 이다. 2~3개 정도면 바로, 대량이면 사용자 확인 후 진행. **해제·이동은 기존 구조를 바꾸는 것이라 건수 무관 표로 제안 후 진행**(사용자가 의도적으로 묶었을 수 있다 — 조용히 풀지 않는다).

> ⚠ milestone 은 같은 project 내로 갇힌다 — **cross-team 블록은 마일스톤에 안 잡힌다**(그건 blockedBy 관계가 담당). 마일스톤 진척과 별개로 블록은 우선순위 표에서 명시한다.

> **소관 경계 (↔ linear-groom):** milestone **설계·생성·체인 기준 재편**은 이 스킬 전속.
> 이슈를 다른 프로젝트로 **재배치하면서 생기는 milestone 이동/해제**는 groom 소관(재배치
> 동반 처리) — 여기서 손대지 않는다. 반대로 groom 은 신규 milestone 을 만들지 않는다.

## 출력 포맷

ALWAYS 이 구조로 낸다 (사용자가 한눈에 "뭐부터·뭐 동시에"를 읽도록):

```
## 📋 <repo> 미완 이슈 — 우선순위 + 병렬 분석

### 의존 그래프
<ASCII — EPIC 체인·blockedBy·충돌 공유를 화살표로>

### 우선순위 (착수가능성 × 가치 × 언블락효과)
| 순위 | ID | 상태 | 근거 |
...
(`triage` 상태 이슈는 순위표에 넣되 상태 칸에 **분류 대기** 로 구분 표시 —
linear-register 가 신규를 전부 Triage 로 넣으므로 사용자 triage 결정이 선행 신호다.
분류 대기가 3건+ 이면 "먼저 Triage 정리 권장" 한 줄을 덧붙인다.)

### 🔀 지금 동시 착수 가능 (충돌 없는 병렬 집합)
{ ID ∥ ID ∥ ID } — <왜 충돌 없는지 1줄>
착수: 각 이슈마다 `linear-goal <id>` (자율실행 kickoff — 병렬 워크트리로 바로 넘김)
블록: <막힌 이슈 + 막은 원인>

### 🗂 마일스톤 구조 (묶은 경우)
Project: ...
 └ Milestone: ... ▓▓░░ N/M
```

마일스톤을 새로 묶었거나 기존 구조를 재편(해제/이동/재정의)했으면 무엇을 왜 바꿨고 무엇을 의도적으로 안 건드렸는지 1~2줄로 보고한다.

## 경계 (이 스킬이 아닌 것)

| 하려는 것 | 올바른 도구 |
|---|---|
| 이슈 단순 조회·검색 | `linear-dispatch.md` 룰 (현재 repo 팀 스코프) |
| 신규 이슈 등록 | `linear-register` 스킬 |
| 백로그 재배치·thin 이슈 보강 | `linear-groom` 스킬 |
| 단일 티켓 자율 빌드 실행 | `linear-goal` 스킬 |
| plan/PRD 를 다중 이슈로 분할 | `linear-register` (분할 모드) |
| 실제 코드 구현 | `forge`/`hunt`/`renew` |

이 스킬은 **이미 등록된 미완 이슈의 실행 계획**만 낸다 — 새 이슈도, 코드도 만들지 않는다.

## Related

- `~/.claude/skills/linear-register/references/backlog-scan.md` — 팀 스코프 + 전수 수집 절차(Step 1~2 SSOT, groom 과 공유).
- `~/.claude/rules-ondemand/linear-dispatch.md` — repo→팀 조회 스코프(backlog-scan §A 의 근거 룰).
- `~/.claude/linear-repo-map.json` — repo↔team 매핑 + team≠repo 혼재 note.
- `[[feedback-epic-chain-milestone-autobind]]` — EPIC 체인 milestone 묶기 컨벤션(Step 6 근거).
