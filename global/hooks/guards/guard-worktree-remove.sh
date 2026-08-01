#!/usr/bin/env bash
# PreToolUse hook (Bash): `git worktree remove` 는 사용자 인터뷰 승인 후에만.
# exit 2 + stderr → blocks tool execution with reason.
#
# 배경 (2026-07-23 실사고): "develop 머지됨 + clean" 판정만으로 세션 워크트리
# (싱크-컨테이너-리뷰)를 삭제 → 다른 라이브 세션의 cwd 일 수 있어 원복.
# 그 기준은 브랜치 수명 판정일 뿐 "사용 중 아님"을 보장하지 않는다. 삭제 대상
# 선택은 훅이 강제로 사용자 인터뷰(AskUserQuestion)에 태운다.
#
# 통과 마커: 명령 문자열에 GUARD_WORKTREE_OK=1 포함 — 사용자가 인터뷰에서
# 해당 워크트리 삭제를 승인한 뒤에만 붙일 것.
# 끄기: env GUARD_WORKTREE_REMOVE_DISABLE=1
# 은퇴 조건: 분기 ablation 스윕에서 무단삭제 재발 0 이 2분기 연속이면 폐기 검토.

[ -n "${GUARD_WORKTREE_REMOVE_DISABLE:-}" ] && exit 0

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | python3 -c 'import json,sys
try:
    p=json.loads(sys.stdin.read() or "{}")
    print((p.get("tool_input") or {}).get("command") or "")
except Exception:
    print("")
' 2>/dev/null)

[ -z "$CMD" ] && exit 0

# 승인 마커 — 인터뷰 통과분만 (raw CMD 에서 검사)
printf '%s' "$CMD" | grep -q 'GUARD_WORKTREE_OK=1' && exit 0

# 따옴표 내부를 비워 grep/echo 등 정상 명령의 오탐 방지 (guard-destructive-cmd 동일 기법)
SANITIZED=$(printf '%s' "$CMD" | sed -E "s/'[^']*'/''/g" | sed -E 's/"[^"]*"/""/g')

if echo "$SANITIZED" | grep -qE 'worktree[[:space:]]+remove'; then
  echo "[guard] BLOCKED: git worktree remove — 삭제 대상 인터뷰 필요: $CMD" >&2
  echo "절차: ① git worktree list 로 현황 수집 ② AskUserQuestion(multiSelect) 으로 어떤 워크트리를 제거할지 사용자 선택 ③ 승인된 대상만 GUARD_WORKTREE_OK=1 git worktree remove <path> 로 실행." >&2
  echo "주의: 세션 워크트리(skdkfk8758/*)는 머지됨+clean 이어도 라이브 세션 cwd 일 수 있다 — 머지 여부는 삭제 안전의 근거가 아니다." >&2
  exit 2
fi

exit 0
