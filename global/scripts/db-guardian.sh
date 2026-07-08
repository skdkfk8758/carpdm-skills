#!/usr/bin/env bash
# db-guardian.sh — 정기 DB 스키마 감시 (읽기 전용, drop 절대 안 함)
#
# 무엇: headless claude 가 dev/prod 스키마를 introspect 해 ① ERD 재생성(/erd)
#       ② drift 감지(마이그 파일 vs 실객체) ③ orphan/미사용 테이블 후보 리포트를
#       만들고, 발견 사항을 Linear 이슈로 등록한다. **어떤 경우에도 DDL/DML 을
#       실행하지 않는다** — 산출물은 리포트와 이슈뿐, 조치는 사람이 한다.
#
# 사용:
#   db-guardian.sh <repo-path>
#   예) db-guardian.sh ~/Workspace/ADMap
#
# 로그:   ~/.claude/logs/guardian/<repo>-YYYYMMDD-HHMMSS.log
# 리포트: <repo>/docs/reports/db-guardian-YYYY-MM-DD.md (+ ERD HTML)
#
# 권한 설계 (의도적 제약):
#   --permission-mode acceptEdits 고정 (리포트/ERD 파일 쓰기용). DB 접근은
#   읽기 전용 쿼리(information_schema, pg_stat_*)만 — 프롬프트가 강제하고,
#   psql allowlist 는 settings.json permissions 로 관리. 권한 게이트를 끄는
#   옵션은 제공하지 않는다.
#
# launchd 등록 (매주 월 04:00 예시) — ~/Library/LaunchAgents/com.carpdm.db-guardian.plist:
#   ProgramArguments: /bin/bash /Users/carpdm/.claude/scripts/db-guardian.sh /Users/carpdm/Workspace/ADMap
#   StartCalendarInterval: { Weekday=1, Hour=4, Minute=0 }
#   (plist 골격은 backlog-drain.sh 헤더의 예시와 동일 — Label/경로만 교체)

set -euo pipefail

REPO="${1:?usage: db-guardian.sh <repo-path>}"
[ -d "$REPO/.git" ] || { echo "not a git repo: $REPO" >&2; exit 1; }

export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
command -v claude >/dev/null || { echo "claude CLI not on PATH" >&2; exit 1; }

LOG_DIR="$HOME/.claude/logs/guardian"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/$(basename "$REPO")-$(date +%Y%m%d-%H%M%S).log"
TODAY=$(date +%Y-%m-%d)

PROMPT=$(cat <<EOF
DB 스키마 정기 감시. 하드 제약을 엄수하라:

**절대 금지: DDL/DML 실행 (DROP/ALTER/DELETE/TRUNCATE/INSERT/UPDATE), 마이그
apply, 컨테이너/볼륨 조작. 허용되는 DB 접근은 읽기 전용 SELECT
(information_schema, pg_catalog, pg_stat_*) 뿐이다.**

1. repo 의 DB 접속 정보(.env*, docker-compose)를 찾아 dev/prod 각각 읽기 전용
   introspection: 테이블·컬럼·FK·인덱스 + pg_stat_user_tables 활동 통계.
   **DB 조회는 psql 직접 호출 금지 — 반드시 읽기 전용 래퍼로:**
   \`bash ~/.claude/scripts/db-ro-query.sh "<dsn>" "<sql>"\`
   (래퍼가 쓰기/DDL 키워드 거부 + default_transaction_read_only 강제. 래퍼가
   REJECTED 를 내면 그 쿼리를 읽기 전용으로 재작성하라 — 우회 금지.)
   prod 접속 불가면 dev 만으로 진행하고 그 사실을 리포트에 명시.
2. drift 판정: repo 마이그레이션 파일들이 기대하는 스키마 vs 실객체.
   migrations 이력 테이블은 신뢰하지 말 것 (이력 미기록 사례 실존) —
   information_schema 실객체 + '=' 완전일치가 진실 (verification-safety V2/V3).
3. orphan 후보: 코드/설정 grep 참조 0 + pg_stat 활동 0 인 테이블. **후보일 뿐
   결론이 아니다** — db-drop-preflight 3증거 중 스크립트가 못 보는 범위(타 repo
   참조 등)를 리포트에 한계로 명시하고, drop 제안은 반드시 "사람 검증 필요" 로.
4. /erd 스킬로 현재 스키마 ERD HTML 재생성.
5. 산출: docs/reports/db-guardian-${TODAY}.md — drift/orphan/미적용 마이그 요약
   + ERD 파일 경로. 발견이 actionable 하면(미적용 마이그, drift, orphan 후보)
   linear-register 스킬로 이슈 등록 — 이슈에도 "읽기 전용 감시 결과, 조치 전
   db-drop-preflight 검증 필수" 를 박는다. 발견 0건이면 이슈 등록 생략.
EOF
)

echo "[guardian] repo=$REPO log=$LOG"
cd "$REPO"
claude -p "$PROMPT" --permission-mode acceptEdits >"$LOG" 2>&1 || {
  echo "[guardian] claude exited non-zero — see $LOG" >&2
  exit 1
}
echo "[guardian] done — $LOG"
