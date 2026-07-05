# Requirements: 파이프라인 스킬 실행 중 대화턴 Task 체크리스트 표시

> Crystallized from a deep-interview on 2026-07-06. Final ambiguity: 17% (target ≤ 20%).
> Type: brownfield. Rounds: 6. Status: draft.

## 1. Goal & scope

파이프라인 스킬(forge/hunt/renew/harness-run/linear-goal)이 돌 때, Claude Code 네이티브
Task 도구(TaskCreate/TaskUpdate) 기반 페이즈 체크리스트가 대화턴에 항상 렌더되어
(완료=strikethrough, 진행중=■, 대기=□) 사용자가 진행 상황을 한눈에 따라갈 수 있게 한다.
현재는 강제 장치가 없어 세션마다 나올 수도 안 나올 수도 있는 것이 문제의 핵심이다.

**In scope:** craft-core(→forge/hunt/renew) + harness-run + linear-goal 의 SKILL/reference
본문에 Task 체크리스트 컨벤션 삽입, 실런 1회 검증.
**Out of scope:** 글로벌 룰(rules/)·hook 강제, land/ship/sweep/deep-plan 등 비파이프라인
스킬, 세부 스텝(파일/태스크) 단위 granularity, 파이프라인 구조 자체의 변경.

## 2. Topology

The pieces this breaks into (locked in Round 0):

| Component | Status | One-line role |
|-----------|--------|---------------|
| A 렌더 메커니즘 | active | Claude Code 네이티브 Task 도구(TaskCreate/TaskUpdate) 사용 |
| B 적용 범위 | active | 스킬 파이프라인만 — craft-core 계열 + harness-run + linear-goal |
| C 강제 방식 | active | 스킬 본체에 컨벤션 섹션 직접 삽입 (호출 시 반드시 읽힘) |
| D 업데이트 규율 | active | 페이즈 단위 항목 + 긴 페이즈 내부는 Workflow 진행트리 위임 |

## 3. Functional requirements

| ID | Requirement (the system SHALL…) | Priority | Acceptance criteria | Origin |
|----|----------------------------------|----------|---------------------|--------|
| REQ-F-001 | 파이프라인 스킬은 실행 시작 직후(첫 실질 단계 진입 전) TaskCreate 로 페이즈 단위 체크리스트를 생성한다 | Must | 파이프라인 시작 후 첫 1~2 턴 안에 체크리스트가 대화 UI 에 나타남 | R1, R5 |
| REQ-F-002 | 각 페이즈 경계에서 TaskUpdate 로 상태를 전이한다 — 페이즈 진입 시 in_progress, 페이즈 검증 완료 시 completed | Must | 페이즈가 끝날 때마다 해당 항목이 strikethrough 로 바뀌고 다음 항목이 ■ 로 바뀜 | R2, R5 |
| REQ-F-003 | 체크리스트 항목 1줄 = 파이프라인 페이즈 1개(5~10 항목). 세부 스텝 단위 항목 생성 금지 | Must | 생성된 체크리스트 항목 수가 해당 파이프라인의 페이즈 수와 일치(±세분 항목) | R2 |
| REQ-F-004 | 10분을 넘길 것으로 예상되는 페이즈만 내부 스텝으로 쪼개 추가 항목을 둘 수 있다 — 단, 메인 루프가 경계를 제어하는 스텝에 한정 | Should | 긴 페이즈에 내부 항목이 있으면 각각이 메인 루프 턴에서 갱신됨 | R2, R4 |
| REQ-F-005 | Workflow 한 방으로 도는 구간의 중간 진행은 Task 로 세분하지 않는다 — 대신 Workflow 스크립트의 phase()/log() 를 충실히 작성해 진행트리가 라이브 표시를 담당한다 | Must | Workflow 실행 중 Task 항목은 해당 페이즈 1개가 in_progress 로 유지되고, 진행트리에 phase/log 라인이 나타남 | R4 |
| REQ-F-006 | 컨벤션 텍스트는 craft-core(공유 파이프라인 문서 1곳 → forge/hunt/renew 자동 커버) + harness-run SKILL.md + linear-goal SKILL.md 에 삽입한다 | Must | 3개 파일 diff 에 컨벤션 섹션 존재; forge/hunt/renew 개별 SKILL.md 는 무변경 | R3, R6 |
| REQ-F-007 | harness-run 체크리스트 항목은 게이트 표기(G0~G4)를 유지한다 — 스크린샷과 동형 | Should | harness-run 실런에서 항목 텍스트에 게이트 라벨 포함 | R0 |

