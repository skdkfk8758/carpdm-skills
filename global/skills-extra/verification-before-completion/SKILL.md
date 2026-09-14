---
name: verification-before-completion
description: "Verify a completion claim against actual user-visible behavior and appropriate project checks."
---

# verification-before-completion

List the claims being made and the smallest evidence capable of proving each. Run fresh checks for the changed behavior and required repository gates. Preserve exit codes and inspect output. Validate UI via a real browser, API via an actual request, CLI via invocation, and data migrations via target-state inspection when authorized.
Differentiate static correctness, mocked tests and real integration behavior. Record pre-existing failures separately without declaring unverified work complete. A failed acceptance criterion blocks a completion claim and PR handoff. Summarize commands, outcomes and evidence paths; do not rerun broad checks absent new changes or unresolved concerns.

## Execution boundaries
Use the tools actually available in the current host. Read the repository's CLAUDE.md and applicable local rules before repository work. In Codex, use its native shell, patch and question tools; in Claude Code use its equivalents. If a structured question tool is absent, ask one plain-text question. Browser work uses an available authenticated browser surface when needed. Do not assume a named model, agent role, plugin, hook or background runtime exists. Work directly unless parallel work is explicitly requested or permitted by governing instructions.

Continue authorized reversible work without repeat approval. An authorized implementation task may include committing, pushing and creating its PR after checks pass. Merge, deployment, branch/worktree deletion and issue deletion each require an explicit request covering that action and target. Skill invocation alone does not authorize an ambiguous destructive target. A request for PR creation does not authorize merging. Preserve unrelated changes, credentials and session history. Report the actual command/output or artifact proving completion and any validation gaps.
