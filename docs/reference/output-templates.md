# Output Templates — 문서형 스킬 산출물 카탈로그 (reference)

> 이 파일은 **인덱스**다 — 문서를 산출하는 스킬들의 출력 형태를 한눈에 모은다.
> 각 템플릿의 **본 SSOT 는 해당 스킬/엔진 파일**이며, 여기서 복제하지 않는다
> (project.md R1 — 동일 정보 두 곳이면 SSOT 가 깨진다). 골격을 바꾸려면 아래
> "SSOT" 열이 가리키는 파일을 바꿔라 — 이 카탈로그가 아니라.

## 왜 이 파일이 있나

스킬마다 산출 형태가 흩어져 있어 "이 스킬은 무엇을 어떤 모양으로 내놓나"를 한 번에
보기 어려웠다. 이 카탈로그가 그 진입점이다. **출력을 강제 정형화하지 않는다** —
골격을 제공하고 왜 각 섹션이 필요한지 설명할 뿐, 매 산출에 `MUST` 를 씌우지 않는다
(skill-creator 가이드: 경직된 ALWAYS/MUST 는 yellow flag).

## 적용 범위 — 문서형 산출만

| 산출 유형 | 정형화 | 이유 |
|---|---|---|
| 문서(`.md`) — plan / spec / goal / adr | **대상** | 재사용·리뷰되는 영속/시점 기록 |
| 코드 — imprint(React+Tailwind+HTML) | 제외 | token-traceability 가 이미 출력을 제약 |
| 액션 — sweep / land | 제외 | 파일을 산출하지 않음 (정리·머지 *행위*) |
| 세션 덤프 — handoff | 자체 포맷 유지 | 인계 전용 구조가 이미 SSOT |

## 공통 frontmatter (권고 — 강제 아님)

문서형 산출물 상단에 두면 출처·시점·상태를 일관되게 추적할 수 있다. 가치 있을 때만
달고, 일상적 메모에 제조하지 말 것.

```yaml
---
skill: <forge|hunt|renew|deep-plan|deep-interview>   # 어느 스킬이 만들었나
created: YYYY-MM-DD          # 작성일 (시점 기록 추적)
status: draft|approved|done  # 진행 상태 (해당될 때만)
---
```

## 종류별 템플릿 — SSOT 포인터

| 산출물 | 만드는 스킬 | 본문 골격 SSOT |
|---|---|---|
| **PLAN** (`docs/plans/YYYY-MM-DD-<topic>.md`) | deep-plan, forge/hunt/renew(Phase 1) | [`skills/craft-core/references/pipeline.md`](../../skills/craft-core/references/pipeline.md) Phase 1 — `Goal / Scope / Files / Steps / Risks / Security surface / YAGNI / Acceptance` |
| **HTML companion** (`docs/plans/….html`) | deep-plan, craft Phase 1 | 같은 pipeline.md Phase 1 — UI plan 이면 UI 목업, 비UI 면 plan 렌더 ([[craft-html-companion-ui-mockup]] 규칙 공유) |
| **SPEC** (번호 매긴 요구사항) | deep-interview | [`skills/deep-interview`](../../skills/deep-interview) — `REQ-F`/`REQ-N` + 요구사항별 acceptance |
| **Goal Prompt** (`docs/plans/….-prompt.md`) | deep-plan (Step 1) | [`skills/deep-plan`](../../skills/deep-plan) Step 1 — 고정 7-섹션: Objective / Success Criteria / Context / Constraints / Verification / Out of Scope / Done & Report |
| **ADR** (`docs/adr/NNN-slug.md`) | craft Phase 5 (ADR 감일 때) | [`skills/craft-core/references/context-adr.md`](../../skills/craft-core/references/context-adr.md) + `~/.claude/rules/knowledge-folders.md` |

## 폴더 컨벤션

출력 *경로* 는 `~/.claude/rules/knowledge-folders.md` 의 `docs/` sub-tree 규약을
따른다 — knowledge(`adr/concepts/guides/reference`) vs artifact(`plans/specs/…`).
이 카탈로그는 *형태*, knowledge-folders 는 *위치* 를 정의한다.
