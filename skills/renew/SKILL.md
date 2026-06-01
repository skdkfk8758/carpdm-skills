---
name: renew
description: Renew or revamp an EXISTING feature through a rigorous pipeline — Socratic interview to separate what must change from what must be preserved → adversarial plan review by codex → dynamic-workflow TDD on sonnet → security-verified. Use this whenever the user wants to CHANGE, REDESIGN, REVAMP, MODERNIZE, OVERHAUL, EXTEND, or REWORK an existing feature, flow, screen, or API — phrasings like "redo the X", "rework how Y works", "modernize the Z flow", "change the behavior of W", "the old A should now also do B". Especially when backward compatibility, migration, or not breaking existing callers matters. Do NOT use it to build something brand new (use forge), to fix a bug (use hunt), or to restructure code with no behavior change (use reshape).
---

# Renew — revamp an existing feature

You are changing something that already works and that something already depends
on. The risk is breaking the parts that should have stayed, or losing track of
who relied on the old behavior. The pipeline makes the preserve/change line
explicit, pins the preserved behavior with tests before you touch it, and lets
codex hunt for the callers you forgot.

Run the shared engine in `~/.claude/skills/craft-core/references/pipeline.md`
(read it first). Apply these renew-specific emphases inside it:

## Phase 1 — Socratic focus (see craft-core/references/socratic.md)

The spec here is a *delta* against current reality, so map current reality first:

- **Current behavior inventory** — what does the feature do today? Establish it by
  reading first (code-graph/LSP if available, else Read/Grep) plus the relevant
  ADRs/concepts (`context-adr.md`) — not memory, and not against a standing ADR.
- **Preserve vs change** — draw the explicit line: which behaviors MUST survive
  untouched, which are being changed, which are being removed.
- **Dependents & contracts** — who calls this? what contract (API shape, event,
  store key) do they rely on? Will the change break them?
- **Migration & compatibility** — is a migration needed? a deprecation window?
  what's the rollback?
- **ADR-worthy?** A contract/behavior decision (auth-model swap, API envelope
  change, migration strategy) → record an ADR in Phase 5.
- **Edge & failure inputs (type 5)** — the worst/unusual inputs the changed
  behavior must survive, and what breaks downstream if it doesn't. Behavior
  changes are where unhandled edges hide — run the completeness sweep before
  finalizing the spec.
- **YAGNI** — old code paths the revamp obsoletes get deleted in the same change.

## Phase 3 — TDD entry point (see craft-core/references/dynamic-tdd.md)

First write **characterization tests pinning the preserved behavior** — the
"MUST survive" list from Phase 1. They should pass against today's code; they are
your safety net so the revamp can't silently break what should stay. Then drive
the *changed* behavior red → green → refactor on sonnet, with the characterization
tests staying green throughout.

Phases 0, 2, 4, 5 run exactly as in the shared pipeline.
