# Secure Verify

Phase 4 proves the change works AND is safe before anything ships. Two parts run
together: the project's functional verify gate, and a security pass over the
diff. A green test suite with a SQL injection in it is not done.

## 1. Functional gate

Run the project's standard verify path. If the project defines one (e.g. a
`verify.sh`, a `make verify`, or documented commands), use it — it already knows
which checks apply. Otherwise run the obvious equivalents: tests, typecheck,
lint, build. Nothing proceeds while any of these is red.

## 2. Security pass over the diff

Use the **`security-review`** skill on the branch/diff for the heavy lifting. In
addition, eyeball the change for the categories that bite most often:

- **Injection** — user input reaching SQL / shell / eval. For SQL, parameterized
  queries only; dynamic identifiers must come from an allowlist, never
  string-interpolated input.
- **AuthN / AuthZ** — does the new path enforce the same auth as its neighbors?
  Any endpoint or action that skips a check a sibling makes?
- **Secrets & hosts** — no credentials, tokens, or hardcoded infra hosts in code
  or in the built bundle. Config comes from env/proxy, not literals.
- **Input validation** — every external input validated at the boundary (schema /
  DTO), not trusted downstream.
- **Path traversal / file ops** — user-controlled paths sanitized.
- **Unsafe deserialization / `eval`** — none on untrusted data.
- **Error & log hygiene** — errors don't leak stack traces, secrets, or internal
  structure to the client.
- **Dependencies** — new deps are necessary and not known-vulnerable.

Respect any project-specific guardrails (e.g. a forbidden hardcoded host, a
service→DB boundary rule) — those exist for a reason and the gate should enforce
them.

## 3. Adversarially verify each finding

Before reporting a security issue as real, try to **refute** it: is the input
actually reachable? is it actually untrusted? is there an upstream check that
already neutralizes it? Default to "refuted" when uncertain — a wall of
false-positive findings is worse than a short true one, because it trains the
user to ignore the report. Report only findings that survive the refutation
attempt, each with the file:line and why it's exploitable.

## Output

Report: functional gate result (pass/fail per check), security verdict (clean, or
the surviving findings with severity + location), and any residual risk you're
consciously accepting. If anything is red, say so plainly with the evidence —
never round a partial pass up to "done".
