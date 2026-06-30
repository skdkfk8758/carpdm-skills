// Attribution worksheet generator for the self-heal loop (C4).
// Input: frozen rubric.json + eval-check verdict.json. Output: grain-aware worksheet.
// Deterministic structure + numbers; the culprit JUDGMENT is the harness-heal skill's job.
// Culprit ids are canonical: 'deep-plan' | 'eval-generate' | 'forge-dev'.

function candidates(label, gap) {
  return [
    { culprit: 'deep-plan', check: `rubric 가 요구한 ${label} 를 플랜이 명세했나? 안 했으면 plan 결함.` },
    { culprit: 'eval-generate', check: `플랜엔 있는데 rubric 이 ${label} 를 누락/오채점(gap ${gap}pts)했나?` },
    { culprit: 'forge-dev', check: `플랜·rubric 정상인데 dev 산출물이 ${label} 를 반복 미달했나?` },
  ];
}

/**
 * @param {object} rubric  frozen rubric (docs/reference/eval-rubric-schema.md)
 * @param {object} verdict eval-check verdict (pass, total, threshold, itemScores, mustPassFailed, breachedFloors, failedItems, categories)
 * @returns {{rows: object[]}}  rows ordered by leverage: mustPass items → breached categories → total-short
 */
export function buildWorksheet(rubric, verdict) {
  if (verdict.pass) return { rows: [] };

  const itemIndex = {}; // id -> { category, points, mustPass }
  const catIndex = {}; // key -> { name, weight, floor, itemIds }
  for (const cat of rubric.categories) {
    catIndex[cat.key] = { name: cat.name, weight: cat.weight, floor: cat.floor, itemIds: [] };
    for (const it of cat.items) {
      itemIndex[it.id] = { category: cat.key, points: it.points, mustPass: !!it.mustPass };
      catIndex[cat.key].itemIds.push(it.id);
    }
  }
  const scores = verdict.itemScores || {};
  const mustPassFailed = verdict.mustPassFailed || [];
  const breachedFloors = verdict.breachedFloors || [];
  const rows = [];

  // 1. mustPass item-rows (highest leverage)
  for (const id of mustPassFailed) {
    const it = itemIndex[id] || { category: '?', points: 0, mustPass: true };
    const earned = scores[id] ?? 0;
    const gap = it.points - earned;
    rows.push({ grain: 'item', key: id, category: it.category, points: it.points, earned, gap, mustPass: true, candidates: candidates(`항목 ${id}`, gap) });
  }

  // 2. category-rows (breached floors) — enumerate under-points items within
  for (const key of breachedFloors) {
    const cat = catIndex[key] || { name: key, weight: 0, floor: 0, itemIds: [] };
    const catScore = (verdict.categories || []).find((c) => c.key === key) || {};
    const under = cat.itemIds
      .map((id) => ({ id, earned: scores[id] ?? 0, points: itemIndex[id].points }))
      .filter((x) => x.earned < x.points)
      .map((x) => ({ ...x, gap: x.points - x.earned }));
    const gap = (catScore.floorScore ?? cat.floor * cat.weight) - (catScore.score ?? 0);
    rows.push({ grain: 'category', key, name: cat.name, score: catScore.score, floorScore: catScore.floorScore, gap, underItems: under, candidates: candidates(`카테고리 ${key}(${cat.name})`, Math.round(gap)) });
  }

  // 3. total-short aggregate — only when no mustPass and no floor failure
  if (!mustPassFailed.length && !breachedFloors.length && verdict.total < verdict.threshold) {
    const under = (verdict.failedItems || []).map((id) => {
      const pts = itemIndex[id]?.points ?? 0;
      const earned = scores[id] ?? 0;
      return { id, earned, points: pts, gap: pts - earned };
    });
    const gap = verdict.threshold - verdict.total;
    rows.push({ grain: 'total', key: 'total', total: verdict.total, threshold: verdict.threshold, gap, underItems: under, candidates: candidates(`총점(${verdict.total}/${verdict.threshold})`, gap) });
  }

  return { rows };
}

/** The single highest-leverage row to interview on (REQ-F-013): mustPass > floor > total. */
export function topRow(worksheet) {
  return worksheet.rows[0] ?? null; // rows are already leverage-ordered
}
