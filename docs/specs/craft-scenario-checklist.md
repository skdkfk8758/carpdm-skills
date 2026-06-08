# Requirements: craft-core 검증을 자동 TDD floor + 플랜 파생 사람 체크리스트로 재편

> Crystallized from a deep-interview on 2026-06-08. Final ambiguity: 20% (target ≤ 20%).
> Type: brownfield. Rounds: 7 (R0 topology + R1–R6). Status: draft.

## 1. Goal & scope

craft-core 파이프라인의 검증 방식을 바꾼다: 자동 TDD 는 **최소 floor**(회귀 취약 +
보안 + 결정론적 로직)로 유지하고, 그 위에 **플랜에서 파생된 사람이 직접 도는
acceptance 체크리스트**를 얹는다. 목적 — AI 가 자기 코드에 맞춰 쓴 자동 테스트가
놓치는 *의도/UX* 검증을 사람 판단으로 보강하되, 회귀 잠금은 여전히 자동에 맡겨
자율 실행을 깨지 않는다.

**In scope:** A(시나리오/체크리스트 정의·형식), B(Phase 3/4 사이클 변경 — 자동 floor
+ 사람 체크리스트 레이어 추가), C(플랜을 체크리스트 원천으로 사용).
**Out of scope:** D(작업유형별 forge/hunt/renew 체크리스트 진입점 차별화) — deferred.
Phase 2 codex 플랜 리뷰 자체 변경 — 건드리지 않음.

## 2. Topology

Round 0 에서 고정:

| Component | Status | One-line role |
|-----------|--------|---------------|
| A 시나리오 정의·형식 | active | 체크리스트가 무엇이고 어떤 항목 형태인가 |
| B Phase 사이클 변경 | active | 자동 floor + 사람 체크리스트 레이어를 파이프라인에 슬롯 |
| C 플랜 검사(원천) | active | 플랜을 체크리스트의 source of truth 로 사용 |
| D 작업유형별 진입점 | deferred | forge/hunt/renew 별 체크리스트 차이 — 이번 범위 밖 |

## 3. Functional requirements

| ID | Requirement (the system SHALL…) | Priority | Acceptance criteria | Origin |
|----|----------------------------------|----------|---------------------|--------|
| REQ-F-001 | Phase 3 구현 완료 후, 플랜의 Acceptance 섹션에서 파생된 검증 체크리스트를 `.md` 로 생성한다 | Must | forge/hunt/renew 샘플 실행 → 플랜 Acceptance 의 각 조건이 체크리스트 항목으로 1:1 나타남 | R2 |
| REQ-F-002 | 각 체크리스트 항목은 `[AUTO]` 또는 `[HUMAN]` 으로 태그된다 | Must | 모든 항목에 둘 중 하나의 태그가 있고, 미분류 항목이 0 | R6 |
| REQ-F-003 | 경계 규칙 적용: `[AUTO]` = 기계가 결정론적으로 단언 가능 AND 매 변경 재확인 필요(회귀); `[HUMAN]` = 판단 필요 OR 자동화 비용>가치인 일회성 UX/의도 | Must | 표준 예: `빈 비번→400`=AUTO, `bcrypt cost 12`=AUTO, `302→/dashboard`=AUTO, "화면 안 깨짐"(시각)=HUMAN 으로 분류됨 | R4 |
| REQ-F-004 | `[AUTO]` 항목은 Phase 3 자동 테스트(red→green→refactor)가 커버한다 — "최소 TDD" floor | Must | 모든 `[AUTO]` 항목에 대응하는 자동 테스트가 존재하고 green | R5 |
| REQ-F-005 | `[HUMAN]` 항목은 체크리스트에 사람 실행용으로 나열된다(pass/fail 기록 칸 포함) | Must | 각 `[HUMAN]` 항목에 체크 가능한 칸이 있음 | R2 |
| REQ-F-006 | 기본 동작은 **non-blocking**: 사람 없이 파이프라인 완주 + 체크리스트 생성 | Must | 비고위험 작업 dry-run 이 사람 개입 없이 Phase 5 까지 완주하고 체크리스트 파일을 남김 | R5 |
| REQ-F-007 | **고위험** 작업에서는 Phase 4 가 사람 체크리스트 pass 까지 출시(Phase 5)를 막는다(blocking) | Must | auth/payments/계약변경/6+파일 조건 작업에서 `[HUMAN]` 미완 시 Phase 5 진입 차단 | R5 |

## 4. Non-functional requirements

