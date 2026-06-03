# Orchestrated Execution — team-mode council + dynamic workflow

The **orchestrated driver** for the craft engine. Same five phases and the same
content refs as the linear path (`pipeline.md`), but the *topology* is
multi-agent instead of a single linear session: a persistent design council
argues the plan, a Workflow builds it test-first, and a verification panel checks
the result against the original intent.

This driver is **task-type-agnostic**. The calling skill (`forge` / `renew` /
`hunt` / `reshape`) supplies the same two things it gives the linear engine — its
**Phase 1 Socratic focus** and its **Phase 3 TDD entry point** — and this file
supplies the execution structure around them. So the council interviews with
forge's IO-contract focus or renew's preserve/change focus; the build starts from
forge's acceptance test or hunt's regression test; nothing about the task framing
changes, only how it is executed.

Use it only when the user explicitly asked for the heavyweight treatment (see
`pipeline.md` → *Execution mode*). It is expensive — persistent agents + workflow
fan-out + manual shutdown — and only pays off when design risk is real. The
linear path runs the same engine far cheaper.

The **main session is the hub**: it relays the user ↔ the council agents, launches
the Workflow runs, and routes verification findings. Team-mode agents cannot talk
to the user directly — every user turn passes through the main session.

Persistence rule (the reason team mode is here at all): an agent stays alive
**only if it must remember across rounds**. The **designer** qualifies (it carries
the design intent from Phase 1 into Phase 4 judgment); the **adversary** qualifies
for the council loop. QA / tester / security do **not** — they run once as a
stateless Workflow fan-out.

Models: designer + adversary + verification judges = **opus** (`claude-opus-4-8`);
the Phase 3 build = **sonnet** (`claude-sonnet-4-6`) — see §3.

---

## §0 — Frame & convene the team

1. Restate the task type and one-line goal. Confirm the heavyweight path is
   wanted — if the user just wants the work done, fall back to the linear engine.
2. Isolation (project rule): 6+ files, an architecture change, or a 3+ file
   refactor → branch into a worktree before any edit. Say why if you skip it.
3. `TeamCreate({ team_name: 'craft-<topic>', description: '<one-line goal>' })`.
4. Spawn the two council agents with the Agent tool, `team_name` set, `model: 'opus'`:
   - **designer** (`subagent_type: general-purpose`) — owns the spec and the plan.
     Brief: "You are the designer on a craft council. Run the Socratic interview
     (the main session relays the user's answers to you) **applying the calling
     skill's Phase 1 focus** — read that skill's SKILL.md Phase 1 section and
     `~/.claude/skills/craft-core/references/socratic.md` and `context-adr.md`.
     Ground every question in the actual code (Read/Grep) and existing docs, and
     produce a testable plan at `docs/plans/<date>-<topic>.md` plus its `.html`
     companion. You will defend and revise this plan against an adversary, and
     later judge the built result against your own intent. Keep your design
     rationale in context — you persist across the whole job."
   - **adversary** (`subagent_type: general-purpose`) — hostile plan reviewer.
     Brief: "You are the adversarial reviewer. Attack the designer's plan per
     `~/.claude/skills/craft-core/references/codex-review.md` — hidden assumptions,
     missing edges, security holes, a simpler path, scope creep, ADR conflicts. If
     the `codex:rescue` plugin is available, invoke it and fold its findings in.
     Label each finding blocking / non-blocking. You exist to make the plan wrong
     before code does."

Do not spawn QA / tester / security here — they belong to Phase 4 and are not
team agents.

---

## §1 — Council loop (Phase 1 interview + Phase 2 attack, fused)

The interview and the adversarial review run as one **convergence loop**, because
in team mode the reviewer is a standing agent — its objections from round N inform
the designer's round N+1, which a single linear session cannot do.

**If a deep-interview spec is already pinned** (`docs/specs/<slug>.md`, REQ-F/REQ-N
with acceptance), don't re-elicit it. Brief designer to load that spec as its
starting plan and enter the loop at the **attack round** (step 3) — the council's
value here is the adversarial design attack on already-pinned requirements, not a
second interview. designer still does a quick ground-check against the code, and
the user-approval gate still applies. Only fall back to the full interview (step 1)
for the parts the spec genuinely left open.

Loop:

1. **Interview round.** designer asks a focused cluster (2–4 questions), using the
   calling skill's Phase 1 focus. The main session surfaces them to the user,
   collects answers, and relays them back via `SendMessage`. Use `AskUserQuestion`
   when the choice is between concrete options. designer reads code/docs to answer
   what it can itself.
2. **Draft / revise.** designer writes (or updates) the plan `.md` + `.html`
   companion. Sections are the craft-engine standard (Goal / Scope / Files /
   Steps→verify / Risks / Security surface / YAGNI / Acceptance).
3. **Attack round.** main hands the plan path to **adversary**; adversary returns
   blocking + non-blocking findings (and codex's, if present). main relays the
   blocking findings to designer.
4. **Converge check** — repeat 1–3 until **BOTH** gates hold:
   - **User-approval gate** — the user has seen the current plan and approved it.
   - **Adversary gate** — adversary (and codex) raise **no blocking** objection,
     **or** 2 review rounds have completed. Record each round's verdict in the plan.

When both gates pass, the plan is frozen as the Phase 3 contract. Refresh the
`.html` so it matches the final `.md`.

> Termination is these two gates — nothing loops "until optimal" by feel.

---

## §3 — Dynamic-workflow TDD build (sonnet)

Read `~/.claude/skills/craft-core/references/dynamic-tdd.md` for the red→green→
refactor discipline and the "atomic task" definition — but **override its model
pin: the orchestrated build runs on `sonnet`, not opus**. The build is test-pinned
and independently verified, which is what licenses the cheaper tier; opus is
reserved for the judgment-heavy phases (design, adversarial review, verification).

The **calling skill defines where the TDD cycle starts** — exactly as in the linear
engine: `forge` writes the acceptance test as task 1; `hunt` writes the failing
regression test first; `renew` / `reshape` write characterization tests pinning
preserved behavior before any task touches code. The orchestrated driver does not
change the entry point, only the executor.

The **designer stays idle-alive** through this phase (do not shut it down) so its
design intent is still in context for Phase 4. The main session drives the
Workflow; the build agents are stateless Workflow agents, not team members.

Pass the approved plan's Steps in as `args.tasks` (`{ id, title, spec, files }`).

```javascript
export const meta = {
  name: 'craft-build',
  description: 'Split the approved plan into atomic tasks and build each test-first on sonnet',
  phases: [{ title: 'Build', model: 'sonnet' }, { title: 'Verify', model: 'sonnet' }],
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
    { label: `build:${t.id}`, phase: 'Build', agentType: 'executor', model: 'sonnet',
      isolation: 'worktree', schema: RESULT }
  ),
  (impl, t) => agent(
    `Verify task "${t.title}" is genuinely green: run its tests and confirm. ` +
    `Report testsGreen honestly — do not trust the implementer's claim.`,
    { label: `verify:${t.id}`, phase: 'Verify', agentType: 'test-engineer', model: 'sonnet', schema: RESULT }
  ).then(v => ({ ...impl, verified: v.testsGreen }))
)

