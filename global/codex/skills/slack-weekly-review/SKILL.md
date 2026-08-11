---
name: slack-weekly-review
description: "Create Kim Dong-hyun's evidence-based weekly work review from the Draftype strategy-technology Slack channel, then interview the user one question at a time to finalize next week's outcomes. Use for weekly wrap-ups, weekly performance summaries, Friday reports, or requests to prepare Slack-ready weekly settlement text."
---

# Slack Weekly Review

Create a Korean, Slack-ready weekly review for Kim Dong-hyun from channel evidence. Treat Slack as the source for past work and the user interview as the source for future plans.

## Fixed context

- Workspace: `draftypehq`
- Channel ID: `C09AKQV5G95`
- Channel URL: `https://draftypehq.slack.com/archives/C09AKQV5G95`
- Subject: Kim Dong-hyun (`김동현`)
- Subject user ID: `U062Q3ST879`
- Timezone: `Asia/Seoul`
- Default period: Monday 00:00 through the current time in the current week

Honor an explicit reporting period from the user. Interpret `이번 주` in `Asia/Seoul`.

## Workflow

### 1. Collect Slack evidence

1. Confirm Slack read tools are available. If unavailable, explain that the Slack connection is required and stop.
2. Read up to 1,000 recent channel messages and filter them to the reporting period.
3. Inspect thread replies for relevant parent messages when any of these conditions apply:
   - Kim Dong-hyun authored the parent message.
   - The parent mentions `U062Q3ST879`, `김동현`, or `동현님`.
   - Kim Dong-hyun appears among the reply authors.
   - The parent is a daily or weekly strategy-technology work thread during the period.
4. Include direct posts, replies, explicit assignments, and explicit collaboration credit. Do not treat mere thread participation or reactions as proof of work.
5. Keep source timestamps and links as internal verification evidence. Do not include them in the final text unless the user explicitly requests sources.

Never post, reply, react, or otherwise mutate Slack unless the user explicitly asks. This skill's default result is text for manual paste.

### 2. Build the evidence draft

Group evidence into project or workstream results such as R&D, product development, data/infrastructure, DevOps, and operations. Merge repeated daily updates into one result.

Classify every item as one of:

- Completed: Slack contains explicit completion, deployment, delivery, validation, or measurable outcome evidence.
- In progress: work started or advanced, but completion is not evidenced.
- Planned: only an intention or schedule is present.
- Blocked: a dependency or impediment is explicit.

Do not infer completion from a plan. Do not invent metrics, impact, dates, or collaborators. Omit weak evidence or label it `확인 필요`.

Draft:

- Up to five meaningful results, ordered by impact.
- In-progress and carryover candidates.

### 3. Interview for next week's plan

Begin with the carryover candidates discovered from Slack instead of asking a blank question. Ask exactly one concise question per turn and wait for the answer.

Cover these topics adaptively:

1. Which suggested carryovers and new outcomes must be delivered next week? Limit the final list to three priorities.
2. What observable completion criterion applies to each priority?
3. What deadline, order, or milestone applies?
4. What dependency, collaboration, decision, or risk applies?

Skip questions already answered. Prefer one combined question when the user supplied most details. After collecting enough detail, show only the proposed next-week section and ask for corrections or confirmation.

Do not generate the final review before the plan is confirmed unless the user asks for an immediate draft.

### 4. Produce the final Slack text

Return only one copyable code block containing plain text for Slack. Keep it concise and outcome-first. Do not use asterisks for emphasis. Do not include a one-line summary or evidence/source links. Use this shape:

```text
김동현 [YYYY년 M월 N주차] 주간 결산 ([M/D]~[M/D])

1. 이번 주에 만든 결과

① [업무명] — [핵심 결과]
• 결과: [...]
• 영향: [...]

2. 진행 중·이월 과제
• [과제]: [현재 상태와 남은 범위]

3. 다음 주에 만들 결과

① [우선순위] — [목표 결과]
• 완료 기준: [...]
• 목표 일정: [...]
• 선행 조건·협업: [...]
• 예상 리스크: [...]

상시 루틴
• [정기적으로 반복할 업무와 확인 기준]

4. 지원·의사결정 필요사항
• [없음 또는 구체적인 요청]
```

Omit empty result entries. Omit optional detail lines whose value would be `없음`; retain the support section and write `없음` there when applicable.
