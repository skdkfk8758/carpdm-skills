# Source Ladder

Use this reference when Naver Real Estate does not load or does not expose enough visible listing data.

## Principle

Separate sources into two groups:

- `live listing source`: pages that show current listing candidates.
- `public supplement`: official or public market data used only for context, not as live listings.

Never merge these groups without labeling the source type.

## Listing Source Order

1. Naver Real Estate visible UI.
   - Try desktop first when available.
   - Try `https://m.land.naver.com/` when desktop entry points fail.
2. KB Real Estate visible UI.
3. Zigbang visible UI.
4. Dabang visible UI.
5. Danggeun Real Estate visible UI.
6. Hogangnono visible UI.
7. Regional/local listing portals found from ordinary web search, such as local real estate newspapers, regional classifieds, or local broker listing sites.

Use only sources that open normally in the current browser session. If a source blocks access, asks for credentials, or shows anti-bot friction, stop that source and move to the next one.

## Public Supplement Sources

Use these only to improve briefing context and broker questions:

- MOLIT real transaction public data.
- Korea Real Estate Board statistics.
- VWorld public spatial/land datasets.
- Local government or public open-data pages when directly relevant.

Do not use public supplement data to claim that a live listing exists.

## Fallback Report Rules

When all listing sources fail:

- Produce a blocker report instead of inventing listings.
- Include attempted source URLs or source names.
- Provide broker follow-up questions and a recommended manual retry path.
- If public supplement data was available, present it in a separate section.

When fallback listing sources work:

- Label each listing with its source.
- Keep classification based on visible listing facts.
- Mention that cross-site duplicate matching is tentative unless fields strongly match.
- Prefer regional/local portals for smaller cities when national portals fail or expose only market context.
