# Requirements Spec Template — what the interview crystallizes into

When ambiguity crosses the threshold (or a cap forces a stop), write the spec in
this structure. It is a **system requirements document**: a stranger — or a build
pipeline — picks it up cold, implements against the numbered requirements, and
verifies each one without having seen the interview.

Every requirement gets a **stable ID** (`REQ-F-NNN` functional, `REQ-N-NNN`
non-functional). IDs are the unit of traceability: the clarity trail maps back to
them, acceptance hangs off them, and a builder can check them off one by one. Once
an ID is assigned, never renumber it — append new ones instead, so references in
code, commits, or downstream specs never go stale.

Fill every section; if one is genuinely empty, write `None` rather than deleting
it, so a reader knows it was considered, not forgotten.

## Path & naming

Save where the project keeps specs if there's an obvious home — `docs/specs/` in
a repo that uses that layout. If the repo uses a directory-per-spec convention
(`docs/specs/<slug>/spec.md`), follow it. Otherwise propose a path and let the
user confirm before writing. Name from a slug of the goal, e.g.
`docs/specs/<slug>.md` or `docs/specs/<slug>/spec.md`.

## Template

```markdown
# Requirements: <one-line title>

> Crystallized from a deep-interview on <date>. Final ambiguity: <N>% (target ≤ <T>%).
> Type: <greenfield | brownfield>. Rounds: <count>. Status: <draft | approved>.

## 1. Goal & scope

<One or two sentences: what the system is for and why. State the underlying need,
not just the feature — a stranger reads this and knows what success looks like.>

**In scope:** <the components / capabilities this spec covers>
**Out of scope:** <what this explicitly will NOT do, confirmed with the user, so
scope creep can't reopen it. `None` if nothing was excluded.>

## 2. Topology

The pieces this breaks into (locked in Round 0):

| Component | Status | One-line role |
|-----------|--------|---------------|
| <name>    | active | <what it does> |
| <name>    | deferred | <why out of scope for now> |

## 3. Functional requirements

What the system must *do*. One row per requirement; keep each atomic (one
testable behavior) so it can pass or fail on its own.

| ID | Requirement (the system SHALL…) | Priority | Acceptance criteria | Origin |
|----|----------------------------------|----------|---------------------|--------|
| REQ-F-001 | <single testable behavior, with exact values/shapes — not "handle errors"> | Must | <how a tester who never saw the interview verifies it: exact input → exact output/exception> | R<n> |
| REQ-F-002 | … | Should | … | R<n> |

Priority is MoSCoW: **Must** / **Should** / **Could** / **Won't (this round)**.
Origin is the interview round that pinned it — that's the traceability link.

## 4. Non-functional requirements

How well it must do it — only the dimensions this system plausibly touches. Skip
the ones that don't apply rather than padding with boilerplate.

| ID | Category | Requirement | Acceptance criteria | Origin |
|----|----------|-------------|---------------------|--------|
| REQ-N-001 | Performance | <e.g. p95 latency < 200ms at 100 rps> | <how it's measured> | R<n> |
| REQ-N-002 | Security | <e.g. input X is validated against Y before persistence> | <how it's verified> | R<n> |
| REQ-N-003 | Compatibility | <e.g. existing callers of Z keep current return shape> | <how it's verified> | R<n> |

Common categories: Performance/scale, Security, Compatibility/migration,
Reliability/error behavior, Observability, Accessibility.

## 5. Constraints & assumptions

- **Constraints:** <hard limits the design must respect — tech stack, deps,
  budget, deadlines, data residency.>
- **Assumptions resolved:** <each premise surfaced in the interview and how it
  was settled — "input is always valid UTF-8: confirmed" / "single-user: assumed,
  not guaranteed — see REQ-N-00x risk".>
- **Residual ambiguity:** <anything still vague at stop time, the requirement(s)
  it affects, and the risk. `None` if fully clear.>

## 6. Context *(brownfield only)*

<Integration points, behavior that must be preserved, blast radius — grounded in
the actual code read during the interview, with file/symbol references. Tie each
to the REQ it constrains.>

## 7. Traceability — clarity trail

| Round | Ambiguity | Targeted dimension | Requirements pinned |
|-------|-----------|--------------------|---------------------|
| 0 | — | topology lock | <components> |
| 1 | <N>% | <dim> | REQ-F-001 |
| … | | | |

## 8. Handoff

Recommended next skill: <`/forge` (new) | `/renew` (change) | `/reshape` (refactor)
| `/hunt` (bug) | implementation plan | carry elsewhere>, chosen from the nature
of the work above.

**Treat this spec as the completed requirements step.** The recommended skill runs
its own Socratic interview by default — skip it. Feed these numbered requirements
in as the pinned Phase-1 output and proceed straight to plan review, so the work
isn't re-interviewed from scratch.
```

## Filling it well

- **Pin precisely, not directionally.** "REQ-F-003: raises `ValueError` on a
  negative amount" beats "validates input". "REQ-N-001: caps at 1000 items" beats
  "has a limit". The precision *is* the contract — a half-pinned requirement
  leaves a gap a builder fills with a guess.
- **One behavior per requirement.** If a row needs an "and" joining two testable
  behaviors, split it into two IDs. Atomic requirements pass/fail cleanly; compound
  ones hide a half-failure.
- **Acceptance is mandatory, per requirement.** A requirement with no acceptance
  criterion isn't a requirement, it's a wish — a builder can't prove it's done.
- **Carry residual ambiguity forward honestly.** If you stopped at a cap with
  something still vague, say so and name the affected REQ. A spec that hides its
  own gaps turns them into production surprises; a named gap gets handled.
- **Traceability earns its place.** The Origin column + clarity trail let a
  reviewer see *which* question pinned *which* requirement, and spot any REQ that
  was waved through without a real answer.
