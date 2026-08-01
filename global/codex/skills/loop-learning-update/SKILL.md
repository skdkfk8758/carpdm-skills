---
name: loop-learning-update
description: Analyze loop failures, review findings, or retrospectives and draft safe, approval-gated improvements to project guidance, global skills, or tooling without auto-applying them.
---

# Loop Learning Update

Use this skill when a loop run fails, repeats the same mistake, exposes a weak instruction, or needs a retrospective that may improve project rules, global skills, or support tooling. The default output is an improvement proposal, not a mutation.

## Safety Contract

- Do not automatically edit global skills, project `AGENTS.md`, project files, hooks, configs, or tooling.
- Do not treat one failure as enough to create a global rule unless the evidence shows it generalizes.
- Do not remove or weaken existing safety instructions to make a failed loop pass.
- Do not apply a patch until the user explicitly approves the exact target and diff.
- Do not include secrets, private logs, tokens, cookies, credentials, raw env dumps, or PII in proposals.
- If a proposed change affects global behavior, require validation after applying it.

Read-only inspection is allowed. Patch drafting is allowed. Applying a patch is allowed only after explicit user approval in the current conversation.

## Workflow

1. **Collect evidence**
   - Gather the failure, review comment, loop ledger entry, test output, transcript excerpt, or user retrospective.
   - Prefer concrete artifacts over memory.
   - Redact sensitive data before quoting.

2. **Classify the learning**
   - Read `references/classification.md`.
   - Classify as one of:
     - task-local note
     - project guidance candidate
     - global skill improvement candidate
     - tooling/script improvement candidate
     - no durable update

3. **Check generalization**
   - Ask whether this is a repeated pattern, a repo-specific rule, a global agent behavior issue, or a one-off accident.
   - If evidence is weak, recommend a local retrospective note instead of a global update.

4. **Draft improvement proposal**
   - Read `references/proposal-template.md`.
   - Produce a proposal with:
     - evidence
     - root cause
     - target file or skill
     - proposed change
     - blast radius
     - validation plan
     - rollback plan

5. **Approval gate**
   - Ask the user to choose:
     - keep as note only
     - revise proposal
     - apply project guidance patch
     - apply global skill patch
     - apply tooling/script patch
   - Do not apply anything before approval.

6. **Apply and validate only if approved**
   - Apply the smallest patch that addresses the learning.
   - Run the relevant validation:
     - skill frontmatter/loader checks for global skills
     - simulation cases for workflow skills
     - project tests or lint only if the user approved project changes
   - If validation fails, report the failure and either revert your own patch or leave it as a draft, based on user direction.

## Output Contract

Before approval, output:

1. `Loop Learning Proposal`
2. `Classification`
3. `Evidence`
4. `Proposed Target`
5. `Draft Change`
6. `Validation Plan`
7. `Approval Needed`

After approved application, output:

1. `Applied Change`
2. `Validation Evidence`
3. `Residual Risk`
4. `Next Loop Action`

## Good Targets

- Project `AGENTS.md` or local instruction files when the learning is repo-specific.
- A global skill when the learning is repeated, tool-agnostic, and would help future tasks.
- A reference file inside a skill when the learning is detailed but not core trigger logic.
- A script or template only when the failure came from repeated manual procedure or deterministic formatting.

## Bad Targets

- Global rules for one-off project quirks.
- Broad bans such as "never use X" from a single failure.
- Hidden instruction changes that silently increase autonomy.
- Changes that bypass verification, approval, or safety gates.

