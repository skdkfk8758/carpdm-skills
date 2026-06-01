# Adversarial Plan Review via Codex

Phase 2 hands the finished Phase-1 plan to codex as a hostile reviewer. Codex is
a second model with no stake in your plan — that independence is the whole value.
Its job is to find what's wrong before any code exists, where fixes are cheap.

## How to invoke

Use the **`codex:rescue`** skill (via the `Skill` tool). It forwards your prompt
to a single codex `task` run. Two things matter:

1. **Keep it read-only.** The rescue runtime defaults to write-capable codex
   unless your prompt clearly asks for review-only. So your prompt MUST say, in
   plain words, *"Review and critique only. Do not edit, create, or delete any
   files."* That keeps codex out of your working tree during planning.
2. **Point codex at the plan file** by path so it reads the actual document
   rather than your summary of it.

## Prompt shape

Codex responds best to compact, XML-tagged operator prompts. Adapt:

```
<task>
Adversarially review the implementation plan at <plan-path>. Your job is to find
what is WRONG with it before any code is written. Be hostile but specific.
Review and critique only — do NOT edit, create, or delete any files.
</task>

<look_for>
- Hidden or unstated assumptions that, if false, break the plan
- Missing edge cases / failure modes
- Security holes (injection, authz gaps, secret/host exposure, unsafe input)
- A materially simpler approach that reaches the same goal
- Scope creep — steps not justified by the stated goal
- Steps whose "verify" check does not actually prove the step
- Architecture decisions: does the plan make a hard-to-reverse decision that
  should be recorded as an ADR? Does it conflict with a standing ADR?
</look_for>

<grounding_rules>
Cite the specific plan section for every finding. If something is a hypothesis,
say so. Do not invent problems to seem thorough.
</grounding_rules>

<structured_output_contract>
Return two lists:
1. BLOCKING — must be resolved before implementation, each with the section it
   refers to and a concrete suggested fix.
2. NON-BLOCKING — worth considering, same format.
If the plan is sound, say so plainly and return empty lists.
</structured_output_contract>
```

## After codex responds

- Triage: fold every **BLOCKING** finding into the plan (revise the relevant
  section). Decide per NON-BLOCKING item whether to adopt it; note the decision.
- Record the outcome in the plan: `## Codex review — round N: <verdict + what changed>`.
- **Re-review** the revised plan if you made non-trivial changes. Stop after no
  blocking objection remains, or after 2 rounds (diminishing returns past that).
- If codex and you disagree, surface it to the user with both arguments — don't
  silently override the adversary, and don't blindly obey it.

## Anti-patterns

- Letting codex edit files during a *plan* review (forgot the read-only line).
- Pasting codex's output into the plan verbatim instead of resolving each item.
- One round and done when round 1 surfaced real structural problems.
- Treating every NON-BLOCKING nit as mandatory → scope creep the plan didn't ask
  for.
