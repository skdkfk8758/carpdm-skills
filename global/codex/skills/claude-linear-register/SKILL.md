---
name: claude-linear-register
description: Deprecated imported Claude compatibility entry. Use only when an explicit request refers to the old claude-linear-register skill; do not create or update Linear issues with this skill, and route actual issue registration to the Codex-native linear-create-issues skill.
---

# Deprecated Claude Linear Register Import

Do not use this imported compatibility entry to read or write Linear.

For one or a few Linear issues, use `$linear-create-issues`. It performs the full-status scan,
placement and duplicate review, exact-body preview, approval gate, write, and post-write verification.

The live Claude Code equivalent is maintained separately at
`~/.claude/skills/linear-register/SKILL.md`.
