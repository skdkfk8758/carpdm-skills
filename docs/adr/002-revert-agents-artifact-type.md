# ADR 002 — agents 배포 아티팩트 철회 (스킬 단일 아티팩트로 원복)

- Status: Accepted
- Date: 2026-06-07
- Supersedes: ADR 001
- Context source: renew (linear) — 사용자 요청 "agents 폴더 제거 + 관련 부분 정리"

## Context

ADR 001 이 `agents/` 를 `skills/` 와 나란한 두 번째 배포 아티팩트로 도입했다(큐레이트
6종 + install/sync/Stop hook 확장 + `summon` 스킬과의 컨벤션 호환). ADR 001 의
Consequences 는 이 결정을 **명시적으로 가역적**이라고 기록했다 — "agents/ 삭제 +
두 스크립트·훅의 agents 블록 revert 로 원복 가능".

사용자가 그 revert 를 요청했다. 이중 아티팩트(스킬+에이전트)가 만든 표면적이 이
레포의 실제 용도(스킬 배포) 대비 과하다는 판단이다 — install/sync/훅의 분기 블록,
README 의 비대칭 가드(스킬만 강제), craft-core 의 풀 결합이 유지 비용을 더했다.

## Decision

**ADR 001 을 되돌린다.** `agents/` 를 1급 배포 아티팩트에서 제거하고, 레포를
**스킬 단일 아티팩트**로 원복한다.

- `agents/` 6 파일 삭제. 큐레이트 풀(`executor`/`code-reviewer`/`security-reviewer`/
  `test-engineer`/`debugger`/`explore`)은 더는 이 레포가 배포·관리하지 않는다.
- `summon` 스킬(신규 에이전트 저작) 삭제 — 배포 agents/ 와 짝을 이루던 저작 도구이므로
  같은 변경에서 제거(YAGNI: 짝이 사라지면 함께). 스킬 12 → 11.
- `install.sh`/`sync.sh`/`check-skill-sync.sh` 의 agents 처리 블록 제거 — 단일 아티팩트
  로직으로 환원.
- craft-core 의 `agentType` 라우팅 제거. ADR 001 시점에도 "풀 미설치 시 agentType
  떨구고 기본 subagent" 폴백이 내장돼 있었으므로, 이 제거는 **동작 변화가 아니라**
  폴백 경로를 유일 경로로 고정하는 것이다. Workflow `agent()` 호출·프롬프트·model pin 은 유지.

## Why remove summon too

`summon` 은 ADR 001 이 도입한 agents 컨벤션의 산출물 경로(`~/.claude/agents/`,
`.claude/agents/`)에 맞춰 에이전트를 저작하는 스킬이다. 배포 agents/ 와 직접 결합은
아니지만(Claude Code 일반 subagent 메커니즘 사용), 이 레포가 에이전트 아티팩트를
다루지 않기로 한 이상 에이전트 저작 스킬을 배포할 동기도 사라진다. 사용자가 명시적으로
함께 제거를 택했다.

## Consequences

- install/sync/훅이 스킬 단일 아티팩트 로직으로 단순화 — agents 분기 블록 소멸.
- ADR 001 의 "Known asymmetry"(README 가드가 스킬만 강제)가 **자연 해소** — 이제
  강제 대상이 스킬뿐이라 비대칭이 존재하지 않는다.
- craft-core 워크플로는 기본 subagent 로 동작(폴백 경로). 풀이 주던 battle-tested
  프롬프트·RO-lock 이점은 사라지나, ADR 001 의 폴백 설계상 기능 손실은 없다.
- **이미 설치된** live `~/.claude/agents/` 의 6 에이전트는 이 변경이 건드리지 않는다
  (install 은 복사만 — 삭제 안 함). 원하면 사용자가 수동 정리.
- 시점 기록(`docs/plans/2026-06-03-import-omcc-agents.*`,
  `docs/specs/import-oh-my-claudecode-agents.md`)은 역사로 보존 — 당시 결정의 근거 추적용.

## References

- Superseded ADR: `docs/adr/001-agents-as-second-artifact-type.md`
- Plan: `docs/plans/2026-06-07-remove-agents-artifact.md`
