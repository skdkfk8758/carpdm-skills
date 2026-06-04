# Requirements: DESIGN.md 충실 재현 UI 생성 스킬

> Crystallized from a deep-interview on 2026-06-04. Final ambiguity: 19.5% (target ≤ 20%).
> Type: greenfield. Rounds: 7. Status: draft.

## 1. Goal & scope

design-extractor.com 이 사이트에서 추출해 내려주는 `DESIGN.md`(colors/typography/
spacing/tokens) 파일 하나를 입력으로 받아, **그 디자인 시스템에 충실하게(conformance)**
React+Tailwind 테마 + 예시 컴포넌트 + 독립 HTML 시안을 생성하는 신규 Claude Code
스킬. 핵심 가치는 "멋진 미감을 발명"이 아니라 "주어진 token 을 한 톨도 벗어나지 않고
재현"하는 것 — 기존 `frontend-design` 스킬(자유 창작)과 정반대 축.

**In scope:** DESIGN.md 파싱 → Tailwind 테마(token) 생성 → React+Tailwind 예시
컴포넌트 → 독립 HTML 시안. token 부재 시 파생 token 합성·기록. carpdm-skills 신규
스킬로 저작·배포.
**Out of scope:**
- design-extractor 호출/스크레이프 (공개 API 없음 — 추출은 사람이 웹에서 수동, 산출물 DESIGN.md 만 받음).
- URL/스크린샷에서 스킬이 직접 token 추출 (mode 2/3 기각).
- `frontend-design` 의 자유 미감 창작 — 이 스킬은 token 을 벗어나는 디자인을 만들지 않는다.

## 2. Topology

Round 0 에서 고정 — 5개 전부 active (deferred 없음, 넓은 토폴로지):

| Component | Status | One-line role |
|-----------|--------|---------------|
| A Design source | active | 입력 = `DESIGN.md` 파일 경로 (design-extractor 가 사람 손으로 생성한 산출물) |
| B Generation core | active | theme(token) + 예시 컴포넌트 생성 — theme 이 1차 산출물, 컴포넌트는 데모 |
| C Output/delivery | active | token 파일(Tailwind config+CSS var) · React+Tailwind 코드 · 독립 HTML 시안 |
| D frontend-design 경계 | active | 별도 스킬. 차별점 = DESIGN.md 충실 재현(conformance) vs 자유 창작 |
| E 스킬 형태/배포 | active | carpdm-skills 신규 스킬 (SKILL.md + references), install.sh 배포 |

## 3. Functional requirements

| ID | Requirement (the system SHALL…) | Priority | Acceptance criteria | Origin |
|----|----------------------------------|----------|---------------------|--------|
| REQ-F-001 | `DESIGN.md` 파일 경로를 입력으로 받아 token(색/타이포/스페이싱/기타)을 파싱한다 | Must | 유효한 DESIGN.md → 발견한 token 집합을 보고; 없거나 깨진 파일 → 명확한 에러 | R2 |
| REQ-F-002 | 파싱된 token 으로 Tailwind 테마(config theme extension + CSS 변수)를 생성한다 | Must | DESIGN.md 의 모든 token 이 테마에 named entry 로 1:1 매핑, 누락 0 | R5 |
| REQ-F-003 | 테마를 쓰는 React+Tailwind 예시 컴포넌트를 생성한다 | Must | 컴포넌트가 테마 token(Tailwind 클래스/CSS var)만 사용, 에러 없이 렌더 | R5 |
| REQ-F-004 | 빌드 없이 브라우저에서 바로 열리는 독립(self-contained) HTML 시안을 생성한다 | Must | HTML 단독으로 테마 적용된 컴포넌트 미리보기 표시, 외부 빌드 단계 불필요 | R5 |
| REQ-F-005 | DESIGN.md 에 없는 값(radius/shadow/hover·focus·disabled state/transition 등)이 필요하면 기존 token 에서 **파생**해 테마에 "derived" 로 명시 기록한다 | Must | 그런 값 전부가 테마에 named derived token 으로 존재, 인라인 하드코딩 0 | R6 |
| REQ-F-006 | DESIGN.md 없이 호출되면 design-extractor gallery 를 출처로 안내하고 사전추출 가능 사이트 목록을 hint 로 제시한다 | Could | DESIGN.md 부재 시 gallery URL + 사용법 안내 출력 | R1 |

## 4. Non-functional requirements

| ID | Category | Requirement | Acceptance criteria | Origin |
|----|----------|-------------|---------------------|--------|
| REQ-N-001 | Correctness/Conformance (**핵심**) | token-traceability — 생성된 테마·컴포넌트·시안의 모든 색/크기 값이 DESIGN.md token 또는 기록된 derived token 으로 역추적된다. 하드코딩 raw 값 0 | 컴포넌트·시안 출력에서 raw hex(`#xxxxxx`)·raw px/rem 리터럴 grep → 테마 token 정의부 밖에서 0건 | R5/R6 |
| REQ-N-002 | Identity | frontend-design 과 구분 — 주어진 시스템을 *준수*할 뿐 새 미감을 발명하지 않는다 | DESIGN.md 또는 그 파생으로 도출 불가능한 디자인 값을 스킬이 도입하지 않음 | R3 |
| REQ-N-003 | Deploy/convention | carpdm-skills 컨벤션 준수 — SKILL.md+references, 본문 한국어·식별자 영어, README 스킬 표 갱신, install.sh 설치 가능 | install 후 `ls ~/.claude/skills/` 에 표시; guard-readme-fresh 통과 | R0 |

