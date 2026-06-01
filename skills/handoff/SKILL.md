---
name: handoff
description: Use this skill whenever work needs to survive a session boundary — either saving state before stopping, or picking it back up later. SAVE — the user is wrapping up, pausing, or interrupting mid-task (a meeting, low context, end of day) and wants their progress, what's left, which files they touched, and WHY they decided things written down so a later session (tomorrow, another window, another person, their future self) can resume cold; e.g. "여기까지 하자 내일 이어서", "context 날아가기 전에 저장", "중단해야 되는데 상태랑 결정 남겨줘", "이유까지 기록", "남은거 정리해줘", "save progress", "핸드오프". RESUME — at session start the user wants to continue unfinished work and asks where they left off; e.g. "어디까지 했지", "이어서 하자", "마지막 세션 복원", "뭐 하다 멈췄지", "resume", "continue where we left off" — load the latest handoff first. The skill auto-detects direction (WRITE a dump vs READ a resume). Note — a concrete task name (a feature, a benchmark, a file) plus "이어서/어디까지/저장/남겨줘" still means handoff, NOT a new build (forge), fix (hunt), or change (renew). NOT for durable facts (those go to memory), meeting notes, project docs, or SPEC/PLAN authoring.
---

# Handoff — freeze a session so another can pick it up cold

A handoff document is the bridge between two sessions that share no context. The
receiving session starts at zero — no transcript, no memory of decisions, no idea
which files are half-edited. Your job is to make that cold start cheap: capture
*what was decided and why*, *what is in flight*, and *what to do next* tightly
enough that a fresh agent can resume in one read.

Two directions, auto-detected from the user's ask:

| Direction | Triggers | What you do |
|---|---|---|
| **WRITE** (dump) | "핸드오프", "정리해줘", "마무리", "넘겨줘", end of session | Distill the session into a handoff doc |
| **READ** (resume) | "이어서", "resume", "어디까지 했지", "핸드오프 읽어", session start | Load the latest handoff and restore context |

If the ask is ambiguous (e.g. just "핸드오프"), default by context: a session
with work already done leans WRITE; a session that just started leans READ. When
genuinely unsure, ask one short question.

## Handoff is not memory, and not a SPEC

These three are easy to confuse — keep them separate or you create drift:

- **Memory** (`~/.claude/projects/<slug>/memory/`) = durable *facts* that outlive
  the task — coordinate systems, API quirks, user preferences. Narrow, long-lived.
- **Handoff** (`docs/handoff/`) = a *work snapshot* — what's in flight right now.
  Broad, short-lived. Once the work lands, the handoff is stale → delete it (YAGNI).
- **SPEC / PLAN** (`docs/specs/`, `docs/plans/`) = the external contract and the
  intended change. Authored deliberately, not a session byproduct.

If during a WRITE you notice a durable fact worth keeping (a non-obvious gotcha,
a confirmed decision rule), write it to memory *as well* and link it from the
handoff. Don't smuggle long-lived facts into a doc that's meant to be deleted.

---

## WRITE — distilling the session

### 1. Locate the project and the handoff dir

- Project root = nearest ancestor with a `.git`. The handoff lives at
  `<root>/docs/handoff/`. Create the dir if missing — it's a standard sub-tree.
- No git repo / no project (e.g. a scratch session)? Fall back to
  `~/.claude/projects/<cwd-slug>/handoff/`. Note this in your reply so the user
  knows where it went.

**Route by where the work actually lives, not where the cwd happens to be.** A
global skill gets invoked from inside whatever project you're sitting in, so the
cwd's repo is often unrelated to what you worked on. If the session's primary
work targets files *outside* the cwd repo — global config under `~/.claude/`,
another repo, a sibling project — do NOT dump the handoff into the cwd repo's
`docs/handoff/` (that pollutes an unrelated git tree with an off-topic doc).
Instead write to the global `~/.claude/projects/<cwd-slug>/handoff/` and say so.
Only use `<cwd-root>/docs/handoff/` when the work and the cwd repo are the same
thing. When the work spans both the cwd repo and outside it, the cwd repo wins.

### 2. Pick the file — one per work-thread, not one per session

Naming: `YYYY-MM-DD-<topic>.md` (kebab topic, e.g. `2026-06-01-stay-cluster-bench`).
Use today's date from your context.