| ID | Category | Requirement | Acceptance criteria | Origin |
|----|----------|-------------|---------------------|--------|
| REQ-N-001 | Compatibility | 기존 Phase 2(codex 플랜 리뷰)와 다른 phase 동작은 변경되지 않는다 | dry-run 에서 Phase 0–2·5 산출물이 변경 전과 동일 형태 | R3 |
| REQ-N-002 | Security | 보안 불변식(bcrypt cost, auth 경계 등)은 항상 `[AUTO]` — 절대 HUMAN-only 로 강등 금지 | 보안 항목이 `[HUMAN]` 단독 태그를 받으면 분류 실패로 간주 | R4 |
| REQ-N-003 | Autonomy | 기본(non-blocking) 경로는 사람 없이 자율/백그라운드 실행 가능해야 한다 | 비고위험 작업이 사람 입력 대기 없이 완주(REQ-F-006 과 동일 신호) | R5 |

## 5. Constraints & assumptions

- **Constraints:** TDD 완전 제거 금지 — 최소 floor 유지(R6 확정). 고위험 게이팅은
  *새 메커니즘을 발명하지 말고* 기존 craft-core "Execution mode" stakes/council
  에스컬레이션 트리거(auth/payments/계약변경/6+파일)에 연동한다.
- **Assumptions resolved:**
  - 체크리스트 source of truth = **플랜**(구현체 아님): 확정(R3) — 구현체 기반은
    동어반복(코드가 한 일을 검사) 리스크라 배제.
  - "사용자가 테스트" = **사람이 직접 도는** 체크리스트: 확정(R2).
  - 게이팅 = **조건부**(기본 non-blocking + 고위험 blocking): 확정(R5).
- **Residual ambiguity:**
  - 체크리스트 파일 정확 경로/포맷(플랜 `.md` 옆 vs `docs/checklists/`) — 미확정,
    REQ-F-001/F-005 에 영향. plan 단계에서 결정.
  - 기존 "Acceptance 테스트가 곧 항목"(pipeline.md Phase 1/4)과 새 `[AUTO]`/`[HUMAN]`
    분리의 정합 — 어디까지 기존 Acceptance 섹션을 재사용/대체할지 plan 에서 조율 필요.
  - Component D(작업유형별 차이) deferred — 후속 인터뷰.

## 6. Context (brownfield)

실제 읽은 코드 기준 통합 지점:

- `~/.claude/skills/craft-core/references/pipeline.md`
  - **Phase 1** — 플랜 Acceptance 섹션("번호 매긴 단일 checkable 조건"). 체크리스트의
    원천(REQ-F-001). 새 분리와의 정합이 Residual ambiguity.
  - **Phase 3** — `dynamic-tdd.md` red→green→refactor. `[AUTO]` floor 가 여기 매달림(REQ-F-004).
  - **Phase 4** — secure verify 가 *이미* 플랜 Acceptance 를 pass/fail 체크. 고위험
    blocking 게이트(REQ-F-007)가 자연스럽게 붙는 자리.
  - **"Execution mode"** — stakes signal → council 에스컬레이션 트리거. REQ-F-007 게이팅이
    재사용할 조건(REQ-N constraints).
- `~/.claude/skills/craft-core/references/dynamic-tdd.md` — opus pin·red-green 규율. floor 의 기존 계약.
- 영향 스킬: `forge`/`hunt`/`renew`(공유 엔진 소비) — 진입점 차별화는 D(deferred).

## 7. Traceability — clarity trail

| Round | Ambiguity | Targeted dimension | Requirements pinned |
|-------|-----------|--------------------|---------------------|
| R0 | — | topology lock | A/B/C active, D deferred |
| R1 | 63% | goal (질문의 질문 — 산출물 성격) | brownfield/craft-core 변경 확정 |
| R2 | 54% | goal (clarification — 시나리오 정의) | REQ-F-001, REQ-F-005 |
| R3 | 49% | constraints (probing — source of truth) | source=플랜 확정 |
| R4 | 38% | goal (contrarian — 회귀 vs 사람) | REQ-F-003, REQ-N-002 |
| R5 | 31% | constraints (implications — 게이팅) | REQ-F-004, F-006, F-007, REQ-N-003 |
| R6 | 20% | criteria (reasons/evidence) | REQ-F-002 + acceptance 전체 확정 |

## 8. Handoff

Recommended next skill: **`/renew`** — 기존 craft-core 파이프라인의 동작을 변경하는
brownfield 작업이다(새 능력 추가가 아니라 검증 단계 재편 + 호환성 보존 중요).

**Treat this spec as the completed requirements step.** `/renew` 는 기본적으로 자체
Socratic 인터뷰를 돈다 — 건너뛰라. 이 번호 매긴 요구사항을 고정된 Phase-1 산출물로
넣고 곧장 plan review(Phase 2)로 가서, 처음부터 재인터뷰하지 말 것.
