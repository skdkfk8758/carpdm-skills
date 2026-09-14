#!/usr/bin/env bash
# PreToolUse hook — BLOCKING (exit 2) while the session runs on a Fable model.
#
# Policy: Fable is the interview / design / decision tier, never the
# implementation tier. Implementation and token-heavy tools are refused in the
# Fable session itself; the model must delegate to Agent(model: sonnet|opus|
# haiku) instead. Explicit opt-in markers bypass the gate for a session.
#
# Blocked on Fable:
#   Edit | Write | NotebookEdit         — any file mutation (see exemptions)
#   Agent                               — unless tool_input.model is a
#                                         non-Fable model (sonnet/opus/haiku),
#                                         or subagent_type names a definition in
#                                         ~/.claude/agents/ whose frontmatter
#                                         pins a non-Fable model;
#                                         subagent_type "fork" always blocked
#   Workflow                            — always (spawns many agents)
#   Bash                                — only heavy/mutating commands
#                                         (build/test/install/commit/push/
#                                         migrate/deploy). Read-only shell
#                                         stays allowed for interviewing.
#
# Exempt paths (lightweight config / memory writes that the harness itself
# requires): ~/.claude/**  and  the session scratchpad (/private/tmp/claude-*).
#
# Opt-out (in priority order):
#   FABLE_GATE_DISABLE=1                      env, whole machine
#   ~/.claude/.allow-fable-work               marker, all sessions (remove after)
#   /tmp/fable-gate-allow-<session_id>        marker, this session only
#
# Companion: guard-fable-prompt-nudge.sh (UserPromptSubmit) injects the
# interview-first instruction so the model asks instead of hitting this wall.

[ "${FABLE_GATE_DISABLE:-0}" = "1" ] && exit 0
[ -f "$HOME/.claude/.allow-fable-work" ] && exit 0

INPUT=$(cat)
# Debug: `touch /tmp/fable-gate-debug` to dump every hook payload (remove marker after).
[ -f /tmp/fable-gate-debug ] && printf '%s\n---\n' "$INPUT" >> /tmp/fable-gate-debug.log
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

printf '%s' "$INPUT" | bash "$HERE/fable-model-detect.sh" --is-fable || exit 0

SID=$(printf '%s' "$INPUT" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:[[:space:]]*"//; s/"$//')
[ -n "$SID" ] && [ -f "/tmp/fable-gate-allow-$SID" ] && exit 0

TOOL=$(printf '%s' "$INPUT" | grep -o '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:[[:space:]]*"//; s/"$//')

# $1 = agent name -> `model:` from ~/.claude/agents/<name>.md frontmatter, or empty.
# Path characters are refused so a crafted subagent_type cannot escape the dir.
agent_def_model() {
  case "$1" in
    ""|*/*|*..*|.*) return ;;
  esac
  ADF="$HOME/.claude/agents/$1.md"
  [ -f "$ADF" ] || return
  sed -n '/^---$/,/^---$/p' "$ADF" 2>/dev/null | grep -m1 '^model:' \
    | sed 's/^model:[[:space:]]*//; s/[[:space:]]*$//'
}

block() {
  cat >&2 <<MSG
[fable-gate] 차단: $1
Fable 모델은 인터뷰·설계·결정 전용입니다. 구현/고비용 작업은 모델을 바꾼 뒤 진행하세요.
  경로 1) 위임(1순위):  Agent(subagent_type: scout|editor|fixer|implementer|reviewer, prompt: <자기완결 실행 프롬프트>) — 모델은 에이전트 정의에 박혀 있다 (라우팅표: ~/.claude/rules-ondemand/fable-delegation.md)
  경로 1b) 위임(예외):  Agent(model: sonnet|opus|haiku, subagent_type: general-purpose, prompt: <…>) — 이 세션의 /model 전환은 하지 않는다
  경로 2) Fable 로 강행(사용자 명시 요청 시만):  touch /tmp/fable-gate-allow-${SID:-<session_id>}
지금 할 일: AskUserQuestion 으로 (a) 요구사항 인터뷰를 마치고 (b) 실행 모델을 물은 뒤 (c) 그 모델의 Agent 에 위임한다.
MSG
  exit 2
}

case "$TOOL" in
  Edit|Write|NotebookEdit)
    FP=$(printf '%s' "$INPUT" | grep -o '"\(file_path\|notebook_path\)"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:[[:space:]]*"//; s/"$//')
    case "$FP" in
      "$HOME"/.claude/*|/private/tmp/claude-*|/tmp/claude-*) exit 0 ;;
    esac
    block "$TOOL → ${FP:-?}"
    ;;
  Agent)
    # Read model/subagent_type from the tool_input slice only — the payload's
    # top-level `model` is the PARENT session's and must never grant a pass.
    TI="${INPUT#*\"tool_input\"}"
    ST=$(printf '%s' "$TI" | grep -o '"subagent_type"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:[[:space:]]*"//; s/"$//')
    [ "$ST" = "fork" ] && block "Agent(fork) — fork 는 항상 Fable 로 돈다"
    AM=$(printf '%s' "$TI" | grep -o '"model"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:[[:space:]]*"//; s/"$//')
    if [ -n "$AM" ]; then
      # Explicit model wins, and an explicit Fable model is always refused.
      case "$AM" in
        *fable*) block "Agent(model: $AM) — Fable 워커는 게이트의 목적을 무력화한다" ;;
        sonnet|opus|haiku|claude-sonnet*|claude-opus*|claude-haiku*) exit 0 ;;
      esac
      block "Agent — tool_input.model=$AM 은 허용 모델이 아니다"
    fi
    # No explicit model: accept only a named agent whose definition pins one.
    DM=$(agent_def_model "$ST")
    case "$DM" in
      sonnet|opus|haiku|claude-sonnet*|claude-opus*|claude-haiku*) exit 0 ;;
    esac
    block "Agent — model 미지정이고 subagent_type=${ST:-?} 의 정의에서 모델을 확인할 수 없음"
    ;;
  Workflow)
    block "Workflow — 다중 에이전트 오케스트레이션"
    ;;
  Bash)
    CMD=$(printf '%s' "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:[[:space:]]*"//; s/"$//')
    HEAVY='(^|[;&| ])(make |npm (install|ci|run|test|build)|pnpm |yarn |npx |uv (run|sync)|pytest|vitest|jest|cargo (build|test|run)|go (build|test)|docker (build|compose)|kubectl apply|terraform apply|alembic upgrade|git (commit|push|merge|rebase|cherry-pick)|gh pr (create|merge)|glab mr (create|merge))'
    if printf '%s' "$CMD" | grep -Eq "$HEAVY"; then
      block "Bash(무거운/변경 명령) → ${CMD:0:80}"
    fi
    exit 0
    ;;
esac
exit 0
