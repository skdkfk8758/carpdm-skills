---
name: eval-generate
description: 플랜 문서 + HTML 시안 + acceptance 를 입력으로 받아, 루프엔지니어링 하니스의 eval rubric(4 카테고리 적응형 채점표 + 결정론 테스트 스텁)을 생성한다. 작업 산출물을 채점하지 않는다 — 채점은 별도 eval-check 스킬의 일이다(generator≠checker 분리). 한 작업의 플랜이 확정돼 채점 기준(rubric)을 만들어야 할 때, eval 체크리스트/채점표를 생성할 때, "rubric 만들어줘"/"eval 기준 생성"/"체크리스트 뽑아줘" 류 요청에 사용. 코드를 구현하거나 채점/검사하거나 점수를 매기는 작업에는 쓰지 말 것.
---

# eval-generate

루프엔지니어링 하니스의 **eval-generator 역할**. 플랜 시점(②)에 채점 rubric 을 만든다.
계약 SSOT: [`docs/reference/eval-rubric-schema.md`](../../../docs/reference/eval-rubric-schema.md).
요구사항: `docs/specs/loop-engineering-harness/spec.md` REQ-F-004/006/007/008/017.

## 절대 규칙 (분리 무결성)

- **채점하지 않는다.** 점수·통과/실패 판정은 eval-check 의 일이다(REQ-F-007).
- **dev 산출물을 읽지 않는다.** rubric 은 구현 *전*에 만든다 — 플랜/시안/acceptance 만 입력.
- 산출 rubric 은 G1 사람 승인 후 `frozen:true` 로 잠긴다. 이후 수정 금지(REQ-F-008).

## Quick start

입력: 플랜 `docs/plans/<topic>.md` (+ UI면 `<topic>.html` 시안) + acceptance.
출력: `<worktree>/.eval/rubric.json` + 결정론 항목용 테스트 스텁(`<worktree>/.eval/tests/`).

## Workflow

1. **taskType 판정** — `api` / `ui` / `db` / `mixed`. 시안(HTML)이 있으면 D 활성, API-only 면 D=0.
2. **플랜·시안·acceptance Read** — 계약·엣지·보안 항목·시각 요소를 추출.
3. **카테고리별 항목 도출** — schema 의 기본 가중치(taskType 표)에서 출발:
   - **A 기능**(결정론, `test`): acceptance 를 원자적 테스트 케이스로. 보안·무결성은 `mustPass:true`.
   - **B spec부합**(`judge`): 플랜 계약 vs 구현 대조 기준.
   - **C 품질**: C1 `lint`(tsc+lint 0 error, 결정론) + C2 `judge`(패턴 재사용·중복).
   - **D 시안충실도**(`judge`, UI만): 렌더 UI vs 시안 비교 기준.
4. **재분배** — 비활성 카테고리 배점을 활성에 비례 분배, 합 100 유지. 카테고리 내 points 합 = weight.
5. **DB 특례**(REQ-F-017) — `db`/마이그 포함이면 A 에 "dev 적용·rollback·information_schema=intent" 결정론 항목 추가.
6. **테스트 스텁 생성** — 결정론 항목(`test`)마다 실패/pending 테스트 스텁을 `.eval/tests/` 에 작성(checker 가 실행). 스텁은 *기대 동작*만 기술, 구현 가정 금지.
7. **검증** — `node /Users/carpdm/.claude/skills/eval-generate/scripts/validate-rubric.mjs <worktree>/.eval/rubric.json`. FAIL 이면 고쳐 재실행. (불변식: 합 100·points=weight·id 유일·api/db 는 mustPass≥1) (글로벌 변형 — 스크립트는 cwd 무관 절대경로; rubric 인자는 워크트리 기준. 프로젝트 로컬 설치본은 상대경로.)
8. **G1 핸드오프** — rubric + 스텁을 사람 승인(플랜/시안과 함께)으로 넘긴다. **freeze 는 사람이** 한다 — 이 스킬은 `frozen:false` 로 둔 채 멈춘다.

## 좋은 rubric 규칙

- **항목당 한 검증.** "and" 로 두 동작을 잇지 말고 두 항목으로 쪼갠다.
- **결정론 우선.** 테스트/lint 로 객관 채점 가능한 건 `judge` 로 빼지 않는다 — judge 는 시각·설계 판단에만.
- **must-pass 는 보안/무결성에만.** 남발하면 모든 fail 이 즉시 fail 이 돼 점수 신호가 죽는다.
- **추측 금지.** 플랜에 없는 요구를 rubric 에 넣지 않는다 — 그건 플랜 결함(귀속은 eval-check→C4 의 일).

## 출력 보고

종료 시 `result:` 한 줄 + 산출물 경로(`.eval/rubric.json`, 스텁 디렉토리) + "G1 승인/freeze 대기" 명시.
