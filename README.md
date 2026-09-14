# carpdm-skills

Claude Code 글로벌 스킬 배포 레포. **심층 인터뷰 1종 + 세션/운영 6종(랜딩·운영 릴리즈·dev 배포 배선·워크트리 정리·스킬 배포·dev 서버 데몬) + Linear 라이프사이클 3종**, 총 **배포 스킬 10종.** 관점 리뷰·리서치 2종(`council-review`·`council-research`)은 `skills/` 가 아니라 글로벌 덤프(`global/skills-extra/`)로 함께 설치된다. 스킬과 별개 축으로 [`global/`](global/README.md) 이 **글로벌 환경 전수 덤프**(rules·hooks·settings·서드파티 스킬·codex·MCP/플러그인 재현)를 담아 팀원 동일 환경을 3명령으로 재현한다.

**구현·수정·버그픽스에는 스킬이 없다** — 메인이 직접 한다(plan mode → 구현 → `/code-review`, 보안 민감 변경이면 `/security-review`). 2026-08-04 에 파이프라인 3종(`forge`·`renew`·`hunt`)과 공유 엔진 `craft-core` 를 은퇴시켰다. 근거·되살릴 조건은 [ADR 003](docs/adr/003-harness-minimization-2026-08.md). 2026-09-14 에는 플랜 문서·인계 스킬 5종을 더 은퇴시켰다 — 계획은 짧은 스텝 규율과 대화로, 관점 리뷰는 페르소나 council 로 대체한다. 근거는 [ADR 004](docs/adr/004-harness-renewal-2026-09.md).

스킬은 역할에 따라 그룹으로 나뉜다. (물리 폴더는 플랫 — `skills/` 한 레벨. 공유 참조 자료는 `global/references/craft/` 에 있고 스킬들이 절대경로로 읽는다.)

### 🧭 think — 코드 전에 요구사항을 정리

| 스킬 | 용도 | 트리거 (자연어로도 발화) | 의존 |
|---|---|---|---|
| [`deep-interview`](skills/deep-interview) | 모호한 아이디어 → 검증가능 spec (소크라테스 인터뷰, ambiguity 게이트) | "인터뷰해줘", "이거 같이 정리하자", "/deep-interview" | 없음 (독립) |

### 🧹 session & ops — 작업 사이클 운영 (저장·정리·랜딩·배포검토)

| 스킬 | 용도 | 트리거 (자연어로도 발화) | 의존 |
|---|---|---|---|
| [`land`](skills/land) | 올린 PR 머지 + 로컬 정리 | "PR 머지하고 브랜치 정리", "land my PRs" | 없음 (독립) |
| [`keel`](skills/keel) | 신규 프로젝트에 dev 배포 파이프라인 — 인터뷰 1콜(노출 등급·외부 의존·라인) → GitLab CI(test→build→promote) + `gitops/apps/<svc>/`·Application·AppProject → MR 둘 열고 멈춤 · 준비도 미충족이면 infra 요청 문서 | "배포 붙여줘", "CI 세팅해줘", "새 서비스 온보딩", "/keel" | GitLab PAT(keychain `gitlab-onprem`) + kubectl port-forward · `DevOps/infra` clone |
| [`launch`](skills/launch) | GitLab 서비스 운영 릴리즈 — 버전·노트 제안 → 승인 1회 → 태그·Release → 태그 파이프라인(dev digest 재태깅+infra prod promote MR) → MR 자동 머지 → Argo/health 검증 · 배선 없으면 setup, prod 환경 준비도(10항목 3-상태) 판정·가이드 + connect 모드 | "운영 배포해줘", "prod 릴리즈", "운영배포 세팅해줘", "/launch" | GitLab PAT(keychain `gitlab-onprem`) + kubectl port-forward · references/craft (output-contract·linear) |
| [`wt-sweep`](skills/wt-sweep) | PR 없이 잔여·세션 워크트리만 정리 | "워크트리 정리해줘", "세션 워크트리 치워줘" | 자체 references/sweep-mode.md 가 절차 SSOT |
| [`ship`](skills/ship) | (레포 전용) 스킬 변경 PR→CI→머지→로컬정리 한 흐름 | "PR 올리고 land 까지", "ship 해줘", "CI 통과하면 머지" | 없음 (독립, carpdm-skills 전용) |
| [`dev-server-daemon`](skills/dev-server-daemon) | dev 서버를 daemon(double-fork)으로 띄워 세션 종료 후에도 살려둠 — 사람이 브라우저로 직접 확인하도록 인계 | "개발서버 백그라운드로 띄워줘", "dev 서버 올려둬 내가 확인할게", "올려놔" | 없음 (독립, references/craft `ui-verify §5.1` 이 이 스킬을 호출) |

