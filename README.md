# carpdm-skills

Claude Code 글로벌 스킬 배포 레포. **계획 2종(심층 인터뷰·계획 수립) + 세션/운영 5종(인계·랜딩·워크트리 정리·스킬 배포·dev 서버 데몬) + Linear 라이프사이클 4종**, 총 **스킬 11종.** 스킬과 별개 축으로 [`global/`](global/README.md) 이 **글로벌 환경 전수 덤프**(rules·hooks·settings·서드파티 스킬·codex·MCP/플러그인 재현)를 담아 팀원 동일 환경을 3명령으로 재현한다.

**구현·수정·버그픽스에는 스킬이 없다** — 메인이 직접 한다(plan mode → 구현 → `/code-review`, 보안 민감 변경이면 `/security-review`). 2026-08-04 에 파이프라인 3종(`forge`·`renew`·`hunt`)과 공유 엔진 `craft-core` 를 은퇴시켰다. 근거·되살릴 조건은 [ADR 003](docs/adr/003-harness-minimization-2026-08.md).

스킬은 역할에 따라 그룹으로 나뉜다. (물리 폴더는 플랫 — `skills/` 한 레벨. 공유 참조 자료는 `global/references/craft/` 에 있고 스킬들이 절대경로로 읽는다.)

### 🧭 think & plan — 코드 전에 요구사항·계획·목표를 정리

| 스킬 | 용도 | 트리거 (자연어로도 발화) | 의존 |
|---|---|---|---|
| [`deep-interview`](skills/deep-interview) | 모호한 아이디어 → 검증가능 spec (소크라테스 인터뷰, ambiguity 게이트) | "인터뷰해줘", "이거 같이 정리하자", "/deep-interview" | 없음 (독립) |
| [`deep-plan`](skills/deep-plan) | (모호하면 인터뷰 보강 후) 실행 가능 PLAN 문서 + UI면 HTML 시안, 빌드는 안 함 | "계획 세워줘", "어떻게 만들지 설계", "구현 말고 플랜만", "UI 시안 뽑아줘", "/deep-plan" | references/craft |
| [`goal-prompt`](skills/goal-prompt) | 메타프롬프팅 → 갭 인터뷰 → 페르소나·Karpathy 규율·ponytail·paperthin·Pocock 흐름이 결합된 Goal Prompt 1파일 (PLAN·HTML 없음 — 프롬프트만) | "goal 프롬프트 만들어줘", "자율 에이전트한테 던질 프롬프트", "메타프롬프팅 해줘", "/goal-prompt" | references/craft (output-contract) |

### 🧹 session & ops — 작업 사이클 운영 (저장·정리·랜딩·배포검토)

| 스킬 | 용도 | 트리거 (자연어로도 발화) | 의존 |
|---|---|---|---|
| [`handoff`](skills/handoff) | 세션 인계 (저장/복원) | "여기까지 하자 이어서", "어디까지 했지" | 없음 (독립) |
| [`land`](skills/land) | 올린 PR 머지 + 로컬 정리 | "PR 머지하고 브랜치 정리", "land my PRs" | 없음 (독립) |
| [`wt-sweep`](skills/wt-sweep) | PR 없이 잔여·세션 워크트리만 정리 | "워크트리 정리해줘", "세션 워크트리 치워줘" | 자체 references/sweep-mode.md 가 절차 SSOT |
| [`ship`](skills/ship) | (레포 전용) 스킬 변경 PR→CI→머지→로컬정리 한 흐름 | "PR 올리고 land 까지", "ship 해줘", "CI 통과하면 머지" | 없음 (독립, carpdm-skills 전용) |
| [`dev-server-daemon`](skills/dev-server-daemon) | dev 서버를 daemon(double-fork)으로 띄워 세션 종료 후에도 살려둠 — 사람이 브라우저로 직접 확인하도록 인계 | "개발서버 백그라운드로 띄워줘", "dev 서버 올려둬 내가 확인할게", "올려놔" | 없음 (독립, references/craft `ui-verify §5.1` 이 이 스킬을 호출) |

### 🔗 linear — Linear 이슈 라이프사이클 (등록·실행·정리)

| 스킬 | 용도 | 트리거 (자연어로도 발화) | 의존 |
|---|---|---|---|
| [`linear-register`](skills/linear-register) | Linear 이슈 단건~소수 등록 + 적응형 `## 추천`(적합 스킬/에이전트/워크플로우) + 의존 체인 전방 가이드(다음 작업 포인터·kickoff) | "리니어에 이슈 등록", "이거 티켓으로 올려줘", "연결된 이슈 등록" | Linear MCP |
| [`linear-replan`](skills/linear-replan) | 착수 직전 이슈(또는 짧은 자유 요구사항)를 codex 로 재플래닝 — 초안+결정 갈래 체크리스트 → 인터뷰 전항목 확정 → 착수 계획 1장(+승인 후 이슈 코멘트, 본문 무수정) | "이 티켓 어떻게 할지 먼저 정해줘", "착수 계획 짜줘", "구현 전에 갈래 정리해줘" | codex CLI · Linear MCP(이슈 모드) |
| [`linear-groom`](skills/linear-groom) | 기존 Linear 백로그 그루밍 — 고아 이슈 프로젝트 그룹핑 + 빈약 이슈 보강(+`## 추천`/체인) | "리니어 이슈 정리", "백로그 그루밍", "이슈 보강해줘" | Linear MCP |
| [`linear-prioritize`](skills/linear-prioritize) | 현재 repo 미완 이슈 스프린트 플래닝 — 의존·병렬 분석 + 우선순위 정렬 + 순차 EPIC 체인 milestone 묶기 (이슈 생성·구현 X) | "뭐부터 해야 돼", "병렬로 뭐 돌릴 수 있어", "스프린트 짜줘", "남은 이슈 정리" | Linear MCP |

