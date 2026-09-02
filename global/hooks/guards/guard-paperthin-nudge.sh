#!/usr/bin/env bash
# PostToolUse hook (Write|Edit): route judgment artifacts to the paperthin
# skills the model can NEVER self-invoke (disable-model-invocation: true).
#
# Scope, honestly: 16 of the 28 paperthin skills carry their own description
# and already self-trigger; this hook says nothing about those. The 12 marked
# user-invoked are invisible unless someone types the slash command, so this
# hook is the only place they can surface at the moment they apply.
# Non-blocking, one nudge per (session, file) — iterative edits stay quiet.
# SSOT: ~/.claude/rules-ondemand/paperthin-routing.md
# Disable: GUARD_PAPERTHIN_NUDGE_DISABLE=1

[ "${GUARD_PAPERTHIN_NUDGE_DISABLE:-0}" = "1" ] && exit 0

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"//' | sed 's/"$//')
SESSION=$(echo "$INPUT" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"session_id"[[:space:]]*:[[:space:]]*"//' | sed 's/"$//')

[ -z "$FILE_PATH" ] && exit 0
[ -f "$FILE_PATH" ] || exit 0
case "$FILE_PATH" in *.md) ;; *) exit 0 ;; esac

# The routing rule itself and paperthin's own SKILL.md files are not emissions.
case "$FILE_PATH" in
  */rules-ondemand/paperthin-routing.md) exit 0 ;;
  */.agents/skills/*|*/.claude/skills/*) exit 0 ;;
esac

kind=""
# Judgment artifact — a plan/spec/design/ADR is a decision about to be acted on.
if echo "$FILE_PATH" | grep -qiE '(docs/(specs|plans|reviews)/|\.planning/|wiki/adr/|(^|/)(SPEC|PLAN|DESIGN|ADR|RFC)[^/]*\.md$|-(plan|spec|design|proposal)\.md$)'; then
  kind="decision"
else
  # Prose hygiene — only once a doc has actually grown; small docs are fine.
  LINES=$(wc -l < "$FILE_PATH" 2>/dev/null | tr -d ' ')
  case "$LINES" in ''|*[!0-9]*) exit 0 ;; esac
  if [ "$LINES" -gt 200 ] && echo "$FILE_PATH" | grep -qiE '(docs/|wiki/|(^|/)README\.md$)'; then
    kind="prose"
  fi
fi
[ -z "$kind" ] && exit 0

# One nudge per (session, file) — re-editing the same plan must not re-fire.
STATE_DIR="${TMPDIR:-/tmp}/paperthin-nudge"
mkdir -p "$STATE_DIR" 2>/dev/null || exit 0
STAMP="$STATE_DIR/$(printf '%s|%s|%s' "${SESSION:-nosession}" "$kind" "$FILE_PATH" | shasum | cut -d' ' -f1)"
[ -e "$STAMP" ] && exit 0
: > "$STAMP" 2>/dev/null

NAME="${FILE_PATH##*/}"
if [ "$kind" = "decision" ]; then
  echo "[guard-paperthin] 판단 산출물 감지: $NAME — 확정 전에 검증 스킬 하나를 사용자에게 제안할 것 (모델이 스스로 못 부른다, 사용자가 타이핑해야 함)" >&2
  echo "  /hate     — 급소 반박 1개 + 그게 진짜인지 증명할 최소 실험. 계획을 밀기 직전" >&2
  echo "  /prism    — 실패 모드가 이질적일 때(정확성·보안·비용·악의적 사용자) 2~5 렌즈 수렴/불일치" >&2
  echo "  /feynman  — 방금 고른 선택지를 회의론자에게 설명 못 하는 지점 색출. 결정 직후" >&2
  echo "  /macrothink — 세션이 한 방향으로 굳었다고 의심될 때 fresh read 팬아웃" >&2
  echo "  하나만 골라 '왜 이것인지' 한 줄과 함께 제안한다. 전부 나열해 사용자에게 고르라 미루지 말 것." >&2
else
  echo "[guard-paperthin] 문서 비대 감지: $NAME — 내용이 맞다면 재작성 말고 압축을 제안할 것" >&2
  echo "  /debloat  — 패딩·중복 재진술 제거, 의미 보존" >&2
  echo "  /reorder  — 순서가 임의로 흐트러진 목록·섹션을 한 원칙으로 재배열(내용 불변)" >&2
fi
echo "  SSOT: ~/.claude/rules-ondemand/paperthin-routing.md" >&2

exit 0
