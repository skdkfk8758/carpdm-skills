# carpdm-skills — Project Rules (SSOT)

> 이 파일이 프로젝트 지침 SSOT. AGENTS.md 는 빌드 산출물(글로벌 `~/.claude/rules/` + 본 파일 concat).
> `build-agents-md.sh` 미설치 동안 AGENTS.md 는 본 파일을 수동 미러링한다 — 본 파일만 편집하고 AGENTS.md 는 재생성.

## What this repo is

Claude Code 글로벌 스킬 **배포 레포**. 빌드/런타임 없음 — 스킬은 마크다운(`SKILL.md` + `references/*.md`)이고 `~/.claude/skills/` 로 복사돼야 동작한다. 코드 컴파일·테스트·린트 단계 없음.

스킬 인벤토리·개별 역할의 SSOT 는 각 `skills/<name>/SKILL.md` frontmatter `description:` — 여기 복제하지 않는다(drift 차단). 아키텍처 결합·설계 결정은 아래 §1~§13. 현재 스킬 dir 목록은 `ls skills/`. 그룹 개요:
- 빌드 파이프라인: `forge`(신규)/`hunt`(버그)/`renew`(개편) + 공유엔진 `craft-core`(§1·§5) + 경량 escape-hatch `tdd`(codex 리뷰·보안 페이즈 없는 red-green-refactor 단독 — 풀 파이프라인 아님)
- plan·인터뷰(산출만, 빌드 안 함): `deep-interview`(standalone) · `deep-plan`(§6) · `deep-prompt`(자율 잡용 Goal Prompt 저작)
- 운영: `handoff` · `sweep` · `land` · `wt-sweep`(워크트리·세션기록 정리는 wt-sweep 단독 소관 — land 는 워크트리를 건드리지 않고 Report 로 안내만; 절차 SSOT 는 wt-sweep `references/sweep-mode.md`) · `ship`(§10)
- 검토·판정(코드 한 줄 안 고침, 리포트+수정 라우팅만): `preflight`(§9) · `fortify`(§12)
- UI·도식: `imprint`(수동 추출 DESIGN.md *준수* 재현 — 발명 아님, token-traceability: raw hex/px 하드코딩 0) · `mockup`(기존 프로젝트 충실 HTML 시안; `references/design-context.md` 가 시안 충실도 SSOT — deep-plan·craft pipeline·deep-prompt 가 이 한 소스를 읽는다, 복제 금지) · `erd`(§8)
- 스캐폴딩·셋업: `cicd-scaffold` · `admap-scaffold` · `colocate-domain-context` · `loop-harness-setup`
- Linear 라이프사이클: `linear-register`/`linear-goal`/`linear-groom`/`linear-prioritize` — `## 추천` 생성 규칙은 `linear-register/references/recommend-section.md` SSOT 공유(복제 금지); 모두 graceful — Linear MCP 미설치면 가이드 한 번+스킵. `linear-groom` 은 무인 주기 실행(orca automation)용 **scan-only** 모드 보유(§14)
- 하니스 오케스트레이션: `harness-run`/`eval-generate`/`eval-check`/`harness-heal`(§13)

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
| `bash sync.sh --push` | 미러 + `chore/sync-<ts>` 브랜치·PR·**즉시 머지** 자동 (`gh` CLI 필요). master 직접 push 금지 환경 대응. CI·승인 게이트 없는 빠른 경로 |
| `bash sync.sh --pr-only` | 미러 + 브랜치·커밋·push·PR **생성까지만** (머지 보류). 브랜치를 로컬에 남겨 CI 게이트+land 를 `ship` 스킬이 처리 (§10) |
| `ls ~/.claude/skills/` | 스킬 설치 검증 — `forge hunt renew handoff sweep land ship craft-core` 보여야 함 |

검증 스위트는 없다. "테스트"는 `install.sh`/`sync.sh` 실행 + `ls` 확인이 전부.

## Architecture — 반드시 알 것

