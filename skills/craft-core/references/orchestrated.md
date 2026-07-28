# Orchestrated Execution — team-mode council + dynamic workflow

craft 엔진의 **orchestrated driver**. linear 경로 (`pipeline.md`) 와 같은 다섯
phase 와 같은 content ref 를 쓰지만, *토폴로지* 가 단일 linear 세션이 아니라
멀티에이전트다: 영속적 설계 council 이 플랜을
논쟁하고, Workflow 가 test-first 로 빌드하고, 검증 패널이 결과를 원래
의도에 대해 체크한다.

이 driver 는 **작업유형 무관(task-type-agnostic)** 하다. 호출 스킬 (`forge` / `renew` /
`hunt`) 이 linear 엔진에 주는 같은 두 가지 — 자신의
**Phase 1 Socratic 초점** 과 **Phase 3 TDD 진입점** — 을 공급하고, 이 파일이
그 주위의 실행 구조를 공급한다. 그래서 council 은
forge 의 IO-계약 초점이나 renew 의 보존/변경 초점으로 인터뷰하고; 빌드는
forge 의 acceptance 테스트나 hunt 의 regression 테스트에서 시작하며; 작업 framing 의
무엇도 변하지 않는다, 어떻게 실행되는지만.

사용자가 명시적으로 heavyweight 처리를 요청했을 때만 쓴다 (`pipeline.md` →
*Execution mode* 참조). 비싸다 — 영속 에이전트 + 워크플로
fan-out + 수동 shutdown — 그리고 설계 리스크가 진짜일 때만 본전을 뽑는다.
linear 경로는 같은 엔진을 훨씬 싸게 돌린다.

**메인 세션이 허브다**: 사용자 ↔ council 에이전트를 중계하고, Workflow
실행을 시작하고, 검증 발견을 라우팅한다. team-mode 에이전트는 사용자와
직접 대화할 수 없다 — 모든 사용자 턴은 메인 세션을 거친다.

영속 룰 (team mode 가 여기 있는 이유): 에이전트는 **라운드 간에 기억해야 할
때만** 살아있다. **designer** 가 자격이 있다 (Phase 1 의 설계 의도를
Phase 4 판정으로 운반); **adversary** 는 council 루프에 대해 자격이
있다. QA / tester / correctness / security 는 **그렇지 않다** — 무상태(stateless) Workflow fan-out
으로 한 번 돈다.

모델: designer + adversary + 검증 judge + Phase 3 빌드 = **무핀(세션 모델 상속)** —
세션이 최상위 티어면 상속이 곧 최고 품질, 세션이 opus 미만일 때만 `model: 'opus'`
상향 핀(linear 엔진과 동일 규칙 — `dynamic-tdd.md` SSOT). 결정론 스테이지
(§3 verify · §4 tester lane)만 `model: 'haiku'` 최저가 핀.

---

## §0 — Frame & convene the team

1. 작업유형과 한 줄 목표를 되짚는다. heavyweight 경로가 원해진 것인지
   확인 — 사용자가 그냥 작업이 되길 원하면, linear 엔진으로 폴백한다.
2. **세션 이름 설정 (백그라운드 잡일 때 — team convene 전 즉시).** `$CLAUDE_JOB_DIR` 있으면
   `[<key>] <짧은 목표>` 로 rename(`<key>` = Linear 이슈ID 있으면 그것, 없으면 worktype).
   `session-rename.md` snippet 그대로(`name` + `nameSource:"user"`). 잡 아니면 생략, 실패해도 note 만.
