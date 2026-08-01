# Pitfalls — production-discovered, baked into the templates

These five only surfaced by actually running the pipeline on GitHub Actions, not
from reading docs. The templates this skill writes already avoid them — this file
records *why* each guard exists so a future edit doesn't innocently remove it, and
so you can diagnose fast if a hand-modified pipeline hits one. (Origin: the
Intelligence-Auth as-built runbook, `구축 중 잡은 함정`.)

## 1. workflow-level `env` cannot read `secrets`

A `env:` block at the *workflow* (top) level cannot reference `${{ secrets.* }}`
— GitHub rejects the run with `startup_failure` before any step executes. So
`deploy.yml` puts `ECR_IMAGE` (which interpolates `secrets.AWS_ACCOUNT_ID`) under
the **job** `env:`, not the workflow `env:`. Keep secret-derived env at job level.

## 2. A reusable workflow cannot exceed the caller's permissions

`deploy.yml` needs `id-token: write` to mint the OIDC token for ECR. But a
reusable (`workflow_call`) workflow is capped by the **caller's** granted
permissions — it cannot request more than the caller holds. So every caller
(`deploy-dev.yml`, `release.yml`) must itself declare `permissions: id-token:
write`. Symptom if missing: `Error: Credentials could not be loaded` /
`Not authorized to perform sts:AssumeRoleWithWebIdentity` even though the trust
policy is correct.

## 3. `environment:` rewrites the OIDC `sub` claim

The moment a job declares `environment: <name>`, GitHub sets the OIDC token's
`sub` claim to `repo:OWNER/REPO:environment:<name>` — **not** the
`:ref:refs/heads/...` form you'd expect from the branch. `deploy.yml`'s deploy job
uses `environment:`, so the AWS role trust policy must match on
`:environment:dev` / `:environment:prod`, not on branch/tag refs. Scope the trust
to refs instead and `AssumeRoleWithWebIdentity` fails with "Not authorized".
(`references/aws-oidc-setup.md` encodes the correct environment-based form.)

## 4. Container CI leaves root-owned files in a shared self-hosted workspace

Only bites the **self-hosted CI** variant. When CI runs inside a `node:20`
container on a self-hosted runner, it runs as **root** and writes root-owned
`.next/` / `.git/` into the runner's shared workspace dir. The next *host* job
(the deploy job, running as the non-root runner user) then fails its checkout's
`git clean` with `Permission denied`. Guard: the deploy job's first step wipes the
workspace via host `docker` (root) before `actions/checkout`. The `github` CI
variant (ubuntu-latest) is ephemeral and never shares a workspace, so it has no
wipe step — that's why the wipe lives in the `ci-self-hosted` optional block.

## 5. GitHub-hosted runners die when org billing stops

`ubuntu-latest` is a GitHub-hosted runner — billed minutes, and it simply won't
start if the org's Actions billing is suspended (free-tier exhausted, card
expired). The all-self-hosted variant exists to remove that dependency entirely:
zero GitHub-hosted minutes, so CI and deploy keep running regardless of billing.
The tradeoff — self-hosted is a SPOF: if the runner host is down, CI *and* deploy
stop together. Two runner hosts (dev + prod) is the minimum mitigation.

## Cross-plan limits (not bugs — billing-tier facts)

- **prod Required reviewers** (Environment protection) needs a **public repo or
  GitHub Pro/Team/Enterprise**. On a **private repo on the Free plan** the API
  returns `422 ... billing plan`. The de-facto prod gate is then the **manual
  `v*` tag** — nothing reaches prod without a human consciously cutting a tag.
- **Branch protection / required status checks** have the same limit → on
  Free+private, CI red **cannot block a merge** (advisory only). Merge discipline
  falls to humans + local guard hooks. See `branch-worktree-strategy.md §8`.
</content>
</invoke>
