# Phase 0 — Verify proximity auto-load (and fallbacks)

The colocation half of this skill only pays off if Claude Code actually loads a
deep nested `CLAUDE.md` when you touch a sibling file. Confirm it in the *target*
project before building on it. Do not skip this — a silent failure here makes every
domain `CLAUDE.md` dead weight.

## What the mechanism is

Claude Code walks up the directory tree from files it reads and loads any `CLAUDE.md`
it finds. The root one loads at session start; **subdirectory ones load lazily, when
a file under that directory is read** (documented at
https://code.claude.com/docs/en/memory.md). Two consequences that bite:

- **Depth/layout can vary.** A `CLAUDE.md` 4–5 levels down, or in a monorepo package,
  may behave differently than the docs imply for a given version. Test, don't assume.
- **Mid-session creation is not hot-reloaded.** Indexing happens at session start. A
  `CLAUDE.md` you just created will typically NOT load when you read a sibling file in
  the *same* session — only after the file is committed/present and a **fresh session**
  starts. (This is the single most common false-negative when testing.)

## The check

1. Create a probe file at a representative deep domain dir, e.g.
   `<domain-root>/<some-domain>/CLAUDE.md`, containing a unique marker line such as
   `PROBE-MARKER-7F3A: proximity auto-load works`.
2. **Commit it** (so it's present at session start) on your feature branch.
3. Start a **fresh** Claude Code session in the project.
4. Read a sibling source file in that same domain dir.
5. Run `/memory` (or inspect whether the marker appears in loaded context). If the
   probe `CLAUDE.md` is listed as loaded → **PASS**. If not → **FAIL**.
6. Remove the probe (or convert it into the first real domain file).

If you cannot drive a fresh session yourself, hand steps 3–5 to the user as a one-time
manual check and gate expansion on their result. It is legitimate to author the first
real pilot domain file and have the user confirm load on their next session — just
don't scale to many domains until the check passes.

## If it FAILS — fallback mechanisms

The co-update gate is unaffected (it keys on `CLAUDE.md` presence regardless of how
that file reaches context). Only swap the *colocation* mechanism:

- **Path-scoped rules.** Put domain guidance in `.claude/rules/<domain>.md` with a
  `paths:` glob in frontmatter matching that domain's files. These load when matching
  files are touched, without relying on deep nesting. Point the gate at these files
  instead (adjust the discovery path).
- **Shallower CLAUDE.md.** Place one `CLAUDE.md` closer to the root (e.g. at the
  domain-root level) that aggregates short per-domain sections. Loses per-folder
  precision but is reliably loaded.
- **Explicit @-import.** From the root `CLAUDE.md`, `@import` a domain notes file.
  Heaviest (loads at every session start, always in context) — use sparingly, only
  for a domain touched in almost every session.

Pick the lightest fallback that actually loads in the target project, then proceed
with Phases 1–5 using that mechanism.
