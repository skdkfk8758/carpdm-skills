---
name: launch
description: GitLab 에 호스팅된 서비스를 운영(prod)으로 릴리즈한다 — 마지막 태그 이후 머지분을 읽어 semver 버전·릴리즈 노트를 제안하고, 승인 1회 뒤 annotated 태그 push → GitLab Release → 태그 파이프라인(dev 검증 digest 재태깅 + `DevOps/infra` prod promote MR) 감시 → MR 자동 머지 → prod Argo sync·healthz 검증 → 실패 시 롤백 MR 제안까지 한 흐름으로 잇는다. 프로젝트에 릴리즈 배선(태그 `v*` 잡·prod gitops 경로)이 없으면 setup 모드로 전환해 인터뷰하며 `.gitlab-ci.yml` release 잡·infra prod 경로·protected tag 를 세팅하고, prod 환경(EKS·Argo·Secret) 준비도를 10항목 3-상태로 판정해 미충족 항목은 어디서 만드는지 가이드하며, 환경이 준비되면 connect 모드로 CI 변수를 채워 배선과 잇는다. "운영 배포해줘", "prod 릴리즈", "태그 따서 배포", "v1.4 로 릴리즈", "운영배포 세팅해줘", "이 서비스 릴리즈 파이프라인 붙여줘", "release to prod", "cut a release", "/launch" 에 — 'launch' 란 말이 없어도 — 트리거. dev 반영(develop push·promote MR 머지)은 land 가 끝낸 뒤 자동이라 launch 아님. GitHub 만 쓰는 repo 는 범위 밖(GitLab 이관 전엔 손배포). PR 머지·로컬 동기화는 land, 스킬 레포 배포는 ship.
---

# Launch — GitLab 태그 한 번으로 운영 릴리즈를 끝낸다

당신은 dev 까지는 자동이다: 브랜치 → PR/MR → `land` 로 머지 → develop 파이프라인이
이미지를 굽고 `DevOps/infra` 에 promote MR 을 열고 → Argo 가 dev 에 반영한다. 그런데
**운영 반영만 손으로 한다** — 버전을 고민하고, 태그 메시지를 즉흥으로 쓰고(스타일이
제각각: `v1.23.0 — …` / `release: …` / lightweight), 태그를 push 하고, 파이프라인을
눈으로 보고, MR 을 웹에서 머지하고, 됐는지 확인한다. 이 스킬은 그 손일을 **승인 1회짜리
파이프라인**으로 접는다.

계약은 `land` 와 같다: **읽기 전용 발견 → 플랜(버전·노트·대상) 제시 → 승인 1회 →
실행 → 검증 → 보고.** 태그는 immutable 하고 prod 반영은 되돌리기 비싸므로, 승인 전엔
어떤 write 도 하지 않고 승인 후엔 추측으로 진행하지 않는다.

