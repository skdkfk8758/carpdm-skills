---
name: keel
description: 신규 프로젝트에 dev 배포 파이프라인을 깐다 — GitLab CI(test→build→promote)와 DevOps/infra 의 GitOps 배선(gitops/apps/<svc>/·Argo Application·AppProject)을 만들고 MR 두 개를 열고 멈춘다. "배포 붙여줘", "CI 세팅해줘", "이 프로젝트 배포 파이프라인 만들어줘", "dev 배포 되게 해줘", "새 서비스 온보딩", "GitOps 경로 만들어줘", "scaffold the deploy pipeline", "/keel" 에 — 'keel' 이란 말이 없어도 — 트리거. 이미 dev 배선이 있고 운영 릴리즈를 붙이려는 것이면 launch, PR 머지·로컬 동기화는 land, 스킬 레포 배포는 ship. 클러스터·AWS 계정 리소스는 만들지 않는다(DevOps/infra 트랙).
---

# Keel — 신규 프로젝트에 dev 배포 파이프라인을 깐다

조선 순서 그대로다: **keel(용골 부설) → `launch`(진수) → `ship`(출항).** `launch setup`
은 첫 화면에서 "dev 매니페스트 없으면 **dev 배선부터 — setup 범위 밖, 멈춘다**" 라고
선언한다. 그 멈춤을 받는 것이 이 스킬이다. 둘은 인접하고 겹치지 않는다.

**계약: 발견 → 인터뷰 1콜 → 플랜 → 승인 1회 → MR 두 개 → 멈춘다.** 머지하지 않고,
`kubectl apply` 도 `terraform apply` 도 하지 않는다. 배선 오류와 환경 오류를 분리해서
봐야 원인이 갈리기 때문이다(`launch` 가 같은 이유로 같은 선을 긋는다).

## 무엇을 묻고 무엇을 묻지 않는가 — 기준은 되돌리는 비용

되돌리기 비싼 값은 사실상 **namespace 하나**다. Secret 이름·모니터링 라벨·
NetworkPolicy·접속 URL·문서가 전부 거기 딸려간다. 나머지는 MR 에서 한 줄이면 고쳐진다.

그런데 "namespace 뭘로 할까요" 는 나쁜 질문이다. 사람이 답할 수 있는 것은 *누가
접근하나* 이고 ns·AppProject·Service 타입은 거기서 **파생**된다.

| 노출 등급 | namespace | AppProject | Service |
|---|---|---|---|
| **사내 전용** (tailnet·LAN) — 기본 | `internal-<svc>` | `apps-internal` | NodePort |
| 공개 서비스 — 명시 선택 | `<svc>` | `apps-dev` | ClusterIP + 엣지 |

**사내 전용이 기본인 이유**: 실수로 공개되는 것보다 실수로 닫히는 편이 싸다. 그리고
조직에 ns 관례가 둘 공존하는데(`apps-dev`/`survey-radar` vs `apps-internal`/
`internal-admap-mcp`) 스킬이 분산을 복제하면 신규 프로젝트마다 분산이 재생산된다.
하나를 기본으로 굳히고 다른 하나를 opt-in 으로 두면 시간이 갈수록 좁아진다.

`AskUserQuestion` **1콜 · 최대 3문항**. 이 상한을 넘으면 스킬이 아니라 폼이고, 폼이
되는 순간 아무도 안 쓴다.

1. **노출 등급** — 위 표. 나머지를 파생시킨다
2. **외부 의존** — DB·외부 API 가 있나. 있으면 Secret 참조와 `EXTERNAL_ALLOWED_HOSTS`
   골격을 넣고, 없으면 통째로 뺀다
3. **릴리즈 라인 확인** — `origin` 에서 읽었으면 확인만(`main`/`develop`)

