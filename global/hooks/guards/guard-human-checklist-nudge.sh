#!/usr/bin/env bash
# PostToolUse hook (Write|Edit): Nudge Artifact publish + live dev server after
# writing a [사용자 직접 확인 필요] checklist page.
#
# Scope, honestly: this hook cannot detect the *decision* to emit a checklist
# (that needs "UI surface changed AND 2+ HUMAN items left" — a semantic judgment
# no grep can make). It only guards the *emission quality* once the file exists:
# publish it, and hand it over with a live dev server. The decision itself is
# enforced by ui-verify.md §4 (gate clause) + the goal/board contracts.
# Non-blocking — the AI reading ui-verify.md §5·§5.1 does the real enforcement.
# Disable: GUARD_HUMAN_CHECKLIST_NUDGE_DISABLE=1

[ "${GUARD_HUMAN_CHECKLIST_NUDGE_DISABLE:-0}" = "1" ] && exit 0

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"//' | sed 's/"$//')

[ -z "$FILE_PATH" ] && exit 0

# The template's own file is the SSOT, not an emission — don't nudge on it.
case "$FILE_PATH" in
  */craft-core/references/assets/*) exit 0 ;;
esac

# Detect a checklist emission: by filename, OR — for any .html the name misses
# (e.g. qa-verify.html) — by the template's own content markers.
is_checklist=0
echo "$FILE_PATH" | grep -qiE 'checklist[^/]*\.html$|체크리스트[^/]*\.html$' && is_checklist=1
if [ "$is_checklist" = "0" ] && echo "$FILE_PATH" | grep -qiE '\.html$' && [ -f "$FILE_PATH" ]; then
  grep -q '사용자 직접 확인' "$FILE_PATH" 2>/dev/null && is_checklist=1
fi
[ "$is_checklist" = "1" ] || exit 0

echo "[guard-human-checklist] 체크리스트 페이지 감지: ${FILE_PATH##*/}" >&2
echo "  1) Artifact 도구로 publish (favicon 필수) — URL 이 딜리버러블이다" >&2
echo "  2) 넘기기 전 dev 서버를 daemon 으로 띄운다 (작업 워크트리 경로로):" >&2
echo "     python3 ~/.claude/skills/dev-server-daemon/scripts/devserverctl.py start --cwd <워크트리>" >&2
echo "  3) 링크 origin 은 그 스크립트가 찍은 실측값만 — 관례 포트(:3000) 추정 금지" >&2
echo "     (메인 체크아웃을 가리키면 사람이 '변경 없는 브랜치' 화면을 검증한다)" >&2
echo "  4) 보고에 artifact URL + dev origin + 정지 명령. 체크는 사람이 채운다(대신 켜지 말 것)" >&2
echo "  5) 회수: 사용자가 '결과 복사' markdown 을 붙여넣으면 - [x] 를 파싱해 장부를 닫는다" >&2
echo "  SSOT: ~/.claude/skills/craft-core/references/ui-verify.md §5·§5.1" >&2

exit 0
