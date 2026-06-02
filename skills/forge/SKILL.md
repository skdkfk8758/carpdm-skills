---
name: forge
description: Build a NEW feature end-to-end through a rigorous pipeline — Socratic requirements interview → adversarial plan review by codex → dynamic-workflow TDD implementation on opus → security-verified. Use this whenever the user wants to ADD, BUILD, IMPLEMENT, or CREATE a new feature, endpoint, component, page, command, or capability that does not exist yet — even when they phrase it casually like "add X", "build me Y", "I need a Z", or "can you make it do W", and even if they never mention a process or tests. Prefer forge over ad-hoc coding for any non-trivial new feature. Do NOT use it for fixing broken behavior (use hunt), changing an existing feature (use renew), or restructuring code without behavior change (use reshape).
---

# Forge — build a new feature

You are building something that does not exist yet. The risk is building the
wrong thing, or the right thing without proof it works. The pipeline kills both:
the spec is pinned by Socratic interview, attacked by codex, then implemented
outside-in test-first on opus, then verified and security-checked.

Run the shared engine in `~/.claude/skills/craft-core/references/pipeline.md`
(read it first). Apply these forge-specific emphases inside it:

## Phase 1 — Socratic focus (see craft-core/references/socratic.md)

A new feature's spec lives in the user's head — extract it. Lead with:

- **User value / job-to-be-done** — what does this let someone do, and why does
  that matter? (Question the question — sometimes the real need is simpler.)
- **Exact IO contract** — concrete inputs and the exact outputs/states expected,
  with examples. This becomes your acceptance test.
- **Success metric & acceptance scenarios** — "done" stated as checks, not vibes.
- **Non-goals** — what this feature explicitly will NOT do (caps scope creep).
- Confirm where it plugs in by reading first (code-graph/LSP if available, else
  Read/Grep) — existing routes, stores, types — so the new code matches real
  contracts, not assumed ones. Skim relevant ADRs/concepts (`context-adr.md`) too.
- **ADR-worthy?** A new architectural pattern, dependency, or external contract →
  record an ADR in Phase 5. A plain feature on existing rails → no ADR.

## Phase 3 — TDD entry point (see craft-core/references/dynamic-tdd.md)

Build **outside-in**: task 1 is the acceptance test derived straight from the IO
contract (it fails — the feature is absent). Then each subsequent task is a unit
slice driven red → green → refactor on opus until the acceptance test passes.
Don't build infrastructure the acceptance scenarios don't demand.

Phases 0, 2, 4, 5 run exactly as in the shared pipeline.