## 5. Constraints & assumptions

- **Constraints:**
  - 출력 스택 고정 = React + Tailwind.
  - design-extractor 공개 API 없음 (UI 전용). DESIGN.md 는 사람이 수동 생성해 스킬에 *파일로* 건넨다 — 스킬은 네트워크 호출 안 함.
  - 스킬 아티팩트 = 마크다운 (레포에 테스트 스위트 없음 — 검증은 install + grep 기반 traceability 체크).
  - 설치 경로 `~/.claude/skills/` 고정 컨벤션.
- **Assumptions resolved:**
  - "스킬이 URL 받아 자동 추출 소비" → **기각**: design-extractor API 부재 확인(WebFetch). 입력은 DESIGN.md 파일 (R2 확정).
  - "충실 재현이 핵심, 별도 스킬" → 확정 (R3).
  - "token-traceability 가 최소 통과선" → 확정, visual resemblance 는 게이트 아님 (R5).
  - "없는 값은 derive 해서 기록" → 확정, restrict/flag 기각 (R6).
  - html 시안 = 독립 self-contained HTML 미리보기 (React 빌드 불요) → 가정, low-risk (R5 해석).
- **Residual ambiguity:**
  - DESIGN.md 의 정확한 스키마/필드 — 실제 샘플 파싱 전까지 미확정. REQ-F-001/002 에 영향. **리스크 낮음**: 빌드 시 실제 샘플로 발견, 스킬은 DESIGN.md 실제 내용에 맞춰 파싱하도록 구현.
  - 예시 컴포넌트의 개수·구성 미고정. REQ-F-003. 기본값: 대표 세트(Button/Card/Input/Nav 등). 리스크 낮음.
  - 출력 파일 저장 위치 미고정. 기본값: 생성 시 유저 확정. 리스크 낮음.

## 6. Context

greenfield (신규 능력). 단 carpdm-skills 레포 컨벤션에 묶임:
- 기존 `frontend-design` 스킬과 트리거 경쟁 주의 — description 을 "DESIGN.md/추출된 디자인 시스템 충실 재현"으로 좁혀 frontend-design(자유 창작)과 분리 (REQ-N-002).
- craft-core 의존 없음 (handoff/sweep/land/summon 처럼 단독 스킬). craft 파이프라인 안 탐.
- README 스킬 표·카운트 갱신 필수 — guard-readme-fresh 차단형 훅 (REQ-N-003).

## 7. Traceability — clarity trail

| Round | Ambiguity | Targeted dimension | Requirements pinned |
|-------|-----------|--------------------|---------------------|
| 0 | — | topology lock | A·B·C·D·E (5 active) |
| 1 | 70% | goal/source mechanic | REQ-F-006 (URL hint) |
| 2 | 69% | goal (가정 붕괴: API 부재) | 입력 재정의 → DESIGN.md |
| 3 | 57% | goal/boundary (D) | REQ-N-002 (conformance identity) |
| 4 | 51% | constraints (생성 범위) | B 모델 3, React+Tailwind |
| 5 | 42% | criteria (측정 가능 done) | REQ-F-002/003/004, REQ-N-001 |
| 6 | 28% | constraints (token-gap) | REQ-F-005 (derive 규칙) |
| 7 | 19.5% ✓ | — (gate 통과) | crystallize |

## 8. Handoff

Recommended next skill: **`skill-creator`** (신규 스킬 정의 저작 — 이 아티팩트 타입에
정확히 맞음). 대안 **`/forge`** (레포의 범용 신규-능력 파이프라인이나 Phase 3 TDD 가
마크다운 스킬 저작에 깔끔히 매핑되지 않음 — 레포에 테스트 스위트 없음).

Intensity: **linear** 권장. 토폴로지는 넓었으나(5 active) 7라운드로 빠르게 수렴,
entity 안정, ontologist 미발동, 게이트 도달. 5개 컴포넌트는 런타임 상호의존 모듈이
아니라 개념 분해 — council 의 적대적 디자인 공격이 줄 이득이 작다. 마크다운 저작
작업이라 design 리스크 낮음.

**Treat this spec as the completed requirements step.** 추천 스킬은 기본적으로 자체
Socratic 인터뷰를 도는데 — 건너뛸 것. 이 번호 매긴 요구사항을 못 박힌 Phase-1
산출물로 먹이고 곧장 plan/구현으로 진행해, 처음부터 다시 인터뷰하지 말 것.
