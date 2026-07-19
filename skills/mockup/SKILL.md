---
name: mockup
description: 프로젝트의 DESIGN.md·디자인 토큰·기존 화면 어휘를 추출해 실제 구현 수준에 충실한 self-contained HTML 시안(목업)을 만들고, 토큰 부분집합 기계 검증 + 실화면 대조까지 마친 뒤 Artifact 로 publish 한다. 사용자가 기존 프로젝트의 화면·페이지·컴포넌트·대시보드 시안/목업을 원할 때마다 사용한다 — "이 화면 시안 만들어줘", "목업 떠줘", "UI 미리보기 만들어줘", "이렇게 생길지 그려줘", "mockup this screen" 같은 표현이면 'mockup'·'스킬'이란 말이 없어도 트리거. deep-plan·craft-core pipeline·deep-prompt 가 UI 시안을 만들 때도 이 스킬의 references/design-context.md 가 충실도 SSOT 다. 구분: 외부 사이트에서 추출한 디자인 시스템의 재현은 imprint, 기존 어휘가 전혀 없는 신규 프로덕트의 자유 창작은 frontend-design(본 스킬이 토큰 계약을 주입해 위임 제안), 여러 안 비교는 prototype, DB 스키마 도식은 erd. 실제 프로덕션 UI 구현(forge/renew)에는 쓰지 말 것 — 시안은 정적 예고이지 제품이 아니다.
---

# Mockup — 실구현에 충실한 HTML 시안

시안의 일은 "구현 후 모습의 예고"다. 예고가 실물과 다르면 — 시안엔 없던 색, 실화면엔
없는 컴포넌트 스타일, 과장된 밀도 — 리뷰에서 합의한 것과 다른 물건이 나오고, 괴리는
구현 후에야 발견된다(실측: AUT-60, Intelligence 다수). 이 스킬은 시안을 그리기 전에
프로젝트의 디자인 실체를 **추출**하고, 그린 뒤 **기계+사람으로 검증**해 그 괴리를
사전에 차단한다.

## 절차

### 1. 대상 확정

어느 프로젝트의 어느 화면인지 확정한다. 시안 파일 경로는 호출 맥락을 따른다 —
plan companion 이면 plan 과 같은 경로·basename(`.html`), standalone 요청이면
`docs/preview/<slug>.html` 류 프로젝트 컨벤션(없으면 제안 후 확정).

### 2. Design context 추출

**`references/design-context.md` 를 읽고 그대로 따른다** — 7항목 추출(§1),
DESIGN.md 인라인/포인터형 해석(§2), 부재 시 코드 스캔 폴백 + 백필 제안(§3).
추출 결과는 context 블록으로 보고에 포함한다. 이 단계를 건너뛰고 그리기 시작하는
것이 괴리의 근원이다 — 시안 한 줄보다 추출이 먼저다.

재사용할 기존 화면 어휘가 없는 net-new UI 면 design-context.md §6 의 위임 경로를
따른다(전문 스킬 제안 + 토큰 계약 주입).

### 3. 시안 작성

self-contained HTML (inline `<style>`, 외부 asset 0, 브라우저에서 바로 열림) 로
쓴다. **design-context.md §4 의 4축 계약**(토큰 일치·어휘 재사용·밀도·기술 제약)을
지킨다. "mockup" 임을 눈에 띄게 표식해 출시 제품으로 오인되지 않게 한다. 핵심
인터랙션은 inline `<script>` 로 가볍게 시연해도 된다(과투자 금지 — 시안은 합의
도구다).

호출 맥락이 추가 요구를 갖고 오면 그것도 지킨다 — 예: pipeline/deep-plan companion
은 Eval 체크리스트 패널 동반(그 규칙의 SSOT 는 `craft-core/references/pipeline.md`
Phase 1).

### 4. 검증

design-context.md §5 대로:

- **기계**: `scripts/check-tokens.sh <mockup.html> <tokens.txt>` — 추출한 토큰
  집합으로 부분집합 체크. 위반이면 수정 후 재실행, 통과까지. 프로젝트 자체
  `design-lint` 류가 있으면 함께 실행.
- **사람**: 리뷰 요청 시 대표 실화면 참조(경로·가용하면 스크린샷)를 시안과 나란히
  제시한다.

### 5. Publish

시안을 쓴 직후 `Artifact` 도구로 publish 하고 artifact URL 을 딜리버러블로
제시한다. 로컬 파일은 유지(하니스·빌드 스킬 입력). 갱신 시 같은 경로로 재-publish.
규칙 SSOT: `~/.claude/rules/html-mockup-artifact.md`.

## Anti-patterns

- 추출 없이 그리기 시작 — 이 스킬의 존재 이유를 무효화.
- 토큰 체크 실패를 "시안이니까" 로 넘김 — 위반은 수정하거나 `non-token: <이유>` 로
  선언한다. 침묵 위반 금지.
- 포인터형 DESIGN.md 에서 포인터만 읽고 값을 추측 — 가리키는 코드를 Read 한다.
- 디자인 시스템 전체 덤프 — 추출은 시안 대상의 영향 반경에 한정.
- 시안 단독 제시 — 실화면 참조 없이 보여주면 사람 검증 축이 죽는다.