3. `TeamCreate({ team_name: 'craft-<topic>', description: '<one-line goal>' })`.
4. 두 council 에이전트를 Agent 도구로 spawn 한다 (`team_name` 설정, model 무핀 —
   세션 상속; 세션이 opus 미만일 때만 `model: 'opus'` 상향):
   - **designer** (`subagent_type: general-purpose`) — spec 과 플랜을 소유한다.
     Brief: "You are the designer on a craft council. Run the Socratic interview
     (the main session relays the user's answers to you) **applying the calling
     skill's Phase 1 focus** — read that skill's SKILL.md Phase 1 section and
     `~/.claude/skills/craft-core/references/socratic.md` and `context-adr.md`.
     Ground every question in the actual code (Read/Grep) and existing docs, and
     produce a testable plan at `docs/plans/<date>-<topic>.md` plus its `.html`
     companion. You will defend and revise this plan against an adversary, and
     later judge the built result against your own intent. Keep your design
     rationale in context — you persist across the whole job."
   - **adversary** (`subagent_type: general-purpose`) — 적대적 플랜 리뷰어.
     Brief: "You are the adversarial reviewer. Attack the designer's plan per
     `~/.claude/skills/craft-core/references/codex-review.md` — hidden assumptions,
     missing edges, security holes, a simpler path, scope creep, ADR conflicts. If
     the `codex:rescue` plugin is available, invoke it and fold its findings in.
     Label each finding blocking / non-blocking. You exist to make the plan wrong
     before code does."

QA / tester / correctness / security 를 여기서 spawn 하지 말 것 — 그들은 Phase 4 에 속하고
team 에이전트가 아니다.

---

## §1 — Council loop (Phase 1 인터뷰 + Phase 2 공격, 융합)

인터뷰와 적대적 리뷰가 하나의 **수렴 루프(convergence loop)** 로 돈다, 왜냐하면
team mode 에서 리뷰어는 standing 에이전트이기 때문이다 — 라운드 N 의 이의가
designer 의 라운드 N+1 에 정보를 주는데, 단일 linear 세션은 이를 할 수 없다.

**deep-interview spec 이 이미 확정됐으면** (`docs/specs/<slug>.md`, acceptance 가
있는 REQ-F/REQ-N), 그걸 다시 elicit 하지 말 것. designer 에게 그 spec 을 시작
플랜으로 로드하고 **attack 라운드** (step 3) 에서 루프에 진입하라고 brief 한다 — 여기서
council 의 가치는 이미 확정된 요구사항에 대한 적대적 설계 공격이지,
두 번째 인터뷰가 아니다. designer 는 여전히 코드에 대해 빠른 ground-check 를 하고,
user-approval 게이트도 여전히 적용된다. spec 이 진짜로 열어둔 부분에 대해서만
전체 인터뷰 (step 1) 로 폴백한다.

Loop:

1. **Interview 라운드.** designer 가 집중된 클러스터 (2–4 질문) 를, 호출 스킬의
   Phase 1 초점으로 묻는다. 메인 세션이 그것을 사용자에게 surface 하고,
   답을 모으고, `SendMessage` 로 다시 중계한다. 선택이 구체적 옵션 사이일 때
   `AskUserQuestion` 을 쓴다. designer 는 스스로 답할 수 있는 것을 위해 코드/문서를
   읽는다.
2. **Draft / revise.** designer 가 플랜 `.md` + `.html` companion 을
   쓴다 (또는 갱신한다). 섹션은 craft-engine 표준 (Goal / Scope / Files /
   Steps→verify / Risks / Security surface / YAGNI / Acceptance).
3. **Attack 라운드.** main 이 플랜 경로를 **adversary** 에게 넘긴다; adversary 가
   blocking + non-blocking 발견 (그리고 있으면 codex 의) 을 반환한다. main 이 blocking
   발견을 designer 에게 중계한다.
4. **Converge check** — **둘 다** 게이트가 성립할 때까지 1–3 을 반복한다:
   - **User-approval 게이트** — 사용자가 현재 플랜을 보고 승인했다.
   - **Adversary 게이트** — adversary (그리고 codex) 가 **blocking** 이의를
     제기하지 않는다, **또는** 2 리뷰 라운드가 완료됐다. 각 라운드의 평결을 플랜에 기록한다.

둘 다 통과하면, 플랜은 Phase 3 계약으로 frozen 된다. 최종 `.md` 와 맞도록
`.html` 을 갱신한다.

> 종료는 이 두 게이트다 — 느낌으로 "최적까지" loop 하는 것은 없다.

**라운드 배너 (progress.md P1).** council 은 자동 진행 트리가 없으므로, 메인
세션이 **라운드 경계마다** 수렴 스코어보드 1블록을 턴에 찍는다 — 공격 건수 +
대표 이의 1구절만, 메시지 본문 중계 금지. 포맷은
`~/.claude/skills/craft-core/references/progress.md` §P1 을 읽어 따른다(복제 금지).
공격 카운트의 감소가 사용자에게 보이는 수렴 게이지다.

---

## §3 — Dynamic-workflow TDD build (opus)

red→green→refactor 규율과 "atomic task" 정의를 위해
`~/.claude/skills/craft-core/references/dynamic-tdd.md` 를 읽어라 — **그 모델
규칙을 그대로 따른다: 구현 무핀(세션 상속, 세션이 opus 미만이면 상향 핀),
verify 는 `haiku` 최저가 핀** — orchestrated 도 linear 엔진과 동일하다.

**호출 스킬이 TDD 사이클이 어디서 시작하는지 정의한다** — linear
엔진과 정확히 같이: `forge` 는 acceptance 테스트를 태스크 1 로 쓴다; `hunt` 는 실패하는
regression 테스트를 먼저 쓴다; `renew` 는 어떤 태스크가 코드를
건드리기 전에 보존 behavior 를 핀하는 characterization 테스트를 쓴다. orchestrated driver 는
진입점을 바꾸지 않고, 구현 단계만 바꾼다.

**designer 는 idle-alive 로 머문다** 이 phase 내내 (shut down 하지 말 것) — 그
설계 의도가 Phase 4 를 위해 여전히 context 에 있도록. 메인 세션이
Workflow 를 구동한다; 빌드 에이전트는 team 멤버가 아니라 무상태 Workflow 에이전트다.

(opt-in — `--codex-build` 또는 명시 요청 시: 빌드 레인의 green 스텝을 codex 로
위임하는 cross-model 구현. Phase 2 의 cross-model 리뷰와 대칭이며, red·verify·intent
judgment 는 여전히 Claude 가 쥔다. 계약·limit 래더 SSOT `codex-build.md`. 미발동이면
아래 표준 Workflow 빌드 그대로 — floor.)

승인된 플랜의 Steps 를 `args.tasks` (`{ id, title, spec, files }`) 로 넘긴다.

```javascript
export const meta = {
  name: 'craft-build',
  description: 'Split the approved plan into atomic tasks and build each test-first',
  phases: [{ title: 'Build' }, { title: 'Verify', model: 'haiku' }],
}

const TASKS = args.tasks
const RESULT = { type: 'object', required: ['task','testsGreen','summary'], properties: {
  task: { type: 'string' }, testsGreen: { type: 'boolean' },
  filesChanged: { type: 'array', items: { type: 'string' } },
  summary: { type: 'string' },
} }

const results = await pipeline(
  TASKS,
  (t) => agent(
    `TDD task: ${t.title}\n\nSpec: ${t.spec}\nFiles in scope: ${t.files}\n\n` +
    `Re-read the approved plan and the relevant docs/guides/ before coding.\n` +
    `1) Write the failing test first; confirm it fails for the right reason.\n` +
    `2) Minimal implementation to green — no speculative extras (YAGNI).\n` +
    `3) Refactor with tests green.\n` +
    `Run only this task's tests. Report testsGreen + files changed. ` +
    `If a target already matches the spec, report testsGreen:true and skip.`,
    { label: `build:${t.id}`, phase: 'Build', schema: RESULT }
  ),
  (impl, t) => agent(
    `Verify task "${t.title}" is genuinely green: run its tests and confirm. ` +
    `Report testsGreen honestly — do not trust the implementer's claim.`,
    { label: `verify:${t.id}`, phase: 'Verify', model: 'haiku', effort: 'low', schema: RESULT }
  ).then(v => ({ ...impl, verified: v.testsGreen }))
)

