---
name: craft-core
description: Internal shared engine for the forge / renew / reshape / hunt development skills. Not invoked directly — those skills read its reference files.
user-invocable: false
---

# Craft Core

Shared 4-phase development engine: **Socratic interview → adversarial plan review
(codex) → dynamic-workflow TDD on sonnet → secure verify**. The four
task-type skills (`forge`, `renew`, `reshape`, `hunt`) each add their own
Socratic focus and TDD entry point, then run this engine.

This skill is a container for shared references. Do not trigger it on its own.

## References

- `references/pipeline.md` — the full 4-phase pipeline (the spine).
- `references/socratic.md` — Socratic questioning method for Phase 1.
- `references/codex-review.md` — adversarial plan review via `codex:rescue`.
- `references/dynamic-tdd.md` — `Workflow`-tool task split + TDD on sonnet.
- `references/security.md` — secure verify (Phase 4).
- `references/context-adr.md` — read ADRs/concepts for grounding (Phase 1),
  write/manage ADRs & concept docs for durable decisions (Phase 5).

A task-type skill points you here. Read `pipeline.md` first; pull the others in as
each phase needs them.