**추정하고 보여준다 — 묻지 않는다.** 검증 게이트(`pyproject.toml`·`package.json`·
`go.mod`·`Cargo.toml` 감지) · `changes:` 목록(Dockerfile 의 `COPY` 경로 + lockfile 실측) ·
컨테이너 포트(`EXPOSE`) · health 경로(기본 `/healthz`) · 리소스 requests(기본
`50m`/`192Mi`). 전부 **플랜과 보고에 "추정" 으로 명시**한다 — 조용한 추정이 드리프트의
근원이고, MR 전이 교정이 가장 싼 구간이다.

**절대 묻지 않는다 — ADR 0006 규약이다.** ECR 경로 `apps/<svc>` · 태그
`<line>-<sha>` · digest pin · immutable · 환경 구분은 저장소가 아니라 태그 · promote 는
MR 로. 여기서 선택지를 주면 그게 곧 드리프트다.

## 안전 경계

| Action | 입장 |
|---|---|
| **절대 안 함** | MR 머지 · `kubectl apply` · `terraform apply` · 클러스터/AWS 계정 리소스 생성 · trunk 직접 push · 기존 `.gitlab-ci.yml` 잡 삭제 |
| **승인 1회 후** | 두 MR 생성(앱 repo · `DevOps/infra`) · 인프라 요청 문서 파일 쓰기 |
| **자유롭게** | 저장소 읽기 · `kubectl get` · GitLab API 읽기 · `kubectl kustomize` 렌더 · sed dry-run |

GitLab API 접근(PAT + port-forward)은 `launch/references/gitlab-access.md` 가 SSOT 다 —
복제하지 않고 그 파일을 읽는다.

## 파이프라인

### 0. Discover — 읽기 전용

- **repo·호스트**: `git remote get-url origin` 이 GitLab 인가. GitHub 만이면 멈춘다
  ("GitLab 이관 전 서비스는 범위 밖"). 프로젝트 경로는 `<group>/<svc>.git` **전체**를
  쓴다 — `apps/` 를 가정하지 않는다
- **이미 배선이 있나**: `.gitlab-ci.yml` 에 `kaniko`/`promote` 가 있으면 이 스킬은 할 일이
  없다 — `launch setup` 으로 라우팅하고 멈춘다
- **릴리즈 라인**: 기본 브랜치
- **스택**: 매니페스트 파일 감지 → 검증 명령 후보
- **Dockerfile**: `COPY` 경로 · `EXPOSE` 포트
- **infra 저장소**: `~/Workspace/infra` 또는 clone. `gitops/apps/<svc>/` 가 이미 있으면
  멈춘다(중복 생성 금지)
- **dev 준비도**: `references/dev-readiness.md` §1 표를 돌린다

### 1. Interview — 1콜

위 3문항. 발견에서 채운 값은 확인 문구로만 보인다.

### 2. Plan — 승인 게이트

한 블록으로 보인다: 서비스·라인·이미지 경로 · 노출 등급에서 파생된 ns/AppProject/
Service · **추정 목록**(검증 게이트·`changes:`·포트·health·리소스) · 만들 파일 목록 ·
준비도 표(FAIL 있으면) · 두 MR 의 제목과 대상 브랜치.

`AskUserQuestion` 1회 — 그대로 진행 / 추정값 수정 후 / 중단.

### 3. Emit — 승인 뒤 첫 write

- **앱 repo**: `assets/gitlab-ci-dev.yml` 을 현재 `.gitlab-ci.yml` 에 **병합**한다
  (덧붙이기가 아니라). 기존 파일이 없으면 그대로 쓴다. 브랜치
  `chore/keel-dev-pipeline` → MR(target = 릴리즈 라인)
- **`DevOps/infra`**: `assets/manifests/` 를 `gitops/apps/<svc>/` 로 채우고,
  `gitops/bootstrap/applications/apps-<svc>.yaml` 을 만들고, AppProject 의
  `destinations` 에 ns 를 더한다. 브랜치 `keel/<svc>-dev-path` → MR(target main)

`{{…}}` 자리표시자가 산출물에 남으면 실패다 — 쓰기 전에 grep 으로 확인한다.

### 4. Verify — MR 까지이므로 여기까지만 판정 가능하다