return results.filter(Boolean)
```

기본은 per-agent 워크트리 격리 **없음** — 에이전트는 메인 세션 작업 트리를
상속해 Stage 2 verify 가 Stage 1 변경을 *같은 트리* 에서 본다. `isolation:
'worktree'` 는 병렬로 같은 파일을 쓰고 충돌할 때만 켜고, 켜면 (a) verify 도 같은
태스크 워크트리에서 돌리고 (b) 종료 후 메인 트리로 merge-back 한다 — 안 하면
verify 가 빈 트리를 봐 false red 를 내거나 변경이 orphan 워크트리에 갇힌다.
`testsGreen:false` 나 `verified:false` 를 반환하는 태스크는 Phase 4 전에 고친다 —
red 태스크로 진행하지 말 것.

build / verify 는 기본 워크플로 subagent 에서 돈다 — 모델 규칙은 위와 같다
(linear 와 동일: 구현 상속, verify haiku). 프롬프트가 곧 계약이다.

---

## §3.5 — Simplify review pass (forge / renew / hunt)

§3 의 빌드가 green 이 된 후, §4 verify 전 — **`forge` / `renew` / `hunt` 모두**.
`~/.claude/skills/craft-core/references/simplify-pass.md` 를 읽어라.

메인 세션이 `AskUserQuestion` 으로 **한 번 제안한다** (기본 off). 거부되거나
정리할 게 없으면, 곧장 §4 로. 수락되면 변경된 diff 를 `/simplify` 스킬로
정리한다 (재사용/단순화/효율/altitude, behavior 불변). `/simplify` 미설치 시
같은 정리를 **단일 Workflow 에이전트(무핀 — 세션 상속)**로 돌린다 (fan-out 없음 —
빌드 diff 에 대한 한 번의 순차 pass, §3 빌드 tier 에 맞춤):

```javascript
export const meta = {
  name: 'craft-simplify-pass',
  description: 'Simplify the build diff, behavior-preserving (fallback when /simplify absent)',
  phases: [{ title: 'Simplify' }],
}
const RESULT = { type: 'object', required: ['testsGreen','summary'], properties: {
  testsGreen: { type: 'boolean' },
  filesChanged: { type: 'array', items: { type: 'string' } },
  summary: { type: 'string' },
} }
return await agent(
  `Simplify pass per simplify-pass.md and convention-guide.md ` +
  `(merge with the project's lint/rules and docs/guides/, most specific wins).\n` +
  `Scope: the §3 build diff and its immediate neighborhood only — Read the diff.\n` +
  `The build's test suite is the behavior pin. Clean in small steps (reuse, ` +
  `dedup, inline, simpler expressions); run the suite after each step. ` +
  `A test goes red → that step changed behavior → revert it and stop on that axis. ` +
  `Never edit a test to make it pass. Do not hunt bugs. Report testsGreen + files changed.`,
  { label: 'simplify:diff', phase: 'Simplify', schema: RESULT })
