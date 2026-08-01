# HTML Report Template

Use this reference when the user asks for HTML, browser-viewable output, a shareable report, or a printable report.

## Output Rules

- Generate one standalone `.html` file.
- Embed all CSS in a `<style>` tag.
- Do not use JavaScript.
- Do not depend on external fonts, images, CDNs, or network assets.
- Use Korean copy by default.
- Keep the section order fixed.
- Mark missing values as `not visible`.
- Clearly separate customer-facing content from broker-only review content.
- Clearly label `live listing` and `public supplement` data.

## Fixed Section Order

1. Header: report title, target area/client criteria, collection time, source count.
2. Customer summary: concise recommendation narrative.
3. Recommended listing cards: top candidates only.
4. Customer briefing draft: text the broker can adapt.
5. Broker review table: all listings and classifications.
6. Broker confirmation questions: grouped by listing.
7. Public/official market reference: supplemental data only.
8. Excluded listings: reasons and whether reconsideration is possible.
9. Source and limitation log: URLs, blocked sources, missing data, freshness note.

## Visual Direction

Use a refined editorial brief aesthetic:

- paper-like ivory background
- charcoal text
- muted sage panels
- brass accent lines and badges
- compact broker tables
- no generic blue/purple gradients
- no external images

Suggested CSS variables:

```css
:root {
  --paper: #f6f1e8;
  --ink: #24231f;
  --muted: #6f6a60;
  --sage: #dfe8dd;
  --sage-ink: #24352d;
  --brass: #a6783a;
  --line: #d8cdbb;
  --white: #fffaf1;
  --danger: #8f3d2f;
  --warn: #9b6b1f;
  --ok: #2f684e;
}
```

## HTML Skeleton

Use this structure and replace bracketed placeholders. Remove optional list items only when there is truly no data.

```html
<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>[REPORT_TITLE]</title>
  <style>
    :root {
      --paper: #f6f1e8;
      --ink: #24231f;
      --muted: #6f6a60;
      --sage: #dfe8dd;
      --sage-ink: #24352d;
      --brass: #a6783a;
      --line: #d8cdbb;
      --white: #fffaf1;
      --danger: #8f3d2f;
      --warn: #9b6b1f;
      --ok: #2f684e;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      background: var(--paper);
      color: var(--ink);
      font-family: "Apple SD Gothic Neo", "Noto Sans KR", "Malgun Gothic", sans-serif;
      line-height: 1.55;
      word-break: keep-all;
    }
    .page { max-width: 1120px; margin: 0 auto; padding: 42px 28px 64px; }
    .hero {
      border: 1px solid var(--line);
      background: linear-gradient(135deg, var(--white), #eee4d3);
      padding: 34px;
    }
    .eyebrow { color: var(--brass); font-family: Georgia, serif; font-size: 13px; letter-spacing: .08em; text-transform: uppercase; }
    h1, h2, h3 { line-height: 1.15; margin: 0; }
    h1 { font-size: clamp(30px, 4vw, 42px); max-width: 780px; margin-top: 12px; font-weight: 850; letter-spacing: 0; }
    h2 { font-size: 22px; margin-bottom: 16px; font-weight: 850; letter-spacing: 0; }
    h3 { font-size: 17px; font-weight: 850; letter-spacing: 0; overflow-wrap: anywhere; }
    .meta { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 22px; }
    .pill { border: 1px solid var(--line); padding: 7px 10px; background: rgba(255,255,255,.45); font-size: 13px; }
    section { margin-top: 28px; }
    .panel { border: 1px solid var(--line); background: rgba(255,250,241,.72); padding: 24px; }
    .summary { display: grid; grid-template-columns: 1.15fr .85fr; gap: 18px; }
    .cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 14px; align-items: stretch; }
    .card { border: 1px solid var(--line); background: var(--white); padding: 18px; min-width: 0; display: flex; flex-direction: column; gap: 10px; }
    .card p { margin: 0; }
    .status { align-self: flex-start; display: inline-block; padding: 4px 8px; font-size: 12px; line-height: 1.2; border: 1px solid currentColor; }
    .recommended { color: var(--ok); }
    .needs-confirmation { color: var(--warn); }
    .excluded { color: var(--danger); }
    .price { font-size: clamp(21px, 2vw, 25px); font-weight: 850; margin: 2px 0 0; line-height: 1.25; overflow-wrap: anywhere; }
    table { width: 100%; border-collapse: collapse; font-size: 13px; background: var(--white); }
    th, td { border-bottom: 1px solid var(--line); padding: 10px 9px; text-align: left; vertical-align: top; }
    th { color: var(--sage-ink); background: var(--sage); font-weight: 700; }
    .broker-only { border-left: 5px solid var(--brass); }
    .note { color: var(--muted); font-size: 13px; }
    .source-list { columns: 2; padding-left: 18px; }
    @media (max-width: 760px) {
      .page { padding: 22px 14px 40px; }
      h1 { font-size: 30px; }
      .summary { grid-template-columns: 1fr; }
      table { display: block; overflow-x: auto; white-space: nowrap; }
      .source-list { columns: 1; }
    }
    @media print {
      body { background: white; }
      .page { max-width: none; padding: 18mm; }
      .panel, .hero, .card { break-inside: avoid; }
    }
  </style>
</head>
<body>
  <main class="page">
    <header class="hero">
      <div class="eyebrow">Real Estate Brief</div>
      <h1>[REPORT_TITLE]</h1>
      <div class="meta">
        <span class="pill">대상: [TARGET]</span>
        <span class="pill">모드: [MODE]</span>
        <span class="pill">조사 시각: [COLLECTED_AT]</span>
        <span class="pill">출처: [SOURCE_SUMMARY]</span>
      </div>
    </header>

    <section class="summary">
      <div class="panel">
        <h2>고객용 요약</h2>
        <p>[CUSTOMER_SUMMARY]</p>
      </div>
      <div class="panel">
        <h2>중개사용 핵심 체크</h2>
        <ul>
          <li>[BROKER_CHECK_1]</li>
          <li>[BROKER_CHECK_2]</li>
          <li>[BROKER_CHECK_3]</li>
        </ul>
      </div>
    </section>

    <section>
      <h2>추천 매물</h2>
      <div class="cards">
        [RECOMMENDED_CARDS]
      </div>
    </section>

    <section class="panel">
      <h2>고객 브리핑 초안</h2>
      [CUSTOMER_BRIEFING]
    </section>

    <section class="panel broker-only">
      <h2>중개사용 전체 비교표</h2>
      [LISTING_TABLE]
    </section>

    <section class="panel broker-only">
      <h2>중개사 확인 질문</h2>
      [BROKER_QUESTIONS]
    </section>

    <section class="panel broker-only">
      <h2>공공/공식 시세 참고</h2>
      [PUBLIC_REFERENCE_TABLE]
    </section>

    <section class="panel broker-only">
      <h2>제외 매물 및 사유</h2>
      [EXCLUDED_LISTINGS]
    </section>

    <section class="panel">
      <h2>출처 및 한계</h2>
      [SOURCE_LIMITATIONS]
    </section>
  </main>
</body>
</html>
```

## Card Pattern

Use this for each recommended listing:

```html
<article class="card">
  <span class="status recommended">recommended</span>
  <h3>[LISTING_NAME]</h3>
  <div class="price">[PRICE]</div>
  <p>[AREA] · [FLOOR] · [TRANSACTION_TYPE]</p>
  <p>[CUSTOMER_REASON]</p>
  <p class="note">확인 필요: [CONFIRMATION_ITEM]</p>
</article>
```
