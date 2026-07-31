---
name: renew
description: >-
  엄격한 파이프라인을 통해 EXISTING 기능을 새단장하거나 개편한다 — 무엇이 바뀌어야 하고 무엇이 보존되어야 하는지 분리하는 소크라테스식 인터뷰 → plan review 게이트(상류 deep-plan 리뷰면 스킵, 고위험만 적대 1-pass) → dynamic-workflow TDD → correctness diff 리뷰 포함 보안 검증. 사용자가 기존 기능, 플로우, 화면, 또는 API 를 CHANGE, REDESIGN, REVAMP, MODERNIZE, OVERHAUL, EXTEND, 또는 REWORK 하려 할 때마다 사용한다 — "redo the X", "rework how Y works", "modernize the Z flow", "change the behavior of W", "the old A should now also do B", "이 화면 개편해줘", "동작 바꿔줘", "리뉴얼해줘", "고도화해줘", "이 기능 손봐줘", "기존 X 를 Y 도 되게 확장해줘" 같은 표현. 특히 하위 호환성, 마이그레이션, 또는 기존 호출자를 깨지 않는 것이 중요할 때. 완전히 새로운 것을 만들거나(use forge), 버그를 고치는(use hunt) 데에는 사용하지 말 것.
---

# Renew — 기존 기능 개편

당신은 이미 동작하며 무언가가 이미 의존하고 있는 것을 바꾸고 있다. 위험은 남아
있어야 할 부분을 깨뜨리거나, 옛 동작에 의존하던 대상을 놓치는 것이다. 파이프라인은
보존/변경 경계선을 명시하고, 손대기 전에 보존할 동작을 테스트로 고정하며, 구현 후
correctness diff 리뷰가 당신이 잊은 호출자·경계를 사냥하게 한다(계약 변경·
마이그 동반 플랜은 구현 전 1-pass 적대 리뷰도 — Phase 2 게이트).

`~/.claude/skills/craft-core/references/pipeline.md` 의 공유 엔진을 실행하라
(먼저 읽을 것). 그 안에서 다음 renew 고유 강조점을 적용한다:

## 실행 모드 (risk-gated)

**기본 linear** (craft-core 기본 그대로). renew 고유 에스컬레이션 문턱 — 다음 중
하나면 Phase 1 전에 orchestrated 를 **1회 제안**한다(`pipeline.md` Execution mode
의 제안 메커니즘): **외부 호출자가 있는 계약 변경 · DB 마이그레이션 동반**.
`[council]`/`--council` 명시 요청은 언제나 즉시 orchestrated.

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
남아야 할 것을 조용히 깨뜨리지 못하게 하는 안전망이다. 그다음 *바뀐* 동작을
red → green → refactor 로 몰아가되, characterization test 는 내내 green 으로 유지한다.

Phase 0, 2, 4, 5 는 공유 파이프라인 그대로 실행된다. (Phase 3.5 simplify pass 는
은퇴 — diff 정리는 Phase 5 §N 권장 라우팅의 `/simplify` 로, `pipeline.md` 참조.)

## Anti-patterns (renew 고유 — 공유분은 pipeline.md)

- **preserve/change 경계 미확정 후 편집** — 무엇이 살아남고 무엇이 바뀌는지 안 그으면
  characterization test 로 잠글 대상이 흐려져, 보존돼야 할 동작을 조용히 깬다.
- **개편이 죽인 옛 경로를 같은 변경에서 안 지움** — "다음 PR" 로 미루면 데드코드가
  남는다(YAGNI 위반). 옛 경로 삭제는 같은 작업 단위에 넣는다.
