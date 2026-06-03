# 표준 Claude Code 서브에이전트 frontmatter

서브에이전트 정의 파일의 YAML frontmatter, 그리고 model 및 도구 선택 규칙에 대한 권위 있는 참조.
출처: Claude Code 문서 (code.claude.com/docs/en/sub-agents). `name` 과 `description` 만 필수이고,
나머지는 모두 선택이다.

## 지원 필드

| 필드 | 필수 | 역할 |
|---|---|---|
| `name` | **Yes** | 고유 식별자, 소문자 + 하이픈. 훅이 이를 `agent_type` 으로 받는다. 파일명이 일치할 필요는 없지만, 온전한 정신을 위해 동일하게 유지하라. |
| `description` | **Yes** | Claude 가 언제 이 에이전트에 위임해야 하는지. 이것이 라우팅 신호다 — 무엇인지가 아니라 *언제 쓸지*에 관해 작성하라. |
| `tools` | No | 에이전트가 쓸 수 있는 도구의 allowlist, 쉼표 구분. **생략 시 모든 도구를 상속한다.** |
| `disallowedTools` | No | denylist — 상속/허용된 집합에서 제거되는 도구. read-only 에이전트에 이것을 쓰라 (`Write, Edit`). |
| `model` | No | `sonnet`, `opus`, `haiku`, 전체 model ID (예: `claude-opus-4-8`), 또는 `inherit`. 기본값은 `inherit`. |
| `permissionMode` | No | `default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, 또는 `plan`. |
| `maxTurns` | No | 에이전트가 멈추기 전 agentic 턴 상한. |
| `skills` | No | 시작 시 에이전트 컨텍스트에 미리 로드할 스킬 (전체 내용 주입). |
| `mcpServers` | No | 이 에이전트가 사용할 수 있는 MCP 서버 (이름 또는 인라인 config). |
| `hooks` | No | 이 에이전트로 범위 한정된 생명주기 훅. |
| `isolation` | No | `worktree` 는 에이전트에게 repo 의 격리된 사본을 준다. |

일부 서드파티 함대에서 보이는 비표준 필드 — **사용하지 말 것**, 표준 Claude Code 가 무시한다:
`level`, `color`, 그리고 `<Agent_Prompt>` XML 본문 래퍼 (oh-my-claudecode 프레임워크 컨벤션).

## 서브에이전트가 사용할 수 있는 도구

서브에이전트는 기본적으로 메인 대화의 내부 도구와 MCP 도구를 상속한다. **다음 도구들은 `tools` 에
나열되어 있어도 서브에이전트에서 절대 사용 불가하다** — 메인 대화의 UI/세션 상태에 의존하기
때문이다:

- `Agent`
- `AskUserQuestion`
- `EnterPlanMode`
- `ExitPlanMode` (`permissionMode: plan` 이 아닌 한)
- `ScheduleWakeup`
- `WaitForMcpServers`

따라서 서브에이전트는 스스로 사용자에게 질문하거나 `Agent` 로 다른 서브에이전트를 띄울 수 없다 —
그것을 감안해 설계하라. 에이전트가 "사용자에게 물어봐야" 한다면, 대신 미해결 질문을 출력에 반환해
오케스트레이터가 해결하게 하라.

## 도구 제한 — 두 가지 전략

둘 다가 아니라 하나를 쓰라:

**Allowlist** (`tools`) — 한 집합만 배타적으로 허용; MCP 도구를 포함한 그 외 모든 것은 거부됨:
```yaml
---
name: safe-researcher
description: Research agent with restricted capabilities
tools: Read, Grep, Glob, Bash
---
```

**Denylist** (`disallowedTools`) — 명시된 도구를 제외한 모든 것을 상속. read-only advisor 를 만드는
깔끔한 방법:
```yaml
---
name: architecture-advisor
description: Read-only architecture and debugging advisor
disallowedTools: Write, Edit
---
```

경험칙:
- **Read-only / advisory** → `disallowedTools: Write, Edit` (가장 단순) 또는 빡빡한 `tools` allowlist.
- **Writing / implementing** → `tools` 생략 (전부 상속), 대신 본문에서 범위를 제약.

## model 선택 규칙

| 선택 | 작업 성격 | 이유 |
|---|---|---|
| `opus` | 모호성 하의 판단: 계획, 적대적 리뷰, 요구사항, 보안, 아키텍처 | 이 작업들은 얕은 추론에 벌점을 준다; 비용이 정당화됨 |
| `sonnet` | 한정된 실행 / 구조화된 조사: 구현, 디버깅, 테스트, 추적 | "정의된 이 일을 잘하라"의 강력한 기본값 |
| `haiku` | 기계적, 좁음, 대량: codebase search, 문서 생성 | 깊은 추론이 불필요한 곳에서 빠르고 저렴 |
| 생략 (`inherit`) | 에이전트가 부모 세션이 돌리는 무엇이든 따라야 할 때 | 비용/품질을 고정하고 싶지 않을 때 |

진정으로 확신이 없으면 `sonnet` 을 기본으로.

## 파일 위치와 우선순위

두 에이전트가 이름을 공유하면, 우선순위가 높은 쪽이 이긴다:

| 위치 | 범위 | 우선순위 |
|---|---|---|
| Managed settings | 조직 전체 | 1 (최고) |
| `--agents` CLI flag | 현재 세션 | 2 |
| `.claude/agents/` | 현재 프로젝트 | 3 |
| `~/.claude/agents/` | 모든 프로젝트 | 4 |
| Plugin `agents/` dir | 플러그인이 활성화된 곳 | 5 (최저) |

`.claude/agents/` 와 `~/.claude/agents/` 둘 다 재귀적으로 스캔되므로, 정리를 위한 하위 폴더
(`agents/review/…`)도 괜찮다 — 정체성은 경로가 아니라 `name` 에서 온다.

## 로딩

에이전트 디렉터리에 직접 작성된 파일은 **다음** Claude Code 시작 시 로드된다. `/agents` 대화형
인터페이스로 만든 에이전트는 즉시 적용된다. `summon` 이 파일을 작성한 뒤, 사용자에게 재시작하라고
알려라 (지금 당장 라이브로 필요하면 `/agents` 로 재생성).
