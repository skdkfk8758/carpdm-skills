# <PROJECT-NAME> — 에이전트 지침

## 목표

<GOAL — 이 프로젝트가 무엇을 해결하는가, 한 줄>

## 스택·진입점

- 스택: <STACK>
- 진입점: <ENTRYPOINT>
- 먼저 읽을 곳: <KEY-PATHS>

## 검증 3종

| 종류 | 명령 |
|---|---|
| typecheck | `<VERIFY-CMD-1>` |
| test | `<VERIFY-CMD-2>` |
| build | `<VERIFY-CMD-3>` |

판정 명령에 `|| true`·`|| echo`·`| tail` 을 붙이지 않는다 — 종료 코드가 삼켜진다.
셋 중 없는 것은 행을 지우지 말고 `없음` 이라고 적는다.

## 브랜치

- trunk = `<TRUNK>` · 브랜치명 `<type>/<issue-id>-<topic>`
- 새 브랜치는 worktree 로 격리한다. PR base = trunk · <MERGE-RULE>.
- push·PR·머지·배포는 사용자가 대상을 명시했을 때만.

## ADR

설계 결정은 `docs/adr/NNNN-<slug>.md`. 스텝 계획은 ADR 을 목표로 삼는다.
결정 없는 작업은 ADR 없이 진행.

## 사람만 아는 규칙

- <코드·문서를 읽어도 알 수 없는 것만 여기 적는다. 없으면 이 줄을 지운다>

모델 티어·스텝 규율·응답 형식은 글로벌 `~/.claude/CLAUDE.md` 를 따른다.