```

**designer 는 idle-alive 로 머문다** 이 phase 내내 (§4 가 여전히 필요로 한다). 
§4 패널은 그다음 **결합된 (build + simplify) diff** 를 검증한다 — 이 pass 를 위한
별도 verify 게이트는 없다. pass 가 `testsGreen:false` 를 반환하면, red 빌드
태스크처럼 취급한다: §4 로 진행 전에 고치거나 되돌린다.

---

## §4 — Verification panel (hybrid: workflow fan-out + designer judgment)

두 단계. fan-out 은 결정론적 Workflow; 판정은 영속
designer 다.

**Stage A — 병렬 검증 (Workflow `parallel()`).** 
`~/.claude/skills/craft-core/references/security.md` 를 읽어라. diff 에 대해 네 독립
검증자를 돌린다 — **tester lane 은 `haiku`**(결정론 게이트 재실행), 나머지
(qa/correctness/security)는 무핀(세션 상속 — 추론 lane) — correctness·security
lane 의 적대적 refute-each-finding 단계를 포함하여:

```javascript
export const meta = {
  name: 'craft-verify',
  description: 'QA + tester + correctness + security verification of the orchestrated build',
  phases: [{ title: 'Panel' }],
}

const FINDING = { type: 'object', required: ['lane','findings'], properties: {
  lane: { type: 'string' },
  findings: { type: 'array', items: { type: 'object', required: ['title','severity','evidence'],
    properties: { title: {type:'string'}, severity: {type:'string'}, evidence: {type:'string'} } } },
} }

const LANES = [
  { lane: 'qa',          prompt: 'QA the diff against the approved plan Acceptance section: does each acceptance check actually hold? Report gaps.' },
  // tester = deterministic gate re-run → cheapest tier
  { lane: 'tester',      model: 'haiku', effort: 'low', prompt: 'Run the project verify gate (tests / typecheck / lint / build). Report every failure with evidence; redirect long output to a log and cite lines.' },
  { lane: 'correctness', prompt: 'Correctness review of the diff: hunt for bugs the tests MISS — untested branches, off-by-one, null/boundary handling, wrong conditionals/operators, resource leaks, races. Quality (reuse/simplify) and security are other lanes — focus only on correctness defects. For each finding, adversarially try to REFUTE it (is the path reachable? do existing tests already cover it? does an input constraint exclude the branch?); report only survivors with evidence.' },
  { lane: 'security',    prompt: 'Security pass over the diff per security.md. For each candidate finding, adversarially try to REFUTE it; report only those that survive, with evidence.' },
]

