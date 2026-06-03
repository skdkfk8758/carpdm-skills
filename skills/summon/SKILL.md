---
name: summon
description: Author a NEW reusable Claude Code subagent definition file end-to-end — run a short interview to pin the agent's job, pick the right model (opus/sonnet/haiku), lock its tool access (read-only vs writing), and write a battle-tested system prompt (Role → Success Criteria → Constraints → Output Format → Failure Modes → Final Checklist) into ~/.claude/agents/ or .claude/agents/. Use this whenever the user wants to CREATE, DEFINE, SCAFFOLD, DESIGN, or WRITE a new subagent/agent — phrasings like "make me an agent that reviews migrations", "create a subagent for dependency audits", "I need a specialized agent to triage flaky tests", "scaffold a security-review agent", "design an agent for X", "/summon". This is for AUTHORING a new agent DEFINITION FILE, not for getting one-off work done. Do NOT trigger when the user just wants a task delegated to some agent (use the Agent/Task tools), when building an app feature (use forge), or fixing a bug (use hunt).
---

# summon — author a Claude Code subagent

Turn a one-line idea ("an agent that audits SQL migrations") into a complete, well-structured
subagent definition file that Claude Code can delegate to. The output is a single markdown file
with YAML frontmatter, written to the user's agent directory.

The design discipline here is reverse-engineered from a battle-tested fleet of 19 production
subagents: every agent declares its mission, its non-responsibilities (which doubles as a
delegation map), measurable success criteria, an explicit output template, and contrastive
failure modes. That structure is what makes an agent *reliable* instead of a vague persona.

## Why this shape works

A subagent's body becomes its **entire** system prompt — it does NOT inherit Claude Code's main
system prompt, only the body plus basic environment info. So the body has to carry everything:
who the agent is, what "done" means, what it must never do, and exactly what to emit. Thin
"You are a helpful X" prompts drift; the skeleton below pins behavior. Explain the *why* behind
each rule in the prompt you write — these models reason well and follow rationale better than
bare MUSTs.

## Workflow

Do these in order. Ask only what you genuinely can't infer — if the user already described the
agent richly, fill the slots yourself and confirm, don't interrogate.

### 1. Pin the job (interview only if fuzzy)

Get crisp answers to:
- **Mission** — one sentence: "analyze X and produce Y". If the user can't say it in one
  sentence, the agent is too broad — split it or narrow it.
- **Delegation trigger** — when should the orchestrator hand work to this agent? This becomes the
  `description` and is the single most important field: Claude routes to the agent by matching
  the task against it.
- **Reads or writes?** — does it mutate files/code (writing agent) or only inspect and advise
  (read-only agent)? This decides tools (step 3).
- **Hand-offs** — what is it explicitly NOT responsible for, and which other agent owns that?
  Even "none" is a valid answer; capture it.

### 2. Name + description

- `name`: lowercase-with-hyphens, matches the file stem (e.g. `migration-auditor`).
- `description`: a delegation tagline. Two proven styles — a role + parenthetical
  (`"Adversarial plan/code review gate (read-only)"`) or a capability list
  (`"Root-cause analysis, regression isolation, stack-trace triage"`). Keep it ≤ ~20 words and
  make it about *when to route here*, since that drives selection.

### 3. Pick the model

Legible rule (from the source fleet's distribution):

| Choose | When the job is | Examples |
|---|---|---|
| `opus` | judgment under ambiguity — planning, adversarial review, requirements, security, architecture | planner, critic, security-reviewer, architect |
| `sonnet` | bounded execution or structured investigation | executor, debugger, test-engineer, tracer |
| `haiku` | mechanical lookup or cheap narrow output | codebase search, doc-writing |

Default to `sonnet` if unsure. Omit `model` entirely to inherit the parent session's model — only
do that when cost/quality truly shouldn't be pinned.

### 4. Lock tool access

The body narrates *which* tools to use; the frontmatter *enforces* what's reachable. Pick one:

- **Read-only / advisory agent** → restrict mutation. Cleanest: `disallowedTools: Write, Edit`
  (inherits everything else, blocks file changes). Or a tight allowlist:
  `tools: Read, Grep, Glob, Bash, WebFetch`.
- **Writing / implementing agent** → omit `tools` to inherit the full toolset, then constrain
  scope in the body (`<Constraints>`), not the frontmatter.

Caveat: some tools are never available to subagents even if listed — `Agent`, `AskUserQuestion`,
`EnterPlanMode`, `ExitPlanMode`, `ScheduleWakeup`. Never put those in `tools`. (Full rules and the
complete frontmatter field list: `references/frontmatter.md`.)

### 5. Write the system prompt body

Fill the section skeleton. Read `references/convention.md` for the annotated template and the
writing-discipline rules; read `references/examples.md` for two complete worked agents (one
read-only advisor, one writing implementer) to copy the shape from. The backbone, in order:

1. **Role** — `You are <Name>. Your mission is to <verb>.` then `You are responsible for …` then
   `You are not responsible for … (<other-agent> handles that).` The negative clause is the
   delegation map.
2. **Why This Matters** — the cost/consequence rationale. Why do these rules exist?
3. **Success Criteria** — measurable, checkable done-conditions (they become the Final Checklist).
4. **Constraints** — hard rules, scope limits, `Hand off to:` lines, escalation policy.
5. **Process** — the numbered domain workflow the agent follows.
6. **Tool Usage** — `Use <Tool> for <purpose>` bullets.
7. **Output Format** — a *literal* markdown template the agent emits every time.
8. **Failure Modes to Avoid** — contrastive pairs: `<name>: <bad behavior>. Instead, <right
   behavior>.`
9. **Examples** — one concrete Good, one concrete Bad (real file:line / commands, not abstract).
10. **Final Checklist** — Success Criteria restated as "Did I …?" questions.

Not every agent needs all ten — a tiny lookup agent can shed Why/Examples — but default to the
full set and drop sections deliberately, not by omission. Use markdown `##` headings for the
sections (standard Claude Code agents are plain markdown; the XML-tag style from the source fleet
is an oh-my-claudecode framework convention and is unnecessary here).

### 6. Choose the install location (ASK)

Ask the user, unless they already said:
- **Global** `~/.claude/agents/<name>.md` — available in every project.
- **Project** `.claude/agents/<name>.md` — scoped to this repo, checked into version control so the
  team shares it. Create the directory if absent.

### 7. Write, validate, and report

Write the file, then verify before claiming done:
- frontmatter parses; `name` is kebab-case; `description` present.
- `model` is one of `opus`/`sonnet`/`haiku`/`inherit` (or omitted).
- no subagent-unavailable tool in a `tools` allowlist.
- all chosen sections present and non-placeholder.

Tell the user the path and that a **new** agent file needs a Claude Code restart to load (agents
created via the `/agents` interface load immediately, but a file written directly does not until
restart). Then show them how to invoke it (delegate a matching task, or call it explicitly).

## Anti-patterns

- **Persona-only prompt** — "You are an expert X" with no Success Criteria or Output Format. It
  reads fine and behaves randomly. The skeleton exists to stop exactly this.
- **Kitchen-sink agent** — one agent that plans AND implements AND reviews. Split by
  responsibility; the non-responsibility clause is there to force this.
- **Frontmatter scope theater** — listing `tools` you then contradict in the body, or restricting
  a writing agent so tightly it can't do its job. Match the lock to the role (step 4).
- **Copying the `level:` field or `<Agent_Prompt>` XML wrapper** from oh-my-claudecode agents —
  those are that framework's runtime convention; standard Claude Code ignores `level` and doesn't
  need the wrapper.
