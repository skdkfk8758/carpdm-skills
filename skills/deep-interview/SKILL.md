---
name: deep-interview
description: Run a rigorous one-question-at-a-time Socratic interview that turns a vague idea into a testable, build-ready spec — gated by a measurable ambiguity score so it stops exactly when the requirements are clear, not before. Use this whenever the user shows up with a fuzzy, half-formed, or ambitious idea and wants to be interviewed, questioned, or "thought through" before any code is written — phrasings like "interview me about X", "help me think this through", "I have a rough idea for Y", "socratically question me", "pin down what I actually want", "deep dive on the requirements", or "/deep-interview". It drives the conversation with the six classic Socratic question types (clarification, probing assumptions, probing reasons/evidence, alternative viewpoints, implications/consequences, and questioning the question), locking the component topology first, then attacking the single weakest dimension each round until the spec is clear enough that a stranger could verify it. Prefer this over jumping straight to a plan when the idea is genuinely ambiguous or large. Do NOT use it for small, already-clear tasks, for fixing a known bug, or when a build pipeline (forge/renew/hunt/reshape) is already running its own requirements step.
---

# Deep Interview — Socratic disambiguation before you build

Someone arrives with an idea that lives mostly in their head. The risk is not
that they can't explain it — it's that *they don't yet know which parts are
still vague*, and neither do you. A normal "what do you want?" conversation
papers over that: the user fills silence with plausible-sounding answers, you
nod, and the ambiguity survives intact into the build, where it costs 10×.

This skill kills that by doing two things at once:

1. **Measure the ambiguity.** Every round you score how clear the spec is on a
   few weighted dimensions and report a single number. The interview is *gated*
   on that number — it ends when the spec is provably clear, not when the user
   runs out of patience.
2. **Drive with the Socratic method.** Each question is one of six classic
   Socratic types, chosen to attack the *weakest* dimension. You ask one
   sharp question, they answer, the answer raises a score, you re-target. The
   user does the thinking; you supply the pressure and the structure.

The output is a crystallized spec a stranger could verify, plus a clean handoff
to whatever builds it.

## When this is the right tool

