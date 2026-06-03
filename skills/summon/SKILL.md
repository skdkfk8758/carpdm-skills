---
name: summon
description: 재사용 가능한 NEW Claude Code 서브에이전트 정의 파일을 end-to-end 로 저작 — 짧은 인터뷰로 에이전트의 역할을 확정하고, 적합한 model(opus/sonnet/haiku)을 고르고, 도구 접근(read-only 대 writing)을 잠그고, 검증된 시스템 프롬프트(Role → Success Criteria → Constraints → Output Format → Failure Modes → Final Checklist)를 ~/.claude/agents/ 또는 .claude/agents/ 에 작성한다. 사용자가 새 서브에이전트/에이전트를 CREATE, DEFINE, SCAFFOLD, DESIGN, WRITE 하려 할 때 사용 — "make me an agent that reviews migrations", "create a subagent for dependency audits", "I need a specialized agent to triage flaky tests", "scaffold a security-review agent", "design an agent for X", "/summon" 같은 표현. 이것은 새 에이전트 DEFINITION FILE 을 저작하기 위한 것이지, 일회성 작업을 처리하기 위한 것이 아니다. 사용자가 단지 어떤 에이전트에게 작업을 위임하려 할 때(Agent/Task 도구 사용), 앱 기능을 빌드할 때(forge 사용), 버그를 고칠 때(hunt 사용)는 트리거하지 말 것.
---

# summon — Claude Code 서브에이전트 저작

한 줄짜리 아이디어("SQL 마이그레이션을 감사하는 에이전트")를, Claude Code 가 위임할 수 있는 완성된
잘 구조화된 서브에이전트 정의 파일로 바꾼다. 산출물은 YAML frontmatter 가 붙은 단일 마크다운 파일
하나이며, 사용자의 에이전트 디렉터리에 작성된다.

여기서의 설계 규율은 검증된 19개 프로덕션 서브에이전트 함대에서 역설계한 것이다: 모든 에이전트는
자신의 미션, 비책임 영역(이것이 위임 맵 역할도 한다), 측정 가능한 성공 기준, 명시적 출력 템플릿,
그리고 대비형 실패 모드를 선언한다. 그 구조가 에이전트를 막연한 페르소나 대신 *신뢰할 수 있게*
만든다.

## 이 형태가 통하는 이유

서브에이전트의 본문은 그 자체로 **전체** 시스템 프롬프트가 된다 — Claude Code 의 메인 시스템
프롬프트를 상속하지 *않고*, 본문에 기본 환경 정보만 더해진다. 따라서 본문이 모든 것을 짊어져야 한다:
에이전트가 누구인지, "완료"가 무엇을 의미하는지, 절대 해서는 안 되는 것이 무엇인지, 정확히 무엇을
내보내야 하는지. 얄팍한 "You are a helpful X" 프롬프트는 표류한다; 아래 골격은 행동을 고정한다.
당신이 쓰는 프롬프트에서 각 규칙 뒤의 *이유*를 설명하라 — 이 모델들은 추론을 잘하며 헐벗은 MUST 보다
근거를 더 잘 따른다.

## 워크플로

순서대로 진행하라. 진정으로 추론할 수 없는 것만 물어라 — 사용자가 이미 에이전트를 풍부하게
설명했다면 슬롯을 직접 채우고 확인받되, 심문하지 말 것.

**작성 언어 (이 레포 정책):** 생성하는 에이전트의 본문 prose 와 frontmatter `description` 값은
**한국어**로 작성한다. 단 `name`·`model`·`tools`/`disallowedTools` 값·도구명·코드 식별자·파일경로,
그리고 `description` 안에 인용한 트리거 예시 구절은 원문(영어) 그대로 유지한다 — 식별자/매칭이
깨지지 않도록. (근거: `rules/project.md` 의 작성 언어 정책.)

### 1. 역할 확정 (모호할 때만 인터뷰)

