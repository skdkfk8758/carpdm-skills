# GitHub Setup — secrets, environments, runners (do this once per repo)

Substituting the workflow tokens is not enough — the pipeline reads these
out-of-file settings at run time, and a missing one fails the run with a
confusing error rather than a clear "you forgot X". Walk the user through each
section **in order**. Where `gh` can do it, offer to run the command; never
invent a secret value — ask the user or read it from their local file.

Prereqs: the user has `gh` installed and authenticated (`gh auth status`) with
admin on the repo. Every `gh` command below runs from inside the repo clone, so
`:owner/:repo` resolves automatically — no need to type the slug.

---

## 1. Repo-level secrets (2)

These are the same for every environment, so they live at the repo level.

| secret | what it is | where to get it |
|---|---|---|
| `AWS_ACCOUNT_ID` | your 12-digit AWS account number — `deploy.yml` builds the ECR registry host `…<id>.dkr.ecr.<region>.amazonaws.com` from it | AWS console top-right account menu, or `aws sts get-caller-identity --query Account --output text` |
| `AWS_ROLE_TO_ASSUME` | full ARN of the OIDC push role | the output of `references/aws-oidc-setup.md` step 3 — `arn:aws:iam::<id>:role/<repo>-ecr-push` |

```bash
gh secret set AWS_ACCOUNT_ID  --body 123456789012
gh secret set AWS_ROLE_TO_ASSUME --body arn:aws:iam::123456789012:role/myrepo-ecr-push
```

Verify they exist (values are never shown back):
```bash
gh secret list
```

> Do **not** create `GITHUB_TOKEN` — Actions injects it automatically each run.

---

## 2. GitHub Environments — `dev` and `prod`

Environments scope secrets/vars per deploy target and are what `deploy.yml`'s
`environment:` key selects. Create both:

```bash
gh api -X PUT repos/{owner}/{repo}/environments/dev
gh api -X PUT repos/{owner}/{repo}/environments/prod
```

### 2a. Per-environment secret — `ENV_PRODUCTION`

This is the **entire `.env.production`** the container runs with. `deploy.yml`
writes it to a file and passes it via `docker run --env-file`. dev and prod each
hold their **own** value (different DB, different secrets), so set it twice:

```bash
# pipe the local env file straight in — no copy/paste, no value echoed
gh secret set ENV_PRODUCTION --env dev  < ./.env.dev
gh secret set ENV_PRODUCTION --env prod < ./.env.production
```

Each file is plain `KEY=value` lines, e.g.:
```
NODE_ENV=production
DATABASE_URL=postgres://user:pass@host:5432/mydb
SESSION_SECRET=…
```
> ⚠ The container is the only consumer of these — make sure the DB host/name
> matches the target environment. (A wrong `DB_NAME` here passes CI but the
> container fails its health check on boot.)

### 2b. Per-environment variable — `DEPLOY_ENABLED`

A **variable** (not a secret — it's not sensitive and the gate step reads it via
the `vars` context). `true` lets the container actually run; unset = build + ECR
push only (a smoke test). **Leave it unset for the very first deploy**, confirm
the image lands in ECR, then flip it on:

```bash
# first deploy: do NOT set it. After the smoke run is green:
gh variable set DEPLOY_ENABLED --env dev  --body true
gh variable set DEPLOY_ENABLED --env prod --body true
```

Verify environment secrets/vars:
```bash
gh secret list   --env prod
gh variable list --env prod
```

### 2c. prod gate — what you actually get on each plan

The prod gate is the **manual `v* tag`**: nothing reaches prod unless a human
consciously runs `git tag -a v0.0.1 … && git push origin v0.0.1`. That is the
real safety mechanism and it works on every plan.

**Required reviewers** (a GitHub Environment protection rule that *pauses* the
deploy job for an explicit click-approval) is an *optional extra* on top — but it
needs a **public repo or GitHub Pro/Team/Enterprise**. On a **private repo on the
Free plan** the API rejects it:

```bash
# Only works on public repo OR Pro/Team. On Free+private this returns
# 422 "... is not available for your billing plan".
gh api -X PUT repos/{owner}/{repo}/environments/prod \
  -F 'reviewers[][type]=User' -F 'reviewers[][id]=<numeric-user-id>'
# (get <numeric-user-id> from:  gh api users/<login> --jq .id )
```

So tell the user plainly: on Free+private, the tag is the gate; reviewers are a
later upgrade. Leave `dev` with no reviewers (continuous deploy). See
`references/pitfalls.md` "Cross-plan limits".

---

## 3. Self-hosted runners — `dev` and `prod` labels

The deploy host runs the GitHub Actions runner agent. `deploy.yml` targets it
with `runs-on: [self-hosted, "${{ inputs.runner_label }}"]`, so each runner needs
the `self-hosted` label **plus** its environment label (`dev` or `prod`). With the
default `--ci-runner self-hosted`, CI also runs here (on the `dev` runner), so the
runner is required before *any* workflow can pass.

Register a runner (per host):
1. Repo → **Settings → Actions → Runners → New self-hosted runner**.
2. Run the shown `./config.sh` on the host. When it asks for **labels**, add `dev`
   (or `prod`) — `self-hosted` is added automatically.
3. Install it as a service so it survives reboot: `sudo ./svc.sh install && sudo ./svc.sh start`.

Host requirements:
- **Docker** installed, and the runner's user in the `docker` group
  (`sudo usermod -aG docker $USER` then re-login) — the deploy job shells out to
  `docker build/push/run` and (self-hosted CI) `docker run` for the workspace wipe.
- For `--ci-runner self-hosted`: nothing else — CI runs inside a `node:20`
  container the runner pulls.

dev and prod can be the **same machine** (two runner agents, different labels) or
**two machines** — the workflows don't care. Two hosts is safer: self-hosted is a
SPOF (`pitfalls.md #5`), so if one host is down both CI and its deploys stop.

Verify the runner is online: Repo → Settings → Actions → Runners (green "Idle"),
or `gh api repos/{owner}/{repo}/actions/runners --jq '.runners[]|{name,status,labels:[.labels[].name]}'`.

---

## 4. Limitation — server-side merge block is not available on Free+private

A private repo without GitHub Pro can't set branch protection / required status
checks (the API returns 403), so **CI red cannot block a merge** — it's advisory.
Merge discipline falls to humans + local guard hooks until the repo is public or
on Pro. See `branch-worktree-strategy.md §8` and `pitfalls.md` "Cross-plan limits".

---

## Quick checklist

- [ ] `gh secret set AWS_ACCOUNT_ID`, `AWS_ROLE_TO_ASSUME` (repo level)
- [ ] `gh api -X PUT …/environments/dev` and `/prod`
- [ ] `ENV_PRODUCTION` set for **both** dev and prod environments
- [ ] `DEPLOY_ENABLED` **left unset** for the first run (set to `true` after smoke)
- [ ] self-hosted runner(s) online with `dev` / `prod` labels + Docker
- [ ] (optional, Pro/Team only) prod Required reviewers
- [ ] AWS side done — see `references/aws-oidc-setup.md`
</content>
