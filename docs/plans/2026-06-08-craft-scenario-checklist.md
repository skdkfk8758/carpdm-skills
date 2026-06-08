# craft-core 검증 재편 — 자동 TDD floor + 플랜 파생 사람 체크리스트

> Plan from deep-plan on 2026-06-08. Source spec: `docs/specs/craft-scenario-checklist.md` (ambiguity 20%, brownfield).
> 빌드 아님 — 이 문서는 PLAN 이다. 구현은 별도 빌드 스킬(`/renew`)이 한다.

## 0. 사전 정직성 — 기존 구현과의 겹침 (반드시 먼저 읽기)

ground 결과, spec 이 제안한 것의 **상당 부분이 이미 존재한다**:

- `docs/plans/2026-06-03-craft-acceptance-gate.md` 가 이미 랜딩됨 → `pipeline.md` Phase 1
  Acceptance 는 "번호 매긴 단일 검증가능 조건", Phase 4 는 "각 항목 통과/미통과 대조"를
  **이미 명시**한다.
- 그 plan 의 codex 적대리뷰가 **"유저확인 후 재진입" 제어 흐름을 과설계로 차단(B6)** 했고,
  변경 가치를 "집행력(gate)이 아니라 plan 품질"로 재정의했다.

따라서 이 plan 은 spec 전체를 곧이곧대로 구현하지 않고 **진짜 delta 에만** 범위를
좁힌다. 겹치는 부분(번호 매긴 Acceptance, Phase 4 대조)은 재구현하지 않는다.

## 1. Goal (testable success criteria)

기존 Acceptance gate 위에 **세 가지 delta** 를 얹는다:

1. craft 플랜의 Acceptance 각 항목이 `[AUTO]` 또는 `[HUMAN]` 으로 분류된다 — 경계 규칙은
   단일 SSOT 레퍼런스에 정의.
2. `[AUTO]` 항목은 Phase 3 자동 TDD 가 커버하는 "최소 floor"(회귀+보안+결정론적 로직)임을
   명문화. `[HUMAN]` 은 자동 floor 에서 제외.
3. `[HUMAN]` 항목으로 사람이 도는 체크리스트 `.md` 를 생성하고, **기본 non-blocking**,
   **고위험만 Phase 4 에서 blocking**(기존 stakes/council 트리거 재사용).

성공 = 위 3개가 craft-core 레퍼런스 문서에 일관되게 기술되고, 기존 Acceptance/Phase 4
규율과 모순 없이 흡수되며, codex 선례(B6 과설계 차단)와 충돌하지 않는 형태로 표현됨.

## 2. Scope (IN / OUT)

**IN**
- `skills/craft-core/references/scenario-checklist.md` **(신규)** — delta 의 SSOT:
  AUTO/HUMAN 경계 규칙, 체크리스트 `.md` 포맷, 조건부 게이팅 로직.
- `skills/craft-core/references/pipeline.md` — Phase 1(Acceptance 항목에 AUTO/HUMAN 태그
  도입 + 신규 ref 링크), Phase 4(고위험 시 사람 체크리스트 blocking 게이트 한 줄), 신규
  레퍼런스 lazy-load 안내.
- `skills/craft-core/references/dynamic-tdd.md` — `[AUTO]` = 자동 테스트 floor 경계 명문화.

**OUT** (의도적 제외)
- 기존 Acceptance "번호 매긴 검증가능 조건" + Phase 4 항목 대조 — **이미 존재, 재구현 금지**.
- `orchestrated.md` — Phase 4 패널이 이미 Acceptance 대조 + designer intent 판정 수행(중복).
  prior plan 도 동일 이유로 OUT. 건드리지 않음.
- 작업유형별 진입점 차별화(spec component D) — deferred.
- 새 어휘(`[AUTO]`/`[HUMAN]` 외 ID 체계), 자동 루프, prd.json/파서 — YAGNI.
- forge/hunt/renew SKILL.md — D deferred 라 Phase 3 진입점 문구 변경 불요(엔진 ref 만 갱신).

## 3. Files (verified — path : why it changes)

- `skills/craft-core/references/scenario-checklist.md` *(신규)* : delta SSOT. 경계 규칙·체크리스트
  포맷·게이팅. 다른 phase 필요 시 lazy-load 되는 기존 ref 패턴(codex-review/security 등)과 동일.
- `skills/craft-core/references/pipeline.md` : 확인함 — Phase 1 `## Acceptance` 섹션,
  Phase 4 "Nothing ships red" + 항목 대조 문장 존재. 여기에 AUTO/HUMAN 태그 + 조건부 게이트
  링크를 얹는다.