**무엇을 배포하는가 = 이미 dev 에서 검증된 digest 다.** 태그 파이프라인은 다시 빌드하지
않는다 — 릴리즈 라인 커밋의 `<line>-<sha>` 이미지에 `vX.Y.Z` 태그를 덧붙이고(ECR
put-image, 같은 digest) 그 digest 를 prod gitops 경로에 pin 한다(ADR 0006 "dev 검증 후
prod 가 같은 digest 를 쓴다"). 그래서 **dev 이미지가 없는 커밋은 태그할 수 없다** — 릴리즈
라인에 push 되어 빌드가 끝난 커밋만 릴리즈 대상이다.

## 세 모드 — 배선(setup) · 환경 연결(connect) · 릴리즈(release)

Step 0 발견에서 판정한다. 한 세션에 섞지 않는다 — setup 은 배선을 만들고 **멈추고**, connect 는 환경과
배선을 잇고 **멈춘다**(첫 릴리즈는 사용자가 다시 `/launch`). 배선 직후 곧바로 태그까지 가면 배선 오류·환경
오류·릴리즈 실패가 한 덩어리로 나타나는데, 셋은 분리해서 봐야 원인이 갈린다.

| 판정 | 조건 | 다음 |
|---|---|---|
| **setup** | `.gitlab-ci.yml` 에 `$CI_COMMIT_TAG` 규칙 잡 또는 `PROD_GITOPS_PATH` 변수 없음, 또는 사용자가 "세팅/붙여줘" 명시 | `references/setup.md` (lazy-read) |
| **connect** | 배선 있음 + `PROD_ARGO_APP`/`PROD_KUBE_CONTEXT` 빈칸 + 사용자가 "환경 됐다/연결해줘" 또는 준비도 1~5 PASS | `references/prod-readiness.md` §3 (lazy-read) |
| **release** | 배선 있음 (환경 변수는 비어 있어도 된다 — 그땐 검증 skip 으로 진행하며 connect 를 권장한다) | §Release 파이프라인 |

**배선 ≠ 환경.** setup 은 CI 잡·infra 경로·protected tag 를 만들지만 EKS·Argo·Secret 은 만들지 않는다
(스킬 밖 — infra 트랙). 그 환경이 어디까지 있는지는 매 모드 Step 0 이 `references/prod-readiness.md` §1 의
**10 항목 3-상태 표**로 판정하고, 없는 것은 §2 가 어디서 만드는지 안내한다. "`PROD_ARGO_APP` 이 비어 있으니
미구축" 같은 대리 판정으로 끝내지 않는다.

## 안전 경계 — 무엇이든 하기 전에 읽을 것

| Action | 입장 |
|---|---|
| **절대 안 함** | 태그 이동·삭제·재push, force push, 빨간 파이프라인의 promote MR 머지, dirty/미push HEAD 태그, dev 이미지 없는 커밋 태그, `latest` 태그, prod 매니페스트 직접 `kubectl apply`, 롤백 MR 자동 머지 |
| **승인 1회 후 실행** (한 게이트가 아래 전부를 덮는다) | annotated 태그 생성+push, GitLab Release 생성, 태그 파이프라인의 promote MR 을 API 로 머지, Linear Release 생성·이슈 코멘트 |
| **별도 승인** | 롤백 MR 생성(자동 아님 — 제안 후 열기, 머지는 사람), setup 모드의 모든 write(CI 파일 MR·infra MR·protected tag) |
| **자유롭게 실행** | `git fetch/log/tag/describe`, GitLab API 읽기(MR·파이프라인·Release 조회), `kubectl get applications.argoproj.io`, healthz `curl`, Linear 읽기 |

> 공유 브랜치 force-push 금지·trunk 직접 push 금지의 SSOT = `~/.claude/rules-ondemand/branch-worktree-strategy.md` §3.
> GitOps 규율(digest pin·MR 만·머지=배포)은 `DevOps/infra` `CLAUDE.md` 가 SSOT — 이 스킬은 그 규율 위에서 promote MR 을 여는 쪽이지 우회하는 쪽이 아니다.

"태그 1회 승인 + MR 자동 머지" 는 사용자 결정(2026-09-03)이다 — 태그 승인이 곧 prod
결정이고, 그 뒤 MR 머지는 사람이 다시 볼 것이 없는 기계 단계(digest 한 줄)라 스킬이 API 로
머지한다. 단 **파이프라인이 green 이고 MR diff 가 기대한 이미지 한 줄만 바꿨을 때만**이다.
diff 에 다른 파일이 섞였거나 digest 가 태그 파이프라인이 찍은 값과 다르면 머지하지 않고 멈춘다.

## GitLab 접근 — 태그는 SSH, 나머지는 API

태그 push 는 `origin`(tailnet SSH, NodePort 30022)으로 바로 된다. 파이프라인 상태·MR 머지·
Release 생성은 API 가 필요한데, 웹 `gitlab.draftype.work` 는 Cloudflare Access 뒤라 토큰만으론
안 뚫린다. 경로는 **PAT + `kubectl port-forward`** 하나다 — 열기·닫기·호출 카탈로그·PAT 부재 시
안내는 `references/gitlab-access.md` (lazy-read — Step 0 에서 읽는다).

API 가 안 열리면 release 모드는 **진행하지 않는다**. 태그만 SSH 로 밀고 나면 MR 머지·검증이
사람 손으로 돌아가 이 스킬의 존재 이유가 사라지고, 반쯤 자동화된 릴리즈가 가장 헷갈린다.
PAT 발급 안내를 내고 멈춘다.

## Release 파이프라인

### 0. Discover — 읽기 전용

한 화면에 모은다. 하나라도 빠지면 플랜을 내지 않는다.

- **repo·호스트**: `git remote get-url origin` 이 GitLab(`seungman.tailc0ab05.ts.net` / `gitlab.draftype.work`)인가.
  GitHub 만이면 멈춘다 — "GitLab 이관 전 서비스는 launch 범위 밖" 한 줄과 함께. 프로젝트 경로는 origin 의
  `<group>/<svc>.git` **전체**를 쓴다(`apps/survey-radar` 도 `infra/admap-mcp` 도 있다 — `apps/` 를 가정하지 않는다).
  `<svc>` = 마지막 세그먼트, API id 조회는 전체 경로 URL-encode.
- **배선**: `.gitlab-ci.yml` 의 `variables:` 에서 `RELEASE_LINE`(main/develop) · `IMAGES`(ECR repo 목록) ·
  `PROD_GITOPS_PATH` · `PROD_HEALTH_URL`(없을 수 있음) · `PROD_ARGO_APP`(없을 수 있음) 을 읽는다.
  이 변수 블록이 프로젝트별 설정의 **유일한 자리**다(별도 config 파일 없음 — setup 이 여기 쓴다).
- **HEAD**: 현재 브랜치 == `RELEASE_LINE`, working tree clean, `HEAD == origin/<line>`(fetch 후).
  아니면 멈춘다 — 릴리즈는 원격이 아는 커밋에만 건다.
- **dev 이미지(= 배포될 digest)**: HEAD 부터 `git rev-list --max-count=50 HEAD` 를 거슬러 `IMAGES` 첫 repo 에
  `<RELEASE_LINE>-<sha>` 태그가 있는 첫 커밋을 찾는다(`aws ecr describe-images … imageTag=…`). **HEAD 에 없는 게
  정상일 수 있다** — build 잡은 `changes:`(Dockerfile·src·lock) 규칙으로 docs-only 커밋을 건너뛴다(admap-mcp 실측:
  origin/develop HEAD 에 이미지 없음). 그 규칙이 "마지막 빌드 이후 소스 변경 0" 을 보장하므로 마지막 빌드 커밋의
  digest 가 곧 현재 소스다 — 태그 파이프라인의 `retag` 도 같은 규칙으로 찾는다. 플랜에 "이미지 커밋 <sha>
  (HEAD 에서 N 커밋 전, 건너뛴 커밋은 전부 docs/ci)" 로 적는다. 건너뛴 커밋에 `src/`·`Dockerfile` 변경이 있으면
  build 가 실패했거나 아직 도는 중이다 — 파이프라인 URL 과 함께 멈춘다. 50 커밋 안에 없으면 멈춘다.
- **마지막 태그**: `git describe --tags --abbrev=0 --match 'v*'`. 없으면 첫 릴리즈(→ `v0.1.0` 제안).
- **머지분**: `git log <last>..HEAD --no-merges --format='%h %s'` + 그 범위 MR 목록(API,
  `merge_requests?state=merged&target_branch=<line>`, 마지막 태그 날짜 이후). 커밋 제목의
  `!NN`·`(#NN)`·conventional prefix·이슈 키(`[A-Z]{2,5}-\d+`)를 뽑는다. 머지분 0건이면 릴리즈할
  게 없다 — 그 사실을 보고하고 멈춘다.
- **API 도달**: `references/gitlab-access.md` 절차로 port-forward 열고 `GET /api/v4/version` 200.
- **protected tag**: `GET /projects/:id/protected_tags` 에 `v*` 가 있는가. 없으면 멈춘다 — `GITOPS_PUSH_TOKEN`·AWS
  자격이 protected 변수라 보호되지 않은 태그의 파이프라인엔 주입되지 않는다(`retag` 가 빈 자격으로 죽는다).
  setup §2c 가 만들었어야 할 것이므로 "setup 미완 — protected tag 생성 후 재실행" 으로 보고한다.
- **prod 환경 준비도**: `references/prod-readiness.md` §1 표(10 항목, PASS/FAIL/확인필요)를 돌려 플랜에 그대로
  넣는다. 6(Application Synced/Healthy)이 PASS 면 Step 5 검증이 켜진다. 아니면 검증은 skip 으로 계속한다 —
  MR 머지까지는 의미가 있다(환경이 생기면 그 시점 gitops 상태가 곧 prod 다). 단 1~5 가 PASS 인데 변수만
  비어 있으면 릴리즈 전에 **connect 를 먼저** 제안한다(`prod-readiness.md` §3 — 변수 채우기 MR 하나로 검증이 켜진다).
  FAIL·확인필요 항목은 §2 가이드와 함께 보고의 `## ⚠ 미검증` 에 실린다.

### 1. Plan — 버전·노트 제안

`references/release-notes.md` 를 읽고(lazy-read) 그 규칙대로 **bump 를 판정**(BREAKING→major ·
feat→minor · 그 외→patch)하고 **노트 초안**을 만든다. 사용자가 버전을 말했으면(`v1.4 로`) 그
값을 쓰되 규칙과 다르면 한 줄로 짚는다(강요 아님).

플랜을 한 블록으로 보여준다:

```
릴리즈 플랜 — apps/survey-radar
  버전     v0.0.17 → v0.1.0   (feat 2건 → minor)
  대상     develop @ 402789f  (dev 이미지 develop-402789f… 확인, digest sha256:bd0f…)
  prod     DevOps/infra gitops/prod/apps/survey-radar/  → promote MR 자동 머지
  준비도   10/10 PASS · Argo apps-prod-survey-radar (eks-prod)   ← FAIL 있으면 "7/10 — 검증 skip, §2 가이드 첨부"
  health   https://survey.adtype.work/api/health          ← 없으면 "미설정"
  Linear   SUR-43 · SUR-38 → Release v0.1.0 생성 + 이슈 코멘트   ← MCP 없으면 "생략"

  노트 (태그 메시지 = GitLab Release 본문):
  ┌ v0.1.0 — 카탈로그 뷰 + 오라클 회귀망 경로 해석 전환
  │ ## 변경
  │ - feat(catalog): 카탈로그 뷰 goal prompt 기록 (!49, SUR-38)
  │ - feat(oracle): 회귀망 경로 해석 실행 트리 기준 전환 (!51, SUR-43)
  └
승인하면 태그 push → Release → 파이프라인 → MR 머지 → 검증까지 멈추지 않고 진행한다.
```

승인은 **`AskUserQuestion` 1회** — 선택지: 그대로 진행 / 버전만 바꿔서(다른 bump) / 노트 수정 후
/ 중단. 백그라운드 잡(`$CLAUDE_JOB_DIR`)이면 `AskUserQuestion` 대신 텍스트 플랜 + `needs input:`
경로. 노트 수정은 사용자가 준 문구를 그대로 반영해 플랜을 다시 보이고 한 번 더 승인받는다
(수정본 재확인은 게이트 추가가 아니라 같은 게이트의 재제시다).

### 2. Tag + Release — 승인 뒤 첫 write

```bash
git tag -a vX.Y.Z -F <notes-file> --cleanup=verbatim
git push origin vX.Y.Z              # 태그만. 브랜치 push 아님.
```

push 직후 API 로 GitLab Release 를 만든다(`POST /projects/:id/releases` — `tag_name`·`name`·
`description`=노트 본문). Release 는 태그의 웹 표면이다 — 파이프라인엔 영향 없고 사람이 나중에
"뭐가 나갔지" 를 찾는 자리다. 실패해도 릴리즈는 계속한다(경고만).

### 3. Watch — 태그 파이프라인

`GET /projects/:id/pipelines?ref=vX.Y.Z` 로 파이프라인을 찾고 상태를 폴링한다(30초 간격,
상한 20분). 잡은 두 개다 — `retag`(ECR put-image) · `promote-prod`(infra MR 생성). 로그에서
digest 와 MR URL(`MR opened from ci/<svc>-prod-vX.Y.Z`)을 잡아둔다.

실패하면 **여기서 멈춘다**. 태그는 이미 밀렸고 지울 수 없다(안전 경계) — 실패 잡 로그
요약 + "원인 수정 후 다음 patch 버전으로 다시 launch" 를 보고한다. 태그를 되돌리려 하지 말 것:
immutable 태그가 실패 기록으로 남는 것이 정상이고, 그게 다음 사람에게 무슨 일이 있었는지 말해준다.

### 4. Merge — promote MR

MR 을 API 로 조회해 **세 가지를 확인한 뒤** 머지한다(`PUT …/merge_requests/:iid/merge`,
`squash=false` — promote 커밋 1개라 squash 가 의미 없고, revert 대상이 그 커밋 하나여야 한다):

1. MR 의 파이프라인(infra 에 CI 가 있으면)이 success — 없으면 이 조건은 비어 있는 것으로 본다.
2. `changes` 가 `PROD_GITOPS_PATH` 아래 파일만, 그리고 바뀐 줄이 `image:` 줄만이다.
3. 새 `image:` 의 `@sha256:` 이 Step 3 에서 잡은 digest 와 같다.

하나라도 어긋나면 머지하지 않고 MR URL 과 어긋난 항목을 보고한다. 머지 후 `merged_at` 이
채워졌음을 재조회로 확인한다 — 200 응답은 요청이 받아들여졌다는 뜻이지 머지됐다는 뜻이 아니다.

### 5. Verify — Argo · health

준비도 6 이 PASS 일 때만(Step 0 판정). 아니면 `## ⚠ 미검증` 에 준비도 표 + `prod-readiness.md` §2 가이드(FAIL·확인필요 항목만)를 넣고 넘긴다.

- **Argo**: `kubectl --context <ctx> -n argocd get applications.argoproj.io <PROD_ARGO_APP> -o json`
  에서 `status.sync.status == Synced` **그리고** `status.health.status == Healthy` **그리고**
  `status.sync.revision` 이 머지 커밋 sha 인지 — 세 개 다. 자동 sync 라 보통 3분 안에 온다
  (폴링 30초, 상한 10분). `phase=Succeeded` 는 *이전* operation 것일 수 있으니 판정에 쓰지 않는다
  (infra `CLAUDE.md` 실측 함정).
- **health**: `PROD_HEALTH_URL` 이 있으면 `curl -sS -o /dev/null -w '%{http_code}'` 가 200 인지
  3회(10초 간격) — 롤아웃 중 한 번의 non-200 은 정상이므로 연속 3회 실패만 실패로 본다.

**실패 판정이면 롤백 MR 을 제안한다.** 자동으로 열지 않고 `AskUserQuestion` — "revert MR 열기 /
잠깐 두고 보기 / 직접 처리". 열기를 택하면 infra 를 clone 해 promote 커밋을 `git revert` 하고
브랜치 `revert/<svc>-vX.Y.Z` 로 push + MR 생성(`-o merge_request.create -o merge_request.target=main`).
**머지는 하지 않는다** — 롤백은 태그 승인이 덮지 않은 새 결정이다. MR URL 을 보고하고 사람이
머지하면 Argo 가 이전 digest 로 되돌린다(GitOps 규율: 롤백 = MR revert).

### 6. Linear — graceful 부가 단계

`~/.claude/references/craft/linear.md` §1 의 MCP 감지 절차를 따른다. 없으면 **묻지 않고 생략**.
있으면 Step 0 에서 뽑은 이슈 키로:

- Linear **Release** 오브젝트 생성(이름 `vX.Y.Z`, 대상 이슈 연결) — 도구 이름을 하드코딩하지
  않는다(§11 원칙). available tools 에서 release 저장 도구를 찾고, 없으면 이 항목만 생략.
- 각 이슈에 코멘트 1줄: `released in vX.Y.Z — <GitLab Release URL>`. 상태 전이는 하지 않는다
  (Done 은 land 가 머지 시점에 이미 옮겼다 — 릴리즈는 상태가 아니라 이벤트다).

### 7. Report

카드형 1장 + `▶ 다음 단계` 블록 + `result:` — 순서 고정, 조용히 빠지는 항목 금지.

```
🚀 Released apps/survey-radar v0.1.0
────────────────────────
태그      v0.1.0 @ 402789f · Release https://gitlab.draftype.work/apps/survey-radar/-/releases/v0.1.0
이미지    apps/survey-radar:v0.1.0 @sha256:bd0f09b0… (develop-402789f… 와 동일 digest)
prod MR   DevOps/infra !131 merged · gitops/prod/apps/survey-radar/deployment.yaml
Argo      apps-prod-survey-radar Synced/Healthy @ 9c1e2ab        ← 또는 "⚠ 미검증 — 준비도 7/10"
health    200 ×3 https://survey.adtype.work/api/health           ← 또는 "미설정"
Linear    Release v0.1.0 · SUR-43 SUR-38 코멘트                   ← 또는 "생략(MCP 없음)"

## ⚠ 미검증 / 미완     (해당 시만 — 준비도 표 + §2 가이드, health 미설정, Release 생성 실패, 롤백 MR 열림)

▶ 다음 단계
```

`▶ 다음 단계` 블록의 규격은 `~/.claude/references/craft/output-contract.md` §N(고정 3행
잔여/필수/권장 — 복제 금지, 그 파일이 SSOT). launch 의 행 매핑:

- **잔여** = 릴리즈에 안 실린 것 — 없다(릴리즈 라인 HEAD 를 통째로 태그했으므로). 단 `RELEASE_LINE`
  이 main 인데 develop 에 main 보다 앞선 커밋이 있으면 "develop N 커밋 미릴리즈 — develop→main
  MR 후 다음 launch" 로 적는다.
- **필수** = 이번 launch 가 만든 후속 — 롤백 MR 머지 판단, Release 생성 실패 시 수동 생성,
  마이그레이션 포함 릴리즈면 "prod DB apply 검증"(머지 ≠ 적용 — land report-format §5 와 같은 규율).
- **권장** = 검증 skip 이 있었으면 준비도에 따라 한 줄 — 1~5 PASS 면 "`/launch` connect 로 변수 채우면 다음
  launch 부터 검증이 켜진다", 아니면 "준비도 FAIL 항목(§2 가이드) 해소 후 connect". 그 외엔 "없음".

마지막 줄은 L1:

```
result: apps/survey-radar v0.1.0 released — tag+Release · infra !131 merged · Argo Synced/Healthy · health 200 · Linear 2 issues
```

검증을 skip 했으면 `result:` 에 그대로 쓴다(`Argo 미검증(EKS 미구축)`). 안 한 것을 한 것처럼
쓰지 않는다 — `result:` 는 백그라운드 classifier 가 읽는 유일한 신호라 여기서 위장하면 상류가
전부 속는다.

## 이 스킬이 틀린 선택일 때

- PR/MR 을 머지하고 로컬을 정리하려는 것이면 → `land`. dev 반영은 land 가 끝낸 뒤 파이프라인이
  자동으로 한다 — launch 는 그 *다음*, prod 만 담당한다.
- GitHub 에만 있는 서비스(ADMap·ADType-Intelligence 등, prod = GitHub tag→compose)면 → 범위 밖.
  GitLab 이관이 선행이고 이관은 `DevOps/infra` 트랙의 일이다.
- 스킬 레포(carpdm-skills) 변경을 배포하려는 것이면 → `ship`.
- 릴리즈 배선은 있는데 파이프라인 자체를 고쳐야 하면(잡 스크립트 버그) → 메인이 직접 수정 후
  land. launch 는 배선을 *쓰는* 쪽이고 setup 은 *처음 만드는* 쪽이다 — 수리는 둘 다 아니다.
- EKS·Argo CD·Secret 같은 prod **환경 자체**를 만들려는 것이면 → `DevOps/infra` 트랙(Terraform·ADR 0006).
  launch 는 준비도를 판정하고 어디서 만드는지 안내할 뿐(`prod-readiness.md` §2), 만들지 않는다.
