# Browser Safety

Use this reference before any real estate browser automation.

## Allowed

- Navigate with normal visible UI controls.
- Use safe visible-UI fallback sources when Naver fails. Choose them with `source-ladder.md`.
- Search, filter, scroll, open listing cards, and inspect detail pages.
- Extract only visible screen text or visible DOM text.
- Use an already logged-in session only if the user logged in manually before or during the task.
- Use official/public datasets as supplemental market context when available.
- Collect a bounded number of listings that is appropriate for the user's immediate request.

## Forbidden

- Do not ask for Naver credentials.
- Do not type, store, or manage credentials.
- Do not automate login.
- Do not bypass CAPTCHA, access controls, rate limits, or abnormal-traffic warnings.
- Do not use internal APIs, hidden endpoints, browser network responses, or devtools scraping.
- Do not run unattended background monitoring, scheduled alerts, or bulk collection.
- Do not contact brokers, customers, owners, or any outside party.
- Do not create, edit, delete, or register listings.
- Do not export to Excel or Google Sheets in v1.
- Do not present public market data as if it were a live listing.

## Stop Conditions

Stop automation and report the blocker when:

- A CAPTCHA appears.
- Naver asks for credentials or account verification.
- An abnormal-traffic or access warning appears.
- Data is hidden behind a permission boundary.
- The user asks for external contact, listing writes, or internal API collection.
- The UI changes enough that fields cannot be identified with confidence.
- A fallback site blocks access, asks for credentials, or shows anti-bot friction.

## Data Handling

- Include collection date/time in the report.
- Treat collected data as current only at collection time.
- Mark unavailable fields as `not visible`; do not infer them.
- Do not preserve cookies, credentials, or account-specific private data in generated artifacts.
