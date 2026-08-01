# orm-stack — JS ORM 표준 = Drizzle (introspect-first)

IMPORTANT: 사용자의 **JS/TS 프로젝트 ORM 표준은 Drizzle(`drizzle-orm` + `drizzle-kit`)** 이다. 단 이 환경은 **DB 가 스키마 SSOT**(DB-Manager 소유, 사전 프로비저닝)라서 Drizzle 의 기본 schema-first 워크플로를 그대로 쓰면 안 된다 — **introspect-first** 로 쓴다. 새 JS 프로젝트에 ORM/DB 레이어를 세팅하는 질문이 오면 본 룰의 컨벤션을 적용한다. Python 백엔드(`BE_DrafType_API_APP` = SQLAlchemy)는 **본 룰 밖**이다.

## 왜 introspect-first (schema-first 금지)

- **DB-Manager 가 스키마를 소유**한다. 앱이 schema 를 정의·소유하지 않는다 → DB 가 진실.
- **운영DB slow-lane** — apply 절차 SSOT = `branch-worktree-strategy.md §6b`(psql apply + information_schema 검증, prod 자동 migrate 금지 — 공유 운영DB 비가역성 안전장치).
- Drizzle 의 셀링포인트(`generate`→`migrate` 자동 마이그)는 이 두 제약과 정면충돌한다. 그래서 Drizzle 은 **query builder + 타입소스**로만 쓰고, 마이그는 기존 psql 러너를 유지한다.

## 컨벤션 (이대로 세팅)

- **schema 는 손으로 쓰지 않는다.** `drizzle-kit pull`(구 `introspect`)로 라이브 DB → `schema.ts` 생성. kysely-codegen 이 하던 역할 그대로. 생성물은 편집 금지(drift 0).
- **`drizzle-kit generate` / `migrate` / `push` 금지.** 마이그는 기존 psql `.up.sql/.down.sql` slow-lane(`scripts/migrate.mjs` 류) 유지.
- `drizzle.config.ts` = `dialect: 'postgresql'` + `dbCredentials` + `out`(schema 출력 경로)만. 마이그 디렉토리 설정은 두지 않는다(혼동 방지).
- `package.json` script: `db:pull = drizzle-kit pull`(타입 갱신) / `db:migrate* = psql 러너`(기존 유지). `kysely-codegen` 의 `db:types` 자리를 `db:pull` 이 대체.
- **bigint 주의** — pg `int8/bigint` 컬럼은 `drizzle-kit pull` 이 `bigint(..., { mode: 'number' })` 로 뽑는다. 큰 ID 정밀도 손실 위험 시 `mode: 'bigint'` 또는 경계에서 `String()` 변환(IA 의 Int8 string 계약과 동형). introspect 직후 ID 컬럼 mode 확인.

## 적용 범위 — 신규부터 수렴, 기존 강제전환 안 함

- **새 JS 프로젝트는 처음부터 본 표준.** 통일은 신규 수렴으로 달성한다.
- **`Intelligence-Auth` 는 Drizzle 전환 완료** (2026-06-15, PR #22, harness-run pass). introspect-first(14 테이블)·마이그 psql 유지, 실 dev DB 통합 OUTCOME 테스트로 동작 100% 보존 검증(tsc clean·vitest 221/221·grep kysely=0). 이제 전 JS 프로젝트가 Drizzle 표준.
- **통일 표면 한계 고지** — 메인 백엔드가 Python/SQLAlchemy 라 "전사 DB 접근 통일"은 ORM 선택으로 달성 불가. 본 룰은 **JS 쪽 한정**.

## 재사용 자산 (선택 — 미설치면 수동)

- `~/.config/drizzle-template/`(아직 미설치) — `drizzle.config.ts`(introspect, no migrate) + `db.ts` factory + 위 script 셋. 신규 프로젝트가 복붙해 시작. `cicd-template` 패턴과 동형. 없으면 본 룰 컨벤션대로 수동 세팅.

## Anti-patterns

- Drizzle 을 schema-first 로 세팅(`generate`/`migrate`/`push` 사용) — DB-Manager 소유권·운영DB slow-lane 안전장치 붕괴.
- `drizzle-kit pull` 생성 `schema.ts` 손편집 — DB 와 drift.
- 동작보존 oracle 없이 검증된 코드를 맹목 ORM 전환 — IA 전환(#22)은 실DB 통합 OUTCOME oracle 로 동작보존을 먼저 잠근 뒤 진행했다(harness G1 freeze→자율 dev+eval). oracle 없는 재작성은 회귀 위험.
- Python 백엔드를 본 룰로 끌어옴 — SQLAlchemy 는 별개 스택.

## Related

- `~/.claude/rules/branch-worktree-strategy.md` §6a/6b — 타임스탬프 마이그 prefix·운영DB slow-lane(본 룰의 마이그 정책 SSOT).
- `~/.claude/rules-ondemand/cicd-pipeline.md` — 동질 스택 반복 적용 철학의 짝(배포 표준).
- `~/.claude/rules-ondemand/knowledge-folders.md` — 본 룰을 프로젝트 `AGENTS.md`/`rules/` 에 미러링하는 규약.
- 전환 인스턴스(Drizzle 실적용): `Intelligence-Auth` (PR #22, harness-run) — introspect-first + 실DB 통합 oracle 실례. `src/lib/db.ts`(drizzle factory) + `src/lib/db/schema.ts`(pull 생성, 14 테이블).
