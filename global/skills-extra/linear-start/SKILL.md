---
name: linear-start
description: "Implement explicitly selected Linear issues through validation and PR creation."
---

# linear-start

Read the issue, acceptance criteria, linked design, blockers and repository mapping. Resolve only missing decisions that materially change behavior. Respect dependencies; do not start blocked work blindly. Use one isolated worktree per independent issue with repository branch naming. Inspect existing branches/PRs to resume safely.
Transition the authorized issue to the actual team's In Progress state when work begins and publish the branch according to repository policy. Implement directly, or delegate only if permitted; parallelism is optional. Verify each acceptance criterion and required project checks, then commit, push and create/update its PR. Link the PR and report actual state. Do not mark Done merely because a PR exists or a typecheck passes. Do not merge or deploy without an explicit request. Keep recoverable work and explain any blocker.

## Execution boundaries
Use the tools actually available in the current host. Read the repository's CLAUDE.md and applicable local rules before repository work. In Codex, use its native shell, patch and question tools; in Claude Code use its equivalents. If a structured question tool is absent, ask one plain-text question. Browser work uses an available authenticated browser surface when needed. Do not assume a named model, agent role, plugin, hook or background runtime exists. Work directly unless parallel work is explicitly requested or permitted by governing instructions.

Continue authorized reversible work without repeat approval. An authorized implementation task may include committing, pushing and creating its PR after checks pass. Merge, deployment, branch/worktree deletion and issue deletion each require an explicit request covering that action and target. Skill invocation alone does not authorize an ambiguous destructive target. A request for PR creation does not authorize merging. Preserve unrelated changes, credentials and session history. Report the actual command/output or artifact proving completion and any validation gaps.
