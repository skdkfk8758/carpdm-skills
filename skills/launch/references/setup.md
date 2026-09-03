# Setup 모드 — 프로젝트에 릴리즈 배선을 붙인다 (launch 가 배선 부재를 감지했을 때)

> 목표는 하나다: 이 프로젝트가 **release 모드의 Step 0 판정을 통과**하게 만든다 —
> `.gitlab-ci.yml` 에 태그 규칙의 `retag`/`promote-prod` 잡 + `variables:` 설정 블록,
> `DevOps/infra` 에 `gitops/prod/apps/<svc>/` 경로. 배선을 만들고 **멈춘다**. 첫 릴리즈는
> 사용자가 다시 `/launch` 한다(SKILL.md §두 모드 — 배선 오류와 릴리즈 실패를 분리해서 보기 위해).

## 0. 발견 — 물을 것을 줄이기 위해 먼저 읽는다

인터뷰 항목의 절반은 repo 에 이미 있다. 읽고 나서 **못 읽은 것만** 묻는다.

| 항목 | 어디서 | 못 읽으면 |
|---|---|---|
| 서비스 이름 `<svc>` · 그룹 | `origin` 경로 `<group>/<svc>.git` 의 마지막 세그먼트(`apps/survey-radar`·`infra/admap-mcp` 둘 다 있다 — `apps/` 가정 금지) | 묻는다 |
| 릴리즈 라인 | 기존 `promote` 잡 `rules` 의 `$CI_COMMIT_BRANCH == "…"` (mentalmarket=main, admap-mcp/review/survey=develop) | 묻는다 |
| 이미지 목록 | `variables:` 의 `IMAGE*: "$ECR_REGISTRY/apps/…"` | 묻는다 |
| dev 매니페스트 · AppProject · ns | `DevOps/infra` `gitops/apps/<svc>/` + `gitops/bootstrap/applications/apps-<svc>.yaml` 의 `spec.project`·`destination.namespace`(`apps-dev`/`survey-radar` 도, `apps-internal`/`internal-admap-mcp` 도 있다) | 매니페스트 없으면 dev 배선부터 — setup 범위 밖, 멈춘다 |
| health 경로 | dev deployment 의 `readinessProbe.httpGet.path` | health 검증 미설정으로 둔다 |
| `GITOPS_PUSH_TOKEN` | API `GET /projects/:id/variables` key 목록 | 없으면 체크리스트에 [HUMAN] |
| 기존 태그 규칙 잡 | `.gitlab-ci.yml` 에 `$CI_COMMIT_TAG` grep | 있으면 충돌 — 그 잡을 보여주고 멈춘다(덮어쓰지 않는다) |
| protected tag · 변수 protected 여부 | API `GET /projects/:id/protected_tags` · `GET /projects/:id/variables` 의 `protected` 필드 | §2c 로 — API 없으면 [HUMAN] 첫 줄 |

GitLab API 는 `references/gitlab-access.md` 로 연다. API 없이도 파일 생성은 되지만 protected tag·
변수 확인이 빠지므로 체크리스트에 `[HUMAN]` 으로 남긴다.

## 1. 인터뷰 — `AskUserQuestion` 1회, 못 읽은 것만

한 번에 최대 4문. 발견에서 채운 값은 **확인 문구로만** 보여준다(다시 묻지 않는다).

- **릴리즈 라인** (읽었으면 확인만): main / develop. 이 라인 커밋에만 태그가 붙는다.
- **prod 경로**: 기본 `gitops/prod/apps/<svc>` — 온프렘 root app 의 path(`gitops/bootstrap/applications`
  · `gitops/apps/*`) 밖이라 온프렘 Argo 가 건드리지 않는다. 다른 위치를 원할 때만 바꾼다.
- **prod namespace**: 기본 = dev Application 의 `destination.namespace` 그대로(별도 클러스터라 충돌 없음). 다르게 하려면 여기서.
- **AWS Argo 가 infra 를 읽을 URL**: GitHub 미러(`https://github.com/Team-DrafType/DevOps.git`, 공개 경로,
  push mirror 지연 수분) / GitLab 직결(CF Access 뒤라 AWS 에서 자격 필요). 미정이면 GitHub 미러를 기본으로
  쓰고 Application 주석에 남긴다 — EKS 가 서는 날 바꿀 수 있는 한 줄이다.
- **prod health URL**: 도메인이 아직 없으면 빈칸 — 검증은 EKS 뒤 CI 변수로 켠다.

프로젝트에 서비스가 여러 이미지(mentalmarket api+web)면 `IMAGES` 에 나열하고, prod 매니페스트에
그 이미지 줄이 각각 있는지 §3 에서 확인한다.

