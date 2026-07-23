#!/usr/bin/env node
// Build a static ADMap map-page folder: fetch the published style, switch off the
// layers the planner did not pick (visibility only — never delete), scaffold the
// folder, then run static verification.
//
// Usage:
//   node build.mjs --out ./my-page [--title "..."] [--project "..."]
//                  [--selected id1,id2 | --selected-file picks.json]
//                  [--center 127.0276,37.4979] [--zoom 14]

import { mkdir, writeFile, readFile, access } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import { join, resolve } from 'node:path';

const BASE = process.env.ADMAP_API_BASE ?? 'https://map.adtype.work/api/v1';
const MAP_ID = process.env.ADMAP_MAP_ID ?? 'main';
const KEY = process.env.ADMAP_API_KEY;

const MAPLIBRE_VERSION = '5.21.0';
const PMTILES_VERSION = '4.4.0';
// 스타일은 style.json 이 아니라 style.js 로 굽는다. maplibre 가 style URL 을 fetch() 로
// 읽는데 file:// origin(null) 에서는 브라우저가 그 fetch 를 막아 더블클릭이 안 된다.
// classic <script src> 는 CORS 대상이 아니라 통과한다. 원격 타일·스프라이트는 ADMap
// CDN 이 Access-Control-Allow-Origin: * 라 origin null 도 허용한다(실측).
const STYLE_GLOBAL = '__ADMAP_STYLE__';
const DEFAULT_CENTER = [126.978, 37.5665]; // 서울시청
const DEFAULT_ZOOM = 11;
const LOGICAL_ID_KEY = 'admap:layerId';

const TEMPLATES = new URL('../templates/', import.meta.url);

function fail(msg) {
  console.error(`[admap-scaffold] ${msg}`);
  process.exit(1);
}

function parseArgs(argv) {
  const out = {};
  for (let i = 0; i < argv.length; i += 1) {
    const a = argv[i];
    if (!a.startsWith('--')) continue;
    const key = a.slice(2);
    const next = argv[i + 1];
    if (next === undefined || next.startsWith('--')) fail(`--${key} 에 값이 필요합니다.`);
    out[key] = next;
    i += 1;
  }
  return out;
}

const args = parseArgs(process.argv.slice(2));
if (!args.out) fail('--out <dir> 이 필요합니다.');
if (!KEY) fail('ADMAP_API_KEY 가 설정되지 않았습니다. `export ADMAP_API_KEY=admap_...` 후 다시 실행하세요.');

const outDir = resolve(args.out);
const project = args.project ?? args.out.replace(/^.*[/\\]/, '');
const title = args.title ?? project;

let center = DEFAULT_CENTER;
if (args.center) {
  const parts = args.center.split(',').map((n) => Number(n.trim()));
  if (parts.length !== 2 || parts.some(Number.isNaN)) fail('--center 는 "lng,lat" 형식이어야 합니다.');
  center = parts;
}
const zoom = args.zoom === undefined ? DEFAULT_ZOOM : Number(args.zoom);
if (Number.isNaN(zoom)) fail('--zoom 은 숫자여야 합니다.');

// --- 1. 기존 폴더 보호 (REQ-F-013) -----------------------------------------
let exists = true;
try {
  await access(outDir);
} catch {
  exists = false;
}
if (exists) fail(`${outDir} 가 이미 존재합니다. 덮어쓰지 않습니다 — 다른 --out 을 쓰거나 기존 폴더를 옮기세요.`);

// --- 2. 선택 집합 -----------------------------------------------------------
let selected = new Set();
if (args['selected-file']) {
  const raw = JSON.parse(await readFile(args['selected-file'], 'utf8'));
  const ids = Array.isArray(raw) ? raw : (raw.selected ?? []);
  selected = new Set(ids);
} else if (args.selected) {
  selected = new Set(
    args.selected
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean),
  );
}

// --- 3. API 조회 ------------------------------------------------------------
async function get(path, asText = false) {
  let res;
  try {
    res = await fetch(`${BASE}${path}`, { headers: { 'X-API-Key': KEY } });
  } catch (err) {
    fail(`GET ${path} 실패 — 네트워크 오류: ${err.message}`);
  }
  if (!res.ok) {
    const hint = res.status === 401 ? ' (ADMAP_API_KEY 가 무효하거나 만료됐습니다)' : '';
    fail(`GET ${path} -> HTTP ${res.status}${hint}`);
  }
  return asText ? res.text() : res.json();
}

