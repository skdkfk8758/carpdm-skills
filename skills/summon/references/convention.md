# 서브에이전트 저작 컨벤션

신뢰할 수 있는 서브에이전트 뒤에 있는 주석 달린 섹션 골격과 작성 규율 규칙. 19개 프로덕션
에이전트 함대에서 증류했다. `SKILL.md` 의 5단계에서 본문을 작성할 때 이것을 템플릿으로 쓰라. 당신이
작성하는 본문은 그 자체로 에이전트의 전체 시스템 프롬프트다 — 제 무게를 짊어지게 하라.

## 골격 (마크다운 형식)

표준 Claude Code 에이전트는 순수 마크다운 본문을 쓴다. 각 섹션을 `##` 헤딩으로 렌더하라.
(소스 함대는 이것들을 `<Agent_Prompt>` XML 태그로 감쌌다 — oh-my-claudecode 프레임워크 컨벤션이다.
래퍼는 버리고; 섹션은 유지하라.)

```markdown
---
name: <kebab-name>
description: <delegation tagline — when to route here>
model: opus | sonnet | haiku        # omit to inherit
disallowedTools: Write, Edit        # ONLY for read-only agents; else omit
---

You are <Name>. Your mission is to <one-sentence verb-phrase>.
You are responsible for <comma-separated duties>.
You are not responsible for <duties> (<other-agent> handles that).

## Why this matters
<Cost/consequence rationale. Why do these rules exist? Frame the stakes — a bad call here
costs 10–100x downstream, an undetected X ships to prod, etc. This is what lets the model
generalize past the literal instructions.>

## Success criteria
- <Measurable, checkable done-condition.>
- <Another. These should be objectively verifiable, not "do a good job".>

## Constraints
- <Hard rule. Scope limit. Read-only marker if applicable.>
- After <N> failed attempts on the same issue, escalate to <agent> with full context.
- Hand off to: <agent> (<when>), <agent> (<when>).

## Process
1. <First step — usually "gather context / read before acting".>
2. <...>
N. <Synthesize into the Output Format below.>

## Tool usage
- Use <Tool> for <purpose>.
- Use <Tool> for <purpose>.

## Output format
<A LITERAL markdown template the agent emits every time. Show the actual headings, the actual
table columns, the verdict line. Not a description of the output — the output itself, with
[bracketed placeholders].>

## Failure modes to avoid
- <Named failure>: <the bad behavior>. Instead, <the correct behavior>.
- <Named failure>: <the bad behavior>. Instead, <the correct behavior>.

## Examples
**Good:** <Concrete, with real file:line / commands. Shows the discipline in action.>
**Bad:** <Concrete counter-example. Name why it's bad.>

## Final checklist
- Did I <success-criterion #1 as a question>?
- Did I <success-criterion #2 as a question>?
```

## 섹션별 규율

