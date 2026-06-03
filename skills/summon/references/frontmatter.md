# Standard Claude Code subagent frontmatter

Authoritative reference for the YAML frontmatter of a subagent definition file, plus the
model- and tool-selection rules. Source: Claude Code docs (code.claude.com/docs/en/sub-agents).
Only `name` and `description` are required; everything else is optional.

## Supported fields

| Field | Required | What it does |
|---|---|---|
| `name` | **Yes** | Unique identifier, lowercase letters + hyphens. Hooks receive it as `agent_type`. The filename does not have to match, but keep them equal for sanity. |
| `description` | **Yes** | When Claude should delegate to this agent. This is the routing signal — write it about *when to use*, not just what it is. |
| `tools` | No | Allowlist of tools the agent may use, comma-separated. **Inherits all tools if omitted.** |
| `disallowedTools` | No | Denylist — tools removed from the inherited/allowed set. Use this for read-only agents (`Write, Edit`). |
| `model` | No | `sonnet`, `opus`, `haiku`, a full model ID (e.g. `claude-opus-4-8`), or `inherit`. Defaults to `inherit`. |
| `permissionMode` | No | `default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, or `plan`. |
| `maxTurns` | No | Cap on agentic turns before the agent stops. |
| `skills` | No | Skills to preload into the agent's context at startup (full content injected). |
| `mcpServers` | No | MCP servers available to this agent (by name or inline config). |
| `hooks` | No | Lifecycle hooks scoped to this agent. |
| `isolation` | No | `worktree` gives the agent an isolated copy of the repo. |

Non-standard fields seen in some third-party fleets — **do not use**, standard Claude Code ignores
them: `level`, `color`, and the `<Agent_Prompt>` XML body wrapper (oh-my-claudecode framework
conventions).

## Tools available to subagents

Subagents inherit the internal tools and MCP tools of the main conversation by default. **These
tools are never available to a subagent even if listed in `tools`** — they depend on the main
conversation's UI/session state:

- `Agent`
- `AskUserQuestion`
- `EnterPlanMode`
- `ExitPlanMode` (unless `permissionMode: plan`)
- `ScheduleWakeup`
- `WaitForMcpServers`

So a subagent cannot itself ask the user a question or spawn another subagent via `Agent` — design
around that. If an agent "needs to ask the user", it should instead return its open questions in
its output for the orchestrator to resolve.

## Restricting tools — two strategies

Use one, not both:

**Allowlist** (`tools`) — exclusively permit a set; everything else, including MCP tools, is denied:
```yaml
---
name: safe-researcher
description: Research agent with restricted capabilities
tools: Read, Grep, Glob, Bash
---
```

**Denylist** (`disallowedTools`) — inherit everything except the named tools. The clean way to make
a read-only advisor:
```yaml
---
name: architecture-advisor
description: Read-only architecture and debugging advisor
disallowedTools: Write, Edit
---
```

Rule of thumb:
- **Read-only / advisory** → `disallowedTools: Write, Edit` (simplest) or a tight `tools` allowlist.
- **Writing / implementing** → omit `tools` (inherit all), constrain scope in the body instead.

## Model selection rule

| Choose | Job character | Why |
|---|---|---|
| `opus` | judgment under ambiguity: planning, adversarial review, requirements, security, architecture | these tasks punish shallow reasoning; the cost is justified |
| `sonnet` | bounded execution / structured investigation: implementing, debugging, testing, tracing | strong default for "do this defined thing well" |
| `haiku` | mechanical, narrow, high-volume: codebase search, doc generation | fast and cheap where deep reasoning isn't needed |
| omit (`inherit`) | the agent should track whatever the parent session runs | when you don't want to pin cost/quality |

Default to `sonnet` when genuinely unsure.

## File locations & priority

When two agents share a name, higher priority wins:

| Location | Scope | Priority |
|---|---|---|
| Managed settings | Organization-wide | 1 (highest) |
| `--agents` CLI flag | Current session | 2 |
| `.claude/agents/` | Current project | 3 |
| `~/.claude/agents/` | All your projects | 4 |
| Plugin `agents/` dir | Where plugin enabled | 5 (lowest) |

Both `.claude/agents/` and `~/.claude/agents/` are scanned recursively, so subfolders
(`agents/review/…`) are fine for organization — identity comes from `name`, not path.

## Loading

A file written directly to an agents directory loads on the **next** Claude Code start. Agents
created through the `/agents` interactive interface take effect immediately. After `summon` writes
a file, tell the user to restart (or recreate via `/agents` if they need it live now).
