---
name: linear-register
model: sonnet
description: >-
  Linear MCP로 실제 Linear 이슈를 한 건 또는 소수 생성한다. 모든 상태의 기존 이슈,
  프로젝트, 마일스톤, 라벨, 네이티브 관계를 확인한 뒤 중복 처리와 배치안을 먼저 보여주고
  승인 후 등록한다. "리니어에 이슈 등록", "티켓 만들어줘", "이거 이슈로 올려줘",
  "이슈로 남겨줘", "file this as a Linear issue" 같은 요청에 사용한다. 대량 plan/spec/PRD
  분해, 백로그 전체 그루밍, 생성한 이슈의 작업 실행에는 사용하지 않는다.
---

# Linear Register

사람이 읽기 쉬운 Linear 이슈를 안전하게 생성한다. 라우팅 분석, 중복 판단, 실행 방법은
이슈 본문 밖에서 처리한다.

## 경계

- 한 건 또는 소수 이슈만 처리한다. 일반적으로 최대 다섯 건이다.
- 큰 plan, spec, PRD, roadmap을 백로그로 분해하지 않는다.
- 이슈가 설명하는 작업을 실행하지 않는다.
- 백로그 전체를 정리하거나 재배치하지 않는다.
- 정확한 배치안과 본문을 보여주고 승인받기 전에는 Linear에 쓰지 않는다.
- 이슈 본문에 추천 스킬, 에이전트, 워크플로, kickoff prompt, 다음 작업 prompt를 넣지 않는다.

## 필수 리소스

- Linear를 조회하기 전에 [references/context-and-placement.md](references/context-and-placement.md)를 전부 읽는다.
- 본문을 작성하기 전에 [references/human-issue-writing.md](references/human-issue-writing.md)를 전부 읽는다.
- 미리보기 전에 모든 본문을 `scripts/validate_issue_body.py`로 검증한다.

## 워크플로

### 1. 요청 규모 확인

예정 이슈 수를 확인한다. 입력이 큰 작업 분해를 의미하면 즉시 필요한 한 건에서 다섯 건을
선택하도록 요청한다. plan 전체를 조용히 다수 이슈로 만들지 않는다.

사람만 결정할 수 있는 정보만 질문한다. Linear에서 확인할 수 있는 사실은 도구로 조사한다.

### 2. Linear 배치 맥락 해소

사용 가능한 `mcp__linear__*` 도구를 런타임에서 확인하고, 존재하지 않는 도구명을 추측하지 않는다.

다음 순서로 확정한다.

1. Team
2. Existing project
3. Existing milestone
4. Existing labels
5. State. 사용할 수 있으면 `Backlog`가 기본이다.

사용자의 명시적 선택을 우선한다. 그렇지 않으면 현재 대화와 Linear 근거에서 추론한다. 팀이나
서로 성격이 다른 프로젝트 후보가 여전히 모호할 때만 한 번에 하나의 짧은 질문을 한다.

정확한 팀 key 또는 이름을 알고 있으면 exact team lookup을 우선한다. team list 검색 결과가
없으면 exact team getter로 다시 조회하고, 알려진 project 또는 issue의 team 필드로 교차 검증한
뒤에만 사용자에게 질문한다.

Claude의 repo map은 존재하고 현재 저장소와 일치할 때 보조 근거로 사용할 수 있다. repo map과
Linear의 실제 team/project 정보가 충돌하면 Linear 근거를 우선하고 충돌을 사용자에게 알린다.

### 3. 초안 작성 전 기존 작업 확인

`references/context-and-placement.md`의 전체 상태 조회 절차를 따른다.

최소한 다음을 수행한다.

- 관련 project와 milestone을 조회한다.
- team의 label과 status를 조회한다.
- `includeArchived: true`로 관련 issue를 모두 조회하고 pagination을 끝까지 진행한다.
- backlog, active, review, completed, canceled, archived 상태를 포함한다.
- 예정 이슈마다 집중 semantic search를 수행한다.
- 강한 후보의 전체 상세와 native relation을 조회한다.
- 완료·취소 이유가 중요하면 comment까지 확인한다.

먼저 compact project/issue field를 사용한다. 넓은 요청이 Linear complexity limit을 넘으면 field를
줄이고, 후보 project, milestone, issue만 상세 조회한다. 이는 조회 fallback이며 전체 상태 compact
scan을 생략할 수 있는 근거가 아니다.

Pagination이나 조회가 끝나지 않았다면 전체 상태 또는 전체 project를 확인했다고 말하지 않는다.

### 4. 중복과 배치 분류

강한 후보를 다음 중 하나로 분류한다.

