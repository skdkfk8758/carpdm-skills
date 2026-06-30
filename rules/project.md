# carpdm-skills — Project Rules (SSOT)

> 이 파일이 프로젝트 지침 SSOT. AGENTS.md 는 빌드 산출물(글로벌 `~/.claude/rules/` + 본 파일 concat).
> `build-agents-md.sh` 미설치 동안 AGENTS.md 는 본 파일을 수동 미러링한다 — 본 파일만 편집하고 AGENTS.md 는 재생성.

## What this repo is

Claude Code 글로벌 스킬 **배포 레포**. 빌드/런타임 없음 — 스킬은 마크다운(`SKILL.md` + `references/*.md`)이고 `~/.claude/skills/` 로 복사돼야 동작한다. 코드 컴파일·테스트·린트 단계 없음.

스킬 25종: 작업유형 파이프라인 3 (`forge`/`hunt`/`renew`) + 심층인터뷰 1 (`deep-interview`) + 계획수립 1 (`deep-plan`) + goal프롬프트저작 1 (`deep-prompt`) + 세션인계 1 (`handoff`) + 정리유틸 1 (`sweep`) + PR 랜딩 1 (`land`) + 스킬배포 1 (`ship`) + 배포전최종검토 1 (`preflight`) + 배포전보안감사 1 (`fortify`) + UI충실재현 1 (`imprint`) + ERD도식 1 (`erd`) + 코드베이스컨텍스트셋업 1 (`colocate-domain-context`) + CICD스캐폴딩 1 (`cicd-scaffold`) + 루프하니스셋업 1 (`loop-harness-setup`) + 공유엔진 1 (`craft-core`) + Linear 라이프사이클 3 (`linear-register`/`linear-goal`/`linear-groom`) + 하니스 오케스트레이션 4 (`harness-run`/`eval-generate`/`eval-check`/`harness-heal`, §13). `imprint` 는 standalone (craft-core 무의존) — design-extractor 의 `DESIGN.md` 파일을 입력받아 그 디자인 시스템에 충실하게(token-traceability: raw hex/px 하드코딩 0, 없는 값은 derive 해 명시 기록) React+Tailwind 테마·예시 컴포넌트·독립 HTML 시안을 생성한다. `frontend-design`(자유 창작)과 반대 축 — 발명이 아니라 *준수*. 추출은 안 함(design-extractor API 없음 — 사람이 수동 추출한 DESIGN.md 만 소비). 공유엔진은 두 실행 모드를 가진다 — linear(기본) / orchestrated(멀티에이전트 council, §5). `deep-interview` 는 standalone (craft-core 무의존) — 모호한 아이디어를 소크라테스 인터뷰 + 수학적 ambiguity 게이트로 검증가능 spec 까지 끌어올린 뒤 빌드 파이프라인으로 핸드오프. 빌드는 안 함. `deep-plan` 은 craft-core 의 **Phase 0+1 만** 차용하는 4번째 craft consumer (§6) — (모호하면 적응형 인터뷰로 보강 후) 실행 가능한 PLAN 문서 + UI plan 이면 HTML 시안까지 산출하고 **멈춘다**. codex 리뷰·TDD·보안 등 빌드 페이즈는 진입하지 않으며, deep-interview 처럼 빌드로 *자동 라우팅* 하지 않는다 — 순수 산출(단 종료 시 다음 스킬을 `AskUserQuestion` 으로 *제안*만 함, 시작은 사용자 몫 — §6). `deep-prompt` 는 standalone (craft-core 무의존) — 자율/백그라운드 잡에 넣을 검증 가능한 Goal Prompt 를 고정 템플릿(Objective/Success Criteria/Context/Constraints/Verification/Out of Scope/Done & Report)으로 저작해 `.md` 로 저장한다. 성공 기준을 측정 가능하게 못 박아 사람 개입 없이 루프가 끝까지 돌게 하는 데 초점. 빌드는 안 함. `erd` 는 standalone (craft-core 무의존) — DB 스키마(라이브 DB introspection/마이그레이션/ORM 모델/repository 코드/산문/PLAN)를 입력받아 dbdiagram 풍 테이블 카드(컬럼명·타입·PK 열쇠/FK 링크/코멘트 아이콘·NN/UQ pill) + SVG 자동 라우팅 관계선(fk/hier/dep/soft 4종 색 + crow's foot)을 갖춘 self-contained HTML ERD 를 그린다. 핵심 자산은 `assets/erd-template.html`(토큰 CSS + 아이콘 mask + **SVG wire 엔진 verbatim** — 베지어 라우팅 + crow's foot 글리프는 매번 재작성 금지). 스키마를 그릴 뿐 마이그레이션을 작성하거나 DB 를 바꾸지 않는다. `deep-plan` 이 DB/BE plan 일 때 ERD companion 으로 차용한다 (§8). `colocate-domain-context` 는 standalone (craft-core 무의존) — 도메인별 `CLAUDE.md` 를 코드 옆에 두어(경로 근접 auto-load) 도메인 함정·지식을 코드와 같이 두고, 코드만 바뀌고 문서가 안 따라오면 경고하는 co-update 게이트(`scripts/coupdate-check.sh`)를 셋업한다. 프로젝트 구조와 verify host(verify.sh/husky/pre-commit/CI/Makefile/none)에 적응한다 — ADMap 고유 결합을 제거하고 패턴만 일반화했다. 루트 `CLAUDE.md` 신규 작성(init)·일반 리팩터(renew)·코드→문서 자동생성과는 다르다(사람 유지·게이트 flag 방식의 colocated 컨텍스트 셋업). `preflight` 는 standalone (craft-core 엔진 무의존 — 단 종료 출력은 output-contract 공유) — 앱을 다 만든 뒤 **배포 직전** 관점에서 전체를 전문가 수준으로 최종 점검하고 배포 가능 여부(GO/조건부GO/NO-GO)를 판정한다 (§9). 코드가 "동작하는지"만이 아니라 유지보수·중복/복잡성·성능 병목·UX/UI·예외/오류/로딩·보안·반응형·확장 구조·치명 이슈·기술부채 10차원 + 전용 기술부채 인벤토리를 본다. 코드는 한 줄도 안 고치고 — 고정 포맷 리포트(`docs/reviews/…-preflight.md`)와 수정 라우팅 제안(발견→forge/renew/hunt/simplify)까지가 일이다. `code-review`(현재 diff 버그)·`security-review`(보안만)·`improve-codebase-architecture`(리팩터 기회 발굴)와 직교 — 이들 전문 리뷰어를 안에서 호출해 합성하고, 없는 차원(UX/반응형/유지보수/부채)을 더해 *배포 판정*을 낸다. `ship` 은 standalone (craft-core 엔진 무의존, output-contract 공유) — **이 레포 전용** 배포 스킬 (§10). 라이브 `~/.claude/skills/` 의 스킬 변경을 repo 미러→PR→CI 대기→승인 게이트→squash 머지→로컬정리로 한 흐름에 흘린다. `sync.sh --push`(PR 생성과 동시에 즉시 머지 — CI·게이트 없는 빠른 경로)와 달리 CI 를 기다리고 머지 전 한 번 멈춰 확인한다. 신규 `sync.sh --pr-only`(미러+커밋+push+PR 까지만, 머지 보류)를 호출 엔진으로 쓴다. 범용 다중 PR/워크트리 정리(land)와 달리 단일 sync PR 전용 — land 의 stack 처리는 차용하지 않는다(YAGNI). `fortify` 는 standalone (craft-core 엔진 무의존, output-contract 공유) — 웹서비스 **배포 직전 보안 한 축만** 5 카테고리(앱·코드/인증·권한/데이터·통신/인프라·네트워크/로깅·백업)로 감사해 배포 보안 판정(PASS/조건부PASS/FAIL)을 낸다 (§12). preflight 가 보안 포함 10차원 *종합* 판정인 반면 fortify 는 보안 한 축을 더 깊게(라이브 probe + 인프라 체크리스트) 본다. 코드 보안(OWASP/주입/XSS)은 `security-review` 를 호출해 합성하고(DRY), 나머지 운영 포스처는 직접 본다. 핵심은 **3-상태 판정**(PASS 증거확인 / FAIL 증거위반 / 확인필요 코드로안보임) — 코드로 안 보이는 인프라(방화벽·서브넷·WAF·백업복구)는 추측 PASS 하지 않고 사람에게 넘긴다. 라이브 probe 는 **읽기전용 비침투**만(curl 헤더·openssl TLS·npm/pip audit), 공격성 스캔(포트스캔·익스플로잇·DoS)은 거부. 코드는 한 줄도 안 고치고 — 고정 포맷 리포트(`docs/reviews/…-fortify.md`) + 수정 라우팅 제안(발견→hunt/renew/forge)까지가 일이다. `cicd-scaffold` 는 standalone (craft-core 무의존, skill-creator 산출 구조 — `assets/`(워크플로 5종+Dockerfile.template)·`references/`·`scripts/scaffold.py`) — Node 앱(Next/Express, 단일·monorepo)의 GitHub Actions 배포 파이프라인을 *생성*한다(디버그 아님). 타깃 형상: develop push→dev 자동, 버전 태그→prod, Docker 이미지 ECR push(주로 OIDC·정적키 0), self-hosted runner. build/test 명령·포트를 탐지해 AWS/GitHub 공백을 채운 뒤 워크플로·(없으면)Dockerfile·셋업 체크리스트를 쓴다. `~/.config/cicd-template/` 툴킷(글로벌 rule `cicd-pipeline`)의 스킬화 — 기존 파이프라인 디버그·standalone Dockerfile·Terraform/IAM 단독 프로비저닝은 범위 밖. `loop-harness-setup` 은 standalone (craft-core 무의존, `references/visualization.md`) — 레포에 개발 "하니스"(loop/eval-게이트 자율개발 오케스트레이터 인프라)를 **처음** 설치·이식·복제하고 그 위 `loop/` 가시화 HTML·일별 로그까지 셋업한다. 신호는 단 하나 — 타깃에 하니스가 *아직 없음*. 글로벌 rule `loop-visualization`(검증된 셋업 가이드 포인터)의 스킬화 — 이미 깔린 하니스로 이슈를 *실행*(harness-run)·빌드(forge)·플랜(deep-plan)하는 것과 다르다(인프라 자체를 새로 설치). `linear-register`/`linear-goal`/`linear-groom` 은 standalone (craft-core 무의존, Linear MCP 의존) — Linear 이슈 라이프사이클 3종(§11). `linear-register` 는 단건~소수 이슈를 등록하며 각 이슈에 적응형 `## 추천`(적합 글로벌 스킬/에이전트 우선 + 프로젝트 로컬 포인터 부차) + 의존 체인이면 Linear 네이티브 관계 세팅·전방 kickoff 포인터를 박는다(repo→팀 라우팅 = `linear-repo-map.json` 역매핑 + 생성 전 확인 게이트 + AI disclaimer). 대형 plan 분할은 `to-issues`, PRD 는 `to-prd` 로 위임(니치 경계). `linear-goal` 은 티켓 1건(특히 linear-register 산출 이슈)을 **경량** 흐름으로 자율 실행한다 — 메타프롬프트·시안·적대 critic 없이 이슈의 `## 작업 내용`/`## 수용 기준`(또는 groom 의 `## 작업 범위`/`## Acceptance`)을 Goal Prompt 로 매핑 → 경량 확인 게이트 → worktree 검증 → goal worker 백그라운드 잡 → In Review(머지는 land/사람). harness-class(estimate≥5·cross-cutting·전면개편)면 harness-run 추천하고 멈춘다(`## 추천` 이 빌드를 가리켜도 안전 게이트가 상위). `linear-groom` 은 기존 백로그를 그루밍한다 — 고아 이슈 프로젝트 그룹핑 + 빈약 이슈(empty/shallow) 보강(코드·메모리 근거로 `## 배경/현황/범위/Acceptance` + `## 추천`/체인, healthy 는 surgical 보존), 승인 표 게이트 후 일괄 write. 세 스킬의 `## 추천` 생성 규칙은 `linear-register/references/recommend-section.md` SSOT 공유(복제 금지). 모두 graceful — Linear MCP 미설치면 가이드 한 번+스킵. (강제 레이어 rule `linear-register-mandatory`·hook `guard-linear-register-nudge`·settings 는 `~/.claude` 글로벌 — 본 배포 레포 밖.)

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
loop/eval-게이트 자율개발 하니스의 실행 스킬 4종. **이 레포에 새로 추적되기 시작**했다 — 종전 SSOT 는 `~/Workspace/Intelligence-Auth/.claude/skills/`(하니스 origin)였고, 글로벌 사본(`~/.claude/skills/`)을 그 미러로 두는 구조였다. 사용자 결정으로 **글로벌을 단일 SSOT** 로 수렴 중이며, 그 1단계가 글로벌 사본에 git 집(본 레포 추적 + PR/CI/history)을 주는 것이다.
- **추적 내용 = 글로벌 변형 정본(절대경로).** harness-run·eval-generate·eval-check 의 `SKILL.md`·workflow scriptPath 는 cwd-무관 동작을 위해 `/Users/carpdm/.claude/skills/...` **구체 절대경로**를 쓴다(Workflow scriptPath 는 프로젝트 cwd 가 아니라 skills 디렉토리에 resolve 돼야 함 → 상대·`~` 불가). **2단계에서 이식성 해결:** `install.sh` 가 설치 시 `/Users/carpdm/.claude/skills` → `$HOME/.claude/skills` 로 home prefix 재작성(메인테이너 머신 = no-op, 타 머신 = 그 머신 경로). 단방향이라 `sync.sh`(글로벌→repo, carpdm 머신서만 실행)는 no-op 왕복 → repo 오염 없음. 따라서 본 레포의 "어느 머신이든 동작" 불변식 충족.
- **결합 세트.** harness-run 이 eval-generate(rubric 생성)·eval-check(채점)·harness-heal(단락 자가개선)을 호출하는 한 묶음 — 4종은 함께 추적/이동한다. 상세 하니스 구조(게이트 G0~G4·3역할 분리·decideNext·C4 heal)는 글로벌 rule `loop-visualization` + IA `loop/` 가 SSOT.
- **이관 단계:** ①(git 집 확보)·②(경로 전략 = install.sh 재작성) 완료. **남은 단계(미완):** ③ 글로벌 단독 동작 검증(IA 사본 임시 비활성 후 harness-run 1회 완주), ④ IA `.claude/skills/{harness-run,eval-generate,eval-check,harness-heal}` 삭제 + SSOT 포인터 룰(`loop-visualization.md`·harness-run 글로벌 변형 노트) 갱신.

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
