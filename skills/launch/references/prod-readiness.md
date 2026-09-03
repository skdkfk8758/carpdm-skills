# prod 환경 준비도 — 점검 · 가이드 · connect (launch Step 0 · setup 보고 · connect 모드 공용)

> 배선(pipeline wiring)이 있어도 **prod 환경**이 없으면 릴리즈는 MR 머지에서 끝나고 아무것도 뜨지 않는다.
> 이 파일은 그 환경이 어디까지 있는지를 **명령으로** 판정하고(§1), 없는 것을 어디서 어떤 순서로 만드는지
> 안내하고(§2), 다 갖춰졌을 때 배선과 환경을 잇는다(§3). EKS 자체를 만드는 것은 여전히 스킬 밖이다
> (`DevOps/infra` Terraform · ADR 0006 — 아직 "문서만, apply 없음") — 여기서는 **판정과 안내**만 한다.

## 0. 3-상태 판정 — 추측 PASS 금지

| 상태 | 뜻 |
|---|---|
| **PASS** | 아래 명령 출력이 조건을 충족한다 |
| **FAIL** | 명령이 "없음/불일치" 를 돌려줬다 |
| **확인필요** | 로컬에서 판정 불가(자격 없음·네트워크 밖·컨텍스트 부재) — 사람에게 넘긴다 |

컨텍스트가 없으면 그 아래 항목은 전부 **확인필요**다(FAIL 아님 — 없다는 증거가 아니라 볼 수 없다는 뜻).
표는 항목 순서대로 의존이 걸려 있어 위가 FAIL 이면 아래는 판정하지 않고 `—` 로 둔다.

## 1. 점검 표 — Step 0 이 그대로 출력한다

값의 출처: `.gitlab-ci.yml variables:`(`PROD_KUBE_CONTEXT`·`PROD_ARGO_APP`·`PROD_GITOPS_PATH`·`PROD_HEALTH_URL`) ·
`DevOps/infra` `gitops/prod/…`(로컬 `~/Workspace/infra` 또는 clone) · setup 인터뷰의 repoURL.
`CTX="--context $PROD_KUBE_CONTEXT"` 로 줄인다.

| # | 항목 | 판정 명령 | PASS 조건 |
|---|---|---|---|
| 1 | kube context | `kubectl config get-contexts -o name \| grep -x "$PROD_KUBE_CONTEXT"` · `kubectl $CTX get ns >/dev/null` | 이름 존재 + API 응답. 변수 빈칸이면 **FAIL(미설정)** |
| 2 | Argo CD 설치 | `kubectl $CTX -n argocd get deploy argocd-server -o name` | 출력 있음 |
| 3 | root app → prod 경로 | `kubectl $CTX -n argocd get applications.argoproj.io -o jsonpath='{range .items[*]}{.spec.source.path}{"\n"}{end}' \| grep -x gitops/prod/bootstrap/applications` | 한 줄 매치 |
| 4 | repo credential | `kubectl $CTX -n argocd get secret -l argocd.argoproj.io/secret-type=repository -o jsonpath='{range .items[*]}{.data.url}{"\n"}{end}' \| base64 -d` | setup 의 repoURL 포함 |
| 5 | AppProject | `kubectl $CTX -n argocd get appprojects.argoproj.io <prod-project> -o name` | 출력 있음(이름은 setup §2b 파생 규칙) |
| 6 | Application | `kubectl $CTX -n argocd get applications.argoproj.io "$PROD_ARGO_APP" -o jsonpath='{.status.sync.status}/{.status.health.status}'` | `Synced/Healthy`. 변수 빈칸이면 FAIL(미설정) |
| 7 | imagePullSecret | `kubectl $CTX -n <ns> get secret ecr-pull -o name` · `kubectl $CTX get cronjob -A \| grep ecr-token-refresh` | Secret + 갱신 CronJob 둘 다 |
| 8 | 앱 Secret | prod 매니페스트의 `secretRef`/`secretKeyRef` 이름을 뽑아 `kubectl $CTX -n <ns> get secret <name> -o name` | 참조된 전부 존재 |
| 9 | 데이터 도달성 | ConfigMap/Secret 의 DB·외부 호스트를 뽑아 **목록만** — 로컬에서 probe 하지 않는다 | 항상 **확인필요** + 호스트 목록. 온프렘 주소(`192.168.*`·`*.ts.net`·NAS)면 "EKS 에서 도달 경로 없음 — 결정 필요" 명시 |
| 10 | health URL | `PROD_HEALTH_URL` 비어 있지 않고 `dig +short <host>` 응답 | DNS 해석. 200 여부는 릴리즈 Step 5 의 일 |