return results.filter(Boolean)
```

`isolation: 'worktree'` only if tasks write in parallel and would collide; drop it
for a strictly sequential set. Any task returning `testsGreen:false` or
`verified:false` is fixed before Phase 4 — do not advance with red tasks.

`agentType: 'executor'` / `'test-engineer'` route build / verify to the curated
`agents/` pool. Here the pool's default model (sonnet) **matches** the orchestrated
§3 tier, so unlike the linear engine no opus override is needed — the `model:
'sonnet'` is just explicit. If the pool isn't installed, drop `agentType`; the
default workflow subagent runs the same prompt.

---

## §3.5 — Convention reshape pass (forge / renew only)

After §3's build is green, before §4 verify — **for `forge` and `renew` only**
(`hunt` and `reshape` skip it, same reasoning as the linear engine). Read
`~/.claude/skills/craft-core/references/reshape-pass.md`.

The main session **offers it once** (default off) via `AskUserQuestion`. If
declined or there's nothing to align, go straight to §4. If accepted, run the
alignment as a **single `sonnet` Workflow agent** (no fan-out — it's one
sequential pass over the build diff, matching the §3 build tier):

```javascript
export const meta = {
  name: 'craft-reshape-pass',
  description: 'Align the build diff to project convention, behavior-preserving, on sonnet',
  phases: [{ title: 'Reshape', model: 'sonnet' }],
}
const RESULT = { type: 'object', required: ['testsGreen','summary'], properties: {
  testsGreen: { type: 'boolean' },
  filesChanged: { type: 'array', items: { type: 'string' } },
  summary: { type: 'string' },
} }
return await agent(
  `Convention reshape pass per reshape-pass.md and convention-guide.md ` +
  `(merge with the project's lint/rules and docs/guides/, most specific wins).\n` +
  `Scope: the §3 build diff and its immediate neighborhood only — Read the diff.\n` +
  `The build's test suite is the behavior pin. Align in small steps (naming, ` +
  `guard-clauses, import groups, error handling); run the suite after each step. ` +
  `A test goes red → that step changed behavior → revert it and stop on that axis. ` +
  `Never edit a test to make it pass. Report testsGreen + files changed.`,
  { label: 'reshape:convention', phase: 'Reshape', model: 'sonnet', schema: RESULT })
