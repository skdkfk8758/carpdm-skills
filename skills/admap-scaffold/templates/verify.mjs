#!/usr/bin/env node
// Static re-verification for an admap-scaffold output folder.
// Run after overlay work: `node verify.mjs`. Exit 1 on any FAIL (WARN does not fail).
// Baseline layer/source counts are baked in at scaffold time — style.js is a frozen
// snapshot, so the counts must never drift.

import { readFile, readdir, access } from 'node:fs/promises';
import { join, dirname, extname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = dirname(fileURLToPath(import.meta.url));
const STYLE_GLOBAL = '__ADMAP_STYLE__';
const BASE_LAYERS = {{LAYER_COUNT}};
const BASE_SOURCES = {{SOURCE_COUNT}};

const results = [];
function report(level, name, detail) {
  results.push({ level, name, detail });
}

async function exists(p) {
  try {
    await access(join(ROOT, p));
    return true;
  } catch {
    return false;
  }
}

// --- 1. required files -------------------------------------------------------
const required = ['index.html', 'style.js', 'README.md', 'OVERLAY-RULES.md', 'CLAUDE.md', 'data', 'media'];
const missing = [];
for (const f of required) if (!(await exists(f))) missing.push(f);
report(missing.length ? 'FAIL' : 'PASS', '필수 파일 존재', missing.length ? `누락: ${missing.join(', ')}` : `${required.length}개 확인`);

// --- 2. style.js intact ------------------------------------------------------
let style = null;
try {
  const win = {};
  new Function('window', await readFile(join(ROOT, 'style.js'), 'utf8'))(win);
  style = win[STYLE_GLOBAL];
  const layers = style?.layers?.length ?? 0;
  const sources = Object.keys(style?.sources ?? {}).length;
  report(
    layers === BASE_LAYERS && sources === BASE_SOURCES ? 'PASS' : 'FAIL',
    'style.js 무손상 (스냅샷 기준)',
    `layers ${layers}/${BASE_LAYERS} · sources ${sources}/${BASE_SOURCES}`,
  );
} catch (err) {
  report('FAIL', 'style.js 무손상 (스냅샷 기준)', `실행 실패: ${err.message}`);
}

// --- 3. file:// regression + A/B mode ---------------------------------------
let html = '';
try {
  html = await readFile(join(ROOT, 'index.html'), 'utf8');
  const fetchesLocalStyle = /style:\s*['"]\.\//.test(html) || /fetch\(\s*['"]\.\//.test(html);
  report(
    !fetchesLocalStyle && html.includes('style.js') && html.includes(STYLE_GLOBAL) ? 'PASS' : 'FAIL',
    'file:// 로 열림 (스타일 로컬 fetch 없음)',
    fetchesLocalStyle ? '로컬 경로 fetch 감지 — 더블클릭이 깨진다' : 'style.js <script src> 로드',
  );

  // Overlay loading mode: A = ./data/*.js via <script src>, B = data URL into addSource.
  const usesA = /<script[^>]+src=["']\.\/data\/[^"']+\.js["']/.test(html);
  const usesB = /data:\s*['"]\.\/data\//.test(html);
  if (usesA && usesB) {
    report('FAIL', '오버레이 A/B 혼용 없음', 'A(.js wrapper)와 B(로컬 URL)가 섞였다 — 폴더가 서버 없이는 안 뜬다. 한 방식으로 통일할 것 (OVERLAY-RULES.md)');
  } else if (usesB) {
    report('WARN', '오버레이 방식 = B (서버 필요)', '더블클릭으로는 안 뜬다. 의도한 선택이면 무시 — 아니면 A 방식으로 (OVERLAY-RULES.md)');
  } else {
    report('PASS', '오버레이 A/B 혼용 없음', usesA ? 'A 방식 (.js wrapper) — 더블클릭 유지' : '오버레이 로드 없음');
  }
} catch (err) {
  report('FAIL', 'index.html 읽기', err.message);
}

// --- 4. API key leak ---------------------------------------------------------
const KEY_PATTERN = /admap_[A-Za-z0-9]{16,}/;
async function textFiles(dir, acc = []) {
  for (const e of await readdir(join(ROOT, dir), { withFileTypes: true })) {
    if (e.name.startsWith('.')) continue;
    const rel = dir === '.' ? e.name : `${dir}/${e.name}`;
    if (e.isDirectory()) await textFiles(rel, acc);
    else if (['.html', '.js', '.mjs', '.md', '.json', '.geojson', '.css'].includes(extname(e.name))) acc.push(rel);
  }
  return acc;
}
const leaked = [];
for (const f of await textFiles('.')) {
  if (KEY_PATTERN.test(await readFile(join(ROOT, f), 'utf8'))) leaked.push(f);
}
report(leaked.length ? 'FAIL' : 'PASS', 'API key 미노출', leaked.length ? `노출 의심: ${leaked.join(', ')}` : '전 텍스트 파일 clean');

// --- 5. geojson coordinate sanity (EPSG:5179 misload guard) ------------------
// Korean public data often ships EPSG:5179 (meters, ~1,000,000 scale). Fed to
// maplibre as-is, nothing renders. Heuristic: any coordinate pair outside
// lng [-180,180] / lat [-90,90] fails.
function findBadCoord(node) {
  if (Array.isArray(node)) {
    if (node.length >= 2 && typeof node[0] === 'number' && typeof node[1] === 'number') {
      if (Math.abs(node[0]) > 180 || Math.abs(node[1]) > 90) return node.slice(0, 2);
      return null;
    }
    for (const item of node) {
      const bad = findBadCoord(item);
      if (bad) return bad;
    }
    return null;
  }
  if (node && typeof node === 'object') {
    if (node.coordinates) return findBadCoord(node.coordinates);
    for (const key of ['features', 'geometry', 'geometries']) {
      if (node[key]) {
        const bad = findBadCoord(node[key]);
        if (bad) return bad;
      }
    }
  }
  return null;
}
const coordProblems = [];
let dataFileCount = 0;
if (await exists('data')) {
  for (const e of await readdir(join(ROOT, 'data'), { withFileTypes: true })) {
    if (!e.isFile()) continue;
    const rel = `data/${e.name}`;
    const ext = extname(e.name);
    try {
      if (ext === '.geojson' || ext === '.json') {
        dataFileCount += 1;
        const bad = findBadCoord(JSON.parse(await readFile(join(ROOT, rel), 'utf8')));
        if (bad) coordProblems.push(`${rel} → [${bad.join(', ')}]`);
      } else if (ext === '.js') {
        dataFileCount += 1;
        const win = {};
        new Function('window', await readFile(join(ROOT, rel), 'utf8'))(win);
        for (const v of Object.values(win)) {
          const bad = findBadCoord(v);
          if (bad) {
            coordProblems.push(`${rel} → [${bad.join(', ')}]`);
            break;
          }
        }
      }
    } catch (err) {
      coordProblems.push(`${rel} → 파싱/실행 실패: ${err.message}`);
    }
  }
}
report(
  coordProblems.length ? 'FAIL' : 'PASS',
  'geojson 좌표계 (EPSG:4326 경위도)',
  coordProblems.length
    ? `범위 밖 좌표 — EPSG:5179 의심, 변환 필요: ${coordProblems.join(' · ')}`
    : dataFileCount ? `data/ ${dataFileCount}개 파일 정상 범위` : 'data/ 비어 있음',
);

// --- report ------------------------------------------------------------------
console.log(`[verify] ${ROOT}`);
for (const r of results) console.log(`  ${r.level.padEnd(4)}  ${r.name} — ${r.detail}`);
const failed = results.filter((r) => r.level === 'FAIL');
if (failed.length) {
  console.error(`\n[verify] ${failed.length}건 FAIL. 위 항목을 고친 뒤 다시 실행하세요. 규칙: OVERLAY-RULES.md`);
  process.exit(1);
}
console.log('\n[verify] 정적 검증 통과. 실렌더 확인은 브라우저로 (콘솔 에러 0 확인).');
