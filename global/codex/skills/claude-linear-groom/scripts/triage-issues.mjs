#!/usr/bin/env node
// Deterministic groom triage for Linear issues (vendor-neutral).
// Pure functions only — the MCP fetch (list_issues / get_issue) happens in the
// SKILL main loop; scripts cannot call MCP. This module takes the fetched issue
// array and classifies each open issue into one of three buckets so the groom
// plan is consistent and cheap across invocations (no re-deriving the heuristic
// by hand every run). Mirrors the harness intake's OPEN/order conventions.

// Linear statusTypes that are still actionable. Done/Canceled are excluded —
// grooming a closed issue is wasted write (and risks resurrecting dead work).
const OPEN = new Set(['backlog', 'unstarted', 'started', 'triage']);

export function isOpen(issue) {
  return OPEN.has(String(issue?.statusType ?? '').toLowerCase());
}

// Strip the parts of a description that carry no readable spec text, so we can
// measure how much actual prose an issue has. Screenshots and embeds are signal
// to a human but give the model nothing to group/plan on — an issue that is ONLY
// an image is "thin" even though its raw string is long.
export function proseLength(description) {
  const raw = String(description ?? '');
  // A truncation marker means list_issues clipped a LONG body — definitely not thin.
  if (/\(truncated, use `?get_issue/i.test(raw)) return Infinity;
  const stripped = raw
    .replace(/!\[[^\]]*\]\([^)]*\)/g, '')          // markdown images
    .replace(/<linear-embed[\s\S]*?<\/linear-embed>/g, '') // video/file embeds
    .replace(/<linear-embed[^>]*\/?>/g, '')
    .replace(/https?:\/\/\S+/g, '')                // bare URLs (signed asset links)
    .replace(/[#>*_`~\-|\s]+/g, ' ')               // markdown punctuation + whitespace
    .trim();
  return stripped.length;
}

// How badly an issue needs enrichment, as a tier the proposal table can sort on:
//   'empty'   — no readable spec at all (blank, or only a screenshot/embed). A
//               builder cannot start without re-interviewing. Always worth fixing.
//   'shallow' — some prose but no section structure (no "##") and still short —
//               a one-liner or intake paragraph. Worth deepening, but optional;
//               surface it so the human can opt in rather than forcing churn.
//   null      — already has headings + body (ADT-31 quality). Leave it alone
//               (surgical-changes principle — don't rewrite healthy issues).
// Two tiers exist because "image-only" and "decent paragraph" are different asks:
// the user may want only the empties fixed, or a full deep-pass over both.
export function enrichTier(issue) {
  const raw = String(issue?.description ?? '');
  if (/\(truncated, use `?get_issue/i.test(raw)) return null; // long body, skip
  const prose = proseLength(raw);
  const hasStructure = /(^|\n)\s*#{1,3}\s+\S/.test(raw);
  if (prose < 80) return 'empty';
  if (!hasStructure && prose < 200) return 'shallow';
  return null;
}

export function needsEnrichment(issue) {
  return enrichTier(issue) !== null;
}

// An issue needs grouping when it is not attached to any project.
export function needsGrouping(issue) {
  return !issue?.project && !issue?.projectId;
}

// Classify the full open backlog into groom buckets. An issue can land in BOTH
// gaps (e.g. ADT-5: no project AND screenshot-only). `healthy` issues are
// reported so the user sees they were considered and deliberately left alone.
export function triage(issues) {
  const open = (issues ?? []).filter(isOpen);
  const result = { groupingGaps: [], enrichmentGaps: [], healthy: [], skippedClosed: [] };
  for (const i of issues ?? []) {
    if (!isOpen(i)) {
      result.skippedClosed.push({ id: i?.id, title: i?.title, status: i?.status });
      continue;
    }
  }
  for (const i of open) {
    const prose = proseLength(i?.description);
    const tier = enrichTier(i);
    const row = {
      id: i?.id,
      title: i?.title,
      project: i?.project ?? null,
      proseLength: Number.isFinite(prose) ? prose : null, // null = long body, not measured
      needsGrouping: needsGrouping(i),
      enrichTier: tier,                                    // 'empty' | 'shallow' | null
    };
    if (row.needsGrouping) result.groupingGaps.push(row);
    if (tier) result.enrichmentGaps.push(row);
    if (!row.needsGrouping && !tier) result.healthy.push(row);
  }
  return result;
}

// CLI: pipe a list_issues JSON (either the raw {issues:[...]} envelope or a bare
// array) on argv[2] or stdin; prints the triage buckets.
if (import.meta.url === `file://${process.argv[1]}`) {
  const read = () =>
    process.argv[2]
      ? Promise.resolve(process.argv[2])
      : new Promise((res) => {
          let s = '';
          process.stdin.on('data', (d) => (s += d));
          process.stdin.on('end', () => res(s));
        });
  read().then((raw) => {
    const parsed = JSON.parse(raw);
    const issues = Array.isArray(parsed) ? parsed : parsed.issues ?? [];
    console.log(JSON.stringify(triage(issues), null, 2));
  });
}
