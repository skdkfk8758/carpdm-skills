# Verification Safety — green 은 가설이다, 위조 불가능하게 만들 것

IMPORTANT: "검증 통과(green)" 는 선언이 아니라 **검증 가능한 사실**이어야 한다. 실측 사고 2종 — ① `|| echo` 가 실패 테스트의 exit code 를 삼켜 false-green, ② 검증 쿼리의 LIKE 패턴에 unescaped `_` 와일드카드가 정상 테이블(`persona_layers`)을 잔재로 오탐 — 둘 다 사용자 pushback 으로만 잡혔다. 아래 3규칙으로 검증 신호 자체를 신뢰 가능하게 유지한다.

## V1: 검증 명령에 exit-swallow 금지

- test/typecheck/lint/build 검증 명령에 `|| echo`·`|| true`·`|| :` 를 붙이지 않는다 — 실패가 green 으로 위장된다.
- 파일 존재 감지 등 **탐지 단계**의 `|| true` 는 허용 (예: `grep ... || true` 로 목록 수집). 금지 대상은 **판정 단계**(pass/fail 을 가르는 명령)다.
- green 선언 전 자가 점검: "이 명령이 실패했다면 지금 출력이 달랐을 것인가?" — 아니오면 그 green 은 신호가 아니다. strict 로 재실행.

## V2: SQL 검증 쿼리는 와일드카드 이스케이프

- `LIKE 'persona_%'` 의 `_` 는 any-char 와일드카드 — `personaXlayers` 도 매칭돼 오탐/누락을 만든다.
- 검증·drift 판정 쿼리에서 리터럴 언더스코어는 `LIKE 'persona\_%' ESCAPE '\'` 또는 `=` 완전일치 사용.
- 존재/부재 판정은 가능하면 `information_schema` + `=` 완전일치가 기본.

## V3: 마이그레이션 "ran" ≠ "applied"

- 마이그 명령의 exit 0 은 "실행됨"일 뿐. **적용 증거**는 대상 DB 직접 쿼리로 별도 확보 — `information_schema` 컬럼/테이블 존재, before/after row count.
- prod 는 migrations 이력 테이블도 신뢰 불가(이력 미기록 스크립트 실존) — 실객체 조회만 증거로 인정.
- apply 절차 SSOT: `~/.claude/rules-ondemand/orm-stack.md` §slow-lane, `branch-worktree-strategy.md` §6b.

## 강제 (hook 자동 — 비차단 nudge)

- `guard-verify-swallow.sh` (PostToolUse Bash) — 검증류 명령 + swallow 패턴 동시 감지 시 stderr 리마인드. 끄기: `GUARD_VERIFY_SWALLOW_DISABLE=1`. 훅은 의도 판별 불가 — 실제 판정은 본 룰을 읽은 AI 가 한다.

## Anti-patterns

- `pnpm test || echo done` 후 출력에 에러가 안 보인다고 green 선언 — V1 위반.
- 마이그 스크립트 exit 0 을 "prod 적용 완료"로 보고 — V3 위반.
- `LIKE '%_layers'` 로 잔재 테이블 판정 — V2 위반.
- Stop 훅/게이트가 green 이라고 검증 명령 자체의 신뢰성 점검 생략.

## Related

- `~/.claude/rules-ondemand/orm-stack.md` — 마이그 apply·검증 절차 SSOT.
- `~/.claude/rules/acceptance-criteria-gate.md` G1 — 검증이 체크를 선행 (본 룰은 그 검증 신호의 무결성).
- `~/.claude/rules-ondemand/db-drop-preflight.md` — 파괴 방향의 짝 (drop 전 liveness 증거).
