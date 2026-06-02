---
name: hunt
description: Fix a BUG with a reproduction-first, regression-locked pipeline — Socratic interview to pin the exact reproduction and root cause → adversarial plan review by codex → dynamic-workflow TDD on opus (failing regression test first) → security-verified. Use this whenever the user reports something BROKEN, failing, erroring, crashing, throwing, returning the wrong result, hanging, or behaving unexpectedly and wants it fixed — phrasings like "X is broken", "Y throws on Z", "why does this return null", "the page crashes when…", "this used to work and now…", "getting a 500 from…". Do NOT use it to build a new feature (use forge), to intentionally change a working feature (use renew), or to restructure code with no behavior change (use reshape).
---

# Hunt — fix a bug

The two failure modes of bug fixing are: fixing the symptom instead of the cause,
and fixing it in a way that silently comes back later. The pipeline blocks both —
you can't fix what you can't reproduce, so the cause must be pinned by evidence
first, and the fix is locked by a regression test that fails before and passes
after.

Run the shared engine in `~/.claude/skills/craft-core/references/pipeline.md`
(read it first). Apply these hunt-specific emphases inside it:

## Phase 1 — Socratic focus (see craft-core/references/socratic.md)

- **Exact reproduction** — the precise steps, inputs, and environment that
  trigger it. If you can't reproduce it, that's the first thing to resolve with
  the user; don't guess at a fix for a bug you can't see.
- **Expected vs actual** — what should happen, what does happen, with the real
  error message / stack / wrong output quoted exactly (not paraphrased).
- **Scope & onset** — how widespread, since when, what changed around then.
- **Root-cause hypothesis** — trace it to the actual cause in the code (graph/LSP
  first for callers/impact, else Read/Grep) and the error's own vocabulary; check
  whether an ADR/concept already documents this area (`context-adr.md`). State
  confidence; if it's a guess, say so and verify before planning the fix. Fixing a
  symptom you haven't traced is the most common way bug fixes fail.
- **ADR-worthy?** Usually **no**. Exception: the fix establishes a standing
  invariant/policy future code must honor → record an ADR in Phase 5.
- **Blast radius & edge inputs (type 5)** — what else the root cause touches, and
  the edge inputs the fix must not break (no new regressions). Run the completeness
  sweep before finalizing, so the fix doesn't trade one bug for another.

## Phase 3 — TDD entry point (see craft-core/references/dynamic-tdd.md)

Task 1 is a **failing regression test that reproduces the bug** — it fails for
exactly the reported reason against current code. Only then implement the fix on
opus until that test goes green, and confirm no other test regressed. The
regression test staying in the suite is what stops the bug from returning.

Keep the fix minimal and targeted at the root cause — a bug fix is not a license
to refactor surrounding code (that's reshape). Phases 0, 2, 4, 5 run exactly as
in the shared pipeline.
