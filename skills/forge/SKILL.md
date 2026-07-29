---
name: forge
description: >-
  엄격한 파이프라인을 통해 NEW 기능을 end-to-end 로 구축한다 — 소크라테스식 요구사항 인터뷰 → plan review 게이트(상류 deep-plan 리뷰면 스킵, 고위험만 codex 1-pass) → dynamic-workflow TDD 구현 → codex diff 리뷰 포함 보안 검증. 사용자가 아직 존재하지 않는 기능, 엔드포인트, 컴포넌트, 페이지, 명령, 능력을 ADD, BUILD, IMPLEMENT, 또는 CREATE 하려 할 때마다 사용한다 — "add X", "build me Y", "I need a Z", "can you make it do W", "이 기능 추가해줘", "X 만들어줘", "붙여줘", "구현해줘", "이런 거 되게 해줘" 처럼 캐주얼하게 표현하더라도, 프로세스나 테스트를 전혀 언급하지 않더라도 마찬가지다. 사소하지 않은 신규 기능이라면 즉흥적 코딩보다 forge 를 우선하라. 깨진 동작을 고치거나(use hunt), 기존 기능을 변경하거나(use renew), Linear 이슈를 그대로 자율 실행하는(use linear-goal) 경우에는 사용하지 말 것.
---

# Forge — 새 기능 구축

당신은 아직 존재하지 않는 무언가를 만들고 있다. 위험은 잘못된 것을 만들거나,
올바른 것을 만들었지만 동작한다는 증거가 없는 것이다. 파이프라인은 둘 다 제거한다:
spec 은 소크라테스식 인터뷰로 고정하고, 그다음 outside-in test-first 로 구현하고,
이어 codex cross-model diff 리뷰와 보안 점검으로 검증한다(고위험 플랜은 구현 전
1-pass 적대 리뷰도 — Phase 2 게이트).

`~/.claude/skills/craft-core/references/pipeline.md` 의 공유 엔진을 실행하라
(먼저 읽을 것). 그 안에서 다음 forge 고유 강조점을 적용한다:

## 실행 모드 (risk-gated)

**기본 linear** (craft-core 기본 그대로). forge 고유 에스컬레이션 문턱 — 다음 중
하나면 Phase 1 전에 orchestrated 를 **1회 제안**한다(`pipeline.md` Execution mode
의 제안 메커니즘): **신규 아키텍처 패턴/의존성 도입 · 6+ 파일 · auth/payment
surface**. 보안 surface 는 제안을 강권 톤으로. `[council]`/`--council` 명시 요청은
언제나 즉시 orchestrated.

## Phase 1 — Socratic focus (see craft-core/references/socratic.md)

새 기능의 spec 은 사용자의 머릿속에 있다 — 그것을 끄집어내라. 다음을 앞세운다:

- **User value / job-to-be-done** — 이것이 누군가에게 무엇을 할 수 있게 해주며, 왜
  그것이 중요한가? (질문 자체를 의심하라 — 때로 진짜 필요는 더 단순하다.)
- **Exact IO contract** — 구체적인 입력과 기대되는 정확한 출력/상태를 예시와 함께.
  이것이 당신의 acceptance test 가 된다.
- **Success metric & acceptance scenarios** — "완료"를 느낌이 아니라 체크로 진술.
- **Non-goals** — 이 기능이 명시적으로 하지 않을 것 (스코프 크리프를 제한).
- 먼저 읽어서 어디에 끼워지는지 확인하라 (가능하면 code-graph/LSP, 아니면
  Read/Grep) — 기존 라우트, 스토어, 타입 — 그래야 새 코드가 가정된 계약이 아니라
  실제 계약에 들어맞는다. 관련 ADR/concepts (`context-adr.md`) 도 훑어볼 것.
- **ADR-worthy?** 새로운 아키텍처 패턴, 의존성, 또는 외부 계약 →
  Phase 5 에서 ADR 기록. 기존 레일 위의 평범한 기능 → ADR 없음.

## Phase 3 — TDD entry point (see craft-core/references/dynamic-tdd.md)

**outside-in** 으로 구축하라: task 1 은 IO contract 에서 곧바로 도출한 acceptance
test 다 (실패한다 — 기능이 부재하므로). 그다음 각 후속 task 는 acceptance test 가
통과할 때까지 red → green → refactor 로 몰아가는 unit slice 다.
acceptance scenario 가 요구하지 않는 인프라는 만들지 말 것.

Phase 0, 2, 4, 5 는 공유 파이프라인 그대로 실행된다. (Phase 3.5 simplify pass 는
은퇴 — diff 정리는 Phase 5 §N 권장 라우팅의 `/simplify` 로, `pipeline.md` 참조.)

## Anti-patterns (forge 고유 — 공유분은 pipeline.md)

- **문턱 미달 작업에 council 에스컬레이션** — 명확·작은 신규에 orchestrated 를
  제안하는 것 자체가 과투자다. 문턱(신규 아키텍처·6+ 파일·보안 surface)에 걸릴 때만.
- **IO 계약 없이 Phase 3 진입** — acceptance test(task 1)는 Phase 1 의 정확한 IO 계약에서
  도출된다. 계약이 흐린 채 outside-in 을 시작하면 허공을 친다 — 먼저 계약을 못 박아라.
