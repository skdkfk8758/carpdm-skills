---
id: language-policy
name: language-policy
description: 코드 주석/커밋 메시지/AI 응답 언어 정책 — 프로젝트별 설정 강제
category: output
priority: critical
applies_to: [code, doc, commit]
tracks: [T1, T2, T3]
hooks: [Stop]
related: []
overrides: []
---

# Language Policy

IMPORTANT: Follow the configured language settings strictly for all work in the project.

## Configuration

Language policy is configured per-project with three independent settings:

| Setting | Controls | Example |
|---------|----------|---------|
| `code_comments` | Code comments, docstrings, inline documentation | `en` (English) |
| `commit_messages` | Git commit messages | `ko` (Korean) |
| `ai_responses` | AI agent responses to the user | `ko` (Korean) |

## Rules

- **Code comments**: Write all code comments, docstrings, and inline documentation in the configured language
- **Commit messages**: Write all git commit messages in the configured language
- **AI responses**: Respond to the user in the configured language

## Scope

This policy applies to ALL agents in the system. Each agent MUST check the project's language configuration before producing output.

## Defaults

When no language policy is explicitly configured:
- Code comments: English (`en`)
- Commit messages: English (`en`)
- AI responses: English (`en`)
