# Topology — 하이브리드 self-hosted runner + ECR (설계 불변식)

이 스킬이 스캐폴딩하는 파이프라인. 워크플로를 수정하기 전에 먼저 이해해서,
사소한 변경이 불변식을 조용히 깨뜨리지 않게 한다.

```
PR ───────────────▶ ci.yml          (gate: build / typecheck / test)
develop push ─────▶ deploy-dev.yml ─uses─▶ deploy.yml(env=dev, runner=dev)
                     continuous, no approval
v* tag push ──────▶ release.yml   ─uses─▶ deploy.yml(env=prod, runner=prod)
                     manual tag = the prod gate, then GitHub Release
                     (optional Required-reviewers approval needs Pro/Team)
```

deploy.yml (SSOT) 은 deploy host 를 겸하는 self-hosted runner 위에서 돈다:
`OIDC creds → ECR login → docker build+push → [DEPLOY_ENABLED] pull + docker run`.

## 불변식 — 깨지 말 것

- **재사용 deploy.yml 이 SSOT 다.** dev 와 prod 는 입력값(environment,
  runner_label, image_tag, extra_tag)만 다르다. deploy 로직을 복붙하지 않는다.
- **같은 host 가 build·push·run 을 한다.** runner 가 곧 deploy host 다. ECR 은
  버전/롤백 저장소이지 원격 박스로의 전송 수단이 아니다 — 그래서 SSH/SCP 가 없다.
  (사용자가 나중에 별도 deploy host 를 원하면 그게 SSH-remote variant 다 —
  이 스킬이 기본으로 생성하지 않는 다른 topology.)
- **OIDC, static key 제로.** runner 가 push role 을 assume 하고, 같은 OIDC
  session 이 same-host `docker pull` 을 authorize 한다. server IAM user 없음.
- **태그 정책.** prod 는 `latest`(롤백 대상)를 갱신하고, dev 는 `dev` 를 굴린다.
  dev 는 절대 `latest` 를 건드리면 안 된다.
- **DEPLOY_ENABLED 는 step-level gate 다.** environment-scoped var 는 step level
  에서만 resolve 되므로(GHA context 한계), run step 이 gate output 으로 이를 확인한다.
  build+push 는 항상 돌고, container run 만 gate 된다. unset = smoke.
- **.env.production SSOT = ENV_PRODUCTION secret**, environment 별로 scope 된다.
  서버에서 손으로 수정한 것은 다음 deploy 때 덮어써진다.
- **CI 가 deploy chain 을 통해 trunk 를 gate 한다.** deploy-dev/release 가 ci.yml 을
  자신의 `test` job 으로 호출하므로, PR 이 안 돌았어도 develop/tag push 는 여전히 gate 된다.

## CI runner — self-hosted (기본) vs github
CI 와 GitHub-Release job 은 self-hosted runner(`node:20` 컨테이너,
`--ci-runner self-hosted`) 또는 `ubuntu-latest`(`--ci-runner github`) 중
하나에서 돈다. self-hosted 가 기본인 이유는 이 topology 전체의 핵심이 **zero
GitHub-hosted minutes** 이기 때문이다 — 그러면 파이프라인이 Actions billing 중단에도
살아남는다(`pitfalls.md #5`). 대신 결과가 하나 따라온다: 컨테이너 CI 는 root 로 돌아
공유 workspace 에 root 소유 파일을 남기므로, deploy job 이 먼저 workspace 를 비운다
(`pitfalls.md #4`). `github` variant 는 더 단순/격리되지만 billed 다; 사용자가 billing
여유가 있고 GH-hosted CI 를 원할 때만 고른다.

## 선택 요소를 빼는 시점
- private `@scope` dep 없음 → "Configure npm for GitHub Packages" step 과
  BuildKit github_token secret 을 뺀다.
- 단일 패키지(monorepo 아님) → ci.yml "API typecheck" 를 뺀다.
- DB migration 없음 → migration 관련 생성물 없음(이 스킬은 기본적으로 생략 —
  프로젝트에 migration 이 있을 때만 migration-naming check 를 추가).
- audit.yml 은 선택적 가시성 — 원치 않으면 뺀다.
