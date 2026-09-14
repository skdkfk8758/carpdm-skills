---
name: systematic-debugging
description: "Diagnose a reproducible failure and verify a minimal fix using evidence; use for bugs and regressions."
---

# systematic-debugging

Capture the failing user operation, environment and exact error. Reproduce at the relevant surface; if unavailable, explain the limitation. Trace inputs across boundaries to find where observed behavior diverges. Compare a working case or history when useful. Form a falsifiable hypothesis and run the smallest experiment distinguishing it from alternatives.
Fix the demonstrated cause. Add a regression check when it protects a meaningful behavioral boundary. Re-run the failing scenario and appropriate project checks. Do not equate a typecheck with browser/DB behavior. If an experiment refutes the hypothesis, update it explicitly. Report cause, change, observed result and remaining uncertainty. Do not change unrelated code or mask failures.

## Execution boundaries
Use the tools actually available in the current host. Read the repository's CLAUDE.md and applicable local rules before repository work. In Codex, use its native shell, patch and question tools; in Claude Code use its equivalents. If a structured question tool is absent, ask one plain-text question. Browser work uses an available authenticated browser surface when needed. Do not assume a named model, agent role, plugin, hook or background runtime exists. Work directly unless parallel work is explicitly requested or permitted by governing instructions.

Continue authorized reversible work without repeat approval. An authorized implementation task may include committing, pushing and creating its PR after checks pass. Merge, deployment, branch/worktree deletion and issue deletion each require an explicit request covering that action and target. Skill invocation alone does not authorize an ambiguous destructive target. A request for PR creation does not authorize merging. Preserve unrelated changes, credentials and session history. Report the actual command/output or artifact proving completion and any validation gaps.
