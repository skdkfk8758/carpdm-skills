---
name: eval-check
description: 확정(frozen)된 eval rubric 으로 작업 산출물을 채점해 pass/fail 판정과 점수 리포트·실패 시그니처를 낸다. rubric 을 생성하지 않는다 — 생성은 별도 eval-generate 스킬의 일이다(checker≠generator 분리). 진범 스킬 귀속도 하지 않는다 — 그건 C4 외부 루프의 일. 구현이 끝나 rubric 기준으로 채점·평가·점수화해야 할 때, eval 을 돌려 임계점(90) 통과 여부를 판정할 때, "eval 돌려줘"/"채점해줘"/"rubric 으로 검사" 류 요청에 사용. rubric 을 만들거나 코드를 구현/수정하는 작업에는 쓰지 말 것.
---

# eval-check

루프엔지니어링 하니스의 **eval-checker 역할**. 구현(③) 후 frozen rubric 으로 채점(④)한다.
계약 SSOT: [`docs/reference/eval-rubric-schema.md`](../../../docs/reference/eval-rubric-schema.md).
요구사항: `docs/specs/loop-engineering-harness/spec.md` REQ-F-005/006/007/010/011, REQ-N-001/002.

## 절대 규칙 (분리 무결성)

- **rubric 을 만들지 않는다.** 채점만 한다 — rubric 생성은 eval-generate(REQ-F-007).
- **frozen rubric 만 채점한다.** `frozen:true` 아니면 거부(REQ-F-008). G1 미승인 rubric 채점 금지.
- **진범 귀속 안 한다.** "플랜/rubric/dev 중 누가 잘못"은 C4 의 일. 여기선 verdict + 실패 시그니처(evidence)까지.
- **코드를 안 짠 fresh-context 에서 돈다** — developer 와 동일 agent 가 채점하면 분리 위반(REQ-N-001).

## Quick start

입력: frozen `<worktree>/.eval/rubric.json` + dev 산출물(워크트리 코드).
출력: `<worktree>/.eval/verdict.json` (pass/fail · 점수 · 시그니처).

## Workflow

1. **frozen 확인** — `rubric.json` 의 `frozen:true` 아니면 즉시 중단(채점 거부).
2. **결정론 항목 실행** — `method` 가 `test`/`tsc`/`lint` 인 항목: 테스트/lint/tsc 를 실제 실행해 항목별 pass/fail 수집. 큰 출력은 `.eval/run.log` 로 빼고 필요한 줄만 Read(룰 R5).
3. **judge 항목 채점** — `method:judge` 항목(B spec부합·C2 패턴·D 시안): rubric 기준에 따라 0..points 점수 + 근거를 부여. 시안 항목은 렌더 결과 vs `<topic>.html` 비교.
4. **results.json 작성** — `{ "items": { "A1": {"pass": true}, "B1": {"score": 24}, ... } }`. 결정론=`pass`, judge=`score`. 활성 항목 전부 채워야 함.
5. **채점 실행** — `node /Users/carpdm/.claude/skills/eval-check/scripts/score-rubric.mjs <worktree>/.eval/rubric.json <worktree>/.eval/results.json`. 스크립트가 3-part 규칙(mustPass 만점 + 카테고리 하한 + 총합 ≥threshold)과 시그니처를 결정론으로 계산해 `verdict.json` 산출. (글로벌 변형 — 스크립트는 cwd 무관 절대경로; rubric/results 인자는 워크트리 기준. 프로젝트 로컬 설치본은 상대경로.)
6. **보고** — verdict 의 pass/fail·총점·실패 시그니처를 오케스트레이터(C1)에 넘긴다. **fail 이면 시그니처가 단락 판정(REQ-F-009/010)의 입력** — 같은 시그니처 2연속이면 C1 이 외부 루프로 단락.

## 채점 규칙 (스크립트가 강제, 손으로 재계산 금지)

pass = 모든 `mustPass` 항목 만점 **AND** 모든 활성 카테고리 점수 ≥ `floor×weight` **AND** 총합 ≥ `threshold`. 셋 중 하나라도 어기면 fail. → `score-rubric.mjs` 가 단일 SSOT. 사람/LLM 이 총점을 눈대중하지 않는다.

## judge 규율

- **결정론으로 가능한 건 judge 로 채점하지 않는다** — rubric 이 `method:test` 로 박은 건 반드시 실행해서 pass/fail. judge 점수로 우회 금지.
- **근거 없는 점수 금지** — judge 항목마다 왜 그 점수인지 한 줄. 만점 아니면 무엇이 빠졌는지 명시(C4 가 읽는다).
- **rubric 밖을 채점하지 않는다** — rubric 에 없는 기준으로 감점 금지. 누락은 rubric/플랜 결함이고 그 귀속은 C4 의 일.

## 출력 보고

종료 시 `result:` 한 줄(pass/fail + 총점/threshold) + `verdict.json` 경로 + (fail 이면) 시그니처.
