#!/usr/bin/env node
// Store ADMAP_API_KEY in the user's GLOBAL Claude Code settings (~/.claude/settings.json)
// so every session inherits it. Verifies the key against the live API before writing,
// backs up the previous settings file, and never prints the key in full.
//
// Usage:
//   node set-key.mjs --key admap_xxxxx        # 값 직접 전달
//   echo -n admap_xxxxx | node set-key.mjs --stdin   # 셸 히스토리에 안 남김
//   node set-key.mjs --key admap_xxxxx --no-verify   # 라이브 검증 생략
//   node set-key.mjs --show                   # 현재 저장 상태만 마스킹 출력

import { readFile, writeFile, access, copyFile } from 'node:fs/promises';
import { homedir } from 'node:os';
import { join } from 'node:path';

const SETTINGS = join(homedir(), '.claude', 'settings.json');
const ENV_VAR = 'ADMAP_API_KEY';
const BASE = process.env.ADMAP_API_BASE ?? 'https://map.adtype.work/api/v1';
const KEY_PATTERN = /^admap_[A-Za-z0-9]{16,}$/;

function fail(msg) {
  console.error(`[set-key] ${msg}`);
  process.exit(1);
}
function mask(k) {
  return typeof k === 'string' && k.length > 12 ? `${k.slice(0, 10)}…${k.slice(-4)}` : '(형식 이상)';
}

const argv = process.argv.slice(2);
const flag = (name) => argv.includes(`--${name}`);
const value = (name) => {
  const i = argv.indexOf(`--${name}`);
  if (i === -1) return undefined;
  const v = argv[i + 1];
  if (v === undefined || v.startsWith('--')) fail(`--${name} 에 값이 필요합니다.`);
  return v;
};

async function readSettings() {
  try {
    await access(SETTINGS);
  } catch {
    return {}; // 파일이 없으면 새로 만든다.
  }
  const raw = await readFile(SETTINGS, 'utf8');
  try {
    return JSON.parse(raw);
  } catch (err) {
    fail(
      `${SETTINGS} 가 유효한 JSON 이 아닙니다 — 덮어쓰지 않습니다. 직접 고친 뒤 다시 실행하세요.\n  ${err.message}`,
    );
  }
}

// --- --show: 현재 상태만 보고 -----------------------------------------------
if (flag('show')) {
  const s = await readSettings();
  const stored = s.env?.[ENV_VAR];
  console.log(`설정 파일   ${SETTINGS}`);
  console.log(`${ENV_VAR}  ${stored ? mask(stored) : '(미설정)'}`);
  console.log(`현재 셸     ${process.env[ENV_VAR] ? mask(process.env[ENV_VAR]) : '(미설정)'}`);
  process.exit(0);
}

// --- 키 수집 ----------------------------------------------------------------
let key = value('key');
if (flag('stdin')) {
  const chunks = [];
  for await (const c of process.stdin) chunks.push(c);
  key = Buffer.concat(chunks).toString('utf8').trim();
}
if (!key) fail('키가 없습니다. `--key admap_...` 또는 `--stdin` 을 쓰세요.');
if (!KEY_PATTERN.test(key)) {
  fail(`키 형식이 올바르지 않습니다 — \`admap_\` 로 시작하는 영숫자 키여야 합니다 (받은 값: ${mask(key)}).`);
}

// --- 쓰기 대상 선점 검사 (fail-fast) -----------------------------------------
// 네트워크 왕복 전에 settings 를 읽어둔다 — 파일이 깨져 있으면 검증에 시간을 쓸 이유가 없다.
const settings = await readSettings();

// --- 라이브 검증 (기본 on) ---------------------------------------------------
if (!flag('no-verify')) {
  let res;
  try {
    res = await fetch(`${BASE}/maps`, { headers: { 'X-API-Key': key } });
  } catch (err) {
    fail(`검증 실패 — ${BASE} 에 접속할 수 없습니다: ${err.message}\n  오프라인이면 --no-verify 로 건너뛸 수 있습니다.`);
  }
  if (res.status === 401) fail('검증 실패 — 이 키는 무효하거나 만료됐습니다(401). 저장하지 않았습니다.');
  if (!res.ok) fail(`검증 실패 — GET /maps -> HTTP ${res.status}. 저장하지 않았습니다.`);
  const body = await res.json().catch(() => ({}));
  const maps = (body.maps ?? body ?? []).length;
  console.log(`[set-key] 검증 통과 — 접근 가능한 map ${maps}개`);
}

// --- 저장 --------------------------------------------------------------------
const previous = settings.env?.[ENV_VAR];
settings.env = { ...(settings.env ?? {}), [ENV_VAR]: key };

try {
  await access(SETTINGS);
  const backup = `${SETTINGS}.bak-${new Date().toISOString().replace(/[:.]/g, '-')}`;
  await copyFile(SETTINGS, backup);
  console.log(`[set-key] 백업 ${backup}`);
} catch {
  // 원본이 없으면 백업할 것도 없다.
}

await writeFile(SETTINGS, `${JSON.stringify(settings, null, 2)}\n`);

console.log(`[set-key] 저장 완료 ${SETTINGS}`);
console.log(`  ${ENV_VAR}  ${previous ? `${mask(previous)} -> ${mask(key)}` : mask(key)}`);
console.log('  주의: 새 값은 Claude Code 세션을 다시 시작해야 반영됩니다.');
console.log(`  이번 세션에서 바로 쓰려면: export ${ENV_VAR}=<키>`);
