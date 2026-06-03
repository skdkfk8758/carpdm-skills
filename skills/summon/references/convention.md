# Subagent authoring convention

The annotated section skeleton and the writing-discipline rules behind a reliable subagent.
Distilled from a fleet of 19 production agents. Use this as the template when writing the body in
step 5 of `SKILL.md`. The body you write IS the agent's entire system prompt — make it carry its
own weight.

## The skeleton (markdown form)

Standard Claude Code agents use a plain markdown body. Render each section as a `##` heading.
(The source fleet wrapped these in `<Agent_Prompt>` XML tags — an oh-my-claudecode framework
convention. Drop the wrapper; keep the sections.)

```markdown
---
name: <kebab-name>
description: <delegation tagline — when to route here>
model: opus | sonnet | haiku        # omit to inherit
disallowedTools: Write, Edit        # ONLY for read-only agents; else omit
---

You are <Name>. Your mission is to <one-sentence verb-phrase>.
You are responsible for <comma-separated duties>.
You are not responsible for <duties> (<other-agent> handles that).

## Why this matters
<Cost/consequence rationale. Why do these rules exist? Frame the stakes — a bad call here
costs 10–100x downstream, an undetected X ships to prod, etc. This is what lets the model
generalize past the literal instructions.>

## Success criteria
- <Measurable, checkable done-condition.>
- <Another. These should be objectively verifiable, not "do a good job".>

## Constraints
- <Hard rule. Scope limit. Read-only marker if applicable.>
- After <N> failed attempts on the same issue, escalate to <agent> with full context.
- Hand off to: <agent> (<when>), <agent> (<when>).

## Process
1. <First step — usually "gather context / read before acting".>
2. <...>
N. <Synthesize into the Output Format below.>

## Tool usage
- Use <Tool> for <purpose>.
- Use <Tool> for <purpose>.

## Output format
<A LITERAL markdown template the agent emits every time. Show the actual headings, the actual
table columns, the verdict line. Not a description of the output — the output itself, with
[bracketed placeholders].>

## Failure modes to avoid
- <Named failure>: <the bad behavior>. Instead, <the correct behavior>.
- <Named failure>: <the bad behavior>. Instead, <the correct behavior>.

## Examples
**Good:** <Concrete, with real file:line / commands. Shows the discipline in action.>
**Bad:** <Concrete counter-example. Name why it's bad.>

## Final checklist
- Did I <success-criterion #1 as a question>?
- Did I <success-criterion #2 as a question>?
```

## Section-by-section discipline

**Role triad.** Always three moves: mission (one sentence) → responsibilities → non-responsibilities.
The non-responsibility clause names the *other* agent that owns the excluded work — this is how a
fleet stays decoupled and how an orchestrator knows where to route. Write it even for solo agents
("You are not responsible for implementation — you only advise.").

**Why this matters.** The single highest-leverage section. It converts rote rules into understood
rules. "Every finding cites file:line" is weak alone; "diagnoses without file:line evidence are
unreliable and waste implementer time, so every claim must be traceable" makes the model *want*
to comply. Prefer one strong rationale over a list.

**Success criteria → Final checklist.** Write these as a pair. Each criterion is a measurable
done-condition; each checklist item is that same criterion phrased as "Did I …?". If a criterion
can't become a yes/no question, it's too vague — sharpen it.

**Constraints.** Where you put the guardrails: scope limits ("smallest viable diff"), read-only
markers, circuit breakers ("after 3 failed attempts, escalate"), and the `Hand off to:` map. For
writing agents this is where you prevent scope creep, since their tools are unrestricted.

**Process.** A numbered sequence, not prose. Investigation/advisory agents almost always start
with "gather context / read the actual code FIRST" — the recurring failure mode is acting before
reading. End by funneling into the Output Format.

**Tool usage.** One bullet per tool: `Use <Tool> for <purpose>`. This is *soft* guidance (the
frontmatter is the hard enforcement). If the agent may delegate, say so explicitly and add the
guardrail "skip silently if delegation is unavailable; never block on it".

**Output format.** Make it literal. The agents that behave most consistently say "Structure your
response EXACTLY as follows" and then show the real template — verdict line
(`APPROVE / REQUEST CHANGES`), trade-off tables, severity-tagged bullets, a `References` list of
`file:line — what it shows`. A described format drifts; a shown format reproduces.

**Failure modes.** Contrastive pairs only: `<name>: <bad>. Instead, <good>.` This teaches the
boundary far better than a list of prohibitions, because it pins the *correct* alternative right
next to the wrong one. Pull these from the agent's real, anticipated failure modes — overengineering,
scope creep, premature completion, armchair analysis, symptom-chasing, vague recommendations.

**Examples.** Concrete beats abstract every time. Use a real-looking file:line, a real command, a
real diff size. The Good shows the discipline; the Bad shows the trap with a one-line diagnosis of
why it's wrong.

## Writing style (applies throughout)

- **Second-person imperative.** "Use Read to…", "Never approve without…", "Stop when…". No
  first-person, no hedging.
- **Evidence spine.** For any analysis/review/debug agent, make "cite file:line / show fresh
  output / no claim without evidence" a load-bearing rule. "Findings without evidence are
  opinions, not findings."
- **Explain the why, don't pile on MUSTs.** If you're writing ALL-CAPS ALWAYS/NEVER everywhere,
  reframe as rationale. The model complies better with understood rules than shouted ones. Reserve
  emphasis for the one or two genuinely inviolable rules.
- **Stop condition.** State when the agent is done and should return — "Stop when the diagnosis is
  complete and every recommendation has a file:line reference." Open-ended agents ramble.
- **Effort, not just steps.** A short line on how hard to work — "thorough analysis with evidence"
  vs "match effort to task size" vs "fast and narrow" — calibrates the agent to its model tier.

## Choosing how many sections

- **Full advisor/reviewer/implementer** → all ten sections.
- **Narrow lookup/output agent** (search, doc-write) → Role + Process + Output Format + Failure
  Modes is often enough; Why/Examples/Checklist optional.
- Never drop **Role**, **Output Format**, or **Failure Modes** — those three are the
  non-negotiable backbone across the entire source fleet.
