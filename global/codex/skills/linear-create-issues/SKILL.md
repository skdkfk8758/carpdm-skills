---
name: linear-create-issues
description: Create one or a few real Linear issues through the Linear MCP after inspecting existing issues across every status, projects, milestones, labels, and native relations. Use when the user asks Codex to register, create, or add a small number of Linear issues and wants a placement and duplicate-handling preview before approval. Do not use for bulk plan/spec/PRD decomposition, backlog-wide grooming, or executing the created work.
---

# Linear Create Issues

Create reliable Linear issues whose bodies are written for people. Keep routing analysis, duplicate reasoning, and execution advice outside the issue body.

## Boundaries

- Handle one or a few issues, normally no more than five.
- Do not split a large plan, spec, PRD, or roadmap into a backlog.
- Do not execute the work described by an issue.
- Do not perform backlog-wide cleanup or reorganization.
- Never write to Linear before showing the exact proposal and receiving approval.
- Never add recommended skills, agents, workflows, kickoff prompts, or next-work prompts to an issue body.

## Required resources

- Read [references/context-and-placement.md](references/context-and-placement.md) before inspecting Linear.
- Read [references/human-issue-writing.md](references/human-issue-writing.md) before drafting bodies.
- Run `scripts/validate_issue_body.py` on every proposed body before previewing it.

## Workflow

### 1. Confirm the request is small

Count the intended issues. If the input implies a large decomposition, stop and ask the user to select the immediate one-to-five issues. Do not silently turn a plan into many issues.

Capture only missing human decisions. Discover workspace facts with Linear tools instead of asking the user.

### 2. Resolve the Linear workspace context

Discover the available `mcp__linear__*` tools at runtime; do not invent tool names.

Resolve, in order:

1. Team
2. Existing project
3. Existing milestone
4. Existing labels
5. State, defaulting to `Backlog` when available

Explicit user input wins. Otherwise infer from current conversation and Linear evidence. Ask one concise question if the team or materially different project choices remain ambiguous.

For an exact team key or name, prefer an exact team lookup. If a team-list query returns no match, retry with the exact team getter and corroborate the result from known project or issue team fields before asking the user.

Do not depend on Claude-specific repo maps. Use a Codex-local mapping only when it already exists and matches the current repository; otherwise rely on Linear and user context.

### 3. Inspect existing work before drafting

Follow the full-status scan in `references/context-and-placement.md`.

At minimum:

- List relevant projects and their milestones.
- List the team's existing labels and statuses.
- List all relevant issues with `includeArchived: true` and follow pagination to completion.
- Include backlog, active, review, completed, canceled, and archived records.
- Run focused semantic searches for each proposed issue.
- Fetch full details and native relations for the strongest candidates.
- Read comments for completed or canceled candidates when the resolution or cancellation reason matters.

Start with compact project and issue fields. If a broad request exceeds Linear's complexity limit, reduce the fields and then fetch details only for candidate projects, milestones, or issues. Treat this as a retrieval fallback, not as permission to skip the full compact scan.

Do not claim an all-status or full-project scan if pagination or retrieval was incomplete.

### 4. Classify overlap and placement

Classify each strong candidate as one of:

- Exact active duplicate
- Near duplicate or scope extension
- Related prerequisite or follow-up
- Completed work that may make the request resolved, recurrent, or a follow-up
- Canceled approach whose reason constrains the new work

Propose one action for the user to approve:

- Create new
- Create new and relate it
- Update an existing issue with a minimal patch
- Skip because existing work already covers it

Never choose the action automatically. Never revive or reopen completed/canceled work solely because the title is similar.

Prefer an existing project, milestone, and labels when they accurately fit. Propose a new project, milestone, or label only when no existing structure fits, and treat each creation as an explicit write requiring approval.

### 5. Draft for human readers

Choose the smallest template from `references/human-issue-writing.md`:

- Feature or improvement
- Bug
- Research or decision

Keep the title outcome-oriented and unambiguous. Explain why the issue exists before listing work. Use plain checkboxes for completion conditions.

Do not repeat team, project, milestone, labels, state, parent, blockers, or related issues in the body. Store those as Linear metadata and native relations.

Do not add:

- `## 추천`
- `## 다음 작업`
- `[AUTO]` or `[HUMAN]`
- Skill, agent, or workflow names
- Implementation-method prescriptions that are not product requirements
- Kickoff or copy-paste prompts
- AI boilerplate unless an explicit workspace policy requires it

### 6. Validate every body

Write each draft to a temporary file and run:

```bash
python3 scripts/validate_issue_body.py --kind feature /path/to/body.md
```

Use `--kind bug` or `--kind research` as appropriate. Fix every error before the approval preview.

### 7. Show the approval preview

Before any Linear write, show for each issue:

- Title
- Proposed action
- Team, project, milestone, state, and existing labels
- Native relation plan
- Strong duplicate/related candidates with status and one-line reasoning
- Completed/canceled context that affects the decision
- The exact full body in a fenced Markdown block

Also list every proposed project, milestone, or label creation.

Ask for approval and wait. Approval must cover both placement and exact body. Do not implement a bypass for phrases such as "register immediately"; this skill always previews first.

For an existing-issue update, preview the minimal patch and the resulting full body. Preserve useful history and avoid replacing the entire description when a surgical patch is possible.

### 8. Write in dependency order

After approval:

1. Create approved projects or milestones, if any.
2. Create blockers before blocked issues.
3. Create or update issues with `mcp__linear__save_issue`.
4. Set `project`, `milestone`, `labels`, `state`, and approved native relations using `blockedBy`, `blocks`, `relatedTo`, or `parentId`.
5. Use only labels verified to exist unless label creation was explicitly approved.

If a partial failure occurs, stop. Report successful writes and the failed operation. Do not retry creation blindly because that can make duplicates.

### 9. Verify after writing

Retrieve every created or updated issue with relations. Verify:

- Identifier and URL exist
- Team, project, milestone, state, and labels match the approved preview
- Native relations point in the correct direction
- Body has no forbidden recommendation or workflow sections
- No unresolved placeholder remains

Report the result grouped by milestone or project. Call out any verification gap directly.

## Safety invariants

- Reads may proceed without approval; writes may not.
- Never delete, archive, cancel, reopen, or close existing issues unless the user explicitly approved that exact action.
- Never mutate unrelated issues while improving placement.
- Never treat a completed or canceled status as proof of duplication.
- Never hide scan limits, pagination failures, or connector errors.
