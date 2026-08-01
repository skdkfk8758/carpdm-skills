---
name: claude-cicd-scaffold
description: Imported Claude skill for planning and generating GitHub Actions CI/CD deployment workflows for Node applications.
---

# cicd-scaffold — GitHub Actions CI/CD for self-hosted runner + ECR

Scaffold a trunk-based CI/CD pipeline onto a Node project. The topology is fixed
(self-hosted runner + ECR + OIDC, same host builds/pushes/runs) — read
`references/topology.md` to understand the invariants and
`references/pitfalls.md` to understand the five production-discovered gotchas the
templates already guard (so you don't strip a guard or mis-debug one). Then
follow the steps below. The work is: **detect what the project already tells you →
interview only for the gaps → substitute tokens → walk the GitHub+AWS setup in
detail → guide a safe first deploy.**

Do not invent values. Anything you cannot detect from the repo, ask. A wrong AWS
region or port silently breaks the pipeline, so confirm rather than guess.

## What gets generated

Into `<project>/.github/workflows/`:
- `ci.yml` — PR gate + reusable test job (build / typecheck / test)
- `deploy.yml` — reusable deploy SSOT (OIDC → ECR push → same-host pull + run)
- `deploy-dev.yml` — develop push → dev deploy (continuous)
- `release.yml` — v* tag → prod deploy (manual tag = the gate) + GitHub Release
- `audit.yml` — weekly npm audit (optional)

Plus, if the project has no Dockerfile, `scaffold.py --gen-dockerfile` writes one
from the template. The container is run inline by `deploy.yml`
(`docker run --env-file .env.production`) — no docker-compose unless the project
runs multiple containers (ask if so).

## Step 1 — Detect from the project

Read these and fill in what you can before asking the user anything:

| What | Where to look | Token |
|---|---|---|
| Package manager / Node | `package.json`, lockfile | (npm assumed) |
| Build command | `package.json` scripts (`build`, `typecheck`) | `__BUILD_CMD__` |
| Test command | `package.json` scripts (`test`) | `__TEST_CMD__` |
| Monorepo? api workspace | `package.json` `workspaces`, `apps/`, `packages/` | `__API_BUILD_CMD__` |
| Private npm scope | `.npmrc`, `@scope/` deps in `package.json` | `__PRIVATE_NPM_SCOPE__` |
| Dockerfile path | `Dockerfile*` | `__DOCKERFILE__` |
| Container port | Dockerfile `EXPOSE`, framework default | `__CONTAINER_PORT__` |
| Start command (if generating Dockerfile) | `package.json` `start`, framework | `--start-cmd` |
| Repo + owner | `git remote -v` | `__OWNER__` `__REPO__` |
| App name (container) | repo name | `__APP_NAME__` |
| Trunk branch | `git branch`, default branch | (assume `develop`; confirm) |
| DB migrations | `migrations/` dir | (omit unless present) |

State what you detected back to the user in a short table so they can correct it.

## Step 2 — Interview for the gaps

These cannot be read from the repo. Ask in one batch (use AskUserQuestion where
the options are discrete):

- **AWS region** (`__AWS_REGION__`) — e.g. `ap-northeast-2`
- **AWS account ID** (`__AWS_ACCOUNT_ID__`) — 12-digit, for ECR host + trust policy
- **ECR repo name** (`__ECR_REPO__`) — defaults to the app name; confirm
- **Host port** (`__HOST_PORT__`) — the port published on the deploy host
- **dev/prod runners** — same machine (two labels) or two machines? Are the
  self-hosted runners already registered, or does the user need the setup steps?
- **CI runner** (`--ci-runner`) — where CI and the GitHub-Release job run.
  `self-hosted` (default) runs them in a `node:20` container on the dev/prod
  runner: **zero GitHub-hosted minutes**, so the pipeline keeps working even if
  the org's Actions billing is suspended — this matches the runbook's zero-billing
  goal and adds the workspace-wipe guard (`pitfalls.md #4`/`#5`). `github` runs
  them on `ubuntu-latest`: simpler and isolated, but billed and dead on a billing
  stop. Default to `self-hosted` unless the user specifically wants GitHub-hosted
  isolation and has billing headroom.
- **Build-time args** (`__BUILD_ARGS__`) — frontend inline env (e.g. `VITE_API_BASE=/api`).
  Empty for most backends — then delete the `build-args:` block in deploy.yml.

If the project has no private `@scope` dependency, tell the user you're dropping
the GitHub Packages npm steps (and the BuildKit `github_token` secret) — they add
noise when unused.

## Step 3 — Run scaffold.py with the resolved values

Don't hand-copy and hand-substitute the YAML — `scripts/scaffold.py` does the
mechanical part deterministically: copy templates, prune the optional blocks that
don't apply (private scope / api typecheck / build-args / audit), substitute every
token, build a correct exec-form Dockerfile `CMD`, and hard-fail if any
`__TOKEN__` survives. You provide the values you detected + interviewed; the
script removes the divergence and the per-file `sed` reasoning.

```bash
python /Users/carpdm/.codex/skills/claude-cicd-scaffold/scripts/scaffold.py --dest <project> \
  --app-name <name> --aws-region <region> --ecr-repo <repo> \
  --host-port <H> --container-port <C> --dockerfile <path> \
  --build-cmd "<build cmd>" --test-cmd "<test cmd>" \
  [--npm-scope @scope]            # omit if no private GitHub Packages dep \
  [--api-build-cmd "<cmd>" | --no-api-build]   # monorepo api typecheck vs single package \
  [--build-args "KEY=VALUE"]      # frontend build-time env; omit to drop the block \
  [--no-audit]                    # drop audit.yml \
  [--ci-runner self-hosted|github]  # CI/release runner; default self-hosted (zero GH minutes) \
  [--gen-dockerfile --start-cmd "<container start cmd>"]   # only when no Dockerfile exists
```

Flag → behavior:
- `--ci-runner self-hosted` (default) → ci.yml + release job run in a `node:20`
  container on the self-hosted runner, and deploy.yml gets the workspace-wipe step
  (root-owned files from container CI, `pitfalls.md #4`). `github` → both run on
  `ubuntu-latest` and the wipe step is dropped.
- `--npm-scope` present → keeps the GitHub Packages npm steps + BuildKit
  `github_token` secret. Omit → those blocks are stripped (no dead auth).
- `--api-build-cmd` present (and not `--no-api-build`) → keeps ci.yml "API
  typecheck". Single package → pass `--no-api-build`.
- `--build-args` present → keeps the deploy.yml `build-args:` block. Omit → stripped.
- `--no-audit` → audit.yml not written.
- `--gen-dockerfile` → also writes a Dockerfile from the template; `--start-cmd`
  is split into a JSON exec-form array. Skip this flag if the project already has
  a Dockerfile (the build step just references it via `--dockerfile`).

The script prints the files it wrote and confirms the no-token guard. If it exits
non-zero on leftover tokens, you missed a value — fix and re-run (idempotent).

## Step 4 — GitHub + AWS setup (the part users get stuck on)

The files don't run without out-of-repo setup, and a missing piece fails with a
cryptic error rather than "you forgot X". This is the step to be thorough on —
walk the user through it section by section, running the `gh`/`aws` commands for
them where you can and explaining what each value is and where to find it.

- `references/github-setup.md` — the 2 repo secrets (`AWS_ACCOUNT_ID`,
  `AWS_ROLE_TO_ASSUME`), the `dev`/`prod` environments with their `ENV_PRODUCTION`
  secret + `DEPLOY_ENABLED` var, the self-hosted runner labels, and the **prod
  gate truth**: the manual `v*` tag is the gate; Required reviewers is an optional
  Pro/Team-only extra (Free + private → 422), so don't tell the user to rely on it
  unless they're on a paid plan. Ends with a copy-paste checklist.
- `references/aws-oidc-setup.md` — ECR repo, the account-wide OIDC provider, and
  the push role whose trust policy is scoped to this repo's **`:environment:`
  subjects** (NOT branch refs — `pitfalls.md #3`), plus verification commands.

Never fabricate secret values — have the user provide them, or pipe
`ENV_PRODUCTION` straight from their local `.env` files
(`gh secret set ENV_PRODUCTION --env prod < ./.env.production`).

## Step 5 — Safe first deploy (cutover)

`DEPLOY_ENABLED` starts unset, so the first develop push does build + ECR push
but skips the container run (smoke test). Tell the user to:

1. Merge to `develop`, watch deploy-dev → confirm build+push green, ECR image present.
2. Set `gh variable set DEPLOY_ENABLED --env dev --body true`.
3. Re-trigger (empty commit or re-run) → confirm the container comes up.
4. Repeat for prod via a `v0.0.1` tag once dev is proven.

## Branch strategy alignment

This pipeline assumes the trunk-based strategy in
`~/.claude/rules/branch-worktree-strategy.md`: `develop` is the integration trunk
(dev deploy), `main`/tags are the release line (prod deploy). If the project uses
different branch names, adjust the `on:` triggers in deploy-dev.yml / release.yml
and the OIDC trust policy refs to match — and flag the mismatch to the user.
