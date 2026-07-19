# Requirements: 프로젝트 DESIGN.md 기반 실구현 충실 시안 스킬 (+기존 시안 로직 대체)

> Crystallized from a deep-interview on 2026-07-19. Final ambiguity: 18% (target ≤ 20%).
> Type: brownfield (글로벌 스킬 생태계 — deep-plan·craft-core·deep-prompt 시안 로직 수정).
> Rounds: 8. Status: draft.

## 1. Goal & scope

deep-plan·craft-core pipeline·deep-prompt 가 만드는 HTML 시안이 **실제 구현물과 빈번히
괴리**된다(실측: AUT-60 brands-menu 시안 vs 구현, ADType-Intelligence 작업 다수). 원인은
시안이 프로젝트의 디자인 실체(토큰·컴포넌트 어휘·밀도·기술 제약)를 읽지 않고 즉흥
창작되기 때문. 신규 스킬은 시안 작성 전 프로젝트 `DESIGN.md`(와 그것이 가리키는 코드
SSOT)에서 **design context 를 추출**하고, 시안이 그 계약을 지켰는지 **기계+사람으로
검증**한다. 기존 세 call site 의 inline 시안 로직은 이 스킬의 reference 로 대체된다.

**In scope:** 신규 스킬 본체(A) · DESIGN.md 발견/해석 계약(B) · 기존 로직 대체(C).
**Out of scope:**
- `erd` 스킬 — DB 스키마 도식은 디자인 토큰과 무관 (R5 확정).
- `imprint` 계열(외부 사이트 추출 DESIGN.md → React+Tailwind 테마 생성, `docs/specs/design-md-conformance-skill.md`) — 입력·목적 상이. 경계만 문서화.
- 시안 publish 규칙 자체의 변경 — `html-mockup-artifact.md` 는 그대로 계승.

## 2. Topology

| Component | Status | One-line role |
|-----------|--------|---------------|
| A 신규 스킬 본체 | active | design context 추출 → 시안 렌더/위임 → 검증 |
| B DESIGN.md 해석 계약 | active | 이질 포맷(포인터형/인라인형) 해석 + 부재 폴백 |
| C 기존 로직 대체 | active | 3 call site 배선 교체 + YAGNI 삭제 |
| D 제작 프로세스(skill-creator 경유·eval) | deferred | 실행 방식으로 수용, 요구사항 대상 아님 (R0) |

## 3. Functional requirements

