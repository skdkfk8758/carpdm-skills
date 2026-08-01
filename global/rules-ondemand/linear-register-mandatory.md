# Linear Issue Registration — linear-register 스킬 필수 경유

IMPORTANT: Linear 에 **이슈를 생성·등록**하는 모든 경우는 반드시 `linear-register` 스킬을 경유한다. `mcp__linear__save_issue`(생성 = `id` 없이)를 스킬 없이 직접 호출하지 않는다. 사용자가 "리니어에 이슈 등록", "이거 티켓으로 올려줘", "이슈 만들어줘" 류로 요청하면 — 'linear-register'·'스킬'이라는 말이 없어도 — 이 스킬을 먼저 호출한다.

## 왜

직접 `save_issue` 하면 스킬이 보장하는 절차가 통째로 빠진다: ① repo→팀 라우팅(`linear-repo-map.json` 역매핑) ② 생성 전 확인 게이트 ③ 이슈마다 적응형 `## 추천` 섹션(글로벌 스킬/에이전트 우선) ④ 의존 체인이면 Linear 관계 세팅 + 다음 작업 전방 포인터·kickoff 프롬프트 + AI disclaimer.

## 경계 (이건 linear-register 아님)

**이슈 생성 진입점은 `linear-register` 단일** — 단건~소수 등록과 대형 plan/spec/PRD 분할(분할 모드, `references/plan-split.md`) 모두 이 스킬이 처리한다(2026-07-21 통합). register 표준 코어 헤딩(`## 작업 내용`/`## 수용 기준`/`## 추천`) + team-scope + 기본 state=Triage + AI disclaimer 를 emit 한다. 그 외 스킬은 생성이 아니다.

| 작업 | 스킬 |
|---|---|
| Linear 이슈 등록 — 단건~소수 + plan/spec/PRD 분할·발행 | **`linear-register`** (이 룰) |
| 티켓 자율빌드 실행 | `linear-goal` |
| 기존 백로그 재배치·보강 | `linear-groom` |
| 이슈 **조회**(현재 repo 팀 스코프) | `linear-dispatch.md` 룰 |

> **예외 — `orca-linear`**: `orca linear create` 는 별도 런타임(Orca IDE CLI)이라 본 룰의 MCP 경유 강제 밖이다. Orca 세션에서 티켓을 만들 때만 쓰고, 일반 Claude Code 흐름의 이슈 생성은 단일 진입점을 따른다.

## 강제

- 자동 강제(hook): `guard-linear-register-nudge.sh`(PreToolUse `mcp__linear__save_issue`) — 생성 호출 시 stderr nudge. **비차단**(스킬 자신이 save_issue 를 호출하므로 하드 블록 불가). 끄기: `GUARD_LINEAR_REGISTER_NUDGE_DISABLE=1`.
- 위 nudge 는 리마인드일 뿐 — 실제 경유는 본 룰을 읽은 AI 가 한다.

## Related

- `~/.claude/skills/linear-register/SKILL.md` — 스킬 본체(짝).
- `~/.claude/rules-ondemand/linear-dispatch.md` — 이슈 *조회* 스코프(등록의 반대 방향).
