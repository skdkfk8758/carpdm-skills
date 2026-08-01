#!/usr/bin/env bash
# Build a dummy project tree with BOTH permanent knowledge and disposable cruft,
# PLUS "trap" files that look deletable (old date / dup-ish name / .bak / stale-looking
# handoff) but must be PRESERVED. git-initialized so tracked/untracked tiers are real.
# Sweep evals run against a fresh copy (sweep is destructive — never run twice on one copy).
#
# Usage: build_fixture.sh <dest-dir>
#
# Genuine cruft (SHOULD be swept) vs Traps (must NOT be swept) are both seeded so the
# eval measures precision (don't nuke traps) as well as recall (do remove real cruft).
set -euo pipefail
DEST="${1:?usage: build_fixture.sh <dest-dir>}"
rm -rf "$DEST"
mkdir -p "$DEST"
cd "$DEST"

mkfile() { mkdir -p "$(dirname "$1")"; printf '%b\n' "$2" > "$1"; }

# --- PERMANENT: knowledge sub-tree + rules + code (must NEVER be swept) ---
mkfile rules/project.md            "# Project rules SSOT"
mkfile AGENTS.md                   "# AGENTS — built entry"
mkfile CLAUDE.md                   "@AGENTS.md"
# Portal references some OLD-dated docs on purpose (see traps T1/T2).
mkfile docs/_index/index.md        "# Portal\n- [Data layers](../concepts/data-layers.md)\n- [Quickstart](../guides/quickstart.md)\n- [Capacity report](../reports/2025-08-capacity.md)\n- [Payments plan](../plans/2025-12-payments.md)"
mkfile docs/adr/001-db-choice.md   "# ADR 001 — use Postgres (permanent decision, old but binding)"
mkfile docs/concepts/data-layers.md "# Data layers (permanent domain knowledge)"
mkfile docs/guides/quickstart.md   "# Quickstart (permanent guide)"
mkfile docs/reference/api.md       "# API reference (permanent)"
mkfile docs/specs/AUTH/spec.md     "# AUTH spec — ACTIVE contract, open items remain"
mkfile src/app.py                  "print('app')"
mkfile package.json                '{"name":"dummy"}'

# --- GENUINE CRUFT: stale point-in-time docs (tracked → recoverable) ---
mkfile docs/plans/2026-01-10-init-auth.md   "# Plan: init auth\n- [x] done\n- [x] merged (superseded by 2026-05 revamp)"
mkfile docs/plans/2026-05-20-auth-revamp.md "# Plan: auth revamp (NEWER, supersedes init-auth)\n- [ ] open"
mkfile docs/handoff/auth-wip.md    "# Handoff: auth WIP — task SHIPPED, now stale (safe to delete per YAGNI)"
mkfile docs/reports/2026-02-perf.md "# Old perf report (superseded by perf.md, not referenced anywhere)"
mkfile docs/reports/perf.md        "# Perf report — canonical SSOT"
mkfile docs/reports/perf-copy.md   "# Perf report — canonical SSOT"   # TRUE duplicate of perf.md (same body)
mkdir -p docs/reviews/empty-dir

# --- TRAPS: look deletable, must be PRESERVED (tracked) ---
# T1: old date BUT referenced from the portal → alive.
mkfile docs/reports/2025-08-capacity.md "# Capacity report 2025-08 — REFERENCED from docs/_index/index.md, still cited"
# T2: old date BUT open checkboxes + active, blocked → alive.
mkfile docs/plans/2025-12-payments.md "# Plan: payments — ACTIVE, blocked on vendor\n- [ ] integrate gateway\n- [ ] reconcile (referenced from portal)"
# T3: handoff that is NOT done — work still in flight.
mkfile docs/handoff/migration-wip.md "# Handoff: DB migration — IN FLIGHT, NOT shipped, resume here next session"
# T6: looks like a dup of perf.md by name but is a DIFFERENT report (frontend, not backend) → not a dup.
mkfile docs/reports/perf-v2.md     "# Frontend perf report — DIFFERENT subject from perf.md (backend). Similar name, NOT a duplicate."

# Commit the permanent + tracked set so they have a recovery tier.
git init -q
git config user.email t@t.t; git config user.name t
git add -A
git -c commit.gpgsign=false commit -qm "init project" >/dev/null

# --- GENUINE CRUFT: volatile / untracked (NOT recoverable) ---
mkfile logs/qa/run-20260115.log    "qa fail evidence (old)"
mkfile logs/qa/run-20260116.log    "qa fail evidence (old)"
mkfile logs/agents/executor-x.log  "agent scratch"
mkfile logs/agents/reviewer-y.status.log "status"
mkfile tmp/scratch.txt             "tmp scratch"
: > SKILL.md.bak-1748000000
: > config.json.bak-1748000001
: > notes.orig

# Age the qa logs past the 7-day GC window (fixture-land 'today' = 2026-06-02).
touch -t 202601150000 logs/qa/run-20260115.log logs/qa/run-20260116.log 2>/dev/null || true
# T5: a .bak created JUST NOW (recent mtime) — could be an intentional manual backup.
: > config.json.bak-recent

echo "fixture built at $DEST"
echo "--- GENUINE CRUFT (should be swept) ---"
echo "  tracked:   docs/plans/2026-01-10-init-auth, docs/handoff/auth-wip, docs/reports/2026-02-perf, docs/reports/perf-copy (true dup), docs/reviews/empty-dir"
echo "  untracked: logs/qa/* (old), logs/agents/*, tmp/, SKILL.md.bak-1748*, config.json.bak-1748*, notes.orig"
echo "--- TRAPS (must be PRESERVED) ---"
echo "  T1 docs/reports/2025-08-capacity.md   (old date but portal-referenced)"
echo "  T2 docs/plans/2025-12-payments.md     (old date but active/open)"
echo "  T3 docs/handoff/migration-wip.md      (handoff still in flight)"
echo "  T6 docs/reports/perf-v2.md            (dup-looking name, different content)"
echo "  T5 config.json.bak-recent             (recent .bak, maybe intentional → caution/ask)"
echo "--- PERMANENT (must survive) ---"
echo "  rules/ AGENTS.md CLAUDE.md docs/{adr,concepts,guides,reference,_index,specs} src/ package.json"
