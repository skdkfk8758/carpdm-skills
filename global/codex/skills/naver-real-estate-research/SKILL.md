---
name: naver-real-estate-research
description: Research Korean real estate listings for broker workflows with Naver Real Estate as the first source and compliant fallback sources when Naver is unavailable. Use when Codex needs to search by customer conditions, monitor an area or apartment complex, collect visible listing data from real estate sites, supplement with official/public market data, classify listings as recommended/needs-confirmation/excluded, draft customer briefing notes, and produce broker follow-up questions without automated login, external contact, listing writes, internal API scraping, CAPTCHA bypass, or long-running alerts.
---

# Naver Real Estate Research

Use this skill to help a real estate broker turn Korean real estate listing pages into a broker-ready research report. Start with Naver Real Estate, but use safe fallback sources when Naver does not load. Keep the workflow human-supervised and conservative: inspect only visible page data, separate live listings from public market-data supplements, draft recommendations, and leave final judgment and outreach to the broker.

## Core Boundary

Do:

- Use computer-use/browser tools to navigate Naver Real Estate and fallback real estate sites like a human user.
- Use visible screen text and visible DOM text only.
- Allow an already logged-in browser session only when the user logged in manually.
- Use official/public market data only as supplemental context, not as live listing evidence.
- Classify listings as `recommended`, `needs confirmation`, or `excluded`.
- Draft customer briefing notes and broker confirmation questions.
- Include source URLs and collection time when available.

Do not:

- Ask for, type, store, or automate Naver credentials.
- Use internal APIs, network responses, hidden endpoints, or browser devtools scraping.
- Bypass CAPTCHA, rate limits, access controls, or abnormal-traffic warnings.
- Contact brokers, customers, owners, or outside services.
- Create, edit, delete, or register listings.
- Run unattended monitoring, scheduled alerts, or bulk harvesting.
- Export to Excel or Google Sheets in v1.
- Present public market data as verified market context only when the source is official/public and cited.
- Mix public market data into the live listing table without labeling it separately.

If a blocked state appears, stop browsing and report the blocker.

## Workflow

1. Determine the mode:
   - `customer-condition`: the broker has customer criteria.
   - `area-monitoring`: the broker wants candidates from an area, neighborhood, building, or apartment complex.
2. Ask for missing hard criteria before browsing:
   - location or complex
   - transaction type
   - budget
   - size or area
   - move-in timing if relevant
   - hard exclusions
   - maximum number of listings to inspect
3. Follow the source ladder in `references/source-ladder.md`.
   - Start with Naver Real Estate.
   - If Naver fails, try safe visible-UI fallback listing sources.
   - Use public/official data only to supplement price context and verification questions.
4. Let the user handle any login manually. Never automate login.
5. Search and filter through visible UI controls.
6. Inspect a bounded set of listings.
7. Extract visible fields only. Mark unavailable fields as `not visible`.
8. Classify each listing using `references/classification-rules.md`.
9. Produce the final report using `references/report-template.md`.
10. State data freshness, missing fields, blockers, and broker-side verification needs.

## Reference Loading

- Read `references/browser-safety.md` before any browser automation or crawling-like task.
- Read `references/source-ladder.md` before choosing a source or fallback source.
- Read `references/classification-rules.md` before classifying listings.
- Read `references/report-template.md` before writing the final output.
- Read `references/html-report-template.md` when the user asks for HTML, browser-viewable output, a shareable report, or a printable report.

## Output Standard

The final response must include:

- A listing table.
- Classification for each listing.
- Customer-facing briefing draft for suitable listings.
- Broker confirmation questions.
- Source URL and collection time when available.
- A concise limitation note for missing or stale data.

When HTML is requested, generate a single static `.html` file with embedded CSS and no JavaScript. Follow `references/html-report-template.md` exactly so repeated reports use the same section order and visual structure.
