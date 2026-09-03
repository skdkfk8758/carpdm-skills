# GitLab 접근 — PAT + port-forward (launch Step 0 · setup 공용)

> 온프렘 GitLab 은 두 얼굴이다. git 은 tailnet SSH(NodePort 30022)로 바로 닿고, 웹
> `gitlab.draftype.work` 는 Cloudflare Access(`@draftype.net` OTP) 뒤라 API 토큰만으론 401 이
> 아니라 Access 로그인 페이지가 온다. **API 는 클러스터 안 서비스로 직접 붙는다** — 2026-08-31
> 실측(`~/.claude/projects/-Users-carpdm-orca-projects-Onprem-VPN/memory/gitlab-ecr-platform-state.md`).

## 1. 열기

```bash
# PAT — macOS 키체인. 없으면 §3.
GL_TOKEN=$(security find-generic-password -s gitlab-onprem -w) || { echo "PAT 없음"; }

# port-forward — 백그라운드, 세션 끝나면 닫는다(§4). 컨텍스트는 platform-admin 이어야 한다(viewer 는 port-forward 거부).
kubectl --context on-prem-platform-admin -n gitlab port-forward svc/gitlab-webservice-default 8181:8181 >/dev/null 2>&1 &
PF_PID=$!
sleep 2
GL_API=http://127.0.0.1:8181/api/v4

# 도달 확인 — 200 + version 이어야 계속. 401 이면 PAT, 연결 거부면 port-forward 문제.
curl -sS -o /dev/null -w '%{http_code}\n' -H "PRIVATE-TOKEN: $GL_TOKEN" "$GL_API/version"
```

`glab` 을 쓰고 싶으면 `GITLAB_HOST=127.0.0.1:8181 GITLAB_TOKEN=$GL_TOKEN glab …` 로 같은 경로를
탄다(`glab auth login` 없이). 단 glab 은 https 를 가정하는 명령이 있어 curl 이 더 예측 가능하다 —
아래 카탈로그는 curl 기준.

## 2. 호출 카탈로그 (launch 가 쓰는 것만)

프로젝트 id 는 origin 의 **전체 경로**를 URL-encode 해 얻는다: `apps/survey-radar` → `apps%2Fsurvey-radar`, `infra/admap-mcp` → `infra%2Fadmap-mcp`(그룹이 `apps` 가 아닌 서비스도 있다).
`DevOps/infra` 는 **id=1** 로 고정(그룹 이전에도 유지 — 위 메모리 파일).

| 목적 | 호출 |
|---|---|
| 프로젝트 id | `GET /projects/<group>%2F<svc>` → `.id` |
| 마지막 태그 이후 머지 MR | `GET /projects/:id/merge_requests?state=merged&target_branch=<line>&updated_after=<ISO>&per_page=100` |
| 태그 파이프라인 | `GET /projects/:id/pipelines?ref=vX.Y.Z` → `[0].id`, `.status` |
| 잡 목록·로그 | `GET /projects/:id/pipelines/:pid/jobs` · `GET /projects/:id/jobs/:jid/trace` |
| Release 생성 | `POST /projects/:id/releases` body `{"tag_name","name","description"}` |
| infra 의 promote MR 찾기 | `GET /projects/1/merge_requests?state=opened&source_branch=ci/<svc>-prod-vX.Y.Z` |
| MR diff | `GET /projects/1/merge_requests/:iid/changes` → `.changes[].new_path`, `.diff` |
| MR 파이프라인 | `GET /projects/1/merge_requests/:iid/pipelines` (없으면 `[]` — infra 에 CI 가 없을 수 있다) |
| MR 머지 | `PUT /projects/1/merge_requests/:iid/merge` body `{"squash":false,"should_remove_source_branch":true,"sha":"<head>"}` |
| 머지 확인 | `GET /projects/1/merge_requests/:iid` → `.state == "merged"` 그리고 `.merged_at` 채워짐 |
| PAT self-rotate | `POST /personal_access_tokens/self/rotate` body `{"expires_at":"YYYY-MM-DD"}` → `.token`(신규) |
| protected tag (setup) | `POST /projects/:id/protected_tags` body `{"name":"v*","create_access_level":40}` (40=Maintainer) |
| CI 변수 존재 (setup) | `GET /projects/:id/variables` → key 목록 (값은 보지 않는다 — masked) |

머지 응답 200 은 "요청 수락" 이다. `merged_at` 재조회 없이 머지됐다고 쓰지 않는다.