## 2. 산출 — 두 repo 에 MR 하나씩 (write 는 승인 뒤)

플랜을 보여주고 **승인 1회** 뒤 실행한다. 두 MR 은 독립이다 — infra 쪽이 먼저 머지돼야 첫 릴리즈의
`promote-prod` 가 경로를 찾는다(잡이 `test -d` 로 확인하고 없으면 그렇게 말한다).

### 2a. 앱 repo — `.gitlab-ci.yml` 에 release 잡 병합

`assets/gitlab-ci-release.yml` 을 읽어 **현재 파일에 병합**한다(덧붙이기가 아니라):

- `variables:` 블록에 `RELEASE_LINE`·`IMAGES`·`PROD_GITOPS_PATH`·`PROD_HEALTH_URL`·`PROD_ARGO_APP`·
  `PROD_KUBE_CONTEXT` 6개를 인터뷰 값으로 채워 **기존 variables 에 추가**(기존 키는 보존).
- `.release-rules` 앵커 + `retag` + `promote-prod` 잡을 파일 끝에 추가. `stages` 에 `deploy` 가
  이미 있으니 그대로 쓴다(없으면 추가).
- **기존 잡의 rules 를 점검한다** — `test`/`build`/`promote` 가 `$CI_COMMIT_BRANCH == …` 만 보면 태그
  파이프라인에선 자동으로 빠진다(태그 push 시 `CI_COMMIT_BRANCH` 는 비어 있다). `rules` 없이
  `only/except` 도 없는 잡이 있으면 태그에서도 돌아버리니 `- if: $CI_COMMIT_TAG / when: never` 를
  맨 앞에 넣어 준다 — 재빌드 금지 원칙이 여기서 지켜진다.
- 주석 헤더의 "흐름:" 줄에 `→ 태그 vX.Y.Z: retag → promote-prod` 를 한 줄 추가(파일 상단 주석이
  이 repo 들의 배선 문서다 — mentalmarket·admap-mcp 헤더 참조).

브랜치 `chore/launch-release-job` → push → MR(target = 릴리즈 라인). **직접 커밋하지 않는다**
(라인은 protected). MR 머지는 사용자(또는 사용자가 원하면 API 로 — 승인 게이트에 포함시켜 물었을
때만). CI 파일 변경은 MR 파이프라인이 lint 해 준다 — `yaml` 문법 오류는 여기서 잡힌다.

### 2b. `DevOps/infra` — prod 경로 + AWS Application

```
gitops/prod/apps/<svc>/            ← gitops/apps/<svc>/ 를 복사해 시작
  kustomization.yaml · deployment.yaml · service.yaml · networkpolicy.yaml …
gitops/prod/bootstrap/applications/apps-prod-<svc>.yaml   ← assets/argo-prod-application.yaml
gitops/prod/bootstrap/projects/appprojects.yaml            ← apps-prod AppProject (첫 서비스일 때만 생성)
```

복사 후 손볼 것 — diff 로 보여준다:

- dev 전용 리소스 제거: `devdb.yaml`, `dev-*` 참조, `platform-dev-pg` 의존(`DATABASE_URL` 은 prod Secret 이
  따로 있어야 한다 — 체크리스트 [HUMAN]).
- `image:` 줄은 **그대로 둔다**(dev digest). 첫 `promote-prod` 가 `vX.Y.Z@sha256:…` 로 바꾼다. 여기서
  미리 바꾸면 sed 패턴이 안 맞아 첫 릴리즈가 "digest unchanged" 로 빈다.
- namespace 를 인터뷰 값으로. `rbac-deployer.yaml` 이 있으면 SA 이름·ns 도.
- prod AppProject: dev Application 의 `spec.project` 를 본뜬다 — 이름은 `dev`→`prod` 치환(`apps-dev`→`apps-prod`),
  `dev` 가 없으면 `-prod` 접미(`apps-internal`→`apps-internal-prod`). `destinations.namespace` 는 이 서비스 ns 만,
  `sourceRepos` 는 인터뷰의 repoURL, cluster-scoped 금지(`clusterResourceWhitelist: []`) 는 dev 와 동일. 첫 서비스면
  `gitops/prod/bootstrap/projects/appprojects.yaml` 을 새로 만들고, 이미 있으면 그 파일에 project 를 추가한다.
  `assets/argo-prod-application.yaml` 의 `project:` 도 이 이름으로.

브랜치 `launch/<svc>-prod-path` → push → MR(target main). 이 MR 은 **머지돼도 아무것도 배포하지 않는다**
— 온프렘 Argo 는 `gitops/prod/` 를 보지 않고 AWS Argo 는 아직 없다. 그래서 setup 이 안전하다. MR
설명에 이 문장을 그대로 넣는다(리뷰어가 "이거 머지하면 뭐가 뜨나" 를 안 물어도 되게).