### 1. craft-core 절대경로 결합 (깨지기 쉬움)
파이프라인 3종 + `deep-plan` 은 craft-core 엔진을 **하드코딩 절대경로**로 읽는다:
`~/.claude/skills/craft-core/references/pipeline.md`. 따라서:
- 설치 경로는 `~/.claude/skills/` **고정**. 다른 위치면 4종 전부 깨짐.
- forge/hunt/renew **그리고 deep-plan** 은 craft-core 와 **항상 함께** 설치돼야 함 (deep-plan 은 deep-interview references 도 차용 — §6). handoff·sweep·land 는 craft-core **엔진(pipeline) 무의존** — 단 종료 출력은 craft-core 의 `output-contract.md` 를 공유 참조한다(§7, 엔진 결합 아니라 출력 규격 한 장).
- craft-core 는 `user-invocable: false` — 직접 트리거 금지, 컨테이너일 뿐.

### 2. 공유 4-phase 파이프라인 (craft-core/references/pipeline.md)
Socratic 인터뷰 → codex 적대적 플랜 리뷰(`codex:rescue` 플러그인) → 동적 워크플로 TDD(sonnet) → 보안 검증.
각 작업유형 스킬은 이 엔진 위에 **자기 Phase 1 Socratic 초점 + Phase 3 TDD 진입점**만 얹는다 (SKILL.md 본문은 짧음 — 차이만 기술). 공통 Phase 0/2/4/5 는 엔진 그대로.
- `codex:rescue` 미설치 시 Phase 2 는 수동 리뷰로 폴백.
- 참조 분리: `socratic.md`/`codex-review.md`/`dynamic-tdd.md`/`security.md`/`context-adr.md` — phase 필요 시 lazy load. `output-contract.md` 는 phase 참조가 아니라 **전 스킬 공통 종료 출력 규격**(§7). `linear.md` 는 **Linear 연동 공유 SSOT**(§11) — 엔진 의존 아닌 공유 한 장.
- **Linear 라이프사이클 wiring (§11):** Phase 0 에 `linear.md` 바인딩(활성 이슈→In Progress), Phase 5 wrap 에 verify green→In Review 를 주입(개별 SKILL.md 안 건드림). 셋 다 graceful — Linear 미설치/이슈 없으면 무시하고 평소대로.

### 3. SKILL.md frontmatter = 트리거
`name` + `description` 만. `description` 이 자연어 트리거 매칭을 좌우 — 파이프라인 3종은 **언더트리거 설계**(과발화 방지, 슬래시 명시 권장), handoff 는 **양방향 자동 감지**(작업종료=저장 / 세션시작=복원).

### 4. sync = true mirror
`sync.sh` 의 SSOT 는 repo 가 추적 중인 것 — `skills/` 의 디렉토리 목록. 새 스킬 배포 시작은 `skills/<name>/` 디렉토리를 **먼저 만든 뒤** sync. live 에서 지운 파일도 `--delete` 로 repo 에 반영됨(strict 미러). git history 가 안전망.

### 5. craft-core 실행 모드 — linear / orchestrated
craft 엔진은 **두 토폴로지**를 가진다. **linear**(기본, `pipeline.md`) = 단일세션이 전 페이즈 수행. **orchestrated**(`references/orchestrated.md`) = 멀티에이전트 — Phase 1+2 팀모드 council(designer+adversary 영속 opus, 수렴 루프), Phase 3 Workflow TDD(**sonnet** — dynamic-tdd 의 opus pin 의도적 override), Phase 4 Workflow 검증 fan-out(QA/tester/security opus) + 살아있는 designer 의 intent 판정, Phase 5 팀 shutdown.

핵심: orchestrated 는 **별도 스킬이 아니라 강도(intensity) 선택**으로, 작업타입과 직교한다. forge/renew/hunt 어느 것이든 유저가 명시적으로 council/팀+워크플로/maximum rigor 요청 시 엔진이 orchestrated 로 에스컬레이트(`pipeline.md` → Execution mode). 호출 스킬의 Phase 1 focus + Phase 3 TDD 진입점을 그대로 쓴다. **트리거는 task-type 스킬이 이미 이긴 뒤 엔진 내부 분기**라 형제 스킬 트리거 경쟁이 없다(과거 별도 `convene` 스킬이 가졌던 문제를 모드화로 제거). 무겁고 비싼 경로 — 설계 리스크 클 때만. `shutdown_request` 로 팀 정리 필수. Workflow `agent()` 호출(구현/검증/패널)은 모두 기본 subagent 로 돈다 — 프롬프트가 곧 계약이고, 모델은 phase 계약대로 명시 pin(Phase 3 linear=opus, orchestrated=sonnet; Phase 4 패널=opus).

