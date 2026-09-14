#!/usr/bin/env bash
# UserPromptSubmit hook — injects the "Fable = interview only" instruction into
# the model's context on every prompt while a Fable model is active. Non-blocking.
# The hard stop lives in guard-fable-cost-gate.sh (PreToolUse); this hook exists
# so the model plans around the gate instead of colliding with it.
#
# Silent when: not Fable, FABLE_GATE_DISABLE=1, or an opt-in marker exists.

[ "${FABLE_GATE_DISABLE:-0}" = "1" ] && exit 0
[ -f "$HOME/.claude/.allow-fable-work" ] && exit 0

INPUT=$(cat)
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOLVED=$(printf '%s' "$INPUT" | bash "$HERE/fable-model-detect.sh" --with-source)
MODEL=${RESOLVED%%	*}
SOURCE=${RESOLVED##*	}
case "$MODEL" in *fable*) ;; *) exit 0 ;; esac

SID=$(printf '%s' "$INPUT" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:[[:space:]]*"//; s/"$//')
[ -n "$SID" ] && [ -f "/tmp/fable-gate-allow-$SID" ] && exit 0

BODY='이 세션은 인터뷰·설계·결정 전용이다 — 구현·대량 탐색·테스트 실행·커밋을 직접 하지 않고 `/model` 로 전환하지도 않는다. 절차(인터뷰 → 자기완결 실행 프롬프트 → 라우팅표로 에이전트 선택 → 위임 → §A 보고)·라우팅표·게이트 해제 조건은 `~/.claude/rules-ondemand/fable-delegation.md` §0–§2 가 SSOT 다 — 이 세션에서 아직 안 읽었으면 위임·구현 판단 전에 Read 한다. Edit/Write/Agent(모델 미확인)/Workflow/무거운 Bash 는 훅이 차단 — 우회 금지. 질문·설명·~/.claude 편집은 그대로 진행한다.'

if [ "$SOURCE" = "settings" ]; then
  # No session evidence yet (first prompt before any assistant turn) — the
  # only hint is the saved default. Let the model self-check instead of
  # asserting: a `claude -p --model sonnet` run must not act as Fable.
  HEAD='[fable-gate] 세션 증거가 아직 없어 저장된 기본 모델(Fable)로 추정한다. **현재 모델이 Fable(claude-fable-*)이 아니면 이 문단을 무시하고 평소대로 작업한다.** Fable 이면: '
else
  HEAD='[fable-gate] 현재 모델은 Fable 이다. '
fi

python3 - "$HEAD$BODY" <<'PY'
import json, sys
print(json.dumps({"hookSpecificOutput": {"hookEventName": "UserPromptSubmit",
      "additionalContext": sys.argv[1]}}, ensure_ascii=False))
PY
exit 0
