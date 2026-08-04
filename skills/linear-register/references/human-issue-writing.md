# Human-readable Linear issue writing

Write the issue for a person who needs to understand it in under one minute. Put routing and execution metadata in Linear fields, not prose.

## General rules

- State the reason or problem before the work list.
- Use concrete nouns and observable outcomes.
- Keep sentences short; define unavoidable abbreviations once.
- Prefer two to five work bullets and two to six completion checkboxes.
- Keep the body near 1,600 characters or less. Link a separate design document when more detail is necessary.
- Mention implementation details only when they are a binding product or operational constraint.
- Omit empty optional sections.
- Do not repeat native relations, project, milestone, state, or labels.
- Do not include recommended skills, agents, workflows, work methods, kickoff prompts, or next-work prompts.

## Feature or improvement

Use for new behavior or a deliberate improvement.

```markdown
## 목적
<왜 필요한지와 사용자가 얻는 결과를 1~3문장으로 설명한다.>

## 작업 내용
- <사람이 이해할 수 있는 동작 단위>
- <필요한 상태나 예외 처리>

## 완료 조건
- [ ] <관찰 가능한 완료 상태>
- [ ] <실패·빈 상태·권한 등 중요한 조건>

## 범위 밖
- <이번 이슈에서 하지 않는 것>

## 참고
- <필요한 문서나 외부 근거 링크>
```

## Bug

Use when existing behavior is wrong or has regressed.

```markdown
## 문제
<누가 어떤 상황에서 어떤 피해를 받는지 설명한다.>

## 재현 방법
1. <최소 재현 단계>
2. <문제가 발생하는 단계>

## 기대 결과
<정상이라면 보여야 하는 동작을 설명한다.>

## 완료 조건
- [ ] <재현 절차에서 문제가 더 이상 발생하지 않는다>
- [ ] <중요한 회귀 방지 조건>

## 범위 밖
- <함께 고치지 않을 인접 문제>

## 참고
- <로그, 스크린샷, 관련 링크>
```

## Research or decision

Use when the result is evidence or a decision rather than shipped behavior.

```markdown
## 확인할 질문
<이 이슈가 답해야 하는 하나의 결정 질문을 쓴다.>

## 조사 범위
- <확인할 대상>
- <비교할 선택지 또는 데이터>

## 완료 조건
- [ ] <근거가 기록됐다>
- [ ] <결론과 남은 위험이 명확하다>

## 결과물
- <결정 기록, 보고서, 데이터셋 등>

## 범위 밖
- <이번 조사에서 다루지 않는 것>

## 참고
- <기존 결정이나 자료 링크>
```

## Title guidance

Good titles identify the outcome or failure:

- `역사별 카메라 장애를 독립적으로 표시`
- `세션 재연결 후 승하차 수가 중복 집계되는 문제`
- `영상 보관 기간과 자동 만료 정책 결정`

Avoid titles that only name a component or activity:

- `카메라 작업`
- `API 수정`
- `조사 필요`

## Do not include

Reject or rewrite bodies containing:

- `## 추천`
- `## 다음 작업`
- `시작 프롬프트`
- `[AUTO]` or `[HUMAN]`
- Commands that tell an agent which skill or workflow to run
- Boilerplate declaring how the issue was generated, unless workspace policy explicitly requires it