## 4. Non-functional requirements

| ID | Category | Requirement | Acceptance criteria | Origin |
|----|----------|-------------|---------------------|--------|
| REQ-N-001 | Compatibility | 파이프라인 실행 구조(Workflow 스크립트, 캐시/resume, 게이트 로직)는 변경 0 — 컨벤션은 텍스트 추가만 | diff 가 SKILL/reference 마크다운에 한정 | R4 |
| REQ-N-002 | 검증(발화율) | 실런 1회에서 3관찰 모두 성립해야 pass: ①시작 직후 생성 ②경계 전이 ③종료 시 전 항목 completed | 파이프라인 스킬 1개를 실작업으로 1회 실행해 관찰 | R5 |
| REQ-N-003 | 노이즈 | 항목 수 상한 — 기본 5~10, 세분 포함 15 미만 | 실런 체크리스트 항목 수 확인 | R2 |

## 5. Constraints & assumptions

- **Constraints:** Task 항목 갱신은 메인 루프만 가능(백그라운드 Workflow/subagent 는 불가).
  강제는 hook 으로 불가능(TaskCreate 강제 훅 없음) — 스킬 본문 컨벤션이 유일한 레버.
  스킬 변경 배포는 carpdm-skills repo 미러링(ship) 경유.
- **Assumptions resolved:** "글로벌 룰로 충분하다" — 기각(critical 룰 95% 무시 실측,
  karpathy-core 기록). "긴 페이즈도 Task 로 세분 가능" — 절반 기각(메인 루프 잠듦,
  Workflow 진행트리 위임으로 해소, R4). "렌더는 네이티브 Task 도구" — 확정(스크린샷이
  그 UI, R1).
- **Residual ambiguity:** 컨벤션 텍스트를 지켰는지의 장기 발화율은 실런 1회로만 검증
  (REQ-N-002) — 세션·모델별 편차 리스크는 남음. 반복 위반 관측 시 hook nudge(Out of
  scope 였던 옵션) 재검토.

## 6. Context (brownfield)

- 삽입 지점: `~/.claude/skills/craft-core/references/pipeline.md`(forge/hunt/renew 가
  공유 Read — Phase 구조가 이미 정의된 문서라 페이즈↔Task 매핑 서술의 자연 위치),
  `~/.claude/skills/harness-run/SKILL.md`(게이트 G0~G4 정의 보유),
  `~/.claude/skills/linear-goal/SKILL.md`.
- grep 실측: 세 스킬 어디에도 TaskCreate/TodoWrite 언급 없음 — 기존 동작과 충돌 없음.
  craft-core 의 기존 "체크리스트" 언급은 HTML eval 체크리스트(별개 개념) — 용어 충돌
  주의해 섹션명에 "Task 진행 체크리스트" 같은 구분 표기 필요.
- 보존 동작: output-contract(L1 result: 등)·pipeline Phase 구조·Workflow 스크립트 규격
  전부 무변경. blast radius = 마크다운 3파일.

## 7. Traceability — clarity trail

| Round | Ambiguity | Targeted dimension | Requirements pinned |
|-------|-----------|--------------------|---------------------|
| 0 | — | topology lock | A~D 전부 active |
| 1 | 63% | B.goal | REQ-F-001 (범위=스킬 파이프라인) |
| 2 | 63%→40% | D.goal | REQ-F-003, REQ-F-004 |
| 3 | 54% | C.goal | REQ-F-006 |
| 4 | 41% | D.constraints (contrarian) | REQ-F-005, REQ-N-001 |
| 5 | 40% | criteria (전 컴포넌트) | REQ-N-002 |
| 6 | 24% | B.context | REQ-F-006 명단 확정, REQ-F-007 |

## 8. Handoff

Recommended next skill: 스킬 문서 편집 작업 — `skill-creator:skill-creator`(기존 스킬
수정 전용) 또는 `/renew`(brownfield 변경, linear 강도). 소규모 텍스트 편집이라 직접
편집 후 실런 검증 → `ship` 배포도 유효한 최단 경로.

**Treat this spec as the completed requirements step.** 다음 스킬은 자체 인터뷰를
건너뛰고 이 번호 매긴 요구사항을 Phase-1 결과물로 받아 곧장 편집/plan review 로
진행할 것.