**Role 삼위.** 항상 세 동작: mission(한 문장) → 책임 → 비책임. 비책임 절은 제외된 작업을 소유하는
*다른* 에이전트를 지목한다 — 이것이 함대가 결합도를 낮게 유지하는 방식이자 오케스트레이터가 어디로
라우팅할지 아는 방식이다. 단독 에이전트에게도 작성하라 ("You are not responsible for
implementation — you only advise.").

**Why this matters.** 단일 최고 레버리지 섹션. 암기식 규칙을 이해된 규칙으로 바꾼다. "모든 발견이
file:line 을 인용한다"는 그 자체로 약하다; "file:line 증거 없는 진단은 신뢰할 수 없고 implementer
시간을 낭비하므로 모든 주장은 추적 가능해야 한다"는 모델이 따르고 *싶게* 만든다. 목록보다 강한 근거
하나를 선호하라.

**Success criteria → Final checklist.** 이 둘을 쌍으로 작성하라. 각 기준은 측정 가능한 완료
조건이고; 각 체크리스트 항목은 그 동일 기준을 "Did I …?"로 표현한 것이다. 기준이 예/아니오 질문이 될
수 없다면 너무 모호하다 — 날카롭게 다듬어라.

**Constraints.** 가드레일을 두는 곳: 범위 한계("smallest viable diff"), read-only 표식, 서킷
브레이커("3회 실패 후 에스컬레이트"), 그리고 `Hand off to:` 맵. writing 에이전트의 경우 도구가
제한되지 않으므로 여기서 범위 확산을 막는다.

**Process.** 산문이 아니라 번호 매긴 시퀀스. 조사/조언 에이전트는 거의 항상 "맥락 수집 / 실제 코드를
FIRST 읽기"로 시작한다 — 반복되는 실패 모드는 읽기 전에 행동하는 것이다. Output Format 으로 깔때기를
만들며 끝내라.

**Tool usage.** 도구당 한 불릿: `Use <Tool> for <purpose>`. 이것은 *부드러운* 안내다 (frontmatter 가
강한 강제다). 에이전트가 위임할 수 있다면 명시하고 가드레일을 더하라 "위임이 불가능하면 조용히
건너뛰어라; 절대 그 때문에 막히지 말 것".

**Output format.** 문자 그대로 만들어라. 가장 일관되게 행동하는 에이전트들은 "Structure your
response EXACTLY as follows"라고 말한 뒤 실제 템플릿을 보여준다 — 판정 줄
(`APPROVE / REQUEST CHANGES`), 트레이드오프 표, 심각도 태그 불릿, `file:line — 무엇을 보여주는지`의
`References` 목록. 서술된 형식은 표류하고; 보여진 형식은 재현된다.

**Failure modes.** 대비형 쌍만: `<name>: <bad>. Instead, <good>.` 이것은 금지 목록보다 경계를 훨씬 잘
가르친다, *올바른* 대안을 틀린 것 바로 옆에 고정하기 때문이다. 에이전트의 실제로 예상되는 실패
모드에서 뽑아내라 — overengineering, scope creep, premature completion, armchair analysis,
symptom-chasing, vague recommendations.

**Examples.** 구체가 매번 추상을 이긴다. 실제처럼 보이는 file:line, 실제 명령, 실제 diff 크기를
쓰라. Good 은 규율을 보여주고; Bad 은 왜 틀렸는지 한 줄 진단과 함께 함정을 보여준다.

## 작성 스타일 (전반 적용)

- **2인칭 명령형.** "Use Read to…", "Never approve without…", "Stop when…". 1인칭 없음, 얼버무림
  없음.
- **증거 척추.** 모든 분석/리뷰/디버그 에이전트에 대해 "file:line 인용 / fresh output 표시 / 증거
  없는 주장 금지"를 하중을 받는 규칙으로 만들어라. "증거 없는 발견은 발견이 아니라 의견이다."
- **이유를 설명하고, MUST 를 쌓지 말라.** 도처에 대문자 ALWAYS/NEVER 를 쓰고 있다면, 근거로 재구성
  하라. 모델은 소리지른 규칙보다 이해된 규칙을 더 잘 따른다. 강조는 진정으로 침범 불가한 한두 규칙에
  아껴두라.
- **정지 조건.** 에이전트가 언제 완료되어 반환해야 하는지 명시하라 — "진단이 완료되고 모든 권고에
  file:line 참조가 있을 때 멈춰라." 끝이 열린 에이전트는 횡설수설한다.
- **노력, 단계뿐 아니라.** 얼마나 열심히 일할지에 대한 짧은 한 줄 — "증거를 동반한 철저한 분석" 대
  "작업 크기에 노력 맞추기" 대 "빠르고 좁게" — 가 에이전트를 그 model 티어에 맞춰 보정한다.

## 섹션을 몇 개 둘지 선택

- **풀 advisor/reviewer/implementer** → 열 개 섹션 전부.
- **좁은 조회/출력 에이전트** (search, doc-write) → Role + Process + Output Format + Failure Modes
  로 충분한 경우가 많다; Why/Examples/Checklist 는 선택.
- **Role**, **Output Format**, **Failure Modes** 는 절대 떨어뜨리지 말 것 — 이 셋은 소스 함대 전체에
  걸친 협상 불가 척추다.
