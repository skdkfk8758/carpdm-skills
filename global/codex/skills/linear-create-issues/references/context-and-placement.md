# Context and placement review

Use this reference before drafting or writing Linear issues.

## 1. Resolve scope

Identify the candidate team and project from explicit user context first. If not explicit:

1. Inspect the current conversation for a previously confirmed team or project.
2. Inspect Linear teams and projects.
3. Compare adjacent issues and milestones.
4. Ask the user only when multiple materially different placements remain plausible.

Never infer a team from a similarly named project without checking the project's teams.

When a team key or exact name is known, use the exact team getter first. A fuzzy team-list search can return no rows even when the key is valid. If exact lookup and list search disagree, corroborate with the team recorded on a known project or issue; ask the user only if the evidence still conflicts.

## 2. Collect compact workspace facts

Retrieve compact fields first to avoid flooding context:

- Issues: identifier, title, status, status type, labels, project, milestone, parent, updated time, archived/completed/canceled time, URL
- Projects: name, status, teams, summary, milestones
- Labels: existing names and team ownership
- Statuses: names and types

Use `includeArchived: true`. Follow every `hasNextPage` cursor until false. If the connector cannot complete pagination, disclose the incomplete scan in the preview.

If Linear rejects a broad project or issue request because of query complexity, retry with the smallest compact field set. Fetch full project milestones and issue descriptions only for shortlisted candidates. Do not abandon the all-status compact scan merely because the full-field request was too large.

## 3. Search semantically

For each proposed issue:

1. Scan all compact titles across every status.
2. Run two to four focused searches using the outcome, domain nouns, and likely synonyms.
3. Merge and deduplicate candidates.
4. Fetch full descriptions and native relations for up to five strongest candidates.
5. Fetch comments for completed or canceled candidates when the close reason is not obvious.

Do not use keyword overlap alone. Ask whether the candidate would cause the same work to be performed again.

## 4. Interpret status without losing history

| Candidate status | Interpretation questions |
| --- | --- |
| Backlog / unstarted | Is this the same work, a narrower child, or an adjacent prerequisite? |
| In progress / review | Would a new issue conflict with work already underway or create rework? |
| Done / completed | Is the request already resolved, a regression, a new environment, or a follow-up? |
| Canceled | Was the approach invalid, already implemented elsewhere, superseded, or merely deferred? |
| Archived | Is it historical context or still an authoritative constraint? |

Never auto-skip from status alone.

## 5. Choose a proposed action

Use one proposal, subject to user approval:

- **Create new**: no meaningful overlap exists.
- **Create and relate**: the work is distinct but depends on or extends existing work.
- **Update existing**: the active issue owns the same outcome and a small patch makes it accurate.
- **Skip**: the requested outcome is already covered without meaningful scope change.

When proposing an update, preserve the issue's useful history. Prefer metadata or a narrow description patch over a wholesale rewrite.

## 6. Place the issue

Prefer evidence in this order:

1. Explicit user choice
2. Exact/near-duplicate placement
3. Most closely related active work
4. Project and milestone definitions
5. A new structure, only if nothing fits

Use only existing label vocabulary. Do not create convenient synonyms.

Store dependencies in native relations:

- `blockedBy`: this issue cannot start until the referenced issue finishes
- `blocks`: completing this issue unlocks the referenced issue
- `relatedTo`: contextually related without a hard dependency
- `parentId`: the issue is a true child of a broader issue

Do not copy these relations into the human body.

## 7. Approval preview format

Present a compact placement table followed by each exact body:

```markdown
| Issue | Action | Project | Milestone | State | Labels |
| --- | --- | --- | --- | --- | --- |
| ... | Create and relate to ABC-12 | ... | ... | Backlog | FE, Feature |
```

For each issue, list strong candidates and reasoning, then the full body in a fenced block. Explicitly list new container or label writes. End with one approval question covering placement, action, relations, and body.