- 진행 중인 정확한 중복
- 유사 중복 또는 범위 확장
- 관련 선행 작업 또는 후속 작업
- 요청이 이미 해결됐거나 재발·후속일 수 있는 완료 작업
- 새 작업의 접근법을 제한하는 취소 작업

사용자 승인을 받을 제안은 다음 중 하나다.

- 신규 생성
- 신규 생성 후 관계 연결
- 기존 이슈를 최소 범위로 수정
- 기존 작업이 이미 포함하므로 생성 생략

자동으로 선택하지 않는다. 제목이 비슷하다는 이유만으로 완료·취소 이슈를 되살리거나 다시 열지
않는다.

정확히 맞는 기존 project, milestone, label을 우선한다. 기존 구조가 맞지 않을 때만 새로운 구조를
제안하고, 각각을 승인이 필요한 별도 write로 취급한다.

### 5. 사람을 위한 본문 작성

`references/human-issue-writing.md`에서 가장 작은 템플릿을 고른다.

- Feature or improvement
- Bug
- Research or decision

제목은 결과 중심으로 모호하지 않게 쓴다. 작업 목록보다 이슈가 필요한 이유를 먼저 설명한다.
완료 조건은 일반 checkbox를 사용한다.

Team, project, milestone, label, state, parent, blocker, related issue는 본문에 반복하지 않는다.
Linear metadata와 native relation에 저장한다.

다음 내용은 넣지 않는다.

- `## 추천`
- `## 다음 작업`
- `[AUTO]` 또는 `[HUMAN]`
- Skill, agent, workflow 이름
- Product requirement가 아닌 구현 방법 지시
- Kickoff 또는 복사·붙여넣기용 prompt
- Workspace policy가 명시적으로 요구하지 않은 AI boilerplate

### 6. 모든 본문 검증

각 초안을 임시 파일에 저장하고 실행한다.

```bash
python3 ~/.claude/skills/linear-register/scripts/validate_issue_body.py --kind feature /path/to/body.md
```

유형에 따라 `--kind bug` 또는 `--kind research`를 사용한다. 오류를 모두 수정한 뒤 미리보기를
제시한다.

### 7. 승인 미리보기

Linear write 전에 이슈별로 다음을 보여준다.

- Title
- Proposed action
- Team, project, milestone, state, existing labels
- Native relation plan
- 강한 중복·관련 후보와 status, 한 줄 근거
- 판단에 영향을 준 completed/canceled context
- Fenced Markdown block 안의 정확한 전체 본문

새 project, milestone, label 생성 제안도 모두 명시한다.

배치, action, relation, 정확한 본문을 포괄하는 승인을 요청하고 대기한다. "바로 등록" 같은
표현에도 승인 단계를 생략하지 않는다.

기존 이슈 수정안은 최소 patch와 수정 후 전체 본문을 보여준다. 유용한 이력을 보존하고 작은
수정으로 충분하면 description 전체를 교체하지 않는다.

### 8. 의존 순서로 쓰기

승인 후 다음 순서로 실행한다.

1. 승인된 새 project 또는 milestone 생성
2. Blocked issue보다 blocker를 먼저 생성
3. `mcp__linear__save_issue`로 issue 생성 또는 수정
4. `project`, `milestone`, `labels`, `state`와 승인된 `blockedBy`, `blocks`, `relatedTo`,
   `parentId` 관계 설정
5. Label 생성이 명시적으로 승인되지 않았다면 실제 존재가 확인된 label만 사용

부분 실패가 발생하면 중지한다. 성공한 write와 실패한 operation을 보고한다. 중복이 생길 수
있으므로 create를 무작정 재시도하지 않는다.

### 9. 쓰기 결과 검증

생성·수정한 모든 issue와 relation을 다시 조회해 검증한다.

- Identifier와 URL 존재
- Team, project, milestone, state, label이 승인안과 일치
- Native relation 방향이 정확
- 본문에 금지된 추천 또는 workflow section이 없음
- 미해결 placeholder가 없음

결과를 milestone 또는 project별로 묶어 보고한다. 검증하지 못한 부분은 명시한다.

## 안전 불변식

- Read는 승인 없이 수행할 수 있지만 write는 승인 후에만 수행한다.
- 사용자가 정확한 action을 승인하지 않으면 기존 issue를 delete, archive, cancel, reopen, close하지 않는다.
- 배치를 개선하면서 관련 없는 issue를 수정하지 않는다.
- Completed 또는 canceled status만으로 중복이라고 단정하지 않는다.
- Scan limit, pagination failure, connector error를 숨기지 않는다.
