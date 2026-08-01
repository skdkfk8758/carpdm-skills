# Classification Rules

Use these rules after collecting visible listing data.

## Criteria Order

Apply criteria in this order:

1. Hard requirements: location, transaction type, budget, size, move-in timing, and explicit exclusions.
2. Important preferences: floor, direction, maintenance fee, parking, building age, nearby amenities, and customer-specific preferences.
3. Visible risks: missing price details, unclear area, restricted move-in timing, suspicious inconsistency, possible duplicate, or outdated listing signal.
4. Briefing value: whether the listing can be explained clearly to the customer.

## Statuses

### `recommended`

Use when:

- The listing meets all visible hard requirements.
- No visible blocker appears.
- Enough information exists to draft a useful customer briefing.

### `needs confirmation`

Use when:

- The listing looks promising but has missing or ambiguous data.
- The listing may be a duplicate but cannot be confidently grouped.
- A key field must be verified by a broker before customer recommendation.
- The listing slightly misses a preference but may still be worth discussing.

### `excluded`

Use when:

- The listing violates a hard requirement.
- A visible blocker makes it unsuitable.
- The listing lacks enough information to be useful and does not appear promising.

## Duplicate Handling

Group listings only when visible fields strongly match, such as:

- same complex/building
- same transaction type
- same or near-identical price
- same area
- same floor or highly similar description

When uncertain, mark `possible duplicate` and add a broker confirmation question.

## Avoid Overclaiming

- Do not say a listing is safe, verified, below market, or legally clean without external evidence.
- Do not infer unshown details from similar listings.
- Do not treat customer briefing drafts as final messages.
- Use "appears", "visible information suggests", or "needs broker confirmation" when evidence is incomplete.
