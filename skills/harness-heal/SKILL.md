---
name: harness-heal
description: 하니스 dev-eval 루프가 단락(short-circuit)했을 때 자가개선 — 실패 verdict 를 진범 귀속 worksheet 로 만들어, 한 번에 가장 레버리지 높은 실패 1건만 사람 인터뷰로 확정·수정하되 프로젝트 로컬 오버레이(rules/harness-overlays/)만 건드린다. harness-run 의 G2 에서 호출된다. eval 단락 원인 진단·스킬 개선이 필요할 때 사용. 글로벌 스킬 수정·일괄 자동개선에는 쓰지 말 것(REQ-F-012/013).
---

# harness-heal — 자가개선 루프 (C4)

C1 의 G2 를 실체화. dev-eval 단락 → 진범 귀속 → 로컬 오버레이 인터뷰 개선.
요구사항: `docs/specs/loop-engineering-harness/spec.md` REQ-F-010/011/012/013, REQ-N-001.
귀속 결정론: `scripts/attribution.mjs`(단위테스트). 게이트 계약: `../harness-run/references/gate-contract.md`.

## 절대 규칙

- **로컬 오버레이만** — 수정은 `rules/harness-overlays/<skill>.md`(프로젝트 로컬). 글로벌 `~/.claude/skills/` **수정 금지**(REQ-F-012). ※ 이 금지는 절차 규율이지 런타임 강제 아님 — Edit 대상은 항상 `rules/harness-overlays/` 하위.
- **한 번에 1건** — worksheet 가 N row 라도 **가장 레버리지 높은 1건만**(mustPass > floor > total) 인터뷰(REQ-F-013). 나머지는 다음 단락 때.
- **자동확정 금지** — 진범 라벨·수정은 사람 인터뷰 게이트 통과 후에만(REQ-F-013).
- **heal-round bound** — 같은 signature 가 heal 2라운드 살아남으면 "오버레이로 해결불가"로 사람에 에스컬레이트(livelock 차단).

## Workflow

1. **worksheet 생성** — `node scripts/attribution.mjs` 로직으로 `(frozen rubric, verdict)` → grain별 worksheet(item/category/total row + 각 3후보 deep-plan/eval-generate/forge-dev + 증거 check).
2. **최고 레버리지 1건 선택** — `topRow`(rows 는 mustPass>floor>total 순). 그 1 row 만 다룬다.
3. **진범 판정(판단)** — 그 row 의 3후보 `check` 를 실제로 확인: 플랜(`docs/plans/…`)·rubric(`.eval/rubric.json`)·dev diff 를 읽어
   - rubric 요구를 **플랜이 명세 안 함** → `deep-plan`
   - 플랜엔 있는데 **rubric 누락/오채점** → `eval-generate`
   - 둘 다 맞는데 **dev 반복 미달** → `forge-dev`
   판정 근거를 사람에게 제시.
4. **인터뷰(사람)** — 진범 라벨 확인 + 어떤 보강을 로컬 오버레이에 넣을지 한 가지 합의(한 번에 하나).
5. **로컬 오버레이 수정** — `rules/harness-overlays/<culprit>.md` 에 보강 규칙 append(deep-plan.md / eval-generate.md / dev.md). 글로벌 미수정.
6. **재진입** — 개선된 오버레이로 이슈가 dev-eval 루프 재진입(harness-run 이 오버레이를 주입). 같은 signature 2라운드 생존 시 에스컬레이트.
7. **loop 로그 기록** — 라운드 완료 시 **오늘 날짜 파일** `loop/log/YYYY-MM-DD.md` 에 `HEAL` 엔트리 append(없으면 H1=날짜로 생성; 포맷은 `loop/log/README.md`): "무엇"=signature, "진범"=라벨, "조치"=수정한 오버레이 경로 또는 에스컬레이트. 자동 hook 아님 — 스킬 컨벤션.

## 소비 경로 (오버레이가 실제로 먹게)

harness-run(메인루프)이 `rules/harness-overlays/dev.md`/`deep-plan.md`/`eval-generate.md` 를 읽어 각 단계 호출에 주입한다(Workflow 는 fs 불가 → args 로 전달). dev 오버레이는 `dev-eval-loop.js` 가 `args.devOverlay` 로 받아 dev 프롬프트에 prepend. 안 그러면 오버레이는 死코드.

## 진범 귀속의 한계 (정직)

귀속은 plan-vs-rubric-vs-dev 판단이라 오판 가능 — **사람 인터뷰가 최종 게이트**다. 실 자가개선 1회 실증(부실 플랜→귀속→개선→재통과)은 C5 필요라 **M2**. 본 스킬은 worksheet(결정론) + 판단/인터뷰 절차까지.

## 출력 보고

종료 시 `result:` 한 줄(다룬 1건 · 진범 라벨 · 수정한 오버레이 경로 · 에스컬레이트 여부 · `loop/log/YYYY-MM-DD.md` HEAL 엔트리 기록).
