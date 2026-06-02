# Convention Guide — the baseline reshape pass aligns to

This is the **shared baseline** the Phase 3.5 convention reshape pass
(`reshape-pass.md`) aligns code to, after a `forge` or `renew` implementation is
green. It deliberately covers only what a linter and the global rules do **not**:

- A linter/formatter already owns mechanical style (indentation, quotes,
  semicolons, trailing commas, line width). The pass does **not** re-decide those
  — it runs the project's formatter and trusts it.
- The global rules already own size/dead-code discipline (karpathy simplicity,
  YAGNI, the 300-line source-file ceiling). The pass does **not** restate them.

What remains are taste-level structural rules a formatter can't enforce. Those
are below, on four axes.

## Precedence (merge order)

The pass merges three sources, **most specific wins**:

1. **Project lint/formatter + `rules/`** — eslint / prettier / ruff / project
   `rules/*.md`. Highest authority for anything they cover.
2. **Project `docs/guides/` convention page** — if the project has one (e.g.
   `docs/guides/conventions.md`), it overrides this baseline for its project.
3. **This baseline** — the fallback when neither above speaks to a question.

If a baseline rule below contradicts the project's linter or guide, the project
wins and the baseline rule is dropped for that project. Never reformat against
this file in a way that the project's own formatter would immediately undo.

## Axis 1 — Naming

- Functions start with a verb: `fetchUser`, `buildPlan` — not `userFetch`,
  `planBuilder` (a function is an action).
- Booleans (and boolean-returning functions) carry an `is` / `has` / `should`
  prefix: `isReady`, `hasAccess`, `shouldRetry`.
- No cryptic abbreviations: `config` not `cfg`, `request` not `req` (loop
  indices `i`/`j` and idiomatic local `e`/`err` are fine).
- A name describes the domain meaning, not the type (`users`, not `userArray`).

## Axis 2 — Function / file structure

- **Guard-clause / early-return** over nested `if`. Handle the exceptional case
  and return; keep the happy path at the top indentation level.
- One function, one responsibility. If you must use "and" to describe what it
  does, it is two functions.
- Public-before-private export order: the file's exported surface reads top-down
  before its helpers.
- A file mixing unrelated concerns gets split along the concern boundary — but
  only when there's a real second concern, not on a line count alone (size is the
  global rule's job).

## Axis 3 — Import / dependency organization

- Import groups separated by a blank line, in order: **external → internal
  (absolute) → relative**.
- Respect layer direction: a lower layer must not import from a higher one
  (e.g. domain must not import from UI). A reverse import is a structural smell —
  flag it; do not "fix" it by moving behavior in a way that changes it (that's a
  `renew`, not a reshape).

## Axis 4 — Error handling

- Error messages state **what failed and why**, in the library's own vocabulary:
  `"parseConfig: missing required key 'port'"`, not `"error"` or `"invalid"`.
- No empty `catch`. Either handle, rethrow with context, or let it propagate —
  swallowing an error silently is never the convention.
- Handle only errors that can actually occur on this path (aligns with karpathy
  simplicity — no defensive handling for impossible states).
- Keep one error model per module: don't mix `throw` and result-type returns for
  the same kind of failure within a module. Match whatever the surrounding module
  already does rather than introducing a second style.
