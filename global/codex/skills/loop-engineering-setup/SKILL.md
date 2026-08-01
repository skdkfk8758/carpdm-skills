---
name: loop-engineering-setup
description: Diagnose a repo or task and produce a planning-only loop-engineering readiness report and setup plan using OMX and LazyCodex workflows.
---

# Loop Engineering Setup

Use this skill when the user asks to set up loop engineering, choose between OMX/LazyCodex loops, prepare a repo for evidence-bound execution, or design a dev/eval/checker harness plan. This skill is planning-only: it diagnoses and proposes; it does not install, modify, or execute setup.

## Hard Boundaries

During this skill's runtime:

- Do not create, edit, delete, move, or stage target-repo files.
- Do not create `.omx/`, `.omo/`, `.claude/`, `loop/`, `docs/`, `rules/`, package, CI, test, or product files in the target repo.
- Do not run environment-changing commands such as `npm install`, `omx setup`, `lazycodex-ai install`, `codex plugin add`, package-manager commands, network calls, or plugin/config updates.
- Do not enable `--madmax`, autonomous modes, or permission-changing options.
- Do not choose the final loop path for the user. Recommend one, explain tradeoffs, and ask for confirmation before producing the setup plan.

Read-only inspection is allowed. Prefer `rg`, `find`, `ls`, `git status`, config/package reads, and existing docs. If a command could change state or contact a network, do not run it; list it as a proposed later command instead.

## Workflow

1. **Clarify target**
   - Identify whether the target is the current repo, another local path, or a task description.
   - If the target is missing or ambiguous, ask one focused question before inspection.

2. **Read-only diagnosis**
   - Inspect repository signals without changing files:
     - `AGENTS.md`, README/getting-started docs, `package.json`, test scripts, CI files.
     - Existing `.omx`, `.omo`, `.claude`, `loop`, `docs`, `rules` directories when present.
     - Plans/specs under `.omx/` or `.omo/` if they already exist.
   - Classify the target as greenfield, brownfield, or task-only.

3. **Route loop options**
   - Read `references/routing.md`.
   - Present candidate workflows with tradeoffs.
   - Include one clear recommendation, but require user confirmation before setup planning.
   - If the user asks for failure-driven improvement, retrospective updates, or automatic skill/rule refinement, route to `loop-learning-update` as a separate approval-gated follow-up rather than adding mutation logic to this setup skill.

4. **Produce readiness report**
   - Read `references/report-template.md`.
   - Output the readiness report in chat only.
   - If the user selected `--report-only`, stop here.

5. **Approval gate**
   - Ask the user which loop path to plan, using your recommendation as the default.
   - Do not produce a setup plan until the user confirms a path.

6. **Produce setup plan**
   - Output the setup plan in chat only.
   - Mark all files and commands as proposed future changes.
   - Include an explicit approval gate before any later file writes or external commands.

## Output Contract

Every normal run should produce:

1. `Loop Readiness Report`
2. `Recommended Route`
3. `User Decision Needed`

After user confirmation, produce:

1. `Loop Setup Plan`
2. `Proposed Files`
3. `Proposed Commands`
4. `Verification Plan`
5. `Approval Gate`
6. Optional `Learning Update Hook` when the selected execution loop should feed failures or retrospectives into `loop-learning-update`

## Validation

When creating or updating this skill, use `references/simulation-cases.md` to validate:

- Documentation is clear.
- Simulated runs produce reports/plans without file writes or external execution.
- `SKILL.md` frontmatter remains valid and loader-safe.
