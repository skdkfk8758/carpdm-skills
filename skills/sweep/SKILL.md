---
name: sweep
description: Clean up accumulated project cruft — stale point-in-time docs (old plans, landed handoffs, superseded reports), volatile logs (logs/qa, agent logs), orphaned/duplicate docs, and build/tmp leftovers — through a scan → classify → propose → confirm → delete pipeline with git history as the safety net. Use when the user explicitly asks to clean up, tidy, prune, sweep, or clear out leftover docs/logs/artifacts that pile up after working through forge/hunt/renew/reshape — phrasings like "레거시 문서 정리해줘", "쌓인 로그/플랜 치워줘", "docs 청소해줘", "오래된 리포트 정리", "clean up old reports", "prune stale handoffs", "이 프로젝트 잡동사니 좀 치워줘". It preserves the permanent knowledge sub-tree (adr / concepts / guides / reference), all rules and code, and anything still referenced. Do NOT trigger for general file deletion outside the project doc/log convention, for restructuring code (use reshape), or for writing a handoff (use handoff).
---

# Sweep — clear project cruft without losing anything that matters

A project that runs through `forge` / `hunt` / `renew` / `reshape` accretes
*point-in-time artifacts*: plans that already landed, handoffs whose work shipped,
agent logs, `.bak` files, superseded reports. They pile up, blur `grep`, and make
the repo read as if half of it is still in flight. Sweep removes that layer —
and **only** that layer.

The hard part is not deleting; it is knowing what is safe to delete. The
`knowledge-folders` convention already draws that line for you, and sweep is built
on top of it: **permanent knowledge stays, point-in-time artifacts are candidates.**
Your job is to apply that boundary carefully, explain every removal, and never
take an irreversible action the user did not approve.

## The safety boundary — read before scanning

The convention splits `docs/` into two sub-trees. Sweep treats them oppositely.

| Tier | Paths | Sweep stance |
|---|---|---|
| **NEVER touch** | `rules/`, `AGENTS.md`, `CLAUDE.md`, `MEMORY.md`, `memory/`, `.git/`, source code, config, `docs/adr/`, `docs/concepts/`, `docs/guides/`, `docs/reference/`, `docs/_index/` | Permanent knowledge + decisions + portal. Out of scope, full stop. |
| **Candidate** | `docs/plans/`, `docs/handoff/`, `docs/reports/`, `docs/reviews/`, `docs/runbooks/`, `docs/benchmarks/`, `docs/solutions/`, `docs/_archive/`, `logs/`, `*.bak-*`, `dist/`, `build/`, `tmp/`, `*.tmp`, empty dirs | Point-in-time / volatile. Eligible — but each still needs a *reason* before it goes. |

A path being a candidate is **necessary, not sufficient**. A plan from this morning
is still a candidate location but obviously alive. You delete on *evidence of
staleness*, not on folder alone.

If a project does not follow `knowledge-folders` (no `docs/` tree), fall back to
the same principle: source, config, READMEs, and anything git-tracked-and-imported
is permanent; logs, `.bak`, `tmp`, and build output are candidates. When unsure
whether something is knowledge or artifact, **ask — do not guess and delete.**

## The recovery tier — this drives how careful you are

Two candidate files can carry very different risk:

- **git-tracked** → `git rm` is recoverable from history. Safe to propose deletion.
- **untracked** (most logs, `tmp`, fresh `.bak`) → once `rm`'d it is **gone**, no
  git safety net. Treat with extra care: prefer `gitignore`-and-leave, or require
  an explicit per-item confirmation, and say plainly "this cannot be recovered."

Always run `git status` / `git ls-files` during the scan so you know each
candidate's tier. Never present a deletion proposal without it.

## Pipeline

### 1. Scan
Detect candidates across the four categories. See `references/detection.md` for
the per-category heuristics and the exact commands. Record for each hit: path,
category, **why it looks stale** (the evidence), and recovery tier (tracked /
untracked).

### 2. Classify
Group hits by category. Drop any false positive you can already see (a "plan"
that is actually a living spec, a log written minutes ago, a `.bak` the user just
made on purpose). When the evidence for staleness is weak, downgrade it to
"flagged, not proposed" rather than proposing deletion.

### 3. Propose — ALWAYS use this report shape
The user decides from this report alone, so make removal and reason legible:

```
# Sweep proposal — <repo name>

## Summary
<N> candidates, <X> tracked (recoverable) / <Y> untracked (NOT recoverable).
Permanent knowledge & code untouched.

## Stale docs (point-in-time)
- docs/plans/2026-04-01-old-thing.md  [tracked]  — superseded by 2026-05 plan; work merged in <commit>
- docs/handoff/foo.md                 [tracked]  — referenced task shipped; handoff is stale per YAGNI

## Logs (volatile)
- logs/qa/                            [untracked, NOT recoverable] — 14 files, all > 7d (GC window)
- logs/agents/executor-*.log          [untracked, NOT recoverable] — 6 files

## Orphan / duplicate
- docs/_archive/empty/                [tracked]  — empty dir
- docs/reports/dup-of-X.md            [tracked]  — duplicate SSOT of docs/reports/X.md

## Build / tmp
- *.bak-1748* (3 files)               [untracked, NOT recoverable]
- tmp/                                [untracked, NOT recoverable]

## Excluded on purpose
<anything you flagged but did NOT propose, with the reason — so the user sees you considered it>
```

### 4. Confirm
Offer granularity: approve **all**, **per-category**, or **per-file**. For the
untracked / not-recoverable group, confirm it *separately and explicitly* — do
not let it ride on a blanket "yes". This is the irreversible part; treat it like
one.

### 5. Execute
- Tracked → `git rm <path>` (or `git rm -r` for dirs). Stage, don't commit, unless
  asked — let the user review the staged deletion.
- Untracked → `rm` only the items confirmed in step 4. For volatile dirs the user
  wants to keep emitting (e.g. `logs/`), prefer adding to `.gitignore` over deleting
  the dir itself.
- Never `rm -rf` a path the scan did not explicitly list. No globbing beyond what
  was shown in the proposal.

### 6. Verify
Run `git status` and report the end state: what was removed, what is staged, what
was skipped. If you added `.gitignore` entries, show them. Leave the repo in a
state the user can review and commit themselves — committing is the user's call
(external/irreversible), not sweep's.

## What sweep is not

- Not `git clean -fdx` — that is blunt and ignores the knowledge/artifact boundary.
- Not a refactor — it never edits file *contents* (use `reshape`).
- Not memory or handoff hygiene logic — it deletes stale handoffs but does not
  write them (use `handoff`).
- Not automatic — it scans and proposes; deletion always waits for confirmation.
