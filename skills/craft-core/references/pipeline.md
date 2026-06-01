# Craft Pipeline — Socratic → Adversarial Plan → Dynamic TDD → Secure Verify

Shared 4-phase engine behind `forge` (new feature), `renew` (renew existing),
`reshape` (refactor), and `hunt` (bug fix). The calling skill supplies the
task-type framing — its Socratic focus and where the TDD cycle starts. This file
is the common spine they all run.

The point of the pipeline is to never let a vague ask turn into vague code: an
ask becomes a *testable spec*, the spec gets *attacked* before any code exists,
implementation happens *test-first*, and nothing ships until it is *verified and
secure*. Skipping a phase is allowed only when the user explicitly says so —
otherwise the value of the skill is lost.

## Phase 0 — Frame & isolate

- Restate the task type and a one-line goal back to the user.
- Isolation (project rule): 6+ files, architecture change, or a 3+ file refactor
  → branch into a worktree before editing. If you skip it, say why in your first
  response. A 1–2 file same-topic change can stay on the current branch.

## Phase 1 — Socratic interview → plan

Read `socratic.md`. **Ground first, then ask:** scope-read the code the task
touches (project code-graph/LSP if available, else Read/Grep) and the relevant
existing ADRs/concepts (`context-adr.md`) — so questions are code-anchored and the
plan respects standing decisions instead of re-litigating them. Then use Socratic
questioning to convert the ask into a spec you could hand to a stranger. **Do not
write implementation code in this phase.**

Keep questioning (in small focused clusters, not a 20-question dump) until you
can state all of:

- **Goal** as verifiable success criteria ("returns 400 on empty body", not
  "handles bad input").
- **Scope IN / OUT** — what this change does and explicitly does not touch.
- **Affected files & contracts** — verified by Read/Grep, never guessed. Naming a
  file or symbol you haven't opened is a Phase-1 failure.
- **Edge cases & failure modes.**
- **Security surface** — every input, auth boundary, secret, and external call
  this change exposes or relies on.
- **YAGNI deletions** — dead paths this change orphans, to be removed in the
  same change (not "a later PR").

Write the plan to `docs/plans/YYYY-MM-DD-<topic>.md` (or the project's
`.planning/<phase>/` if it uses that). Sections:

```
# <topic>
## Goal (testable success criteria)
## Scope (IN / OUT)
## Files (verified — path : why it changes)
## Steps (each step → its verify check)
## Risks
## Security surface
## YAGNI (deletions in this change)
## Acceptance (the checks that mean "done")
```

Alongside the `.md`, write a review-friendly HTML companion at the same path with
a `.html` extension (`docs/plans/YYYY-MM-DD-<topic>.html`). It is a rendering of
the same plan — no new content, just the Markdown made visual for review. Make it
self-contained (inline `<style>`, no external assets) so it opens straight in a
browser: render each section as a heading + block, show Scope IN/OUT and the
Steps→verify pairs as tables, and code-style the file paths. When codex verdicts
land in the `.md` in Phase 2, re-render the `.html` so the two stay in sync.

Ask the user to confirm the plan before Phase 2. A plan the user hasn't seen is
not a plan.

## Phase 2 — Adversarial plan review (codex)

Read `codex-review.md`. Hand the plan to codex as a hostile reviewer whose job is
to find what is wrong with it — hidden assumptions, missing edge cases, security
holes, a simpler path, scope creep, **and whether the plan makes an architecture
decision that warrants an ADR or conflicts with a standing one**. Fold every
*blocking* finding back into the plan. Re-review until codex raises no blocking
objection or you have done 2 rounds. Record each round's verdict in the plan.

## Phase 3 — Dynamic workflow: task split + TDD (sonnet)

Read `dynamic-tdd.md`. Use the `Workflow` tool to break the approved plan into
atomic tasks and drive each through a strict TDD cycle — **red → green →
refactor** — with implementation agents pinned to `model: 'sonnet'`. Pipeline
over the tasks; a task is done only when its own tests are green. The plan is the
contract; do not implement anything not in it without going back to Phase 1.

## Phase 4 — Secure verify

Read `security.md`. Run the project verify gate (tests / typecheck / lint /
build) **and** a security pass over the diff. Adversarially verify each security
finding (try to refute it) before reporting it as real. Nothing ships red.

## Phase 5 — Wrap

- Summarize: what changed, tests added, security verdict, residual risks.
- Record durable decisions/knowledge (`context-adr.md`): if the work made an
  **ADR-worthy** decision, write `docs/adr/NNN-slug.md` and update the registry;
  if it established **reusable context**, write/update a `docs/concepts/` page.
  Only when it's genuinely worth it — don't manufacture docs for routine work.
- Do not commit or push unless the user asks.

## Anti-patterns (the whole pipeline exists to prevent these)

- Coding before the spec is testable (Phase 1 skipped).
- Treating the user's first phrasing as the full spec.
- Skipping codex review because "the plan looks fine" — the plan looking fine is
  exactly when an adversary is most useful.
- Implementing on opus/this-model instead of sonnet in Phase 3.
- Reporting tests green without running the security pass.
