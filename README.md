# carpdm-skills

Claude Code 글로벌 스킬 배포 레포. **작업 유형별 엄격 파이프라인 3종 + 심층 인터뷰 1종 + 계획 수립 1종 + Goal Prompt 저작 1종 + 세션 인계 1종 + 정리 유틸 1종 + PR 랜딩 1종 + 워크트리 정리 1종 + 스킬 배포 1종 + 배포 전 최종 검토 1종 + 배포 전 보안 감사 1종 + UI 디자인 충실 재현 1종 + 프로젝트 충실 UI 시안 1종 + ERD 도식 1종 + 코드베이스 컨텍스트 셋업 1종 + CI/CD 스캐폴딩 1종 + ADMap 지도 스캐폴딩 1종 + 공유 엔진 1종 + Linear 라이프사이클 4종**, 총 **스킬 25종.**

스킬은 역할에 따라 **6개 그룹**으로 나뉜다. (물리 폴더는 플랫 — `skills/` 한 레벨. craft-core 절대경로 결합 때문에 카테고리 폴더는 두지 않으며, 분류는 개념적이다.)

### 🔨 build-pipeline — 코드를 짓는 엄격 파이프라인

craft-core 공유 엔진(소크라테스 인터뷰 → plan review 게이트 → TDD → 보안 검증) 위에서 도는 작업유형 3종 + 엔진.

| 스킬 | 용도 | 트리거 (자연어로도 발화) | 의존 |
|---|---|---|---|
| [`forge`](skills/forge) | 새 기능 구현 (0→1) | "X 추가/구현/만들어줘" | craft-core |
| [`hunt`](skills/hunt) | 버그 수정 (재현→회귀잠금) | "X 깨졌어", "왜 null 반환하지" | craft-core |
| [`renew`](skills/renew) | 기존 기능 변경/리뉴얼 | "X 다시 만들어", "동작 바꿔줘" | craft-core |
| [`craft-core`](skills/craft-core) | ⚙️ 공유 엔진 (직접 호출 X) | forge/hunt/renew/deep-plan 이 내부에서 읽음 | — |

### 🧭 think & plan — 코드 전에 요구사항·계획·목표를 정리

| 스킬 | 용도 | 트리거 (자연어로도 발화) | 의존 |
|---|---|---|---|
| [`deep-interview`](skills/deep-interview) | 모호한 아이디어 → 검증가능 spec (소크라테스 인터뷰, ambiguity 게이트) | "인터뷰해줘", "이거 같이 정리하자", "/deep-interview" | 없음 (독립) |
| [`deep-plan`](skills/deep-plan) | (모호하면 인터뷰 보강 후) 실행 가능 PLAN 문서 + UI면 HTML 시안, 빌드는 안 함 | "계획 세워줘", "어떻게 만들지 설계", "구현 말고 플랜만", "UI 시안 뽑아줘", "/deep-plan" | craft-core |
| [`deep-prompt`](skills/deep-prompt) | 입력 → 자율 goal/백그라운드 잡 실행용 검증가능 Goal Prompt(.md) 저작 (고정 템플릿, 성공기준 측정가능화) | "goal 프롬프트 만들어줘", "백그라운드로 돌릴 목표 정리", "/deep-prompt" | 없음 (독립) |

### 🎨 design & ui — 추출된 디자인 시스템 충실 재현

| 스킬 | 용도 | 트리거 (자연어로도 발화) | 의존 |
|---|---|---|---|
| [`imprint`](skills/imprint) | DESIGN.md(design-extractor 추출) → React+Tailwind 테마·컴포넌트·HTML 시안 충실 재현 (token-traceability) | "이 DESIGN.md 로 컴포넌트 만들어줘", "추출한 디자인대로 Tailwind 테마", "/imprint" | 없음 (독립) |
| [`mockup`](skills/mockup) | 기존 프로젝트의 디자인 토큰·화면 어휘 추출 → 충실한 self-contained HTML 시안 + 토큰 기계검증·실화면 대조 후 Artifact publish | "이 화면 시안 만들어줘", "목업 떠줘", "UI 미리보기", "/mockup" | 없음 (독립) |
| [`erd`](skills/erd) | DB 스키마(마이그/ORM/repo) → self-contained HTML ERD (테이블 카드 + SVG 관계선 4종 색) | "이 마이그레이션으로 ERD 그려줘", "DB 관계도 HTML 로", "스키마 다이어그램", "/erd" | 없음 (독립) |

