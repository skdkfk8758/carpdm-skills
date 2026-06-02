---
name: land
description: Land the open PRs you pushed from worktrees and bring local back in sync — in a fresh session, merge your mergeable PRs (squash, after CI passes), then pull the default branch, delete merged local branches, remove merged worktrees, and rebase any branches that did not land. Use this whenever the user wants to MERGE / LAND open PRs and CLEAN UP local git state — phrasings like "올린 PR들 머지하고 로컬 최신화해줘", "PR 다 머지하고 브랜치/워크트리 정리", "merged 브랜치 prune하고 master 당겨줘", "워크트리 개발 끝났으니 정리", "land my PRs and sync local", "merge the open PRs and clean up branches". It auto-detects whether the PRs are independent or stacked (one PR based on another) and merges in the right order. Do NOT use it to write code, build a feature (use forge), fix a bug (use hunt), or to resume an unfinished task / recall where you left off (use handoff) — land is about getting already-pushed PRs merged and the local tree clean, not about the work inside them.
---

# Land — merge your pushed PRs and resync local, safely

You develop on worktree branches, push a stream of PRs, and then — often in a
fresh session with no memory of which branch was which — you want them merged and
your local tree cleaned up: default branch current, merged branches and worktrees
gone, surviving branches rebased onto the new base. Doing this by hand is fiddly
and easy to get wrong: merge a stacked PR out of order and you create a mess;
delete a branch that hasn't actually landed and you lose work.

This skill does it as a disciplined pipeline. The work is **mostly irreversible**
(merging, deleting branches, removing worktrees, rebasing), so the contract is:
discover the real state, decide a safe order, **show the plan and get one
confirmation**, then execute and report. Never guess; never force.

## Safety boundary — read before doing anything

| Action | Stance |
|---|---|
| **Never** | `git push --force` to a shared branch, merge a PR that is draft / has failing CI / is not mergeable, delete a branch whose PR is still open, commit directly on the default branch, resolve a conflict by guessing |
| **Confirm once, then do** | merging PRs, deleting merged local branches, `git worktree remove`, rebasing surviving branches |
| **Free to do** | `gh pr list`, `git worktree list`, `git fetch`, reading CI status, `git checkout <default>` + `git pull` (fast-forward) |

A branch is only safe to delete when **its PR is merged** (or it has no PR and the
user confirmed). "Looks merged" is not enough — verify against `gh`/git, not the
branch name. If anything is ambiguous (an open PR you didn't expect, a dirty
worktree, a branch with no PR), **stop and ask** rather than proceed.

If CI fails, a merge is blocked, or a rebase hits a conflict: **halt that item,
leave it in a recoverable state, report it, and move on to what's still safe.**
Do not abort the whole run for one stuck PR, and do not `rebase --abort` or
discard a conflict without the user — they may want to resolve it.

## The pipeline

### 1. Discover — get the real state, don't assume

Run these (read-only) and build a picture before touching anything:

- `gh pr list --author @me --state open --json number,title,headRefName,baseRefName,isDraft,mergeable,mergeStateStatus,statusCheckRollup`
  — the open PRs, their head/base branches, draft flag, mergeability, CI status.
- `git worktree list` — which worktrees exist and what branch each holds.
- `git branch --format '%(refname:short) %(upstream:short) %(upstream:track)'` — local branches and their tracking state.
- `git fetch --prune` — refresh remote refs and drop deleted remote-tracking branches.

Identify the default branch from `gh repo view --json defaultBranchRef` (don't hardcode `master`/`main`).

### 2. Classify — independent vs stacked

For each open PR, compare its `baseRefName` to the default branch:

- **base == default** → independent PR. Merge order doesn't matter.
- **base == another open PR's head** → stacked. The PRs form a chain; they must
  merge bottom-up, and each merge requires re-pointing the next PR's base.

Mixed is normal — some independent, some stacked. Build the merge order by
topological sort of the stack chains, with independent PRs anywhere. See
`references/stacking.md` for the exact re-basing dance when a stack is present.

Drop from the candidate set: drafts, PRs with failing/pending CI you were told
not to wait on, and anything not `mergeable`. List what you dropped and why.

### 3. Confirm — one plan, one approval

Show the user a single plan before any irreversible action:

```
Will merge (squash, after CI passes), in this order:
  #41 fix login redirect        (independent)
  #43 add rate-limit middleware (stack base) → then re-point #44 onto default
  #44 rate-limit config UI      (stacked on #43)
Skipping:
  #45 wip: dashboard            (draft)
  #46 refactor auth             (CI failing)
After merge, locally:
  pull <default>, delete merged branches [fix-login, rate-limit-mw, rate-limit-ui],
  remove worktrees [../wt-login, ../wt-ratelimit], rebase surviving [refactor-auth] onto <default>
Proceed?
```

Wait for approval. This is the one gate — after it, execute without further prompts unless something halts.

### 4. Merge — squash, wait for CI

For each PR in order: `gh pr merge <n> --squash --auto --delete-branch`.
`--auto` lets GitHub merge once required checks pass; poll `gh pr view <n> --json state,mergeStateStatus` until `MERGED` or a check fails. `--delete-branch` removes the *remote* branch on merge (local cleanup is step 5).

For a **stack**, after the base PR merges, re-point the next PR's base to the
default branch (`gh pr edit <next> --base <default>`) before merging it — otherwise
its diff is wrong. Details and edge cases: `references/stacking.md`.

If a check fails or merge is blocked, halt that PR (and anything stacked above it,
since it can't merge yet), report, continue with independent PRs that are still fine.

### 5. Sync local — pull, prune branches, remove worktrees, rebase survivors

Once merges are done:

1. **Pull default**: `git checkout <default> && git pull --ff-only`. (Never commit here — the branch-protection guard blocks direct work, and `--ff-only` keeps it clean.)
2. **Remove merged worktrees first, then delete their branches** — order matters: a branch checked out in a worktree can't be deleted. `git worktree remove <path>` for each worktree whose branch landed, then `git branch -d <branch>` (lowercase `-d` so git refuses if it's *not* actually merged — a built-in safety net; if it refuses, that branch didn't land, so investigate, don't `-D`).
3. **Prune remote-tracking**: already handled by `git fetch --prune` / `--delete-branch`; a final `git remote prune origin` cleans stragglers.
4. **Rebase survivors**: for each local branch that did NOT land, `git rebase <default>`. On conflict, stop and report that branch (leave the rebase in progress so the user can resolve or you can on request) — see `references/stacking.md` for the recovery shape.

### 6. Report

End with a short summary: which PRs merged, which were skipped and why, which
branches/worktrees were removed, which branches were rebased (and any left
mid-rebase awaiting conflict resolution). Make the not-done items obvious so
nothing silently falls through.

## When this is the wrong skill

- The user wants to *write* the change, not merge it → `forge` / `hunt` / `renew` / `reshape`.
- The user wants to resume an unfinished task or recall where they left off → `handoff`.
- The user wants to clear stale docs/logs, not git branches → `sweep`.