| ID | Requirement (the system SHALL…) | Priority | Acceptance criteria | Origin |
|----|----------------------------------|----------|---------------------|--------|
| REQ-F-001 | 시안 작성 전 **design context** 를 추출한다 — ① 토큰 값 집합(색·radius·font·spacing) ② 컴포넌트/class 어휘 ③ 미감 원칙·하드룰 ④ 대표 실화면 1~2개 경로 ⑤ 브레이크포인트 ⑥ 모션 규칙 ⑦ 실화면 스크린샷(best-effort). 각 항목은 "없음(사유)" 명시 허용 — 빈칸 금지 | Must | 시안 산출 전 7항목이 채워진(또는 없음 명시된) context 블록이 보고에 존재 | R7·R8 |
| REQ-F-002 | `DESIGN.md` 를 진입점으로 삼되, 값이 인라인 표면 그대로 쓰고 **포인터형이면 가리키는 코드**(예: `theme.ts`·`globals.css` 헤더)를 추적해 실값을 확보한다 | Must | 포인터형(IA)·인라인형(review-radar/ADMap) 양쪽에서 토큰 실값 추출 성공 — 실측 검증 완료(R8) | R6·R8 |
| REQ-F-003 | DESIGN.md 부재/부실 시 코드 직접 스캔(theme·globals·기존 페이지)으로 추출을 시도하고, 부재 사실을 보고하며 DESIGN.md 백필 생성을 제안한다 | Must | DESIGN.md 없는 프로젝트에서 호출 → 시안은 산출되고 보고에 "DESIGN.md 없음 + 백필 제안" 명시 | R4 |
| REQ-F-004 | 시안은 **4축 계약**을 지킨다 — ① 디자인 토큰 실값 일치 ② 기존 컴포넌트 어휘 재사용(새 스타일 발명 금지) ③ 실화면 수준 레이아웃 밀도 ④ 실스택이 표현 못 하는 것 미포함 | Must | 4축 각각에 대해 위반 예시가 시안에서 발견되지 않음 (①은 REQ-F-005 기계 체크, ②~④는 REQ-F-006 사람 리뷰) | R2·R3 |
| REQ-F-005 | 시안 산출 후 **기계 검증**을 실행한다 — 시안 HTML 내 색상값(및 radius 등 수치 토큰)이 추출된 토큰 집합의 부분집합인지 체크, 위반 시 수정 후 재검증 (review-radar `design-lint.sh` 패턴의 일반화) | Must | 토큰 집합 밖 raw 값 주입 시 체크가 fail 을 보고하고, 통과 시안은 위반 0 | R5·R8 |
| REQ-F-006 | **사람 판정**을 지원한다 — 시안 리뷰 시점에 대표 실화면 참조(파일 경로, 가용하면 스크린샷)를 시안과 나란히 제시한다 | Must | 시안 보고에 실화면 참조가 동반됨 | R5 |
| REQ-F-007 | 재사용할 기존 화면 어휘가 없는 **net-new UI** 면 전문 스킬(frontend-design 등)에 위임하되 추출된 토큰 계약을 주입하고, 위임 결과에도 REQ-F-005 검증을 돌린다 | Should | 위임 경로 산출물도 토큰 부분집합 체크를 통과 | R6 |
| REQ-F-008 | 인터페이스는 **혼합형** — 사람이 직접 호출하는 standalone 스킬 + 스킬 간 소비용 공유 reference(추출 절차·4축 계약·검증법) 이중 진입 | Must | "시안 만들어줘" 직접 트리거 동작 + 세 스킬이 reference 경로를 로드 | R7 |
| REQ-F-009 | 3 call site 를 대체한다 — `deep-plan` Step 3 · `craft-core` pipeline Phase 1 companion · `deep-prompt` §3.5 의 inline 시안 규칙을 신규 reference 포인터로 교체. `erd` 는 제외 | Must | 세 스킬 본문 grep: 옛 inline 시안 규칙 이중화 0, 신규 reference 포인터 존재 | R5·R6 |
| REQ-F-010 | 시안 산출 규약 계승 — self-contained(외부 asset 0)·"mockup" 표식·Artifact publish(`html-mockup-artifact.md`) 를 그대로 따른다 | Must | 산출 시안이 기존 룰의 체크리스트를 통과 | R1 |

## 4. Non-functional requirements

| ID | Category | Requirement | Acceptance criteria | Origin |
|----|----------|-------------|---------------------|--------|
| REQ-N-001 | SSOT 단일성 | 시안 생성 로직 본문은 신규 스킬 references 한 곳에만 산다 — 세 call site 에는 포인터만 | 로직 본문 grep 시 신규 스킬 밖 중복 0 | R7 |
| REQ-N-002 | YAGNI | 대체로 호출처가 사라지는 옛 inline 규칙·중복 문구는 **같은 커밋**에서 제거 | 대체 커밋 diff 에 삭제 포함, "다음 PR" 이월 없음 | R5 |
| REQ-N-003 | 배포/경계 | carpdm-skills 컨벤션(SKILL.md+references, 한국어 본문) 준수, `imprint`·`frontend-design` 과의 차별점을 description 에 명시(트리거 혼선 방지) | 스킬 description 만 읽고 세 스킬 중 무엇을 쓸지 구분 가능 | R8 |
| REQ-N-004 | E2E acceptance | 실전 1회 — DESIGN.md 보유 프로젝트(IA 등)에서 시안 1건 생성 → 기계 체크 통과 + 사용자 시각 승인 | 통과 기록이 대체 PR 에 첨부 | R8 |

## 5. Constraints & assumptions

