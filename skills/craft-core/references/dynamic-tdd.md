# Dynamic Workflow — Task Split + TDD on Opus

Phase 3 은 승인되고 Phase 2 게이트를 통과한 플랜을 동작하는 코드로 바꾼다.
`Workflow` 도구로 (a) 플랜을 atomic 태스크로 쪼개고 (b) 각 태스크를
엄격한 TDD 사이클로 구동한다. 구현은 **무핀 — 세션 모델을 상속**한다: 세션이
최상위 티어(fable 등)면 상속이 곧 최고 품질이고, 세션이 opus 미만일 때만
`model: 'opus'` 로 상향 핀한다(계약은 "구현 다운그레이드 금지"이지 특정
모델명이 아니다). 태스크별 red/green 규율과 독립 verify 단계가 워크플로를
정직하게 유지한다.

여기서 `Workflow` 호출이 허가되는 것은 이 스킬의 지침이 그렇게 하라고
말하기 때문이다 — 그것이 skill-invoked opt-in 경로다.

## "atomic task" 가 의미하는 것

태스크 하나 = 자체적으로 green 이 될 수 있는 플랜의 한 조각: 단일
behavior, 엔드포인트, 함수, 또는 수정. 태스크가 "X 이유로 실패하는 테스트를
쓰고, 그다음 통과시켜라" 로 표현될 수 없으면, 너무 크다 — 쪼개라.

**시간 가드레일 (실측) — 상한·하한 양쪽**: implement 에이전트 1회 벽시계
~10분(600s) 초과 = 그 태스크는 atomic 이 아니었다는 사후 신호다 (실측:
647s/561s/530s 태스크들이 한 워크플로 벽시계의 75% 를 차지). 태스크를 자를 때
"이게 opus 런 10분 안에 red→green→refactor 가 되나?" 를 기준으로 삼아라. 넘칠
것 같으면 설계 단계에서 더 잘게 — 사후에 발견하면 다음 유사 태스크 분할에 반영.

**하한도 있다 (2026-07-29 — 공유 트리 직렬 구조상 태스크 수가 곧 벽시계).**
Phase 3 벽시계 ≈ 태스크 수 × 태스크당 ~4.4분(median, 에이전트 스핀업+플랜
재독 고정비 포함)이다. 한 파일 한 함수급 미니 태스크는 **같은 표면의 인접
태스크와 병합**하라 — "단일 red 테스트로 표현되나"가 상한이라면, "이 둘을
가르는 게 스핀업 고정비 값을 하나 더 낼 만큼 독립적인가"가 하한이다. 판정
신호: 두 태스크가 같은 파일·같은 계약을 만지고 red 테스트를 한 파일에 나란히
쓸 수 있으면 병합 후보. atomic 규율(위)을 깨지 않는 선에서 개수를 줄이는 것이
공유 트리 직렬(실측 parallelism 1.00x)에서 벽시계를 줄이는 1차 레버다.

플랜 Acceptance 항목의 태그가 무엇을 자동화할지 정한다: **`[AUTO]` 항목은 반드시
자동 테스트**(아래 red → green → refactor)로 커버한다 — 회귀민감·보안·계약 수준이라
매 변경 재확인이 필요하기 때문. **`[HUMAN]` 항목은 Phase 3 테스트 의무에서 제외**
(시각 판단·UX 의도 등 자동화 가치가 낮음)하되, Phase 4 에서 사용자와 하나씩 walk 해
닫는다 (pipeline.md Phase 4 의 하이브리드 eval 장부 — SSOT). 새 메커니즘이 아니라
*어느 Acceptance 항목을 자동화하느냐의 분류*다.

## 각 태스크가 따라야 할 TDD 사이클

각 태스크는 red → green → refactor 사이클을 따른다 — 실패하는 테스트 먼저(*올바른
이유로* 실패, typo/import 에러 아님), 통과시키는 최소 구현(투기적 extra 없음, YAGNI),
green 인 채로 정리(새 behavior 없음). red-green-refactor 와 vertical-slice tracer-bullet
규율의 정식 정의는 `tdd` 스킬이 SSOT 다 (`~/.claude/skills/tdd/SKILL.md` — 여기 복제하지
않는다). 아래는 파이프라인 맥락의 추가 계약이다:

