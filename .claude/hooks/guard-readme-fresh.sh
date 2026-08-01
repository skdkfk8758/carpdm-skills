#!/usr/bin/env bash
# PreToolUse(Bash) guard: before `gh pr create`, ensure README.md agrees with the
# skills/ inventory. Blocks (exit 2) with an actionable message if stale.
#
# Judgment logic lives in scripts/ci/catalog.js (SSOT — the same check CI runs:
# link presence + stale references + count claims). This hook is the fast local
# feedback at the moment a PR is opened; CI is the server-side gate. The inline
# grep loop below is only a fallback for environments without node.
#
# Override: README_FRESH_DISABLE=1
set -euo pipefail

[ "${README_FRESH_DISABLE:-0}" = "1" ] && exit 0

ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
INPUT="$(cat)"

# Act on outbound moments: `gh pr create` AND `git push` — a red that only CI
# can see costs a full round-trip (PR #159: invisible-char hit found post-push).
CMD="$(printf '%s' "$INPUT" \
  | python3 -c 'import sys,json; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null || true)"
case "$CMD" in
  *"gh pr create"*|*"git push"*) ;;
  *) exit 0 ;;
esac

README="$ROOT/README.md"
[ -f "$README" ] || exit 0
[ -d "$ROOT/skills" ] || exit 0

# Preferred path: run the full CI validate suite locally (same scripts CI runs —
# catalog + skill frontmatter + invisible chars; all node-only, <1s total).
if command -v node >/dev/null 2>&1 && [ -f "$ROOT/scripts/ci/catalog.js" ]; then
  fail=0; outs=""
  for s in validate-skills.js check-invisible-chars.js catalog.js; do
    [ -f "$ROOT/scripts/ci/$s" ] || continue
    if ! out="$(node "$ROOT/scripts/ci/$s" 2>&1)"; then fail=1; outs="$outs
$out"; fi
  done
  [ "$fail" = 0 ] && exit 0
  echo "[guard-readme-fresh] BLOCKED: 로컬 CI 검증 실패 — push/PR 전에 고치세요:" >&2
  echo "$outs" >&2
  echo "[guard-readme-fresh] override: README_FRESH_DISABLE=1" >&2
  exit 2
fi

# Fallback (node 없음): link-presence check only.
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
