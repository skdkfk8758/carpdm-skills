# DB Drop Preflight — drop 전 liveness 3증거 의무

IMPORTANT: "이 DB/테이블은 죽었다/redundant 다" 라는 설명(사용자 발화·문서·이슈 본문 포함)을 **사실로 받지 말 것**. 실측: 'redundant' 로 지목된 DB 가 실제 라이브 프로덕션 타겟이었고, 삭제 직전 증거 발견으로 중단해 데이터 손실을 면했다. 그 정지는 모델 판단 우연이었다 — 본 룰이 그것을 절차로 고정한다.

## 적용 대상

`DROP DATABASE` / `DROP SCHEMA` / `DROP TABLE`, 대량 `DELETE`/`TRUNCATE`, DB 컨테이너·볼륨 삭제, "백업 후 삭제" 류 — **비가역 삭제로 향하는 모든 경로**. 코드의 데드코드 삭제(yagni-core)와 별개 — 본 룰은 데이터다.

## 3증거 (전부 확보 후에만 진행)

1. **활성 커넥션 0** — `SELECT count(*) FROM pg_stat_activity WHERE datname='<db>' AND pid<>pg_backend_pid();` (테이블이면 `pg_stat_user_tables` 의 해당 테이블 seq/idx scan 최근성 병행).
2. **최근 write 없음** — `max(updated_at)`/최신 sequence 값/`pg_stat_user_tables` 의 `n_tup_ins·upd·del` 로 최근 쓰기 부재 확인. 통계 리셋 시점 감안 — 단일 지표로 단정 금지.
3. **참조 0** — 앱 코드·`.env*`·docker-compose·CI/CD 설정·배포 스크립트에서 대상 이름 grep = 0. 다른 repo 가 붙는 공유 DB 면 그 repo 들도 범위.

## 판정 규칙

- **하나라도 live 신호 → 즉시 halt** + 발견 증거를 사용자에게 보고. "그래도 지워도 되는지" 를 되묻는 게 아니라, 전제("죽었다")가 깨졌음을 먼저 알린다.
- 3증거 확보 후에도 실행 전 대상·영향·복구수단(덤프 여부)을 1회 요약 제시 (`guard-destructive-cmd` 경고와 별개의 내용 게이트).
- 검증 쿼리는 `verification-safety.md` V2 준수 — LIKE 와일드카드 이스케이프, `=` 완전일치 우선.

## Anti-patterns

- 이슈/문서의 "미사용 테이블 목록"을 재검증 없이 drop 스크립트로 변환.
- migrations 이력 테이블만 보고 스키마 상태 단정 — prod 이력은 낡을 수 있음 (실측). 실객체(`information_schema`) 조회가 진실.
- "백업 떴으니 바로 drop" — 백업은 복구수단이지 liveness 증거가 아니다. 3증거는 여전히 필수.
- dev 에서 확인한 liveness 를 prod 에 이전 적용 — DB 마다 독립 검증.

## Related

- `~/.claude/rules/verification-safety.md` — 검증 쿼리 무결성 (짝).
- `~/.claude/rules/branch-worktree-strategy.md` §6b — 운영DB slow-lane (같은 비가역성 근거).
- `guard-destructive-cmd` 훅 — 명령 패턴 경고 (본 룰은 그 앞의 "대상이 정말 죽었나" 판정).