### 🔗 linear — Linear 이슈 라이프사이클 (등록·실행·정리)

| 스킬 | 용도 | 트리거 (자연어로도 발화) | 의존 |
|---|---|---|---|
| [`linear-register`](skills/linear-register) | Linear 이슈 단건~소수 등록 — 전 상태 중복 대조 + 배치안 승인 게이트, 본문은 착수 에이전트가 그대로 먹는 규격(판정 가능한 완료 조건)으로 작성 | "리니어에 이슈 등록", "이거 티켓으로 올려줘", "연결된 이슈 등록" | Linear MCP |
| [`linear-groom`](skills/linear-groom) | 기존 Linear 백로그 그루밍 — 고아 이슈 프로젝트 그룹핑 + 빈약 이슈 보강(+`## 추천`/체인) | "리니어 이슈 정리", "백로그 그루밍", "이슈 보강해줘" | Linear MCP |
| [`linear-prioritize`](skills/linear-prioritize) | 현재 repo 미완 이슈 스프린트 플래닝 — 의존·병렬 분석 + 우선순위 정렬 + 순차 EPIC 체인 milestone 묶기 (이슈 생성·구현 X) | "뭐부터 해야 돼", "병렬로 뭐 돌릴 수 있어", "스프린트 짜줘", "남은 이슈 정리" | Linear MCP |

### 🔭 council — 관점 리뷰·리서치

(물리 위치는 `global/skills-extra/` — 배포 스킬이 아니라 글로벌 환경 덤프로 설치된다.)

| 스킬 | 용도 | 트리거 (자연어로도 발화) | 의존 |
|---|---|---|---|
| [`council-review`](global/skills-extra/council-review) | diff·브랜치·PR 을 Karpathy·Torvalds·Pocock 세 관점의 sonnet 서브에이전트가 병렬 리뷰하고 메인이 병합한다 — 편집 없음 | "리뷰해줘", "이 변경 봐줘", "카운슬 리뷰", "/council-review" | `global/agents/persona-*.md` |
| [`council-research`](global/skills-extra/council-research) | 주제·설계 질문·기술 선택을 Hightower(운영)·Abramov(제품/API) 두 관점의 sonnet 서브에이전트가 병렬 조사하고 메인이 병합한다 — 파일을 만들지 않고 보고만 | "리서치해줘", "조사해줘", "비교 분석해줘", "/council-research" | `global/agents/persona-*.md` |

문서를 산출하는 스킬(spec·adr)의 출력 형태 카탈로그는 [`docs/reference/output-templates.md`](docs/reference/output-templates.md).

> 과거 재사용 서브에이전트 6종(`agents/*.md`)과 에이전트 저작 스킬 `summon` 을 함께 배포했으나 [ADR 002](docs/adr/002-revert-agents-artifact-type.md) 로 철회했다 — 이 레포는 다시 스킬 단일 아티팩트다. 2026-09-14 부터 `global/agents/` 가 워커·페르소나 서브에이전트 정의를 담지만, 배포 아티팩트가 아니라 글로벌 환경 덤프의 일부다.

---

## 설치

### 전체 설치

```bash
git clone https://github.com/skdkfk8758/carpdm-skills.git
cd carpdm-skills
bash install.sh
```

10개 스킬을 `~/.claude/skills/` 로 복사한다. 기존 동일 이름은 in-place 덮어씀 (멱등 — git history 가 안전망). 설치 후 Claude Code **재시작**.

