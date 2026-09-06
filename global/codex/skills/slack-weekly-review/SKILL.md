---
name: slack-weekly-review
description: "Create Kim Dong-hyun's Slack-ready weekly review from Draftype channel evidence, centered on each initiative's current progress, next-week projected progress, and 100% finish line. Use for weekly wrap-ups, Friday reports, delivery-progress reviews, or Slack-ready settlement text."
---

# Slack Weekly Review

Create a Korean, Slack-ready weekly review for Kim Dong-hyun from channel evidence. Treat Slack as the source for past work and the user interview as the source for future plans and initiative progress estimates. Center the review on delivery progress toward each initiative's agreed finish line, not on a chronological process retrospective.

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
- Keep completion classification internal. In the final text, express status naturally in the nested bullet instead of adding `결과`, `영향`, or status labels.

### 2.1 Estimate initiative progress

For each finite active initiative, establish what `100%` means before assigning a percentage. The finish line is the currently agreed deliverable or operational handoff, not indefinite product maturity.

- Prefer a percentage supplied or confirmed by the user.
- Otherwise propose an estimate in 5- or 10-point increments from observable completed milestones divided by the known finish-line milestones. Mark it `추정` until confirmed.
- Project next week's percentage from the outcomes the user explicitly plans to complete. It must not be lower than the current percentage and must not exceed 100%.
- Do not assign percentages to open-ended routine operations such as monitoring, infrastructure upkeep, recurring data loads, or security response without a defined closure condition. Put these under `상시 진행사항`.
- When scope, current percentage, or next-week projection is materially uncertain, ask one concise confirmation question with proposed values instead of inventing precision.

### 3. Interview for next week's plan

Begin with the carryover candidates discovered from Slack instead of asking a blank question. Ask exactly one concise question per turn and wait for the answer.

Cover these topics adaptively:

1. Which suggested carryovers and new outcomes must be delivered next week? Keep the list compact, but preserve distinct items the user explicitly supplied instead of merging them solely to meet an arbitrary count.
2. What observable completion criterion defines 100% for each finite initiative?
3. What current progress percentage and next-week expected percentage apply?
4. What deadline, order, milestone, dependency, collaboration, decision, or risk applies?

Skip questions already answered. Prefer one combined question when the user supplied most details. After collecting enough detail, show only the proposed next-week section and ask for corrections or confirmation. If the user already provided concrete work items, propose concise nested bullets and ask one combined confirmation question.

Do not generate the final review before the plan is confirmed unless the user asks for an immediate draft.

### 4. Produce the final Slack text

Return only one copyable code block containing plain text for Slack. Match the compact Slack daily-update style: a section title, `•` initiative bullets, and indented `◦` detail bullets. Keep it concise and progress-first. Do not use numbered sections, circled numbers, asterisks for emphasis, or labels such as `결과:`, `영향:`, `완료 기준:`, `목표 일정:`, `선행 조건:`, and `예상 리스크:`. Do not include a one-line summary or evidence/source links.

Dates belong only in a detail bullet when the user explicitly supplied a real milestone or appointment. Do not add a generic target-schedule field. Put routine infrastructure and operational work under `상시 진행사항`. Include `지원·확인 필요사항` only when there is a concrete dependency or decision worth surfacing.

Use this shape:

```text
김동현 [YYYY년 M월 N주차] 주간 결산 ([M/D]~[M/D])

프로젝트 공정률
• [프로젝트명] — 현재 [N]% → 차주 예상 [N]%
  ◦ 100% 기준: [현재 합의된 완료 상태]
  ◦ 현재 상태: [확인된 완료 범위와 남은 핵심 범위]
  ◦ 차주 목표: [다음 주에 완료할 범위]
  ◦ [명시된 일정·협업·의존성이 있을 때만 추가]

상시 진행사항
• [정기적으로 반복할 업무]
  ◦ [운영 또는 확인 기준이 유용할 때만 추가]

지원·확인 필요사항
• [구체적인 요청]
```

Omit empty sections and empty detail bullets. If there is no concrete support request, omit `지원·확인 필요사항` entirely. Keep top-level bullets parallel and group closely related operational items only when that makes the Slack post easier to scan. For finite initiatives, always show the current and next-week percentages plus the agreed 100% definition. For routine work, omit percentages unless a finite closure condition has been explicitly defined.
