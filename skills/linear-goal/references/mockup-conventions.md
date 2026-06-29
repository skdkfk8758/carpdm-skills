# 시안 규칙 — UI mockup / 비-UI 로직 약도 + 단일 review HTML

Phase 4~5 에서 읽는다. 모든 티켓이 **시각 산출물**을 가진다 — 그게 승인 게이트(D)의
"볼 것"이다. 텍스트 Goal Prompt 만 승인하는 건 약한 게이트라 false-done 을 못 막는다.
시안은 사용자가 *무엇이 만들어질지* 합의하는 시각 계약이다.

공통 규칙 (전 시안 동형):

- **외부 asset 0** — CSS/폰트/스크립트/이미지 전부 인라인. 더블클릭하면 브라우저가
  바로 연다. CDN·import·fetch 금지.
- **픽셀 완벽 불필요** — 목적은 합의이지 최종 디자인이 아니다.
- **표상 수준** — 비-UI 시각화는 실제 introspect/측정이 아니라 *티켓이 만들 구조의
  약도*다. repo 전체 스캔 금지 (비용·부정확).

## A. UI 결과물 → mockup

페이지·컴포넌트·대시보드·패널·모달·레이아웃·시각 출력일 때.

- 목표 화면의 **핵심 요소·레이아웃·상태**를 담는다. 실제 데이터 흉내(플레이스홀더
  OK), 주요 상태(빈/로딩/에러/채워짐)는 정적 섹션으로 나열.
- brownfield 면 대상 repo 의 `DESIGN.md`/디자인 시스템/`index.css` `@theme` 토큰을
  가볍게 Read 해 색·간격·폰트를 맞춘다(추측 금지). 토큰 있으면 그걸 인라인 반영.
- 첨부 스크린샷이 있으면 그 레이아웃을 시각 레퍼런스로 따른다.

## B. 비-UI 결과물 → 로직/구조 약도

백엔드·데이터·인프라일 때. 티켓 성격에 맞는 한 가지(또는 조합):

- **약식 API 계약** — 엔드포인트·메서드·요청/응답 shape 를 카드/표로. 예: `POST
  /api/v1/profile/stay/aggregate` → body `{cellIds[]}` → `200 {profile}`. 실제
  구현 아님, *계약 약도*.
- **DB 스키마 약도** — 추가/변경될 테이블·컬럼·관계를 박스+선으로. 정밀 ERD 가
  필요하면 `erd` 스킬 위임을 제안(본 시안은 약도까지).
- **인프라/플로우 구조도** — 컴포넌트 박스 + 화살표(데이터/요청 흐름). 예:
  `Browser → route handler → @api repository → Postgres`.

종류 선택 휴리스틱: `area:*` 라벨·티켓 본문 키워드로 고른다 (엔드포인트 언급 →
API 계약, 테이블/마이그 → 스키마, 서비스/배선 → 구조도). 모호하면 본문이 가장
강조하는 산출물 하나로.

## C. 단일 review HTML 합치기 (Phase 5)

시안(A 또는 B)과 Goal Prompt **전문**을 하나의 self-contained HTML 로 합친다 —
`<slug>-review.html`. 사용자는 이 한 파일만 열어 둘 다 본다.

레이아웃:

```
┌─────────────────────────────────────────┐
│  [티켓 ID · 제목]   라우팅: repo / goal   │  ← 헤더
├─────────────────────────────────────────┤
│  ▼ 시안 (UI mockup 또는 로직 약도)        │  ← 상단: 시각 계약
│     ...                                   │
├─────────────────────────────────────────┤
│  ▼ Goal Prompt                            │  ← 하단: 전문 렌더
│     # Goal: ...                           │     (markdown → 가독성 있게,
│     ## Success Criteria ...               │      코드블록 monospace)
└─────────────────────────────────────────┘
```

- Goal Prompt 는 `.md` 원문을 `<pre>` 또는 간단 마크다운 스타일로 렌더 — 사용자가
  Success Criteria·Constraints 를 읽고 승인 판단을 할 수 있게.
- 헤더에 라우팅 결과(repo / worker=goal / 사유)를 박아 한눈에 보이게.
- 거부 시 피드백을 반영해 **둘 다 재생성**하고 같은 파일을 덮어쓴다(버전은 git/
  scratchpad 에 안 남겨도 됨 — 승인된 최종만 의미).

## D. 제시 (Phase 5)

- review HTML 을 **`SendUserFile`** 로 사용자에게 surface 한다 — `open <path>` 텍스트
  안내보다 산출물을 직접 띄우는 게 승인 게이트의 "볼 것"에 맞는다.
- visualize MCP(`mcp__visualize__show_widget`)가 가용하면 mockup 을 챗 **인라인
  프리뷰**로 추가 렌더해 즉시성을 높인다. **단 HTML 파일은 유지** — worker 가 Goal
  Prompt Context 의 "UI 시각 타겟"으로 이 파일을 참조하므로 widget 은 프리뷰일 뿐
  파일을 대체하지 않는다.
- visualize MCP 미가용 환경이면 SendUserFile 만으로 충분하다(graceful degrade).

## Anti-patterns

- 비-UI 에 억지 UI mockup — 노이즈. 로직 약도로.
- 시안과 Goal Prompt 를 별도 2파일로 — 사용자가 한 번에 못 본다. 단일 HTML.
- 시안의 핵심 요소를 Goal Prompt Success Criteria 에 *관찰 가능 대조 항목*으로 안
  묶기 — 그러면 시안은 장식일 뿐 worker 가 무시한다.
- 정밀 introspect 로 실제 DB/repo 전체를 떠서 시안 만들기 — 표상 약도면 충분.
