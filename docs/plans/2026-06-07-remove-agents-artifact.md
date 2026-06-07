# agents 배포 아티팩트 제거 (스킬 단일 아티팩트로 원복)

ADR 001(agents 를 두 번째 배포 아티팩트로 도입)을 되돌린다. `agents/` 디렉토리와
레포 전반의 agents 결합 지점을 제거하고, `summon` 스킬(에이전트 저작)도 함께 제거한다.
ADR 001 의 "Consequences > 가역적" 항이 명시한 revert 경로를 그대로 실행한다.

## Goal (testable success criteria)

- `agents/` 디렉토리와 `skills/summon/` 디렉토리가 레포에서 사라진다.
- `bash install.sh` 가 에이전트 설치 단계 없이 11개 스킬만 설치하고 성공 종료한다.
- `bash -n` 이 install.sh / sync.sh / check-skill-sync.sh 셋 다 통과한다.
- craft-core references 전체에 `agentType` 문자열이 0건이다 (워크플로는 기본 subagent 로 동작).
- README·rules/project.md 가 "11 스킬, 에이전트 아티팩트 없음" 으로 정합하고
  guard-readme-fresh 가 통과한다 (모든 `skills/<name>` 링크 존재).

## Scope (IN / OUT)

**IN**
- 삭제: `agents/` (6 파일), `skills/summon/` (디렉토리)
- 편집: `install.sh`, `sync.sh`, `.claude/hooks/check-skill-sync.sh`,
  `rules/project.md`, `README.md`,
  `skills/craft-core/references/{pipeline,dynamic-tdd,orchestrated}.md`
- ADR: `docs/adr/001` 을 Superseded 표시, `docs/adr/002` 신규(되돌림 결정 기록)

**OUT (보존 — 손대지 않음)**
- `AGENTS.md` 파일 — `@rules/project.md` shim. 진입점이라 유지(rules 편집이 자동 반영).
  파일명의 "AGENTS" 는 배포 아티팩트가 아니라 에이전트 진입점 문서.
- 나머지 11 스킬의 비-agents 내용.
- `docs/plans/2026-06-03-import-omcc-agents.{md,html}`,
  `docs/specs/import-oh-my-claudecode-agents.md`,
  `docs/specs/design-md-conformance-skill.md`(line 75 summon 언급) — 전부 시점 기록(역사), 보존.
- `docs/guides/craft-modes.md` "spare no agents" — 관용구, 유지.
- craft-core 의 Workflow `agent()` 도구 호출 자체 — 도구 사용은 유지, `agentType` 바인딩만 제거.
- `skills/sweep` 의 `logs/agents/` — agent 실행 로그(휘발 scratch), 배포 아티팩트와 무관.

## Files (verified — path : why it changes)

| 파일 | 변경 |
|---|---|
| `agents/*.md` (6) | 삭제 — 제거 대상 아티팩트 본체 |
| `skills/summon/` | 삭제 — 에이전트 저작 스킬(사용자 결정: 같이 제거) |
| `install.sh` | line 3 주석, 29–50 agents 설치 블록, 53–54 출력 문구에서 agents 제거 |
| `sync.sh` | line 2–7 헤더 주석, 38–51 agents 미러 블록, 56·64 git add, 78 PR body 에서 agents 제거 |
| `.claude/hooks/check-skill-sync.sh` | line 6–8 주석, 33–41 (a2) agents drift, 45–48 (b) diff 경로에서 agents 제거 |
| `rules/project.md` | 스킬 12→11(summon 제거), §6 통째 제거, agents/summon 언급·검증 행·§5/§7 cross-ref 정리 |
| `README.md` | 스킬 표 summon 행 제거, "에이전트" 섹션(26–39) 제거, 카운트·검증 명령(3·53·104·105·129) 갱신 |
| `skills/craft-core/references/pipeline.md` | line 149–158 agents 풀 문단 제거(agent() 호출은 유지, agentType만 제거) |
| `skills/craft-core/references/dynamic-tdd.md` | line 56·63 agentType 키, 74–80 풀 설명 제거 |
| `skills/craft-core/references/orchestrated.md` | line 119·151·157·168–171·241–257 agentType·풀 설명 제거 |
| `docs/adr/001-...md` | Status → Superseded by ADR 002 |
| `docs/adr/002-revert-agents-artifact-type.md` | 신규 — 되돌림 결정·사유 기록 |

