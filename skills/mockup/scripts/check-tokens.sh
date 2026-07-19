#!/usr/bin/env bash
# check-tokens.sh — mockup token-subset check (design-context.md §5).
# Verifies every hex color in a mockup HTML belongs to the extracted token set.
# Usage: check-tokens.sh <mockup.html> <tokens.txt>
#   tokens.txt: one allowed color per line (hex; # optional; case-insensitive).
# Lines marked `non-token:` in the mockup are exempt (declared exceptions).
# Exit 0 = clean, exit 1 = violations (printed), exit 2 = usage error.
set -u

[ "$#" -eq 2 ] || { echo "usage: check-tokens.sh <mockup.html> <tokens.txt>" >&2; exit 2; }
MOCKUP="$1"; TOKENS="$2"
[ -f "$MOCKUP" ] || { echo "missing mockup: $MOCKUP" >&2; exit 2; }
[ -f "$TOKENS" ] || { echo "missing tokens: $TOKENS" >&2; exit 2; }

# normalize: lowercase, strip leading #, expand 3/4-digit hex to 6/8-digit
normalize() {
  local h
  h="$(printf %s "$1" | tr 'A-F' 'a-f')"; h="${h#\#}"
  if [ "${#h}" -eq 3 ] || [ "${#h}" -eq 4 ]; then
    local out="" i c
    for ((i = 0; i < ${#h}; i++)); do c="${h:i:1}"; out+="$c$c"; done
    h="$out"
  fi
  printf %s "$h"
}

ALLOWED="$(mktemp)"; trap 'rm -f "$ALLOWED"' EXIT
while IFS= read -r line; do
  line="${line%%#*[!0-9a-fA-F]*}"  # keep hex-ish content only via later grep
  for tok in $(printf %s "$line" | grep -oE '#?[0-9a-fA-F]{3,8}\b' || true); do
    # only accept plausible hex lengths (3,4,6,8)
    raw="${tok#\#}"
    case "${#raw}" in 3|4|6|8) normalize "$tok" >> "$ALLOWED"; echo >> "$ALLOWED" ;; esac
  done
done < "$TOKENS"
sort -u "$ALLOWED" -o "$ALLOWED"
[ -s "$ALLOWED" ] || { echo "token set is empty — check $TOKENS" >&2; exit 2; }

viol=0
# scan mockup line by line so exempt lines can be skipped and violations located
n=0
while IFS= read -r line; do
  n=$((n + 1))
  case "$line" in *non-token:*) continue ;; esac
  for hex in $(printf %s "$line" | grep -oE '#[0-9a-fA-F]{3,8}\b' || true); do
    raw="${hex#\#}"
    case "${#raw}" in 3|4|6|8) : ;; *) continue ;; esac
    norm="$(normalize "$hex")"
    if ! grep -qxF "$norm" "$ALLOWED"; then
      echo "L$n: $hex (non-token)"
      viol=$((viol + 1))
    fi
  done
done < "$MOCKUP"

if [ "$viol" -gt 0 ]; then
  echo "FAIL: $viol non-token color(s) — fix or mark 'non-token: <reason>' with justification"
  exit 1
fi
echo "OK: all colors in token set"
exit 0
