# Detection heuristics

Per-category rules for finding cleanup candidates. Each hit must carry **evidence
of staleness**, not just a matching path. Run `git ls-files` and `git status` once
up front so every hit gets a recovery tier (tracked / untracked).

Table of contents:
- [1. Stale point-in-time docs](#1-stale-point-in-time-docs)
- [2. Volatile logs](#2-volatile-logs)
- [3. Orphan / duplicate docs](#3-orphan--duplicate-docs)
- [4. Build / tmp leftovers](#4-build--tmp-leftovers)
- [Cross-cutting: never-touch guard](#cross-cutting-never-touch-guard)

## 1. Stale point-in-time docs

Locations: `docs/plans/`, `docs/handoff/`, `docs/reports/`, `docs/reviews/`,
`docs/runbooks/`, `docs/benchmarks/`, `docs/solutions/`, `docs/_archive/`.

Staleness evidence (need at least one; more = higher confidence):

- **Dated filename in the past** — `docs/plans/YYYY-MM-DD-*.md` where the date is
  well behind today. A plan older than the most recent plan on the same topic is
  likely superseded.
- **Landed work** — a `handoff/` or `plans/` doc whose described task is done.
  Check: does its target file/feature exist and look finished? Is there a later
  commit that says it merged? Per the YAGNI rule, a handoff whose work shipped is
  meant to be deleted.
- **Superseded** — two docs on the same topic; the older is a candidate, the newer
  stays. Confirm by reading both, not by date alone.
- **Already archived** — anything under `docs/_archive/` is by definition retired;
  propose it (tracked → recoverable) unless the user uses `_archive` as long-term
  cold storage (ask if unclear).

Useful commands (read evidence, don't act):
```bash
git -C <repo> log --oneline -5 -- docs/plans/<file>      # was its work merged?
git ls-files docs/plans docs/handoff docs/reports        # tracked candidates
ls -lt docs/handoff                                       # oldest-last by mtime
```

Do NOT treat as stale: an active SPEC (`docs/specs/`), a plan with a future date or
open checkboxes, a report referenced from `docs/_index/index.md`.

## 2. Volatile logs

Locations: `logs/` (esp. `logs/qa/`, `logs/agents/`), `*.status.log`.

- `logs/qa/` has a **7-day GC window** by convention — files older than 7 days are
  prime candidates.
- `logs/agents/*.log`, `*.status.log` — agent run scratch, almost always volatile.
- These are usually **untracked → NOT recoverable**. Flag that tier loudly.
- If `logs/` should keep emitting, prefer ensuring it is `.gitignore`d over deleting
  the directory itself — deleting it just makes the next run recreate it.

```bash
find logs -type f -mtime +7 2>/dev/null     # older than 7 days
git check-ignore logs/qa/ || echo "logs/qa NOT gitignored"
```

## 3. Orphan / duplicate docs

- **Orphans** — docs under `docs/` not reachable from `docs/_index/index.md` (the
  portal). Grep the portal for the filename; zero hits + point-in-time location =
  orphan candidate. Knowledge sub-tree files missing from the portal are a *portal
  gap to fix*, not a delete candidate — flag, don't propose.
- **Duplicates** — two files with near-identical content / same SSOT. The convention
  forbids duplicate SSOT; keep the canonical one, propose the copy.
- **Empty dirs** — directories with no files (often left after earlier moves).

```bash
grep -rl "<filename>" docs/_index/ || echo "orphan: not in portal"
find docs -type d -empty
```

## 4. Build / tmp leftovers

- `*.bak-*` (the timestamped backups `install.sh` and similar make), `*.tmp`,
  `*.orig`, `*~`.
- Build output: `dist/`, `build/`, `out/`, `.next/`, `coverage/` — but ONLY if the
  project clearly regenerates them (a build step exists). For a docs-only or
  markdown repo, a `build/` dir might be meaningful — check before assuming.
- `tmp/`, `.cache/` scratch.
- These are typically **untracked → NOT recoverable**.

**Recent-backup caution.** A `.bak` / `.orig` with a *recent* mtime (or a name that
is not an epoch-timestamped tool backup, e.g. `config.json.bak-recent` vs
`config.json.bak-1748000000`) may be one the user just made on purpose. Deleting an
untracked, non-recoverable file someone created minutes ago is exactly the
irreversible mistake to avoid. Do NOT fold it into the auto-proposed batch — move it
to "Excluded on purpose" and offer it as an explicit opt-in, noting it looks
intentional. Stale tool backups (old mtime + epoch-timestamp name) stay normal
candidates.

```bash
find . -name '*.bak-*' -o -name '*.tmp' -o -name '*.orig' 2>/dev/null
find . -name '*.bak*' -mtime -1 2>/dev/null      # made in last day → caution, likely intentional
git status --porcelain --ignored | grep '^!!'    # ignored build/tmp output
```

## Cross-cutting: never-touch guard

Before proposing ANY path, re-check it is not in the permanent set:

`rules/`, `AGENTS.md`, `CLAUDE.md`, `MEMORY.md`, `memory/`, `.git/`, `docs/adr/`,
`docs/concepts/`, `docs/guides/`, `docs/reference/`, `docs/_index/`, `docs/specs/`
(active contracts), source code, `package.json`, lockfiles, CI config, `.claude/`.

A single mis-proposed permanent file erodes all trust in the tool. When a path sits
on the boundary (is this `report` actually durable reference?), move it to the
"Excluded on purpose" list with your reasoning and let the user pull it back in —
err toward keeping.
