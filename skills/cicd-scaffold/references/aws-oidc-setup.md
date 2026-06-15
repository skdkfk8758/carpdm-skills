# AWS Setup — OIDC push role + ECR repo (AWS 계정/repo 당 한 번)

파이프라인은 static key 제로로 ECR 에 push 한다: GitHub 이 OIDC token 을 발급하고
AWS 가 이를 단명 role 로 교환한다. 첫 deploy run 전에 이를 셋업한다.

전제: IAM + ECR admin 권한 유저로 AWS CLI 인증됨
(`aws sts get-caller-identity` 작동). scratch 디렉토리에서 명령을 실행하고 두
`*.json` policy 파일을 거기 둔다. 모든 `__TOKEN__` 을 `scaffold.py` 에 먹인 것과 같은
값으로 치환한다(`__AWS_REGION__`, `__AWS_ACCOUNT_ID__`, `__ECR_REPO__`,
`__OWNER__`, `__REPO__`).

## 1. ECR repository

이미지 하나당 repo 하나(`__ECR_REPO__`):

```bash
aws ecr create-repository --repository-name __ECR_REPO__ --region __AWS_REGION__
```

## 2. GitHub OIDC identity provider (AWS 계정당 한 번)

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

이미 존재하면(다른 repo 가 셋업함) 건너뛴다 — 계정당 하나다.

## 3. Push role + trust policy

role 의 trust policy 는 이 repo 의 deploy subject 만 허용해야 한다 — `*` 가 아니라.
`*` 면 어떤 repo 든 이를 assume 할 수 있게 된다.

> ⚠ **`sub` claim 은 `environment:` 에 좌우된다.** `deploy.yml` 의 deploy job 이
> `environment: <dev|prod>` 를 선언한다. job 이 environment 를 참조하면 GitHub 은
> OIDC `sub` claim 을 `repo:OWNER/REPO:environment:<name>` 로 설정한다 —
> `:ref:refs/heads/...` 가 **아니다**. 그러니 trust 를 브랜치/태그 ref 가 아니라
> **environments** 에 scope 하거나, 안 그러면 `sts:AssumeRoleWithWebIdentity` 가
> "Not authorized" 로 실패한다. (deploy job 이 `environment:` 를 안 썼다면 대신
> `:ref:refs/heads/develop` / `:ref:refs/tags/v*` 형태를 쓴다.)

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

`ecr-push-policy.json` (repo 하나로 push + auth token):
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

role ARN 을 받아둔다 — 이것이 `AWS_ROLE_TO_ASSUME` GitHub secret 이다:
```bash
aws iam get-role --role-name __REPO__-ecr-push --query Role.Arn --output text
# arn:aws:iam::__AWS_ACCOUNT_ID__:role/__REPO__-ecr-push
```

### 첫 deploy 전 검증
```bash
aws ecr describe-repositories --repository-names __ECR_REPO__ --region __AWS_REGION__   # repo exists
aws iam get-role-policy --role-name __REPO__-ecr-push --policy-name ecr-push            # inline policy attached
aws iam get-role --role-name __REPO__-ecr-push --query Role.AssumeRolePolicyDocument    # trust lists :environment:dev/prod
```
첫 deploy 가 "Configure AWS credentials" 에서 `Not authorized to perform
sts:AssumeRoleWithWebIdentity` 로 실패하면, trust 의 `sub` 가 안 맞는 것이다 —
`:environment:` 형태를 쓰는지(위 ⚠ 박스 / `pitfalls.md #3` 참조), 그리고 caller
워크플로가 `permissions: id-token: write` 를 선언하는지(`pitfalls.md #2`) 다시 확인한다.

## Optional — 여러 repo 가 role 하나를 공유

repo 마다 하나 대신 단일 push role 을 여러 repo/이미지에 재사용할 수 있다: 각 repo 의
`:environment:*` subject 를 **같은** trust policy `sub` 리스트에 추가하고, ECR
resource ARN 을 넓힌다(또는 여러 개 나열). 기본은 per-repo role 이 더 단순하다 —
fleet 을 의도적으로 관리할 때만 공유한다.

## same-host pull 에 관한 노트

self-hosted runner 가 deploy host 를 겸하므로, 이것이 assume 하는 OIDC creds 는 같은
job 에서 `docker pull` 에 이미 유효하다 — 별도 server-side IAM user 가 필요 없다
(SSH-remote topology 와 달리). host 는 Docker 만 있으면 되고, ECR auth 는
`amazon-ecr-login` 을 통해 job 의 OIDC session 에 얹혀 간다.