**`sha` 는 선택이 아니라 필수다.** 빼면 `400 {"message":"SHA must be provided when merging"}`
가 온다(2026-09-03 실측, GitLab 19.3.1 · `DevOps/db-manager` !1). 값은 머지 직전 MR 을 조회해
`.sha`(= head commit)를 그대로 넣는다 — 로컬 `git rev-parse` 로 조립하지 말 것(원격이 앞서
있으면 어긋난다). 이 필드는 "내가 본 그 커밋을 머지한다"는 낙관적 잠금이라, 사이에 push 가
들어오면 409 로 막아 주는 안전장치이기도 하다.

머지 뒤 로컬 브랜치 정리에서 **squash 머지는 `git branch -d` 를 거부한다**(`not fully merged`).
브랜치 커밋이 기본 브랜치의 조상이 아니게 되기 때문이며 정상이다. MR `state == "merged"` 를
확인한 뒤 `git branch -D <b>  # landed` 로 지운다 — `# landed` 주석은 파괴 명령 훅
(`guard-destructive-cmd.sh`)이 요구하는 마커다.

## 3. PAT 가 없거나 만료가 임박할 때

**만료 임박 = 스킬이 직접 갱신한다.** 토큰이 살아 있기만 하면 웹 세션 없이 자체 로테이트가
된다(GitLab 16+, 19.3.1 실측):

```bash
NEW=$(curl -sS -X POST -H "PRIVATE-TOKEN: $GL_TOKEN" -H 'Content-Type: application/json' \
      -d '{"expires_at":"2027-09-02"}' "$GL_API/personal_access_tokens/self/rotate" \
      | python3 -c 'import sys,json; print(json.load(sys.stdin)["token"])')
security add-generic-password -a carpdm -s gitlab-onprem -w "$NEW" -U
```

- **구 토큰은 응답과 동시에 폐기된다.** 응답의 `token` 을 놓치면 복구 수단이 없으니
  로테이트·저장·검증을 **한 스크립트 안에서** 끝낸다 — 중간에 사람 확인을 끼우지 말 것.
- 저장처가 둘 이상이면(예: `~/.config/admap-mcp.env` 의 `GITLAB_TOKEN=`) 같은 스크립트에서
  전부 갱신하고, 각 저장처에서 다시 읽어 `GET /version` 200 으로 검증한다.
- 만료일은 서버 정책 상한을 넘으면 조용히 줄어든다 — 응답의 `expires_at` 을 그대로 믿지 말고
  출력해 확인한다.

**아예 없을 때만** 사람 손이 필요하다(발급은 Access 통과 세션이 필요). 이 문구를 그대로 내고
**멈춘다**:

```
GitLab PAT 가 keychain(gitlab-onprem)에 없다. 발급:
  1. https://gitlab.draftype.work/-/user_settings/personal_access_tokens
     name: launch-cli · scopes: api · expires: 1년
  2. security add-generic-password -a carpdm -s gitlab-onprem -w '<token>' -U
  3. /launch 다시 실행
```

`api` scope 하나로 충분하다(읽기·MR 머지·Release·protected_tags 전부). `write_repository` 는
불필요 — 태그 push 는 SSH 키가 한다.

## 4. 닫기

release/setup 이 끝나면(성공·실패 무관) `kill $PF_PID`. report 직전에 닫는다 — 열어둔
port-forward 는 다음 세션의 `8181` 바인딩을 막는다. 이미 누가 8181 을 잡고 있으면(`lsof -i :8181`)
그 프로세스를 죽이지 말고 `8182:8181` 로 바꿔 연다 — 다른 세션의 것일 수 있다.

## 5. 함정

- `kubectl get app` 은 Rancher CRD 로 잡힌다 — Argo 는 항상 `applications.argoproj.io`.
- 기본 kube 컨텍스트 `on-prem-viewer` 는 port-forward 도 거부한다. `--context on-prem-platform-admin` 명시.
- MR 머지가 405 `Method Not Allowed` 면 파이프라인 대기 중이거나 conflict — 재시도 말고 상태를 읽는다.
- GitLab 19 의 project access token(`GITOPS_PUSH_TOKEN`)은 Developer 라 protected `main` 머지 권한이 없다.
  그래서 promote MR 머지는 CI 가 아니라 **이 스킬이 사용자 PAT(Owner)로** 한다 — 설계상 의도.
