---
name: cicd-scaffold
description: >-
  Node 앱용 GitHub Actions 배포 워크플로(.github/workflows/)를 GENERATE 할 때
  쓴다 — 사용자가 CI/CD 또는 배포 파이프라인을 set up, build, scaffold, wire up
  하려 할 때이며, 기존 것을 디버그하려는 게 아닐 때. 타깃 형상: develop push 가
  dev 에 자동 배포, 버전 태그가 prod 에 배포(수동 태그가 게이트; Pro/Team 이면
  Required-reviewers 승인 옵션), 이미지는 AWS ECR 로 build·push(주로 OIDC, 정적
  키 없음), self-hosted runner 에서 실행(GitHub-hosted 분 0). 단일 repo 또는
  monorepo(api + web); Next.js, Express 등 Node. 사용자가 그 형상에 맞는 배포
  자동화를 만들어 달라고 할 때마다 트리거 — 부분적이어도, "CI/CD" 라는 말을 안
  써도: "build the github actions to deploy to dev and prod", "ship to prod on a
  tag and dev on develop", "continuous deployment with ECR and a self-hosted
  runner". build/test 명령과 포트를 탐지하고, AWS/GitHub 공백을 채운 뒤,
  워크플로·(없으면)Dockerfile·셋업 체크리스트를 쓴다. 기존 파이프라인 디버그,
  standalone Dockerfile·배포 스크립트 단독 작성, Terraform/IAM 단독 프로비저닝
  에는 쓰지 말 것.
---

# cicd-scaffold — self-hosted runner + ECR 용 GitHub Actions CI/CD

Node 프로젝트에 trunk-based CI/CD 파이프라인을 scaffold 한다. 토폴로지는 고정이다
(self-hosted runner + ECR + OIDC, 같은 호스트가 build/push/run) — 불변식을 이해하려면
`references/topology.md` 를, 템플릿이 이미 방어하는 다섯 가지 운영 발견 함정을 이해하려면
`references/pitfalls.md` 를 읽어라(가드를 벗겨내거나 잘못 디버그하지 않도록). 그런 다음 아래
단계를 따른다. 할 일은: **프로젝트가 이미 알려주는 것을 탐지 → 공백만 인터뷰 → 토큰 치환 →
GitHub+AWS 셋업을 상세히 안내 → 안전한 첫 배포 가이드.**

값을 발명하지 마라. repo 에서 탐지할 수 없는 것은 물어라. AWS 리전이나 포트가 틀리면
파이프라인이 조용히 깨지므로 추측하지 말고 확인하라.

## 무엇이 생성되나

`<project>/.github/workflows/` 안으로:
- `ci.yml` — PR 게이트 + 재사용 test job (build / typecheck / test)
- `deploy.yml` — 재사용 deploy SSOT (OIDC → ECR push → 같은 호스트 pull + run)
- `deploy-dev.yml` — develop push → dev 배포 (continuous)
- `release.yml` — v* 태그 → prod 배포 (수동 태그 = 게이트) + GitHub Release
- `audit.yml` — 주간 npm audit (선택)

추가로, 프로젝트에 Dockerfile 이 없으면 `scaffold.py --gen-dockerfile` 가 템플릿에서 하나
생성한다. 컨테이너는 `deploy.yml` 이 인라인으로 실행한다
(`docker run --env-file .env.production`) — 프로젝트가 여러 컨테이너를 돌리지 않는 한
docker-compose 는 없다(그러면 물어라).

## Step 1 — 프로젝트에서 탐지

사용자에게 무엇이든 묻기 전에 다음을 읽고 채울 수 있는 만큼 채운다:

