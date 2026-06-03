# carpdm-skills — Project Rules (SSOT)

> 이 파일이 프로젝트 지침 SSOT. AGENTS.md 는 빌드 산출물(글로벌 `~/.claude/rules/` + 본 파일 concat).
> `build-agents-md.sh` 미설치 동안 AGENTS.md 는 본 파일을 수동 미러링한다 — 본 파일만 편집하고 AGENTS.md 는 재생성.

## What this repo is

Claude Code 글로벌 스킬 **배포 레포**. 빌드/런타임 없음 — 스킬은 마크다운(`SKILL.md` + `references/*.md`)이고, `~/.claude/skills/` 로 복사돼야 동작한다. 코드 컴파일·테스트·린트 단계 없음.

스킬 10종: 작업유형 파이프라인 4 (`forge`/`hunt`/`renew`/`reshape`) + 심층인터뷰 1 (`deep-interview`) + 세션인계 1 (`handoff`) + 정리유틸 1 (`sweep`) + PR 랜딩 1 (`land`) + 에이전트저작 1 (`summon`) + 공유엔진 1 (`craft-core`). 공유엔진은 두 실행 모드를 가진다 — linear(기본) / orchestrated(멀티에이전트 council, §5). `deep-interview` 는 standalone (craft-core 무의존) — 모호한 아이디어를 소크라테스 인터뷰 + 수학적 ambiguity 게이트로 검증가능 spec 까지 끌어올린 뒤 빌드 파이프라인으로 핸드오프. 빌드는 안 함.

## Commands

| 명령 | 용도 |
|---|---|
| `bash install.sh` | repo `skills/` → `~/.claude/skills/` 복사. 멱등 — 기존 동명 스킬은 `.bak-<ts>` 백업 후 덮어씀. 설치 후 Claude Code 재시작 필요 |
| `bash sync.sh` | 반대 방향. live `~/.claude/skills/` → repo `skills/` 미러(rsync `--delete`). repo 가 **이미 추적 중인** 스킬만 갱신. staged 변경 표시 |
| `bash sync.sh --push` | 미러 + `chore/sync-<ts>` 브랜치·PR·머지 자동 (`gh` CLI 필요). master 직접 push 금지 환경 대응 |
| `ls ~/.claude/skills/` | 설치 검증 — `forge hunt renew reshape handoff sweep land summon craft-core` 보여야 함 |

검증 스위트는 없다. "테스트"는 `install.sh`/`sync.sh` 실행 + `ls` 확인이 전부.

## Architecture — 반드시 알 것

### 1. craft-core 절대경로 결합 (깨지기 쉬움)
파이프라인 4종은 craft-core 엔진을 **하드코딩 절대경로**로 읽는다:
`~/.claude/skills/craft-core/references/pipeline.md`. 따라서:
- 설치 경로는 `~/.claude/skills/` **고정**. 다른 위치면 4종 전부 깨짐.
- forge/hunt/renew/reshape 는 craft-core 와 **항상 함께** 설치돼야 함. handoff·sweep·land·summon 은 단독 가능 (craft-core 의존 없음).
- craft-core 는 `user-invocable: false` — 직접 트리거 금지, 컨테이너일 뿐.

### 2. 공유 4-phase 파이프라인 (craft-core/references/pipeline.md)
Socratic 인터뷰 → codex 적대적 플랜 리뷰(`codex:rescue` 플러그인) → 동적 워크플로 TDD(sonnet) → 보안 검증.
각 작업유형 스킬은 이 엔진 위에 **자기 Phase 1 Socratic 초점 + Phase 3 TDD 진입점**만 얹는다 (SKILL.md 본문은 짧음 — 차이만 기술). 공통 Phase 0/2/4/5 는 엔진 그대로.
- `codex:rescue` 미설치 시 Phase 2 는 수동 리뷰로 폴백.
- 참조 분리: `socratic.md`/`codex-review.md`/`dynamic-tdd.md`/`security.md`/`context-adr.md` — phase 필요 시 lazy load.

