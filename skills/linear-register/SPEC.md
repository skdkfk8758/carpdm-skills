# Requirements: linear-register — Linear 이슈 등록 + 적응형 추천 + 체인 전방 가이드

> Crystallized from a deep-interview on 2026-06-30. Final ambiguity: 18% (target ≤ 20%).
> Type: brownfield. Rounds: 7. Status: draft.

## 1. Goal & scope

주어진 이슈 아이디어를 Linear 에 **네이티브로 등록**하면서, 각 이슈에 (a) 그 작업에
적합한 글로벌 스킬/에이전트/워크플로우를 모델 판단으로 러프하게 추천하는 섹션을 덧붙이고,
(b) 의존 체인이면 다음 작업으로의 전방 포인터 + kickoff 프롬프트를 미리 심는 스킬.
근본 필요: "이슈를 등록한 뒤 *무엇으로 어떻게 이어가야 하나*"를 등록 시점에 함께 박아,
등록과 다음 행동 사이의 끊김을 없앤다.

**In scope:** C1 등록 코어 · C2 적응형 추천 섹션 · C3 연결 이슈 전방 가이드 · C4 기존 스킬 경계.
**Out of scope:** 대형 plan→다중 슬라이스 분할(to-issues 위임), 대화→PRD 합성(to-prd 위임),
기존 백로그 재배치·보강(linear-groom), 티켓 자율빌드 실행(linear-goal). 타repo 파일시스템 읽기.

## 2. Topology

| Component | Status | One-line role |
|-----------|--------|---------------|
| C1 등록 코어 | active | Linear MCP 로 이슈 생성 — 팀/프로젝트 라우팅, 본문/라벨/우선순위 |
| C2 적응형 추천 | active | 등록 이슈에 적합한 글로벌 스킬/에이전트 우선 추천 + 프로젝트 로컬 포인터(부차) |
| C3 체인 전방 가이드 | active | 의존 체인 등록 시 Linear 관계 세팅 + 다음 작업 포인터/프롬프트 심기 |
| C4 기존 스킬 경계 | active | a-메커니즘(Linear 독립 등록) + c-경계(니치 description, 분할/PRD 위임) |

## 3. Functional requirements

| ID | Requirement (the system SHALL…) | Priority | Acceptance criteria | Origin |
|----|----------------------------------|----------|---------------------|--------|
| REQ-F-001 | 사용자 제공 이슈 아이디어를 Linear MCP `save_issue`(`id` 없이 = 생성, `title`+`team` 필수)로 1건 이상 생성 | Must | 입력 1건 → Linear 에 이슈 1개 생성, identifier 반환 | R1 |
| REQ-F-002 | 타깃 팀을 현재 repo → `linear-repo-map.json` 역매핑으로 추론; 맵에 없으면 사용자에게 질의 | Must | 맵에 있는 repo 에서 호출 → 해당 teamId 자동 선택; 없는 repo → "어느 팀?" 질문 | R6 |
| REQ-F-003 | 프로젝트를 그 팀의 `list_projects` 에서 고르거나 사용자 확인 | Must | 생성 전 프로젝트가 결정/확인됨 (projectId 또는 명시적 "프로젝트 없음") | R6 |
| REQ-F-004 | 모든 Linear 쓰기 전, "X팀 / Y프로젝트 / N건" 확인을 제시하고 대기 — 단 사용자가 "바로 등록" 지시 시 스킵 | Must | 게이트 미승인 상태에서 `save_issue`(생성) 호출 0회; "바로 등록" 입력 시에만 게이트 없이 진행 | R6 |
| REQ-F-005 | 각 생성 이슈 본문에 "## 추천" 섹션 — **글로벌 스킬/에이전트 우선**(forge/hunt/renew/linear-goal/harness-run/to-issues/deep-plan + Explore/Plan), 이슈 타입·크기에 적응한 모델 판단 추천 | Must | bug 이슈 → hunt 류 추천; 큰 교차 기능 → harness-run/to-issues 류 추천; 섹션에 글로벌 후보 ≥1 명시 | R2,R3 |
| REQ-F-006 | "## 추천" 섹션에 프로젝트 로컬 스킬/에이전트 **경량 포인터**를 부차로 포함 — 타repo 를 읽지 않음 | Must | 섹션에 "해당 repo 의 `.claude/skills`/`.agents` 도 확인" 류 1줄; 타repo 파일 read 호출 0회 | R5 |
| REQ-F-007 | 대형 plan 분해 / PRD 합성 입력은 직접 처리하지 않고 to-issues/to-prd 위임을 추천 | Must | "이 plan 전체를 이슈로 쪼개줘" 류 입력 → 자체 분할 대신 to-issues 추천 출력 | R4 |
| REQ-F-008 | 의존 다건(체인) 등록 시 Linear 네이티브 관계(blocks/related/parent-child) 세팅 | Must | A→B→C 등록 → Linear 상 A blocks B, B blocks C 관계 존재 | R3 |
| REQ-F-009 | 체인의 각 이슈 본문 또는 코멘트에 다음 이슈 전방 포인터 + 붙여넣기용 kickoff 프롬프트 명시 | Must | 각 이슈에 "다음: <id>" + 시작 프롬프트 텍스트 포함 (마지막 이슈 제외) | R3 |
| REQ-F-010 | 등록 후 사용자에게 첫(또는 다음) 실행 가능 이슈의 kickoff 프롬프트를 응답으로 제시 | Must | 등록 종료 메시지에 즉시 복사 가능한 프롬프트 1개 포함 | R3 |
| REQ-F-011 | 스킬이 쓰는 모든 이슈 본문/코멘트에 짧은 AI 생성 표식 1줄 부착(한국어, 예 `> AI 가 등록·작성`) | Must | 생성된 이슈 본문 하단/코멘트에 disclaimer 줄 존재 | R7 |