- `skills/craft-core/references/dynamic-tdd.md` : 확인함 — red→green→refactor, opus pin, "atomic
  task" 정의 존재. `[AUTO]` floor 경계를 한 단락 추가.

## 4. Steps (each step → its verify check)

1. **신규 `scenario-checklist.md` 작성** — 섹션: (a) AUTO/HUMAN 경계 규칙(spec REQ-F-003
   표준 예시 포함), (b) 체크리스트 `.md` 포맷(항목별 태그 + `[HUMAN]` pass/fail 칸), (c) 조건부
   게이팅(기본 non-blocking, 고위험=기존 stakes 트리거 시 Phase 4 blocking), (d) 동어반복 회피
   주의(source=플랜, 구현체 아님).
   → verify: 파일이 4개 섹션을 담고, 경계 규칙이 spec REQ-F-003 4예시와 일치, 보안 불변식 항상
   AUTO(REQ-N-002) 명시.
2. **pipeline.md Phase 1 갱신** — Acceptance 섹션에 "각 항목을 `[AUTO]`/`[HUMAN]` 으로
   분류(scenario-checklist.md 참조)" 한 줄 + 레퍼런스 lazy-load 목록에 신규 파일 추가.
   → verify: Phase 1 이 태깅을 명시하고 신규 ref 를 가리킴. 기존 "번호 매긴 조건" 문구는 보존
   (재작성 아님 — surgical).
3. **pipeline.md Phase 4 갱신** — 고위험 작업에서 `[HUMAN]` 체크리스트 미완 시 ship 차단
   한 줄(기존 "nothing ships red" 규율에 흡수, 새 제어 흐름 신설 금지 — B6 선례 준수).
   → verify: Phase 4 가 조건부 게이트를 기존 규율 표현으로 명시, "유저확인 재진입" 같은 새 흐름
   어휘 미등장.
4. **dynamic-tdd.md 갱신** — "atomic task" 근처에 `[AUTO]` floor = 자동 테스트가 커버하는
   회귀+보안+결정론 항목, `[HUMAN]` 은 자동에서 제외 한 단락.
   → verify: floor 경계가 명문화되고 opus pin·red-green 규율과 모순 없음.
5. **정합 점검(드라이런 성격)** — 4개 문서를 통독해 AUTO/HUMAN 어휘가 일관되고, 기존 Acceptance
   gate 와 중복 서술이 없는지 확인.
   → verify: 같은 개념을 두 곳이 다르게 정의하지 않음(SSOT = scenario-checklist.md).

## 5. Risks

- **(높음) blocking 게이트가 codex 선례와 충돌.** prior acceptance-gate 의 codex 리뷰가
  "유저확인 후 재진입" 흐름을 과설계로 차단(B6)했다. REQ-F-007 의 고위험 blocking 도 같은
  판정을 받을 수 있다. 완화: 새 제어 흐름을 *신설*하지 말고 기존 "nothing ships red" + stakes
  트리거에 **흡수**하는 표현으로만 기술. /renew 의 Phase 2 codex 리뷰에서 재검증 대상.
- **(중간) delta 가 작다.** 핵심 실익은 AUTO/HUMAN 태깅 + 사람 체크리스트 산출물. 번호 매긴
  Acceptance·Phase 4 대조는 이미 있으니, 순이득은 "어느 항목이 자동/사람인지 명시 + 사람용
  체크리스트 파일". 이게 신규 레퍼런스 1개 값어치 하는지는 /renew Phase 2 에서 다툴 것.
- **(중간) non-blocking 체크리스트 skip 위험.** 기본 non-blocking 이라 사람이 안 돌면 그냥 안 됨.
  이건 spec 이 자율성(REQ-N-003) 위해 의도적으로 받아들인 트레이드오프 — 고위험만 강제로 보완.
- **(낮음) 마크다운 지시문의 집행력 한계.** 모든 craft 변경 공통 — AI 가 ref 를 읽고 따르느냐에
  의존. 신규 기능 아님, 기존과 동급.

## 6. Security surface

- 없음 — 마크다운 레퍼런스 문서만 변경. 단 **내용상** REQ-N-002(보안 불변식 항상 `[AUTO]`,
  HUMAN-only 강등 금지)를 scenario-checklist.md 에 명문화해, 보안 검증이 사람 체크리스트로
  새지 않게 한다.

## 7. YAGNI (deletions this change would make)

