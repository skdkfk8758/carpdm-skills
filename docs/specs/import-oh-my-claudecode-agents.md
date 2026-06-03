# SPEC — oh-my-claudecode agents 큐레이트 import

> Origin: deep-interview 세션 (2026-06-03). 최종 ambiguity ≈ 0.15 (deep 목표 0.10, 조기진행).
> Status: requirements pinned — 빌드 파이프라인 Phase-1 산출물로 소비.

## Goal & Scope

[Yeachan-Heo/oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode/tree/main/agents) 의 19개 agent 중 carpdm-skills 워크플로 역할군에 매핑되는 **10개**를 큐레이트해, 이 레포의 **배포 아티팩트**로 추가하고 동시에 `~/.claude/agents/` 로 개인 설치한다.

- **IN**: agent 선택(10개) / 최소 변형 / install·sync·문서 배선.
- **OUT (deferred)**: 기존 스킬(forge/hunt 등)을 named agent 참조로 재배선 (Q1 에서 (c) 제외). 비코드 agent(writer/designer/document-specialist/analyst/scientist/git-master/verifier/tracer/code-simplifier) import. `summon` 스킬 연동 (별개 스킬, agents/ 컨벤션만 호환 유지).

## Locked topology

| # | 컴포넌트 | 상태 |
|---|---|---|
| C1 | Selection — 10개 큐레이트 | active |
| C2 | Adaptation — 최소 변형 | active |
| C3 | Deploy plumbing — install/sync/문서 | active |
| C4 | 기존 스킬 재배선 | deferred |

## Selection (C1) — import 대상 6개 (10→7→6)

당초 10개 → Phase 2 적대 리뷰가 planner/critic/architect 의 oh-my-claudecode 결합 집중(consensus 24참조·`.omc/`·start-work·analyst 데이터계약) + craft-core 기능 중복을 밝혀 **7개로 축소**(ADR 001) → 이후 `qa-tester` 가 tmux 전용·좁은 니치로 판명돼 **6개로 추가 드롭**. 남은 6개 = orchestrated 모드가 실제 spawn 하는 코드 워크플로 역할군:

| 역할 | 외부 agent | model |
|---|---|---|
| executor | `executor` | sonnet |
| reviewer | `code-reviewer` | opus |
| security | `security-reviewer` | opus |
| tester | `test-engineer` | sonnet |
| debugger | `debugger` | sonnet |
| explore | `explore` | haiku |

제외: `planner`/`critic`/`architect` (결합 집중·중복), `qa-tester` (tmux 전용·좁은 니치).

## Brownfield context

- 레포는 skills 배포 전용 — `agents/` 디렉토리·`~/.claude/agents/` **부재**. agents 는 신규 아티팩트 타입.
- 외부 agent frontmatter: `name`/`description`/`model`(opus·sonnet)/`level`(1-3, **비정식**)/`disallowedTools`(정식). 본문 ~180줄, role+protocol+output+failure modes.
- agent 끼리 **이름으로 핸드오프 참조** → 연결 시스템. 부분집합 import 시 dangling 참조 발생.
- Claude Code 정식 frontmatter (공식문서 검증): `name`/`description`/`tools`(allowlist)/`disallowedTools`(denylist)/`model`/`permissionMode`/`hooks`/`maxTurns`/`skills`/`effort`/`isolation`/`color` 등. `level` 없음.

## Requirements

### Functional

| ID | 요구 | Priority | Acceptance | Origin |
|---|---|---|---|---|
| REQ-F-001 | 10개 agent 를 repo `agents/<name>.md` 로 추가 | MUST | `ls agents/` → 10 파일 | R1 |
| REQ-F-002 | 각 frontmatter 에서 `level:` 줄 삭제, 나머지(`disallowedTools`/`model`) 유지 | MUST | `grep -l "^level:" agents/` → 0 | R2 |
| REQ-F-003 | 본문 핸드오프 참조 중 **import 안 된 agent 이름** 제거; 집합 내 참조는 유지 | MUST | 본문에 비-import agent 이름 grep → 0 | R2/Q4 |
| REQ-F-004 | `install.sh` 가 `agents/` → `~/.claude/agents/` 복사 (skills 와 동일 멱등·백업 로직) | MUST | `bash install.sh` 후 `ls ~/.claude/agents/` → 10 | R2 |
| REQ-F-005 | `sync.sh` 가 live `~/.claude/agents/` → repo `agents/` 미러 (추적 중인 것만, `--delete`) | MUST | sync 왕복 무손실 | R2 |
| REQ-F-006 | README + rules/project.md 에 agents 표·카운트 추가 | MUST | 10개 모두 링크 | R2 |

### Non-functional

| ID | 요구 | Priority | Acceptance | Origin |
|---|---|---|---|---|
| REQ-N-001 | install.sh 멱등 — 재실행 시 기존 agent `.bak-<ts>` 백업 후 덮어씀 | MUST | 2회 실행 안전 | R2 |
| REQ-N-002 | agent 본문 영어 유지 (레포 문서 규약). 런타임 한국어는 글로벌 룰 처리 | SHOULD | — | R2 |
| REQ-N-003 | `agents/` 컨벤션을 `summon` 산출물과 호환 (동일 경로·포맷) | SHOULD | summon 이 같은 dir 에 쓸 수 있음 | R2 |

## Assumptions resolved

- 주 용도 = 코드/개발 워크플로 → 비코드 agent 제외 (Q3 추천 수용).
- prune = 집합 밖 참조 삭제, 집합 안 유지 (Q4, 조기진행).

## Residual ambiguity (조기진행 — 빌드 중 해소)

- 5개 agent(tester/qa/security/critic/planner/explore/debugger)의 정확한 model pin — import 시 원본 확인.
- 에이전트별 핸드오프 참조 실제 분포 — 다운로드 후 grep 로 식별.
- README 표 행 문구 — 수동 작성.

## Clarity trail

| Round | ambiguity | 해소 |
|---|---|---|
| 0 | 0.49 | 토폴로지 3-active 잠금 |
| 1 | 0.42 | C1 = Option B (큐레이트 10) |
| 2 | 0.24 | frontmatter 검증, C2 최소변형, criteria |
| exit | 0.15 | "진행" 조기종료, prune 방식 확정 |
