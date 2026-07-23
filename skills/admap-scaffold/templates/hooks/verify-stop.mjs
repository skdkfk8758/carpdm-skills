#!/usr/bin/env node
// Stop hook — reruns the folder's static verification when a session ends.
// verify FAIL → exit 2 (blocks stop, feeds the failure back to the model to fix).
// stop_hook_active guards against loops; verify.mjs missing → allow (never trap).

import { spawnSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

let raw = '';
for await (const chunk of process.stdin) raw += chunk;

try {
  if (JSON.parse(raw).stop_hook_active) process.exit(0);
} catch {
  // unparsable input — fall through, still safe to verify
}

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const verify = join(root, 'verify.mjs');
if (!existsSync(verify)) process.exit(0);

const res = spawnSync(process.execPath, [verify], { cwd: root, encoding: 'utf8' });
if (res.status === 0) process.exit(0);

console.error(
  '[verify-stop] 정적 검증 FAIL — 아래 항목을 고친 뒤 종료하세요.\n' +
    `${res.stdout ?? ''}${res.stderr ?? ''}`,
);
process.exit(2);