- **Constraints:**
  - DESIGN.md 포맷은 이질적 — 포인터형(IA 58줄)·인라인 대형(ADMap 438줄)·인라인+lint(review-radar 86줄) 3종 실측. 파서가 아니라 **해석 절차**(모델이 읽는 지침)로 대응.
  - 스크린샷(⑦)은 실행 중인 앱 필요 — dev URL·브라우저 가용 시에만 best-effort, 실패해도 시안 산출을 막지 않음.
  - 스킬 생태계는 markdown — 자동 테스트 스위트 없음. 검증 = E2E(REQ-N-004) + grep(REQ-F-009).
- **Assumptions resolved:**
  - "괴리" 는 실재하며 cross-project — 확인 (R1: AUT-60 + Intelligence 다수).
  - 4축 전부가 계약 — 확인 (R2 "모두").
  - DESIGN.md 존재 전제 아님 — 스캔 폴백 + 백필 제안 (R4 "a+c").
  - 전문 스킬은 제거가 아니라 토큰 계약 주입 위임으로 통합 (R6).
  - design context 7항목 전부 채택, 스크린샷만 조건부 (R8 실측 검증).
- **Residual ambiguity:** 신규 스킬 이름 미정(skill-creator 가 결정 — 가칭 `mockup`); 기계 체크의 구현 형태(reference 절차 vs 동봉 스크립트)는 빌드 시 결정 — REQ-F-005 의 판정 기준은 형태와 무관.

## 6. Context (brownfield)

| 통합 지점 | 파일 | 현재 동작 → 변경 |
|---|---|---|
| deep-plan Step 3 | `~/.claude/skills/deep-plan/SKILL.md` (시안 섹션 + "시안을 누가 만드나" 라우팅) | inline 기본 + 전문 스킬 제안 → 신규 reference 위임. 전문 스킬 라우팅은 REQ-F-007 로 흡수 |
| craft-core Phase 1 | `~/.claude/skills/craft-core/references/pipeline.md` (HTML companion 규칙, forge/hunt/renew 공용) | inline companion 작성 → 신규 reference 위임. Phase 4 시안충실도 게이트는 보존(사후 대조 — REQ-F-005 의 사전 검증과 상보) |
| deep-prompt §3.5 | `~/.claude/skills/deep-prompt/SKILL.md` | inline mockup 작성 → 신규 reference 위임 |
| publish 규칙 | `~/.claude/rules/html-mockup-artifact.md` | 유지. "적용 대상" 목록에 신규 스킬 추가만 |
| 보존 | `erd`·`imprint`·기존 시안 파일들 | 불변 |

배포 경로: 스킬 SSOT = `~/.claude/skills/` ↔ `carpdm-skills` repo 미러 — 변경은 `ship` 스킬로 land.

## 7. Traceability — clarity trail

| Round | Ambiguity | Targeted dimension | Requirements pinned |
|-------|-----------|--------------------|---------------------|
| 0 | — | topology lock (A·B·C active, D deferred) | — |
| 1 | 57% | A goal (괴리 실재) | Goal 근거 |
| 2 | 52% | A goal (괴리 종류) | REQ-F-004 |
| 3 | 44% | B constraints (부재 폴백) | REQ-F-003 |
| 4 | 42% | A criteria (판정 방식) | REQ-F-005·006 |
| 5 | 41% | C scope (call site·erd 제외) | REQ-F-009, N-002 |
| 6 | 31% | C 통합 (전문 스킬 활용) | REQ-F-007 |
| 7 | 29% | C 인터페이스 (혼합형) | REQ-F-008, N-001 |
| 8 | 22→18% | B criteria (7항목 실측 검증) + C criteria (E2E) | REQ-F-001·002, N-004 |

## 8. Handoff

Recommended next: **`/skill-creator:skill-creator`** — 사용자 명시 경로. 본 spec 을
완료된 요구사항 단계로 취급하고 재인터뷰 없이 스킬 저작으로 직행: ① 신규 스킬
생성(A·B — REQ-F-001~008·010) ② 3 call site 대체(C — REQ-F-009, N-001·002) ③ E2E
검증(N-004) ④ `ship` 으로 carpdm-skills land.
