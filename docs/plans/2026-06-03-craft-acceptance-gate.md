# craft Acceptance — plan 품질 명시화 (ralph PRD 차용, 최소판)

OMC `ralph:` PRD 에서 "done 을 결정 가능한 합격기준으로 적는다"는 발상만 차용한다.
무한 자동반복은 craft 철학과 충돌하므로 제외. **Phase 2 codex 적대리뷰 결과 초안이
과설계로 판정되어, 진짜 delta 만 남긴 최소판으로 축소했다(verdict 하단).**

핵심 정직성: 이 변경의 가치는 **집행력(gate)이 아니다** — 마크다운 지시문은 기존
"Nothing ships red" 와 집행력이 동급이다. 가치는 **Phase 1 plan 품질**이다: 모호한
산문("handles errors") 대신 **번호 붙은 단일 검증가능 조건**("AC-1: empty body → 400")을
쓰게 만들고, Phase 4 가 그걸 항목별로 대조하게 한다.

## Goal (testable success criteria)

- `pipeline.md` Phase 1 plan 템플릿의 Acceptance 섹션이, 각 항목을 **번호 붙은 단일
  검증가능 조건**으로 쓰도록 규정한다. 호출 스킬의 acceptance/regression/characterization
  test 가 곧 그 항목이다 — **새 어휘(AC-N)를 강제하지 않는다**(스킬별 용어 보존).
- `pipeline.md` Phase 4 가 ship 전에 **Acceptance 각 항목을 통과/미통과로 대조**한다.
  미충족 처리는 기존 "Nothing ships red" 규율 그대로 — 새 제어 흐름·유저확인 단계
  추가 없음.

## Scope (IN / OUT)

**IN** — `craft-core/references/pipeline.md` **단 1파일, 2곳** (Phase 1 Acceptance 문구, Phase 4 대조 한 줄).

**OUT** (codex blocking 으로 전부 폐기)
- `orchestrated.md` §4 — 이미 QA 가 Acceptance 대조 + designer gap 판정 + 루프 수행(중복).
- `dynamic-tdd.md` — 이미 테스트로 done 정의(불필요).
- `README.md` / `craft-modes.md` — 변경이 작아 흐름 설명 갱신 불요.
- 4 SKILL.md — 불변(애초에 건드릴 일 없음).
- `AC-N` 강제 어휘, 새 "유저확인 후 재진입" 흐름, 보안 AC 예시, `prd.json`/파서/자동루프.
- ralph 무한 자동반복.

## Files (verified — path : why it changes)

- `craft-core/references/pipeline.md` : Phase 1 Acceptance 섹션(L91)을 "번호 붙은 검증가능
  조건" 규정으로 구체화, Phase 4(L151–155)에 "각 항목 대조" 한 줄 추가.

## Steps (each step → its verify check)

1. pipeline.md Phase 1, `## Acceptance (the checks that mean "done")` 섹션 본문에 한두 줄
   추가: "각 항목을 번호 붙은 단일 검증가능 조건으로 적는다(모호한 산문 금지). 호출
   스킬의 acceptance/regression/characterization test 가 그 항목이 된다."
   → verify: 섹션이 "번호 붙은·검증가능·스킬 test 가 곧 항목" 을 명시. 새 ID 어휘 강제 없음.
2. pipeline.md Phase 4, "Nothing ships red." 문장에 이어: "ship 전 plan 의 Acceptance 각
   항목을 통과/미통과로 대조하고, 미통과 항목은 red 와 동일하게 취급한다."
   → verify: Phase 4 가 항목별 대조를 명시, 기존 규율에 흡수(새 흐름 없음).

## Risks

- **가치가 작다** — codex 가 옳다: 집행력은 기존과 동급, 순수 cosmetic 에 가깝다. 유일한
  실익은 Phase 1 plan 작성 습관(모호 산문 억제). 이 실익이 1파일 2줄 값어치는 한다고 봄.
- **이미 충분하다는 반론** — 기존 Acceptance 섹션 + Phase 4 로 충분하다면 이 변경도 불필요.
  경계선 변경임을 인정 — 그래도 "번호 붙은 검증가능" 명문화는 작은 순이득.

## Security surface

- 없음(마크다운 1파일). 보안 AC 예시는 Phase 4 security 패스와 중복이라 넣지 않음.

## YAGNI (deletions in this change)

- 삭제 대상 없음 — Acceptance 섹션은 제목뿐이라 "대체"할 산문이 애초에 없었다(초안의
  replace 주장은 codex finding 2 로 철회). 순수 문구 보강 2곳.

## Acceptance (this plan)

1. `pipeline.md` Phase 1 Acceptance 섹션이 "번호 붙은 단일 검증가능 조건 + 스킬 test 가 곧
   항목 + 모호 산문 금지" 를 명시한다. AC-N 강제 어휘는 없다.
2. `pipeline.md` Phase 4 가 "ship 전 Acceptance 각 항목 통과/미통과 대조, 미통과=red" 를
   명시하고, 새 제어 흐름·유저확인 단계를 추가하지 않는다.
3. 그 외 파일(orchestrated/dynamic-tdd/README/SKILL.md) 무변경.

---

## Phase 2 — codex 적대리뷰 verdict

**Round 1 — BLOCKING 6 / NON-BLOCKING 2. 초안 과설계 판정.** fold 결과:

- B1 (caller 스킬 어휘 충돌) → AC-N 강제 폐기, 스킬 test = 합격항목으로 포섭. **반영.**
- B2 (replace 대상 없음) → "대체" 주장 철회, "구체화"로. **반영.**
- B3 (orchestrated §4 중복) → §4 변경 폐기. **반영(scope OUT).**
- B4 (집행력 없음) → 가치를 "gate" 아닌 "plan 품질"로 재정의, 정직히 명기. **반영.**
- B5 (5파일 과함) → pipeline.md 1파일 2곳으로 축소. **반영.**
- B6 (유저확인 흐름 모순) → 새 흐름 삭제, 기존 "nothing ships red" 흡수. **반영.**
- NB7 (보안 AC 중복) → 보안 AC 폐기. **반영.**
- NB8 (YAGNI 자가모순) → 크로스 doc/리포팅 작업 제거로 해소. **반영.**

재리뷰 생략 — codex 가 최소경로를 직접 명시했고 그대로 수렴함(2round 불요).
