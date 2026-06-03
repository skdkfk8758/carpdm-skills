# Convention Guide — reshape pass 가 맞추는 baseline

이것은 `forge` 나 `renew` 구현이 green 이 된 후 Phase 3.5 convention reshape
pass (`reshape-pass.md`) 가 코드를 맞추는 **공유 baseline** 이다.
의도적으로 linter 와 글로벌 룰이 하지 **않는** 것만 다룬다:

- linter/formatter 가 이미 mechanical 스타일 (들여쓰기, 따옴표,
  세미콜론, 후행 쉼표, 줄 너비) 을 소유한다. pass 는 그것들을 재결정하지
  **않는다** — 프로젝트의 formatter 를 돌리고 그것을 신뢰한다.
- 글로벌 룰이 이미 size/dead-code 규율 (karpathy simplicity,
  YAGNI, 300줄 소스 파일 ceiling) 을 소유한다. pass 는 그것들을 재진술하지 **않는다**.

남는 것은 formatter 가 강제할 수 없는 taste-level 구조적 룰이다. 그것들이
아래에, 네 축으로 있다.

## Precedence (머지 순서)

pass 는 세 소스를 머지한다, **가장 구체적인 것이 이긴다**:

1. **Project lint/formatter + `rules/`** — eslint / prettier / ruff / project
   `rules/*.md`. 그것들이 커버하는 무엇이든 최고 권위.
2. **Project `docs/guides/` 컨벤션 페이지** — 프로젝트에 하나 있으면 (예:
   `docs/guides/conventions.md`), 그 프로젝트에 대해 이 baseline 을 override 한다.
3. **이 baseline** — 위 둘 다 어떤 질문에 말하지 않을 때의 폴백.

아래 baseline 룰이 프로젝트의 linter 나 guide 와 모순되면, 프로젝트가
이기고 baseline 룰은 그 프로젝트에 대해 떨궈진다. 프로젝트 자신의 formatter 가
즉시 undo 할 방식으로 이 파일에 반해 절대 reformat 하지 말 것.

## Axis 1 — Naming

- 함수는 동사로 시작한다: `fetchUser`, `buildPlan` — `userFetch`,
  `planBuilder` 아님 (함수는 action 이다).
- Boolean (그리고 boolean 반환 함수) 은 `is` / `has` / `should`
  prefix 를 가진다: `isReady`, `hasAccess`, `shouldRetry`.
- 알 수 없는 약어 금지: `cfg` 가 아니라 `config`, `req` 가 아니라 `request`
  (루프 인덱스 `i`/`j` 와 관용적 로컬 `e`/`err` 은 괜찮다).
- 이름은 타입이 아니라 도메인 의미를 기술한다 (`userArray` 가 아니라 `users`).

## Axis 2 — Function / file structure

- nested `if` 보다 **guard-clause / early-return**. 예외 케이스를 처리하고
  return; happy path 를 top indentation 레벨에 유지한다.
- 한 함수, 한 책임. 그것이 하는 일을 기술하는 데 "and" 를 써야 한다면,
  두 함수다.
- Public-before-private export 순서: 파일의 exported surface 가 helper 보다
  top-down 으로 읽힌다.
- 무관한 관심사를 섞은 파일은 관심사 경계를 따라 쪼갠다 — 단
  줄 수만으로가 아니라 진짜 두 번째 관심사가 있을 때만 (size 는 글로벌 룰의
  일이다).

## Axis 3 — Import / dependency organization

- Import 그룹을 빈 줄로 분리, 순서로: **external → internal
  (absolute) → relative**.
- layer 방향을 존중: 하위 layer 는 상위에서 import 하면 안 된다
  (예: domain 은 UI 에서 import 하면 안 된다). 역 import 은 구조적 smell 이다 —
  플래그하라; 그것을 바꾸는 방식으로 behavior 를 옮겨 "고치지" 말 것 (그건
  reshape 가 아니라 `renew` 다).

## Axis 4 — Error handling

- 에러 메시지는 라이브러리 자신의 어휘로 **무엇이 왜 실패했는지** 진술한다:
  `"parseConfig: missing required key 'port'"`, `"error"` 나 `"invalid"` 아님.
- 빈 `catch` 금지. 처리하거나, context 와 함께 rethrow 하거나, propagate 하게 두라 —
  에러를 조용히 삼키는 것은 절대 컨벤션이 아니다.
- 이 경로에서 실제로 발생할 수 있는 에러만 처리하라 (karpathy
  simplicity 에 맞춤 — 불가능한 상태에 defensive 처리 없음).
- 모듈당 하나의 에러 모델을 유지: 모듈 내 같은 종류의 실패에 대해
  `throw` 와 result-type 반환을 섞지 말 것. 두 번째 스타일을 도입하기보다
  주변 모듈이 이미 하는 무엇이든 맞춰라.
