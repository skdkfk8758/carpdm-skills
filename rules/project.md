# carpdm-skills — Project Rules (SSOT)

> 이 파일이 프로젝트 지침 SSOT. AGENTS.md 는 빌드 산출물(글로벌 `~/.claude/rules/` + 본 파일 concat).
> `build-agents-md.sh` 미설치 동안 AGENTS.md 는 본 파일을 수동 미러링한다 — 본 파일만 편집하고 AGENTS.md 는 재생성.

## What this repo is

Claude Code 글로벌 스킬 **배포 레포**. 빌드/런타임 없음 — 스킬은 마크다운(`SKILL.md` + `references/*.md`)이고 `~/.claude/skills/` 로 복사돼야 동작한다. 코드 컴파일·테스트·린트 단계 없음.

스킬 11종: 작업유형 파이프라인 3 (`forge`/`hunt`/`renew`) + 심층인터뷰 1 (`deep-interview`) + 계획수립 1 (`deep-plan`) + goal프롬프트저작 1 (`deep-prompt`) + 세션인계 1 (`handoff`) + 정리유틸 1 (`sweep`) + PR 랜딩 1 (`land`) + UI충실재현 1 (`imprint`) + 공유엔진 1 (`craft-core`). `imprint` 는 standalone (craft-core 무의존) — design-extractor 의 `DESIGN.md` 파일을 입력받아 그 디자인 시스템에 충실하게(token-traceability: raw hex/px 하드코딩 0, 없는 값은 derive 해 명시 기록) React+Tailwind 테마·예시 컴포넌트·독립 HTML 시안을 생성한다. `frontend-design`(자유 창작)과 반대 축 — 발명이 아니라 *준수*. 추출은 안 함(design-extractor API 없음 — 사람이 수동 추출한 DESIGN.md 만 소비). 공유엔진은 두 실행 모드를 가진다 — linear(기본) / orchestrated(멀티에이전트 council, §5). `deep-interview` 는 standalone (craft-core 무의존) — 모호한 아이디어를 소크라테스 인터뷰 + 수학적 ambiguity 게이트로 검증가능 spec 까지 끌어올린 뒤 빌드 파이프라인으로 핸드오프. 빌드는 안 함. `deep-plan` 은 craft-core 의 **Phase 0+1 만** 차용하는 4번째 craft consumer (§6) — (모호하면 적응형 인터뷰로 보강 후) 실행 가능한 PLAN 문서 + UI plan 이면 HTML 시안까지 산출하고 **멈춘다**. codex 리뷰·TDD·보안 등 빌드 페이즈는 진입하지 않으며, deep-interview 처럼 빌드로 *자동 라우팅* 하지 않는다 — 순수 산출(단 종료 시 다음 스킬을 `AskUserQuestion` 으로 *제안*만 함, 시작은 사용자 몫 — §6). `deep-prompt` 는 standalone (craft-core 무의존) — 자율/백그라운드 잡에 넣을 검증 가능한 Goal Prompt 를 고정 템플릿(Objective/Success Criteria/Context/Constraints/Verification/Out of Scope/Done & Report)으로 저작해 `.md` 로 저장한다. 성공 기준을 측정 가능하게 못 박아 사람 개입 없이 루프가 끝까지 돌게 하는 데 초점. 빌드는 안 함.

> 과거 `agents/`(재사용 서브에이전트, 플랫 `.md`)를 두 번째 배포 아티팩트로 두고 `summon`(에이전트 저작) 스킬을 함께 배포했으나, [ADR 002](../docs/adr/002-revert-agents-artifact-type.md) 로 철회했다 — 이 레포는 다시 **스킬 단일 아티팩트**다.

## 작성 언어 정책 (skill authoring) — 글로벌 language-policy override

신규·수정 스킬(`SKILL.md`+`references/*.md`)의 **본문 prose 와 frontmatter `description:` 값은 한국어로 작성**한다. 글로벌 `language-policy`(문서=영어)를 이 레포의 skills 산출물에 한해 override — 사용자가 한국어 운용을 명시했기 때문.

**단, 다음은 항상 원문(영어/식별자) 유지 — 번역·한글화 금지(시스템이 깨짐):**
- frontmatter `name:` 값 (스킬 식별자 — install·sync·invocation·craft-core 절대경로가 참조).
- `model:`/`user-invocable:`/`disallowedTools:`/`tools:` 등 frontmatter 키와 그 값(opus/sonnet/haiku, Write/Edit 등).
- 코드 식별자·도구명(Read/Grep/Bash/Task/Workflow/Edit…)·파일경로·URL·XML 태그·코드블록 내용.
- `description:` 안의 **인용된 트리거 예시 구절**(자연어 발화 매칭용) — 원어 그대로(영어 예시는 영어로) 유지하고 설명 prose 만 한글.