| 무엇 | 어디서 | Token |
|---|---|---|
| Package manager / Node | `package.json`, lockfile | (npm 가정) |
| Build 명령 | `package.json` scripts (`build`, `typecheck`) | `__BUILD_CMD__` |
| Test 명령 | `package.json` scripts (`test`) | `__TEST_CMD__` |
| Monorepo? api workspace | `package.json` `workspaces`, `apps/`, `packages/` | `__API_BUILD_CMD__` |
| Private npm scope | `.npmrc`, `package.json` 의 `@scope/` deps | `__PRIVATE_NPM_SCOPE__` |
| Dockerfile 경로 | `Dockerfile*` | `__DOCKERFILE__` |
| 컨테이너 포트 | Dockerfile `EXPOSE`, 프레임워크 기본값 | `__CONTAINER_PORT__` |
| Start 명령 (Dockerfile 생성 시) | `package.json` `start`, 프레임워크 | `--start-cmd` |
| Repo + owner | `git remote -v` | `__OWNER__` `__REPO__` |
| App 이름 (컨테이너) | repo 이름 | `__APP_NAME__` |
| Trunk 브랜치 | `git branch`, default 브랜치 | (`develop` 가정; 확인) |
| DB migrations | `migrations/` 디렉토리 | (있을 때만) |

탐지한 것을 짧은 표로 사용자에게 되돌려 보여 정정할 수 있게 한다.

## Step 2 — 공백 인터뷰

이것들은 repo 에서 읽을 수 없다. 한 배치로 묻는다(옵션이 이산적이면 AskUserQuestion 사용):

- **AWS 리전** (`__AWS_REGION__`) — 예: `ap-northeast-2`
- **AWS 계정 ID** (`__AWS_ACCOUNT_ID__`) — 12자리, ECR 호스트 + trust policy 용
- **ECR repo 이름** (`__ECR_REPO__`) — 기본값은 app 이름; 확인
- **호스트 포트** (`__HOST_PORT__`) — 배포 호스트에 publish 되는 포트
- **dev/prod runner** — 같은 머신(라벨 2개)인가 두 머신인가? self-hosted runner 가 이미
  등록돼 있는가, 아니면 사용자가 셋업 단계를 필요로 하는가?
- **CI runner** (`--ci-runner`) — CI 와 GitHub-Release job 이 도는 곳.
  `self-hosted`(기본)는 dev/prod runner 위의 `node:20` 컨테이너에서 돌린다: **GitHub-hosted
  분 0** — 그래서 org 의 Actions 빌링이 정지돼도 파이프라인이 계속 돈다. 이는 runbook 의
  zero-billing 목표에 맞고 workspace-wipe 가드를 더한다(`pitfalls.md #4`/`#5`). `github` 는
  `ubuntu-latest` 에서 돌린다: 단순하고 격리되지만, 과금되고 빌링 정지 시 죽는다. 사용자가
  GitHub-hosted 격리를 특별히 원하고 빌링 여유가 있지 않은 한 `self-hosted` 를 기본으로 한다.
- **Build-time args** (`__BUILD_ARGS__`) — 프론트엔드 인라인 env (예: `VITE_API_BASE=/api`).
  대부분 백엔드는 비어 있음 — 그러면 deploy.yml 의 `build-args:` 블록을 지운다.

프로젝트에 private `@scope` 의존성이 없으면, GitHub Packages npm 단계(와 BuildKit
`github_token` secret)를 빼겠다고 사용자에게 말한다 — 안 쓰면 노이즈다.

## Step 3 — 해결된 값으로 scaffold.py 실행

YAML 을 손으로 복사·치환하지 마라 — `scripts/scaffold.py` 가 기계적 부분을 결정론적으로
한다: 템플릿 복사, 해당 없는 선택 블록 prune(private scope / api typecheck / build-args /
audit), 모든 토큰 치환, 올바른 exec-form Dockerfile `CMD` 구성, 그리고 `__TOKEN__` 이
하나라도 살아남으면 hard-fail. 너는 탐지·인터뷰한 값을 제공하고; 스크립트가 divergence 와
파일별 `sed` 추론을 제거한다.

```bash
python ~/.claude/skills/cicd-scaffold/scripts/scaffold.py --dest <project> \
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

Flag → 동작:
- `--ci-runner self-hosted`(기본) → ci.yml + release job 이 self-hosted runner 위의
  `node:20` 컨테이너에서 돌고, deploy.yml 에 workspace-wipe 단계가 들어간다(컨테이너 CI 가
  남긴 root-owned 파일, `pitfalls.md #4`). `github` → 둘 다 `ubuntu-latest` 에서 돌고
  wipe 단계는 빠진다.
