#!/usr/bin/env bash
# Shared issue-id matcher for the Linear guards (branch-naming, state, acceptance).
#
# Why: the old default [A-Za-z]{2,10}-[0-9]+ matched any word-dash-number token —
# `collector-7` in `ci/adroute-collector-7d2422c0`, `main-7` in a promote commit,
# UTF-8, SHA-256 — so the state/acceptance nudges named issues that do not exist,
# and branch-naming stayed silent for names that carry no real id. Allowing only
# the team keys in linear-repo-map.json keeps every real id and drops those.
#
# Usage:
#   . "$(dirname "${BASH_SOURCE[0]}")/lib-issue-id.sh"
#   ISSUE_UC=$(printf '%s' "$TEXT" | issue_id_first)   # e.g. ADT-196, or empty
#
# Config:
#   GUARD_LINEAR_ISSUE_RE=<regex>  — override the pattern (ERE, matched case-insensitively)
#   GUARD_LINEAR_REPO_MAP=<path>   — team-key source (default ~/.claude/linear-repo-map.json)
# Without a readable map the generic pattern is the fallback.

issue_re() {
  if [ -n "$GUARD_LINEAR_ISSUE_RE" ]; then
    printf '%s' "$GUARD_LINEAR_ISSUE_RE"
    return
  fi
  local map keys
  map="$GUARD_LINEAR_REPO_MAP"
  [ -z "$map" ] && map="$HOME/.claude/linear-repo-map.json"
  keys=$(python3 -c 'import json, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(0)
ks = {r.get("teamKey") for s in ("teamRoutes", "labelRoutes") for r in d.get(s) or []}
ks |= {r.get("team") for r in d.get("projectExceptions") or []}
print("|".join(sorted(k for k in ks if isinstance(k, str) and k.isascii() and k.isalnum())))' "$map" 2>/dev/null)
  # Bounded interval — BSD grep rejects open-ended {2,}.
  if [ -n "$keys" ]; then
    printf '(%s)-[0-9]+' "$keys"
  else
    printf '%s' '[A-Za-z]{2,10}-[0-9]+'
  fi
}

_ISSUE_ID_RE=$(issue_re)

issue_id_first() { # stdin = text -> first issue id, uppercased (empty if none)
  local g=/usr/bin/grep
  [ -x "$g" ] || g=grep
  # A non-alphanumeric (or the edge) on both sides, so a key fragment inside a
  # longer token (`xadt-1`, `adt-1d2f`) does not count.
  $g -oiE "(^|[^A-Za-z0-9])(${_ISSUE_ID_RE})([^A-Za-z0-9]|\$)" | head -1 \
    | $g -oiE "$_ISSUE_ID_RE" | head -1 | tr '[:lower:]' '[:upper:]'
}
