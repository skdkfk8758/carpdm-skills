# carpdm-skills — Project Rules

> 이 파일이 이 저장소의 **유일한 지침 진입점이자 본문**이다. Claude Code 가 native 로 읽는다.
> 벤더별 진입점(`AGENTS.md` 등)도, 중간 파일도 두지 않는다 — 두 벌을 유지하면 갈라진다.
> 개인 하네스의 글로벌 룰은 `~/.claude/CLAUDE.md` 로 별도 auto-load 된다.
> **이 저장소 trunk = `master`** (PR base·머지 대상). 글로벌 `CLAUDE.md` §브랜치의 `develop` 은 여기 적용되지 않는다.

## What this repo is

Claude Code 글로벌 스킬 **배포 레포**. 빌드/런타임 없음 — 스킬은 마크다운(`SKILL.md` + `references/*.md`)이고 `~/.claude/skills/` 로 복사돼야 동작한다. 코드 컴파일·테스트·린트 단계 없음.

스킬 인벤토리·개별 역할의 SSOT 는 각 `skills/<name>/SKILL.md` frontmatter `description:` — 여기 복제하지 않는다(drift 차단). 아키텍처 결합·설계 결정은 `docs/architecture/decisions.md` §1~§16. 현재 스킬 dir 목록은 `ls skills/`. 그룹 개요:
- 빌드 파이프라인: `forge`(신규)/`hunt`(버그)/`renew`(개편) + 공유엔진 `craft-core`(§1·§5) + 경량 escape-hatch `tdd`(적대 리뷰·보안 페이즈 없는 red-green-refactor 단독 — 풀 파이프라인 아님)
- plan·인터뷰(산출만, 빌드 안 함): `deep-interview`(standalone) · `deep-plan`(§6 — 자율 잡용 Goal Prompt `-prompt.md` 도 여기서 산출; 종전 `deep-prompt` 는 #167 에서 은퇴·흡수)
- 운영: `handoff` · `sweep` · `land` · `wt-sweep`(워크트리·세션기록 정리는 wt-sweep 단독 소관 — land 는 워크트리를 건드리지 않고 Report 로 안내만; 절차 SSOT 는 wt-sweep `references/sweep-mode.md`) · `ship`(§10) · `launch`(§16 — GitLab 서비스 운영 릴리즈: 태그 승인 1회 → 파이프라인 → prod promote MR 자동 머지 → 검증)
- 검토·판정(코드 한 줄 안 고침, 리포트+수정 라우팅만): `preflight`(§9) · `fortify`(§12)
- UI·도식: `imprint`(수동 추출 DESIGN.md *준수* 재현 — 발명 아님, token-traceability: raw hex/px 하드코딩 0) · `mockup`(기존 프로젝트 충실 HTML 시안; `references/design-context.md` 가 시안 충실도 SSOT — deep-plan·craft pipeline 이 이 한 소스를 읽는다, 복제 금지) · `erd`(§8)
- 스캐폴딩·셋업: `cicd-scaffold` · `admap-scaffold` · `colocate-domain-context`
- Linear 라이프사이클: `linear-register`/`linear-groom`/`linear-prioritize`/`linear-replan` — 이슈 **본문 계약**은 `linear-register/references/human-issue-writing.md` SSOT 공유(groom 보강도 이걸 읽는다, 복제 금지) + `scripts/validate_issue_body.py` 가 강제; 모두 graceful — Linear MCP 미설치면 가이드 한 번+스킵. `linear-groom` 은 무인 주기 실행(orca automation)용 **scan-only** 모드 보유(§14)

> 과거 `agents/`(재사용 서브에이전트, 플랫 `.md`)를 두 번째 배포 아티팩트로 두고 `summon`(에이전트 저작) 스킬을 함께 배포했으나, [ADR 002](../docs/adr/002-revert-agents-artifact-type.md) 로 철회했다 — 이 레포는 다시 **스킬 단일 아티팩트**다.

## 작성 언어 · 저작 표준 → `CODING_STANDARDS.md`

스킬(`SKILL.md`·`references/*.md`)을 **쓰거나 고치기 전에**, 그리고 **리뷰할 때** 읽는다.
한국어 본문 정책과 번역 금지 항목(§1), 저작 시 하지 말 것 5가지(§2), 리뷰 체크리스트(§3).

## Commands

| 명령 | 용도 |
|---|---|
| `bash install.sh` | repo `skills/` → `~/.claude/skills/` 복사. 멱등 — 기존 동명은 in-place 덮어씀(백업 안 남김 — git history 가 안전망). 설치 후 Claude Code 재시작 필요 |
| `bash sync.sh` | 반대 방향. live `~/.claude/skills/` → repo `skills/` 미러(rsync `--delete`, repo 가 **이미 추적 중인** 것만) + **`sync-global.sh` 내장 실행**(글로벌 덤프 — `global/` 도 함께 미러·stage, 2026-08-02 통합). staged 변경 표시 |
| `bash sync.sh --push` | 미러 + `chore/sync-<ts>` 브랜치·PR·**즉시 머지** 자동 (`gh` CLI 필요). master 직접 push 금지 환경 대응. CI·승인 게이트 없는 빠른 경로 |
| `bash sync.sh --pr-only` | 미러 + 브랜치·커밋·push·PR **생성까지만** (머지 보류). 브랜치를 로컬에 남겨 CI 게이트+land 를 `ship` 스킬이 처리 (§10) |
| `bash sync.sh --dry-run` | 미러하면 바뀔 파일(추가·수정·삭제)만 rsync itemize 로 나열 — repo 파일·index·`global/` 무변경, `sync-global.sh` 미호출·PR 없음. 회귀 테스트 `scripts/ci/test-sync-dry-run.sh`(hermetic `HOME`) |
| `bash install-global.sh` | repo `global/` → `~/.claude/` 글로벌 셋업(CLAUDE.md·rules·rules-ondemand·guards·settings) 설치. 변경분 백업 후 덮어씀, settings `<FILL-ME>` 는 로컬 실값 보존 머지. 상세 `global/README.md` |
| `bash sync-global.sh` | 반대 방향. live `~/.claude/` → repo `global/` 전수 미러 + settings secret 마스킹 + 커밋 전 secret 스캔 게이트(발견 시 exit 1). 글로벌 룰 수정 후 실행해 stale 미러 방지 |
| `ls ~/.claude/skills/` | 스킬 설치 검증 — `forge hunt renew handoff sweep land ship craft-core` 보여야 함 |

검증 스위트: `scripts/ci/` 3종 — `validate-skills.js`(frontmatter: name↔dir 일치·ASCII kebab-case·description 존재), `check-invisible-chars.js`(ASCII-smuggling 위험 invisible 문자 0 유지 — emoji·U+FE0F 변이선택자는 의도적 허용), `catalog.js`(README↔skills/ 링크·stale 참조·"N개 스킬" 카운트 대조). 전부 의존성 0(node 단독), CI(`.github/workflows/ci.yml` validate 잡)와 `guard-readme-fresh` 훅이 같은 스크립트를 실행한다. 그 외 "테스트"는 `install.sh`/`sync.sh` 실행 + `ls` 확인.

## Architecture — 결정은 `docs/architecture/decisions.md` (§1~§16)

**아래 상황에 진입하면 해당 절을 Read 하고 진행.** 절 번호는 고정이라 `§N` 으로 인용해도 안전하다.

| 무엇을 건드리나 | 절 |
|---|---|
| craft 엔진·pipeline·설치 경로 결합 | §1 craft-core 절대경로 · §2 4-phase 파이프라인 · §5 실행 모드(linear/orchestrated) |
| plan·인터뷰 산출물 | §6 deep-plan · §8 erd companion |
| 스킬 트리거·배포 미러 | §3 frontmatter=트리거 · §4 sync=true mirror |
| 종료 출력 규격 | §7 output-contract 3레이어 |
| Linear 연동 | §11 라이프사이클 wiring · §14 linear-groom scan-only |
| 검토·판정 스킬 | §9 preflight · §12 fortify |
| 배포·릴리즈 | §10 ship · §16 launch |
| worktree 격리 판정 | §15 게이트(생성 아님) |
| 은퇴한 것을 되살리려 할 때 | §13 하니스 5종 은퇴 |

## Editing workflow
정식 개발 루프: live `~/.claude/skills/<name>/` 편집 → `bash sync.sh` 로 repo 반영 → 리뷰 → `--push`. repo 에서 직접 편집했다면 `install.sh` 로 live 반영. 두 방향 혼용 시 마지막 동기화 방향 주의 (`--delete` 미러라 한쪽이 SSOT).

## Work-end check (Stop hook)
작업 종료 시 글로벌 스킬이 repo 에 미반영이거나 push 안 됐으면 `.claude/hooks/check-skill-sync.sh` (Stop hook, `.claude/settings.json` 등록)가 **비차단 경고**. 감지: (a) live↔repo drift (skills 디렉토리별) → `bash sync.sh`, (b) `skills/` 미커밋, (c) 미push 커밋 → `bash sync.sh --push`. 감지·알림만 — auto-push 안 함(외부발신·비가역). 경고 뜨면 직접 sync/push 로 마무리.

## Push/PR-time 로컬 CI 게이트 (PreToolUse hook)
`git push`·`gh pr create` 직전 `.claude/hooks/guard-readme-fresh.sh` (PreToolUse:Bash hook)가 **CI validate 3종 전부**(`validate-skills.js`+`check-invisible-chars.js`+`catalog.js` — 서버 CI 와 동일 스크립트)를 로컬 실행 — 실패하면 **차단(exit 2)**. `sync.sh --push/--pr-only` 도 PR 전에 같은 3종을 자체 실행(훅은 Bash 명령 문자열 매칭이라 스크립트 내부 push 를 못 보는 갭 보완). invisible-chars 스캔은 untracked 파일 포함(`git ls-files --others`) — 커밋 전 로컬 green 이 CI green 을 보장한다. 훅은 node 부재 시에만 링크-존재 grep 폴백. Override: `README_FRESH_DISABLE=1`. 근거: 카운트 drift 실사고 2회(#109·#137) + PR #159(untracked 신규 파일의 invisible char 가 로컬 green·CI red — push 후에야 발견, 왕복 비용).
