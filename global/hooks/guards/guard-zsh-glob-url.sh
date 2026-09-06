#!/usr/bin/env bash
# PreToolUse hook (Bash): Warn when a URL/path argument carrying `?` or `*`
# is passed unquoted — zsh globs it and the command dies before it runs.
# NON-BLOCKING — exit 0 + stderr only (guard-linear-register-nudge pattern).
#
# Why: measured incident (2026-09-05) — `gh api repos/o/r/git/trees/HEAD?recursive=1`
# failed 3x in one session with `zsh: no matches found`, costing 3 round trips.
# The shell here is zsh, where `?` and `*` are glob metacharacters even inside
# an argument that looks like a URL. Quoting fixes it.
#
# Fires only for network commands (gh api / curl / wget / http), where a glob
# is never intended — a bare `skills/*/SKILL.md` in a normal shell command is
# a real glob and must not be nudged.
#
# Config:
#   GUARD_ZSH_GLOB_URL_DISABLE=1  — turn off

[ "${GUARD_ZSH_GLOB_URL_DISABLE:-0}" = "1" ] && exit 0

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | python3 -c 'import json,sys
try:
    p=json.loads(sys.stdin.read() or "{}")
    print((p.get("tool_input") or {}).get("command") or "")
except Exception:
    print("")
' 2>/dev/null)

[ -z "$CMD" ] && exit 0

# Network commands only — globs are legitimate everywhere else.
printf '%s' "$CMD" | grep -qE '(^|[|;&[:space:]])(gh[[:space:]]+api|curl|wget|http)([[:space:]]|$)' || exit 0

HIT=$(printf '%s' "$CMD" | python3 -c '
import re,sys
cmd = sys.stdin.read()
# Blank out quoted strings — quoted args are already safe.
stripped = re.sub(r"\x27[^\x27]*\x27", "", re.sub(r"\"[^\"]*\"", "", cmd))
for tok in stripped.split():
    if tok.startswith("-") or "/" not in tok:
        continue
    if "?" in tok or "*" in tok:
        print(tok); break
' 2>/dev/null)

[ -z "$HIT" ] && exit 0

cat >&2 <<EOF
[guard-zsh-glob-url] 따옴표 없는 인자에 zsh glob 문자가 있다: $HIT
zsh 는 URL 안의 \`?\`·\`*\` 도 글로브로 먹는다 — 명령이 실행되기 전에
\`no matches found\` 로 죽고 왕복 1회가 통째로 낭비된다.
→ 인자를 통째로 따옴표로 감싼다: gh api "repos/o/r/git/trees/HEAD?recursive=1"
(의도한 글로브면 무시. 끄기: GUARD_ZSH_GLOB_URL_DISABLE=1)
EOF
exit 0