## Commands

| 명령 | 용도 |
|---|---|
| `bash install.sh` | repo `skills/` → `~/.claude/skills/` 복사. 멱등 — 기존 동명은 in-place 덮어씀(백업 안 남김 — git history 가 안전망). 설치 후 Claude Code 재시작 필요 |
| `bash sync.sh` | 반대 방향. live `~/.claude/skills/` → repo `skills/` 미러(rsync `--delete`). repo 가 **이미 추적 중인** 것만 갱신. staged 변경 표시 |
| `bash sync.sh --push` | 미러 + `chore/sync-<ts>` 브랜치·PR·머지 자동 (`gh` CLI 필요). master 직접 push 금지 환경 대응 |
| `ls ~/.claude/skills/` | 스킬 설치 검증 — `forge hunt renew handoff sweep land craft-core` 보여야 함 |

검증 스위트는 없다. "테스트"는 `install.sh`/`sync.sh` 실행 + `ls` 확인이 전부.

## Architecture — 반드시 알 것

### 1. craft-core 절대경로 결합 (깨지기 쉬움)
파이프라인 3종 + `deep-plan` 은 craft-core 엔진을 **하드코딩 절대경로**로 읽는다:
`~/.claude/skills/craft-core/references/pipeline.md`. 따라서:
- 설치 경로는 `~/.claude/skills/` **고정**. 다른 위치면 4종 전부 깨짐.
- forge/hunt/renew **그리고 deep-plan** 은 craft-core 와 **항상 함께** 설치돼야 함 (deep-plan 은 deep-interview references 도 차용 — §6). handoff·sweep·land 는 단독 가능 (craft-core 의존 없음).
- craft-core 는 `user-invocable: false` — 직접 트리거 금지, 컨테이너일 뿐.

### 2. 공유 4-phase 파이프라인 (craft-core/references/pipeline.md)
Socratic 인터뷰 → codex 적대적 플랜 리뷰(`codex:rescue` 플러그인) → 동적 워크플로 TDD(sonnet) → 보안 검증.
각 작업유형 스킬은 이 엔진 위에 **자기 Phase 1 Socratic 초점 + Phase 3 TDD 진입점**만 얹는다 (SKILL.md 본문은 짧음 — 차이만 기술). 공통 Phase 0/2/4/5 는 엔진 그대로.
- `codex:rescue` 미설치 시 Phase 2 는 수동 리뷰로 폴백.
- 참조 분리: `socratic.md`/`codex-review.md`/`dynamic-tdd.md`/`security.md`/`context-adr.md` — phase 필요 시 lazy load.

### 3. SKILL.md frontmatter = 트리거
`name` + `description` 만. `description` 이 자연어 트리거 매칭을 좌우 — 파이프라인 3종은 **언더트리거 설계**(과발화 방지, 슬래시 명시 권장), handoff 는 **양방향 자동 감지**(작업종료=저장 / 세션시작=복원).

### 4. sync = true mirror
`sync.sh` 의 SSOT 는 repo 가 추적 중인 것 — `skills/` 의 디렉토리 목록. 새 스킬 배포 시작은 `skills/<name>/` 디렉토리를 **먼저 만든 뒤** sync. live 에서 지운 파일도 `--delete` 로 repo 에 반영됨(strict 미러). git history 가 안전망.

### 5. craft-core 실행 모드 — linear / orchestrated
craft 엔진은 **두 토폴로지**를 가진다. **linear**(기본, `pipeline.md`) = 단일세션이 전 페이즈 수행. **orchestrated**(`references/orchestrated.md`) = 멀티에이전트 — Phase 1+2 팀모드 council(designer+adversary 영속 opus, 수렴 루프), Phase 3 Workflow TDD(**sonnet** — dynamic-tdd 의 opus pin 의도적 override), Phase 4 Workflow 검증 fan-out(QA/tester/security opus) + 살아있는 designer 의 intent 판정, Phase 5 팀 shutdown.

핵심: orchestrated 는 **별도 스킬이 아니라 강도(intensity) 선택**으로, 작업타입과 직교한다. forge/renew/hunt 어느 것이든 유저가 명시적으로 council/팀+워크플로/maximum rigor 요청 시 엔진이 orchestrated 로 에스컬레이트(`pipeline.md` → Execution mode). 호출 스킬의 Phase 1 focus + Phase 3 TDD 진입점을 그대로 쓴다. **트리거는 task-type 스킬이 이미 이긴 뒤 엔진 내부 분기**라 형제 스킬 트리거 경쟁이 없다(과거 별도 `convene` 스킬이 가졌던 문제를 모드화로 제거). 무겁고 비싼 경로 — 설계 리스크 클 때만. `shutdown_request` 로 팀 정리 필수. Workflow `agent()` 호출(구현/검증/패널)은 모두 기본 subagent 로 돈다 — 프롬프트가 곧 계약이고, 모델은 phase 계약대로 명시 pin(Phase 3 linear=opus, orchestrated=sonnet; Phase 4 패널=opus).