const styleText = await get(`/maps/${MAP_ID}/style`, true);
let style;
try {
  style = JSON.parse(styleText);
} catch {
  fail('style 응답이 유효한 JSON 이 아닙니다.');
}
const originalLayerCount = (style.layers ?? []).length;
const originalSourceCount = Object.keys(style.sources ?? {}).length;

const catalog = await get(`/maps/${MAP_ID}/layers`);
const catalogIds = new Set((catalog.layers ?? []).map((l) => l.id));

// --- 4. visibility 패치 (REQ-F-006 / 006a / 006b) ---------------------------
// 매핑은 metadata['admap:layerId'] 로만 한다 — layer.id 문자열 매칭은 __casing·__sN
// 파생 레이어를 놓친다. 이 키가 없는 레이어(background 등)는 카탈로그 비대응이므로
// 손대지 않는다. 선택 집합이 비면 아무것도 바꾸지 않는다(스냅샷 그대로).
//
// 양방향인 이유: ADMap 라이브 style 은 published 레이어를 visibility:'none' 으로
// 내보내는 경우가 있다(실측 — trade-areas·districts). 미선택만 끄면 "골랐는데 안 보이는"
// 결과가 나온다. 선택 = 명시적으로 켠다.
let switchedOff = 0;
let switchedOn = 0;
if (selected.size > 0) {
  for (const layer of style.layers ?? []) {
    const logical = layer.metadata?.[LOGICAL_ID_KEY];
    if (!logical) continue;
    if (!catalogIds.has(logical)) continue;
    const want = selected.has(logical) ? 'visible' : 'none';
    const had = layer.layout?.visibility ?? 'visible';
    if (had === want) continue;
    layer.layout = { ...(layer.layout ?? {}), visibility: want };
    if (want === 'none') switchedOff += 1;
    else switchedOn += 1;
  }
}

// --- 5. 스캐폴딩 (REQ-F-007) ------------------------------------------------
async function template(name) {
  return readFile(new URL(name, TEMPLATES), 'utf8');
}
function fill(text, vars) {
  return text.replace(/\{\{(\w+)\}\}/g, (m, k) => (k in vars ? String(vars[k]) : m));
}

const vars = {
  TITLE: title,
  PROJECT: project,
  CENTER_LNG: center[0],
  CENTER_LAT: center[1],
  ZOOM: zoom,
  MAPLIBRE_VERSION,
  PMTILES_VERSION,
  MAP_ID,
  LAYER_COUNT: originalLayerCount,
  SOURCE_COUNT: originalSourceCount,
};

await mkdir(outDir, { recursive: true });
await mkdir(join(outDir, 'data'), { recursive: true });
await mkdir(join(outDir, 'media'), { recursive: true });
await mkdir(join(outDir, '.claude', 'hooks'), { recursive: true });

const styleJs = [
  '// ADMap style snapshot — 생성 시점에 고정. 손으로 편집하지 말 것.',
  '// JSON 이 아니라 JS 인 이유: file:// 더블클릭으로도 열리게 하기 위함(build.mjs 주석 참조).',
  `window.${STYLE_GLOBAL} = ${JSON.stringify(style, null, 2)};`,
  '',
].join('\n');
await writeFile(join(outDir, 'style.js'), styleJs);
await writeFile(join(outDir, 'index.html'), fill(await template('index.html'), vars));
await writeFile(join(outDir, 'README.md'), fill(await template('README.md'), vars));
await writeFile(join(outDir, 'OVERLAY-RULES.md'), fill(await template('OVERLAY-RULES.md'), vars));
await writeFile(join(outDir, 'CLAUDE.md'), fill(await template('CLAUDE.md'), vars));
await writeFile(join(outDir, 'verify.mjs'), fill(await template('verify.mjs'), vars));
await writeFile(join(outDir, '.claude', 'settings.json'), await template('claude-settings.json'));
await writeFile(join(outDir, '.claude', 'hooks', 'guard-static-only.mjs'), await template('hooks/guard-static-only.mjs'));
await writeFile(join(outDir, '.claude', 'hooks', 'verify-stop.mjs'), await template('hooks/verify-stop.mjs'));
await writeFile(join(outDir, 'data', '.gitkeep'), '');
await writeFile(join(outDir, 'media', '.gitkeep'), '');

// --- 6. 정적 검증 (REQ-F-011 / REQ-N-001) -----------------------------------
const checks = [];
function check(name, ok, detail) {
  checks.push({ name, ok, detail });
}