Reach for it when the idea is **genuinely ambiguous or large** and the cost of
building the wrong thing is real. Skip it for small, already-clear tasks (just
do them), for fixing a known bug (that's a different kind of investigation), or
when a build pipeline is already running its own requirements step — don't
double-interview.

## The six Socratic question types — your only instrument

Every question you ask is one of these. Naming the type to yourself keeps you
from drifting into leading questions or thinly-veiled suggestions. Each round,
pick the type that best pries open the *current weakest dimension*.

| # | Type | What it pries open | Trigger phrasing |
|---|------|--------------------|------------------|
| 1 | **Clarification** | Vague nouns/verbs; the actual IO | "What exactly do you mean by X? Give me one concrete input and the output you'd want." |
| 2 | **Probing assumptions** | Unstated premises taken as fact | "You're assuming X always holds — does it? What breaks if it doesn't?" |
| 3 | **Probing reasons & evidence** | Claims with no backing | "What makes you confident that's true? Is there a case that already shows it?" |
| 4 | **Alternative viewpoints** | Tunnel vision; simpler paths | "Is there a simpler approach that avoids this entirely? Who would disagree with this choice?" |
| 5 | **Implications & consequences** | Downstream/edge effects | "If we do that, what's the worst input it now has to survive? What contract moves?" |
| 6 | **Question the question** | The wrong problem being solved | "What's the real goal behind this? If we solved that need another way, would this task still matter?" |

Deep guidance, example banks per type, and how to select — `references/socratic-playbook.md`. Read it before round 1.

## The interview, phase by phase

State lives in the conversation itself: each round you print a short report
table, and those reports *are* the resumable record. No hidden state files.

### Phase 0 — Set the ambiguity threshold (do this first, once)

The interview ends when **ambiguity ≤ threshold**. Default threshold is **0.2**
(i.e. you stop at ~80% clarity). The user can override per-run:

- `--quick` → threshold 0.35 (faster, fewer rounds, coarser spec)
- `--standard` / default → 0.20
- `--deep` → 0.10 (exhaustive; all challenge modes fire)

State the threshold and where it came from in one line before any question, so
the user knows the finish line: *"Target: ambiguity ≤ 0.20 (standard). I'll stop
when we cross it."*

### Phase 1 — Orient (greenfield vs brownfield)

Decide whether this idea touches an existing codebase (**brownfield**) or is
net-new (**greenfield**). If brownfield, scope-read the area it touches *before*
asking — a grounded question ("`getPlan` returns `None` on a missing id today —
keep that or raise?") gets a decision; a generic one gets a generic answer. Use
the project's code intelligence (code-graph MCP / LSP) if present, else
Read/Grep, scoped to the impact radius — never the whole repo. This choice also
selects the scoring formula (see `references/scoring.md`).

### Round 0 — Lock the topology (one gate, before depth)

Before drilling into anything, get the user to confirm the **top-level component
list** — the 1–6 big pieces the idea breaks into. Mark each **active** (we'll
nail it now) or **deferred** (acknowledged, out of scope for this interview).
This is a single confirmation question, and it matters: without it, you can
spend ten rounds perfecting component A while the real ambiguity hides in
component C. The topology is the map you rotate across.

### Phase 2 — The interview loop (one question per round)

Repeat until ambiguity ≤ threshold:

1. **Score** each dimension 0–1 (goal / constraints / criteria, + context for
   brownfield) and compute ambiguity. Formulas and dimension definitions:
   `references/scoring.md`.
2. **Target** the weakest dimension of the weakest active component. Say which
   one and *why it's the current bottleneck* — the user should see the logic.
3. **Ask one question** — never batch. Pick the Socratic type that best attacks
   that dimension (e.g. weak goal → type 1/6; weak constraints → type 2/5; weak
   criteria → type 3/5).
4. **Report** a compact round table: dimension scores, ambiguity %, which
   component, what you're targeting next.

One question per round is non-negotiable: batching lets the user answer
shallowly across the board instead of thinking hard about the one thing that
matters most right now.

### Phase 3 — Challenge modes (perspective shifts at depth)

If ambiguity is stubborn, the issue is usually a bad assumption, not a missing
detail. Inject these once each, at round thresholds — they layer *on top of* the
Socratic types:

- **Round 4+ — Contrarian:** attack a core assumption head-on (Socratic type 2/4).
- **Round 6+ — Simplifier:** probe whether the complexity is even needed (type 4/5).
- **Round 8+ — Ontologist:** if still murky, reframe the whole thing around its
  core entities and their relationships (type 1/6).

Details and example openers: `references/socratic-playbook.md` (Challenge modes).

### Stopping — the gate, with escape hatches

- **Primary:** ambiguity ≤ threshold → proceed to Phase 4.
- **Soft cap (round 10):** offer to continue or crystallize now, naming what's
  still vague and the risk of stopping.
- **Hard cap (round 20):** crystallize with current clarity; flag residual
  ambiguity explicitly in the spec.
- **Early exit (round 3+):** if the user says "stop / build it / good enough",
  honor it — state the current ambiguity and what's unresolved, then crystallize.

### Phase 4 — Crystallize the requirements spec

Write a **system requirements document** using `references/spec-template.md`.
Each requirement gets a stable ID (`REQ-F-NNN` functional / `REQ-N-NNN`
non-functional), a MoSCoW priority, its own acceptance criterion, and an Origin
column tracing it back to the interview round that pinned it. The template also
captures the goal/scope, locked topology, constraints, assumptions resolved,
brownfield context, and the clarity trail.

Save it where the project keeps specs if there's an obvious home (`docs/specs/`
in a repo that uses that layout — follow a directory-per-spec convention if the
repo has one), otherwise propose a path and let the user confirm before writing.
This file is meant to live on as the system's requirements of record, so the
numbered IDs must stay stable once assigned.

### Phase 5 — Route to the right next skill

This skill does **not** build — it produces a requirements spec and routes it to
the pipeline that does. The interview already revealed the *nature* of the work
(Phase 1's greenfield/brownfield call plus the goal), and that nature maps to a
specific task-type skill. Classify it, then recommend with `AskUserQuestion` —
let the user choose, never auto-start.

| Interview revealed… | Route to | What the spec gives it | Fit |
|---------------------|----------|------------------------|-----|
| A **new** capability that doesn't exist (greenfield) | **`/forge`** | the spec *is* its pinned requirements | best |
| **Changing** an existing feature — behavior moves, callers may break (brownfield) | **`/renew`** | what must change vs what must be preserved | strong |
| **Restructuring** with no behavior change (brownfield) | **`/reshape`** | the invariant to hold + blast radius — but pure refactors rarely need a full interview | partial |
| Something **broken** to fix | **`/hunt`** | weak match — hunt wants a reproduction + root cause, not requirements; usually go to `/hunt` directly instead | weak |
| Not code, or leaving this session | return the spec file | the user carries it elsewhere | — |

**Recommend the intensity too, not just the skill.** The craft pipeline runs in
one of two modes — *linear* (default, single session) or *orchestrated* (a
multi-agent design council: adversarial design attack + post-build intent
verification, slower and more expensive). The engine normally guesses the mode
from a cold "stakes signal" at its start — but you just spent a whole interview
measuring exactly that, so pass your read forward instead of letting it guess.
Recommend **council** only when the interview surfaced real design risk; default
to **linear** otherwise (council is opt-in and costly — don't push it on clear,
small work). Strong council signals:

- **Residual ambiguity at stop** — you hit a cap with requirements still vague.
- **Broad topology** — 4–6 interdependent active components, large design surface.
- **Hard convergence** — many rounds, challenge modes fired (especially the
  ontologist at round 8+, meaning the framing itself was wrong), or churning
  entities.
- **Cross-cutting non-functionals** — security / migration / compatibility that
  span components, where one design choice ripples.

When these are absent (clear, converged fast, 1–2 components), say linear and
move on. When present, name the signal in the handoff, e.g.: *"6 components,
stopped at 18% with REQ-N-002 still soft — worth running `/forge` in council
mode."* The user still decides; you're handing the engine an informed call.

**Avoid the double interview.** Each of forge / renew / reshape / hunt runs its
*own* Socratic requirements step (the shared craft-core Phase 1, and the fused
council loop in orchestrated mode). If you hand off naively, the user gets
interviewed twice. So the handoff must tell the next skill
to treat this spec as its **already-completed Phase 1 output** and skip straight
to plan review. Frame the recommendation that way, e.g.:

> "Requirements are pinned in `docs/specs/<slug>.md` (ambiguity <N>%). Run
> `/forge` using that spec as the Phase-1 result — don't re-interview; go to the
> adversarial plan review next."

If the matching skill isn't installed in this project, fall back to a plain
implementation plan built from the numbered requirements, or just hand over the
spec file.

## Anti-patterns

- **Batching questions** — defeats the whole mechanism; one per round.
- **Leading questions** — "Don't you think we should use Postgres?" is a
  suggestion wearing a question mark. Stay in the six types.
- **Scoring theater** — inventing precise-looking numbers you don't believe.
  The score is a judgment call made honestly; its job is to show direction and a
  finish line, not to fake rigor.
- **Interviewing past clarity** — once ambiguity ≤ threshold, stop. More
  questioning is friction, not diligence.
- **Skipping Round 0** — drilling deep before the topology is locked is how you
  perfect the wrong component.
- **Asking what the code already answers** (brownfield) — read first, then ask
  the decision the code can't make for you.