다음에 대해 명료한 답을 얻어라:
- **Mission** — 한 문장: "X 를 분석하고 Y 를 산출한다". 사용자가 한 문장으로 말할 수 없다면 그
  에이전트는 너무 넓다 — 분할하거나 좁혀라.
- **Delegation trigger** — 오케스트레이터가 언제 이 에이전트에게 작업을 넘겨야 하는가? 이것이
  `description` 이 되며 단일 최중요 필드다: Claude 는 작업을 이것과 매칭해 에이전트로 라우팅한다.
- **Reads or writes?** — 파일/코드를 변경하는가(writing agent), 아니면 검사하고 조언만 하는가
  (read-only agent)? 이것이 도구를 결정한다 (3단계).
- **Hand-offs** — 명시적으로 책임지지 *않는* 것은 무엇이고, 그것은 어느 다른 에이전트가 소유하는가?
  "없음"도 유효한 답이다; 그것을 포착하라.

### 2. Name + description

- `name`: lowercase-with-hyphens, 파일 스템과 일치 (예: `migration-auditor`).
- `description`: 위임 태그라인. 검증된 두 스타일 — 역할 + 괄호 부연
  (`"Adversarial plan/code review gate (read-only)"`) 또는 능력 목록
  (`"Root-cause analysis, regression isolation, stack-trace triage"`). 약 20단어 이하로 유지하고
  *언제 여기로 라우팅할지*에 관한 것으로 작성하라, 그것이 선택을 좌우하기 때문이다.

### 3. model 선택

읽기 쉬운 규칙 (소스 함대의 분포에서):

| 선택 | 작업 성격 | 예 |
|---|---|---|
| `opus` | 모호성 하의 판단 — 계획, 적대적 리뷰, 요구사항, 보안, 아키텍처 | planner, critic, security-reviewer, architect |
| `sonnet` | 한정된 실행 또는 구조화된 조사 | executor, debugger, test-engineer, tracer |
| `haiku` | 기계적 조회 또는 저렴한 좁은 출력 | codebase search, doc-writing |

확신이 없으면 `sonnet` 을 기본으로. 부모 세션의 model 을 상속하려면 `model` 을 통째로 생략하라 —
비용/품질을 정말로 고정해서는 안 될 때만 그렇게 하라.

### 4. 도구 접근 잠금

본문은 *어느* 도구를 쓸지 서술하고; frontmatter 는 무엇에 도달 가능한지 *강제*한다. 하나를 골라라:

- **Read-only / advisory agent** → 변경을 제한. 가장 깔끔한 방법: `disallowedTools: Write, Edit`
  (나머지는 모두 상속, 파일 변경만 차단). 또는 빡빡한 allowlist:
  `tools: Read, Grep, Glob, Bash, WebFetch`.
- **Writing / implementing agent** → `tools` 를 생략해 전체 도구 세트를 상속한 뒤, frontmatter 가
  아니라 본문(`<Constraints>`)에서 범위를 제약하라.

주의: 일부 도구는 나열해도 서브에이전트에서 절대 사용 불가하다 — `Agent`, `AskUserQuestion`,
`EnterPlanMode`, `ExitPlanMode`, `ScheduleWakeup`. 이것들을 `tools` 에 절대 넣지 말 것. (전체 규칙과
완전한 frontmatter 필드 목록: `references/frontmatter.md`.)

### 5. 시스템 프롬프트 본문 작성

섹션 골격을 채워라. 주석 달린 템플릿과 작성 규율 규칙은 `references/convention.md` 를 읽고; 형태를
복사할 두 개의 완성된 작업 예시(read-only advisor 하나, writing implementer 하나)는
`references/examples.md` 를 읽어라. 척추는, 순서대로:

1. **Role** — `You are <Name>. Your mission is to <verb>.` 다음 `You are responsible for …` 다음
   `You are not responsible for … (<other-agent> handles that).` 부정 절이 위임 맵이다.
