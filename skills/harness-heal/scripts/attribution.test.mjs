import { test } from 'node:test';
import assert from 'node:assert/strict';
import { buildWorksheet, topRow } from './attribution.mjs';

// Minimal rubric: A(mustPass A1,A2), B(B1), C(C1,C2).
const rubric = {
  categories: [
    { key: 'A', name: 'functional', weight: 48, floor: 0.9, items: [
      { id: 'A1', points: 24, mustPass: true }, { id: 'A2', points: 24, mustPass: true },
    ] },
    { key: 'B', name: 'spec', weight: 30, floor: 0.8, items: [{ id: 'B1', points: 30 }] },
    { key: 'C', name: 'quality', weight: 22, floor: 0.8, items: [
      { id: 'C1', points: 8 }, { id: 'C2', points: 14 },
    ] },
  ],
};

test('pass verdict → empty worksheet', () => {
  const ws = buildWorksheet(rubric, { pass: true });
  assert.equal(ws.rows.length, 0);
  assert.equal(topRow(ws), null);
});

test('mustPass failure → item-row with 3 canonical candidates', () => {
  const verdict = { pass: false, total: 76, threshold: 90, itemScores: { A2: 0 }, mustPassFailed: ['A2'], breachedFloors: ['A'], failedItems: ['A2'], categories: [{ key: 'A', score: 24, floorScore: 43.2 }] };
  const ws = buildWorksheet(rubric, verdict);
  const top = topRow(ws);
  assert.equal(top.grain, 'item');
  assert.equal(top.key, 'A2');
  assert.equal(top.gap, 24);
  assert.equal(top.mustPass, true);
  assert.deepEqual(top.candidates.map((c) => c.culprit), ['deep-plan', 'eval-generate', 'forge-dev']);
});

test('category floor breach (no mustPass) → category-row enumerating under-points items', () => {
  const verdict = { pass: false, total: 80, threshold: 90, itemScores: { B1: 10 }, mustPassFailed: [], breachedFloors: ['B'], failedItems: ['B1'], categories: [{ key: 'B', score: 10, floorScore: 24 }] };
  const ws = buildWorksheet(rubric, verdict);
  const cat = ws.rows.find((r) => r.grain === 'category');
  assert.ok(cat, 'category row exists');
  assert.equal(cat.key, 'B');
  assert.deepEqual(cat.underItems.map((u) => u.id), ['B1']);
  assert.equal(cat.underItems[0].gap, 20);
});

test('total-short (no mustPass, no floor) → aggregate-row', () => {
  const verdict = { pass: false, total: 86, threshold: 90, itemScores: { C2: 10 }, mustPassFailed: [], breachedFloors: [], failedItems: ['C2'], categories: [] };
  const ws = buildWorksheet(rubric, verdict);
  assert.equal(ws.rows.length, 1);
  const top = topRow(ws);
  assert.equal(top.grain, 'total');
  assert.equal(top.gap, 4);
  assert.deepEqual(top.underItems.map((u) => u.id), ['C2']);
  assert.equal(top.underItems[0].gap, 4);
});

test('leverage order: mustPass row precedes category row', () => {
  const verdict = { pass: false, total: 50, threshold: 90, itemScores: { A2: 0, B1: 10 }, mustPassFailed: ['A2'], breachedFloors: ['A', 'B'], failedItems: ['A2', 'B1'], categories: [{ key: 'A', score: 24, floorScore: 43.2 }, { key: 'B', score: 10, floorScore: 24 }] };
  const ws = buildWorksheet(rubric, verdict);
  assert.equal(topRow(ws).grain, 'item'); // mustPass first
  assert.equal(topRow(ws).key, 'A2');
});