## Steps (each step → its verify check)

1. ADR 002 작성 + ADR 001 Superseded 표시 → `ls docs/adr/002*` 존재, 001 헤더 갱신
2. `agents/` 6 파일 + `skills/summon/` 삭제 → `test ! -d agents && test ! -d skills/summon`
3. install.sh / sync.sh / check-skill-sync.sh agents 블록 제거 → `bash -n` 3종 통과 + `grep -c agents` 가 의도 잔여(0 또는 무관)만
4. craft-core 3 references agentType 제거 → `grep -rc agentType skills/craft-core` = 0
5. rules/project.md 편집(12→11, §6 제거) → `grep -c summon rules/project.md` = 0, "11종" 반영
6. README.md 편집(표·섹션·카운트) → guard-readme-fresh 통과, "11" 카운트 정합
7. `bash install.sh` 실행 → 11 스킬 설치, agents 출력 없음, 성공 종료

## Risks

- **craft-core agentType 제거가 동작을 바꾸나?** 아니오 — pipeline.md 가 이미
  "풀 미설치 시 agentType 떨구고 기본 subagent" 폴백을 명시. agentType 제거 = 그 폴백 경로를
  유일 경로로 고정. 워크플로 자체는 동일 프롬프트로 동작. (preserve: agent() 호출·프롬프트·model pin 유지)
- **install.sh 가 live `~/.claude/agents/` 를 건드리나?** 아니오 — install 은 복사만. 기존
  설치된 6 에이전트는 live 에 남지만 이 레포가 더는 관리/덮어쓰지 않음. 사용자가 원하면 수동 정리(out of scope).
- **시점 SPEC/plan 의 summon·agents 언급이 dangling 되나?** 시점 기록은 "그 시점의 사실" 이라
  현재와 불일치해도 정상(역사). guard 도 이들을 강제하지 않음.

## Security surface

없음 — 문서·셸 스크립트의 파일 복사 로직 제거. 외부 입력·auth·secret·네트워크 변화 없음.
sync.sh `--push` 의 gh PR 자동화 경로는 agents staging 라인만 빠지고 흐름 불변.

## YAGNI (deletions in this change)

- `agents/` 6 파일, `skills/summon/` 전체 — 제거 대상 본체.
- 세 스크립트의 agents 처리 블록 — 호출처(agents/ 디렉토리)가 사라지므로 같은 변경에서 제거.
- craft-core 의 agentType 바인딩·풀 설명 — 라우팅 타겟(풀)이 사라지므로 제거.

## Acceptance (각 항목 = 단일·검증 가능 조건)

1. `test ! -e agents && test ! -e skills/summon` → 통과
2. `bash -n install.sh && bash -n sync.sh && bash -n .claude/hooks/check-skill-sync.sh` → exit 0
3. `bash install.sh` → "11" 스킬 설치 메시지, agents 설치 출력 0줄, exit 0
4. `grep -rc agentType skills/craft-core/references` → 모두 0
5. `grep -rn 'agents/\*\.md\|에이전트 6종\|에이전트 저작' rules/project.md README.md` → 0 (시점 문서 제외)
6. `bash .claude/hooks/guard-readme-fresh.sh` 상당 체크 → 모든 `skills/<name>` 링크 존재, 누락 0
7. `ls docs/adr/002-revert-agents-artifact-type.md` 존재 + ADR 001 Status=Superseded