출력 형식(고정 — 카드 안 그대로):

```
prod 준비도 — apps/<svc>   (7/10 PASS · 2 FAIL · 1 확인필요)
 1 kube context        PASS  eks-prod
 2 Argo CD             PASS  argocd-server 1/1
 3 root app→prod       FAIL  gitops/prod/bootstrap/applications 를 가리키는 Application 없음
 4 repo credential     —
 …
 9 데이터 도달성       확인필요  DATABASE_URL host 192.168.0.194 (온프렘 NAS) — EKS 도달 경로 없음
10 health URL          FAIL  PROD_HEALTH_URL 미설정
```

## 2. 미충족 항목 가이드 — 어디서, 어떤 순서로

setup 보고 끝(§4 체크리스트 위)과 release 보고의 `## ⚠ 미검증` 에 **FAIL·확인필요 항목만** 붙인다.
전부 PASS 면 이 절은 출력하지 않는다. 항목마다 "누가·어디서" 한 줄 — 절차를 여기서 재기술하지 않는다
(온프렘 쪽 선례가 `DevOps/infra` 에 있고 그것이 SSOT 다).

| # | 만드는 곳 | 선례 / 결정 |
|---|---|---|
| 1 | EKS 클러스터 — `DevOps/infra` `infra/terraform/`(ADR 0006 Mode A). **apply 는 ADR 개정이 필요한 결정**(현재 "문서만") | 사용자·infra 트랙. 스킬은 여기서 멈춘다 |
| 2 | Argo CD — `gitops/prod/bootstrap/argocd/` 를 온프렘 `gitops/bootstrap/argocd/` 본떠(install manifest 버전 동일) → `kubectl $CTX apply -k` | ADR 0009 "bootstrap 은 GitOps 밖" — 수동 apply 1회 |
| 3 | root Application — `gitops/prod/bootstrap/root-application.yaml`(path `gitops/prod/bootstrap/applications`, selfHeal) → 수동 apply | 온프렘 `root-application.yaml` 동형 |
| 4 | repo credential Secret — ns argocd, `argocd.argoproj.io/secret-type=repository`, url=setup repoURL. **repo 밖 수동 생성물** | 온프렘 `repo-gitlab-devops-infra` 동형. GitHub 미러면 public 이라 자격 불필요, GitLab 직결이면 deploy token |
| 5 | AppProject — setup §2b 가 `gitops/prod/bootstrap/projects/appprojects.yaml` 에 만들었다. root app path 밖이라 **수동 apply** | 온프렘 규율 동일(`gitops/README.md`) |
| 6 | Application — setup §2b 가 만든 파일을 root app 이 sync 한다. 3 이 PASS 면 자동 | 없으면 3 을 먼저 |
| 7 | `ecr-pull` — ns 별 Secret + 8h 갱신 CronJob. EKS 면 **IRSA 로 대체 가능**(장기 키 불필요) — 선택은 사용자 | 온프렘 `ecr-credentials/ecr-token-refresh` 동형 or IRSA |
| 8 | 앱 Secret — Infisical **prod** env → `kubectl create secret … --from-env-file`(dev 의 `sync-secrets` 잡 동형) 또는 사람이 1회 | admap-mcp 는 사람 생성 방식(`docs/deploy.md`) |
| 9 | 데이터 경로 — 온프렘 DB 면 (a) VPN/Tailscale subnet router (b) DB 를 AWS 로 이전 (c) prod 전용 DB. **ADR 0006 은 "네트워크를 잇지 않는다"** 라 (a) 는 ADR 충돌 | 사용자 결정. 스킬은 세 갈래를 보여주고 묻지 않는다(범위 밖) |
| 10 | 도메인·엣지 — Route53(`adtype.biz`) 또는 Cloudflare, Ingress/ALB. 온프렘은 NPM 이었다 | `serving-architecture.md` 참조 · 결정 후 `PROD_HEALTH_URL` |

