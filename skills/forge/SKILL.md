---
name: forge
description: 엄격한 파이프라인을 통해 NEW 기능을 end-to-end 로 구축한다 — 소크라테스식 요구사항 인터뷰 → codex 의 적대적 플랜 리뷰 → opus 기반 dynamic-workflow TDD 구현 → 보안 검증. 사용자가 아직 존재하지 않는 기능, 엔드포인트, 컴포넌트, 페이지, 명령, 능력을 ADD, BUILD, IMPLEMENT, 또는 CREATE 하려 할 때마다 사용한다 — "add X", "build me Y", "I need a Z", "can you make it do W" 처럼 캐주얼하게 표현하더라도, 프로세스나 테스트를 전혀 언급하지 않더라도 마찬가지다. 사소하지 않은 신규 기능이라면 즉흥적 코딩보다 forge 를 우선하라. 깨진 동작을 고치거나(use hunt), 기존 기능을 변경하는(use renew) 경우에는 사용하지 말 것.
---

# Forge — 새 기능 구축

당신은 아직 존재하지 않는 무언가를 만들고 있다. 위험은 잘못된 것을 만들거나,
올바른 것을 만들었지만 동작한다는 증거가 없는 것이다. 파이프라인은 둘 다 제거한다:
spec 은 소크라테스식 인터뷰로 고정하고, codex 가 공격하며, 그다음 opus 에서
outside-in test-first 로 구현하고, 이어 검증과 보안 점검을 거친다.

`~/.claude/skills/craft-core/references/pipeline.md` 의 공유 엔진을 실행하라
(먼저 읽을 것). 그 안에서 다음 forge 고유 강조점을 적용한다:

## 실행 모드 기본값 (toggle)

**기본 모드: orchestrated.** craft-core 의 linear-기본을 override 한다 — 새 기능은
설계 리스크가 커 적대적 council 검토가 기본값으로 적절하다. `pipeline.md` 의
"Execution mode" 진입 시 linear-기본·stakes 제안을 건너뛰고 곧장 orchestrated
(`orchestrated.md`) 로 간다.

- **이번 호출만 linear**: 호출 어디든 `--linear` 가 있으면 그 호출만 linear 로 돈다.
- **영구 토글**: 위 "기본 모드" 를 `linear` 로 바꾸면 craft-core 기본(linear)으로 복귀.

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
통과할 때까지 opus 에서 red → green → refactor 로 몰아가는 unit slice 다.
acceptance scenario 가 요구하지 않는 인프라는 만들지 말 것.

## Phase 3.5 — Simplify review pass (see craft-core/references/simplify-pass.md)

acceptance test 가 통과하면, Phase 4 이전에 새로 작성한 diff 가 정리(simplify)가
필요한지 검토하고, 필요하면 `/simplify` 스킬로 동작 보존 정리(재사용/단순화/효율)를
**한 번 제안한다** (기본 off). 새 기능은 신선하고 정렬되지 않은 코드가 자리 잡는
곳이므로, 이 패스가 값어치를 하는 지점이다. diff 가 사소하거나 사용자가 거절하면
건너뛴다.

Phase 0, 2, 4, 5 는 공유 파이프라인 그대로 실행된다.
