#!/usr/bin/env node
/**
 * Catalog check: README.md must agree with the actual skills/ inventory.
 *
 * Why: the skill count / table drifted twice within 8 days (fixed in #109
 * "25→27종" on 2026-07-22, drifted again to "27개" vs 25 dirs by #137's
 * retirement of 5 harness skills). The pre-PR hook only checked link
 * PRESENCE, so both incidents passed it. This script is the single source
 * of truth for catalog freshness; guard-readme-fresh.sh calls it too.
 *
 * Checks (exit 1 on any violation):
 *   1. Every skills/<name>/ directory is linked in README.md ("skills/<name>").
 *   2. Every "skills/<name>" reference in README.md points to an existing
 *      directory (catches rows left behind after a skill retirement).
 *   3. Every "N개 스킬" / "N개의 스킬" count claim in README.md equals the
 *      actual directory count. (If a legitimate subset count is ever needed,
 *      rephrase it to avoid the "N개 스킬" pattern.)
 *
 * Zero dependencies. Run: node scripts/ci/catalog.js
 */

'use strict';

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');

function main() {
  const skillsDir = path.join(ROOT, 'skills');
  const readmePath = path.join(ROOT, 'README.md');

  if (!fs.existsSync(skillsDir) || !fs.existsSync(readmePath)) {
    console.error('catalog: skills/ or README.md missing.');
    return 1;
  }

  const dirs = fs
    .readdirSync(skillsDir, { withFileTypes: true })
    .filter(e => e.isDirectory())
    .map(e => e.name)
    .sort();

  const readme = fs.readFileSync(readmePath, 'utf8');
  const errors = [];

  // 1. Every dir linked in README.
  for (const dir of dirs) {
    if (!readme.includes(`skills/${dir}`)) {
      errors.push(`README.md is missing a link to skills/${dir}`);
    }
  }

  // 2. Every README skills/<name> reference exists on disk.
  const referenced = new Set();
  for (const m of readme.matchAll(/skills\/([a-z0-9-]+)/g)) {
    referenced.add(m[1]);
  }
  for (const name of [...referenced].sort()) {
    if (!dirs.includes(name)) {
      errors.push(`README.md references skills/${name} but the directory does not exist (stale row?)`);
    }
  }

  // 3. Count claims match reality.
  for (const m of readme.matchAll(/(\d+)\s*개(?:의)?\s*스킬/g)) {
    const claimed = Number(m[1]);
    if (claimed !== dirs.length) {
      const { line } = locate(readme, m.index);
      errors.push(`README.md:${line} claims "${m[0]}" but skills/ has ${dirs.length} directories`);
    }
  }

  if (errors.length > 0) {
    console.error(`catalog: ${errors.length} violation(s) (actual skill count: ${dirs.length}):`);
    for (const e of errors) console.error(`  - ${e}`);
    return 1;
  }

  console.log(`catalog: OK — ${dirs.length} skills, README.md in sync.`);
  return 0;
}

function locate(text, index) {
  return { line: text.slice(0, index).split('\n').length };
}

process.exit(main());
