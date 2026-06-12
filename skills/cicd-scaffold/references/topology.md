# Topology — hybrid self-hosted runner + ECR (design invariants)

The pipeline this skill scaffolds. Understand it before changing any workflow,
so a tweak doesn't quietly break an invariant.

```
PR ───────────────▶ ci.yml          (gate: build / typecheck / test)
develop push ─────▶ deploy-dev.yml ─uses─▶ deploy.yml(env=dev, runner=dev)
                     continuous, no approval
v* tag push ──────▶ release.yml   ─uses─▶ deploy.yml(env=prod, runner=prod)
                     manual tag = the prod gate, then GitHub Release
                     (optional Required-reviewers approval needs Pro/Team)
```

deploy.yml (the SSOT) on a self-hosted runner that is ALSO the deploy host:
`OIDC creds → ECR login → docker build+push → [DEPLOY_ENABLED] pull + docker run`.

## Invariants — do not break

- **Reusable deploy.yml is the SSOT.** dev and prod differ only by inputs
  (environment, runner_label, image_tag, extra_tag). No copy-pasted deploy logic.
- **Same host builds, pushes, and runs.** The runner IS the deploy host. ECR is
  the version/rollback store, not a transport to a remote box — so no SSH/SCP.
  (If the user later wants a separate deploy host, that's the SSH-remote variant —
  a different topology this skill does not generate by default.)
- **OIDC, zero static keys.** The runner assumes the push role; the same OIDC
  session authorizes the same-host `docker pull`. No server IAM user.
- **Tag policy.** prod updates `latest` (rollback target); dev rolls `dev`.
  dev must never touch `latest`.
- **DEPLOY_ENABLED is a step-level gate.** Environment-scoped vars resolve only
  at step level (GHA context limit), so the run step checks it via a gate output.
  Build+push always run; only the container run is gated. Unset = smoke.
- **.env.production SSOT = ENV_PRODUCTION secret**, scoped per environment.
  Server hand-edits are overwritten next deploy.
- **CI gates the trunk through the deploy chain.** deploy-dev/release call ci.yml
  as their `test` job, so develop/tag pushes are still gated even though no PR ran.

## CI runner — self-hosted (default) vs github
CI and the GitHub-Release job run either on the self-hosted runner (a `node:20`
container, `--ci-runner self-hosted`) or on `ubuntu-latest` (`--ci-runner
github`). Self-hosted is the default because the whole topology's point is **zero
GitHub-hosted minutes** — the pipeline then survives an Actions billing stop
(`pitfalls.md #5`). It carries one consequence: container CI runs as root and
leaves root-owned files in the shared workspace, so the deploy job wipes the
workspace first (`pitfalls.md #4`). The `github` variant is simpler/isolated but
billed; pick it only when the user has billing headroom and wants GH-hosted CI.

## When to drop optional pieces
- No private `@scope` dep → drop the "Configure npm for GitHub Packages" steps
  and the BuildKit github_token secret.
- Single package (not monorepo) → drop ci.yml "API typecheck".
- No DB migrations → nothing migration-related is generated (this skill omits it
  by default; add a migration-naming check only if the project has migrations).
- audit.yml is optional visibility — drop if unwanted.
