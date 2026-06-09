---
name: renew
description: 엄격한 파이프라인을 통해 EXISTING 기능을 새단장하거나 개편한다 — 무엇이 바뀌어야 하고 무엇이 보존되어야 하는지 분리하는 소크라테스식 인터뷰 → codex 의 적대적 플랜 리뷰 → opus 기반 dynamic-workflow TDD → 보안 검증. 사용자가 기존 기능, 플로우, 화면, 또는 API 를 CHANGE, REDESIGN, REVAMP, MODERNIZE, OVERHAUL, EXTEND, 또는 REWORK 하려 할 때마다 사용한다 — "redo the X", "rework how Y works", "modernize the Z flow", "change the behavior of W", "the old A should now also do B" 같은 표현. 특히 하위 호환성, 마이그레이션, 또는 기존 호출자를 깨지 않는 것이 중요할 때. 완전히 새로운 것을 만들거나(use forge), 버그를 고치는(use hunt) 데에는 사용하지 말 것.
---

# Renew — 기존 기능 개편

당신은 이미 동작하며 무언가가 이미 의존하고 있는 것을 바꾸고 있다. 위험은 남아
있어야 할 부분을 깨뜨리거나, 옛 동작에 의존하던 대상을 놓치는 것이다. 파이프라인은
보존/변경 경계선을 명시하고, 손대기 전에 보존할 동작을 테스트로 고정하며, codex 가
당신이 잊은 호출자를 사냥하게 한다.

`~/.claude/skills/craft-core/references/pipeline.md` 의 공유 엔진을 실행하라
(먼저 읽을 것). 그 안에서 다음 renew 고유 강조점을 적용한다:

## Phase 1 — Socratic focus (see craft-core/references/socratic.md)

이 renew 가 `improve-codebase-architecture` 가 발굴한 deepening/리팩터 기회에서
출발했다면(그 스킬이 CONTEXT.md·ADR 기반으로 결합 해소·테스트 용이성 개선 항목을
이미 짚었다면), 그 분석을 Phase 1 입력으로 가져와라 — "무엇을 왜 바꾸나" 는 이미
근거가 있으니 재발굴하지 말고, renew 고유의 **preserve vs change 경계 확정**과
**호출자/계약 보존**에 인터뷰를 집중한다. (해당 스킬을 안 거쳤으면 무시.)

여기서의 spec 은 현재 현실에 대한 *delta* 이므로, 현재 현실을 먼저 매핑하라:

- **Current behavior inventory** — 이 기능은 오늘 무엇을 하는가? 먼저 읽어서 확립하라
  (가능하면 code-graph/LSP, 아니면 Read/Grep) 그리고 관련 ADR/concepts
  (`context-adr.md`) 까지 — 기억이 아니라, 또 항구적 ADR 에 반하지 않게.
- **Preserve vs change** — 명시적 경계선을 그어라: 어떤 동작이 손대지 않고 살아남아야
  하는지, 어떤 것이 바뀌는지, 어떤 것이 제거되는지.
- **Dependents & contracts** — 누가 이것을 호출하는가? 그들이 의존하는 계약(API 형태,
  이벤트, 스토어 키)은 무엇인가? 변경이 그들을 깨뜨리는가?
- **Migration & compatibility** — 마이그레이션이 필요한가? deprecation 기간은?
  롤백은 무엇인가?
- **ADR-worthy?** 계약/동작 결정(auth-model 교체, API envelope 변경,
  마이그레이션 전략) → Phase 5 에서 ADR 기록.
- **Edge & failure inputs (type 5)** — 바뀐 동작이 견뎌야 할 최악의/이례적 입력,
  그리고 견디지 못하면 하류에서 무엇이 깨지는지. 동작 변경은 처리되지 않은 edge 가
  숨는 곳이다 — spec 을 마무리하기 전에 완전성 sweep 을 실행하라.
- **YAGNI** — 개편이 쓸모없게 만드는 옛 코드 경로는 같은 변경에서 삭제된다.

## Phase 3 — TDD entry point (see craft-core/references/dynamic-tdd.md)

먼저 **보존할 동작을 고정하는 characterization test** 를 작성하라 — Phase 1 의
"MUST survive" 목록. 그것들은 오늘의 코드에 대해 통과해야 한다; 그것들은 개편이
남아야 할 것을 조용히 깨뜨리지 못하게 하는 안전망이다. 그다음 *바뀐* 동작을 opus 에서
red → green → refactor 로 몰아가되, characterization test 는 내내 green 으로 유지한다.

## Phase 3.5 — Simplify review pass (see craft-core/references/simplify-pass.md)

바뀐 동작이 green 이 되면, Phase 4 이전에 손댄 diff 가 정리(simplify)가 필요한지
검토하고, 필요하면 `/simplify` 스킬로 동작 보존 정리(재사용/단순화/효율)를 **한 번
제안한다** (기본 off) — characterization test(보존된 동작)는 Phase 3 에서와 똑같이
내내 green 으로 유지한 채. diff 가 사소하거나 사용자가 거절하면 건너뛴다.

Phase 0, 2, 4, 5 는 공유 파이프라인 그대로 실행된다.
