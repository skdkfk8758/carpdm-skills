---
id: subagent-invocation
name: subagent-invocation
description: subagent 호출 시 프롬프트 구성 계약 — Phase 분할/footer/출력 제약/대용량 파일 오프로드
category: workflow
priority: critical
applies_to: [agent-call]
tracks: [T2, T3]
hooks: [PreToolUse]
related: [subagent-delegation, agent-pipeline-tracks]
overrides: []
---

# Subagent Invocation Contract

IMPORTANT: This rule governs **how** the main Claude constructs prompts when delegating to subagents. It complements `subagent-delegation.md` (which governs **when** to delegate).

## Why this exists

Subagent calls fail or truncate for five recurring reasons:

1. Output size explosion (pasting full test/build logs into reports)
2. Long-running single-call work with no checkpoint (OOM / timeout)
3. Transient network/API failures without idempotency
4. Context window collision from pasting plan bodies, past review feedback
5. MCP hook interference when Bash is used for large outputs

All five are addressable at the **prompt construction layer**. Follow this contract on every `Agent` call.

## Rules

### R1: Phase-split large work

For work that touches 6+ files OR writes 200+ new LOC OR is estimated > 10 minutes:

- Split the plan into Phases (A / B / C ...) — each Phase is **one independent Agent call**.
- The main Claude verifies the previous Phase's output on disk before invoking the next Phase.
- Do NOT bundle multiple Phases into one agent call "to save round trips". It loses more on truncation than it saves on overhead.

> **재검토 조건 (2026-08-01).** R1 의 근거(truncation·OOM·타임아웃)는 Claude 5 이전
> 실측이다. Claude 5 계열(1M 컨텍스트·long-horizon, complete-spec 단일 실행에서 최고
> 성능 — 플랫폼 프롬프팅 문서)에서는 phase-split 이 오히려 비용일 수 있다. 다음 분기
> ablation 에서 phase-split 없이 truncation/미완주 재발이 관측되지 않으면 R1 을
> 완화(의무 → 선택)한다.

### R2: Always include the invocation footer

Every `Agent` prompt MUST end with the contents of `~/.claude/agents/_templates/invocation-footer.md` (or an equivalent block). This pins output constraints, evidence paths, and abort conditions.

### R3: Slim the prompt

- Pass **file paths**, not file contents. The subagent has Read.
- Reference prior review feedback as "consolidated into plan §X" with the plan path — never paste the review body.
- Do not copy past conversation turns into the agent prompt. Subagents have no memory of this conversation — if they need context, give them a path to read.

### R4: Idempotent by default

Every prompt must instruct: "If a target file already exists and matches the spec, report `skip: already up-to-date` and move on." This makes retries cheap and safe.

### R5: Large output is offloaded to files

If the agent will run commands whose output exceeds ~20 lines (pytest, build, grep across repo), instruct it to redirect output to `logs/agents/<name>.log` (or another file under `logs/`) and then `Read` only the relevant lines. Pasting full command output back into the agent report is forbidden. Bash is for git, mkdir, rm, mv, navigation, and short-output commands only.

### R6: Route long-running work to deep-worker

If a task is estimated > 10 minutes or needs self-verification loops, call `deep-worker` instead of `executor`. deep-worker is designed around checkpointing.

### R7: Single retry policy

On verify FAIL inside an agent: the agent stops after **one** internal retry, returns a failure summary + evidence path, and lets the main Claude decide whether to re-spawn. No silent retry loops.

### R8: Status log for long-running agents (background = default, foreground = opt-in)

**Background worker/goal jobs: STATUS_LOG injection is the DEFAULT, not opt-in** — the turn
is silent while they run, so the log is the only live window (and R9's [DONE]/[FAIL] marker
depends on it). Foreground agent calls stay opt-in per the criteria below.

Inject `STATUS_LOG=<path>` into the prompt header so the agent appends progress markers to a file the user can `tail -f`:

```
${PROJECT_ROOT}/logs/agents/<subagent>-<slug>-<YYYYMMDD-HHMMSS>.status.log
```

The footer's "Status log" section drives append discipline (≤ 20 step lines, terminal `[DONE]`/`[FAIL]` marker emitted exactly once by the agent itself).

Foreground opt-in criteria (background jobs skip this — always inject):
- Long deep-worker phase (> 10 min) — user wants to watch progress.
- Multi-file refactor where step count is meaningful.
- User explicitly asked to "watch".

Skip for short executor / reviewer calls and read-only research. More than 3 agents in parallel — omit (log files become noisy).

### R9: Idle-without-report = 미완으로 간주

Worker/goal 잡이 최종 구조화 리포트(변경 파일 목록 + 실행한 테스트 + 검증 증거, R8 의 `[DONE]`/`[FAIL]` 마커) 없이 idle notification 만 보내는 경우:

- idle 2회째부터 그 잡을 **완료로 인정하지 않는다** — "idle = 아마 끝났음" 추정 금지 (실측: worker 가 idle 알림만 반복하고 최종 리포트 없이 종료 → 수동 fallback 강제).
- main 이 직접 판정한다: `git diff`/`git log` 로 실제 변경 확인 → 검증 명령 재실행 → 완료/실패 판정. worker 의 침묵이 검증 생략의 근거가 되지 않는다.
- 판정 결과와 "worker 가 리포트 없이 종료" 사실을 함께 보고한다 (도구 실패 명시 — `browser-verify-fallback.md` 3항과 동형).
- **no-op 도 리포트 대상** — 잡이 아무것도 안 바꿨으면 "변경 0 + 이유"를 명시 리포트한다. 조용한 no-op 종료는 건강하지 않은 게 아니라 **리포트 없는 no-op** 이 미완이다. 같은 사실을 매 라운드 재발견하는 잡은 상태 기록 누락 신호.
- **반복·상시 잡은 은퇴 조건 명시** — cron/loop/goal 류 지속 잡은 프롬프트에 "이 잡이 언제 폐지되는가"(목표 달성 조건 또는 재검토 시점)를 포함한다. 은퇴 조건 없는 상시 잡은 잊힌 채 돌며 비용만 낸다.

## Prompt shape (canonical)

```
<Task statement — 1-3 sentences>

## Context
- Plan: <path to docs/plans/...md>
- Scope: Phase <X> of the plan only
- Files expected to change: <explicit list, ≤ 5 unless justified>

## Instructions
<step-by-step, referencing paths not bodies>

## Verify
<exact commands, in order, with SKIP rules>

<<< paste invocation-footer.md here >>>
```

## Applies when

- Any call to the `Agent` tool for implementation / refactor / test / research work.
- Does not apply to `Explore` / `Plan` reads for quick lookups (those are self-bounded).

## Anti-patterns

- Bundling Phase A+B+C into one executor call "because they're related"
- Pasting the full plan body into the agent prompt
- Quoting pytest / tsc output line-by-line back into the agent report
- Telling the agent "retry until it works" (creates silent infinite loops)
- Forgetting the invocation footer "just this once" (this is the most common drift)
