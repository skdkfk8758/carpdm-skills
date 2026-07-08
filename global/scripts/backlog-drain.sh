#!/usr/bin/env bash
# backlog-drain.sh — 야간 Linear backlog 드레인 (PR 까지만, 머지는 아침 /land)
#
# 무엇: headless claude 가 현재 repo 팀의 미착수 Linear 이슈를 골라 linear-goal
#       로 순차 실행 → 각 이슈를 PR(In Review) 까지 올린다. **머지는 하지 않는다**
#       — 아침에 사람이 /land 로 승인 게이트를 거쳐 머지한다 (기존 게이트 보존).
#
# 사용:
#   backlog-drain.sh <repo-path> [max-tickets]     # 기본 max 3
#   예) backlog-drain.sh ~/Workspace/ADMap 3
#
# 로그: ~/.claude/logs/drain/<repo>-YYYYMMDD-HHMMSS.log
#
# 권한 설계 (의도적 제약):
#   --permission-mode acceptEdits 고정 — 파일 편집은 자동, Bash/MCP 는
#   settings.json permissions allowlist 범위 내에서만 무인 진행된다.
#   allowlist 밖 동작을 만나면 그 이슈는 실패로 기록되고 다음 이슈로 넘어간다 —
#   권한 게이트를 끄는 옵션은 제공하지 않는다 (가드 훅만으로는 방어선이 부족).
#   무인 성공률을 올리려면 /fewer-permission-prompts 로 allowlist 를 보강할 것.
#   첫 1~2회는 수동 실행으로 관찰 후 launchd 에 올리는 것을 권장.
#
# launchd 등록 (평일 03:00 예시) — ~/Library/LaunchAgents/com.carpdm.backlog-drain.plist:
#   <?xml version="1.0" encoding="UTF-8"?>
#   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
#   <plist version="1.0"><dict>
#     <key>Label</key><string>com.carpdm.backlog-drain</string>
#     <key>ProgramArguments</key><array>
#       <string>/bin/bash</string>
#       <string>/Users/carpdm/.claude/scripts/backlog-drain.sh</string>
#       <string>/Users/carpdm/Workspace/ADMap</string>
#       <string>3</string>
#     </array>
#     <key>StartCalendarInterval</key><dict>
#       <key>Hour</key><integer>3</integer><key>Minute</key><integer>0</integer>
#     </dict>
#     <key>StandardOutPath</key><string>/Users/carpdm/.claude/logs/drain/launchd.out.log</string>
#     <key>StandardErrorPath</key><string>/Users/carpdm/.claude/logs/drain/launchd.err.log</string>
#   </dict></plist>
#   → launchctl load ~/Library/LaunchAgents/com.carpdm.backlog-drain.plist
#   (CronCreate 는 session-only 라 야간 배치 불가 — launchd 가 정답)

set -euo pipefail

REPO="${1:?usage: backlog-drain.sh <repo-path> [max-tickets]}"
MAX="${2:-3}"
[ -d "$REPO/.git" ] || { echo "not a git repo: $REPO" >&2; exit 1; }

# launchd 는 최소 PATH 로 뜬다 — claude/gh/node 경로 확보
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
command -v claude >/dev/null || { echo "claude CLI not on PATH" >&2; exit 1; }

LOG_DIR="$HOME/.claude/logs/drain"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/$(basename "$REPO")-$(date +%Y%m%d-%H%M%S).log"

PROMPT=$(cat <<'EOF'
야간 backlog 드레인. 규칙을 엄수하라:

1. linear-dispatch 룰대로 현재 repo 의 팀으로 스코프를 좁혀 미착수(unstarted/backlog)
   이슈를 조회한다. 팀 매핑이 없으면 아무것도 하지 말고 "매핑 없음" 보고 후 종료.
2. 그중 서로 독립적인(같은 파일/도메인을 안 건드는) 이슈를 우선순위 순으로 최대
   MAX_TICKETS 건 선정한다. harness-class(estimate>=5, cross-cutting, 전면개편)와
   DB 마이그레이션·prod 배포가 필요한 이슈는 제외하고 사유와 함께 목록만 남긴다.
3. 각 이슈를 linear-goal 스킬로 **순차** 실행한다 — 워크트리 분기, 구현, 검증,
   PR 생성(In Review)까지. **머지 절대 금지. gh pr merge 호출 금지. prod 접근 금지.**
   아침에 사람이 /land 로 머지한다.
4. 권한 프롬프트로 막히는 동작을 만나면 그 이슈를 "권한 부족" 실패로 기록하고
   다음 이슈로 넘어간다 — 우회 시도 금지. 그 외 실패는 1회만 재시도, 그래도
   실패면 스킵. 실패 워크트리는 복구 가능한 상태로 남긴다 (reset/삭제 금지).
5. 종료 시 요약을 남긴다: 처리 이슈별 [PR 올림 #N | 실패-사유 | 스킵-사유],
   생성된 워크트리 목록, 아침에 /land 로 머지하라는 안내 1줄.
EOF
)

echo "[drain] repo=$REPO max=$MAX log=$LOG"
cd "$REPO"
claude -p "${PROMPT/MAX_TICKETS/$MAX}" --permission-mode acceptEdits >"$LOG" 2>&1 || {
  echo "[drain] claude exited non-zero — see $LOG" >&2
  exit 1
}
echo "[drain] done — $LOG"