- 삭제 없음 — 순수 추가(신규 ref 1 + 기존 3문서 문구 보강). 기존 Acceptance gate 서술은
  보존(중복 재작성이 오히려 drift).
- 단 작성 시: spec 의 component C("플랜 검사")는 이미 A/B 로 흡수됐으니 별도 서술 만들지 말 것.

## 8. Acceptance (numbered, single, checkable conditions)

1. `scenario-checklist.md` 가 존재하고 AUTO/HUMAN 경계 규칙·체크리스트 포맷·조건부 게이팅·
   동어반복 회피 4섹션을 담는다.
2. 경계 규칙이 spec REQ-F-003 의 4개 표준 예시(`빈 비번→400`=AUTO, `bcrypt cost 12`=AUTO,
   `302→/dashboard`=AUTO, "화면 안 깨짐"=HUMAN)와 일치한다.
3. 보안 불변식은 항상 `[AUTO]`, HUMAN-only 강등 금지가 명문화된다(REQ-N-002).
4. pipeline.md Phase 1 이 AUTO/HUMAN 태깅을 명시하고 신규 ref 를 lazy-load 목록에 넣되, 기존
   "번호 매긴 검증가능 조건" 문구를 보존한다.
5. pipeline.md Phase 4 의 고위험 blocking 이 새 제어 흐름 신설 없이 기존 "nothing ships red"
   규율 표현으로 흡수된다(B6 선례 준수).
6. dynamic-tdd.md 가 `[AUTO]` floor 경계를 명문화하고 기존 opus pin·red-green 규율과 모순되지
   않는다.
7. 4개 문서 통독 시 AUTO/HUMAN 정의가 한 곳(scenario-checklist.md)에만 있고 나머지는 참조만 한다.

## 9. 다음 단계 (제안 — deep-plan 은 여기서 멈춤)

이 plan 은 brownfield 변경(craft-core 동작 재편)이라 빌드는 `/renew` 가 적합. spec + 이 plan 을
**완료된 Phase-1 산출물**로 넣어 재인터뷰 없이 곧장 codex plan review(Phase 2)로 — 특히 위
Risk(높음: B6 충돌)를 codex 가 적대적으로 다투게 하는 것이 핵심.

---

## Phase 2 — codex 적대리뷰 verdict (2026-06-08, /renew)

**VERDICT: BUILD, 단 강하게 cut. Confidence: high.** (독립 재검증으로 핵심 주장 3개 직접 대조 확인.)

살아남는 delta:
- (1) `[AUTO]`/`[HUMAN]` 태깅 — Phase 1 Acceptance 항목 메타데이터로 inline.
- (2) 최소 TDD floor 경계 — pipeline.md + dynamic-tdd.md 에 narrow 하게.

잘라낸 것 (blocking):
- **B1** REQ-F-007(고위험 blocking 게이트) = B6 과설계 재현(유저확인 흐름 리네임). **삭제.** 미충족
  `[HUMAN]` 은 pipeline blocker 가 아니라 잔여 리스크로 보고.
- **B2** 체크리스트 산출물 = Acceptance+Phase4 와 중복, drift 유발. **삭제.** 대신 Phase 4/5 wrap 에서
  `[HUMAN]` 항목을 `pass/fail/not-run` 으로 보고.
- **B3** 신규 `scenario-checklist.md` 정당화 안 됨(lazy-load 라 안 읽힐 위험). **삭제.** 규칙은
  pipeline.md Phase 1(3~6줄) + dynamic-tdd.md(한 단락)에 직접 inline.
- **B4** "최소 TDD floor"를 새 메커니즘으로 과장 금지. narrow 표현: `[AUTO]`=자동테스트 의무,
  `[HUMAN]`=Phase 3 테스트 의무 제외하되 검증 보고에 노출.

non-blocking 채택:
- 태그를 Acceptance 항목에 직접: `1. [AUTO] 빈 비번 → 400`.
- `[AUTO]`=결정론·회귀민감·보안·계약 수준 / `[HUMAN]`=시각판단·UX의도·카피톤·주관적 사용성·자동화비용>>가치.
- 보안 불변식: auth/payment/crypto/permission 경계는 `[HUMAN]`-only 금지.
- 구현은 **2파일만**: pipeline.md + dynamic-tdd.md. 산출물·게이트·신규 ref 전부 없음.

**revised scope (Phase 2 후):** 신규 파일 없음. 2파일 inline 편집. 사람 체크리스트 산출물·blocking
게이트 제거. spec REQ-F-005/006/007 은 descope(사용자 확인 필요 — 원 아이디어 핵심이었음).
