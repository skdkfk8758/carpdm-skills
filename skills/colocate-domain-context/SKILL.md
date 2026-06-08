---
name: colocate-domain-context
description: >-
  Set up per-domain CLAUDE.md files colocated with code (auto-loaded by directory
  proximity) plus a co-update WARNING gate that flags when a domain's code changes
  without its CLAUDE.md being updated — so domain-specific gotchas live next to the
  code and stay in sync as the code evolves. Use whenever the user wants to keep
  domain/module knowledge next to the code, reduce AI wrong-guesses in specific
  subsystems, prevent documentation from going stale as code changes, or asks about
  "per-folder CLAUDE.md", "domain knowledge gate", "co-update gate", "colocate docs
  with code", "nested CLAUDE.md per module", or references Anthropic's skills /
  data-analytics staleness pattern (accuracy dropping when docs aren't co-updated).
  Korean triggers — "도메인별 CLAUDE.md 셋업", "코드 옆에 도메인 지식 두기", "문서
  노후화 막는 게이트", "폴더별 CLAUDE.md", "모듈 함정 문서 자동로드", "co-update
  게이트 만들어줘". Adapts to each project's structure and verification host
  (verify.sh / husky / pre-commit / CI / Makefile / none). Do NOT use for writing the
  root CLAUDE.md from scratch (use init), for general refactors (use renew), or for
  auto-GENERATING docs from code — this skill sets up human-maintained, gate-flagged
  colocated context, not a code-to-doc generator.
---

# colocate-domain-context

Set up a self-sustaining layer of **domain-scoped context that lives next to the
code and stays in sync with it**. Two coupled mechanisms:

1. **Per-domain `CLAUDE.md`** placed inside each domain/module folder. Claude Code
   loads these *by directory proximity* — when you read a file under that folder, its
   `CLAUDE.md` is pulled into context. Cheap (only loads what you touch), and it puts
   the domain's *gotchas* right where wrong guesses happen.
2. **A co-update warning gate** wired into the project's verification step. When a
   domain's code changes but its `CLAUDE.md` doesn't, the gate **warns** (it does not
   block). A human decides whether the domain knowledge actually changed.

## Why this exists (the motivating evidence)

Anthropic's internal data-analytics write-up reported that giving the agent
procedural "skills" took accuracy from ~21% to ~95%, but **without co-updating those
docs as code changed, accuracy decayed from ~95% to ~65% in a month**. Their fix was
not auto-generation — it was a CI hook that *flags* any code change whose paired doc
wasn't touched, so a human keeps them in sync. This skill ports that pattern to a
coding agent: colocated knowledge (input quality) + a co-update flag (anti-staleness).

Keep these principles in mind while applying the skill; they explain the design
choices and should shape your judgment when a project doesn't fit the default mold:

- **Warning, not auto-generation.** Hooks that rewrite docs from code are fragile
  (edit cycles, timeouts, parse failures) and Anthropic deliberately avoided them.
  The human is the one who knows whether a code change altered the *meaning*.
- **Warning, not blocking (at first).** Blocking before domains are documented spams
  false alarms and breeds gate-fatigue. Start as a warning; promote to blocking only
  after the warning's firing rate shows it's signal, not noise.
- **Thin + gotcha-first.** A domain `CLAUDE.md` is not a tutorial. It captures the
  few things that make an agent guess *wrong* here (a non-obvious coordinate system,
  a coercion seam, an auth quirk). Cross-cutting rules stay in the project's shared
  rules file — duplicating them rots faster and bloats every load.
- **Pilot first.** Co-update is a real ongoing cost (Anthropic saw ~90% of code PRs
  touch a doc). Prove the value on 2–3 high-gotcha domains before scaling to all.
- **Auto-discovered enrollment.** A domain is "enrolled" simply by *having* a
  `CLAUDE.md`. No hardcoded domain list to maintain; un-documented folders are never
  flagged (zero false positives by construction).

## The hard prerequisite: does proximity auto-load actually work here?

The whole pattern rests on Claude Code loading a deep nested `CLAUDE.md` when you
touch a sibling file. This is a documented feature
(https://code.claude.com/docs/en/memory.md — subdirectory CLAUDE.md files load when
Claude reads files in those subdirectories), but **verify it in the target project
before building on it** — depth, monorepo layout, and version can all matter. A
newly-created `CLAUDE.md` is indexed at session start, so a file created mid-session
may not load until a fresh session.

Read `references/auto-load-check.md` and run the check **first**. If it fails, route
to the fallback there (path-scoped `.claude/rules` with a `paths:` glob, or a
shallower CLAUDE.md closer to the root) instead of deep nesting — the co-update gate
still applies, only the colocation mechanism changes.

## Procedure

Work on a feature branch (never a protected branch). Don't mutate the repo until the
auto-load check passes and the user has seen the pilot plan.

### Phase 0 — Verify the premise
Run the auto-load check from `references/auto-load-check.md`. Gate everything on it.
PASS → continue. FAIL → switch to the fallback colocation mechanism, then continue.

### Phase 1 — Map the project
Discover three things, by reading the repo (not guessing):
- **Domain roots** — the directories whose immediate children are domains/modules
  (e.g. `apps/api/src/modules`, `apps/web/src/components`, `src/features`, `pkg/`).
  These become the gate's roots.
- **Verification host** — where a co-update check can hang: a `verify.sh`-style
  script, `.husky/`, `.pre-commit-config.yaml`, `.github/workflows/`, a `Makefile`
  target, or none. Read `references/verify-hosts.md` for how to wire each.
- **Shared-rules home** — where cross-cutting rules already live (a root `CLAUDE.md`,
  `rules/`, `AGENTS.md`). Domain files must *defer* to these, not duplicate them.

Report the map to the user before writing anything.

### Phase 2 — Pick the pilot (2–3 domains)
Choose the domains where wrong guesses are most likely and most costly: complex
algorithms, non-standard coordinate/units/currency, auth/permission boundaries, data
coercion seams, anything with a documented history of bugs. Spanning both back-end
and front-end (if applicable) exercises both gate branches. Name them and why.

### Phase 3 — Write thin domain CLAUDE.md
For each pilot domain, mine **real** gotchas from the code (open the files; cite
actual symbols/paths — never invent). Use this shape, kept short (≈20–35 lines):

```markdown
# <domain> domain

## Entry points
- <key controller/service/repo/component : one-line role>

## Contracts
- <endpoints / DTO / coordinate system / state invariants + the ADR/source that fixes them>

## Gotchas   ← only what makes an agent guess WRONG here
- <verified gotcha + the symptom when violated>

## Cross-layer
- <FE component ↔ store ↔ BE module ↔ repository links>

> co-update: changing this domain's logic means updating this file in the same change
> (co-update gate flags otherwise).
```

Cross-cutting rules (shared coercion helpers, global coordinate policy, adapter
boundaries) stay in the shared-rules home — link to them, don't copy.

### Phase 4 — Wire the co-update gate
Use the bundled `scripts/coupdate-check.sh` — it auto-discovers enrolled domains
(folders with a `CLAUDE.md`) under the roots you pass, diffs them against the change
set, and warns on drift. Copy it into the project (e.g. `scripts/` or `.claude/`) and
hook it into the verification host per `references/verify-hosts.md`. Default to
warning-only (`exit 0`); `--strict` makes it blocking once the user opts in.

Verify the gate behaves before declaring done — drive the three cases:
1. domain code changed, its `CLAUDE.md` not → **warns**
2. both changed → silent
3. a non-enrolled domain changed → silent (no false positive)

### Phase 5 — Record & hand off
Optionally write a short ADR capturing the decision (warning-only, which-mechanism,
pilot scope, Claude-only vs mirrored to other agents). Tell the user the resulting
discipline plainly: which domains are enrolled, that the gate warns (doesn't block),
that they update a domain `CLAUDE.md` in the same change *only when the domain
knowledge actually changed*, and that expansion to more domains should wait until the
pilot proves out.

## Scope discipline

- **Claude-only by default.** Nested `CLAUDE.md` is read by Claude Code, not by other
  agents (Codex/Cursor read a root `AGENTS.md`). Mirroring domain files into a built
  `AGENTS.md` adds drift-gate complexity — only do it if the user needs cross-agent
  visibility, and say so.
- **Don't auto-generate.** If the user asks for a hook that rewrites domain docs from
  code on every edit, push back: it's the fragile path Anthropic avoided. Offer the
  warning gate instead.
- **Don't scale past the pilot unprompted.** Documenting every domain at once
  manufactures thin/rote files and a maintenance tax with unproven payoff.

## Bundled resources

- `scripts/coupdate-check.sh` — portable, project-agnostic co-update warning gate.
- `references/auto-load-check.md` — Phase 0 verification method + fallback mechanisms.
- `references/verify-hosts.md` — how to wire the gate into verify.sh / husky /
  pre-commit / GitHub Actions / Makefile / a fresh git hook.