태스크는 자신의 테스트가 green 이고 형제를 깨지 않았을 때만 완료된다.

UI 태스크에서는 TDD 가 **behavior** 만 잠근다 — 미감은 테스트로 단언하지 않는다.
*visual/미감* 레이어는 승인된 mockup(있으면)에 충실히, DESIGN.md 면 `imprint` 로,
net-new 면 `frontend-design` 으로 빌드한다. 라우팅 규칙은 `pipeline.md` Phase 3 의
"UI / 프론트엔드 작업의 visual 레이어" 참조(SSOT — 여기 복제하지 않는다).

## Workflow 스크립트 골격 (적응 — 맹목적으로 복사하지 말 것)

```javascript
export const meta = {
  name: 'tdd-implement',
  description: 'Split approved plan into tasks and implement each test-first on opus',
  phases: [{ title: 'Implement' }, { title: 'Verify' }],
}

// TASKS comes from the approved plan's Steps — one entry per atomic slice.
const TASKS = args.tasks   // pass the task list in via Workflow `args`

const RESULT = { type: 'object', required: ['task','testsGreen','summary'], properties: {
  task: { type: 'string' }, testsGreen: { type: 'boolean' },
  filesChanged: { type: 'array', items: { type: 'string' } },
  summary: { type: 'string' },
} }

const results = await pipeline(
  TASKS,
  // Stage 1: TDD implement — no model pin (inherits the session model;
  // pin model:'opus' ONLY if the session model is below opus)
  (t) => agent(
    `TDD task: ${t.title}\n\nSpec: ${t.spec}\nFiles in scope: ${t.files}\n\n` +
    `1) Write the failing test first; confirm it fails for the right reason.\n` +
    `2) Minimal implementation to green — no speculative extras (YAGNI).\n` +
    `3) Refactor with tests green.\n` +
    `Run only this task's tests. Report testsGreen + files changed. ` +
    `If a target already matches the spec, report testsGreen:true and skip.`,
    { label: `tdd:${t.id}`, phase: 'Implement', schema: RESULT }
  ),
  // Stage 2: independent verify — pin the CHEAPEST tier. A deterministic test
  // re-run needs no reasoning tier; leaving it unpinned inherits the session's
  // top model and burns it on mechanical work.
  (impl, t) => agent(
    `Verify task "${t.title}" is genuinely green: run its tests and confirm. ` +
    `Report testsGreen honestly — do not trust the implementer's claim.`,
    { label: `verify:${t.id}`, phase: 'Verify', model: 'haiku', effort: 'low', schema: RESULT }
  ).then(v => ({ ...impl, verified: v.testsGreen }))
)