문서를 산출하는 스킬(plan·spec·goal·adr)의 출력 형태 카탈로그는 [`docs/reference/output-templates.md`](docs/reference/output-templates.md).

> 과거 재사용 서브에이전트 6종(`agents/*.md`)과 에이전트 저작 스킬 `summon` 을 함께 배포했으나 [ADR 002](docs/adr/002-revert-agents-artifact-type.md) 로 철회했다 — 이 레포는 다시 스킬 단일 아티팩트다.

---

## 설치

### 전체 설치

```bash
git clone https://github.com/skdkfk8758/carpdm-skills.git
cd carpdm-skills
bash install.sh
```

12개 스킬을 `~/.claude/skills/` 로 복사한다. 기존 동일 이름은 in-place 덮어씀 (멱등 — git history 가 안전망). 설치 후 Claude Code **재시작**.

> 온보딩은 위 스킬 표 11행 + 아래 [설치](#설치) 3명령이 전부다. 종전 `docs/guides/team-workflow-guide.{md,html}`
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
# 예: handoff 만
cp -R skills/handoff ~/.claude/skills/

# 예: 개별 스킬만
```

> ⚠️ **일부 스킬은 `~/.claude/references/craft/` 를 절대경로로 읽는다** — `install.sh` 가 `global/references/craft/` 를 그 경로로 복사한다 (deep-plan 은 deep-interview 의 references 도 차용). handoff / sweep / land / ship / imprint / mockup / erd / colocate-domain-context / cicd-scaffold / dev-server-daemon 은 단독 설치 가능. 단 **deep-plan 의 DB/BE plan ERD 시안** 기능은 `erd` 가 설치돼 있어야 동작한다(없으면 ERD 만 생략, plan/시안은 정상). 둘을 함께 쓰려면 `erd` 도 같이 설치.

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
"대시보드 어떻게 만들지 플랜이랑 UI 시안 줘"     → deep-plan (빌드 X)
"이 티켓 어떻게 할지 먼저 정해줘"                → linear-replan (착수 계획 1장)
"이 작업 자율 에이전트용 goal 프롬프트로 써줘"    → goal-prompt (프롬프트 1파일, 빌드 X)
"여기까지 하자, 내일 이어서 정리해줘"            → handoff (저장)
"어제 하던 거 어디까지 했지"                      → handoff (복원)
"올린 PR 머지하고 로컬 정리해줘"                 → land
"개발서버 백그라운드로 띄워줘"                    → dev-server-daemon

# 슬래시 명시 호출
/deep-plan   /goal-prompt   /linear-replan   /handoff   /land   /wt-sweep
```

handoff 는 **양방향 자동 감지** (작업 끝/중단 = 저장, 세션 시작/재개 = 복원).
구현 요청은 어느 스킬도 잡지 않는다 — plan mode 로 정리하고 메인이 직접 구현한 뒤 `/code-review`.

---

## 검증 / 트러블슈팅

```bash
ls ~/.claude/skills/   # deep-interview deep-plan dev-server-daemon goal-prompt handoff land linear-groom linear-prioritize linear-register linear-replan ship wt-sweep
```

- **스킬이 참조 자료를 못 찾음** → `~/.claude/references/craft/` 존재 확인.
- **Phase 4 correctness 리뷰 스킵** → `/code-review` 미설치. `adversarial-review.md` 계약으로 적대 subagent 폴백.
- **스킬 안 보임** → Claude Code 재시작 (세션 시작 시 로드).
- **handoff 저장 위치** → git repo 의 `docs/handoff/`. repo 밖/non-git 이면 `~/.claude/projects/<slug>/handoff/`.

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
```

`sync.sh` 는 스킬(**레포가 추적 중인** `skills/` 디렉토리별 true mirror — 새 스킬 배포 시작은 `skills/<name>/` 디렉토리를 먼저 만든 뒤 sync)에 더해 **`sync-global.sh` 를 내장 실행**해 글로벌 환경 덤프(`global/` — skills-extra·codex·rules·settings, secret 마스킹+스캔 게이트)도 같은 커밋에 싣는다. `--push`/`--pr-only` 는 PR 전에 CI 검증 3종을 로컬 선실행한다(로컬 green = CI green).