Before creating a new file, check `docs/handoff/` for an existing doc on the same
thread. If this session continued earlier work, **update that doc in place**
(refresh status, append to the log) rather than spawning a near-duplicate. A pile
of stale handoffs for one thread is noise.

### 3. Capture — curated, not a transcript dump

The receiving agent reads this once and acts. Optimize for *fast pickup*, not
completeness. Match the project's existing handoff house style (frontmatter +
sections) — read a sibling in `docs/handoff/` first if any exist.

Write the doc in the session's working language (Korean for this user).

```markdown
---
title: <one-line what-and-why>
type: handoff
created: YYYY-MM-DD
branch: <current branch>
base: <base branch, if on a feature branch>
spec: <SPEC-ID if this work has one, else omit>
status: in-progress | blocked | ready-to-merge
---

# <topic> — 핸드오프

## TL;DR
3-5 bullets. The goal, where it stands, the single most important next move.
Someone who reads ONLY this should know what to do next.

## Done (this session)
- <completed item> — <commit hash if committed>
- ...

## In progress
- <file path> — <what's half-done and the intent>. Why it's not finished yet.

## Next steps
Phrase as verifiable goals, not vague verbs:
1. <step> → verify: <how you'll know it's done>
2. ...

## Key decisions & why
The rationale is the thing most easily lost across sessions. For each non-obvious
choice: what was decided, what was rejected, and WHY. This is what stops the next
agent from re-litigating settled questions or undoing them blindly.

## Open questions / blockers
- <unresolved thing> — what's needed to unblock, who/what decides.

## Touched files
Paths only (the next agent has Read) — group by area. Don't paste file contents.

## Resume command
Exact steps to get a working session back: branch checkout, dev boot, the one
command to re-run the thing you were testing.
```

### 4. Discipline

- **Paths, not contents.** Never paste large file bodies, full diffs, or test
  logs into the handoff. The next agent reads from disk. Reference `file:line`.
- **No secrets.** Never copy `.env` values, tokens, or credentials into the doc —
  it may be git-tracked and shared.
- **Honest status.** If tests are failing or a step was skipped, say so in the doc.
  A handoff that hides breakage costs the next session more than it saves.
- **Link, don't duplicate.** Point to the SPEC/PLAN/ADR/memory rather than copying
  their content. The handoff is a pointer-rich index, not a mirror.

After writing, tell the user the path and give a 2-3 line summary of what you
captured. If you also wrote a memory entry, mention it.

---

## READ — resuming from a handoff

### 1. Find the right handoff

- Look in `<root>/docs/handoff/` (then the global fallback dir). If the user named
  a topic, match it. Otherwise take the **most recent by date**, but if several are
  recent and on different threads, list them and ask which one — resuming the wrong
  thread is worse than a one-line question.

### 2. Restore context before acting

Read the handoff fully. Then *verify it against reality* — a handoff reflects the
moment it was written and may be stale:

- Confirm the branch exists and check it out (`Resume command` section).
- Spot-check `Touched files` actually match the described state (`git status`,
  `git log` since the handoff date). If the repo moved on, say so before proceeding.
- Surface any `Open questions / blockers` to the user up front — those are likely
  why the work paused.

### 3. Re-state and proceed

Give the user a short "here's where we are" recap drawn from the handoff (goal,
last state, the next step you're about to take), then continue the work. Don't
silently dive in — confirm you're resuming the thread they meant.

### 4. Close the loop

When the resumed work lands (merged, shipped, abandoned), the handoff is spent.
Delete it — keeping stale handoffs around defeats the "fast cold start" purpose
and clutters `docs/handoff/`. If part of the thread continues, update the doc to
reflect the new state instead.

---

## Anti-patterns

- Dumping the whole conversation transcript instead of distilling it — the next
  agent then has to do the distillation you skipped.
- Capturing *what* changed but not *why* — the rationale is the expensive part to
  reconstruct, and the easiest to lose.
- A handoff per session for the same ongoing thread — update in place instead.
- Leaving landed handoffs to rot in `docs/handoff/` — delete when spent.
- Pasting secrets, full diffs, or test logs into a git-tracked doc.
- Putting long-lived facts in a handoff (they vanish when it's deleted) — those
  belong in memory.
