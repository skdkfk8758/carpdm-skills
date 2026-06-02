# Context & ADR — read for grounding, write for durable decisions

Two jobs, both shared by forge/renew/reshape/hunt:

- **Read (Phase 1 grounding)** — before asking the user anything, read the
  project's existing decisions, domain context, and documented procedures
  (guides/reference) so questions don't re-litigate what's settled and the plan
  doesn't contradict a standing decision or a documented how-to.
- **Write (Phase 5 wrap)** — when the work made a decision worth remembering or
  established reusable knowledge, record it so the *next* session doesn't redo the
  reasoning.

These skills are global (used across projects), so everything here is
**convention-detecting**, not hard-coded. Detect what the project uses; fall back
gracefully when it isn't there.

## Detect the convention first

- ADRs: is there a `docs/adr/` directory (and usually a registry like
  `docs/adr/INDEX.md`)? If yes, follow its numbering, filename pattern
  (`NNN-slug.md`), frontmatter, and status field exactly — match the existing
  files, don't invent a new shape.
- Concepts/context: is there a `docs/concepts/` (or the project's equivalent
  knowledge tree)? Note its page format.
- Guides & reference: is there a `docs/guides/` (how-to / runbook / tutorial) or
  `docs/reference/` (API surface, external-resource pointers)? These hold the
  *documented procedure and contract* the task should follow — check them, not
  just ADRs/concepts.
- If none exist: don't manufacture a docs tree for a one-off. Offer to start
  `docs/adr/` only when a genuinely ADR-worthy decision actually arises;
  otherwise skip and just summarize the decision in your wrap-up.

## Read for grounding (Phase 1)

Before the Socratic clusters:

- Skim the ADR registry (`ls docs/adr/`, read the ones touching this task's area).
  The plan must **respect standing ADRs**; if the task would contradict one, say
  so out loud and resolve it with the user — don't silently override a recorded
  decision.
- Read the relevant `docs/concepts/` pages for domain vocabulary and constraints,
  so your questions use the project's terms and don't ask what's already written.
- Check `docs/guides/` and `docs/reference/` for an existing how-to, runbook, or
  documented contract covering this area. If a guide already prescribes the
  procedure, the plan must follow it (or call out explicitly why it deviates) —
  don't reinvent a flow the docs already settle.
- Pair this with the code read (see `socratic.md` → "Read before you ask"): code
  tells you *what is*, ADRs/concepts tell you *why it's that way*, guides/reference
  tell you *how it's meant to be done*.

## Write an ADR (Phase 5) — only when it's ADR-worthy

An ADR records a decision that is **architectural and hard to reverse** — a
contract, a boundary, a technology/pattern choice, a policy that future code must
follow. Most tasks do **not** warrant one; a wall of ADRs for routine work
poisons the registry. Write one when:

- the work chose between real architectural alternatives (and someone later will
  ask "why this way?"), or
- Phase 2 codex flagged the plan as making an architecture decision, or
- the user explicitly framed it as a decision to record.

How (follow the detected convention; the shape below is the common one):

1. Number it: next = `ls docs/adr/[0-9]*.md | tail -1` + 1.
2. `docs/adr/NNN-slug.md` with the project's frontmatter (title, type, created,
   related, tags) and a status (default **Proposed**). Body: Context → Decision →
   Consequences (or whatever the existing ADRs use — match them).
3. **Manage the registry**: add the row to `docs/adr/INDEX.md` in the same commit
   — an ADR not in the index is invisible. If this decision supersedes or amends
   an older ADR, link both ways and update the old one's status.

## Write a concept (Phase 5) — for reusable knowledge

When the work established domain knowledge or context that **2+ future pages would
reference** (a data model, an invariant, a glossary term, a layer boundary),
record it as `docs/concepts/<slug>.md` in the project's page format. Prefer
**updating an existing concept** over creating a near-duplicate. One-off,
single-use context stays inline in the plan — don't promote it.

## Per-task ADR-worthiness (the calling skill sharpens this)

- **forge** — a new architectural pattern, dependency, or external contract →
  ADR. A plain feature on existing rails → no ADR.
- **renew** — a contract/behavior change that's a real decision (auth model
  swap, API envelope change, migration strategy) → ADR.
- **reshape** — usually **no ADR** (behavior unchanged). Exception: the refactor
  *adopts a structural pattern* (e.g. "modular monolith", "writer SSOT") that
  future code must follow → ADR.
- **hunt** — usually **no ADR**. Exception: the fix establishes a standing
  invariant or policy ("all sum-zero inputs normalize to uniform") future code
  must honor → ADR.

## Anti-patterns

- Writing an ADR for routine work → registry noise; readers stop trusting it.
- A new ADR file without the INDEX.md row → the decision is unfindable.
- Asking the user something an existing ADR or concept already answers → looks
  like you didn't read.
- Silently planning against a standing ADR → surface the conflict instead.
- Duplicating a concept page instead of updating the existing one.