### 6. deep-plan = Phase 0+1 만 차용하는 plan-only craft consumer
`deep-plan` 은 craft 빌드 엔진과 **같은 검증된 페이즈**(Socratic + grounding + plan + HTML companion)를 쓰되 **Phase 0+1 에서 멈춘다** — Phase 2(codex)·3(TDD)·4(보안)·5(wrap) 에 진입하지 않고, 구현 코드를 한 줄도 쓰지 않으며, deep-interview 처럼 빌드로 *자동 라우팅* 하지 않는다(순수 산출). **단 종료 시(Step 5) 다음 스킬을 `AskUserQuestion` 으로 *제안*만 한다 — 시작은 사용자 몫(제안 ≠ 자동 시작).** 재사용 소스(복제 금지 — 한 소스를 읽어 drift 차단): 인터뷰·grounding `craft-core/references/socratic.md`+`context-adr.md`, plan 섹션+**HTML companion 분기** `craft-core/references/pipeline.md` Phase 1, 모호할 때의 측정 게이트·6 Socratic 유형 `deep-interview/references/scoring.md`+`socratic-playbook.md`, **다음 스킬 추천 `deep-interview/references/next-skill-routing.md`(deep-* 공통)**. **적응형 게이트:** 요청이 이미 crisp(goal+scope+criteria 명확)면 인터뷰 스킵, 모호하면 ambiguity≤threshold 게이트 인터뷰. **HTML companion** 은 craft 와 동일 분기 — UI plan 이면 결과 UI 목업, 비UI 면 plan 렌더, 혼합이면 둘 다([[craft-html-companion-ui-mockup]] 규칙 공유). craft-core·deep-interview 미설치 폴백: 같은 원리 직접 적용. guard-readme-fresh 가 `skills/deep-plan` 링크를 강제하므로 README 스킬 표에 행이 있어야 PR 통과.

## Skill authoring 검증

스킬을 저작/수정한 뒤 검증할 때(carpdm-skills 고유 — 글로벌 rules 가 아니라 여기 둔다):

- **`node --check` 로 스킬 skeleton 을 검증하지 말 것.** skeleton 은 async wrapper 안에서 실행돼 `node --check` 가 false `'Illegal return statement'` 를 뱉는다. 마크다운+frontmatter 구조는 frontmatter 파싱·필수 키(`name`/`description`) 존재·`references/*` 경로 확인으로 검증한다.
- **스킬 트리거(`description`) eval 은 synthetic 단독으로 신뢰하지 말 것.** synthetic 매칭은 name-collision·sibling-skill 경쟁 artifact 로 false 0/100 을 낸다(실측). 실제 `~/.claude/skills/` 에 설치한 뒤 (a) 트리거 매칭 정확도와 (b) sibling-skill 오발화를 보는 **real-env probe** 를 병행한다.

## Editing workflow
정식 개발 루프: live `~/.claude/skills/<name>/` 편집 → `bash sync.sh` 로 repo 반영 → 리뷰 → `--push`. repo 에서 직접 편집했다면 `install.sh` 로 live 반영. 두 방향 혼용 시 마지막 동기화 방향 주의 (`--delete` 미러라 한쪽이 SSOT).

## Work-end check (Stop hook)
작업 종료 시 글로벌 스킬이 repo 에 미반영이거나 push 안 됐으면 `.claude/hooks/check-skill-sync.sh` (Stop hook, `.claude/settings.json` 등록)가 **비차단 경고**. 감지: (a) live↔repo drift (skills 디렉토리별) → `bash sync.sh`, (b) `skills/` 미커밋, (c) 미push 커밋 → `bash sync.sh --push`. 감지·알림만 — auto-push 안 함(외부발신·비가역). 경고 뜨면 직접 sync/push 로 마무리.

## PR-time README check (PreToolUse hook)
`gh pr create` 직전 `.claude/hooks/guard-readme-fresh.sh` (PreToolUse:Bash hook)가 README.md 가 모든 `skills/<name>` 디렉토리를 링크하는지 확인 — 누락 시 **차단(exit 2)** 하고 누락 스킬을 출력한다. 스킬을 추가/삭제하면 같은 PR 에서 README 스킬 표·카운트를 갱신할 것. Stop hook(비차단)과 달리 이건 **차단형** — README drift 가 PR 에 실리는 것을 막는다. Override: `README_FRESH_DISABLE=1`. 체크는 `skills/<name>` 링크 존재만 보며, 표 내용 정확성까지는 검증하지 않으니 행 내용은 수동 관리.
