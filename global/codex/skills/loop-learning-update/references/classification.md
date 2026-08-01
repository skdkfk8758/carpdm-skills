# Learning Classification

Use this table to decide where a learning belongs.

| Evidence pattern | Classification | Target |
| --- | --- | --- |
| One-off failure caused by current task details | Task-local note | Current plan, ledger, or final response only |
| Repeated repo-specific mistake | Project guidance candidate | Project `AGENTS.md`, local rules, or repo docs after approval |
| Repeated agent workflow mistake across repos | Global skill improvement candidate | Relevant global skill after approval |
| Manual process repeatedly produces the same error | Tooling/script improvement candidate | Script, template, or deterministic checklist after approval |
| Failure was caused by missing facts, not bad guidance | No durable update | Improve current investigation, not instructions |
| Proposed rule would be broader than the evidence | No durable update or local note | Avoid global overfitting |

## Generalization Questions

- Did this happen more than once?
- Would the fix help in a different repository?
- Is the learning about behavior, process, tooling, or domain facts?
- Would applying it globally create false positives or unnecessary friction?
- Can the proposed rule be stated narrowly enough to avoid overfitting?

## Minimum Evidence

Use at least one concrete artifact:

- failed command and relevant output
- review finding
- diff that caused the failure
- loop ledger entry
- test or QA artifact
- user-provided retrospective

Avoid durable updates when the only evidence is a vague impression.

