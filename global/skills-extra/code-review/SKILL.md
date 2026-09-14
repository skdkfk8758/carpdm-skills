---
name: code-review
description: "Review a concrete diff or change for actionable bugs and regressions, with file references and supporting evidence."
---

# code-review

Establish the exact diff/base and read surrounding code, callers and tests needed to assess behavior. Prioritize introduced correctness, security, data integrity and regression risks. For each finding provide file/line, trigger, consequence, evidence and a minimal correction. Distinguish demonstrated bugs from uncertainty; omit speculative style preferences.
Run focused reproduction when it materially supports a finding. Review-only requests do not authorize edits or posting comments externally. Report severity-ranked findings, or no findings with the scope and validation limits. Re-evaluate revised code before reusing an earlier approval.

## Execution boundaries
Use the tools actually available in the current host. Read the repository's CLAUDE.md and applicable local rules before repository work. In Codex, use its native shell, patch and question tools; in Claude Code use its equivalents. If a structured question tool is absent, ask one plain-text question. Browser work uses an available authenticated browser surface when needed. Do not assume a named model, agent role, plugin, hook or background runtime exists. Work directly unless parallel work is explicitly requested or permitted by governing instructions.

Continue authorized reversible work without repeat approval. An authorized implementation task may include committing, pushing and creating its PR after checks pass. Merge, deployment, branch/worktree deletion and issue deletion each require an explicit request covering that action and target. Skill invocation alone does not authorize an ambiguous destructive target. A request for PR creation does not authorize merging. Preserve unrelated changes, credentials and session history. Report the actual command/output or artifact proving completion and any validation gaps.