- `--npm-scope` 있음 → GitHub Packages npm 단계 + BuildKit `github_token` secret 유지.
  생략 → 그 블록들 제거(죽은 auth 없음).
- `--api-build-cmd` 있음(그리고 `--no-api-build` 아님) → ci.yml "API typecheck" 유지.
  단일 패키지 → `--no-api-build` 전달.
- `--build-args` 있음 → deploy.yml 의 `build-args:` 블록 유지. 생략 → 제거.
- `--no-audit` → audit.yml 안 씀.
- `--gen-dockerfile` → 템플릿에서 Dockerfile 도 씀; `--start-cmd` 는 JSON exec-form 배열로
  split. 프로젝트에 이미 Dockerfile 이 있으면 이 flag 는 건너뛴다(build 단계가
  `--dockerfile` 로 그걸 참조).

스크립트는 쓴 파일들을 출력하고 no-token 가드를 확인한다. 남은 토큰으로 non-zero 종료하면
값을 빠뜨린 것이다 — 고치고 재실행한다(멱등).

## Step 4 — GitHub + AWS 셋업 (사용자가 막히는 부분)

파일들은 repo 밖 셋업 없이는 돌지 않고, 빠진 조각은 "X 를 빠뜨렸음" 대신 알 수 없는 에러로
실패한다. 여기가 철저해야 할 단계다 — 섹션별로 사용자를 안내하고, 가능하면 `gh`/`aws` 명령을
대신 실행하며 각 값이 무엇이고 어디서 찾는지 설명한다.

- `references/github-setup.md` — repo secret 2개(`AWS_ACCOUNT_ID`, `AWS_ROLE_TO_ASSUME`),
  `dev`/`prod` environment 와 각각의 `ENV_PRODUCTION` secret + `DEPLOY_ENABLED` var,
  self-hosted runner 라벨, 그리고 **prod 게이트 진실**: 수동 `v*` 태그가 게이트; Required
  reviewers 는 Pro/Team 전용 옵션 extra(Free + private → 422)이니, 유료 플랜이 아닌 한
  거기 의존하라고 사용자에게 말하지 마라. 복붙 체크리스트로 끝난다.
- `references/aws-oidc-setup.md` — ECR repo, 계정 전역 OIDC provider, 그리고 trust policy 가
  이 repo 의 **`:environment:` subject** 로 스코프된 push 역할(브랜치 ref 가 아님 —
  `pitfalls.md #3`), 그리고 검증 명령.

secret 값을 절대 지어내지 마라 — 사용자가 제공하게 하거나, 로컬 `.env` 파일에서
`ENV_PRODUCTION` 을 바로 파이프한다(`gh secret set ENV_PRODUCTION --env prod < ./.env.production`).

## Step 5 — 안전한 첫 배포 (cutover)

`DEPLOY_ENABLED` 는 unset 으로 시작하므로, 첫 develop push 는 build + ECR push 를 하되
컨테이너 run 은 건너뛴다(smoke test). 사용자에게 안내한다:

1. `develop` 에 머지, deploy-dev 관찰 → build+push green, ECR 이미지 존재 확인.
2. `gh variable set DEPLOY_ENABLED --env dev --body true` 설정.
3. 재트리거(empty commit 또는 re-run) → 컨테이너가 올라오는지 확인.
4. dev 가 검증되면 `v0.0.1` 태그로 prod 에 대해 반복.

## 브랜치 전략 정렬

이 파이프라인은 `~/.claude/rules-ondemand/branch-worktree-strategy.md` 의 trunk-based 전략을 가정한다:
`develop` 가 통합 trunk(dev 배포), `main`/태그가 release 라인(prod 배포). 프로젝트가 다른
브랜치 이름을 쓰면 deploy-dev.yml / release.yml 의 `on:` 트리거와 OIDC trust policy ref 를
맞춰 조정한다 — 그리고 불일치를 사용자에게 알린다.
