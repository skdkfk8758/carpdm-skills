# GitHub Setup — secrets, environments, runners (repo 당 한 번)

워크플로 토큰을 치환하는 것만으로는 부족하다 — 파이프라인은 이 파일 밖 설정들을
실행 시점에 읽고, 하나라도 빠지면 명확한 "X 를 빠뜨렸다" 대신 혼란스러운 에러로 run 이
실패한다. 사용자를 각 섹션 **순서대로** 안내한다. `gh` 로 할 수 있는 곳에서는 명령
실행을 제안하고, secret 값을 절대 지어내지 말 것 — 사용자에게 묻거나 로컬 파일에서 읽는다.

전제: 사용자가 `gh` 를 설치·인증(`gh auth status`)했고 repo 에 admin 권한이 있다.
아래 모든 `gh` 명령은 repo clone 안에서 실행되므로 `:owner/:repo` 가 자동 resolve 된다
— slug 를 입력할 필요 없다.

---

## 1. Repo-level secrets (2)

이들은 모든 environment 에서 동일하므로 repo level 에 둔다.

| secret | 무엇인가 | 어디서 얻나 |
|---|---|---|
| `AWS_ACCOUNT_ID` | 12자리 AWS 계정 번호 — `deploy.yml` 이 이걸로 ECR registry host `…<id>.dkr.ecr.<region>.amazonaws.com` 를 만든다 | AWS 콘솔 우상단 계정 메뉴, 또는 `aws sts get-caller-identity --query Account --output text` |
| `AWS_ROLE_TO_ASSUME` | OIDC push role 의 전체 ARN | `references/aws-oidc-setup.md` step 3 의 출력 — `arn:aws:iam::<id>:role/<repo>-ecr-push` |

```bash
gh secret set AWS_ACCOUNT_ID  --body 123456789012
gh secret set AWS_ROLE_TO_ASSUME --body arn:aws:iam::123456789012:role/myrepo-ecr-push
```

존재하는지 확인(값은 다시 보여주지 않음):
```bash
gh secret list
```

> `GITHUB_TOKEN` 은 만들지 **말 것** — Actions 가 매 run 자동 주입한다.

---

## 2. GitHub Environments — `dev` 와 `prod`

Environment 는 deploy 대상별로 secrets/vars 를 scope 하며 `deploy.yml` 의
`environment:` 키가 선택하는 대상이다. 둘 다 만든다:

```bash
gh api -X PUT repos/{owner}/{repo}/environments/dev
gh api -X PUT repos/{owner}/{repo}/environments/prod
```

### 2a. Per-environment secret — `ENV_PRODUCTION`

이것은 컨테이너가 실행되는 **`.env.production` 전체** 다. `deploy.yml` 이 이를 파일로
쓰고 `docker run --env-file` 로 넘긴다. dev 와 prod 는 각자 **자기** 값(다른 DB, 다른
secret)을 가지므로 두 번 설정한다:

```bash
# pipe the local env file straight in — no copy/paste, no value echoed
gh secret set ENV_PRODUCTION --env dev  < ./.env.dev
gh secret set ENV_PRODUCTION --env prod < ./.env.production
```

각 파일은 평범한 `KEY=value` 줄들이다, 예:
```
NODE_ENV=production
DATABASE_URL=postgres://user:pass@host:5432/mydb
SESSION_SECRET=…
```
> ⚠ 컨테이너가 이것들의 유일한 소비자다 — DB host/name 이 대상 environment 와
> 맞는지 확인할 것. (여기 `DB_NAME` 이 틀리면 CI 는 통과하지만 컨테이너가 부팅 시
> health check 에 실패한다.)

### 2b. Per-environment variable — `DEPLOY_ENABLED`

**variable**(secret 아님 — 민감하지 않고 gate step 이 `vars` context 로 읽는다).
`true` 면 컨테이너가 실제로 실행되고, unset 이면 build + ECR push 만(smoke test).
**첫 deploy 에서는 unset 으로 둔 채** 이미지가 ECR 에 안착하는지 확인하고, 그다음 켠다:

```bash
# first deploy: do NOT set it. After the smoke run is green:
gh variable set DEPLOY_ENABLED --env dev  --body true
gh variable set DEPLOY_ENABLED --env prod --body true
```

environment secrets/vars 확인:
```bash
gh secret list   --env prod
gh variable list --env prod
```

### 2c. prod gate — 각 plan 에서 실제로 얻는 것