- `kubectl kustomize gitops/apps/<svc>` 가 렌더되고 객체 수가 기대와 같다
- 렌더 결과에 `{{` 가 없다
- `.gitlab-ci.yml` 이 YAML 로 파싱되고 잡 이름이 기대와 같다
- **promote 의 sed dry-run** — 가짜 digest 로 돌려 `image:` 줄만 바뀌는지 `diff` 로 본다.
  0줄이면 패턴 불일치, 예상보다 많으면 의도인지 확인한다
- `git diff --stat` + `git status --porcelain`

**파이프라인 실동작은 원리상 검증 불가하다.** 머지 전에는 돌지 않는다 — 그 사실을
보고에 쓴다. 지어내지 않는다.

### 5. 인프라 요청 문서 — 미충족이 있을 때만

`references/dev-readiness.md` §1 판정에서 **FAIL·확인필요가 하나라도 있으면**
`docs/plans/<날짜>-<svc>-dev-readiness-prompt.md` 를 쓴다. 전부 PASS 면 만들지 않는다 —
볼 것 없는 문서를 쌓지 않는다.

형태는 **infra 세션이 그대로 붙여넣는 실행 계약**이다: 페르소나 한 문단 · Objective ·
현재 상태(실측 리터럴) · **판정 가능한 SC**(명령 + 기대 출력) · 제약 · 범위 밖.
`goal-prompt` 의 규격을 따르되 그 스킬을 호출하지는 않는다 — 4000자 상한도 같이 지킨다.

### 6. Report

```
🔩 keel — <group>/<svc>
────────────────────────
앱 MR      <group>/<svc> !NN   chore/keel-dev-pipeline → <line>   (머지 대기)
infra MR   DevOps/infra !NN    keel/<svc>-dev-path → main          (머지 대기)
노출       사내 전용 · ns internal-<svc> · AppProject apps-internal · NodePort <port>
추정       검증 <명령> · changes: <N>개 · 포트 <p> · health <path> · requests 50m/192Mi
검증       kustomize <N>객체 · 자리표시자 0 · YAML ok · sed dry-run image 줄 <N>개

## ⚠ 준비도 미충족   (있을 때만 — 표 + 요청 문서 경로)

▶ 다음 단계
  잔여   없음
  필수   두 MR 머지(infra 먼저) → 첫 develop 파이프라인이 실검증이다
  권장   운영 릴리즈까지 붙이려면 `/launch` (setup 모드)
```

마지막 줄은 `result:` 1줄. 검증하지 못한 것을 한 것처럼 쓰지 않는다.

## 이 스킬이 틀린 선택일 때

- dev 배선이 이미 있고 **운영 릴리즈**를 붙이려는 것이면 → `launch` (setup 모드)
- PR 머지·로컬 동기화 → `land` · 스킬 레포 배포 → `ship`
- **클러스터·AWS 계정 리소스 자체**를 만들려는 것이면 → `DevOps/infra` 트랙
  (Terraform·ADR 0006). 이 스킬은 준비도를 판정하고 요청 문서를 낼 뿐 만들지 않는다
- GitHub 에만 있는 서비스 → 범위 밖. GitLab 이관이 선행이다

## 알려진 한계 — 이것을 모르고 쓰지 않는다

MR 에서 멈추므로 **파드가 실제로 뜬 뒤에야 드러나는 것을 구조적으로 못 본다.**
2026-09-03 admap-mcp 실측에서 나온 네 가지가 전부 그랬다 — 노드 파드 상한(`Too many
pods`, CPU·메모리는 20%대였다) · CNI 설정만으로는 안 오르는 `max-pods` · 다른 클러스터
base 에서 딸려온 nodeSelector · 플랫폼 구성요소만으로 노드 메모리 87%.

완화는 §5 준비도 판정의 "노드 여유" 항목뿐이고 그것도 사전 추정이다. 첫 배포에서
파드가 안 뜨면 배선이 아니라 환경을 먼저 본다.
