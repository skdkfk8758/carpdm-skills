# Pitfalls — 운영에서 발견해 템플릿에 박아 넣은 함정

이 다섯 가지는 문서를 읽어서가 아니라 실제로 GitHub Actions 에서 파이프라인을
돌려봐야 드러났다. 이 스킬이 쓰는 템플릿은 이미 이것들을 피한다 — 이 파일은 각
가드가 *왜* 존재하는지 기록해서 나중 편집이 무심코 제거하지 않도록 하고, 손으로 수정한
파이프라인이 이 중 하나에 부딪혔을 때 빠르게 진단하게 한다. (출처: Intelligence-Auth
as-built runbook, `구축 중 잡은 함정`.)

## 1. workflow-level `env` 는 `secrets` 를 읽지 못한다

*workflow*(최상위) level 의 `env:` 블록은 `${{ secrets.* }}` 를 참조할 수 없다
— GitHub 은 어떤 step 도 실행되기 전에 `startup_failure` 로 run 을 거부한다. 그래서
`deploy.yml` 은 `ECR_IMAGE`(여기에 `secrets.AWS_ACCOUNT_ID` 가 interpolate 된다)를
workflow `env:` 가 아니라 **job** `env:` 아래에 둔다. secret 파생 env 는 job level 에 둔다.

## 2. 재사용 workflow 는 caller 의 permission 을 넘을 수 없다

`deploy.yml` 은 ECR 용 OIDC token 을 mint 하려면 `id-token: write` 가 필요하다.
하지만 재사용(`workflow_call`) workflow 는 **caller 의** 부여된 permission 에 의해
상한이 정해진다 — caller 가 가진 것보다 더 요청할 수 없다. 그래서 모든 caller
(`deploy-dev.yml`, `release.yml`) 자신이 `permissions: id-token: write` 를
선언해야 한다. 누락 시 증상: trust policy 가 올바른데도 `Error: Credentials could
not be loaded` / `Not authorized to perform sts:AssumeRoleWithWebIdentity`.

## 3. `environment:` 가 OIDC `sub` claim 을 다시 쓴다

job 이 `environment: <name>` 을 선언하는 순간, GitHub 은 OIDC token 의 `sub`
claim 을 `repo:OWNER/REPO:environment:<name>` 로 설정한다 — 브랜치에서 예상할 법한
`:ref:refs/heads/...` 형태가 **아니다**. `deploy.yml` 의 deploy job 이
`environment:` 를 쓰므로, AWS role trust policy 는 브랜치/태그 ref 가 아니라
`:environment:dev` / `:environment:prod` 에 매칭해야 한다. trust 를 대신 ref 에
scope 하면 `AssumeRoleWithWebIdentity` 가 "Not authorized" 로 실패한다.
(`references/aws-oidc-setup.md` 가 올바른 environment 기반 형태를 인코딩한다.)

## 4. 컨테이너 CI 가 공유 self-hosted workspace 에 root 소유 파일을 남긴다

**self-hosted CI** variant 에서만 문제가 된다. CI 가 self-hosted runner 위
`node:20` 컨테이너 안에서 돌 때 **root** 로 실행되어 runner 의 공유 workspace 디렉토리에
root 소유 `.next/` / `.git/` 를 쓴다. 다음 *host* job(non-root runner 유저로 도는
deploy job)이 checkout 의 `git clean` 에서 `Permission denied` 로 실패한다. 가드:
deploy job 의 첫 step 이 `actions/checkout` 전에 host `docker`(root) 로 workspace 를
비운다. `github` CI variant(ubuntu-latest) 는 ephemeral 이라 workspace 를 공유하지
않으므로 wipe step 이 없다 — 그래서 wipe 가 `ci-self-hosted` 선택 블록에 들어 있다.

## 5. GitHub-hosted runner 는 org billing 이 멈추면 죽는다

`ubuntu-latest` 는 GitHub-hosted runner 다 — billed minutes 이고, org 의 Actions
billing 이 정지되면(free-tier 소진, 카드 만료) 아예 시작하지 않는다. all-self-hosted
variant 는 그 의존성을 통째로 제거하려고 존재한다: zero GitHub-hosted minutes 라
billing 과 무관하게 CI 와 deploy 가 계속 돈다. 트레이드오프 — self-hosted 는 SPOF 다:
runner host 가 다운되면 CI *와* deploy 가 함께 멈춘다. 두 runner host(dev + prod) 가
최소한의 완화책이다.

## Cross-plan limits (버그 아님 — billing-tier 사실)

- **prod Required reviewers**(Environment protection)는 **public repo 또는
  GitHub Pro/Team/Enterprise** 가 필요하다. **Free plan 의 private repo** 에서는
  API 가 `422 ... billing plan` 을 반환한다. 그러면 사실상의 prod gate 는 **수동
  `v*` 태그** 다 — 사람이 의식적으로 태그를 끊지 않으면 아무것도 prod 에 도달하지 않는다.
- **Branch protection / required status checks** 도 같은 한계를 갖는다 →
  Free+private 에서는 CI red 가 **머지를 막을 수 없다**(advisory 일 뿐). 머지 규율은
  사람 + 로컬 guard hook 에 달려 있다. `branch-worktree-strategy.md §8` 참조.
