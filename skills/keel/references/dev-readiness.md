# dev 준비도 — 판정 · 안내 · 요청 문서 (keel Step 0 · Step 5 공용)

> 배선(MR 두 개)이 있어도 **환경**이 없으면 머지해도 아무것도 뜨지 않는다.
> 이 파일은 그 환경이 어디까지 있는지를 **명령으로** 판정하고(§1), 없는 것을 어디서
> 만드는지 안내하고(§2), 미충족이 있을 때 요청 문서를 어떤 형태로 내는지 정한다(§3).
> **환경을 만드는 것은 이 스킬 밖이다**(`DevOps/infra` 트랙) — 판정과 안내만 한다.

## 0. 3-상태 — 추측 PASS 금지

| 상태 | 뜻 |
|---|---|
| **PASS** | 아래 명령 출력이 조건을 충족한다 |
| **FAIL** | 명령이 "없음/불일치" 를 돌려줬다 |
| **확인필요** | 로컬에서 판정 불가(자격 없음·네트워크 밖·컨텍스트 부재) — 사람에게 넘긴다 |

컨텍스트가 없으면 그 아래 항목은 전부 **확인필요**다 — FAIL 이 아니다. 없다는 증거가
아니라 볼 수 없다는 뜻이다. 위가 FAIL 이면 아래는 판정하지 않고 `—` 로 둔다.

`CTX="--context on-prem-platform-admin"` 으로 줄인다. 기본 컨텍스트(`on-prem-viewer`)는
읽기도 일부 막히므로 명시한다.

## 1. 판정 표 — Step 0 이 그대로 출력한다

| # | 항목 | 판정 명령 | PASS 조건 |
|---|---|---|---|
| 1 | kube 컨텍스트 | `kubectl config get-contexts -o name \| grep -x on-prem-platform-admin` · `kubectl $CTX get ns >/dev/null` | 이름 존재 + API 응답 |
| 2 | Argo CD | `kubectl $CTX -n argocd get deploy argocd-server -o name` | 출력 있음 |
| 3 | AppProject | `kubectl $CTX -n argocd get appprojects.argoproj.io <APPPROJECT> -o name` | 출력 있음. 없으면 §2 |
| 4 | AppProject 의 destination | `kubectl $CTX -n argocd get appprojects.argoproj.io <APPPROJECT> -o jsonpath='{.spec.destinations[*].namespace}'` | 대상 ns 포함. **없으면 keel 이 MR 로 추가한다**(FAIL 아님, 산출물에 포함) |
| 5 | ECR 저장소 | `aws ecr describe-repositories --repository-names apps/<svc>` | 존재. 없으면 §2 (`infra/terraform/ecr` 의 `repositories` 목록에 한 줄) |
| 6 | ECR pull 자격 | `kubectl $CTX -n <NS> get secret ecr-pull -o name` · `kubectl $CTX get cronjob -A \| grep ecr-token-refresh` | Secret + 갱신 CronJob 둘 다. ns 가 새것이면 Secret 은 FAIL 이 정상이다 |
| 7 | 앱 Secret | 매니페스트의 `secretRef`/`secretKeyRef` 이름을 뽑아 `kubectl $CTX -n <NS> get secret <name> -o name` | 참조된 전부 존재. 외부 의존이 없다고 답했으면 이 항목은 `—` |
| 8 | 노드 여유 | `kubectl $CTX describe node \| grep -A6 "Allocated resources"` · `kubectl $CTX get nodes -o jsonpath='{.items[*].status.allocatable.pods}'` | 메모리 여유가 요청량의 3배 이상 **그리고** 파드 상한에 여유. 아래 주의 |
| 9 | GITOPS_PUSH_TOKEN | GitLab API `GET /projects/:id/variables` 의 key 목록 | 존재. 없으면 promote 잡이 빈 토큰으로 죽는다 |
| 10 | 데이터 도달성 | ConfigMap/Secret 의 DB·외부 호스트를 **목록만** 뽑는다 — probe 하지 않는다 | 항상 **확인필요** + 호스트 목록 |