prod gate 는 **수동 `v* tag`** 다: 사람이 의식적으로
`git tag -a v0.0.1 … && git push origin v0.0.1` 을 돌리지 않으면 아무것도 prod 에
도달하지 않는다. 그것이 진짜 안전장치이며 모든 plan 에서 작동한다.

**Required reviewers**(deploy job 을 *멈춰* 명시적 click-approval 을 받는 GitHub
Environment protection rule)는 그 위에 얹는 *선택적 추가물* 이다 — 단 **public repo
또는 GitHub Pro/Team/Enterprise** 가 필요하다. **Free plan 의 private repo** 에서는
API 가 거부한다:

```bash
# Only works on public repo OR Pro/Team. On Free+private this returns
# 422 "... is not available for your billing plan".
gh api -X PUT repos/{owner}/{repo}/environments/prod \
  -F 'reviewers[][type]=User' -F 'reviewers[][id]=<numeric-user-id>'
# (get <numeric-user-id> from:  gh api users/<login> --jq .id )
```

그러니 사용자에게 분명히 말한다: Free+private 에서는 태그가 gate 이고, reviewers 는
나중 업그레이드다. `dev` 는 reviewers 없이 둔다(continuous deploy). `references/pitfalls.md`
"Cross-plan limits" 참조.

---

## 3. Self-hosted runners — `dev` 와 `prod` 라벨

deploy host 가 GitHub Actions runner agent 를 돌린다. `deploy.yml` 은
`runs-on: [self-hosted, "${{ inputs.runner_label }}"]` 로 이를 타깃하므로, 각 runner 는
`self-hosted` 라벨 **에 더해** environment 라벨(`dev` 또는 `prod`)이 필요하다. 기본
`--ci-runner self-hosted` 에서는 CI 도 여기서(`dev` runner 에서) 돌므로, *어떤*
워크플로든 통과하려면 runner 가 먼저 있어야 한다.

runner 등록(host 당):
1. Repo → **Settings → Actions → Runners → New self-hosted runner**.
2. host 에서 표시된 `./config.sh` 를 실행한다. **labels** 를 물으면 `dev`
   (또는 `prod`)를 추가 — `self-hosted` 는 자동 추가된다.
3. 재부팅에도 살아남게 서비스로 설치: `sudo ./svc.sh install && sudo ./svc.sh start`.

host 요구사항:
- **Docker** 설치, runner 의 유저가 `docker` 그룹에 속함
  (`sudo usermod -aG docker $USER` 후 재로그인) — deploy job 이
  `docker build/push/run` 으로, (self-hosted CI 면) workspace wipe 를 위해
  `docker run` 으로 shell out 한다.
- `--ci-runner self-hosted` 의 경우: 그 외엔 없음 — CI 는 runner 가 pull 하는
  `node:20` 컨테이너 안에서 돈다.

dev 와 prod 는 **같은 머신**(runner agent 두 개, 다른 라벨)이거나 **두 머신**일 수
있다 — 워크플로는 신경 쓰지 않는다. 두 host 가 더 안전하다: self-hosted 는 SPOF
(`pitfalls.md #5`) 라, 한 host 가 다운되면 CI 와 그 deploy 가 함께 멈춘다.

runner 가 온라인인지 확인: Repo → Settings → Actions → Runners (녹색 "Idle"),
또는 `gh api repos/{owner}/{repo}/actions/runners --jq '.runners[]|{name,status,labels:[.labels[].name]}'`.

---

## 4. Limitation — server-side merge block 은 Free+private 에서 불가

GitHub Pro 없는 private repo 는 branch protection / required status checks 를
설정할 수 없다(API 가 403 반환). 그래서 **CI red 가 머지를 막을 수 없다** — advisory 다.
repo 가 public 이 되거나 Pro 가 되기 전까지 머지 규율은 사람 + 로컬 guard hook 에 달려
있다. `branch-worktree-strategy.md §8` 와 `pitfalls.md` "Cross-plan limits" 참조.

---

## Quick checklist

- [ ] `gh secret set AWS_ACCOUNT_ID`, `AWS_ROLE_TO_ASSUME` (repo level)
- [ ] `gh api -X PUT …/environments/dev` 와 `/prod`
- [ ] `ENV_PRODUCTION` 을 dev 와 prod environment **둘 다** 에 설정
- [ ] 첫 run 에서는 `DEPLOY_ENABLED` 를 **unset 으로 둠**(smoke 후 `true` 로 설정)
- [ ] self-hosted runner 가 `dev` / `prod` 라벨 + Docker 로 온라인
- [ ] (선택, Pro/Team 만) prod Required reviewers
- [ ] AWS 쪽 완료 — `references/aws-oidc-setup.md` 참조
