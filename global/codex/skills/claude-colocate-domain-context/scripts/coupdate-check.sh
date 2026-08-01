#!/usr/bin/env bash
# colocate-domain-context — co-update warning gate.
#
# Warns when an ENROLLED domain's code changed but its CLAUDE.md did not.
#   enrolled = a domain directory (immediate child of a ROOT) that contains a CLAUDE.md.
# Enrollment is auto-discovered (no hardcoded domain list): documenting a domain =
# dropping a CLAUDE.md in its folder. Un-documented domains are never flagged, so
# false positives are zero by construction.
#
# Usage:
#   coupdate-check.sh [--strict] [--ext "ts,tsx,py,go"] ROOT [ROOT ...]
#     ROOT     a directory whose immediate children are domains
#              (e.g. apps/api/src/modules  apps/web/src/components  src/features)
#     --strict exit 1 on drift (blocking). Default: warn and exit 0 (non-blocking).
#     --ext    comma-separated source extensions that count as "code"
#              (default covers common languages).
#
# Change set = working tree + staged + untracked, repo-root-relative.
# Exit: 0 = no drift (or warning-only). 1 = drift under --strict. 2 = usage error.

set -euo pipefail

STRICT=0
EXT="ts,tsx,js,jsx,mjs,cjs,py,go,rs,rb,java,kt,kts,php,cs,swift,scala,vue,svelte"
ROOTS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --strict) STRICT=1; shift ;;
    --ext)    EXT="${2:?--ext needs a value}"; shift 2 ;;
    --help|-h)
      sed -n '2,20p' "$0"; exit 0 ;;
    -*) echo "coupdate-check: unknown flag $1" >&2; exit 2 ;;
    *)  ROOTS+=("$1"); shift ;;
  esac
done

[ "${#ROOTS[@]}" -gt 0 ] || {
  echo "usage: coupdate-check.sh [--strict] [--ext csv] ROOT [ROOT ...]" >&2
  exit 2
}

# Change set (repo-root-relative). Tolerate non-git / empty gracefully.
CHANGED=$(
  {
    git diff --name-only HEAD 2>/dev/null || true
    git diff --cached --name-only 2>/dev/null || true
    git ls-files --others --exclude-standard 2>/dev/null || true
  } | sort -u
)

EXT_RE=$(printf '%s' "$EXT" | sed 's/,/|/g')
WARN=""

for root in "${ROOTS[@]}"; do
  [ -d "$root" ] || continue
  while IFS= read -r md; do
    [ -n "$md" ] || continue
    d=$(dirname "$md")
    code=$(printf '%s\n' "$CHANGED" \
      | { grep -E "^$d/" || true; } \
      | { grep -vE "^$d/CLAUDE\.md$" || true; } \
      | { grep -E "\.($EXT_RE)$" || true; })
    mdchg=$(printf '%s\n' "$CHANGED" | { grep -E "^$d/CLAUDE\.md$" || true; })
    if [ -n "$code" ] && [ -z "$mdchg" ]; then
      WARN="${WARN}  ${d}/ code changed — ${d}/CLAUDE.md not updated"$'\n'
    fi
  done < <(find "$root" -mindepth 2 -maxdepth 2 -name CLAUDE.md 2>/dev/null)
done

if [ -n "$WARN" ]; then
  printf "\033[1;33m⚠ domain CLAUDE.md co-update — knowledge may be stale:\033[0m\n%b" "$WARN"
  printf "  Update the domain CLAUDE.md in the same change, or ignore if the domain\n"
  printf "  knowledge did not actually change. (warning only — not blocking)\n"
  [ "$STRICT" = "1" ] && exit 1
fi
exit 0