**8번을 형식적으로 넘기지 않는다.** 파드 상한은 CPU·메모리가 남아도 먼저 닿는다 —
2026-09-03 실측에서 CPU 21%·메모리 24% 인 노드가 `Too many pods` 로 스케줄을 거부했다.
그리고 플랫폼 구성요소(관측·GitOps·에이전트)만으로 작은 노드의 메모리 87%가 찬 사례가
있다. 이 항목이 아슬아슬하면 FAIL 로 적고 요청 문서에 올린다.

출력 형식(고정):

```
dev 준비도 — <group>/<svc>   (7/10 PASS · 2 FAIL · 1 확인필요)
 1 kube 컨텍스트     PASS  on-prem-platform-admin
 2 Argo CD           PASS  argocd-server 1/1
 3 AppProject        FAIL  apps-internal 없음
 4 destination       —
 …
10 데이터 도달성     확인필요  DATABASE_URL host 192.168.0.194 — 클러스터에서 도달 확인 필요
```

## 2. 미충족 항목 — 어디서 만드나

항목마다 "누가·어디서" 한 줄. 절차를 여기서 재기술하지 않는다 —
`DevOps/infra` 가 SSOT 다.

| # | 만드는 곳 |
|---|---|
| 1·2 | 클러스터·Argo CD 부트스트랩 — `DevOps/infra` `gitops/bootstrap/`. 수동 apply(ADR 0009) |
| 3 | AppProject — `gitops/bootstrap/projects/appprojects.yaml`. root Application 이 없어 **수동 apply** |
| 5 | ECR 저장소 — `infra/terraform/ecr` 의 `repositories` 에 한 줄 + `terraform apply`. 사람 |
| 6 | `ecr-pull` — ns 별 Secret + 8h 갱신 CronJob. platform 선례 동형 |
| 7 | 앱 Secret — Infisical → `kubectl create secret … --from-env-file`. 값에 따옴표가 남지 않게 벗겨서 |
| 8 | 노드 여유 — 워크로드를 줄이거나 노드를 늘린다. 이 스킬 밖 |
| 9 | `GITOPS_PUSH_TOKEN` — `DevOps/infra` project access token(write_repository·Developer)을 프로젝트 CI 변수로 |
| 10 | 데이터 경로 — 사람 결정. 세 갈래(같은 클러스터 / 앱레벨 HTTPS / 전용 DB)를 보여주고 묻지 않는다 |

## 3. 요청 문서 — FAIL·확인필요가 있을 때만

전부 PASS 면 **만들지 않는다.** 볼 것 없는 문서를 쌓지 않는다.

경로: `docs/plans/<YYYY-MM-DD>-<svc>-dev-readiness-prompt.md`
수신자: **infra 세션이 그대로 붙여넣는 실행 계약**이다. 사람이 읽는 체크리스트가 아니다.

구성(`goal-prompt` 규격을 따르되 그 스킬을 호출하지 않는다):

- 페르소나 한 문단 — `DevOps/infra` 소유자, 정확성 > 속도, `apply` 는 사람
- Objective 한 줄
- Context — **실측 리터럴만**. 경로·명령 문자열·이름·SHA. "스크립트가 있다" 는 실패,
  "`pnpm verify` → exit 0" 이 정답
- **Success Criteria — 명령 + 기대 출력.** "정상 동작" 같은 표현 금지
- Constraints — 이번 판정에서 실제로 걸린 함정을 적는다
- Out of Scope — 이 요청이 아닌 것

**4000자 상한**을 지킨다(`LC_ALL=en_US.UTF-8 wc -m`). 넘으면 Context 의 실측 인용을
경로 포인터로 줄이되, 소비자가 다시 캐야 하는 리터럴(이름·태그·키)은 남긴다.