### 🏗 project scaffold & context — 프로젝트 인프라·컨텍스트 셋업/생성

| 스킬 | 용도 | 트리거 (자연어로도 발화) | 의존 |
|---|---|---|---|
| [`colocate-domain-context`](skills/colocate-domain-context) | 도메인별 CLAUDE.md 를 코드 옆에 배치(경로 근접 auto-load) + 코드만 바뀌고 문서 미갱신 시 경고하는 co-update 게이트 셋업. 프로젝트 구조·verify host(verify.sh/husky/pre-commit/CI/Makefile/none)에 적응 | "폴더별 CLAUDE.md", "도메인 지식 코드 옆에", "co-update 게이트 만들어줘", "문서 노후화 막는 게이트" | 없음 (독립) |
| [`cicd-scaffold`](skills/cicd-scaffold) | Node 앱 GitHub Actions 배포 워크플로 생성 — develop→dev 자동, 태그→prod, ECR push(OIDC)·self-hosted runner. build/test·포트 탐지 후 워크플로·Dockerfile·셋업 체크리스트 산출 | "dev/prod 배포 github actions 만들어줘", "ECR 로 CD 셋업", "develop 머지하면 자동배포" | 없음 (독립) |
| [`admap-scaffold`](skills/admap-scaffold) | ADMap 지도가 이미 뜨는 정적 HTML 프로젝트 폴더 스캐폴딩 — style 스냅샷 굽기(file:// 더블클릭 유지) + 레이어 인터뷰 + CLAUDE.md·정적전용 가드 훅·verify.mjs 동봉, 산출 후 폴더로 이동해 오버레이 계속 | "지도 페이지 만들어줘", "OOH 제안용 지도 띄워줘", "ADMap 지도 붙인 html 만들어줘" | 없음 (독립, ADMap API 키 필요) |

### 🧹 session & ops — 작업 사이클 운영 (저장·정리·랜딩·배포검토)

| 스킬 | 용도 | 트리거 (자연어로도 발화) | 의존 |
|---|---|---|---|
| [`handoff`](skills/handoff) | 세션 인계 (저장/복원) | "여기까지 하자 이어서", "어디까지 했지" | 없음 (독립) |
| [`sweep`](skills/sweep) | 프로젝트 잡동사니 정리 (문서/로그) | "쌓인 로그/플랜 치워줘", "docs 청소" | 없음 (독립) |
| [`land`](skills/land) | 올린 PR 머지 + 로컬 정리 | "PR 머지하고 브랜치 정리", "land my PRs" | 없음 (독립) |
| [`wt-sweep`](skills/wt-sweep) | PR 없이 잔여·세션 워크트리만 정리 | "워크트리 정리해줘", "세션 워크트리 치워줘" | 자체 references/sweep-mode.md 가 절차 SSOT |
| [`ship`](skills/ship) | (레포 전용) 스킬 변경 PR→CI→머지→로컬정리 한 흐름 | "PR 올리고 land 까지", "ship 해줘", "CI 통과하면 머지" | 없음 (독립, carpdm-skills 전용) |
| [`dev-server-daemon`](skills/dev-server-daemon) | dev 서버를 daemon(double-fork)으로 띄워 세션 종료 후에도 살려둠 — 사람이 브라우저로 직접 확인하도록 인계 | "개발서버 백그라운드로 띄워줘", "dev 서버 올려둬 내가 확인할게", "올려놔" | 없음 (독립, craft-core `ui-verify §5.1` 이 이 스킬을 호출) |
| [`preflight`](skills/preflight) | 배포 직전 앱 전체 최종 검토 → 10차원 + 기술부채 점검, 고정 포맷 리포트 + GO/조건부GO/NO-GO 판정 | "배포 전에 검토해줘", "최종 점검", "출시 전 전체 봐줘", "배포 가능한지", "/preflight" | 없음 (독립) |
| [`fortify`](skills/fortify) | 배포 전 보안 한 축만 5 카테고리(앱/인증/데이터·통신/인프라/로깅) 감사 → PASS/FAIL/확인필요 + 라이브 probe(헤더·TLS·audit), 배포 보안 판정 | "배포 전 보안 검사", "보안 점검해줘", "OWASP 체크리스트로 감사", "/fortify" | 없음 (독립) |

### 🔗 linear — Linear 이슈 라이프사이클 (등록·실행·정리)

| 스킬 | 용도 | 트리거 (자연어로도 발화) | 의존 |
|---|---|---|---|
| [`linear-register`](skills/linear-register) | Linear 이슈 단건~소수 등록 + 적응형 `## 추천`(적합 스킬/에이전트/워크플로우) + 의존 체인 전방 가이드(다음 작업 포인터·kickoff) | "리니어에 이슈 등록", "이거 티켓으로 올려줘", "연결된 이슈 등록" | Linear MCP |
| [`linear-goal`](skills/linear-goal) | Linear 티켓 1건을 경량 흐름으로 자율 실행 (fetch→`## 추천` 라우팅→Goal Prompt 조립→확인 게이트→worktree→worker→In Review) | "ADT-211 goal 로 돌려줘", "이 티켓 그대로 진행", "워커한테 맡겨" | Linear MCP |
| [`linear-groom`](skills/linear-groom) | 기존 Linear 백로그 그루밍 — 고아 이슈 프로젝트 그룹핑 + 빈약 이슈 보강(+`## 추천`/체인) | "리니어 이슈 정리", "백로그 그루밍", "이슈 보강해줘" | Linear MCP |
| [`linear-prioritize`](skills/linear-prioritize) | 현재 repo 미완 이슈 스프린트 플래닝 — 의존·병렬 분석 + 우선순위 정렬 + 순차 EPIC 체인 milestone 묶기 (이슈 생성·구현 X) | "뭐부터 해야 돼", "병렬로 뭐 돌릴 수 있어", "스프린트 짜줘", "남은 이슈 정리" | Linear MCP |

**파이프라인 3종 공통 흐름**: 소크라테스 인터뷰 → plan review 게이트(상류 리뷰면 스킵, 고위험만 적대 1-pass) → 동적 워크플로 TDD(sonnet) → simplify 검토 패스(forge·renew·hunt, 옵션·동작불변, `/simplify` 위임) → 보안 검증 → 빌드 후 다음 스킬 제안(push 했으면 `/land`, 잔여 정리면 `/sweep` — 추천만, 자동 시작 X).

엔진은 두 실행 모드를 가진다 — **linear**(기본, 단일세션) / **orchestrated**(멀티에이전트 council, 명시 요청 시). 사용법은 [`docs/guides/craft-modes.md`](docs/guides/craft-modes.md).

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

25개 스킬을 `~/.claude/skills/` 로 복사한다. 기존 동일 이름은 in-place 덮어씀 (멱등 — git history 가 안전망). 설치 후 Claude Code **재시작**.

### 글로벌 셋업 (rules · hooks · settings — 팀원 동일 환경)

```bash
bash install-global.sh
```

스킬과 별개 축인 행동 규율 전체 — 글로벌 `CLAUDE.md`, 상시 룰(`rules/`), JIT 룰(`rules-ondemand/`), 가드 훅(`hooks/guards/`), `settings.json`(secret 은 `<FILL-ME>` placeholder) — 를 `~/.claude/` 로 설치한다. 스킬만 설치하면 룰·훅이 빠진 환경이 된다. 상세·제외 목록은 [`global/README.md`](global/README.md).

### 개별 설치 (하나씩)

```bash
# 예: handoff 만
cp -R skills/handoff ~/.claude/skills/

# 예: forge 만 — craft-core 도 같이 (의존)
cp -R skills/forge skills/craft-core ~/.claude/skills/
```

> ⚠️ **forge / hunt / renew / deep-plan 은 craft-core 가 반드시 함께 있어야 한다.** 내부에서 `~/.claude/skills/craft-core/references/...` 를 절대경로로 참조하기 때문 (deep-plan 은 deep-interview 의 references 도 차용). handoff / sweep / land / ship / deep-prompt / imprint / mockup / erd / colocate-domain-context / cicd-scaffold / dev-server-daemon 은 단독 설치 가능. 단 **deep-plan 의 DB/BE plan ERD 시안** 기능은 `erd` 가 설치돼 있어야 동작한다(없으면 ERD 만 생략, plan/시안은 정상). 둘을 함께 쓰려면 `erd` 도 같이 설치.

---

## 전제 / 의존성

| 항목 | 필수? | 설명 |
|---|---|---|
| Claude Code | ✅ | 스킬은 Claude Code Skill 기능 위에서 동작 |
| 설치 경로 `~/.claude/skills/` | ✅ 고정 | 다른 위치면 craft-core 엔진을 못 찾아 깨짐 |
| **craft-core** | ✅ | 파이프라인 3종 + deep-plan 공유 엔진. 빼면 4개 전부 동작 불가 |

`~` 절대경로는 사용자별 전개되므로 어느 머신이든 `~/.claude/skills/` 설치면 동작.

---

## 사용법

```
# 자연어 — 의도 감지 자동 발화
"ai ask 엔드포인트에 streaming 추가해줘"        → forge
"벤치가 500 던져, 고쳐줘"                        → hunt
"이 플로우 동작을 이렇게 바꿔줘"                 → renew
"대시보드 어떻게 만들지 플랜이랑 UI 시안 줘"     → deep-plan (빌드 X)
"여기까지 하자, 내일 이어서 정리해줘"            → handoff (저장)
"어제 하던 거 어디까지 했지"                      → handoff (복원)

# 슬래시 명시 호출
/forge   /hunt   /renew
```

handoff 는 **양방향 자동 감지** (작업 끝/중단 = 저장, 세션 시작/재개 = 복원). 파이프라인 3종은 **언더트리거 설계**(과발화 방지) — 확실히 원하면 슬래시 명시 호출 권장.

---

## 검증 / 트러블슈팅

```bash
ls ~/.claude/skills/   # forge hunt renew deep-interview deep-plan deep-prompt handoff sweep land wt-sweep ship preflight fortify imprint mockup erd colocate-domain-context cicd-scaffold craft-core linear-register linear-goal linear-groom linear-prioritize dev-server-daemon
```

- **forge 류가 craft-core 못 찾음** → 설치 경로 확인. `~/.claude/skills/craft-core/` 필수.
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
bash sync.sh           # ~/.claude/skills/ → repo skills/ 미러링 후 변경 표시
bash sync.sh --push    # 미러링 + 브랜치·PR·머지 자동 (master 직접 push 안 함)
```

`sync.sh` 는 **레포가 추적 중인 것만** 갱신한다 (true mirror, 삭제 파일 반영) — `skills/` 의 디렉토리별. 새 스킬 배포 시작은 `skills/<name>/` 디렉토리를 먼저 만든 뒤 sync.

`--push` 는 `chore/sync-<timestamp>` 브랜치를 만들어 PR 생성·머지까지 한다 (`gh` CLI 필요). master 직접 push 를 막는 브랜치 보호 환경에서도 동작.