return (await parallel(LANES.map(L => () =>
  agent(`${L.prompt}\n\nThe approved plan and the diff are on disk — Read them.`,
    { label: `verify:${L.lane}`, phase: 'Panel', schema: FINDING,
      ...(L.model ? { model: L.model, effort: L.effort } : {}) })
))).filter(Boolean)
```

네 lane 은 기본 워크플로 subagent 에서 돈다 — tester 만 `haiku`, 추론 lane 셋은
세션 상속. 프롬프트가 각 lane 의 검증 계약이다 (correctness·security lane 은 발견을
적대적으로 반박해 살아남은 것만 보고).

**Stage B — intent judgment (영속 designer).** 메인 세션이
패널의 살아남은 발견을 **여전히 살아있는 designer** 에게 `SendMessage` 로
넘긴다. **UI 빌드면** 메인이 먼저
`~/.claude/skills/craft-core/references/ui-verify.md` 를 읽어 그 절차대로 **인터랙션
인벤토리(Part A) → chrome MCP 실구동(Part B) → 시안 갭 표(Part C)** 를 수행하고, 그
산출(구동 판정 목록 + 갭 표 + 스크린샷 경로)을 승인 mockup `.html` 과 함께 `SendMessage`
에 실어 designer 가 코드가 아니라 *실제로 눌린 결과* 를 자기 시안 의도에 대조하게 한다 —
정적 렌더 대조만으론 안 잡히는 동작 결함(버튼 무반응·에러 상태 부재)과 상태별 시안
어긋남을 designer 가 confirmed gap 으로 잡을 수 있다. 절차·도구명·폴백 사다리는 그 파일이
SSOT 다(여기 복제 금지). designer — 원래 의도를 보유 — 가 각각을 분류한다:

- **Confirmed gap** — 플랜의 Goal/Acceptance 로부터의 진짜 deviation → 새 atomic
  태스크로 Phase 3 으로 돌아간다 (그 태스크들만으로 빌드 워크플로 재실행).
- **Out of scope** — 플랜이 의도적으로 제외한 올바른 behavior → 이유와 함께
  기록되고 기각된다.
- **Plan defect** — 빌드는 맞지만 *플랜* 이 무언가 빠뜨림 → 플랜을 amend 하는
  짧은 Phase 1 micro-round, 그다음 delta 를 위한 Phase 3.

designer 가 수용할 때까지 Stage A → B → (필요하면 Phase 3) → A 를 loop 한다: 게이트는
**verify 게이트 green AND designer 가 confirmed gap 을 제기하지 않음 AND (UI 빌드면)
ui-verify §4 게이트 통과**. 아무것도 red 로 출시하지 않는다.

세 번째 절이 §5·§5.1 을 끌고 온다 — designer 가 수용해도 **남은 `[사용자 직접 확인 필요]`
가 2건 이상이면 체크리스트 아티팩트를 publish 하고 dev 서버를 띄운 채 넘겨야** 출시다.
Part A~C 결과를 designer 에게 넘기는 데까지만 신경 쓰고 인계를 흘리는 게 실측된 누락
형태다(ADT-406) — 여기 메인은 designer 에게 *보고*하는 주체이자 사람에게 *인계*하는 주체다.

---

## §5 — Wrap & shut down

1. 요약: 무엇이 바뀌었는지, 추가된 테스트, 보안 평결, 잔여 리스크, 그리고
   designer 의 최종 intent-match 평결.
2. 영속 지식 (`context-adr.md`): ADR 감 결정에 ADR; 재사용 가능한 context 에
   `docs/concepts/` 페이지. 진짜로 정당화될 때만.
3. **team 을 shut down 하라** — `{ type: 'shutdown_request' }` 를 **designer** 와
   **adversary** (그리고 여전히 살아있는 teammate) 에게 보낸다. 이 에이전트들은 영속적이고
   그렇지 않으면 idle 로 lingering 한다. 검증 lane 은 Workflow 에이전트였고
   이미 종료됐다.
4. 사용자가 요청하지 않으면 commit 이나 push 하지 말 것.

---

## Cost & failure notes

- 이 토폴로지는 의도적으로 비싼 경로다: 영속 에이전트 2(세션 티어) + 
  빌드 fan-out + 검증 fan-out + loop-back. 설계 리스크가
  진짜일 때만 정당하다.
- `codex:rescue` 부재 → adversary 가 스스로 Phase 2 공격을 한다 (수동
  폴백), linear 파이프라인과 동일.
- Workflow 실행이 빌드 중간에 실패하면, designer/adversary 는 여전히 살아있다 — 고치고
  Workflow 를 재시작하라; council 을 재spawn 하지 말 것.
- §5 shutdown 을 잊으면 idle 에이전트가 context 를 쥔 채 남는다. 항상 team 을 닫아라.
