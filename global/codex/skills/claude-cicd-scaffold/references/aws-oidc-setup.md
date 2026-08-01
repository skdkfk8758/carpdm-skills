# AWS Setup — OIDC push role + ECR repo (once per AWS account/repo)

The pipeline pushes to ECR with zero static keys: GitHub issues an OIDC token,
AWS exchanges it for a short-lived role. Set this up before the first deploy run.

Prereqs: AWS CLI authenticated as a user with IAM + ECR admin
(`aws sts get-caller-identity` works). Run the commands from a scratch dir and
keep the two `*.json` policy files there. Replace every `__TOKEN__` with the same
values you fed `scaffold.py` (`__AWS_REGION__`, `__AWS_ACCOUNT_ID__`, `__ECR_REPO__`,
`__OWNER__`, `__REPO__`).

## 1. ECR repository

One repo per image (`__ECR_REPO__`):

```bash
aws ecr create-repository --repository-name __ECR_REPO__ --region __AWS_REGION__
```

## 2. GitHub OIDC identity provider (once per AWS account)

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

If it already exists (another repo set it up), skip — there is one per account.

## 3. Push role + trust policy

The role's trust policy must allow ONLY this repo's deploy subjects — not `*`,
which would let any repo assume it.

> ⚠ **`sub` claim depends on `environment:`.** The deploy job in `deploy.yml`
> declares `environment: <dev|prod>`. When a job references an environment,
> GitHub sets the OIDC `sub` claim to `repo:OWNER/REPO:environment:<name>` —
> **NOT** `:ref:refs/heads/...`. So scope the trust to the **environments**, not
> the branch/tag refs, or `sts:AssumeRoleWithWebIdentity` fails with
> "Not authorized". (If your deploy job did NOT use `environment:`, you'd use the
> `:ref:refs/heads/develop` / `:ref:refs/tags/v*` form instead.)

`trust-policy.json`:
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Federated": "arn:aws:iam::__AWS_ACCOUNT_ID__:oidc-provider/token.actions.githubusercontent.com" },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": { "token.actions.githubusercontent.com:aud": "sts.amazonaws.com" },
      "StringLike": {
        "token.actions.githubusercontent.com:sub": [
          "repo:__OWNER__/__REPO__:environment:dev",
          "repo:__OWNER__/__REPO__:environment:prod"
        ]
      }
    }
  }]
}
```

```bash
aws iam create-role --role-name __REPO__-ecr-push \
  --assume-role-policy-document file://trust-policy.json

aws iam put-role-policy --role-name __REPO__-ecr-push \
  --policy-name ecr-push --policy-document file://ecr-push-policy.json
```

`ecr-push-policy.json` (push to the one repo + auth token):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    { "Effect": "Allow", "Action": "ecr:GetAuthorizationToken", "Resource": "*" },
    { "Effect": "Allow",
      "Action": ["ecr:BatchCheckLayerAvailability","ecr:InitiateLayerUpload","ecr:UploadLayerPart","ecr:CompleteLayerUpload","ecr:PutImage","ecr:BatchGetImage","ecr:GetDownloadUrlForLayer"],
      "Resource": "arn:aws:ecr:__AWS_REGION__:__AWS_ACCOUNT_ID__:repository/__ECR_REPO__" }
  ]
}
```

Capture the role ARN — this is the `AWS_ROLE_TO_ASSUME` GitHub secret:
```bash
aws iam get-role --role-name __REPO__-ecr-push --query Role.Arn --output text
# arn:aws:iam::__AWS_ACCOUNT_ID__:role/__REPO__-ecr-push
```

### Verify before the first deploy
```bash
aws ecr describe-repositories --repository-names __ECR_REPO__ --region __AWS_REGION__   # repo exists
aws iam get-role-policy --role-name __REPO__-ecr-push --policy-name ecr-push            # inline policy attached
aws iam get-role --role-name __REPO__-ecr-push --query Role.AssumeRolePolicyDocument    # trust lists :environment:dev/prod
```
If the first deploy fails at "Configure AWS credentials" with `Not authorized to
perform sts:AssumeRoleWithWebIdentity`, the trust `sub` doesn't match — re-check
it uses the `:environment:` form (see the ⚠ box above / `pitfalls.md #3`), and that
the caller workflow declares `permissions: id-token: write` (`pitfalls.md #2`).

## Optional — share one role across several repos
You can reuse a single push role for multiple repos/images instead of one per
repo: add each repo's `:environment:*` subjects to the **same** trust policy
`sub` list, and widen the ECR resource ARN (or list several). The per-repo role
is the simpler default; share only when you're deliberately managing a fleet.

## Note on the same-host pull

Because the self-hosted runner is also the deploy host, the OIDC creds it
assumes are already valid for `docker pull` in the same job — no separate
server-side IAM user is needed (unlike the SSH-remote topology). The host only
needs Docker; ECR auth rides on the job's OIDC session via `amazon-ecr-login`.
