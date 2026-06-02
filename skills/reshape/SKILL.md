---
name: reshape
description: Refactor code with ZERO observable behavior change, with behavior pinned by tests first — Socratic interview to fix the invariant → adversarial plan review by codex → dynamic-workflow refactor on opus → security-verified. Use this whenever the user wants to REFACTOR, restructure, clean up, simplify, extract, split, rename, de-duplicate, decouple, or improve the readability/structure of existing code WITHOUT changing what it does — phrasings like "clean up this module", "extract this into a helper", "this file is a mess, restructure it", "DRY up these three copies", "rename X everywhere", "untangle this". Do NOT use it when behavior is meant to change (use renew), when building something new (use forge), or when something is broken and needs fixing (use hunt).
---

# Reshape — refactor without changing behavior

The defining constraint: **observable behavior must not change**. The only way to
prove that is to pin the current behavior with tests *before* you touch the
structure, then keep those tests green through every step. The pipeline enforces
that ordering and lets codex check that your "equivalent" rewrite really is.

Run the shared engine in `~/.claude/skills/craft-core/references/pipeline.md`
(read it first). Apply these reshape-specific emphases inside it:

## Phase 1 — Socratic focus (see craft-core/references/socratic.md)

- **The smell** — what specifically is wrong with the current structure
  (duplication, long function, tangled deps, unclear names)? Verify it's real by
  reading the code, not assuming from a filename.
- **The invariant** — what observable behavior must NOT change? Public API,
  return values, side effects, ordering, error cases. This is the contract the
  refactor may not break.
- **Blast radius** — what calls this? how far do the changes reach? (Use the
  project's impact tooling / graph if available before manual tracing.)
- **Rule of three** — if extracting a shared abstraction: are there genuinely 3+
  call sites sharing the *same domain meaning*, not just similar shape? Two
  copies stay as they are.
- **Ground it** — read the code (graph/LSP first) and any ADR that pins the
  current structure (`context-adr.md`); the refactor must not contradict it.
- **ADR-worthy?** Usually **no** (behavior unchanged). Exception: the refactor
  adopts a structural pattern future code must follow → record an ADR in Phase 5.

## Phase 3 — TDD entry point (see craft-core/references/dynamic-tdd.md)

Task 1 is **characterization tests that pin current observable behavior** — they
must pass against the code as-is. Only then refactor, in small steps, each step a
task that keeps every test green. **No task may add or change behavior** — if a
test needs to change to pass, the refactor broke the invariant; stop and
reassess. Refactor steps are red only in the sense of "structure not yet
applied," never "behavior not yet present."

Phases 0, 2, 4, 5 run exactly as in the shared pipeline. Note Phase 0 isolation:
a 3+ file refactor goes in a worktree.
