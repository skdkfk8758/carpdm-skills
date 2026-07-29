---
name: craft-core
description: forge / renew / hunt 개발 스킬을 위한 내부 공유 엔진. 직접 호출하지 않음 — 해당 스킬들이 이 reference 파일들을 읽는다.
user-invocable: false
---

# Craft Core

공유 4-phase 개발 엔진: **Socratic 인터뷰 → plan review 게이트
(상류 리뷰면 스킵, 고위험만 codex 1-pass) → dynamic-workflow TDD →
codex diff 리뷰 포함 보안 검증**. 3종의 작업유형 스킬(`forge`,
`renew`, `hunt`)은 각자 자신의 Socratic 초점과 TDD 진입점을 얹은 뒤
이 엔진을 돌린다.

이 스킬은 공유 reference 들의 컨테이너다. 단독으로 트리거하지 말 것.

## References

- `references/pipeline.md` — 전체 4-phase 파이프라인 (척추).
- `references/socratic.md` — Phase 1 의 Socratic 질문법.
- `references/codex-review.md` — codex-companion 직접 호출(`codex:rescue` 경유 아님)
  1-pass 리뷰 공통 계약 — 호출 규약·verdict 파싱·triage 원장·watchdog SSOT
  (소비처: Phase 2 폴백·security.md §2·deep-plan 호출 규약).
- `references/dynamic-tdd.md` — `Workflow` 도구 기반 태스크 분할 + TDD (모델 규칙 SSOT).
- `references/simplify-pass.md` — Phase 3.5 선택적 정리 패스 (`/simplify` 위임).
- `references/security.md` — 보안 검증 (Phase 4).
- `references/ui-verify.md` — UI 인수 검증: 인터랙션 실구동 + 시안 갭 분석 (Phase 4, UI 빌드만)
  + **잔여 인계** (체크리스트 아티팩트 2건+ / dev 서버 살려서 넘기기 1건+, §5·§5.1 —
  **표면 무관**, 비UI 빌드는 Phase 5 가 이 두 절만 읽는다).
- `references/context-adr.md` — grounding 을 위한 ADR/concept/guide 읽기 (Phase 1),
  영속적 결정을 위한 ADR & concept 문서 작성/관리 (Phase 5).

작업유형 스킬이 여기로 안내한다. `pipeline.md` 를 먼저 읽고, 나머지는
각 phase 가 필요로 할 때 끌어와라.