### 2c. protected tag `v*` — 선택이 아니라 **배선의 일부**

`POST /projects/:id/protected_tags {"name":"v*","create_access_level":40}`. 이미 있으면 통과.

이유는 편의가 아니다: `GITOPS_PUSH_TOKEN`(그리고 그룹의 AWS 자격)은 **protected 변수**라 protected
ref 의 파이프라인에만 주입된다(admap-mcp 실측 2026-09-03: protected tag 0개 + 변수 protected). `v*` 를
보호하지 않으면 태그 파이프라인의 `retag`/`promote-prod` 가 빈 토큰으로 죽는다 — 첫 릴리즈에서야 드러나는
함정이다. 그래서 API 가 없어 이 단계를 못 하면 setup 은 **미완**이고 체크리스트 첫 줄에 `[HUMAN] v* protected
tag 생성(없으면 릴리즈 파이프라인 변수 미주입)` 으로 올린다. 부수 효과로 Maintainer 만 `v*` 를 만들 수 있어
lightweight 태그 실수도 막힌다.

## 2d. prod 환경 준비도 판정 (write 아님)

배선 MR 을 만든 뒤 `references/prod-readiness.md` §1 표를 돌린다 — setup 이 환경을 만들지는 않지만 사용자가
"배선은 됐는데 다음에 뭘 해야 하나" 를 알아야 한다. FAIL·확인필요 항목에 §2 가이드를 붙여 §4 보고에 싣는다.
컨텍스트가 아직 없으면(보통 그렇다) 1 FAIL + 나머지 `—` 가 정상 출력이고, 가이드는 1 번(EKS)부터다.

## 3. 검증 — 배선이 "있다" 가 아니라 "맞다"

- **release 모드 Step 0 판정을 로컬에서 재현**: 병합된 `.gitlab-ci.yml` 에서 6개 변수를 다시 읽어
  값이 인터뷰와 같은지, `IMAGES` 의 각 repo 가 ECR 에 존재하는지(`aws ecr describe-repositories`),
  `PROD_GITOPS_PATH` 아래 각 이미지의 `image:` 줄이 **정확히 1개 파일에** 있는지(0 이면 sed 가 빈 손,
  2 이상이면 둘 다 바뀌는데 그게 의도인지 확인).
- **sed 패턴 dry-run**: prod deployment 를 임시 복사해 잡의 sed 를 가짜 digest 로 돌려 `image:` 줄만
  바뀌는지 `diff` 로 본다. 이걸 안 하면 첫 릴리즈에서야 패턴 불일치가 드러난다.
- **태그 파이프라인 시뮬레이션은 없다** — 태그를 밀지 않고는 못 돈다. 그래서 setup 은 여기서 멈추고
  첫 `/launch` 가 실검증이다. 그 사실을 보고에 쓴다.

## 4. 보고 — 체크리스트 + `result:`

```
🔧 launch setup — apps/<svc>
────────────────────────
앱 MR      apps/<svc> !NN   chore/launch-release-job → <line>     (머지 대기)
infra MR   DevOps/infra !NN launch/<svc>-prod-path → main          (머지 대기 · 배포 무영향)
protected  v* → Maintainer                                          (또는 [HUMAN] API 없음)
검증       변수 6/6 · ECR repo 2/2 · image 줄 1파일 · sed dry-run OK


prod 준비도 — 2/10 PASS · 7 FAIL · 1 확인필요          ← prod-readiness.md §1 표 그대로(10행)
 1 kube context   FAIL  PROD_KUBE_CONTEXT 미설정
 …
## prod 환경 준비 가이드                                  ← §2 표에서 FAIL·확인필요 행만
 1 EKS — DevOps/infra infra/terraform (ADR 0006 apply 결정 필요)
 …

[HUMAN] 남은 것
- 두 MR 머지 (infra 먼저)
- 위 준비 가이드 항목 해소 → `/launch` (connect 모드가 변수 3개를 채우고 첫 sync 를 확인한다)
- 첫 릴리즈: /launch  (여기서 태그 파이프라인이 처음 돈다 — 실검증)

result: launch setup apps/<svc> — 앱 MR !NN + infra MR !NN 생성, protected tag v*, 배선 검증 4/4 · 첫 릴리즈는 머지 후 /launch
```

`result:` 규격은 `~/.claude/references/craft/output-contract.md` L1. setup 은 산출물(MR)을 만들지만
L2 열기 블록(파일 경로)은 비적용 — MR URL 이 그 역할이다. L3 다음 스킬 제안도 없다 — 다음은 사람의
머지고, 그 뒤가 `/launch` 라는 건 체크리스트가 이미 말한다.
