import { test } from 'node:test';
import assert from 'node:assert/strict';
import { decideNext, runDevEvalLoop } from './loop-control.mjs';

const F = (sig) => ({ pass: false, signature: sig });
const P = { pass: true, signature: null };

// Acceptance #1 — decideNext matrix (6 cases, reviewer-pinned).
test('decideNext: [fail A] → retry', () => {
  assert.equal(decideNext([F('A')]), 'retry');
});
test('decideNext: [fail A, fail A] → short-circuit (same signature)', () => {
  assert.equal(decideNext([F('A'), F('A')]), 'short-circuit');
});
test('decideNext: [fail A, fail B] → retry', () => {
  assert.equal(decideNext([F('A'), F('B')]), 'retry');
});
test('decideNext: [fail A, fail B, fail C] → short-circuit (cap)', () => {
  assert.equal(decideNext([F('A'), F('B'), F('C')]), 'short-circuit');
});
test('decideNext: [fail A, fail B, fail A] → short-circuit (cap, no 4th attempt leak)', () => {
  assert.equal(decideNext([F('A'), F('B'), F('A')]), 'short-circuit');
});
test('decideNext: [fail A, pass] → pass', () => {
  assert.equal(decideNext([F('A'), P]), 'pass');
});

// Acceptance #1b — runDevEvalLoop integration seam (history accumulation + outcome).
test('runDevEvalLoop: passes on 2nd attempt', async () => {
  const scripted = [F('A'), P];
  const r = await runDevEvalLoop({ runAttempt: (n) => Promise.resolve(scripted[n]) });
  assert.equal(r.outcome, 'pass');
  assert.equal(r.history.length, 2);
  assert.deepEqual(r.history.map((h) => h.pass), [false, true]);
});
test('runDevEvalLoop: short-circuits on same-signature 2x (does not reach cap)', async () => {
  let calls = 0;
  const r = await runDevEvalLoop({ runAttempt: () => { calls++; return Promise.resolve(F('A')); } });
  assert.equal(r.outcome, 'short-circuit');
  assert.equal(calls, 2); // stopped at 2, not 3
});
test('runDevEvalLoop: short-circuits at cap on distinct signatures', async () => {
  const scripted = [F('A'), F('B'), F('C')];
  let calls = 0;
  const r = await runDevEvalLoop({ runAttempt: (n) => { calls++; return Promise.resolve(scripted[n]); } });
  assert.equal(r.outcome, 'short-circuit');
  assert.equal(calls, 3); // 1 initial + 2 retries
});
