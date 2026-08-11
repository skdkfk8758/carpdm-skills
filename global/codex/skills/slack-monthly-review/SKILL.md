---
name: slack-monthly-review
description: "Create Kim Dong-hyun's evidence-based monthly work review from the Draftype strategy-technology Slack channel, then interview the user one question at a time to finalize next month's outcomes. Use for month-end reviews, monthly performance summaries, monthly settlements, or requests to prepare Slack-ready monthly wrap-up text."
---

# Slack Monthly Review

Create a Korean, Slack-ready monthly review for Kim Dong-hyun from channel evidence. Treat Slack as the source for past work and the user interview as the source for next-month plans.

## Fixed context

- Workspace: `draftypehq`
- Channel ID: `C09AKQV5G95`
- Channel URL: `https://draftypehq.slack.com/archives/C09AKQV5G95`
- Subject: Kim Dong-hyun (`김동현`)
- Subject user ID: `U062Q3ST879`
- Timezone: `Asia/Seoul`
- Default period: the first calendar day of the current month through the current time

Honor an explicit reporting month from the user. Interpret month boundaries in `Asia/Seoul`.

## Workflow

### 1. Collect Slack evidence

1. Confirm Slack read tools are available. If unavailable, explain that the Slack connection is required and stop.
2. Read up to 1,000 recent channel messages and filter them to the reporting month.
3. Verify coverage: if the oldest retrieved message is newer than the month start while more history exists, state the coverage gap and do not claim a complete monthly review.
4. Inspect thread replies for relevant parent messages when any of these conditions apply:
   - Kim Dong-hyun authored the parent message.
   - The parent mentions `U062Q3ST879`, `김동현`, or `동현님`.
   - Kim Dong-hyun appears among the reply authors.
   - The parent is a daily, weekly, or monthly strategy-technology work thread during the period.
5. Include direct posts, replies, explicit assignments, and explicit collaboration credit. Do not treat mere thread participation or reactions as proof of work.
6. Keep source timestamps and links as internal verification evidence. Do not include them in the final text unless the user explicitly requests sources.

Never post, reply, react, or otherwise mutate Slack unless the user explicitly asks. This skill's default result is text for manual paste.

### 2. Build the evidence draft

Consolidate repeated daily and weekly items into monthly workstreams. Prefer three to five workstreams such as R&D, product development, data/infrastructure, DevOps, and operations.

Classify every item as one of:

- Completed: Slack contains explicit completion, deployment, delivery, validation, or measurable outcome evidence.
- In progress: work started or advanced, but completion is not evidenced.
- Planned: only an intention or schedule is present.
- Blocked: a dependency or impediment is explicit.

Do not infer completion from a plan. Do not invent metrics, impact, dates, or collaborators. Omit weak evidence or label it `확인 필요`.

Draft:

- Three to five major results ordered by impact.
- Operational, infrastructure, and collaboration contributions.
- Plan-versus-result status and carryover candidates.

### 3. Interview for next month's plan

Begin with carryover candidates and recurring work inferred from Slack instead of asking a blank question. Ask exactly one concise question per turn and wait for the answer.

Cover these topics adaptively:

1. Which suggested carryovers and new outcomes must be delivered next month? Limit the final list to three priorities.
2. What observable completion criterion applies to each priority?
3. What business or organizational effect should each priority create?
4. What weekly milestone or deadline applies?
5. What dependency, budget, equipment, collaboration, decision, or risk applies?

Skip questions already answered. Prefer one combined question when the user supplied most details. After collecting enough detail, show only the proposed next-month section and ask for corrections or confirmation.

Do not generate the final review before the plan is confirmed unless the user asks for an immediate draft.

### 4. Produce the final Slack text

Return only one copyable code block containing plain text for Slack. Keep it concise and outcome-first. Do not use asterisks for emphasis. Do not include a one-line summary or evidence/source links. Use this shape:

```text
김동현 [YYYY년 M월] 월간 결산

1. 이번 달 핵심 결과

① [워크스트림] — [대표 성과]
• 목표: [...]
• 결과: [...]
• 영향: [...]

2. 운영·인프라 개선
• 비용: [...]
• 안정성: [...]
• 데이터·보안: [...]

3. 협업 기여
• [협업 대상과 공동 결과]

4. 계획 대비 현황
• 완료: [...]
• 진행 중·이월: [...]
• 보류·변경: [...]

5. 다음 달 핵심 계획

① [목표] — [만들 결과]
• 완료 기준: [...]
• 기대 효과: [...]
• 주요 마일스톤: [...]
• 필요한 협업·지원: [...]
• 예상 리스크: [...]

상시 루틴
• [정기적으로 반복할 업무와 확인 기준]

6. 지원·의사결정 필요사항
• [없음 또는 구체적인 요청]
```

Omit empty result entries. Omit optional detail lines whose value would be `없음`; retain the support section and write `없음` there when applicable.
