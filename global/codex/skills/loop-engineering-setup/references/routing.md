# Loop Routing Reference

Use this file when choosing which loop-engineering path to recommend.

## Routing Rules

Recommend one primary route, list viable alternatives, then ask the user to choose.

| Signal | Recommend | Why |
| --- | --- | --- |
| Requirements are vague or acceptance criteria are missing | OMX `$deep-interview` | Clarifies intent, non-goals, decision boundaries, and acceptance criteria before planning. |
| Repo is large or lacks durable local guidance | LazyCodex `$init-deep` | Creates project memory and hierarchical `AGENTS.md` context before deeper planning. |
| User needs a decision-complete implementation plan | LazyCodex `$ulw-plan` or OMX `$ralplan` | `$ulw-plan` is strong for OMO execution plans; `$ralplan` is strong for consensus/architecture planning. |
| Approved OMO plan exists and evidence-bound execution is needed | LazyCodex `$start-work` | Executes checklist work with Boulder state, delegated workers, manual QA, adversarial QA, cleanup, and review gates. |
| Open-ended task should continue until verified completion | LazyCodex `$ulw-loop` | Uses a durable loop with evidence-bound steps and reviewer pressure. |
| Work should become durable Codex/OMX goals | OMX `$ultragoal` | Converts the clarified brief into durable goal-mode checkpoints. |
| Large work needs parallel lanes | OMX `$team` after plan/goal creation | Coordinates workers; best used after shared scope and verification criteria exist. |
| Repo needs dev/eval/checker separation, rubric freeze, loop visualization, or local harness planning | Project-local eval harness plan inspired by `claude-loop-harness-setup` | Produces a future install plan for harness files, tests, logs, and visualization without installing them now. |
| Failure, repeated mistake, review finding, or retrospective should improve future loops | `loop-learning-update` | Drafts approval-gated improvements to project guidance, global skills, or tooling without auto-applying them. |

## Recommendation Heuristics

- Default to clarification before execution when requirements are unclear.
- Default to OMO `$ulw-plan` + `$start-work` when the user wants evidence-led implementation with explicit plan checkboxes.
- Default to OMX `$ultragoal` when the user wants durable goal tracking more than OMO plan execution.
- Recommend project-local harness planning only when the repo needs repeatable eval gates, rubric scoring, dev/eval/checker role separation, or loop visualization.
- Recommend `loop-learning-update` as a follow-up when the loop needs a learning layer. Keep it separate from setup and execution so failures become reviewed improvement proposals, not automatic global mutations.
- Do not combine multiple long-running loops by default. Prefer one primary driver and list the others as optional follow-ups.

## Candidate Tradeoff Language

- OMX `$deep-interview`: best for ambiguity; not an execution engine.
- OMX `$ralplan`: best for architecture/test-shape review; still planning-first.
- OMX `$ultragoal`: best for durable goal tracking; may be heavier than a small task needs.
- OMX `$team`: best for parallel work; needs a clear shared spec.
- LazyCodex `$init-deep`: best for repo memory; can be overkill for a small repo.
- LazyCodex `$ulw-plan`: best for decision-complete plans; does not implement.
- LazyCodex `$start-work`: best for strict evidence gates; high ceremony for tiny changes.
- LazyCodex `$ulw-loop`: best for open-ended verified completion; avoid if the stopping condition is not clear.
- Project-local eval harness: best for repeatable quality gates; requires later approved file changes.
- `loop-learning-update`: best for failure retrospectives and instruction/tooling improvement proposals; does not auto-edit skills or project rules.
