# Dynamic Workflow — Task Split + TDD on Sonnet

Phase 3 turns the approved, codex-reviewed plan into working code. Use the
`Workflow` tool to (a) split the plan into atomic tasks and (b) drive each task
through a strict TDD cycle. Implementation runs on **sonnet** — cheaper and fast
enough for well-specified, test-pinned tasks; the expensive reasoning already
happened in planning and review.

Invoking `Workflow` is authorized here because this skill's instructions tell you
to — that is the skill-invoked opt-in path.

## What "atomic task" means

One task = one slice of the plan that can be made green on its own: a single
behavior, endpoint, function, or fix. If a task can't be expressed as "write a
test that fails for reason X, then make it pass," it's too big — split it.

## The TDD cycle each task must follow

1. **Red** — write the test FIRST. It must fail, and fail for the *right reason*
   (the behavior is missing), not a typo or import error.
2. **Green** — the minimal implementation that makes the test pass. No
   speculative extras (YAGNI).
3. **Refactor** — clean up with the test staying green. No new behavior here.

A task is done only when its own tests are green AND it didn't break a sibling's.

## Workflow script skeleton (adapt — do not copy blindly)

```javascript
export const meta = {
  name: 'tdd-implement',
  description: 'Split approved plan into tasks and implement each test-first on sonnet',
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
  // Stage 1: TDD implement on sonnet
  (t) => agent(
    `TDD task: ${t.title}\n\nSpec: ${t.spec}\nFiles in scope: ${t.files}\n\n` +
    `1) Write the failing test first; confirm it fails for the right reason.\n` +
    `2) Minimal implementation to green — no speculative extras (YAGNI).\n` +
    `3) Refactor with tests green.\n` +
    `Run only this task's tests. Report testsGreen + files changed. ` +
    `If a target already matches the spec, report testsGreen:true and skip.`,
    { label: `tdd:${t.id}`, phase: 'Implement', model: 'sonnet',
      isolation: 'worktree', schema: RESULT }
  ),
  // Stage 2: independent verify that the task's tests actually pass
  (impl, t) => agent(
    `Verify task "${t.title}" is genuinely green: run its tests and confirm. ` +
    `Report testsGreen honestly — do not trust the implementer's claim.`,
    { label: `verify:${t.id}`, phase: 'Verify', model: 'sonnet', schema: RESULT }
  ).then(v => ({ ...impl, verified: v.testsGreen }))
)

return results.filter(Boolean)
```

Notes on the skeleton:

- `model: 'sonnet'` on every implementation/verify agent — this is the required
  model for Phase 3 per the skill contract.
- `isolation: 'worktree'` only when tasks write files in parallel and would
  collide. For a strictly sequential set of tasks you can drop it (it costs disk
  + setup).
- Pass the task list through Workflow `args`, not hard-coded in the script, so the
  same script serves any plan.
- Keep each agent's command pointing at *paths and the plan*, not pasted code —
  the agent has Read.

## After the workflow returns

- Any task with `testsGreen:false` or `verified:false` → fix it (re-run that task
  or handle inline). Do not proceed to Phase 4 with red tasks.
- The task-type skill defines where the cycle *starts* — e.g. `hunt` writes the
  failing regression test as task 1; `reshape` writes characterization tests
  pinning current behavior before any task touches structure.

## Anti-patterns

- Writing implementation before the test (no red step) → you can't prove the test
  tests anything.
- Implementing on this model instead of sonnet → ignores the skill contract.
- One giant agent call for the whole plan → loses the per-task red/green
  discipline and truncates.
- Trusting the implementer's "green" without the independent verify stage.
