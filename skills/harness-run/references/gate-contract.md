# Gate Contract — 하니스 게이트 G0~G4 (SSOT)

`harness-run` 오케스트레이터의 사람 개입 지점. **자율 구간(워크트리·dev·eval·재시도·정리)엔 게이트 없음**(REQ-F-003). `Workflow` 는 사람 입력을 못 받으므로 모든 게이트는 메인루프(스킬)가 처리한다.

| Gate | 시점 | 누가 | 무엇 | 산출/효과 | REQ |
|---|---|---|---|---|---|
| **G0** | 시작 | 사람 | 이슈 intake — 이슈 기술 수령, slug 확정 | 워크트리명 `feat/<slug>` | F-003 |
| **G1** | ② 후 | 사람 | {플랜·시안·rubric} 한 번에 검토·수정·승인 | **rubric `frozen:true` 잠금** (dev 전) | F-003·F-008 |
| **G2** | 단락 시 | 사람 | `harness-heal` — 진범 귀속 worksheet → 최고레버리지 1건 인터뷰 | 로컬 오버레이(`rules/harness-overlays/`) 개선 | F-010·F-011·F-012·F-013 |
| **G3** | pass 시 | 사람 | PR 검토 → merge 승인 | `land` 머지+워크트리 정리 | F-014 |
| **G4** | merge 후(마이그 시) | 사람 | prod 마이그 개별 `psql -f` + `information_schema` 검증 | 운영 스키마 적용 | F-016·N-006 |

## Freeze 규칙 (G1)

- `eval-generate` 가 `frozen:false` rubric 산출 → 사람이 G1 에서 검토·수정 → 승인 시 `frozen:true`.
- **dev agent 는 frozen rubric 을 열람하지 않는다** — dev 는 플랜+시안(사람 계약)만, checker 만 rubric(기계 채점). 분리 무결성 REQ-F-007/008.
- `eval-check` 의 `score-rubric.mjs` 는 `frozen:true` 아니면 채점 거부 → G1 미승인 산출물 채점 불가.

## 자율 구간 (게이트 없음)

워크트리 분기 · `deep-plan`/`eval-generate` 생성 · **dev-eval-loop**(dev 단일 agent → eval-check → `decideNext` 재시도/단락) · 워크트리 정리. 사람 프롬프트 0(REQ-F-003).

## 진범 귀속 — C4 `harness-heal` 가 수행 (REQ-F-011)

G2 의 진범 귀속은 `harness-heal`(C4)이 수행한다: `attribution.mjs(frozen rubric, verdict)` 로 grain별 worksheet(plan/eval-generate/forge-dev 3후보)를 결정론 생성하고, 최고 레버리지 1건만 사람 인터뷰로 진범 확정 → 로컬 오버레이(`rules/harness-overlays/<culprit>.md`) 개선. 글로벌 미수정. 같은 signature 2 heal-round 생존 시 에스컬레이트. (signature 자체엔 plan-vs-rubric diff 가 없으므로 worksheet 가 plan/rubric/diff 를 읽어 판정한다.)

## 결선 스킬

deep-plan(②) · eval-generate(rubric) · eval-check(④, score-rubric.mjs) · land(③⑨ 머지) · db-migrate(G4). dev 는 dev-eval-loop Workflow 의 단일 `agent()`(forge 아님).
