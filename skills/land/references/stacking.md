# Stacking & rebase recovery

Load this when the discover step finds **stacked PRs** (a PR whose base is another
open PR's head) or when a survivor rebase hits a **conflict**. For all-independent
PRs you don't need any of this.

## Detecting a stack

After `gh pr list ... --json number,headRefName,baseRefName`, build edges
`base → head`. Any PR whose `baseRefName` is the `headRefName` of another open PR
is stacked on it. Chains can be longer than two (A ← B ← C). Topologically sort so
the PR based on the default branch merges first.

Example:
```
#43 head=rate-limit-mw  base=master        ← stack bottom (base is default)
#44 head=rate-limit-ui  base=rate-limit-mw ← sits on #43
```
Merge order: #43, then #44.

## The re-pointing dance

GitHub does NOT auto-move a child PR's base when its parent merges. If you squash
#43 into the default branch and then try to merge #44 as-is, #44's diff is computed
against the now-deleted `rate-limit-mw` branch — wrong or broken.

So, per stack level, bottom-up:

1. Merge the bottom PR: `gh pr merge 43 --squash --auto --delete-branch`. Wait for `MERGED`.
2. Re-point the child onto the default branch: `gh pr edit 44 --base <default>`.
   GitHub recomputes #44's diff against default; because #43's changes are now in
   default, #44 shows only its own delta.
3. Re-check #44's mergeability and CI — re-pointing can re-trigger checks and can
   surface conflicts that were hidden while it sat on its parent. Wait for green.
4. Merge #44. Repeat for any PR stacked on #44.

If step 3 shows a conflict (the child doesn't cleanly apply on the new base), halt
the stack at this level and report — the user (or you, on request) needs to update
the child branch. Do not force-merge.

## Squash vs the stack

Squash merge is the project default and is fine for stacks **as long as you
re-point** between levels (above). The one gotcha: after a squash, the child's
commits look different from default's single squashed commit, so a plain
`git rebase` of the child's *local* branch onto default may replay already-merged
changes as conflicts. Prefer re-pointing the PR base (GitHub handles the diff)
over locally rebasing a stacked child before its parent merges.

## Survivor rebase conflicts (step 5.4)

For a local branch that did **not** land, `git rebase <default>` brings it up to
date. On conflict:

- `git rebase <default>` stops with conflicted paths and the branch left
  mid-rebase (`.git/rebase-merge` present, `git status` shows "rebase in progress").
- **Leave it there.** Report: which branch, which files conflict
  (`git diff --name-only --diff-filter=U`), and that it's paused mid-rebase.
- Do NOT `git rebase --abort` (throws away the partial progress) or `--skip`
  (silently drops a commit) without the user asking — either can lose work.
- The user can resolve and `git rebase --continue`, or ask you to. If they want
  out, `git rebase --abort` returns the branch to its pre-rebase state safely.

If multiple survivors exist, rebase them independently; one conflicting branch
shouldn't block rebasing the others. Report each separately.

## Dirty worktree guard

Before removing a worktree or rebasing a branch checked out in one, confirm the
worktree is clean (`git -C <path> status --porcelain` empty). A dirty merged
worktree means uncommitted local work — stop and ask; don't `worktree remove
--force` over someone's changes.