### 3. SKILL.md frontmatter = 트리거
`name` + `description` 만. `description` 이 자연어 트리거 매칭을 좌우 — 파이프라인 4종은 **언더트리거 설계**(과발화 방지, 슬래시 명시 권장), handoff 는 **양방향 자동 감지**(작업종료=저장 / 세션시작=복원).

### 4. sync = true mirror
`sync.sh` 의 SSOT 는 repo `skills/` 의 디렉토리 목록. 새 스킬 배포 시작은 `skills/<name>/` 를 **먼저 만든 뒤** sync. live 에서 지운 파일도 `--delete` 로 repo 에 반영됨.

### 5. craft-core 실행 모드 — linear / orchestrated
craft 엔진은 **두 토폴로지**를 가진다. **linear**(기본, `pipeline.md`) = 단일세션이 전 페이즈 수행. **orchestrated**(`references/orchestrated.md`) = 멀티에이전트 — Phase 1+2 팀모드 council(designer+adversary 영속 opus, 수렴 루프), Phase 3 Workflow TDD(**sonnet** — dynamic-tdd 의 opus pin 의도적 override), Phase 4 Workflow 검증 fan-out(QA/tester/security opus) + 살아있는 designer 의 intent 판정, Phase 5 팀 shutdown.

핵심: orchestrated 는 **별도 스킬이 아니라 강도(intensity) 선택**으로, 작업타입과 직교한다. forge/renew/hunt/reshape 어느 것이든 유저가 명시적으로 council/팀+워크플로/maximum rigor 요청 시 엔진이 orchestrated 로 에스컬레이트(`pipeline.md` → Execution mode). 호출 스킬의 Phase 1 focus + Phase 3 TDD 진입점을 그대로 쓴다. **트리거는 task-type 스킬이 이미 이긴 뒤 엔진 내부 분기**라 형제 스킬 트리거 경쟁이 없다(과거 별도 `convene` 스킬이 가졌던 문제를 모드화로 제거). 무겁고 비싼 경로 — 설계 리스크 클 때만. `shutdown_request` 로 팀 정리 필수.

## Editing workflow
정식 개발 루프: live `~/.claude/skills/<name>/` 편집 → `bash sync.sh` 로 repo 반영 → 리뷰 → `--push`. repo 에서 직접 편집했다면 `install.sh` 로 live 반영. 두 방향 혼용 시 마지막 동기화 방향 주의 (`--delete` 미러라 한쪽이 SSOT).

## Work-end check (Stop hook)
작업 종료 시 글로벌 스킬이 repo 에 미반영이거나 push 안 됐으면 `.claude/hooks/check-skill-sync.sh` (Stop hook, `.claude/settings.json` 등록)가 **비차단 경고**. 감지 3종: (a) live↔repo drift → `bash sync.sh`, (b) repo 미커밋, (c) 미push 커밋 → `bash sync.sh --push`. 감지·알림만 — auto-push 안 함(외부발신·비가역). 경고 뜨면 직접 sync/push 로 마무리.

## PR-time README check (PreToolUse hook)
`gh pr create` 직전 `.claude/hooks/guard-readme-fresh.sh` (PreToolUse:Bash hook)가 README.md 가 모든 `skills/<name>` 디렉토리를 링크하는지 확인 — 누락 시 **차단(exit 2)** 하고 누락 스킬을 출력한다. 스킬을 추가/삭제하면 같은 PR 에서 README 스킬 표·카운트를 갱신할 것. Stop hook(비차단)과 달리 이건 **차단형** — README drift 가 PR 에 실리는 것을 막는다. Override: `README_FRESH_DISABLE=1`. 체크는 `skills/<name>` 링크 존재만 보며, 표 내용 정확성까지는 검증하지 않으니 행 내용은 수동 관리.