return results.filter(Boolean)
```

골격에 대한 주석:

- **구현** 에이전트는 **무핀(세션 모델 상속)** — 세션이 최상위 티어면 핀이
  오히려 다운그레이드다. 세션 모델이 opus 미만일 때만 `model: 'opus'` 상향 핀.
  **verify** 에이전트는 반대로 **`model: 'haiku'` + `effort: 'low'` 최저가 핀** —
  그 일은 테스트 재실행(결정론적 기계 체크)이라 추론 티어가 필요 없고, 무핀으로
  두면 세션 최상위 모델이 상속돼 결정론 작업에 최고가를 태운다(실측 동형: 과거
  verify 6개가 opus 로 돌아 814s, 그 런 총 벽시계의 24% 소모). verify 의 정직성은
  모델 tier 가 아니라 *독립 컨텍스트*(구현자의 주장을 신뢰하지 않고 직접 실행)에서
  온다.
- 구현 / verify 는 기본 워크플로 subagent 에서 돈다 — 위 프롬프트가 곧 계약이다.
- 기본은 per-agent 워크트리 격리 **없음** — 에이전트는 메인 세션의 작업 트리
  (Phase 0 이 이미 worktree 로 분기했을 수 있음) 를 상속한다. 그래야 Stage 2
  verify 가 Stage 1 의 변경을 *같은 트리* 에서 본다. 이 기본에서 태스크들은
  사실상 **직렬**로 돈다 (실측: parallelism 1.00x — 벽시계 ≈ Σ 에이전트 시간).
  Phase 3 벽시계 = 태스크 수 × 태스크당 opus 시간이므로, 벽시계를 줄이는 1차
  레버는 병렬화가 아니라 위의 태스크 크기 가드레일 + verify 무핀이다.
- `isolation: 'worktree'` 는 태스크들이 병렬로 같은 파일을 쓰고 충돌할 때만
  켠다 (디스크 + 셋업 비용). 켜려면 둘 다 필요하다: (a) verify 도 같은 태스크
  워크트리에서 돌고, (b) 종료 후 변경을 메인 트리로 merge-back 한다. 그 수집
  단계 없이 켜면 — verify 가 빈 트리를 봐서 false red 를 내거나, 변경이 orphan
  워크트리에 갇혀 메인 트리에 안 돌아온다.
- 태스크 리스트를 스크립트에 하드코드하지 말고 Workflow `args` 로 넘겨라,
  같은 스크립트가 어떤 플랜에도 쓰이게.
- 각 에이전트의 command 를 붙여넣은 코드가 아니라 *경로와 플랜* 으로 가리켜라 —
  에이전트는 Read 가 있다.

> **cross-model build lane 은퇴 (2026-07-30).** 종전 여기엔 `--codex-build` opt-in
> 레인이 있었다 — Stage 1 을 red(Claude)→green(codex)→verify(haiku)로 분해해 codex 를
> cross-model *구현자* 로 참여시키는 경로(SSOT `codex-build.md`). 사용자 요청으로 codex
> 플러그인을 제거하면서 호출 경로가 소멸해 레인과 그 SSOT 를 함께 삭제했다. 기본
> Stage 1(Claude subagent 가 red+green+refactor 통째로)이 이제 유일한 경로다 — 종전에도
> 이게 floor 였고 codex 는 증강이었으므로 **기본 동작은 무변경**이다. 복원은
> `claude plugin install codex@openai-codex` 후 git history revert.

## 워크플로가 반환된 후

- `testsGreen:false` 또는 `verified:false` 인 태스크 → 고친다 (그 태스크를
  재실행하거나 inline 처리). red 태스크를 안고 Phase 4 로 진행하지 말 것.
- **형제 회귀 최종 게이트**: 메인 세션에서 전체 수트 + typecheck 를 **1회**
  돌린다 (예: `pnpm typecheck && pnpm test`). 태스크별 verify 는 *그 태스크의*
  테스트만 scoped 실행하므로 형제 태스크를 깬 회귀를 못 본다 — "형제를 깨지
  않았을 때만 완료" 계약은 이 최종 1회가 잠근다. 태스크 내부에서 전체 수트를
  반복 실행하는 것(비쌈)의 대체이지 추가 비용이 아니다.
- 작업유형 스킬이 사이클이 *어디서 시작하는지* 정의한다 — 예: `hunt` 는
  실패하는 regression 테스트를 태스크 1 로 쓴다; `renew` 는 보존돼야 할 behavior 를
  핀하는 테스트를 먼저 쓴 뒤 변경에 들어간다.

## Anti-patterns

- 테스트 전에 구현 쓰기 (red 단계 없음) → 테스트가 무언가를 테스트한다는 걸
  증명할 수 없다.
- **구현 다운그레이드 / verify 업그레이드** — 구현 에이전트를 세션보다 낮은
  tier 로 핀하기(품질 하향), 또는 verify 를 haiku 위 tier 로 돌리기(결정론
  재실행에 추론 모델 낭비). 방향이 반대인 두 실수: 구현은 "세션 상속, opus
  미만이면 상향", verify 는 "항상 최저가 핀".
- 플랜 전체를 위한 하나의 거대 에이전트 호출 → 태스크별 red/green
  규율을 잃고 truncate 된다.
- 독립 verify 단계 없이 구현자의 "green" 을 신뢰하기.
- 태스크 에이전트가 전체 수트를 반복 실행 → scoped 테스트만 돌리고, 전체 수트는
  워크플로 반환 후 메인에서 1회 (위 최종 게이트).
- 600s 넘는 implement 태스크를 "원래 큰 작업이라 그렇다" 로 넘기기 → atomic
  분할 실패의 신호다. 다음 태스크 리스트에 반영하라.
