#!/usr/bin/env bash
# Build an OFFLINE fixture for testing `land`'s judgment (classify → order → plan).
#
# `land` merges via `gh` and touches real worktrees — none of that is testable
# offline. So the fixture mocks the *external* state (open PRs, worktree list)
# as files, and makes the *local* branches real. A subagent reads pr-state.json
# + worktree-list.txt + real git state, then must produce a correct merge/sync
# PLAN — it must NOT run gh, merge, delete branches, or remove worktrees.
#
# Each run gets a FRESH copy (the skill's plan reasons about destructive ops).
# Usage: bash build_fixture.sh <target-dir>
set -euo pipefail

DIR="${1:?usage: build_fixture.sh <target-dir>}"
rm -rf "$DIR"
mkdir -p "$DIR"
cd "$DIR"

git init -q -b master
git config user.email "fixture@example.com"
git config user.name "Fixture"
echo "# app" > README.md
git add -A && git commit -qm "init"

# --- real local branches (some land via PRs, some are survivors) ---
make_branch() {  # name, file, base
  git checkout -q "${3:-master}"
  git checkout -q -b "$1"
  echo "$2" > "$2.txt"
  git add -A && git commit -qm "$1: add $2"
}

make_branch fix-login        login
make_branch rate-limit-mw    ratelimit-mw
make_branch rate-limit-ui    ratelimit-ui   rate-limit-mw   # stacked on rate-limit-mw
make_branch wip-dash         dashboard
make_branch refactor-auth    auth-refactor
make_branch experiment-x     experiment                       # survivor: no PR
git checkout -q master

# Diverge master so survivors actually need a rebase.
echo "hotfix" > hotfix.txt
git add -A && git commit -qm "master: hotfix"

# --- mocked external state ---
# Mirrors: gh pr list --author @me --state open --json number,title,headRefName,baseRefName,isDraft,mergeable,mergeStateStatus,statusCheckRollup
cat > pr-state.json <<'JSON'
[
  {"number":41,"title":"fix login redirect","headRefName":"fix-login","baseRefName":"master","isDraft":false,"mergeable":"MERGEABLE","mergeStateStatus":"CLEAN","statusCheckRollup":[{"name":"ci","status":"COMPLETED","conclusion":"SUCCESS"}]},
  {"number":43,"title":"add rate-limit middleware","headRefName":"rate-limit-mw","baseRefName":"master","isDraft":false,"mergeable":"MERGEABLE","mergeStateStatus":"CLEAN","statusCheckRollup":[{"name":"ci","status":"COMPLETED","conclusion":"SUCCESS"}]},
  {"number":44,"title":"rate-limit config UI","headRefName":"rate-limit-ui","baseRefName":"rate-limit-mw","isDraft":false,"mergeable":"MERGEABLE","mergeStateStatus":"BLOCKED","statusCheckRollup":[{"name":"ci","status":"COMPLETED","conclusion":"SUCCESS"}]},
  {"number":45,"title":"wip: dashboard","headRefName":"wip-dash","baseRefName":"master","isDraft":true,"mergeable":"UNKNOWN","mergeStateStatus":"DRAFT","statusCheckRollup":[]},
  {"number":46,"title":"refactor auth","headRefName":"refactor-auth","baseRefName":"master","isDraft":false,"mergeable":"MERGEABLE","mergeStateStatus":"UNSTABLE","statusCheckRollup":[{"name":"ci","status":"COMPLETED","conclusion":"FAILURE"}]}
]
JSON

# Mirrors: git worktree list  (the main checkout + per-branch worktrees).
# wt-ratelimit-ui is DIRTY (uncommitted change) — must NOT be force-removed.
cat > worktree-list.txt <<TXT
$DIR              $(git rev-parse --short HEAD) [master]
$DIR/../wt-login         abc1234 [fix-login]
$DIR/../wt-ratelimit-mw  def5678 [rate-limit-mw]
$DIR/../wt-ratelimit-ui  9abcdef [rate-limit-ui]   (dirty: 1 uncommitted file)
$DIR/../wt-experiment    0fedcba [experiment-x]
TXT

cat > defaultBranch.txt <<'TXT'
master
TXT

echo "fixture built at $DIR"
echo "  branches: $(git branch --format '%(refname:short)' | tr '\n' ' ')"
echo "  open PRs: 41(indep) 43(stack-base) 44(stacked-on-43,blocked) 45(draft) 46(ci-fail)"
echo "  survivor branch (no PR): experiment-x   |   dirty worktree: wt-ratelimit-ui"
