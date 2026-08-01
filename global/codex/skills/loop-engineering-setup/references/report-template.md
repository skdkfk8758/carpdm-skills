# Report And Plan Templates

Use these structures for response-only output. Do not create files unless the user explicitly approves a later execution step outside this skill.

## Loop Readiness Report

```markdown
**Loop Readiness Report**

Target:
- Path or task:
- Context type: greenfield | brownfield | task-only
- Confidence: high | medium | low

Read-only signals inspected:
- ...

Existing loop artifacts:
- `.omx`: present | absent | not inspected
- `.omo`: present | absent | not inspected
- `.claude`: present | absent | not inspected
- `loop`: present | absent | not inspected
- docs/rules/test/CI signals:

Candidate routes:
- Route:
  - Fit:
  - Tradeoff:
  - Prerequisites:

Learning layer:
- Needed: yes | no
- Recommended follow-up: `loop-learning-update` | none
- Why:

Recommendation:
- Recommended route:
- Rationale:
- Why not the alternatives:

Blocked automatic actions:
- No files changed.
- No external/environment-changing commands run.
- No autonomous/madmax permission changes enabled.

User decision needed:
- Choose the route to turn into a setup plan.
```

## Loop Setup Plan

```markdown
**Loop Setup Plan**

Selected route:
- ...

Checklist:
- [ ] ...

Proposed files for a later approved execution step:
- `path`: reason

Proposed commands for a later approved execution step:
- `command`: reason and expected outcome

Verification plan:
- Documentation validation:
- Simulation validation:
- Runtime/loader validation:
- Repo-specific validation:
- Learning update validation, if included:

Rollback or cleanup considerations:
- ...

Approval gate:
- No file writes or external commands should run until the user explicitly approves the execution step.
```

## Approval Question

Use one focused question:

```text
I recommend <route> because <reason>. Should I turn that route into a setup plan, or would you prefer one of the alternatives?
```
