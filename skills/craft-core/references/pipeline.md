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

## Execution mode — linear (default) vs orchestrated

By default this engine runs **linear**: you, in this single session, run every
phase. That is the right mode for almost all work, and the rest of this file
describes it.

Escalate to the **orchestrated** mode — a persistent multi-agent design council +
dynamic-workflow build + verification panel. It gets requested two ways:

- **Explicit cue** — phrasings like "convene a design council", "full panel
  treatment", "팀으로 설계하고 워크플로로 구현해줘", "maximum rigor, spare no
  agents", "council 소집", or the short canonical keyword **`[council]`** /
  **`--council`** anywhere in the request. Honor it directly — no need to ask.
- **Offer on a stakes signal** — if the user did NOT ask for council but signals
  the work is high-stakes or they're nervous ("이거 중요한데", "리스크 커서",
  "제대로 하고 싶어", "불안해", "this is critical", "don't get this wrong"), OR the
  task is objectively high-risk (auth / payments / a contract change with external
  callers / 6+ files), **offer it once** before Phase 1 via `AskUserQuestion`:
  roughly "고위험이라 멀티에이전트 council 모드로 갈 수도 있어요 (느리지만 적대적
  설계검토 + 구현 후 의도검증). 기본 linear로 갈까요, council로 갈까요?". Default to
  **linear** if dismissed or unanswered, and ask at most once — don't re-offer
  every phase.

A casual "build X" / "fix Y" / "refactor Z" with no stakes signal is NOT an
escalation — stay linear silently. This is an intensity choice orthogonal to the
task type: any of forge / renew / hunt / reshape can run either mode.

When escalated, read `orchestrated.md` and drive the five phases through its
team-mode + Workflow topology instead of the linear instructions below. The phase
*content* and your task-type Phase 1 focus / Phase 3 TDD entry point are
unchanged — only the execution structure differs. One model change: the
orchestrated build runs on **sonnet** (the linear Phase 3 below runs on opus).

## Phase 0 — Frame & isolate

- Restate the task type and a one-line goal back to the user.
- Isolation (project rule): 6+ files, architecture change, or a 3+ file refactor
  → branch into a worktree before editing. If you skip it, say why in your first
  response. A 1–2 file same-topic change can stay on the current branch.

## Phase 1 — Socratic interview → plan

**Skip if requirements are already pinned.** If the user points you at a
`deep-interview` requirements spec (e.g. a `docs/specs/<slug>.md` with numbered
`REQ-F`/`REQ-N` entries and per-requirement acceptance), or hands one over, treat
it as the completed Phase-1 output — do **not** re-interview. Read it, confirm it
still matches the code (a quick ground-check, not a fresh interview), carry its
requirements forward as the spec, and go straight to Phase 2. Re-running the
interview on an already-pinned spec is the double-interview anti-pattern. The rest
of this phase applies only when no such spec exists.

Read `socratic.md`. **Ground first, then ask:** scope-read the code the task
touches (project code-graph/LSP if available, else Read/Grep) and the relevant
existing project docs — ADRs/concepts **and the guides/reference tree**
(`docs/guides/`, `docs/reference/`) (`context-adr.md`) — so questions are
code-anchored and the plan respects standing decisions and documented procedures
instead of re-litigating them. Then use Socratic
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
## Acceptance (the checks that mean "done" — each a numbered, single, checkable
##   condition; the skill's acceptance / regression / characterization test IS
##   the item, not vague prose like "handles errors")
```

Alongside the `.md`, write a review-friendly HTML companion at the same path with
a `.html` extension (`docs/plans/YYYY-MM-DD-<topic>.html`). Make it self-contained
(inline `<style>`, no external assets) so it opens straight in a browser. What the
companion *shows* depends on whether the plan delivers a user-facing UI:

- **UI / frontend plans** (a screen, component, page, flow, or any visible
  UX change): the companion is a **mockup of the resulting UI as the user will
  see it once the plan is implemented** — not a rendering of the plan text. Lay
  out the actual interface (chrome, panes, controls, states) and, where it
  clarifies the UX, make it lightly interactive with inline `<script>` so the key
  interaction can be demonstrated, not just described. Mark it visibly as a mockup
  so it isn't mistaken for the shipped product. The plan's tables stay in the
  `.md`; the `.html` is the picture of the outcome.
- **Non-UI plans** (refactor, backend, DB migration, API/contract change, infra):
  a "resulting UI" doesn't exist, so the companion is a **rendering of the plan**
  — no new content, just the Markdown made visual for review: each section as a
  heading + block, Scope IN/OUT and the Steps→verify pairs as tables, file paths
  code-styled.

If a plan is mixed (a UI change with backend work), mock the UI and keep the
non-UI sections as plan rendering below it. When codex verdicts land in the `.md`
in Phase 2, refresh the `.html` so the two stay in sync.

Ask the user to confirm the plan before Phase 2. A plan the user hasn't seen is
not a plan.

## Phase 2 — Adversarial plan review (codex)

Read `codex-review.md`. Hand the plan to codex as a hostile reviewer whose job is
to find what is wrong with it — hidden assumptions, missing edge cases, security
holes, a simpler path, scope creep, **and whether the plan makes an architecture
decision that warrants an ADR or conflicts with a standing one**. Fold every
*blocking* finding back into the plan. Re-review until codex raises no blocking
objection or you have done 2 rounds. Record each round's verdict in the plan.

## Phase 3 — Dynamic workflow: task split + TDD (opus)

Read `dynamic-tdd.md`. Use the `Workflow` tool to break the approved plan into
atomic tasks and drive each through a strict TDD cycle — **red → green →
refactor** — with implementation agents pinned to `model: 'opus'`. Pipeline
over the tasks; a task is done only when its own tests are green. The plan is the
contract: each implementation agent re-reads the approved plan (`.md`) and the
relevant project guides (`docs/guides/`) before writing code, and implements
nothing not in the plan without going back to Phase 1.

## Phase 3.5 — Convention reshape pass (forge / renew only)

Read `reshape-pass.md`. For `forge` and `renew` only, after Phase 3 is green:
**offer once** (via `AskUserQuestion`, default off) a behavior-preserving cleanup
that aligns the just-written diff to the project's conventions — naming,
function/file structure, import/dependency organization, error handling
(`convention-guide.md`, merged with the project's lint/rules and `docs/guides/`).
The Phase 3 tests are the behavior pin; every step keeps them green, and a test
going red means the step changed behavior — revert it. `hunt` and `reshape` skip
this phase (a fix stays surgical; a reshape already is this pass). If declined or
nothing to align, skip straight to Phase 4.

## Phase 4 — Secure verify

Read `security.md`. Run the project verify gate (tests / typecheck / lint /
build) **and** a security pass over the diff. Adversarially verify each security
finding (try to refute it) before reporting it as real. Nothing ships red.
Before shipping, check each Acceptance item from the plan as pass / fail — an
unmet item counts as red, same rule.

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
- Letting Phase 3 agents fall back to a cheaper tier instead of `model: 'opus'`.
- Reporting tests green without running the security pass.
