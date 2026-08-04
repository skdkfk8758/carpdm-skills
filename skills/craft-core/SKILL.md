---
name: craft-core
description: 스킬 공통 참조 자료(파이프라인·소크라테스·TDD·적대리뷰·보안·출력계약·UI검증). 직접 호출하지 않음 — 다른 스킬들이 이 reference 파일들을 경로로 읽는다.
user-invocable: false
---

# Craft Core

공유 4-phase 개발 엔진: **Socratic 인터뷰 → plan review 게이트
(상류 리뷰면 스킵, 고위험만 적대 1-pass) → dynamic-workflow TDD →
correctness diff 리뷰 포함 보안 검증**. 이 자료를 읽는 스킬들은 각자 자신의 초점을 얹은 뒤
이 엔진을 돌린다.

이 스킬은 공유 reference 들의 컨테이너다. 단독으로 트리거하지 말 것.

## References

- `references/pipeline.md` — 전체 4-phase 파이프라인 (척추).
- `references/socratic.md` — Phase 1 의 Socratic 질문법.
- `references/adversarial-review.md` — 적대 리뷰 1-pass 공통 계약 — 프롬프트 골격·
  verdict 파싱·triage 원장 SSOT (소비처: Phase 2 잔여·security.md §2 폴백·deep-plan
  debate 라운드). cross-model(codex)은 2026-07-30 은퇴 — 같은 모델 + 역할 분리다.
- `references/dynamic-tdd.md` — `Workflow` 도구 기반 태스크 분할 + TDD (모델 규칙 SSOT).
- `references/security.md` — 보안 검증 (Phase 4).
- `references/ui-verify.md` — UI 인수 검증: 인터랙션 실구동 + 시안 갭 분석 (Phase 4, UI 빌드만)
  + **잔여 인계** (체크리스트 아티팩트 2건+ / dev 서버 살려서 넘기기 1건+, §5·§5.1 —
  **표면 무관**, 비UI 빌드는 Phase 5 가 이 두 절만 읽는다).
- `references/context-adr.md` — grounding 을 위한 ADR/concept/guide 읽기 (Phase 1),
  영속적 결정을 위한 ADR & concept 문서 작성/관리 (Phase 5).

작업유형 스킬이 여기로 안내한다. `pipeline.md` 를 먼저 읽고, 나머지는
각 phase 가 필요로 할 때 끌어와라.
