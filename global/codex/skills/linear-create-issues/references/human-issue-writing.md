# Human-readable Linear issue writing

Write the issue for a person who needs to understand it in under one minute. Put routing and execution metadata in Linear fields, not prose.

## General rules

- State the reason or problem before the work list.
- Use concrete nouns and observable outcomes.
- Keep sentences short; define unavoidable abbreviations once.
- Prefer two to five work bullets and two to six completion checkboxes.
- Write every completion checkbox so a person is not required to judge it: a product action or command and its observable result (endpoint response, screen state, CLI output), a file that must exist, or a number. `잘`, `정상적으로`, `깔끔`, `적절히` cannot be judged.
- Do not write test, typecheck, or lint commands as completion checkboxes. They are the means of verification, not the definition of success, and `goal-prompt` measures them from the repo at kickoff (see below).
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
- [ ] <명령 또는 조작 → 기대 결과>
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
- [ ] <근거가 `결과물` 에 적힌 위치에 기록됐다>
- [ ] <결론과 남은 위험이 명확하다>

## 결과물
- <결정 기록, 보고서, 데이터셋 등>

## 범위 밖
- <이번 조사에서 다루지 않는 것>

## 참고
- <기존 결정이나 자료 링크>
```

## Written to be consumed by `goal-prompt`

착수 시점에 이 이슈는 `goal-prompt` 가 읽어 Goal Prompt 한 파일로 깎인다. 각 섹션이 프롬프트의 어느 칸으로 가는지 알고 쓰면 착수할 때 되묻는 왕복이 사라진다.

| 이슈 섹션 | Goal Prompt 칸 |
| --- | --- |
| 목적 / 문제 / 확인할 질문 | `## Objective` |
| 작업 내용 / 조사 범위 | `## Slices` 또는 Step 목록 |
| 재현 방법 | `## Context` — 재현 테스트의 입력. 슬라이스가 아니다(Karpathy 4원칙: "버그 수정 → 재현 테스트를 쓰고 통과시킨다") |
| 완료 조건 | `## Success Criteria` |
| 범위 밖 | `## Out of Scope` |
| 참고 | `## Context` 의 지침·근거 링크 |

세 가지만 지키면 된다.

1. **완료 조건은 그대로 Success Criteria 가 된다.** 사람 없이 판정 가능한 것만 남긴다 — 제품 조작·명령과 그 관측 결과(엔드포인트 응답, 화면 상태, CLI 출력), 파일 존재, 수치. 테스트·타입체크·린트 명령은 쓰지 않는다 — `pnpm test` 가 green 인 것은 검증 수단이지 성공의 정의가 아니고, 그 명령은 아래 절대로 `goal-prompt` 가 실측한다. 주관 판정이나 외부 승인이 필요한 항목은 완료 조건이 아니라 `## 범위 밖` 또는 `## 참고` 로 옮긴다.
2. **대상을 실제 식별자로 최소 한 번 적는다** — 화면 이름, 엔드포인트, CLI 명령, 컴포넌트, 테이블 이름. `goal-prompt` 는 이 이름을 앵커 삼아 레포에서 seam 과 영향 반경을 찾는다. "관련 API" 같은 대명사만 있으면 그 탐색이 실패해 사용자에게 되묻는다.
3. **경계가 자명하지 않으면 `## 범위 밖` 을 비우지 않는다.** 이 칸이 비면 `goal-prompt` 는 범위 경계를 `[HUMAN]` 갭으로 올려 사용자에게 묻는다. 한 줄이라도 적어두면 그 질문이 사라진다.

### 여기에 적지 않는 것 (`goal-prompt` 가 직접 실측한다)

영향 반경 파일 목록, 테스트·타입체크 명령, 브랜치 이름, base SHA, 사용할 스킬 이름 — 전부 `goal-prompt` Step 1 이 레포를 읽어 채운다. 이슈에 복제하면 레포가 바뀔 때마다 조용히 썩고, 착수 에이전트는 낡은 쪽을 사실로 믿는다. 이슈에는 **사람만 답할 수 있는 것**(왜 필요한가, 어디까지가 범위인가, 무엇이 성공인가)만 담는다.

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