### 6. deep-plan = Phase 0+1 만 차용하는 plan-only craft consumer
`deep-plan` 은 craft 빌드 엔진과 **같은 검증된 페이즈**(Socratic + grounding + plan + HTML companion)를 쓰되 **Phase 0+1 에서 멈춘다** — Phase 2(codex)·3(TDD)·4(보안)·5(wrap) 에 진입하지 않고, 구현 코드를 한 줄도 쓰지 않으며, deep-interview 처럼 빌드로 *자동 라우팅* 하지 않는다(순수 산출). **단 종료 시(Step 5) 다음 스킬을 `AskUserQuestion` 으로 *제안*만 한다 — 시작은 사용자 몫(제안 ≠ 자동 시작).** 재사용 소스(복제 금지 — 한 소스를 읽어 drift 차단): 인터뷰·grounding `craft-core/references/socratic.md`+`context-adr.md`, plan 섹션+**HTML companion 분기** `craft-core/references/pipeline.md` Phase 1, 모호할 때의 측정 게이트·6 Socratic 유형 `deep-interview/references/scoring.md`+`socratic-playbook.md`, **다음 스킬 추천 `deep-interview/references/next-skill-routing.md`(deep-* 공통)**. **적응형 게이트:** 요청이 이미 crisp(goal+scope+criteria 명확)면 인터뷰 스킵, 모호하면 ambiguity≤threshold 게이트 인터뷰. **HTML companion** 은 craft 와 동일 분기 — UI plan 이면 결과 UI 목업, 비UI 면 plan 렌더, 혼합이면 둘 다([[craft-html-companion-ui-mockup]] 규칙 공유). **ERD companion(추가 축):** plan 이 DB 스키마/BE 데이터모델 변경을 수반하면 design companion 과 *별개로* ERD HTML 도 생성한다 — `erd` 스킬(§8)을 한 소스로 읽어(`erd/SKILL.md`+`assets/erd-template.html`+`references/schema-discovery.md`, 복제 금지) plan 동일 디렉토리·basename 에 `-erd.html` 산출. 스키마/관계가 plan 핵심일 때만(컬럼 한둘은 과투자), `erd` 미설치면 ERD 만 생략. craft-core·deep-interview·erd 미설치 폴백: 같은 원리 직접 적용. guard-readme-fresh 가 `skills/deep-plan` 링크를 강제하므로 README 스킬 표에 행이 있어야 PR 통과. **Linear 등록(Step 4.5, 추가 축):** PLAN 산출 뒤 이를 Linear 작업 트리(parent 1 + Step별 sub-issue)로 등록할지 *제안*한다 — `craft-core/references/linear.md`(§11)를 한 소스로 읽어 따른다(복제 금지). 이슈 생성은 외부 write 라 확인 게이트, Linear MCP 없으면 가이드 한 번+스킵. PLAN 자체는 Linear 없이도 완전한 산출물이라 등록은 부가 단계.

