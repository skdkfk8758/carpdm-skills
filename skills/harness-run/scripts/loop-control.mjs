// Inner dev-eval loop control for the harness orchestrator (C1).
// Pure decision logic (REQ-F-009 retry cap, REQ-F-010 same-signature short-circuit).
// SSOT — the dev-eval-loop Workflow mirrors decideNext inline (Workflow scripts can't import).

export const MAX_RETRIES = 2; // initial attempt + 2 retries = up to 3 dev runs

/**
 * Decide what to do after the latest attempt.
 * @param {{pass:boolean, signature:string|null}[]} history  attempts in order
 * @param {number} maxRetries
 * @returns {'pass'|'retry'|'short-circuit'}
 */
export function decideNext(history, maxRetries = MAX_RETRIES) {
  const last = history[history.length - 1];
  if (!last) return 'retry'; // nothing run yet → run the first attempt
  if (last.pass) return 'pass';
  // REQ-F-010: same failure signature twice in a row → short-circuit early (don't burn the cap)
  const prev = history[history.length - 2];
  if (prev && !prev.pass && prev.signature === last.signature) return 'short-circuit';
  // REQ-F-009: cap = 1 initial + maxRetries attempts
  if (history.length >= 1 + maxRetries) return 'short-circuit';
  return 'retry';
}

/**
 * Drive the inner loop. `runAttempt(n)` is injected (a dev+eval round) so the loop is
 * testable without the Workflow runtime; the real Workflow supplies agent-backed attempts.
 * @param {{runAttempt:(n:number)=>Promise<{pass:boolean, signature:string|null}>, maxRetries?:number}} opts
 * @returns {Promise<{outcome:'pass'|'short-circuit', history:object[]}>}
 */
export async function runDevEvalLoop({ runAttempt, maxRetries = MAX_RETRIES }) {
  const history = [];
  for (let n = 0; ; n++) {
    const verdict = await runAttempt(n);
    history.push({ pass: !!verdict.pass, signature: verdict.signature ?? null });
    const decision = decideNext(history, maxRetries);
    if (decision !== 'retry') return { outcome: decision, history };
  }
}
