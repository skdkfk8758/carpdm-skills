# Knowledge Folders — Standard Layout

IMPORTANT: 모든 프로젝트는 다음 폴더 컨벤션을 따른다. AI 에이전트(Claude / Codex / Cursor / Aider / Copilot)가 읽을 위치를 단일화한다.

## Standard Layout (per-project)

| 경로 | 역할 | SSOT? | 에이전트 읽기 |
|---|---|---|---|
| `AGENTS.md` | 빌드된 에이전트 지침 (concat of `~/.claude/rules/` + `rules/`). vendor-neutral. | NO (산출물) | 모든 에이전트 primary |
| `CLAUDE.md` | 1줄 shim. `@AGENTS.md` 만 포함. Claude Code 호환. | NO (shim) | Claude Code only |
| `rules/` | 프로젝트별 룰 SSOT. 글로벌 룰 override + 도메인 특화 룰. | **YES** | 빌드 시 AGENTS.md 에 concat |
| `docs/` | 모든 문서 단일 트리 — knowledge sub-tree (`adr/concepts/guides/reference`) + artifact sub-tree (`specs/plans/runbooks/reports/...`). | **YES** | on-demand (AGENTS.md 가 경로만 참조) |
| `memory/` (글로벌 `~/.claude/projects/<slug>/memory/`) | 세션 간 메모리. | YES | auto-load |
| `logs/qa/` | QA 실패 증거 (`QA-evidence-log` 룰). 7일 GC. gitignore. | NO (휘발) | debugger/executor spawn 시 |

## docs/ Sub-tree Convention

`docs/` 가 모든 문서 SSOT. 종류별 sub-tree:

| Sub-tree | 용도 | 예 |
|---|---|---|
| `docs/adr/` | Architecture Decision Records (영속 결정) | `NNN-<slug>.md` |
| `docs/concepts/` | 도메인 개념·용어집 (영속 지식) | `data-layers.md` |
| `docs/guides/` | 실행 가이드·튜토리얼 (영속 절차) | `quickstart.md` |
| `docs/reference/` | API/외부 자료 reference (영속 참조) | `api-endpoints.md` |
| `docs/_index/index.md` | knowledge portal — 전체 navigator (1 prj 1 진입점) | — |
| `docs/specs/` | 외부 계약 SPEC (시점 기록, 상태 전이) | `SPEC-NAME/{spec,plan,acceptance,research}.md` |
| `docs/plans/` | 작업 단위 plan (시점 기록) | `YYYY-MM-DD-<topic>.md` |
| `docs/project/` | 프로젝트 개괄 (tech/product/structure) | — |
| `docs/{runbooks,reports,reviews,handoff,benchmarks,solutions,_archive}/` | 운영 산출물 | — |

**knowledge sub-tree** = 2+ 페이지에서 재참조될 영속 지식 (`adr/concepts/guides/reference`).
**artifact sub-tree** = 시점 기록·단발성 산출물 (`specs/plans/runbooks/reports/...`).

## Rules

### R1: SSOT 단일성

- 동일 정보가 두 곳에 있으면 그중 하나는 산출물이거나 shim 이다. 손편집 금지.
- `AGENTS.md` 손편집 금지 — `rules/` 편집 후 빌드.
- `CLAUDE.md` 손편집 금지 — `@AGENTS.md` 한 줄 유지.

### R2: 에이전트 진입점 = AGENTS.md

- `AGENTS.md` 가 모든 에이전트의 primary entry. Claude 는 `CLAUDE.md → @AGENTS.md` 경로로 도달.
- `AGENTS.md` 본문에 `docs/` 경로를 명시해 on-demand Read 유도. 본문에 inline 하지 않음 (사이즈 폭증 방지).

### R3: 프로젝트 rules/ 는 글로벌 override 도구

- 프로젝트 `rules/*.md` 는 글로벌 `~/.claude/rules/` 뒤에 concat 됨 → 마지막 우선.
- karpathy 4원칙 override 시 `~/.claude/rules/karpathy-core.md` 의 "Karpathy Override" 프로토콜 따름 (사유 명시 의무).

### R4: 빌드 강제

- `~/.claude/scripts/build-agents-md.sh` 가 `AGENTS.md` 생성.
- `make verify` 또는 pre-commit 에서 `build-agents-md.sh --check` 호출 → drift 검증. drift 발견 시 차단.

> NOTE: 빌드 스크립트는 **선택(현재 미설치)**. `~/.claude/scripts/build-agents-md.sh` 가 없으면 `AGENTS.md` 는 `rules/` 를 보고 **수동 미러링**한다 — `rules/` 만 SSOT 로 편집하고 `AGENTS.md` 에 손으로 반영. 스크립트 설치 시 위 자동화로 전환.

### R5: 폴더 부재 허용 정책

| 폴더 | 부재 OK? |
|---|---|
| `AGENTS.md` | **NO** — 에이전트 작업 가능 프로젝트 필수 |
| `CLAUDE.md` | NO — Claude Code 호환 위한 1줄 shim 필수 |
| `rules/` | YES — 글로벌 룰만 충분하면 생략 |
| `docs/` | YES — 작은 프로젝트. 단 knowledge 가 2+ 페이지 누적되면 도입 권고 |

### R6: portal 단일 진입

- 프로젝트가 `docs/` 를 사용한다면 `docs/_index/index.md` 가 단일 진입점 (knowledge portal).
- 신규 문서 작성 시 portal 의 라우팅 표 (knowledge vs artifact) 따름.

## Bootstrap

> 아래는 `build-agents-md.sh` **설치 시** 자동 경로. 미설치(현재 기본)면 수동: `CLAUDE.md` 에 `@AGENTS.md` 한 줄 shim 작성 + `AGENTS.md` 에 `~/.claude/rules/` 와 프로젝트 `rules/` 내용을 손으로 미러링.

신규 프로젝트:
```bash
~/.claude/scripts/build-agents-md.sh --bootstrap
```
→ `CLAUDE.md` shim + 빈 `rules/` + 초기 `AGENTS.md` 생성. `docs/{adr,concepts,guides,reference}` 는 누적 시점에 생성.

기존 프로젝트:
```bash
cd <project> && ~/.claude/scripts/build-agents-md.sh
```
→ 기존 `CLAUDE.md` 백업 후 shim 으로 전환, `AGENTS.md` 빌드.

## Anti-patterns

- `CLAUDE.md` 에 룰 본문 직접 작성 — SSOT 깨짐, Codex/Cursor 못 읽음
- `AGENTS.md` 손편집 — 빌드 시 손실
- `docs/` 내용을 `AGENTS.md` 본문에 inline — 사이즈 폭증, 모든 에이전트 매 턴 로드
- knowledge sub-tree (`adr/concepts/...`) 와 artifact sub-tree (`specs/plans/...`) 혼재 — sub-tree 경계 흐려져 grep 노이즈 폭증

## Related

- `~/.claude/rules/_ORDER.txt` — concat 순서 정의 (미설치 — 없으면 파일명 알파벳/harness 기본 순)
- `~/.claude/scripts/build-agents-md.sh` — 빌드 스크립트 (미설치 — R4/Bootstrap 노트 참조, 수동 미러링)
- `~/.claude/rules/karpathy-core.md` — override 프로토콜
