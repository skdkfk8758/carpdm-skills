#!/usr/bin/env node
// Validate an eval rubric against the shared contract.
// Contract SSOT: docs/reference/eval-rubric-schema.md
// Usage: node validate-rubric.mjs <path/to/rubric.json>
// Exit 0 = valid, 1 = invalid (errors printed), 2 = bad invocation.

import { readFileSync } from 'node:fs';

const path = process.argv[2];
if (!path) {
  console.error('usage: validate-rubric.mjs <rubric.json>');
  process.exit(2);
}

let rubric;
try {
  rubric = JSON.parse(readFileSync(path, 'utf8'));
} catch (e) {
  console.error(`cannot read/parse ${path}: ${e.message}`);
  process.exit(2);
}

const errors = [];
const warnings = [];
const ID_RE = /^[A-D]\d+$/;
const METHODS = new Set(['test', 'tsc', 'lint', 'judge']);
const TASK_TYPES = new Set(['api', 'ui', 'db', 'mixed']);

if (!TASK_TYPES.has(rubric.taskType)) {
  errors.push(`taskType must be one of ${[...TASK_TYPES].join(', ')} (got ${JSON.stringify(rubric.taskType)})`);
}
if (typeof rubric.threshold !== 'number') {
  errors.push('threshold must be a number');
}
if (!Array.isArray(rubric.categories) || rubric.categories.length === 0) {
  errors.push('categories must be a non-empty array');
  report();
}

let weightSum = 0;
const seenIds = new Set();
let mustPassCount = 0;

for (const cat of rubric.categories) {
  const k = cat.key ?? '?';
  if (typeof cat.weight !== 'number') {
    errors.push(`[${k}] weight must be a number`);
    continue;
  }
  weightSum += cat.weight;

  if (typeof cat.floor !== 'number' || cat.floor < 0 || cat.floor > 1) {
    errors.push(`[${k}] floor must be in [0,1] (got ${cat.floor})`);
  }

  const items = Array.isArray(cat.items) ? cat.items : [];

  if (cat.weight === 0) {
    if (items.length !== 0) errors.push(`[${k}] inactive category (weight 0) must have empty items`);
    continue;
  }

  if (items.length === 0) {
    errors.push(`[${k}] active category (weight ${cat.weight}) must have >= 1 item`);
    continue;
  }

  let pointsSum = 0;
  for (const it of items) {
    pointsSum += typeof it.points === 'number' ? it.points : NaN;
    if (!ID_RE.test(it.id ?? '')) errors.push(`item id "${it.id}" must match /^[A-D]\\d+$/`);
    if (seenIds.has(it.id)) errors.push(`duplicate item id "${it.id}"`);
    seenIds.add(it.id);
    if (!METHODS.has(it.method)) errors.push(`[${it.id}] method must be one of ${[...METHODS].join(', ')}`);
    if (it.mustPass === true) mustPassCount++;
  }
  if (pointsSum !== cat.weight) {
    errors.push(`[${k}] item points sum (${pointsSum}) must equal category weight (${cat.weight})`);
  }
}

if (weightSum !== 100) {
  errors.push(`category weights must sum to 100 (got ${weightSum})`);
}

if ((rubric.taskType === 'api' || rubric.taskType === 'db') && mustPassCount === 0) {
  errors.push(`taskType ${rubric.taskType} requires >= 1 mustPass item (security/integrity gate)`);
}

if (rubric.frozen === true) {
  warnings.push('rubric is frozen — generator must not modify a frozen rubric');
}

report();

function report() {
  for (const w of warnings) console.error(`WARN  ${w}`);
  if (errors.length === 0) {
    console.log(`OK  ${path} — valid rubric (${rubric.categories?.filter((c) => c.weight > 0).length} active categories, ${seenIds.size} items, ${mustPassCount} must-pass)`);
    process.exit(0);
  }
  for (const e of errors) console.error(`FAIL  ${e}`);
  console.error(`\n${errors.length} error(s) — rubric invalid`);
  process.exit(1);
}
