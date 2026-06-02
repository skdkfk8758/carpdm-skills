#!/usr/bin/env bash
# PreToolUse(Bash) guard: before `gh pr create`, ensure README.md references every
# skill directory under skills/. Blocks (exit 2) with an actionable message if the
# README is stale (a skill dir exists but isn't linked in README). This keeps the
# README skill table in sync with what actually ships, checked at the moment a PR
# is opened.
#
# Override: README_FRESH_DISABLE=1
set -euo pipefail

[ "${README_FRESH_DISABLE:-0}" = "1" ] && exit 0

ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
INPUT="$(cat)"

# Only act on a real `gh pr create` invocation.
CMD="$(printf '%s' "$INPUT" \
  | python3 -c 'import sys,json; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null || true)"
case "$CMD" in
  *"gh pr create"*) ;;
  *) exit 0 ;;
esac

README="$ROOT/README.md"
[ -f "$README" ] || exit 0
[ -d "$ROOT/skills" ] || exit 0

missing=()
for d in "$ROOT"/skills/*/; do
  [ -d "$d" ] || continue
  name="$(basename "$d")"
  # A skill is "documented" if README links its directory (skills/<name>).
  grep -q "skills/$name" "$README" || missing+=("$name")
done

if [ ${#missing[@]} -gt 0 ]; then
  echo "[guard-readme-fresh] BLOCKED: README.md 가 stale — 다음 스킬이 README 에 없음: ${missing[*]}" >&2
  echo "[guard-readme-fresh] PR 전에 README.md 스킬 표/카운트를 갱신하세요." >&2
  echo "[guard-readme-fresh] override: README_FRESH_DISABLE=1" >&2
  exit 2
fi
exit 0
