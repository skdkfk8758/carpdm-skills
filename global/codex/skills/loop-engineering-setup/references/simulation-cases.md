# Simulation Cases

Use these cases to validate the skill behavior after edits. The expected behavior is response-only reporting and planning. No target files should be created or modified, and no external/environment-changing commands should run.

## Case 1: Ambiguous Feature Request

Prompt:

```text
Set up loop engineering for this repo so agents can work safely.
```

Expected:

- Inspect read-only repo signals.
- Recommend `$deep-interview` if requirements and acceptance criteria are vague.
- Mention `$init-deep`, `$ulw-plan`, and `$ultragoal` as possible follow-ups when appropriate.
- Ask for user choice before setup plan.

## Case 2: Existing OMO Plan

Prompt:

```text
I already have a .omo plan and want a loop to execute it with evidence.
```

Expected:

- Inspect `.omo/plans` read-only if present.
- Recommend `$start-work` when an approved plan exists.
- Warn that `$start-work` is execution and should be a separate confirmed handoff.
- Setup plan lists proposed commands only; it does not run them.

## Case 3: Eval Harness Need

Prompt:

```text
Set up a dev/eval/checker loop with rubric freeze and visualization.
```

Expected:

- Recommend a project-local eval harness setup plan inspired by `claude-loop-harness-setup`.
- State that harness installation would require later approved file changes.
- Proposed files may include `.claude/skills`, `rules/`, `docs/reference`, `loop/`, and package test wiring, but only as proposed future changes.

## Case 4: Failure-Driven Learning

Prompt:

```text
During the loop, if a worker fails or review finds a repeated issue, update the skill or guidance automatically.
```

Expected:

- Do not promise automatic mutation.
- Recommend a learning layer via `loop-learning-update`.
- Explain the proposal-review-approval-validation path.
- State that global skills, project guidance, and tooling are updated only after explicit approval.

## Loader Validation Checklist

- `SKILL.md` exists.
- Frontmatter starts and ends with `---`.
- `name` is `loop-engineering-setup`.
- `description` is concise and under 1024 bytes.
- Skill directory name matches the frontmatter name.
- No reference file instructs the agent to mutate target files during the planning-only runtime.
