# Phase 3.5 — Simplify review pass (forge / renew / hunt)

`forge` / `renew` 구현이나 `hunt` 수정이 green 이 된 후 (Phase 3 완료) 그러나
secure-verify 게이트 (Phase 4) **전에**, 방금 작성한 diff 가 정리(simplify)가
필요한지 검토하고, 필요하면 `/simplify` 스킬로 behavior-preserving 정리를 돌린다.

이 pass 는 무거운 자체 characterization 규율을 직접 운영하는 대신, Claude Code
의 `/simplify` 슬래시 스킬에 위임한다 —
그것은 *변경된 코드만* 대상으로 재사용(reuse) / 단순화(simplification) /
효율(efficiency) / altitude 정리를 찾아 적용하며, 버그는 건드리지 않는다. craft 는
그 위에 게이트(opt-in)와 안전망(테스트 green 유지)만 얹는다.

**대상: forge / renew / hunt 모두.** simplify 는 방금 바뀐 diff 만 보고 동작을
바꾸지 않으므로, 버그 수정(`hunt`)에도 안전하게 적용된다 — surgical 한 fix 의
범위를 넘지 않는다. 다만 trivial 한 수정(1 파일, 몇 줄, 이미 깔끔)은 묻지 말고
스킵한다.

## Gate — 먼저 물어라, 기본 off

이 phase 는 절대 조용히 돌지 않는다. Phase 3 이 green 인 후, `AskUserQuestion` 으로
한 번 제안한다, 대략:

> "구현/수정 끝났고 테스트 green. 변경된 코드에 정리 패스(simplify) 돌릴까요?
> — 재사용/단순화/효율/altitude 정리만, behavior 불변, 테스트 계속 green 유지."

사용자가 거부하거나, 침묵하거나, 정리할 게 없으면, **Phase 4 로 스킵**하고
한 줄로 말한다. 다시 제안하지 말 것.

## Step 1 — 검토: simplify 가 필요한가

먼저 방금 작성한 diff 를 살펴 정리 여지가 실제로 있는지 판단한다 — 중복 로직,
불필요한 중간 변수, 과한 추상화, 인라인 가능한 헬퍼, 죽은 분기, 더 단순한 표현.
없으면 묻지 말고 스킵. 있으면 게이트를 띄운다.

## Step 2 — 동작 핀 (정리 전에)

Phase 3 테스트 스위트가 behavior 핀 **이다** — 진입 시 green 이어야 한다.
정리 대상 경로가 기존 테스트로 커버되지 않으면, 그 경로에 대해
현재 관측 behavior 를 assert 하는 테스트를 먼저 추가하고 코드 그대로에 대해
통과하는지 확인한다.

## Step 3 — `/simplify` 실행 (또는 폴백)

게이트를 통과하면 `/simplify` 스킬을 호출해 변경된 diff 를 정리하게 한다. simplify
는 변경된 코드의 재사용/단순화/효율/altitude 만 손대고 버그 사냥은 하지 않는다
(버그가 의심되면 그건 `hunt` 의 일이다).

`/simplify` 가 설치돼 있지 않으면, 같은 정리를 직접 수행하되 동일한 제약을 지킨다 —
프로젝트 컨벤션은 `convention-guide.md` + 프로젝트 lint/rule + `docs/guides/` 를
참조한다 (가장 구체적인 것이 이김). 프로젝트의 formatter/linter 를 먼저 돌려
mechanical 한 것은 그것에 맡기고, taste-level 축(네이밍, 함수/파일 구조,
import 조직, 에러 처리, 중복 제거)만 손으로 정리한다.

## Step 4 — 동작 불변 확인 → Phase 4 로 넘김

정리 후 **전체 테스트 스위트를 다시 돌린다.** 룰은 절대적이다:

- 테스트가 red → 정리가 behavior 를 바꿈 → **되돌리고 멈춰라.** 정리는 절대
  관측 behavior 를 바꿀 수 없다. behavior 변화 없이는 진짜로 적용될 수 없는
  변경이라면 그건 `renew` 결정이지 정리가 아니다 — 두고, 메모하고, 넘어가라.
- 테스트가 green 유지 → 유지하고 계속.

Scope 는 Phase 3 diff 와 그 직접 이웃뿐이다. 레포 다른 곳의 건드리지 않은
코드를 정리하지 **말 것** — 그건 scope creep 이다 (메모만, 하지 말 것).

diff 가 깔끔하고 전체 스위트가 green 일 때, Phase 4 secure-verify 로 진행한다.
보안 pass 와 verify 게이트는 결합된 (구현 + 정리) diff 에 대해 돈다 — 이 phase
를 위한 별도 게이트는 없다.

## Anti-patterns

- 사용자 go-ahead 없이 pass 를 돌리기 (opt-in, 한 번 묻는다).
- 정리가 테스트를 red 로 만들었는데 "통과시키려고" 테스트를 바꾸기 — 그게
  behavior drift, 이 pass 가 금하는 단 하나의 것.
- Phase 3 변경이 건드린 적 없는 파일을 정리하기.
- 프로젝트 formatter 가 이미 소유한 mechanical 스타일을 재결정하기.
- 정리 중 버그를 "고치기" — 그건 별도 `hunt` 다 (메모만).
