#!/usr/bin/env node
// Score dev output against a FROZEN eval rubric, apply the 3-part pass rule,
// and emit a verdict + deterministic failure signature.
// Contract SSOT: docs/reference/eval-rubric-schema.md
//
// Usage: node score-rubric.mjs <rubric.json> <results.json> [out=verdict.json]
//   results.json: { "items": { "A1": {"pass": true}, "B1": {"score": 24}, ... } }
//     - deterministic items (method test/tsc/lint): {"pass": bool}
//     - judge items (method judge):                 {"score": number 0..points}
// Exit 0 = pass, 1 = fail (verdict written), 2 = bad invocation / unfrozen.

import { readFileSync, writeFileSync } from 'node:fs';

const [rubricPath, resultsPath, outPath = deriveOut(resultsPath)] = process.argv.slice(2);
if (!rubricPath || !resultsPath) {
  console.error('usage: score-rubric.mjs <rubric.json> <results.json> [out=verdict.json]');
  process.exit(2);
}

const rubric = readJSON(rubricPath);
const results = readJSON(resultsPath);

// REQ-F-008: checker grades ONLY a frozen rubric.
if (rubric.frozen !== true) {
  console.error('FAIL  rubric is not frozen (frozen !== true) — checker refuses to grade. G1 must freeze first.');
  process.exit(2);
}

const res = results.items ?? {};
const threshold = rubric.threshold ?? 90;
const DET = new Set(['test', 'tsc', 'lint']);

const categories = [];
const mustPassFailed = [];
const breachedFloors = [];
const failedItems = [];
const itemScores = {};
let total = 0;
const missing = [];

for (const cat of rubric.categories) {
  if (cat.weight === 0) continue; // inactive
  let score = 0;
  for (const it of cat.items) {
    const r = res[it.id];
    let earned;
    if (r === undefined) {
      missing.push(it.id);
      earned = 0;
    } else if (DET.has(it.method)) {
      earned = r.pass === true ? it.points : 0;
    } else {
      earned = clamp(Number(r.score), 0, it.points);
    }
    itemScores[it.id] = earned;
    score += earned;
    if (earned < it.points) failedItems.push(it.id);
    if (it.mustPass === true && earned < it.points) mustPassFailed.push(it.id);
  }
  total += score;
  const floorScore = cat.floor * cat.weight;
  const pass = score >= floorScore;
  if (!pass) breachedFloors.push(cat.key);
  categories.push({ key: cat.key, name: cat.name, score, weight: cat.weight, floor: cat.floor, floorScore, pass });
}

if (missing.length) {
  console.error(`FAIL  results missing for active items: ${missing.join(', ')}`);
  process.exit(2);
}

const totalShort = total < threshold;
// 3-part pass rule (REQ-F-005): all must-pass full AND every active category >= floor AND total >= threshold.
const pass = mustPassFailed.length === 0 && breachedFloors.length === 0 && !totalShort;

// Deterministic failure signature for same-failure short-circuit (REQ-F-009/010).
// Structural only — stable across retries that fail the same way.
const signature = pass
  ? null
  : [
      ...mustPassFailed.map((id) => `must:${id}`).sort(),
      ...breachedFloors.map((k) => `floor:${k}`).sort(),
      ...(totalShort && !mustPassFailed.length && !breachedFloors.length ? [`total:<${threshold}`] : []),
    ].join('|');

const verdict = { pass, total, threshold, categories, itemScores, mustPassFailed, breachedFloors, failedItems, signature };
writeFileSync(outPath, JSON.stringify(verdict, null, 2) + '\n');

console.log(`${pass ? 'PASS' : 'FAIL'}  total ${total}/${threshold}` +
  (pass ? '' : `  [mustPassFailed: ${mustPassFailed.join(',') || '-'} | floors: ${breachedFloors.join(',') || '-'} | sig: ${signature}]`) +
  `  → ${outPath}`);
process.exit(pass ? 0 : 1);

function readJSON(p) {
  try { return JSON.parse(readFileSync(p, 'utf8')); }
  catch (e) { console.error(`cannot read/parse ${p}: ${e.message}`); process.exit(2); }
}
function clamp(n, lo, hi) { return Number.isFinite(n) ? Math.max(lo, Math.min(hi, n)) : 0; }
function deriveOut(p) { return p.replace(/results\.json$/, 'verdict.json').replace(/\.json$/, '.verdict.json'); }