const required = [
  'index.html',
  'style.js',
  'README.md',
  'OVERLAY-RULES.md',
  'CLAUDE.md',
  'verify.mjs',
  '.claude/settings.json',
  '.claude/hooks/guard-static-only.mjs',
  '.claude/hooks/verify-stop.mjs',
  'data',
  'media',
];
const missing = [];
for (const f of required) {
  try {
    await access(join(outDir, f));
  } catch {
    missing.push(f);
  }
}
check('필수 파일 존재', missing.length === 0, missing.length ? `누락: ${missing.join(', ')}` : `${required.length}개 확인`);

// style.js 는 문자열로 검사하지 않고 실제로 실행해 본다 — 브라우저가 하는 일과 같아
// "JS 로 유효한가 + 전역에 스타일이 실리는가"를 한 번에 잡는다.
let reparsed = null;
try {
  const win = {};
  new Function('window', await readFile(join(outDir, 'style.js'), 'utf8'))(win);
  reparsed = win[STYLE_GLOBAL];
  check(
    'style.js 실행 가능 + 구조 무손상',
    reparsed?.layers?.length === originalLayerCount &&
      Object.keys(reparsed?.sources ?? {}).length === originalSourceCount,
    `layers ${reparsed?.layers?.length}/${originalLayerCount} · sources ${Object.keys(reparsed?.sources ?? {}).length}/${originalSourceCount}`,
  );
} catch (err) {
  check('style.js 실행 가능 + 구조 무손상', false, err.message);
}

// file:// 회귀 가드 — index.html 이 로컬 파일을 fetch 로 읽으면 더블클릭이 다시 깨진다.
const html = await readFile(join(outDir, 'index.html'), 'utf8');
const fetchesLocal = /style:\s*['"]\.\//.test(html) || /fetch\(\s*['"]\.\//.test(html);
check(
  'file:// 로 열림 (로컬 fetch 없음)',
  !fetchesLocal && html.includes('style.js') && html.includes(STYLE_GLOBAL),
  fetchesLocal ? 'index.html 이 로컬 경로를 fetch 한다 — file:// 에서 막힌다' : 'style.js 를 <script src> 로 로드',
);

if (reparsed) {
  const brokenSelection = (reparsed.layers ?? []).filter(
    (l) => selected.has(l.metadata?.[LOGICAL_ID_KEY]) && l.layout?.visibility === 'none',
  );
  check(
    '선택 레이어가 켜져 있음',
    brokenSelection.length === 0,
    brokenSelection.length ? `꺼진 선택 레이어: ${brokenSelection.map((l) => l.id).join(', ')}` : `선택 ${selected.size}개`,
  );
}

// REQ-N-001 — 산출물에 키 문자열이 새지 않았는지.
const textOutputs = required.filter((f) => f !== 'data' && f !== 'media');
const leaked = [];
for (const f of textOutputs) {
  const body = await readFile(join(outDir, f), 'utf8');
  if (body.includes(KEY) || /admap_[A-Za-z0-9]{16,}/.test(body)) leaked.push(f);
}
check('API key 미노출', leaked.length === 0, leaked.length ? `노출 의심: ${leaked.join(', ')}` : `${textOutputs.length}개 파일 clean`);

// 동봉된 verify.mjs 가 산출 직후 상태에서 실제로 PASS 하는지 — 이후 세션의 재검증
// 도구 자체를 여기서 한 번 검증한다.
const verifyRun = spawnSync(process.execPath, [join(outDir, 'verify.mjs')], { cwd: outDir, encoding: 'utf8' });
check(
  'verify.mjs 자가 실행',
  verifyRun.status === 0,
  verifyRun.status === 0 ? '동봉 검증 스크립트 PASS' : `exit ${verifyRun.status}\n${verifyRun.stdout ?? ''}${verifyRun.stderr ?? ''}`,
);

// --- 7. 보고 ---------------------------------------------------------------
console.log(`\n[admap-scaffold] ${outDir}`);
console.log(
  `  style      layers ${originalLayerCount} · sources ${originalSourceCount} · 켬 ${switchedOn}개 · 끔 ${switchedOff}개`,
);
console.log(`  camera     [${center[0]}, ${center[1]}] z${zoom}`);
console.log(`  deps       maplibre-gl@${MAPLIBRE_VERSION} · pmtiles@${PMTILES_VERSION}`);
console.log('  검증');
for (const c of checks) console.log(`    ${c.ok ? 'PASS' : 'FAIL'}  ${c.name} — ${c.detail}`);

const failed = checks.filter((c) => !c.ok);
if (failed.length) {
  console.error(`\n[admap-scaffold] 검증 ${failed.length}건 실패.`);
  process.exit(1);
}
console.log('\n[admap-scaffold] 완료. 다음: OVERLAY-RULES.md 를 읽고 자기 데이터를 붙이세요.');