### 7. 전 스킬 공통 출력 contract (craft-core/references/output-contract.md)
모든 스킬의 **종료 출력**을 한 SSOT 로 정규화한다 — `output-contract.md` 하나를 읽어 emit(복제 금지, drift 차단). 통일 대상은 *출력 전체가 아니라 종료 레이어*다 — 산출물 본문(commit/`.md`/삭제목록/PR 보고)은 성질이 달라 억지 통일하면 의미가 깨지므로 그대로 둔다. 3레이어:
- **L1 `result:` 1줄 — 전 스킬 의무.** 백그라운드 잡 classifier 가 메시지 텍스트만 읽어 완료를 판정하는데, `result:` 가 그 유일한 신호다. 이전엔 deep-interview/deep-plan 2종만 emit → forge/hunt/sweep/land 등은 완료 미감지(버그성)였고, 본 contract 가 전 스킬로 확장했다.
- **L2 산출물 열기 블록(`open` 경로) — 파일 산출 스킬만**(deep-*/deep-prompt/imprint/handoff). commit·삭제·머지 보고형(forge/hunt/renew/sweep/land)은 비적용 — git 상태 변화라 각자 보고.
- **L3 다음 스킬 제안(`AskUserQuestion`) — 전진형만**(deep-*/빌드 3종). 운영(sweep/land/handoff)은 `next-skill-routing.md` 가 "다음 후보 아님"으로 배제 → L3 비적용. 규칙은 `next-skill-routing.md` SSOT 를 포인터로만 참조(재기술 안 함).
- 빌드 3종의 L1+L3 은 `pipeline.md` Phase 5 한 곳에서 주입(개별 SKILL.md 안 건드림). craft-core 에 두지만 엔진 의존 아님 — handoff·sweep·land 도 이 한 장만 읽는다(§1). line 10 의 `standalone`/`craft-core 무의존` 표기는 *엔진(pipeline)* 무의존을 뜻하며 output-contract 공유와 무관.

