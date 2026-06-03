# Socratic Playbook — the six question types, in depth

The interview runs on one instrument: the six classic Socratic question types.
This file is the depth behind the table in `SKILL.md` — example banks per type,
how to pick the right type for the weakest dimension, and the three challenge
modes that layer on top.

The point of naming the type to yourself each round is discipline. Under time
pressure it's easy to slide from *asking* into *suggesting* ("should we just use
a queue here?") — that's not Socratic, it's you writing the spec and getting a
rubber stamp. Keeping each question inside one of the six types forces the user
to do the thinking, which is the only way the spec ends up being *theirs* and
therefore correct.

## Table of contents

- The six types — when to use, example bank
- Selecting a type from the weakest dimension
- Challenge modes (contrarian / simplifier / ontologist)
- Grounding brownfield questions in code
- Keeping it one question at a time

## The six types

### 1. Clarification — make the vague concrete

Use when a noun or verb in the idea is doing too much work ("a dashboard", "sync
it", "handle errors"). The cure is a concrete example: one real input, one
desired output.

- "When you say *dashboard*, walk me through one screen — what's the first thing
  a user sees, and what data is on it?"
- "Give me one concrete row of input and exactly what you'd want out of it."
- "*Sync* how often, in which direction, and what wins on a conflict?"
- "Name the single most important thing this must do. If it did only that, would
  it be worth building?"

### 2. Probing assumptions — surface the unstated premise

Use when the user states something as settled fact. Reflect it back as an
assumption and test whether it holds.

- "You're assuming the input is always valid UTF-8 — is it? What arrives if it
  isn't?"
- "That presumes one user at a time. Does it ever run concurrently?"
- "We're treating the upstream API as reliable. What's the plan when it's down?"
- "What has to be true about the data for this design to work — and is it?"

### 3. Probing reasons & evidence — demand the backing

Use when a claim or a success metric is asserted without support. This is where
acceptance criteria get pinned.

- "What makes you confident users want this? Is there a case or a complaint that
  already shows it?"
- "How will we *know* it worked — what's the measurable signal?"
- "You said it's slow today. Slow how — a number, a log, a reproduction?"
- "If it shipped and did nothing, what would you observe that's different now?"

### 4. Alternative viewpoints — break tunnel vision

Use when the user has locked onto one approach, or when the design is getting
heavy. Invite a competing path or a dissenting stakeholder.

- "Is there a simpler approach that avoids this whole component?"
- "Who else touches this — would any of them break or object?"
- "If you had a tenth of the time, what would you cut and would it still work?"
- "What's the strongest argument *against* doing it this way?"

### 5. Implications & consequences — follow it downstream

Use to surface edge cases, blast radius, and the worst-case inputs the thing
must survive. This is the dimension most often left vague and most expensive to
discover late.

- "If we change that return type, what downstream caller has to move with it?"
- "What's the worst, emptiest, largest, or most concurrent input this now has to
  survive — and what does it do on failure: raise, default, or retry?"
- "Ship this and double the traffic — what's the first thing that breaks?"
- "What does this make *impossible* later that's fine today?"

### 6. Question the question — check you're solving the right problem

Use when the request might be a solution in search of the real need. The highest-
leverage type: it can collapse the whole topology.

- "What's the underlying goal this is in service of?"
- "If we solved that need a completely different way, would this task still
  matter?"
- "Why this, and why now — what changes for you when it exists?"
- "Is this the actual problem, or a workaround for one upstream of it?"

## Selecting a type from the weakest dimension

Each round you target the weakest dimension (see `scoring.md`). Map it to types:

| Weakest dimension | Reach for | Why |
|-------------------|-----------|-----|
| **Goal** (what & why is fuzzy) | 1 Clarification, 6 Question-the-question | Concretize the target or check it's the right one. |
| **Constraints** (limits/assumptions loose) | 2 Probing assumptions, 5 Implications | Expose unstated premises and downstream limits. |
| **Criteria** (no measurable "done") | 3 Reasons/evidence, 5 Implications | Force a verifiable signal and its edge behavior. |
| **Context** (brownfield: integration unclear) | 1 Clarification, 2 Probing assumptions | Pin how it meets the existing system; ground in code. |

This is a starting heuristic, not a rule. If a different type obviously fits the
moment, use it — the goal is to move the weakest dimension, not to obey a table.

## Challenge modes — perspective shifts at depth

When ambiguity stalls, the blocker is usually a wrong assumption, not a missing
fact. Fire each mode once, at its round threshold. They don't replace the six
types — they're a *stance* you adopt while still asking one typed question.

- **Round 4+ — Contrarian.** Pick the load-bearing assumption and attack it
  directly (uses type 2/4). Opener: *"Let me push on the core idea — you're
  assuming [X]. I think there's a real case where that's false: [case]. How do
  we handle it, or am I wrong?"* The aim isn't to win; it's to find out whether
  the assumption survives contact.
- **Round 6+ — Simplifier.** Probe whether the accumulating complexity is
  earning its keep (type 4/5). Opener: *"We've added [components/cases]. If we
  cut [the heaviest one], what specifically fails? Could a dumber version ship
  first?"*
- **Round 8+ — Ontologist.** If it's still murky this deep, the framing is
  probably wrong. Reframe around the core *entities* and their relationships
  (type 1/6). Opener: *"Let's reset to the nouns. The real things here seem to be
  [A, B, C]. What's the relationship between them, and which one is the spec
  actually about?"* A late ontology shift often dissolves ambiguity that no
  amount of detail questioning could.

Each mode fires once per interview. Note in the round report when one activates,
so the trail shows why the questioning shifted.

## Grounding brownfield questions in code

A generic question gets a generic answer. Before asking the user about anything
the code already knows, read it (scoped to the impact radius) and put the fact in
the question:

- Generic: "What should happen on a missing record?"
- Grounded: "`getPlan` returns `None` on a missing id today, and `summarize`
  maps that to `[]`. Keep that, or raise now?"

The grounded version converts the question from "explain your system to me" into
"make the one decision I can't make for you" — faster, and it signals you did the
reading. Code tells you *what is*; the user tells you *what should be*.

## Keeping it one question at a time

The single most important mechanic. Batching ("also, what about auth, and
scale, and the schema?") lets the user spray shallow answers across everything
and think hard about nothing. One sharp question on the current bottleneck makes
them stop and actually reason. If you genuinely need two facts to score a
dimension, ask the more load-bearing one first and let the answer reshape the
second — it often makes the second moot.
