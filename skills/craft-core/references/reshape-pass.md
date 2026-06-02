# Phase 3.5 — Convention reshape pass (forge / renew only)

After a `forge` or `renew` implementation is green (Phase 3 done) but **before**
the secure-verify gate (Phase 4), optionally align the just-written code to the
project's conventions — a focused, behavior-preserving cleanup pass.

**Applies to `forge` and `renew` only.** `hunt` skips this phase on purpose: a
bug fix must stay surgical, and folding convention churn into a fix diff buries
the actual change and widens the regression surface. `reshape` skips it too — the
whole skill already *is* a convention/structure pass, so a second one is
redundant.

This pass reuses `reshape`'s defining constraint — **zero observable behavior
change** — so it must obey the same proof discipline. It is structure-only.

## Gate — ask first, default off

This phase never runs silently. After Phase 3 is green, offer it once via
`AskUserQuestion`, roughly:

> "구현 끝났고 테스트 green. 이어서 코드 컨벤션 정렬 리팩터(behavior 불변)
> 돌릴까요? — 네이밍/구조/import/에러처리 축만, 테스트 계속 green 유지."

If the user declines, is silent, or there's nothing to align, **skip to Phase 4**
and say so in one line. Don't re-offer. A trivial change (1 file, a few lines)
where the code already matches convention should skip without even asking.

## Step 1 — Load the conventions (merge)

Read `convention-guide.md` and merge it with the project's own sources, **most
specific wins** (the precedence block in that file is the authority):

1. project lint/formatter config + `rules/*.md`
2. project `docs/guides/` convention page (if any)
3. the baseline in `convention-guide.md`

Run the project's formatter/linter first and trust it for everything mechanical —
this pass only touches the taste-level axes the linter can't enforce (naming,
function/file structure, import/dependency organization, error handling).

## Step 2 — Pin behavior (before touching structure)

The Phase 3 test suite **is** the behavior pin — it must be green going in. Where
the convention changes you intend to make touch code the existing tests don't
cover, add **characterization tests** (assert current observable behavior) for
exactly those paths first, and confirm they pass against the code as-is. No
structural edit happens until the paths it touches are pinned.

## Step 3 — Align in small steps, stay green

Apply the conventions in small, independent steps (one rename set, one
guard-clause flattening, one import regroup at a time). After **every** step, run
the suite. The rule is absolute:

- A test goes red → the step changed behavior → **revert that step and stop.**
  Convention alignment may never alter observable behavior. If a convention
  genuinely can't be applied without a behavior change, that's a `renew`
  decision, not a reshape — leave it, note it, move on.
- Tests stay green → keep the step, continue.

Scope is the Phase 3 diff and its immediate neighborhood only. Do **not** reshape
untouched code elsewhere in the repo — that's scope creep and a separate
`reshape` task (mention it, don't do it).

## Step 4 — Hand to Phase 4

When the diff matches convention and the full suite is green, proceed to Phase 4
secure-verify as normal. The security pass and verify gate run over the combined
(implementation + reshape) diff — there is no separate gate for this phase.

## Anti-patterns

- Running the pass without the user's go-ahead (it's opt-in, asked once).
- Letting a test change "to make it pass" — that's behavior drift, the one thing
  this pass forbids.
- Reshaping files the Phase 3 change never touched.
- Re-deciding mechanical style the project's formatter already owns.
- Applying it to a `hunt` fix or a `reshape` task.