## 4. Non-functional requirements

| ID | Category | Requirement | Acceptance criteria | Origin |
|----|----------|-------------|---------------------|--------|
| REQ-N-001 | Compatibility/trigger | description 을 "단건~소수 Linear 등록 + 추천 + 체인"으로 좁히고 분할→to-issues·PRD→to-prd 위임 명시 | description 에 위임 경계 문장 존재; to-issues/to-prd 와 트리거 충돌 시 이 스킬이 양보 | R4 |
| REQ-N-002 | Security/safety | 확인 게이트(REQ-F-004) 전 외부 쓰기 금지 | 게이트 미승인 시 Linear 쓰기 0회 | R6 |
| REQ-N-003 | Performance | 등록 시 타repo 파일시스템 read 안 함(경량) | 등록 경로에서 타repo Read/Grep 0회 | R5 |
| REQ-N-004 | Reuse | 라우팅을 `linear-repo-map.json` + `linear-dispatch` 역매핑 컨벤션 재사용(재구현 금지) | 팀 결정 로직이 repo-map 참조; 별도 매핑 테이블 신설 0 | R6 |

## 5. Constraints & assumptions

- **Constraints:** Linear-native(MCP `mcp__linear__*`)만 사용 — tracker-agnostic 팩 비의존,
  `setup-matt-pocock-skills` 의존 없음. 스킬은 `~/.claude/skills/linear-register/` 에 거주(잠정명).
- **Assumptions resolved:**
  - 스킬 정체 = (A) 등록기 + 추천 부록 — 추천은 부산물, 등록이 본업 (R1, confirmed)
  - 추천 = 모델 판단 기반 러프; 고정 lookup 테이블 아님 (R2-R3, confirmed)
  - 추천 우선순위 = 글로벌 스킬/에이전트 우선 → 프로젝트 로컬 포인터 부차 (R5, confirmed)
  - 체인 타이밍 = 등록 시점(빌드 완료 시점 아님) (R3, confirmed)
  - "연결된 이슈" = Linear 네이티브 관계; 배치 생성 시 관계 직접 세팅 (R3, confirmed)
  - 라우팅 = repo-map 추론 + 생성 전 확인 게이트 (R6, confirmed)
  - AI disclaimer = 부착 (R7, confirmed)
  - C4 = a-메커니즘 + c-경계 하이브리드; b-위임형 기각(팩 setup 결합 부채) (R4, confirmed)
- **Residual ambiguity:**
  - "## 추천" 섹션 정확한 헤딩/포맷 문구 — 빌드 단계 재량 (영향: REQ-F-005/006, 리스크 low)
  - 이슈 타입(bug/feature/refactor) 판별 방식 — 모델 판단에 위임, 명시 규칙 없음 (영향: REQ-F-005, 리스크 low)
  - 라벨/우선순위 자동 설정 여부 — 기본값 "명백하면 설정, 아니면 생략" (영향: REQ-F-001, 리스크 low)

## 6. Context (brownfield)

- **참고 팩(벤더, 심링크 `~/.agents/skills/`)** — `triage`(role 상태머신 + AI disclaimer 의무 + AGENT-BRIEF),
  `to-issues`(plan→vertical slice + Blocked-by 의존순 발행), `to-prd`(대화→PRD, 인터뷰 안 함).
  tracker-agnostic + `setup-matt-pocock-skills` per-repo 설정 의존 → REQ-N-001/C4 가 이들과 경계를 가름.
- **carpdm Linear 인프라** — `~/.claude/linear-repo-map.json`(repo→team 매핑, REQ-F-002/N-004 입력),
  `~/.claude/rules/linear-dispatch.md`(현재 repo→팀 스코프 역매핑 SSOT — REQ-F-002 가 동형 적용),
  Linear MCP(`create_issue`/`save_issue`/`create_comment`/`list_projects` — REQ-F-001/003/008/009),
  기존 `linear-goal`(티켓 자율빌드)·`linear-groom`(백로그 재배치) — Out of scope 로 경계.
- **Blast radius:** 신규 스킬 — 기존 스킬 코드 변경 없음. 유일 충돌면 = description 트리거(REQ-N-001 로 양보).

## 7. Traceability — clarity trail

| Round | Ambiguity | Targeted dimension | Requirements pinned |
|-------|-----------|--------------------|---------------------|
| 0 | — | topology lock | C1/C2/C3/C4 active |
| 1 | 65% | Goal (C2 정체) | — |
| 2 | 55% | Goal 정체 = (A) | REQ-F-001 |
| 3 | 48% | Criteria (C2 추천 신호) | REQ-F-005 |
| 4 | 40% | Context (C4 경계) | REQ-F-007, REQ-N-001 |
| 5 | 32% | Constraints (C2 깊이) | REQ-F-006, REQ-N-003 |
| 6 | 27% | Constraints (C1 라우팅) | REQ-F-002/003/004, REQ-N-002/004 |
| 7 | 22%→18% | Constraints (disclaimer) + C3 | REQ-F-008/009/010/011 |

## 8. Handoff

Recommended next skill: **`write-a-skill`** (또는 플러그인 `skill-creator:skill-creator`) — 산출물이
*새 스킬* 이므로 스킬 저작 도구가 정확 매칭. (forge 는 일반 greenfield 폴백.)

**Treat this spec as the completed requirements step.** 다음 스킬은 이 번호 매긴 요구사항을
이미 못 박힌 입력으로 받아 곧장 스킬 구조 설계로 진행 — 다시 인터뷰하지 말 것.
