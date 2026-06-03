# Ambiguity Scoring — the gate that ends the interview

The interview is gated on a single number: **ambiguity**. You score a few
weighted dimensions each round, combine them, and stop when ambiguity crosses
the threshold. This file defines the dimensions, the formulas, and how to track
convergence honestly.

The score is not a measurement instrument pretending to physics-grade precision.
It's a *structured judgment* — a way to make "are we clear yet?" answerable and
directional instead of a vibe. Its two jobs: show the user a finish line, and
tell you which dimension to attack next. Score honestly; a number you don't
believe is worse than no number.

## The dimensions

Each dimension is scored **0.0 (no idea) to 1.0 (a stranger could verify it)**.

| Dimension | Question it answers | Fully clear (1.0) means |
|-----------|---------------------|--------------------------|
| **Goal** | What are we building, and why? | One sentence a stranger reads and knows what success looks like. |
| **Constraints** | What limits / assumptions / non-functionals bound it? | The real limits are named and pinned (perf, security, compat, deps, the worst inputs). |
| **Criteria** | How do we know it's done and working? | Acceptance criteria you could hand to a tester who never heard the discussion. |
| **Context** *(brownfield only)* | How does it meet the existing system? | Integration points, preserved behavior, and blast radius are identified from the code. |

Score each *active* component separately when the topology has more than one —
the weakest component's weakest dimension is your target.

## The formulas

Combine the dimensions into clarity, then ambiguity is its complement:

**Greenfield** (net-new, no existing system to integrate with):

```
clarity   = goal×0.40 + constraints×0.30 + criteria×0.30
ambiguity = 1 − clarity
```

**Brownfield** (touches an existing codebase):

```
clarity   = goal×0.35 + constraints×0.25 + criteria×0.25 + context×0.15
ambiguity = 1 − clarity
```

Goal carries the most weight because a wrong goal makes every other dimension
moot — perfectly specified constraints on the wrong target is wasted rigor.
Brownfield adds a context term and rebalances down the others, because in
existing code the integration surface is a first-class source of ambiguity.

### Worked example

Greenfield, round 3: goal 0.8, constraints 0.5, criteria 0.4.

```
clarity   = 0.8×0.40 + 0.5×0.30 + 0.4×0.30 = 0.32 + 0.15 + 0.12 = 0.59
ambiguity = 1 − 0.59 = 0.41  (41%)
```

Weakest dimension is **criteria** (0.4) → next question is type 3/5 to pin a
measurable "done". Threshold 0.20 not met → continue.

## The round report

Print this compact table each round so the trail is visible and resumable:

```
Round 3 · brownfield · component: ingest (active)
  goal 0.8 | constraints 0.5 | criteria 0.4 | context 0.7
  ambiguity: 41%  (target ≤ 20%)
  targeting → criteria (weakest): no measurable "done" yet
  [challenge: contrarian fires next round]
```

The sequence of these tables *is* the interview's state. If the session is
interrupted, the last table says exactly where to resume — no separate state
file is kept.

## Tracking convergence (rounds 2+)

A dropping ambiguity number is necessary but not sufficient — watch two things:

- **Entity stability.** Each round, note the core entities (nouns) the user
  introduces. From round 2, eyeball how much the entity set is *churning*: if new
  fundamental nouns keep appearing, the topology may be wrong (consider the
  ontologist challenge mode), even if dimension scores are creeping up. A stable
  entity set with rising scores is real convergence; a churning set with rising
  scores is false comfort.
- **Diminishing returns.** If two consecutive rounds each move ambiguity by less
  than ~2 points, you're either nearly done (cross the threshold and stop) or
  stuck on something the user can't resolve by talking (name it as a residual
  assumption in the spec and move on). Don't grind.

## Honesty rules for the score

- Score the dimension you'd defend to a skeptic, not the one that makes progress
  look good. A score that jumps 0.3 → 0.9 on a hand-wave is theater.
- It's fine for a score to *drop* between rounds — a good question often reveals
  that a dimension you thought was clear actually wasn't. That's the mechanism
  working, not a regression.
- Round numbers (0.2, 0.5, 0.8) are fine; the precision is in the *direction and
  ordering* of dimensions, not in a phony third decimal.
