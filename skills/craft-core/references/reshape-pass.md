# Phase 3.5 — Convention reshape pass (forge / renew only)

`forge` 나 `renew` 구현이 green 이 된 후 (Phase 3 완료) 그러나 secure-verify
게이트 (Phase 4) **전에**, 방금 작성한 코드를 프로젝트의
컨벤션에 선택적으로 맞춘다 — 집중된, behavior-preserving 정리 pass.

**`forge` 와 `renew` 에만 적용.** `hunt` 는 의도적으로 이 phase 를 스킵한다:
버그 수정은 surgical 하게 유지돼야 하고, 컨벤션 churn 을 수정 diff 에 접어 넣으면
실제 변경을 묻고 regression surface 를 넓힌다. `reshape` 도 스킵한다 —
스킬 자체가 이미 컨벤션/구조 pass 이므로, 두 번째는 redundant 하다.

이 pass 는 `reshape` 의 정의적 제약 — **관측적 behavior 변화 zero** — 을
재사용하므로, 같은 증명 규율을 따라야 한다. 구조 전용이다.

## Gate — 먼저 물어라, 기본 off

이 phase 는 절대 조용히 돌지 않는다. Phase 3 이 green 인 후, `AskUserQuestion` 으로
한 번 제안한다, 대략:

> "구현 끝났고 테스트 green. 이어서 코드 컨벤션 정렬 리팩터(behavior 불변)
> 돌릴까요? — 네이밍/구조/import/에러처리 축만, 테스트 계속 green 유지."

사용자가 거부하거나, 침묵하거나, 맞출 게 없으면, **Phase 4 로 스킵**하고
한 줄로 말한다. 다시 제안하지 말 것. 코드가 이미 컨벤션에 맞는 trivial 변경 (1 파일,
몇 줄) 은 묻지도 않고 스킵해야 한다.

## Step 1 — 컨벤션 로드 (머지)

`convention-guide.md` 를 읽고 프로젝트 자신의 소스와 머지한다, **가장
구체적인 것이 이긴다** (그 파일의 precedence 블록이 권위):

1. project lint/formatter config + `rules/*.md`
2. project `docs/guides/` 컨벤션 페이지 (있으면)
3. `convention-guide.md` 의 baseline

프로젝트의 formatter/linter 를 먼저 돌리고 모든 mechanical 한 것을 그것에 맡긴다 —
이 pass 는 linter 가 강제할 수 없는 taste-level 축만 건드린다 (네이밍,
함수/파일 구조, import/dependency 조직, 에러 처리).

## Step 2 — behavior 핀 (구조를 건드리기 전에)

Phase 3 테스트 스위트가 behavior 핀 **이다** — 진입 시 green 이어야 한다.
의도한 컨벤션 변경이 기존 테스트가 커버하지 않는 코드를 건드리는 곳에,
정확히 그 경로에 대해 **characterization 테스트** (현재 관측 behavior 를 assert) 를
먼저 추가하고, 코드 그대로에 대해 통과하는지 확인한다. 어떤 구조적 편집도
그것이 건드리는 경로가 핀될 때까지 일어나지 않는다.

## Step 3 — 작은 단계로 정렬, green 유지

컨벤션을 작고 독립적인 단계로 적용한다 (한 번에 rename 세트 하나, guard-clause
flatten 하나, import regroup 하나). **모든** 단계 후, 스위트를 돌린다. 룰은
절대적이다:

- 테스트가 red → 단계가 behavior 를 바꿈 → **그 단계를 되돌리고 멈춰라.**
  컨벤션 정렬은 절대 관측 behavior 를 바꿀 수 없다. 컨벤션이
  behavior 변화 없이는 진짜로 적용될 수 없다면, 그건 `renew`
  결정이지 reshape 가 아니다 — 두고, 메모하고, 넘어가라.
- 테스트가 green 유지 → 단계를 유지하고, 계속한다.

Scope 는 Phase 3 diff 와 그 직접 이웃뿐이다. 레포 다른 곳의
건드리지 않은 코드를 reshape 하지 **말 것** — 그건 scope creep 이고 별도
`reshape` 태스크다 (메모만, 하지 말 것).

## Step 4 — Phase 4 로 넘김

diff 가 컨벤션에 맞고 전체 스위트가 green 일 때, Phase 4
secure-verify 로 평소대로 진행한다. 보안 pass 와 verify 게이트는 결합된
(구현 + reshape) diff 에 대해 돈다 — 이 phase 를 위한 별도 게이트는 없다.

## Anti-patterns

- 사용자 go-ahead 없이 pass 를 돌리기 (opt-in, 한 번 묻는다).
- "통과시키려고" 테스트를 바꾸게 두기 — 그게 behavior drift, 이 pass 가
  금하는 단 하나의 것.
- Phase 3 변경이 건드린 적 없는 파일을 reshape 하기.
- 프로젝트 formatter 가 이미 소유한 mechanical 스타일을 재결정하기.
- `hunt` 수정이나 `reshape` 태스크에 적용하기.
