# ADR 001 — agents as a second deployed artifact type

- Status: Accepted
- Date: 2026-06-03
- Context source: deep-interview → forge (linear), Phase 2 adversarial review

## Context

이 레포는 출범 이래 **스킬**(`skills/<name>/`, 디렉토리당 1스킬)만 배포해 왔다. `install.sh`/`sync.sh`/Stop hook/PR-time README hook 모두 `skills/` 단일 아티팩트를 전제로 작성됐다.

[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) 의 재사용 서브에이전트를 가져오려는 요구가 생겼다. Claude Code 서브에이전트는 스킬과 **다른 아티팩트** — 플랫 `.md` 파일이고 `~/.claude/agents/` 에 설치된다. 두 선택지가 있었다:

1. 에이전트를 개인 `~/.claude/agents/` 에 수동 복사만 (레포 비추적).
2. 에이전트를 레포의 **두 번째 배포 아티팩트**로 승격 — install/sync/문서/훅이 함께 관리.

## Decision

**(2) 를 택한다.** `agents/` 를 `skills/` 와 나란한 1급 배포 아티팩트로 추가한다.

- import 대상은 **큐레이트 6종** (전체 19 아님): `executor`, `code-reviewer`, `security-reviewer`, `test-engineer`, `debugger`, `explore`. 선정 기준 = craft-core orchestrated 모드가 실제 spawn 하는 코드 워크플로 역할군.
- 당초 7종에 `qa-tester` 포함이었으나 **드롭**: 설계 전체가 tmux 전용(프리req 미충족 시 fail fast)이고 인터랙티브 CLI/서버 테스트라는 좁은 니치라, 이 사용자 워크플로에 맞지 않음. orchestrated 검증 패널의 acceptance-QA 레인은 풀 에이전트 없이 기본 subagent 로 동작하도록 변경.
- `planner`/`critic`/`architect` 는 **제외**. 이유: (a) craft-core 파이프라인이 이미 계획·적대적리뷰·설계자문을 제공해 기능 중복, (b) oh-my-claudecode 결합(consensus/ralplan 모드 24참조, `.omc/` 경로, `/oh-my-claudecode:start-work` 명령, analyst 데이터흐름 계약)이 이 셋에 집중돼 이식 비용·동작변경 리스크가 큼.
- 적응(adaptation): 비정식 `level:` 제거, `oh-my-claudecode:` 네임스페이스 Task 호출 일반화, `.omc/` 경로 제거, 미import 에이전트 핸드오프(analyst/document-specialist/verifier/explore-high) 일반화. `disallowedTools`/`model` 등 정식 frontmatter 는 유지.
- `agents/` 컨벤션은 `summon` 스킬(신규 에이전트 저작)의 산출물 경로와 호환되게 둔다.

## Why not all 19 (preserve handoff graph)

전체 import 는 에이전트 간 핸드오프 그래프를 무손상 보존하고 prune 작업을 없앤다는 장점이 있다. 그러나 (a) 비코드 에이전트(writer/designer/document-specialist 등)는 이 레포의 코드 중심 용도와 무관, (b) 전체를 가져와도 `oh-my-claudecode:` 네임스페이스·`.omc/`·command 결합은 여전히 적응이 필요해 "prune 0" 이 아니다. 따라서 큐레이트가 더 적은 총비용으로 "현재 프로젝트에 맞게"라는 목표에 부합.

## Consequences

- install/sync 는 **별개 플랫-파일 블록**을 갖는다 (스킬 디렉토리 루프 복제 아님).
- Stop hook(`check-skill-sync.sh`)은 agents drift·미커밋도 감지하도록 확장됨.
- **Known asymmetry:** PR-time 차단형 README hook(`guard-readme-fresh.sh`)은 **스킬만** 강제한다. agents README 신선도는 가드하지 않으므로 수동 관리 — 추후 필요 시 hook 확장이 후속 과제.
- 가역적: `agents/` 삭제 + 두 스크립트·훅의 agents 블록 revert 로 원복 가능.

## References

- Spec: `docs/specs/import-oh-my-claudecode-agents.md`
- Plan: `docs/plans/2026-06-03-import-omcc-agents.md`
