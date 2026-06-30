export const meta = {
  name: 'dev-eval-loop',
  description: 'Autonomous dev→eval inner loop: build, score against frozen rubric, retry/short-circuit (C1 harness)',
  phases: [
    { title: 'Dev', detail: 'single-agent build against the approved plan' },
    { title: 'Eval', detail: 'separate checker scores against the frozen rubric' },
  ],
}

// args: { worktree, planPath, mockupPath, evalDir, maxRetries }
// Returns { outcome: 'pass'|'short-circuit', history, attempts }.
//
// Separation integrity (REQ-F-007/008/N-001): dev and checker are SEPARATE agent() calls
// with fresh context. The dev agent gets the PLAN + 시안 (the human contract) but NEVER the
// rubric. STRUCTURAL enforcement (not just prompt): the frozen rubric + authoritative checker
// tests live in `evalDir`, a directory OUTSIDE the dev worktree, so they are not present in
// the worktree for the dev to read. The dev breached an in-worktree `.eval/` during the M2
// dogfood (read the stubs, coded to them, overrode the plan) — keeping eval artifacts out of
// the worktree closes that channel. The checker materializes the tests into a temp dir only
// during grading and deletes it afterwards. Do NOT pass evalDir/rubric paths to the dev prompt.

// FAIL-FAST arg guard. If args did not thread into the script (e.g. the Workflow
// `args` was passed as a JSON STRING instead of an object), every `args.X` is
// undefined: the dev gets "Read the plan at undefined" and the checker, told to
// grade "undefined/rubric.json", searches disk and silently grades a STALE/wrong
// rubric it finds elsewhere — a false short-circuit on a valid implementation.
// Observed twice in dogfood (2026-06-12, 2026-06-15). Throw loudly instead of
// running blind. See loop/log and harness-run SKILL §7.
for (const k of ['worktree', 'planPath', 'evalDir']) {
  if (!args || typeof args[k] !== 'string' || !args[k]) {
    throw new Error(
      `dev-eval-loop: required arg "${k}" missing/non-string (got ${JSON.stringify(args && args[k])}). ` +
        `Pass Workflow args as a JSON OBJECT, not a stringified JSON.`,
    )
  }
}

const MAX_RETRIES = (args && args.maxRetries) ?? 2

// Mirror of scripts/loop-control.mjs decideNext (SSOT; Workflow scripts cannot import).
// Keep in sync — the unit-tested version lives at scripts/loop-control.mjs.
function decideNext(history, maxRetries) {
  const last = history[history.length - 1]
  if (!last) return 'retry'
  if (last.pass) return 'pass'
  const prev = history[history.length - 2]
  if (prev && !prev.pass && prev.signature === last.signature) return 'short-circuit'
  if (history.length >= 1 + maxRetries) return 'short-circuit'
  return 'retry'
}

const VERDICT = {
  type: 'object',
  required: ['pass', 'signature'],
  properties: {
    pass: { type: 'boolean' },
    signature: { type: ['string', 'null'] },
    total: { type: 'number' },
  },
}

const history = []
let attempts = 0

for (let n = 0; ; n++) {
  attempts = n + 1
  phase('Dev')
  // DEV — single agent. Sees plan + mockup only (NOT the rubric). forge is NOT used here
  // (it is an orchestrated, human-gated pipeline; running it would nest + break autonomy).
  // args.devOverlay = project-local self-heal overlay (rules/harness-overlays/dev.md),
  // read by harness-run (Workflow has no fs) and injected here so C4 improvements actually bite.
  const overlay = args.devOverlay ? `Project dev guidance (self-heal overlay) — follow it:\n${args.devOverlay}\n\n` : ''
  await agent(
    overlay +
      `Implement the change for this worktree strictly per the approved plan. ` +
      `Read the plan at ${args.planPath}` +
      (args.mockupPath ? ` and the approved mockup at ${args.mockupPath}` : '') +
      `. Build outside-in, test-first, faithful to the plan contract. ` +
      `Do not invent behavior the plan does not specify. This is attempt ${n + 1}.` +
      // SEPARATION (REQ-F-008/N-001): the eval rubric + checker tests are withheld by design and
      // are NOT in your worktree. Do NOT search for, read, copy, or run any rubric / verdict /
      // eval-oracle files (e.g. `.eval/`, `.eval-run/`, `*rubric*`, `*verdict*`, score-rubric.mjs).
      // Grade-blind: build only from the plan and your own TDD tests.
      ` The eval rubric and checker tests are deliberately withheld and are not in your worktree — ` +
      `do not look for, read, or run any rubric/verdict/eval-oracle files; build grade-blind from the plan and your own tests.` +
      (n > 0
        ? ` Previous attempt failed eval. You do NOT have the rubric or checker tests — re-examine ` +
          `the PLAN and your own tests for what the contract requires that you may have missed or mis-built.`
        : ''),
    { label: `dev:attempt-${n + 1}`, phase: 'Dev' },
  )

  phase('Eval')
  // EVAL — separate checker agent. Reads the FROZEN rubric, runs the eval-check skill,
  // writes a per-attempt verdict so history is not overwritten (B3).
  const verdict = await agent(
    `Act as the eval-check skill (grade only; you did NOT write the code and must not see the ` +
      `dev's reasoning). The FROZEN rubric and authoritative checker tests live OUTSIDE the dev ` +
      `worktree at ${args.evalDir} — rubric: ${args.evalDir}/rubric.json (must be frozen:true), ` +
      `tests: ${args.evalDir}/tests/. They are withheld from the dev by design; keep them out of ` +
      `the worktree except for the transient run below. ` +
      `Use ONLY this exact rubric path — if ${args.evalDir}/rubric.json is missing or not frozen:true, ` +
      `STOP and report an error. Do NOT search for, discover, or fall back to any other eval/rubric ` +
      `directory (e.g. a stale .eval-* from a prior run) — grading the wrong rubric is a false verdict.\n` +
      `To grade attempt ${n + 1}:\n` +
      `1. Materialize the checker tests so their relative imports resolve: copy ${args.evalDir}/tests/ ` +
      `into ${args.worktree}/.eval-run/tests/ (same depth as the original .eval/tests, so ../../src resolves).\n` +
      `2. From ${args.worktree}: run the deterministic items (the copied checker tests under ` +
      `.eval-run/tests + tsc/build for any lint item); judge the judge items by reading src against the plan. ` +
      `Redirect noisy output to ${args.worktree}/.eval-run/run.log and read only the relevant lines.\n` +
      `3. Write results.json, then run the eval-check score-rubric.mjs with ${args.evalDir}/rubric.json ` +
      `to produce the verdict at ${args.evalDir}/verdict-${n + 1}.json.\n` +
      `4. CLEAN UP (mandatory): delete ${args.worktree}/.eval-run entirely so NO eval artifact remains ` +
      `in the worktree for the next dev attempt. Verify it is gone before returning.\n` +
      `Return {pass, signature, total}.`,
    { label: `eval:attempt-${n + 1}`, phase: 'Eval', schema: VERDICT },
  )

  history.push({ pass: !!(verdict && verdict.pass), signature: (verdict && verdict.signature) ?? null })
  log(`attempt ${n + 1}: ${history[n].pass ? 'PASS' : `FAIL ${history[n].signature}`}`)

  const decision = decideNext(history, MAX_RETRIES)
  if (decision !== 'retry') return { outcome: decision, history, attempts }
}