> 온보딩은 위 스킬 표 12행 + 아래 [설치](#설치) 3명령이 전부다. 종전 `docs/guides/team-workflow-guide.{md,html}`
> 은 은퇴 스킬(`forge`·`hunt`·`renew`·`linear-goal`·`preflight`·`fortify`·`mockup`·`imprint`)을 워크플로 축으로
> 썼기에 2026-08-04 에 삭제했다 — 틀린 온보딩은 없는 것보다 나쁘다. 근거는 [ADR 003](docs/adr/003-harness-minimization-2026-08.md).

### 글로벌 셋업 (팀원 동일 환경 — 전수 덤프)

```bash
bash install-global.sh          # rules·hooks·settings + 서드파티 스킬(skills-extra) + ~/.codex 형상
bash global/setup/replicate.sh  # 파일 밖 환경 — MCP(claude/codex)·플러그인·npm 재현 명령 (멱등, 토큰 무포함)
```

행동 규율(글로벌 `CLAUDE.md`·`rules/`·`rules-ondemand/`·가드 훅·`settings.json` — secret 은 `<FILL-ME>`)에 더해, repo 미추적 서드파티 스킬 전수(`global/skills-extra/`)와 codex 런타임 형상(`global/codex/`), Linear 라우팅 맵까지 설치한다. MCP·플러그인은 파일이 아니라 `replicate.sh` 의 명령으로 재현(각자 OAuth). 상세·제외 목록은 [`global/README.md`](global/README.md).

### 개별 설치 (하나씩)

```bash
# 예: wt-sweep 만
cp -R skills/wt-sweep ~/.claude/skills/

# 예: 개별 스킬만
```

> ⚠️ **일부 스킬은 `~/.claude/references/craft/` 를 절대경로로 읽는다** — `install.sh` 가 `global/references/craft/` 를 그 경로로 복사한다. handoff / sweep / land / ship / imprint / mockup / erd / colocate-domain-context / cicd-scaffold / dev-server-daemon 은 단독 설치 가능.

---

## 전제 / 의존성

| 항목 | 필수? | 설명 |
|---|---|---|
| Claude Code | ✅ | 스킬은 Claude Code Skill 기능 위에서 동작 |
| 설치 경로 `~/.claude/skills/` | ✅ 고정 | 다른 위치면 절대경로 참조가 깨짐 |
| **`~/.claude/references/craft/`** | ✅ | 공유 참조 자료(output-contract·linear·pipeline 등). 빼면 여러 스킬이 읽을 파일을 못 찾는다 |

`~` 절대경로는 사용자별 전개되므로 어느 머신이든 `~/.claude/skills/` 설치면 동작.

---

## 사용법

```
# 자연어 — 의도 감지 자동 발화
"ai ask 엔드포인트에 streaming 추가해줘"        → 스킬 없음. 메인 직접 구현
"벤치가 500 던져, 고쳐줘"                        → 스킬 없음. 메인 직접 수정
"이 브랜치 리뷰해줘"                              → council-review (세 관점 병렬, 편집 X)
"이 둘 중에 뭘 써야 할지 조사해줘"                → council-research (두 관점 병렬, 보고만)
"이거 어떻게 만들지 같이 정리하자"                → deep-interview (spec, 빌드 X)
"올린 PR 머지하고 로컬 정리해줘"                 → land
"개발서버 백그라운드로 띄워줘"                    → dev-server-daemon

# 슬래시 명시 호출
/deep-interview   /council-review   /council-research   /land   /wt-sweep   /ship
```

구현 요청은 어느 스킬도 잡지 않는다 — plan mode 로 정리하고 메인이 직접 구현한 뒤 `/code-review`.

---

## 검증 / 트러블슈팅

```bash
ls ~/.claude/skills/   # deep-interview dev-server-daemon keel land launch linear-groom linear-prioritize linear-register ship wt-sweep
                       # (+ council-review council-research — global/skills-extra 경유 설치)
```

- **스킬이 참조 자료를 못 찾음** → `~/.claude/references/craft/` 존재 확인.
- **Phase 4 correctness 리뷰 스킵** → `/code-review` 미설치. `adversarial-review.md` 계약으로 적대 subagent 폴백.
- **스킬 안 보임** → Claude Code 재시작 (세션 시작 시 로드).

## 업데이트 / 제거 (사용자)

```bash
git pull && bash install.sh      # 업데이트 (기존본 .bak 백업)
rm -rf ~/.claude/skills/<name>   # 개별 제거
```

## 배포 (유지보수자)

작업본(`~/.claude/skills/`)에서 스킬을 고친 뒤 레포로 반영:

```bash
bash sync.sh           # 스킬 + 글로벌 덤프 미러링 후 변경 표시
bash sync.sh --push    # 미러링 + 브랜치·PR·즉시 머지 (게이트 없는 빠른 경로)
bash sync.sh --pr-only # 미러링 + PR 까지만 — CI 게이트+머지는 ship 스킬이 처리 (권장)
bash sync.sh --dry-run # 미러링하면 바뀔 파일만 나열 (rsync -n) — 파일·stage·global 무변경
```

`sync.sh` 는 스킬(**레포가 추적 중인** `skills/` 디렉토리별 true mirror — 새 스킬 배포 시작은 `skills/<name>/` 디렉토리를 먼저 만든 뒤 sync)에 더해 **`sync-global.sh` 를 내장 실행**해 글로벌 환경 덤프(`global/` — skills-extra·codex·rules·settings, secret 마스킹+스캔 게이트)도 같은 커밋에 싣는다. `--push`/`--pr-only` 는 PR 전에 CI 검증 3종을 로컬 선실행한다(로컬 green = CI green).
