#!/usr/bin/env bash
# init-project.sh — install the project template set into a target directory.
#
# Usage: init-project.sh <target-dir> [--sub <subdir>...]
#
# --sub <subdir>  additionally install the monorepo sub-folder templates
#                 (sub/AGENTS.md, sub/CLAUDE.md) into <target-dir>/<subdir>.
#                 Repeatable, e.g. --sub apps/web --sub apps/api.
#
# Never overwrites an existing file: prints "SKIP" and moves on, so re-running
# on a live project is safe. Performs no delete operation of any kind.
set -euo pipefail

usage() {
  echo "usage: $(basename "$0") <target-dir> [--sub <subdir>...]" >&2
  exit 2
}

[ "$#" -ge 1 ] || usage
TARGET="$1"
shift

SUBDIRS=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --sub)
      [ "$#" -ge 2 ] || usage
      SUBDIRS+=("$2")
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

# Template root is the parent of this script's directory.
SRC="$(cd "$(dirname "$0")/.." && pwd)"

FILES=(
  "AGENTS.md"
  "CLAUDE.md"
  ".claude/settings.json"
  "docs/adr/README.md"
  "docs/adr/0000-template.md"
  "prompts/01-design-session.md"
  "prompts/02-step-execution.md"
  "prompts/03-council-review.md"
  "prompts/04-council-research.md"
)

# A pre-existing CLAUDE.md that is not the "@AGENTS.md" pointer is left alone;
# only AGENTS.md lands and the operator is told what to wire up by hand.
claude_conflict=0
if [ -f "$TARGET/CLAUDE.md" ] && ! grep -q '^@AGENTS\.md' "$TARGET/CLAUDE.md"; then
  claude_conflict=1
fi

mkdir -p "$TARGET/docs/adr"

for rel in "${FILES[@]}"; do
  src="$SRC/$rel"
  dest="$TARGET/$rel"
  if [ ! -f "$src" ]; then
    echo "MISS  $rel (템플릿 원본 없음: $src)" >&2
    exit 1
  fi
  if [ -e "$dest" ]; then
    echo "SKIP  $rel (이미 있음 — 덮어쓰지 않음)"
    continue
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  echo "COPY  $rel"
done

SUB_FILES=("sub/AGENTS.md" "sub/CLAUDE.md")
for subdir in "${SUBDIRS[@]:-}"; do
  [ -n "$subdir" ] || continue
  for rel in "${SUB_FILES[@]}"; do
    src="$SRC/$rel"
    dest="$TARGET/$subdir/$(basename "$rel")"
    if [ ! -f "$src" ]; then
      echo "MISS  $rel (템플릿 원본 없음: $src)" >&2
      exit 1
    fi
    if [ -e "$dest" ]; then
      echo "SKIP  $subdir/$(basename "$rel") (이미 있음 — 덮어쓰지 않음)"
      continue
    fi
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    echo "COPY  $subdir/$(basename "$rel")"
  done
done

echo
if [ "$claude_conflict" -eq 1 ]; then
  echo "NOTE  기존 CLAUDE.md 가 '@AGENTS.md' 포인터가 아니다 — 건드리지 않았다."
  echo "      내용을 AGENTS.md 로 옮기고 CLAUDE.md 는 '@AGENTS.md' 한 줄로 줄일 것."
fi
echo "DONE  $TARGET"
echo "다음: AGENTS.md 의 <...> placeholder 를 채우고,"
echo "      docs/adr/0000-template.md 를 복사해 첫 ADR(0001-)을 쓴다."