2. **Why This Matters** — 비용/결과 근거. 이 규칙들이 왜 존재하는가?
3. **Success Criteria** — 측정 가능하고 체크 가능한 완료 조건 (이것이 Final Checklist 가 된다).
4. **Constraints** — 강한 규칙, 범위 한계, `Hand off to:` 줄, 에스컬레이션 정책.
5. **Process** — 에이전트가 따르는 번호 매긴 도메인 워크플로.
6. **Tool Usage** — `Use <Tool> for <purpose>` 불릿.
7. **Output Format** — 에이전트가 매번 내보내는 *문자 그대로의* 마크다운 템플릿.
8. **Failure Modes to Avoid** — 대비형 쌍: `<name>: <bad behavior>. Instead, <right
   behavior>.`
9. **Examples** — 구체적인 Good 하나, 구체적인 Bad 하나 (추상이 아니라 실제 file:line / 명령).
10. **Final Checklist** — Success Criteria 를 "Did I …?" 질문으로 재진술.

모든 에이전트가 열 개 모두 필요한 것은 아니다 — 작은 조회 에이전트는 Why/Examples 를 덜어낼 수
있다 — 하지만 전체 세트를 기본으로 하고, 누락이 아니라 의도적으로 섹션을 떨어뜨려라. 섹션에는
마크다운 `##` 헤딩을 사용하라 (표준 Claude Code 에이전트는 순수 마크다운이다; 소스 함대의 XML 태그
스타일은 oh-my-claudecode 프레임워크 컨벤션이며 여기서는 불필요하다).

### 6. 설치 위치 선택 (ASK)

사용자가 이미 말하지 않았다면 물어라:
- **Global** `~/.claude/agents/<name>.md` — 모든 프로젝트에서 사용 가능.
- **Project** `.claude/agents/<name>.md` — 이 repo 로 범위 한정, 버전 관리에 체크인되어 팀이
  공유한다. 디렉터리가 없으면 생성하라.

### 7. 작성, 검증, 보고

파일을 작성한 뒤, 완료를 주장하기 전에 검증하라:
- frontmatter 가 파싱됨; `name` 이 kebab-case; `description` 존재.
- `model` 이 `opus`/`sonnet`/`haiku`/`inherit` 중 하나 (또는 생략).
- `tools` allowlist 에 서브에이전트 사용 불가 도구 없음.
- 선택된 모든 섹션이 존재하며 플레이스홀더가 아님.

사용자에게 경로를 알려주고, **새** 에이전트 파일은 로드되려면 Claude Code 재시작이 필요함을 알려라
(`/agents` 인터페이스로 만든 에이전트는 즉시 로드되지만, 직접 작성한 파일은 재시작 전까지 그렇지
않다). 그런 다음 호출 방법을 보여줘라 (매칭되는 작업을 위임하거나, 명시적으로 호출).

## 안티패턴

- **페르소나 전용 프롬프트** — Success Criteria 나 Output Format 없는 "You are an expert X". 읽기에는
  멀쩡하나 행동은 무작위다. 골격은 정확히 이것을 막으려 존재한다.
- **만능 에이전트** — 계획도 하고 구현도 하고 리뷰도 하는 하나의 에이전트. 책임별로 분할하라;
  비책임 절은 이것을 강제하려고 있다.
- **frontmatter 범위 연극** — `tools` 를 나열해놓고 본문에서 모순되거나, writing agent 를 너무
  빡빡하게 제한해 일을 못 하게 만들기. 잠금을 역할에 맞춰라 (4단계).
- **`level:` 필드나 `<Agent_Prompt>` XML 래퍼 복사** (oh-my-claudecode 에이전트에서) — 그것들은 그
  프레임워크의 런타임 컨벤션이다; 표준 Claude Code 는 `level` 을 무시하고 래퍼도 필요하지 않다.