순서는 표 번호다 — 1→3 이 뼈대, 4·5 가 3 의 전제, 6 은 자동, 7·8 은 파드가 뜨기 위한 것, 9·10 은 트래픽.
사용자가 "다 됐다" 고 하면 §3 으로.

## 3. connect 모드 — 배선과 환경을 잇는다

진입: 배선 있음(`retag` 잡 + `PROD_GITOPS_PATH`) **그리고** `PROD_ARGO_APP` 또는 `PROD_KUBE_CONTEXT` 가 빈칸
**그리고** 사용자가 환경이 준비됐다고 말하거나(`연결해줘`·`EKS 됐어`·`connect`) §1 표에서 1~5 가 PASS.
release 모드에서 이 상태를 만나면 "connect 먼저" 를 제안하고 릴리즈는 계속한다(검증 skip — SKILL.md Step 0).

1. **준비도 재판정** — §1 표. 1~5 중 FAIL 이 있으면 connect 하지 않는다(§2 가이드만 출력).
   `PROD_KUBE_CONTEXT` 가 아직 빈칸이면 사용자가 말한 컨텍스트 이름으로 표를 돌린다(변수는 4 에서 채운다).
2. **첫 sync 확인** — root app 이 setup 의 Application 을 집었는지: 항목 6 이 `Synced/Healthy` 인가.
   **첫 sync 는 dev digest 로 뜬다**(setup 이 `image:` 줄을 dev 그대로 두었다) — 이것이 prod 환경의 smoke 다:
   같은 이미지가 dev 에서 도는 중이니 여기서 실패하면 환경 문제(Secret·pull·네트워크)다. `Degraded`/`OutOfSync`
   면 `kubectl $CTX -n <ns> get pods` + `describe` 첫 실패 파드를 보고서에 붙이고 멈춘다.
3. **health** — `PROD_HEALTH_URL` 후보(사용자 입력)로 `curl -sS -o /dev/null -w '%{http_code}'` 200. 도메인이
   아직 없으면 `kubectl $CTX -n <ns> port-forward svc/<svc> …` 로 `/healthz` 만 확인하고 URL 은 빈칸 유지.
4. **CI 변수 3개 채우기** — `.gitlab-ci.yml variables:` 의 `PROD_KUBE_CONTEXT`·`PROD_ARGO_APP`·`PROD_HEALTH_URL`.
   릴리즈 라인은 protected 라 **MR**(브랜치 `chore/launch-connect`) — setup §2a 와 같은 규율. **승인 1회**(외부 write).
   MR 머지는 사용자(또는 승인에 포함시켜 API 머지).
5. **보고** — 준비도 표(전부 PASS) + Application 상태 + MR URL + `result:`:

```
🔌 launch connect — apps/<svc>
────────────────────────
준비도    10/10 PASS
Argo      apps-prod-<svc> Synced/Healthy @ <sha>  (dev digest develop-<sha> — 첫 sync smoke)
health    200 https://<svc>.<domain>/healthz          ← 또는 "port-forward /healthz ok · 도메인 미정"
CI 변수   MR !NN chore/launch-connect → <line>        (머지 대기)

▶ 다음 단계
  잔여   없음
  필수   MR !NN 머지 → 첫 릴리즈 /launch (dev digest 를 vX.Y.Z 로 바꾸는 첫 promote)
  권장   없음

result: launch connect apps/<svc> — 준비도 10/10, Argo Synced/Healthy(dev digest smoke), CI 변수 MR !NN · 다음은 /launch
```

connect 는 코드를 배포하지 않는다 — 이미 root app 이 올린 dev digest 를 **확인**하고 변수를 채울 뿐이다.
그래서 승인 게이트는 MR 1회다.
