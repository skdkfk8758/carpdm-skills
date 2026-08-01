#!/usr/bin/env bash
# PreToolUse hook (Bash): Block destructive commands.
# exit 2 + stderr → blocks tool execution with reason.
#
# False-positive 방어 (2026-04-27):
#   - JSON 파싱은 python 으로 (escaped quote 안전)
#   - 매칭은 따옴표 내부를 비운 SANITIZED 문자열에서 수행
#     → `grep "rm -rf foo"`, `echo "DROP TABLE x"`, `git log --grep="reset --hard"`
#       같은 정상 명령이 차단되지 않도록.
#   - 메시지 출력은 원본 CMD 사용 (사용자 가시성).

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | python3 -c 'import json,sys
try:
    p=json.loads(sys.stdin.read() or "{}")
    print((p.get("tool_input") or {}).get("command") or "")
except Exception:
    print("")
' 2>/dev/null)

[ -z "$CMD" ] && exit 0

# 따옴표 안의 내용을 비워서 매칭 대상에서 제외 (guard-branch-protection.sh 와 동일 기법).
#   1) single-quoted strings (cannot contain nested ')
#   2) double-quoted strings
SANITIZED=$(printf '%s' "$CMD" | sed -E "s/'[^']*'/''/g" | sed -E 's/"[^"]*"/""/g')

# --- recursive delete ---
if echo "$SANITIZED" | grep -qE 'rm\s+(-[a-zA-Z]*r|-[a-zA-Z]*f[a-zA-Z]*r|--recursive)'; then
  echo "[guard] BLOCKED: recursive delete detected — $CMD" >&2
  echo "Use rm <file> for individual files instead." >&2
  exit 2
fi

# --- SQL destructive (case-insensitive) ---
if echo "$SANITIZED" | grep -qiE '(DROP[[:space:]]+(TABLE|DATABASE|SCHEMA)|TRUNCATE[[:space:]]+)'; then
  echo "[guard] BLOCKED: SQL destructive command detected — $CMD" >&2
  echo "DROP/TRUNCATE permanently deletes data. Get user approval first." >&2
  exit 2
fi

# --- git work loss ---
if echo "$SANITIZED" | grep -qE 'git\s+reset\s+--hard'; then
  echo "[guard] BLOCKED: git reset --hard detected — $CMD" >&2
  echo "Consider git stash first." >&2
  exit 2
fi

if echo "$SANITIZED" | grep -qE 'git\s+clean\s+-[a-zA-Z]*f'; then
  echo "[guard] BLOCKED: git clean -f detected — $CMD" >&2
  echo "Untracked files will be permanently deleted." >&2
  exit 2
fi

# --- git restore all ---
if echo "$SANITIZED" | grep -qE 'git\s+(checkout|restore)\s+(--\s+)?\.$'; then
  echo "[guard] BLOCKED: full file restore detected — $CMD" >&2
  echo "Restore individual files instead." >&2
  exit 2
fi

# --- git force branch delete ---
# 예외: 머지 검증된 브랜치 cleanup 은 명시 마커로 허용.
#   git branch -D <b>  # landed       (또는 # merged-verified)
# squash 머지는 ancestry 가 끊겨 -d / --merged 가 머지를 못 알아채므로(거부),
# 의도적 force-delete 를 마커로 표명한다. 마커는 "PR MERGED 확인함" 의 인간/agent 단언.
# 마커 없는 -D 는 우발적 작업손실 방지를 위해 기존대로 차단.
if echo "$SANITIZED" | grep -qE 'git\s+branch\s+-D\s+'; then
  if echo "$CMD" | grep -qiE '#[[:space:]]*(landed|merged-verified)([[:space:]]|$)'; then
    : # allowed — caller asserted the branch is merged/verified
  else
    echo "[guard] BLOCKED: force branch delete detected — $CMD" >&2
    echo "Use -d. 머지/squash 된 브랜치면 머지 확인 후 마커를 붙여라: git branch -D <b>  # landed" >&2
    exit 2
  fi
fi

exit 0
