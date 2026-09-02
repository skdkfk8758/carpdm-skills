#!/usr/bin/env bash
# Regression test for `bash sync.sh --dry-run`.
#
# Hermetic: HOME is a mktemp dir holding a fake ~/.claude/skills/<name>/ built
# from the repo copy plus one extra file, so no live ~/.claude install is
# needed (CI has none). Exit 0 of the dry-run itself proves sync-global.sh was
# NOT called: the fake HOME has no $HOME/.claude/rules/, so sync-global.sh's
# first rsync (sync-global.sh:13) would fail and `set -e` would exit non-zero.
#
#   bash scripts/ci/test-sync-dry-run.sh

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

PASS=0
FAIL=0
FAILED_CASES=()

ok() { PASS=$((PASS + 1)); printf '  ok   %s\n' "$1"; }
no() {
  FAIL=$((FAIL + 1))
  FAILED_CASES+=("$1")
  printf '  FAIL %s\n' "$1"
  [ -n "${2:-}" ] && printf '       %s\n' "$2"
}
assert_eq() { # name expected actual
  if [ "$2" = "$3" ]; then ok "$1"; else no "$1" "expected [$2] got [$3]"; fi
}

# First repo-tracked skill dir, picked dynamically — skills retire, so no name
# is hardcoded here.
name=""
for d in "$REPO_ROOT"/skills/*/; do name="$(basename "$d")"; break; done
[ -n "$name" ] || { echo "no skills/ dir in repo"; exit 1; }

TMP="$(mktemp -d)"
FAKE="$TMP/.claude/skills/$name"
mkdir -p "$FAKE"
cp -R "$REPO_ROOT/skills/$name/." "$FAKE/"
echo probe > "$FAKE/dry-run-probe.md"

before="$(git -C "$REPO_ROOT" status --porcelain)"
out="$(HOME="$TMP" bash "$REPO_ROOT/sync.sh" --dry-run 2>&1)"
rc=$?
after="$(git -C "$REPO_ROOT" status --porcelain)"

assert_eq "dry-run exits 0 (sync-global.sh not called)" 0 "$rc"

if grep -qF '>f+++++++ dry-run-probe.md' <<<"$out"; then
  ok "stdout lists the file only live has"
else
  no "stdout lists the file only live has" "$out"
fi

# -c (checksum): repo copy has fresh mtimes but identical content — must not show.
assert_eq "only the probe file is itemized" 1 "$(grep -cE '^(\*deleting|[<>]f)' <<<"$out")"

assert_eq "repo files and index unchanged" "$before" "$after"

echo "── ${PASS} passed, ${FAIL} failed ──"
if [ "$FAIL" -gt 0 ]; then
  printf 'failed: %s\n' "${FAILED_CASES[@]}"
  exit 1
fi
