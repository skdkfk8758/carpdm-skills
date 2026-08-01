---
name: claude-craft-core
description: Imported Claude shared workflow references used by planning, build, review, and handoff skills.
user-invocable: false
---

# Craft Core

공유 4-phase 개발 엔진: **Socratic 인터뷰 → 적대적 플랜 리뷰
(codex) → opus 에서의 dynamic-workflow TDD → 보안 검증**. 3종의
작업유형 스킬(`forge`, `renew`, `hunt`)은 각자 자신의
Socratic 초점과 TDD 진입점을 얹은 뒤 이 엔진을 돌린다.

이 스킬은 공유 reference 들의 컨테이너다. 단독으로 트리거하지 말 것.

## References

- `references/pipeline.md` — 전체 4-phase 파이프라인 (척추).
- `references/socratic.md` — Phase 1 의 Socratic 질문법.
- `references/codex-review.md` — `codex:rescue` 를 통한 적대적 플랜 리뷰.
- `references/dynamic-tdd.md` — `Workflow` 도구 기반 태스크 분할 + opus 에서의 TDD.
- `references/simplify-pass.md` — Phase 3.5 선택적 정리 패스 (`/simplify` 위임).
- `references/security.md` — 보안 검증 (Phase 4).
- `references/context-adr.md` — grounding 을 위한 ADR/concept/guide 읽기 (Phase 1),
  영속적 결정을 위한 ADR & concept 문서 작성/관리 (Phase 5).

작업유형 스킬이 여기로 안내한다. `pipeline.md` 를 먼저 읽고, 나머지는
각 phase 가 필요로 할 때 끌어와라.