```

The **designer stays idle-alive** through this phase (§4 still needs it). The
§4 panel then verifies the **combined (build + reshape) diff** — there is no
separate verify gate for this pass. If the pass returns `testsGreen:false`, treat
it like a red build task: fix or revert before advancing to §4.

---

## §4 — Verification panel (hybrid: workflow fan-out + designer judgment)

Two stages. The fan-out is deterministic Workflow; the judgment is the persistent
designer.

**Stage A — parallel verification (Workflow `parallel()`, opus).** Read
`~/.claude/skills/craft-core/references/security.md`. Run three independent
verifiers over the diff, each on **opus**, including the adversarial
refute-each-finding step for the security lane:

```javascript
export const meta = {
  name: 'craft-verify',
  description: 'QA + tester + security verification of the orchestrated build, on opus',
  phases: [{ title: 'Panel', model: 'opus' }],
}

const FINDING = { type: 'object', required: ['lane','findings'], properties: {
  lane: { type: 'string' },
  findings: { type: 'array', items: { type: 'object', required: ['title','severity','evidence'],
    properties: { title: {type:'string'}, severity: {type:'string'}, evidence: {type:'string'} } } },
} }

const LANES = [
  { lane: 'qa',       agentType: 'qa-tester',         prompt: 'QA the diff against the approved plan Acceptance section: does each acceptance check actually hold? Report gaps.' },
  { lane: 'tester',   agentType: 'test-engineer',     prompt: 'Run the project verify gate (tests / typecheck / lint / build). Report every failure with evidence; redirect long output to a log and cite lines.' },
  { lane: 'security', agentType: 'security-reviewer', prompt: 'Security pass over the diff per security.md. For each candidate finding, adversarially try to REFUTE it; report only those that survive, with evidence.' },
]

return (await parallel(LANES.map(L => () =>
  agent(`${L.prompt}\n\nThe approved plan and the diff are on disk — Read them.`,
    { label: `verify:${L.lane}`, phase: 'Panel', agentType: L.agentType, model: 'opus', schema: FINDING })
))).filter(Boolean)
```

Each lane maps 1:1 to a curated `agents/` pool member: `qa-tester` / `test-engineer`
/ `security-reviewer`. `security-reviewer` is opus by default (matches this panel's
tier); the other two are sonnet-default and **overridden to opus** here for the
verification panel. The reviewer-class pool agents are `disallowedTools: Write,Edit`
— a verifier can't accidentally mutate the diff it's judging. If the pool isn't
installed, drop `agentType` and the prompts run on the default subagent.

**Stage B — intent judgment (the persistent designer, opus).** The main session
hands the panel's surviving findings to the **still-alive designer** via
`SendMessage`. The designer — which holds the original intent — classifies each:

- **Confirmed gap** — a real deviation from the plan's Goal/Acceptance → goes back
  to Phase 3 as a new atomic task (re-run the build workflow with just those tasks).
- **Out of scope** — correct behavior the plan deliberately excluded → recorded
  and dismissed, with the reason.
- **Plan defect** — the build is right but the *plan* missed something → a short
  Phase 1 micro-round to amend the plan, then Phase 3 for the delta.

Loop Stage A → B → (Phase 3 if needed) → A until the designer accepts: gate is
**verify gate green AND designer raises no confirmed gap**. Nothing ships red.

---

## §5 — Wrap & shut down

1. Summarize: what changed, tests added, security verdict, residual risks, and the
   designer's final intent-match verdict.
2. Durable knowledge (`context-adr.md`): ADR for an ADR-worthy decision; a
   `docs/concepts/` page for reusable context. Only when genuinely warranted.
3. **Shut the team down** — send `{ type: 'shutdown_request' }` to **designer** and
   **adversary** (and any teammate still alive). These agents are persistent and
   will linger as idle otherwise. The verification lanes were Workflow agents and
   have already terminated.
4. Do not commit or push unless the user asks.

---

## Cost & failure notes

- This topology is the expensive path on purpose: 2 persistent opus agents + a
  sonnet build fan-out + an opus verify fan-out + loop-backs. Only justified when
  design risk is real.
- `codex:rescue` absent → the adversary does the Phase 2 attack on its own (manual
  fallback), same as the linear pipeline.
- If a Workflow run fails mid-build, the designer/adversary are still alive — fix
  and re-launch the Workflow; do not re-spawn the council.
- Forgetting §5 shutdown leaves idle agents holding context. Always close the team.