### 8. erd = standalone ERD 도식 스킬 + deep-plan 의 ERD companion 소스
`erd` 는 DB 스키마를 self-contained HTML ERD 로 그리는 독립 스킬이다. 두 가지로 쓰인다 — (a) 직접 트리거("이 마이그레이션 ERD 그려줘"), (b) **`deep-plan` 의 DB/BE companion 소스**(§6). 핵심 설계:
- **SVG wire 엔진 verbatim.** `assets/erd-template.html` 의 `<script>`(베지어 자동 라우팅 `edgePoint`/`draw` + crow's foot 글리프 `footMany`/`barOne`)는 검증된 채로 들어 있어 **재작성 금지** — 매 호출이 채우는 건 테이블 카드·`EDGES`(`[from,to,label,kind]`)·그룹 라벨·레이아웃(절대배치)뿐. 베지어/글리프를 손으로 다시 쓰면 미묘하게 틀어진다. skill-creator 의 "반복 작업은 한 번 짜서 bundle" 원칙 적용 — 6 placeholder 만 채운다. **crow's foot 은 SVG `<marker>` 가 아니라 일반 path 로 직접 stroke** — 동적 생성 path 에서 marker 페인트가 불안정(실측: 정적 svg 는 렌더, JS 생성 path 는 marker 미페인트)해 글리프를 좌표 계산해 그린다.
- **시각 문법(dbdiagram 풍 카드):** 테이블 클래스 hub(녹)/lookup(보라)/dep(적)/일반(슬레이트). 컬럼 행 = 좌측 컬럼명+인라인 아이콘(`ic-pk` 열쇠 / `ic-fk` 링크 / `ic-soft` 링크·연보라 / `ic-note` 노트·코멘트 툴팁) ⟶ 우측 데이터 타입(mono)+제약 pill(`NN`/`UQ`)+선택 코멘트 라인(`.cmt`). 관계선 fk(green)/hier(gray)/dep(red dashed)/soft(purple dashed) 끝점에 crow's foot(자식 many 갈래발/부모 one 바). 판정 기준·소스별 스키마 재구성법은 `references/schema-discovery.md`(lazy load).
- **그리기만, 안 바꿈.** 마이그레이션 작성·DB 변경은 erd 의 일이 아니다(forge/renew). 추측 금지 — 못 본 테이블/관계는 그리지 않고 footer 에 한계 명시.
- **자동 레이아웃 도입 금지(YAGNI).** 위치는 손으로, 엔진은 wire 만 자동. 거대 스키마는 중심 hub + 1홉으로 좁히거나 보조군을 한 카드로 접는다.
- output-contract: 산출(단발)군 — L1 `result:` + L2 열기 블록, L3 비적용(§7). standalone 이지만 종료 출력은 output-contract 공유(엔진 의존 아님).
- DESIGN.md 가 컨텍스트에 있으면 `:root` 색/타이포 토큰만 mirror(레이아웃/아이콘/뱃지/edge 토큰은 보존). imprint 수준 token-traceability 는 도식엔 과투자 — 색만 맞춘다.

### 9. preflight = standalone 배포 전 최종 검토·판정 스킬
`preflight` 는 앱 완성 후 **배포 직전** 전체를 보고 ship 여부를 판정하는 독립 스킬이다(craft 엔진 무의존, output-contract 공유). 핵심 설계:
- **재발명 금지(DRY) — 전문 리뷰어 호출 합성.** correctness 는 `/code-review`, 보안은 `/security-review` 를 *호출*해 결과를 합성한다(직접 재구현 안 함). preflight 고유 차원(유지보수·중복/복잡성·UX/UI·반응형·확장 구조·기술부채)만 직접 본다. 매칭 리뷰어 미설치면 그 사실을 말하고 직접 검토. 이게 `code-review`/`security-review`/`improve-codebase-architecture` 와의 직교 포지션 — preflight 은 *합성기 + 배포 판정*이지 또 하나의 코드 리뷰어가 아니다.
- **적응형 토폴로지.** 작은 앱/적은 변경 = 메인이 10차원 린 단일 패스. 큰 앱 또는 "철저히/maximum" 요청 = 차원군별(코드건강/런타임/UX·UI/보안/기술부채) 병렬 subagent fan-out 후 합성. craft 의 linear/orchestrated 와 같은 *강도 직교* 패턴(Workflow 아님 — 병렬 Agent subagent 로 충분, 더 단순).
- **고정 포맷 + severity 루브릭.** 사용자가 습관적으로 붙이는 10기준 프롬프트의 출력 포맷을 verbatim 템플릿으로 박았다(반드시수정/수정하면좋음/유지/리팩토링/배포가능여부/우선순위 + 기술부채 섹션). blocker/should/keep/refactor 와 GO/조건부GO/NO-GO 는 감이 아니라 루브릭으로 — 보안 불변식은 항상 blocker(NO-GO). 모든 발견은 `path:line` 증거 + 보고 전 적대적 재검증(거짓 양성 금지).
- **검토만, 안 고침.** preflight 은 코드를 한 줄도 안 바꾼다(forge/renew/hunt/simplify 가 수정). 산출물군 — L1 `result:` + L2 리포트 열기(`docs/reviews/…-preflight.md`) + L3 **수정 라우팅**(발견→수정 스킬, next-skill-routing 의 산출물 전진과 다른 메커니즘 — output-contract §L3 참조). 상세 차원 체크리스트·기술부채 인벤토리는 `references/audit-checklist.md`(lazy load).

### 10. ship = 이 레포 전용 PR→CI→land 배포 스킬
`ship` 은 carpdm-skills 의 개발 루프(라이브 편집 → repo 미러 → PR → 머지)를 **CI 게이트를 끼운 안전한 한 흐름**으로 묶는 운영 스킬이다. craft 엔진 무의존(land/sweep/handoff 동급), output-contract L1 `result:` 공유. 핵심 설계:
- **`sync.sh --push` 와의 분리가 존재 이유.** `--push` 는 PR 생성과 동시에 즉시 머지(line 49-65)라 CI·검토 게이트가 없다 — 그래서 `--push` 직후 `land` 를 돌리면 머지할 PR 이 비는 게 정상이었다(실측). ship 은 이를 갈라, `sync.sh --pr-only`(신규 — 미러+커밋+push+PR 까지만, 머지 보류, 브랜치를 로컬에 남김)로 PR 만 올리고 → `gh pr checks --watch` 로 CI 를 기다린 뒤 → **승인 게이트 1회** → squash 머지 + 로컬정리. 즉 "PR 올리고 land 까지" 를 머지 전 멈춤이 있는 흐름으로 잇는다.
- **단일 sync PR 전용 — land 의 stack 처리 미차용(YAGNI).** sync 브랜치는 항상 독립·단일이라 land 의 topological merge·re-base·dirty 워크트리 stack 케이스가 필요 없다. land 의 *안전 규율*(머지 검증 후 삭제, squash 가 `-d` 를 깨면 `gh pr view … MERGED` 확인 후 `-D`, force 금지)만 차용하고 multi-PR 일반화는 인라인하지 않는다. 범용 다중 PR/워크트리 정리는 여전히 `land` 의 일.
- **비가역 액션 계약 = land 와 동일.** 발견→PR→CI→플랜 1회 승인→머지→정리→보고. CI 실패·머지 막힘이면 중단하고 PR·브랜치를 복구 가능 상태로 남겨 보고(미납품), 머지 안 된 브랜치는 절대 삭제 금지.
- output-contract: 머지 보고형 — L1 `result:` 만(L2 열기·L3 다음 스킬 제안 비적용, git 상태 변화라 §7 land 와 동렬).

### 11. Linear 통합 = 공유 SSOT 한 장으로 plan→build→merge 라이프사이클 wiring
`craft-core/references/linear.md` 는 Linear 연동 단일 SSOT 다(output-contract 처럼 craft-core 에 두지만 **엔진 의존 아닌 공유 한 장** — deep-plan·forge·renew·hunt·land 가 모두 이 한 소스를 읽는다, 복제 금지). 세 가지를 정의: (1) MCP 감지 + 미설치 시 설치 가이드 한 번/스킵, (2) PLAN→Linear 이슈 트리 등록, (3) 빌드 중 상태 자동 전이. 설계 결정:
- **이슈 granularity = parent 1 + PLAN Step 별 sub-issue.** Step 이 atomic 작업 단위라 빌드 스킬이 sub-issue 하나씩 집어 작업하기 자연스럽다(Phase 3 task split 이 Step 과 정렬 → sub-issue 와도 정렬). Acceptance 는 sub-issue body 에 참조로(Acceptance 단위로 쪼개지 않음). 작은 plan 은 단일 이슈로(트리 과투자 회피).
- **생성은 확인 게이트, 전이는 자동.** 이슈 생성은 외부 write 라 트리 미리보기→동의 후에만(deep-plan Step 4.5). 상태 전이(In Progress/In Review/Done)는 저위험 라벨 변경이라 자동 — 매번 안 묻는다. 전이 맵: 빌드 시작(pipeline Phase 0)→In Progress, Phase 4 green+Acceptance 닫힘(Phase 5 wrap)→In Review, 머지(land Step 5)→Done. 상태 이름은 `list_issue_statuses` 로 실제 조회 후 매핑(하드코딩 금지).
- **graceful 불변식.** Linear MCP 미설치이거나 활성 이슈 없으면 **묻지 말고** Linear 없이 진행 — Linear 는 워크플로를 증강할 뿐 게이트하지 않는다. 상태 전이 실패(권한·네트워크)도 빌드/머지를 막지 않는다(경고만). plan 도 빌드도 Linear 없이 완전한 산출물.
- **도구 이름 비하드코딩.** 공식 원격 서버(`mcp.linear.app/mcp`, HTTP, OAuth)의 정확한 툴 이름은 비문서화·버전 가변 → 스킬은 실제 available tools 확인/`ToolSearch` 로드로 가이드하고 `mcp__linear__*` 류를 추측 단언하지 않는다.
- wiring 은 공유 지점(pipeline Phase 0/5, land Step 5, deep-plan Step 4.5) 한 곳씩만 주입 — 개별 빌드 SKILL.md(forge/renew/hunt)는 안 건드린다(pipeline.md 하나로 3종 동시 적용). `linear.md` 표기상 standalone 무관 — output-contract 처럼 엔진 결합이 아니라 공유 reference.

### 12. fortify = standalone 배포 전 보안 감사·판정 스킬
`fortify` 는 웹서비스를 운영에 올리기 직전 **보안 한 축만** 보고 배포 보안 판정을 내는 독립 스킬이다(craft 엔진 무의존, output-contract 공유). preflight 의 보안 차원을 별도 스킬로 심화한 것. 핵심 설계:
- **포지셔닝 = preflight 직교.** preflight 은 보안 포함 *10차원 종합* 배포 판정(GO/조건부GO/NO-GO). fortify 는 *보안 한 축* 을 5 카테고리(① 앱·코드 ② 인증·권한 ③ 데이터·통신 ④ 인프라·네트워크 ⑤ 로깅·백업)로 더 깊게 — 라이브 probe + 인프라 체크리스트까지. 종합은 preflight, 보안만 깊게면 fortify. 둘 다 코드를 안 고치고 검토·판정·수정 라우팅 제안만(forge/renew/hunt 와 직교).
- **재발명 금지(DRY).** 카테고리 ①(코드 보안 — OWASP/주입/XSS)은 `/security-review` 를 *호출*해 합성(직접 재구현 안 함). 나머지 운영 포스처(인증·데이터·인프라·로깅)는 전문 리뷰어가 없으니 fortify 가 직접. security-review(diff 보안만)와의 직교 포지션 — fortify 는 *운영 전체 포스처 합성기 + 보안 게이트*다.
- **3-상태 판정이 핵심.** 항목별 **PASS**(증거로 충족) / **FAIL**(증거로 위반) / **확인필요**(코드·probe 로 안 보임). 인프라 항목(방화벽·서브넷·WAF·DDoS·백업복구 테스트)은 대부분 코드 밖이라 추측 PASS 금지 — 정직하게 확인필요로 사람에게 넘긴다. 확인필요가 남으면 최소 조건부 PASS(미확인 인프라를 PASS 로 봉하지 않음). 모든 PASS/FAIL 은 `path:line` 또는 probe 출력 증거 + 보고 전 적대적 재검증.
- **라이브 probe = 읽기전용 비침투만.** 사용자 소유 대상 한정·사전확인 후 `curl -sI`(보안헤더/쿠키), `openssl s_client`(TLS 버전/cipher), `npm/pnpm/pip audit`(의존성 CVE)만. **공격성 스캔(nmap 포트스캔·sqlmap/nikto 익스플로잇·DoS·무차별 대입·미인가 대상)은 거부** — 방어적 감사 도구이지 침투 테스트가 아니다. 대상 소유권 불확실하면 정적 + 확인필요로만.
- **고정 포맷 + severity 루브릭.** 사용자 5-카테고리 체크리스트를 verbatim 리포트 템플릿으로 박았다(카테고리별 결과 + 반드시막음/보완권장/확인필요/판정/우선순위). blocker/should/keep 와 PASS/조건부PASS/FAIL 은 감이 아니라 루브릭 — 보안 불변식(auth/payment/crypto/권한경계·비밀노출·평문비번)은 항상 blocker(FAIL). 상세 카테고리 체크리스트·정적 패턴·probe 명령 카탈로그는 `references/security-checklist.md`(lazy load).
- **검토만, 안 고침.** 코드 한 줄 안 바꾼다(수정은 hunt/renew/forge). 산출물군 — L1 `result:` + L2 리포트 열기(`docs/reviews/…-fortify.md`) + L3 수정 라우팅(발견→hunt 보안버그/renew 인증동작변경/forge 누락보안기능, output-contract §L3 메커니즘). standalone 이지만 종료 출력은 output-contract 공유(엔진 의존 아님).

### 13. 하니스 오케스트레이션 4종 (harness-run/eval-generate/eval-check/harness-heal) — IA→글로벌 SSOT 이관 진행 중
loop/eval-게이트 자율개발 하니스의 실행 스킬 4종. **SSOT 가 글로벌(본 레포 추적)로 이관 완료**됐다 — 종전 SSOT 는 `~/Workspace/Intelligence-Auth/.claude/skills/`(하니스 origin)였고 글로벌은 무버전 미러였으나, 사용자 결정으로 **글로벌 단일 SSOT** 로 수렴했다(IA 사본 제거 완료).
- **추적 내용 = 글로벌 변형 정본(절대경로).** harness-run·eval-generate·eval-check 의 `SKILL.md`·workflow scriptPath 는 cwd-무관 동작을 위해 `/Users/carpdm/.claude/skills/...` **구체 절대경로**를 쓴다(Workflow scriptPath 는 프로젝트 cwd 가 아니라 skills 디렉토리에 resolve 돼야 함 → 상대·`~` 불가). **2단계에서 이식성 해결:** `install.sh` 가 설치 시 `/Users/carpdm/.claude/skills` → `$HOME/.claude/skills` 로 home prefix 재작성(메인테이너 머신 = no-op, 타 머신 = 그 머신 경로). 단방향이라 `sync.sh`(글로벌→repo, carpdm 머신서만 실행)는 no-op 왕복 → repo 오염 없음. 따라서 본 레포의 "어느 머신이든 동작" 불변식 충족.
- **결합 세트.** harness-run 이 eval-generate(rubric 생성)·eval-check(채점)·harness-heal(단락 자가개선)을 호출하는 한 묶음 — 4종은 함께 추적/이동한다. 상세 하니스 구조(게이트 G0~G4·3역할 분리·decideNext·C4 heal)는 글로벌 rule `loop-visualization` + IA `loop/` 가 SSOT.
- **이관 완료(①~④):** ① git 집 확보(carpdm-skills 추적) → ② 경로 전략(install.sh home-prefix 재작성) → ③ 글로벌 단독 동작 검증(4스킬 존재·Workflow scriptPath 유효·단위테스트 loop-control 9/9·attribution 5/5·IA 실행 하드의존 0) → ④ IA `.claude/skills/{harness-run,eval-generate,eval-check,harness-heal}` 삭제 + harness-run 글로벌 SSOT 노트 갱신. (`loop-visualization.md` 의 IA 참조는 IA `docs/guides/`·`loop/` 를 가리켜 삭제 무관 — 갱신 불요. 전체 harness-run 실측 완주는 실 이슈 발생 시 자연 검증.)

### 14. linear-groom scan-only = 승인 게이트 스킬을 무인 주기 실행에 붙이는 방식

`linear-groom` 의 핵심 불변식은 "모든 write 는 승인 게이트 뒤"인데, 주기 automation 에는
승인할 사람이 없다. 게이트를 그대로 두면 표만 내고 반영 0건, 게이트를 프롬프트로 우회하면
모델의 비결정론 배치 판정이 사람 눈 없이 누적된다(재배치 churn·본문 덮어쓰기). 그래서
**write 를 빼고 발견만 남기는 모드**를 명시 분기로 뒀다 — 자동화의 가치는 반영이 아니라
"고아 N건·빈약 M건이 생겼다"의 주기적 발견에 있다는 포지셔닝. 설계:

- **Step 0~3 은 기본 모드와 동일**(전수 조회·결정론 분류·매핑·중복·프로젝트 위생 판정),
  Step 4 표를 지정 Linear 이슈 코멘트로 게시하고 Step 5·6 미실행. `save_issue`/`save_project`
  전면 금지, 허용 write 는 **리포트 코멘트 1건**(이슈 필드가 아닌 append 라 백로그 미오염).
- **진입은 프롬프트에 `scan-only` 명시일 때만** — 무인처럼 보인다고 스스로 내려가면
  사용자는 반영된 줄 안다. 상세는 `linear-groom/references/scan-only.md`(SSOT, lazy load).
- **알림 피로 가드 2개**: 갭 0건인 주는 코멘트 생략(실행 여부는 `orca automations runs`),
  리포트 이슈 자신은 스캔 대상에서 제외(안 그러면 매주 자기를 고아로 리포트).
- **운영 형상(2026-07-28)**: orca automation 4개(ADT/AUT/SSO/ADM) · 월 09:00 KST ·
  `--workspace-mode existing`(메인 워크트리 재사용 — 읽기 전용이라 트리 미오염, 워크트리
  쓰레기 0) · 리포트 이슈 ADT-416/AUT-76/SSO-98/ADM-164. 반영은 사람이 세션에서
  `/linear-groom` 실행. **은퇴 조건**: 리포트 코멘트가 3개월간 실제 그루밍으로 이어지지
  않으면(발견은 되는데 아무도 반영 안 하면) 자동화·리포트 이슈를 함께 폐지.

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
