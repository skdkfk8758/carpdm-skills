# Dynamic Workflow — Task Split + TDD on Opus

Phase 3 은 승인되고 codex 리뷰를 거친 플랜을 동작하는 코드로 바꾼다.
`Workflow` 도구로 (a) 플랜을 atomic 태스크로 쪼개고 (b) 각 태스크를
엄격한 TDD 사이클로 구동한다. 구현은 **opus** (4.8) 에서 돈다 — test-pinned
태스크에 대한 최고 구현 품질; 더 싼 tier 가 아니라, 태스크별 red/green
규율과 독립 verify 단계가 워크플로를 정직하게 유지한다.

여기서 `Workflow` 호출이 허가되는 것은 이 스킬의 지침이 그렇게 하라고
말하기 때문이다 — 그것이 skill-invoked opt-in 경로다.

## "atomic task" 가 의미하는 것

태스크 하나 = 자체적으로 green 이 될 수 있는 플랜의 한 조각: 단일
behavior, 엔드포인트, 함수, 또는 수정. 태스크가 "X 이유로 실패하는 테스트를
쓰고, 그다음 통과시켜라" 로 표현될 수 없으면, 너무 크다 — 쪼개라.

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
  // Stage 1: TDD implement on opus
  (t) => agent(
    `TDD task: ${t.title}\n\nSpec: ${t.spec}\nFiles in scope: ${t.files}\n\n` +
    `1) Write the failing test first; confirm it fails for the right reason.\n` +
    `2) Minimal implementation to green — no speculative extras (YAGNI).\n` +
    `3) Refactor with tests green.\n` +
    `Run only this task's tests. Report testsGreen + files changed. ` +
    `If a target already matches the spec, report testsGreen:true and skip.`,
    { label: `tdd:${t.id}`, phase: 'Implement', model: 'opus', schema: RESULT }
  ),
  // Stage 2: independent verify that the task's tests actually pass.
  // No model pin — verify is a deterministic test re-run, not reasoning work;
  // it inherits the session model (cheaper/faster than pinning opus).
  (impl, t) => agent(
    `Verify task "${t.title}" is genuinely green: run its tests and confirm. ` +
    `Report testsGreen honestly — do not trust the implementer's claim.`,
    { label: `verify:${t.id}`, phase: 'Verify', effort: 'low', schema: RESULT }
  ).then(v => ({ ...impl, verified: v.testsGreen }))
)

return results.filter(Boolean)
```

골격에 대한 주석:

- **구현** 에이전트에 `model: 'opus'` — 이것이 스킬 계약상 Phase 3 의 필수
  모델이다. **verify** 에이전트는 핀하지 않는다 — 그 일은 테스트 재실행(결정론적
  기계 체크)이라 opus 추론이 필요 없고, 핀을 떨구면 태스크당 opus 런이 2→1 로
  줄어 Phase 3 벽시계가 절반 가까이 준다. verify 의 정직성은 모델 tier 가 아니라
  *독립 컨텍스트*(구현자의 주장을 신뢰하지 않고 직접 실행)에서 온다.
- 구현 / verify 는 기본 워크플로 subagent 에서 돈다 — 위 프롬프트가 곧 계약이다.
- 기본은 per-agent 워크트리 격리 **없음** — 에이전트는 메인 세션의 작업 트리
  (Phase 0 이 이미 worktree 로 분기했을 수 있음) 를 상속한다. 그래야 Stage 2
  verify 가 Stage 1 의 변경을 *같은 트리* 에서 본다.
- `isolation: 'worktree'` 는 태스크들이 병렬로 같은 파일을 쓰고 충돌할 때만
  켠다 (디스크 + 셋업 비용). 켜려면 둘 다 필요하다: (a) verify 도 같은 태스크
  워크트리에서 돌고, (b) 종료 후 변경을 메인 트리로 merge-back 한다. 그 수집
  단계 없이 켜면 — verify 가 빈 트리를 봐서 false red 를 내거나, 변경이 orphan
  워크트리에 갇혀 메인 트리에 안 돌아온다.
- 태스크 리스트를 스크립트에 하드코드하지 말고 Workflow `args` 로 넘겨라,
  같은 스크립트가 어떤 플랜에도 쓰이게.
- 각 에이전트의 command 를 붙여넣은 코드가 아니라 *경로와 플랜* 으로 가리켜라 —
  에이전트는 Read 가 있다.

## 워크플로가 반환된 후

- `testsGreen:false` 또는 `verified:false` 인 태스크 → 고친다 (그 태스크를
  재실행하거나 inline 처리). red 태스크를 안고 Phase 4 로 진행하지 말 것.
- 작업유형 스킬이 사이클이 *어디서 시작하는지* 정의한다 — 예: `hunt` 는
  실패하는 regression 테스트를 태스크 1 로 쓴다; `renew` 는 보존돼야 할 behavior 를
  핀하는 테스트를 먼저 쓴 뒤 변경에 들어간다.

## Anti-patterns

- 테스트 전에 구현 쓰기 (red 단계 없음) → 테스트가 무언가를 테스트한다는 걸
  증명할 수 없다.
- **구현** 에이전트가 더 싼 tier 로 폴백하게 `model: 'opus'` override 를 떨구기 →
  스킬 계약 무시. (verify 는 반대 — opus 로 핀하는 것이 anti-pattern: 결정론적
  테스트 재실행에 최저속 tier 를 태워 벽시계만 태운다.)
- 플랜 전체를 위한 하나의 거대 에이전트 호출 → 태스크별 red/green
  규율을 잃고 truncate 된다.
- 독립 verify 단계 없이 구현자의 "green" 을 신뢰하기.
