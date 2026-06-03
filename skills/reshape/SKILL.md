---
name: reshape
description: 관찰 가능한 동작 변화 ZERO 로 코드를 리팩터링하며, 동작은 먼저 테스트로 고정한다 — invariant 를 확정하는 소크라테스식 인터뷰 → codex 의 적대적 플랜 리뷰 → opus 기반 dynamic-workflow 리팩터 → 보안 검증. 사용자가 기존 코드가 하는 일을 바꾸지 않으면서 REFACTOR, 재구조화, 정리, 단순화, 추출, 분할, 이름변경, 중복제거, 디커플, 또는 가독성/구조 개선을 하려 할 때마다 사용한다 — "clean up this module", "extract this into a helper", "this file is a mess, restructure it", "DRY up these three copies", "rename X everywhere", "untangle this" 같은 표현. 동작이 바뀌어야 하거나(use renew), 새로운 것을 만들거나(use forge), 무언가 깨져서 고쳐야 하는(use hunt) 경우에는 사용하지 말 것.
---

# Reshape — 동작 변화 없이 리팩터링

핵심 제약: **관찰 가능한 동작은 바뀌면 안 된다**. 그것을 증명하는 유일한 방법은
구조를 손대기 *전에* 현재 동작을 테스트로 고정하고, 모든 단계에서 그 테스트를 green
으로 유지하는 것이다. 파이프라인은 그 순서를 강제하고, 당신의 "동등한" 재작성이
정말로 동등한지 codex 가 점검하게 한다.

`~/.claude/skills/craft-core/references/pipeline.md` 의 공유 엔진을 실행하라
(먼저 읽을 것). 그 안에서 다음 reshape 고유 강조점을 적용한다:

## Phase 1 — Socratic focus (see craft-core/references/socratic.md)

- **The smell** — 현재 구조에서 구체적으로 무엇이 잘못됐는가 (중복, 긴 함수,
  엉킨 의존성, 불명확한 이름)? 파일명으로 가정하지 말고 코드를 읽어 그것이 실제임을
  검증하라.
- **The invariant** — 어떤 관찰 가능한 동작이 바뀌면 안 되는가? Public API,
  반환값, 부수 효과, 순서, 에러 케이스. 이것이 리팩터가 깨뜨려서는 안 되는 계약이다.
- **Blast radius** — 무엇이 이것을 호출하는가? 변경이 얼마나 멀리 미치는가? (수동
  추적 전에 가능하면 프로젝트의 impact 툴링 / graph 를 사용하라.)
- **Rule of three** — 공유 추상화를 추출한다면: 단지 비슷한 형태가 아니라 *같은
  도메인 의미*를 공유하는 호출 지점이 진짜로 3+ 개 있는가? 두 개의 복사본은 그대로
  둔다.
- **Ground it** — 코드를 읽고 (graph/LSP 먼저) 현재 구조를 고정하는 ADR
  (`context-adr.md`) 이 있으면 읽어라; 리팩터는 그것과 모순되어선 안 된다.
- **ADR-worthy?** 보통 **아니오** (동작 불변). 예외: 리팩터가 향후 코드가 따라야 할
  구조적 패턴을 채택하는 경우 → Phase 5 에서 ADR 기록.

## Phase 3 — TDD entry point (see craft-core/references/dynamic-tdd.md)

Task 1 은 **현재 관찰 가능한 동작을 고정하는 characterization test** 다 — 그것들은
코드를 있는 그대로에 대해 통과해야 한다. 그다음에야 작은 단계로 리팩터하며, 각
단계는 모든 테스트를 green 으로 유지하는 task 다. **어떤 task 도 동작을 추가하거나
바꿔선 안 된다** — 통과를 위해 테스트를 바꿔야 한다면 리팩터가 invariant 를 깬
것이다; 멈추고 재평가하라. 리팩터 단계는 오직 "구조가 아직 적용되지 않음"의
의미에서만 red 이며, 결코 "동작이 아직 존재하지 않음"이 아니다.

Phase 0, 2, 4, 5 는 공유 파이프라인 그대로 실행된다. Phase 0 격리에 유의:
3+ 파일 리팩터는 worktree 에서 진행한다.
