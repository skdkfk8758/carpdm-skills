# Wiring the co-update gate into a project's verification host

`scripts/coupdate-check.sh` is portable: it takes domain ROOTs, auto-discovers
enrolled domains, and warns on drift (exit 0 by default; `--strict` to block). The
only project-specific decision is *where to invoke it*. Find the existing
verification host and hook in there — don't invent a new mechanism if one exists.

Copy the script into the project first (e.g. `scripts/coupdate-check.sh` or
`.claude/coupdate-check.sh`) and `chmod +x` it. Below, `ROOTS` stands for the
domain-root dirs discovered in Phase 1 (e.g. `apps/api/src/modules apps/web/src/components`).

## A custom verify script (e.g. `verify.sh`, `check.sh`)
Add a step near the end, after the heavy gates. Match the script's existing style
(its `step`/`ok`/`fail` helpers, its changed-files variable if it has one). Keep it
warning-only so it never blocks a commit:
```bash
# co-update: warn if an enrolled domain's code changed without its CLAUDE.md
bash scripts/coupdate-check.sh ROOTS || true
```
If the host script uses `set -e`, the `|| true` (or the script's own `exit 0`) keeps
a warning from aborting the run.

## Husky (`.husky/pre-commit`)
Append a line:
```bash
bash scripts/coupdate-check.sh ROOTS
```
Warning-only exits 0, so the commit proceeds. Use `--strict` only if the team wants
the commit blocked on drift.

## pre-commit framework (`.pre-commit-config.yaml`)
Add a local hook:
```yaml
- repo: local
  hooks:
    - id: domain-coupdate
      name: domain CLAUDE.md co-update
      entry: bash scripts/coupdate-check.sh ROOTS
      language: system
      pass_filenames: false
      verbose: true        # show the warning even when the hook "passes"
```
`verbose: true` surfaces the warning text on success (since warning-only exits 0).

## GitHub Actions (`.github/workflows/*.yml`)
Add a step. For a PR, fetch enough history for the diff to resolve:
```yaml
- uses: actions/checkout@v4
  with: { fetch-depth: 0 }
- name: domain CLAUDE.md co-update
  run: bash scripts/coupdate-check.sh ROOTS
```
Note: the script's change set comes from `git diff HEAD` + staged + untracked, which
in CI reflects the checked-out commit. For PR-scoped drift you may prefer to diff
against the base branch — adapt the script's `CHANGED` computation to
`git diff --name-only origin/$BASE...HEAD` if PR-accurate detection matters. Keep it a
warning (don't fail the job) until the firing rate proves it's signal.

## Makefile
Add to the `verify`/`check` target:
```make
verify:
	@bash scripts/coupdate-check.sh ROOTS
	# ... existing checks ...
```

## No verification host exists
Offer the lightest option that fits the team:
- A git `pre-commit` hook (`.git/hooks/pre-commit`, or a tracked `scripts/hooks/`
  installed via `git config core.hooksPath`). Warning-only.
- Or simply document running `bash scripts/coupdate-check.sh ROOTS` manually before
  commits / in code review. Less reliable, but zero setup and honest about it.

Don't manufacture a heavy CI pipeline just to host one warning — match the project's
existing rigor.
