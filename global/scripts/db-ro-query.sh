#!/usr/bin/env bash
# db-ro-query.sh — 읽기 전용 psql 래퍼 (무인 세션용)
#
# 무엇: SELECT 류 조회만 통과시키는 psql 래퍼. db-guardian 등 headless 세션이
#       psql 직접 호출 대신 이걸 쓴다 — allowlist 의 `bash` 경로로 무인 통과되되,
#       쓰기/DDL 은 이중으로 막힌다:
#         1. 키워드 거부 — INSERT/UPDATE/DELETE/DROP/ALTER/TRUNCATE/CREATE/
#            GRANT/REVOKE/COPY/VACUUM + read_only 재설정 시도 자체를 reject
#         2. PGOPTIONS default_transaction_read_only=on — 통과해도 서버가 거부
#
# 사용:
#   db-ro-query.sh <connection-uri-or-dsn> <sql>
#   예) bash ~/.claude/scripts/db-ro-query.sh "$DATABASE_URL" \
#         "SELECT table_name FROM information_schema.tables WHERE table_schema='map_layer'"
#
# 제약: 단일 쿼리 인자만 (-f 파일/stdin 미지원 — 검사 우회 방지). 출력은 stdout.

set -euo pipefail

DSN="${1:?usage: db-ro-query.sh <dsn> <sql>}"
SQL="${2:?usage: db-ro-query.sh <dsn> <sql>}"

# 1차 방어 — 쓰기/DDL/read-only 해제 키워드 거부 (주석·대소문자 무관)
STRIPPED=$(printf '%s' "$SQL" | sed -E 's/--[^\n]*//g; s|/\*[^*]*\*/||g')
if printf '%s' "$STRIPPED" | grep -qiE '\b(insert|update|delete|drop|alter|truncate|create|grant|revoke|copy|vacuum|reindex|cluster|do)\b|transaction_read_only'; then
  echo "[db-ro-query] REJECTED: write/DDL keyword detected — read-only wrapper" >&2
  exit 2
fi

# 2차 방어 — 서버 세션을 read-only 로 고정
export PGOPTIONS="-c default_transaction_read_only=on ${PGOPTIONS:-}"
export PGCONNECT_TIMEOUT="${PGCONNECT_TIMEOUT:-10}"

exec psql "$DSN" --no-psqlrc --quiet --tuples-only --pset=format=aligned -v ON_ERROR_STOP=1 -c "$SQL"
