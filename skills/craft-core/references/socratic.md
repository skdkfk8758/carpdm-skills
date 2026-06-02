# Socratic Questioning — turning a vague ask into a testable spec

Goal: extract the spec from the user's head, not impose one. You ask, they
answer, the answers become the plan. Stop when you could write acceptance
criteria a stranger could verify — not before, not long after.

## How to run it

- Ask in **small focused clusters** (2–4 questions), not a 20-question wall.
  Each cluster should target the single biggest current unknown.
- When the choice is between a few concrete options, use the `AskUserQuestion`
  tool so the user picks instead of typing prose.
- Probe assumptions out loud: when the user states something as fact, reflect it
  back — "this assumes X holds; if it doesn't, the design changes to Y."
- Verify against the code, not memory — read first (see "Read before you ask"
  below). If a question is answerable by the code or an existing doc (does this
  endpoint exist? what's the current return type? did an ADR already settle this?),
  answer it yourself before asking the user.
- Stop condition: you can fill every Phase-1 plan section. More questioning past
  that point is friction, not rigor. For non-trivial tasks, run the completeness
  sweep below before you declare the spec done.

## Read before you ask (ground the questions)

A generic question ("what should happen on bad input?") gets a generic answer. A
*grounded* question ("`getPlan` currently returns `None` on a missing id and
`report.summarize` maps that to `[]` — keep that, or raise now?") gets a decision.
The difference is that you read first. Before the Socratic clusters, scope-read
the area the task touches:

- **Code** — use the project's code intelligence if it has any: a code-graph MCP
  (`semantic_search_nodes`, `query_graph` for callers/callees, `get_impact_radius`)
  or LSP, which give you callers and blast radius cheaply. Fall back to Read/Grep
  when there's none. Scope it to what the task touches via the impact radius —
  don't read the whole repo.
- **Decisions, context & guides** — read the relevant existing ADRs and concept
  pages so you don't re-litigate what's settled, and check `docs/guides/` /
  `docs/reference/` for a documented procedure or contract this task should follow
  (see `context-adr.md`). Code tells you *what is*; ADRs/concepts tell you *why*;
  guides/reference tell you *how it's meant to be done*.

Then anchor each question to what you found. This is the single biggest lever for
finishing in one pass: most rework comes from a wrong assumption about existing
code or a forgotten prior decision, and reading first kills both before any
question is asked.

## The six question types (cover the gaps, don't recite them all)

1. **Clarification** — "What exactly do you mean by X?" "Can you give a concrete
   example of the input and the output you want?"
2. **Probing assumptions** — "What are you assuming about the data / the caller /
   the environment here?" "Does that always hold?"
3. **Probing reasons & evidence** — "What makes you think that's the cause?"
   "Is there a failing case or log that shows this?"
4. **Alternative viewpoints** — "Is there a simpler approach that avoids this
   entirely?" "Who else calls this — will they break?"
5. **Implications & consequences** — "If we change this, what downstream
   contract moves?" "What's the worst input this now has to survive?"
6. **Question the question** — "What's the real goal behind this request?" "If we
   solved the underlying need a different way, would this task still matter?"

## Task-type emphasis (the calling skill sets this)

- **forge** → types 1 & 5: nail the IO contract and the success metric for
  something that doesn't exist yet.
- **renew** → types 2, 4 & 5: surface what current behavior must be preserved vs
  changed, who depends on it, and the worst-case/edge inputs the change must
  survive.
- **reshape** → types 2 & 5: pin the invariant that must NOT change observably,
  and the blast radius.
- **hunt** → types 1, 3 & 5: get an exact reproduction and evidence-backed root
  cause, plus the blast radius / edge inputs the fix must not break.

## Before you stop — completeness sweep (non-trivial tasks)

"Testable" is not the same as "complete": a spec can read cleanly and still omit
the edge case that forces a rework round mid-build. The ultimate goal is to finish
the work in one pass, so before declaring the spec done on any non-trivial task
(roughly 3+ files, or anything with real failure modes), run ONE final cluster —
surface what the user hasn't said but the implementation will hit:

- **Edge & failure inputs** — the worst, emptiest, largest, or most concurrent
  input this must survive, and what it does on failure (raise? default? retry?).
- **Non-functional constraints** — only the ones this task plausibly touches:
  performance/scale, security, backward-compatibility, error/log behavior.
- **Explicit out-of-scope** — name what this will NOT do, and confirm it with the
  user, so scope creep can't reopen it later.

Pin each answer *precisely*, not just directionally — the precision is part of the
contract, and a half-pinned answer still leaves a finding for Phase 2. When an
answer implies a contract decision, write the exact form:

- the exact exception, not "raises an error" — name it, `ValueError` vs
  `TypeError`, and which input triggers which.
- the exact constant, not "a cap (e.g. 1000)" — the literal number that lands in
  the code.
- the exact return type/shape, not "a list" when the input could change it —
  e.g. "always a new `list`", not "a slice of the input".

This is recording discipline, not extra questions: most of these are yours to
decide and write down, not the user's to answer. The dimension is what you ask;
the precision is what you pin. A sweep that names the dimensions but leaves
"TypeError/ValueError" or "e.g. 1000" loose still draws blocking findings in
review — the gap was precision, not coverage.

Why this earns its place: an unspecified edge surfaces in Phase 2 as a codex
"this is unspecified" finding — but codex cannot ask the user, so it forces
another round or a guess. Asking here closes that gap up front, which is exactly
what one-pass success needs. Keep it to one cluster (2–4 questions); skip it for
genuinely trivial (T1, 1–2 file) work where it would only add friction.

## Anti-patterns

- Dumping every question at once → the user disengages and answers shallowly.
- Asking what the code already answers → looks like you didn't look.
- Accepting "make it better / handle errors / clean it up" as a spec → these are
  not testable; push until they are.
- Questioning forever → once the spec is testable, move to the plan.
