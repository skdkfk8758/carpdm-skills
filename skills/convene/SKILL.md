---
name: convene
description: Run a NEW build or a change through the heaviest multi-agent orchestration — a persistent design council (a designer agent + an adversarial reviewer agent) that interviews you, drafts a plan, and attacks it in a loop until it converges, then a dynamic-workflow TDD build on sonnet, then a verification panel (QA + tester + security) whose findings the ORIGINAL designer agent judges against the design intent before accepting. Use ONLY when the user explicitly asks for the full council / panel / team treatment, a heavyweight orchestrated build, or maximum-rigor design-plus-verify with multiple cooperating agents — phrasings like "convene a design council", "full panel treatment", "orchestrate this with a team and a workflow", "maximum rigor, spare no agents", "팀으로 설계하고 워크플로로 구현해줘", "council 소집". This is EXPENSIVE (persistent team-mode agents + workflow fan-out + manual shutdown) and deliberately UNDER-triggers. Do NOT auto-trigger on a casual "add X" / "build Y" / "fix Z" — a normal new feature is forge, a change is renew, a bug is hunt, a refactor is reshape. convene is the opt-in heavyweight path on top of that same craft engine.
---

# Convene — council-driven build with a verification panel

A slim team-mode + dynamic-workflow harness over the shared craft engine. It puts
**persistence where judgment lives** (a design council that remembers its own
decisions across rounds, and an intent oracle that survives into verification)
and **determinism where execution lives** (a Workflow-driven TDD build and a
parallel verify fan-out). It is the same four ideas as the craft pipeline —
Socratic spec → adversarial review → test-first build → secure verify — but the
*topology* is multi-agent instead of a single linear session.

Use it only when the extra cost buys something: a high-stakes design where a
standing adversary across rounds and an intent-checked verification are worth the
tokens. For ordinary work, `forge` / `renew` / `hunt` / `reshape` already run the
same engine in one session — reach for those first.

The phase *content* is the shared engine; read those references as each phase
needs them (do not duplicate their logic here):

- `~/.claude/skills/craft-core/references/socratic.md` — Phase 1 interview
- `~/.claude/skills/craft-core/references/codex-review.md` — Phase 2 attack
- `~/.claude/skills/craft-core/references/dynamic-tdd.md` — Phase 3 TDD cycle
  (convene **overrides its model pin** — see below)
- `~/.claude/skills/craft-core/references/security.md` — Phase 4 security pass
- `~/.claude/skills/craft-core/references/context-adr.md` — grounding + Phase 5 ADRs

The convene-specific orchestration — agent roles, team setup, convergence gates,
the Phase 3/4 Workflow scripts, and shutdown discipline — lives in
`references/orchestration.md`. **Read it before Phase 0.**

## Model assignment (hard contract)

| Phase | Agents | Model |
|---|---|---|
| 1+2 | designer, adversarial reviewer | **opus** (`claude-opus-4-8`) |
| 3 | TDD implementation + per-task verify | **sonnet** (`claude-sonnet-4-6`) |
| 4 | QA, tester, security, intent-judge (designer) | **opus** (`claude-opus-4-8`) |

> Phase 3 runs on **sonnet**, deliberately. This **supersedes** the `model:'opus'`
> pin in `dynamic-tdd.md` — that file's "dropping opus is an anti-pattern" note
> does NOT apply under convene. The build is fully test-pinned (red→green→refactor)
> and independently verified, so sonnet carries the implementation while opus is
> reserved for the judgment-heavy phases (design, adversarial review, verification).
> Every other agent in this skill runs on opus.

## Phase map

- **Phase 0 — Frame & convene the team.** Restate task type + one-line goal.
  Isolation per project rule (6+ files / architecture / 3+ file refactor →
  worktree). `TeamCreate`, then spawn the **designer** (opus) and **adversary**
  (opus). See orchestration.md §0.
- **Phase 1+2 — Council loop (team mode).** The designer runs the Socratic
  interview *with you* (relayed through the main session) and writes the plan
  (`docs/plans/…md` + `.html` companion); the adversary attacks it (and calls
  `codex:rescue` when present). designer revises → adversary re-attacks. **Loop
  until BOTH gates pass: you approve the plan AND the adversary/codex raises no
  blocking objection (≤2 review rounds).** No open-ended looping — these gates are
  the termination condition. See orchestration.md §1.
- **Phase 3 — Dynamic-workflow TDD build (sonnet).** The approved plan is the
  contract. Use the `Workflow` tool to split it into atomic tasks and drive each
  red→green→refactor on **sonnet**, with an independent per-task verify. The
  designer agent stays **idle-alive** through this phase so it keeps the design
  intent in context. See orchestration.md §3.
- **Phase 4 — Verification panel (hybrid).** A `Workflow` `parallel()` fan-out
  runs **QA + tester + security** (opus) over the diff — including the adversarial
  refute-each-finding step from `security.md`. Their findings go to the *still-alive*
  **designer** agent, which judges each against the original intent ("is this a real
  gap vs the plan, or out of scope?") and decides **accept** or **re-enter Phase 3**
  for the confirmed gaps. See orchestration.md §4.
- **Phase 5 — Wrap & shut down.** Summarize (changed / tests / security verdict /
  residual risk). Record ADRs/concepts if genuinely warranted (`context-adr.md`).
  **Shut the team down** (`shutdown_request` to every teammate) — convene's
  persistent agents do not self-terminate. Do not commit/push unless asked.

## Anti-patterns (convene-specific)

- Using convene for ordinary work — the council cost only pays off on high-stakes
  design. Casual "add X" is `forge`.
- Open-ended council looping with no convergence gate — Phase 1+2 ends on *user
  approval AND no blocking objection*, not on vibes.
- Letting Phase 3 fall back off **sonnet** to a cheaper tier — sonnet is the floor
  here, not the ceiling. (opus elsewhere; never below sonnet on the build.)
- Running QA/tester/security as persistent team agents — they are a one-shot
  fan-out; only the **designer** earns persistence (it is the intent oracle).
- Forgetting to shut the team down at Phase 5 → idle agents linger.
