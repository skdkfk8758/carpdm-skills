# Schema discovery — 스키마를 어디서 어떻게 재구성하나

ERD 를 그리려면 먼저 **테이블·컬럼·관계**를 확정해야 한다. 추측 금지 — 실제 소스를
Read/Grep 으로 확인한다(karpathy 원칙 1). 입력은 보통 다음 중 하나다. **신뢰도 순서:
라이브 DB(0) > 마이그레이션(1) > ORM(2) > repository 코드(3) > 산문/plan(4)**. 라이브 DB
접속이 가능하면 그게 SSOT 다 — 0 을 우선하되, soft 참조·deprecated 는 introspection 에
안 잡히므로(아래 한계) 코드 소스(1~3)를 보조로 병행한다.

## 0. 라이브 DB introspection (최고 신뢰도 — SSOT)

실제 DB 에 붙어 `information_schema`/시스템 카탈로그를 읽으면 마이그레이션 누락·drift 없이
**현재 운영 스키마 그대로**를 얻는다. 정적 소스로 재구성한 결과와 운영 실물이 어긋날 때
이게 정답이다.

### 안전 수칙 (IMPORTANT — 어기면 사고)

- **읽기 전용만.** `information_schema`/카탈로그 SELECT, `SHOW`, `PRAGMA`, `db pull`/
  `inspectdb` introspection 만 실행한다. `INSERT`/`UPDATE`/`DELETE`/`ALTER`/`DROP` 등
  쓰기·DDL 은 **절대 금지** — ERD 는 그리기만 한다.
- **접속 전 확인.** host 가 localhost/127.0.0.1 가 아니거나 DB 이름·호스트에 `prod`/
  `production`/`live` 가 보이면 **운영 DB 로 간주**하고, 접속 전에 사용자에게 "이 DB 에
  붙어 읽기전용 introspection 해도 되는가" 를 명시적으로 확인한다. 가능하면 로컬·read
  replica·스테이징을 우선 권한다.
- **credential 비노출.** 비밀번호·전체 connection string 을 출력·로그·ERD footer 에
  찍지 않는다. 명령 구성 시 비밀번호는 env var(`PGPASSWORD`, `MYSQL_PWD`)로 넘기고
  커맨드라인 평문에 두지 않는다. footer 출처 표기는 `live DB: <dbname>@<host>` 까지만
  (포트·유저·비번 제외).

### 접속 정보 발견 (추측 금지 — 실제로 확인)

코드베이스에서 접속 정보를 Grep 으로 찾는다. 못 찾으면 사용자에게 connection string 을
물어본다 — 임의로 지어내지 않는다.

- **env 파일** — `.env`, `.env.local`, `.env.*` 의 `DATABASE_URL`/`DB_HOST`·`DB_PORT`·
  `DB_USER`·`DB_PASSWORD`·`DB_NAME`/`POSTGRES_*`/`MYSQL_*`.
- **docker-compose** — `docker-compose.yml`/`compose.yaml` 의 db 서비스 env·ports.
  로컬 컨테이너면 `localhost:<mapped port>` 로 붙을 수 있다.
- **프레임워크 설정** — Rails `config/database.yml`, Django `settings.py` `DATABASES`,
  Prisma `schema.prisma` `datasource.url`, `knexfile.js`, TypeORM `ormconfig`/`data-source.ts`.

### 엔진별 introspection

CLI 가 있으면 그걸로, 없으면 프레임워크 introspection 으로 폴백한다. 출력이 길면
`logs/` 로 redirect 후 필요한 줄만 Read.

**PostgreSQL** — 비번이 argv(`ps aux`)·셸 히스토리에 남지 않게 `PGPASSWORD` env 로 넘긴다:
`PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c '<sql>'`.
(`psql "$DATABASE_URL"` 는 편하지만 URL 에 비번이 박혀 있으면 그대로 argv 에 노출되니 비번
포함 URL 은 피한다.) 아래 쿼리는 `table_schema='public'` 기준 — 앱이 다른 스키마를 쓰면
그 스키마명으로 바꾼다(스키마 목록: `SELECT schema_name FROM information_schema.schemata;`).

```sql
-- 테이블 (+ 코멘트)
SELECT c.relname AS table_name, obj_description(c.oid, 'pg_class') AS table_comment
FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='public' AND c.relkind='r' ORDER BY c.relname;
-- 컬럼 (타입·nullable·default + 코멘트)
SELECT cols.table_name, cols.column_name, cols.data_type, cols.is_nullable, cols.column_default,
       col_description(pc.oid, cols.ordinal_position) AS column_comment
FROM information_schema.columns cols
JOIN pg_class pc ON pc.relname=cols.table_name
JOIN pg_namespace pn ON pn.oid=pc.relnamespace AND pn.nspname=cols.table_schema
WHERE cols.table_schema='public'
ORDER BY cols.table_name, cols.ordinal_position;
-- PK / UNIQUE
SELECT tc.table_name, tc.constraint_type, kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON kcu.constraint_name=tc.constraint_name AND kcu.table_schema=tc.table_schema
WHERE tc.table_schema='public' AND tc.constraint_type IN ('PRIMARY KEY','UNIQUE')
ORDER BY tc.table_name;
-- FK (자식→부모 + ON DELETE 규칙)
-- 복합 FK 안전: 자식 컬럼 ordinal_position 을 부모 컬럼 position_in_unique_constraint 로 짝짓는다.
-- (constraint_column_usage 를 name 으로만 JOIN 하면 복합키에서 카테시안 곱이 나 컬럼이 오매핑됨)
SELECT kcu.table_name AS child, kcu.column_name AS child_col,
       ccu.table_name AS parent, ccu.column_name AS parent_col, rc.delete_rule
FROM information_schema.referential_constraints rc
JOIN information_schema.key_column_usage kcu
  ON kcu.constraint_name=rc.constraint_name AND kcu.constraint_schema=rc.constraint_schema
JOIN information_schema.key_column_usage ccu
  ON ccu.constraint_name=rc.unique_constraint_name
 AND ccu.constraint_schema=rc.unique_constraint_schema
 AND ccu.ordinal_position=kcu.position_in_unique_constraint
WHERE kcu.table_schema='public'
ORDER BY child, kcu.ordinal_position;
```

**MySQL/MariaDB** (`mysql -h … -u … -e '<sql>' <db>`, 비번은 `MYSQL_PWD`): 위와 동일하되
`table_schema=DATABASE()`(또는 대상 DB명) 로 거른다. FK 는 `information_schema.
key_column_usage` 에서 `referenced_table_name IS NOT NULL` 로, ON DELETE 규칙은
`referential_constraints` 에서. 코멘트는 `information_schema.tables.table_comment` /
`columns.column_comment`.

### 0a. 코멘트 — DB 값이 SSOT, 없으면 한글로 작성 (+백필 제안)

ERD 의 모든 테이블(`comment`)·컬럼(`c`) 설명은 한글이어야 한다. 소스 우선순위:

1. **DB 에 코멘트가 있으면 그대로 쓴다** (위 introspection 쿼리의 comment 컬럼).
   영어 코멘트면 한글로 번역해 싣되 원문 유래를 유지한다.
2. **없으면 코드·마이그레이션 주석·도메인 문서(ADR/CLAUDE.md)를 근거로 한글 코멘트를
   작성**한다 — 근거 없는 컬럼은 이름·타입·FK 에서 유추하되 확신 낮으면 짧게(억지 설명
   금지). 이렇게 작성한 코멘트는 DB 미등록분이다 — 테이블/컬럼 목록을 기억해 두고
   SKILL.md Step 4.5 의 **DB 코멘트 백필 제안**에 넘긴다.
3. SQLite 는 코멘트를 지원하지 않는다 — ERD 에만 싣고 백필 단계는 "SQLite 미지원" 으로
   생략을 알린다.

**SQLite** (`sqlite3 <file.db>`): `SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';`
(`sqlite_%` 내부 테이블 — `sqlite_sequence`/FTS shadow 등 — 제외)
→ 테이블별 `PRAGMA table_info(<t>);`(컬럼·PK), `PRAGMA foreign_key_list(<t>);`(FK·on_delete),
`PRAGMA index_list(<t>)`+`index_info`(UNIQUE).

**ORM/프레임워크 폴백** (CLI 없거나 접속만 코드로 가능할 때): Prisma `npx prisma db pull`
→ `schema.prisma` 재생성 후 소스 2 로 읽기, Django `python manage.py inspectdb`,
Rails `rails db:schema:dump` → `db/schema.rb`. introspection 결과 산출물을 소스로 다시 읽는다.

### 0b. 적재량·샘플 데이터 수집 (라이브 DB 일 때 — 데이터 탭 채우기)

ERD 의 데이터 탭은 테이블별 **적재량(row count)** 과 **마스킹된 샘플 rows** 를 보여준다.
DB 접속이 안 되면 수집하지 않고 `rows:null`/`sample:null` 로 둔다(템플릿이 "적재 정보
없음" 을 자동 표시).

**적재량 — 통계 추정치가 기본.** 대형 테이블 `count(*)` 는 풀스캔이라 느리고 DB 에
부담을 준다. 전 테이블을 쿼리 한 방으로:

```sql
-- PostgreSQL: 통계 기반 추정 (ANALYZE 이후 값 — rowsExact:false)
SELECT c.relname AS table_name, c.reltuples::bigint AS approx_rows
FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='public' AND c.relkind='r' ORDER BY c.relname;
```

- MySQL: `SELECT table_name, table_rows FROM information_schema.tables WHERE table_schema=DATABASE();` (추정).
- SQLite: 파일 로컬이라 `SELECT count(*)` 가 안전 — `rowsExact:true`.
- `reltuples` 가 `-1`/`0` 인데 실데이터 의심(통계 미수집)이면 그 테이블만
  `SELECT count(*)` 폴백 — 단 대형 의심 테이블(격자·로그류 이름)은 추정 `-1`→`null` 로
  두고 footer 에 한계 명시.
- 정확값이 필요하고 테이블이 작다고 확인된 경우만 `count(*)` → `rowsExact:true`.

**샘플 — 테이블별 `LIMIT 100` (MAX 100행).** `SELECT * FROM <t> LIMIT 100;` (정렬
불요). 적재가 100행 미만이면 전량이 실린다 — 패널 데이터 탭은 자체 스크롤이라 100행도
읽힌다. 컬럼이 아주 많은 테이블(30+)은 대표 컬럼 ~10개로 줄여도 된다(PK·FK·도메인 핵심
우선). 단 100행 × 넓은 컬럼으로 산출물이 과도해지면(대략 셀 수천 개↑) 그 테이블만 행을
줄이고 데이터 탭 하단에 "N행 중 M행 표시" 사실을 남긴다. 수집한 값은 **템플릿에 넣기
전에** 아래 규칙으로 가공한다:

| 대상 | 처리 |
|---|---|
| **PII 성 컬럼** — 컬럼명이 `email`/`name`/`phone`/`tel`/`mobile`/`address`/`birth`/`ssn`/`password`/`token`/`secret`/`api_key`/`salt` 류 패턴에 걸리면 | 부분 마스킹: `carpdm@draftype.net`→`c***@d***.net`, 이름→첫 글자+`**`, 전화→`010-****-**34`. password/token/secret/key 류는 값 전체를 `<마스킹됨>` |
| 긴 텍스트 (60자+) | 앞 57자 + `…` 로 절단 |
| geometry/bytea/blob | `<geometry>`/`<binary>` placeholder |
| JSON 대형 | 최상위 키만 `{a, b, …}` 요약 |
| NULL | `null` 그대로 (템플릿이 `∅` 렌더) |

마스킹은 **수집 직후, DATA 작성 전**에 한다 — Artifact 는 claude.ai 에 호스팅되므로
원본 PII 가 산출물에 실리면 안 된다. 컬럼명 패턴으로 못 잡는 PII(자유 텍스트 안 실명
등)가 보이면 그 값도 마스킹하고, 애매하면 마스킹 쪽으로 기운다.

### 라이브 DB 의 한계 (코드 병행 필요)

introspection 은 **DB 가 강제하는 것만** 보여준다:

- **soft 참조 안 보임** — FK 제약 없이 값으로만 매칭하는 참조(lookup slug 등)는
  introspection 에 안 잡힌다. `soft` edge 는 repository/쿼리 코드(소스 3)로 보강한다.
- **deprecated 의미 없음** — DB 엔진엔 "deprecated" 개념이 없다. `dep` 분류·edge 는
  마이그레이션 주석·코드 맥락(소스 1·3)에서 온다.
- **fk vs hier 는 의미 구분** — introspection 은 둘 다 그냥 FK 로 준다. 위계/소유 계층
  여부는 도메인 판단(아래 Edge kind 판정)으로 나눈다.

따라서 최고 충실도 = 라이브 DB(실 스키마·강제 FK) + 코드(soft·dep 보강). footer 에는
`출처: live DB <db>@<host> (introspection) + 코드 보강` 로 적고, introspection 으로 확정한
부분은 추측 캐비엇 없이 SSOT 로 표기한다.

## 1. 마이그레이션 디렉토리 (가장 신뢰도 높음)

`migrations/`, `db/migrate/`, `prisma/migrations/`, `alembic/versions/` 등.

- `CREATE TABLE` 로 테이블·컬럼·타입·제약(PK/UNIQUE/NOT NULL) 추출.
- `REFERENCES` / `FOREIGN KEY` 로 실 FK edge 추출. `ON DELETE SET NULL|RESTRICT|CASCADE`
  는 컬럼 li 우측 회색 텍스트로 기록(`SET NULL` 등).
- `ALTER TABLE … ADD COLUMN|CONSTRAINT` 누적분을 **시간순으로 합산** — 최종 스키마는
  baseline + 모든 ALTER 의 누적이다. 한 마이그만 보고 단정하지 말 것.
- baseline CREATE 가 디렉토리 밖(초기 dump)일 수 있다 — 그럴 땐 repository/ORM 코드와
  ALTER 로 재구성하고, footer 에 "정확 SSOT = 운영DB information_schema" 처럼 한계를 명시.

## 2. ORM 모델 / 엔티티 정의

`models.py`(Django/SQLAlchemy), `*.entity.ts`(TypeORM), `schema.prisma`,
`*.model.ts`, Sequelize `define(...)` 등.

- 클래스/모델 = 테이블, 필드 = 컬럼.
- 관계 데코레이터/헬퍼로 edge: `ForeignKey`/`@ManyToOne`/`@OneToMany`/`belongsTo`/
  `references`/Prisma `@relation`. `@ManyToMany`/조인테이블은 N:M 중간 테이블로 그린다.
- `unique=True`/`@Index({unique})`/`@@unique([...])` → UQ 뱃지. 복합 UQ 는
  `(col_a, col_b)` 한 li 로.

## 3. Repository / 쿼리 코드 (보조 — 스키마가 흩어졌을 때)

`*-repository.ts`, DAO, raw SQL 쿼리. CREATE/모델이 불완전할 때 실제 SELECT/INSERT 의
컬럼명·JOIN 조건으로 빈칸을 메운다. JOIN 키가 FK 인지 soft 참조인지 구분:
DB 제약이 있으면 fk, 코드에서 값만 매칭(제약 없음)이면 **soft**.

## 4. 사용자 산문 / plan 문서

사용자가 말로 스키마를 기술하거나, deep-plan 의 PLAN 문서 DB 섹션에서 올 때. 모호한
컬럼/관계가 있으면 그릴 수 있을 만큼만 **한 번에 하나씩** 확인 — 전체 인터뷰는 과함.
plan 입력이면 plan 의 Files/Steps 가 이미 anchor 다; 거기 적힌 테이블만 그린다.

## 테이블 분류 (헤더 색을 정함)

| 분류 | 클래스 | 언제 |
|---|---|---|
| **hub** | `tbl hub` | 도메인 중심 — 다수 테이블이 이걸 참조. ERD 의 주인공. 보통 1개 |
| **lookup** | `tbl lookup` | 분류축/enum 테이블 (slug PK, label, sort_order). soft 참조 대상 |
| **deprecated** | `tbl dep` | collapse/rename/DROP 대기. edge 도 `dep` kind |
| **일반** | `tbl` (클래스 없음) | 그 외 전부 |

분류가 모호하면 일반(`tbl`)으로 둔다 — 색은 강조 도구일 뿐, 틀린 hub 지정보다 무색이 낫다.

## Edge kind 판정

| kind | 색 | 언제 |
|---|---|---|
| `fk` | green(brand) | 실 FK, 도메인 핵심 참조 (자식 → 부모) |
| `hier` | gray | 위계/구조 FK — 조직/소유 계층(company←brand←member 류) |
| `dep` | red dashed | deprecated 테이블이 거는/받는 참조 |
| `soft` | purple dashed | DB FK 제약 **없이** 값으로만 매칭(lookup slug 등) |

`fk` vs `hier` 는 의미 구분일 뿐 둘 다 실제 FK — 핵심 도메인 참조는 fk, 단순 소유/계층은
hier 로 시각 분리하면 그림이 읽힌다. 구분이 안 서면 전부 `fk` 로.

## 레이아웃 (절대배치 — 자동 레이아웃 도입 금지, YAGNI)

엔진은 테이블 위치를 받아 wire 만 자동으로 그린다. 위치는 손으로 정한다:

- 카드 폭 250px 고정, 높이는 컬럼 수에 따라 가변(카드당 최대 30컬럼 표시 — 초과분은
  템플릿이 자동으로 접는다). **카드 간 가로 ≥ 300px, 세로 ≥ 150px 간격**을 둬 wire 와
  라벨이 겹치지 않게.
- **hub 를 중앙**에, 참조하는 테이블들을 주변에 그룹별로 군집. 같은 도메인 그룹
  (lookup / entitlement / hierarchy 등)은 한 영역에 모으고 `grp-label` 한 줄(한글)을
  위에 둔다.
- `.stage` 의 `{{STAGE_W}}`/`{{STAGE_H}}` 를 모든 카드를 감싸도록 설정(가장 오른쪽
  카드 left+250+여백, 가장 아래 카드 top+높이+여백). 너무 작으면 잘리고, 너무 크면 빈
  공간이 휑하다.
- **전체 스키마를 그리는 게 기본**이다 — 클릭 포커스·검색이 탐색을 담당하므로 미리
  접거나 좁히지 않는다. 컬럼이 아주 많은 테이블은 카드 30컬럼 접기가 밀도를 지켜준다.
  40+ 테이블 초대형만 사용자와 범위(도메인 분할)를 협의한다.

## 5. 진단 — ACID 갭 · 구조 개선 제안 (`DATA.findings`)

ERD 에는 스키마 도식과 함께 **진단 패널**이 실린다 — 현 스키마가 ACID 관점에서 어디가
새는지, 어떤 테이블을 쪼개거나 정리할 후보인지. 진단은 **실측 근거가 있는 제안**이지
단정이 아니다 — 각 finding 에 근거(evidence)·영향(impact)·개선안(proposal)을 채우고,
추측이면 "추정" 을 명시한다. 확인 안 된 문제를 지어내지 않는다 — **findings 0건이면
빈 배열**로 두는 게 맞다(진단 버튼 자동 숨김).

축(axis)별 휴리스틱과 증거 쿼리 (전부 읽기 전용):

**C — Consistency (일관성): DB 가 규칙을 강제하는가**

| 신호 | 증거 쿼리 (읽기 전용) | 심각도 |
|---|---|---|
| soft 참조(FK 제약 없는 값 매칭) | 고아값 실카운트: `SELECT count(*) FROM child c LEFT JOIN parent p ON c.ref=p.key WHERE c.ref IS NOT NULL AND p.key IS NULL` — 0건이면 "현재 고아 없음, 단 DB 미강제" 로 톤 낮춤(mid→info 아님, mid 유지: 강제 부재 자체가 갭) | 고아 존재=high / 0건=mid |
| enum 성 varchar(status/type/state 류)에 CHECK 없음 | `SELECT DISTINCT <col>` 로 실제 값 종류 확인 | mid |
| 자연키 후보(email/slug/sku)에 UNIQUE 없음 | 중복 실카운트: `SELECT <col>, count(*) FROM t GROUP BY <col> HAVING count(*)>1 LIMIT 5` | 중복 존재=high / 없음=mid |
| FK 에 ON DELETE 규칙 미지정(기본 NO ACTION 방치) | introspection 의 delete_rule | info |

**A — Atomicity (원자성): 다중 테이블 쓰기가 트랜잭션으로 묶이는가** — 코드 소스가
있을 때만. repository/service 에서 여러 테이블을 잇달아 쓰는 흐름(주문+주문항목,
집계 갱신)을 찾고 `BEGIN`/`transaction(`/`.transaction` 래핑 여부를 grep. 래핑 없으면
mid("부분 실패 시 반쪽 데이터"). 코드 없이 스키마만으로는 판단 불가 — 지어내지 않는다.

**I — Isolation (고립성): 동시성 제어 흔적** — 코드 소스가 있을 때만. 카운터/재고류
컬럼(view_count·stock·balance)의 read-modify-write 패턴 + `FOR UPDATE`/원자적
`SET x=x+1`/version 컬럼(낙관락) 부재를 grep. 부재면 info~mid("동시 갱신 유실 가능").

**D — Durability (지속성): 엔진 설정** — 라이브 DB 일 때만.
- SQLite: `PRAGMA journal_mode;` — `delete`(기본)면 info("WAL 권장 — 동시 읽기·크래시 내성"), `wal` 이면 통과.
- PostgreSQL: `SHOW synchronous_commit; SHOW fsync;` — off 면 high.
- MySQL: `SELECT table_name, engine FROM information_schema.tables WHERE engine='MyISAM'` — MyISAM 은 트랜잭션 자체 미지원 = high. `innodb_flush_log_at_trx_commit` ≠1 이면 mid.

**S — 구조 (분할·정리)**

| 신호 | 판정 | 심각도 |
|---|---|---|
| 넓은 테이블 — 컬럼 20+ 이고 prefix 그룹(예: `shipping_*` 6개)이 보임 | 그룹별 1:1 분리 후보. 컬럼 나열을 근거로 | mid |
| 반복 suffix 컬럼(`tag1,tag2,tag3` 류) | 1:N 정규화 후보 | mid |
| 고성장 로그성 테이블(적재량이 타 테이블 대비 10배+·append-only 이름 `*_logs`/`*_events`)이 트랜잭션 테이블과 같은 DB | 파티셔닝/보존정책/분리 검토 | info |
| **삭제 후보** — 적재 0 + 들어오는 edge 0 + (코드 소스 있으면) 참조 grep 0 | "삭제 후보" 로만 제시. proposal 에 **liveness 3증거 절차**(활성 커넥션 0 · 최근 write 없음 · 앱/설정/타 repo 참조 0 — `db-drop-preflight`) 를 반드시 포함. "지워도 됨" 단정 금지 | info~mid |
| deprecated 테이블(dep 분류)이 여전히 참조를 받음 | 대체 경로·DROP 순서를 proposal 로 | mid |

`DATA.findings` 작성 규칙: `title`/`evidence`/`impact`/`proposal` 전부 한글 산문.
evidence 에는 실측 수치를 그대로 (예: "고아값 37건 (LEFT JOIN 실카운트)"). 심각도는
**실위험=high / 권장=mid / 참고=info** — 갭 개수를 부풀리려 info 를 남발하지 않는다.
NoSQL/BASE 류 의도적 트레이드오프가 보이면(예: 로그 테이블 FK 생략) 그 가능성도
proposal 에 병기한다 — 갭이 늘 결함은 아니다.

## 검증 (그린 뒤, 게시 전)

- 모든 `DATA.edges` 의 from/to 가 `DATA.tables[].id` 와 일치하는가 — 오타 한 글자면
  그 wire 와 포커스 이웃 판정이 조용히 빠진다. grep 등으로 기계 대조한다.
- 샘플 데이터에 마스킹 누락 PII 가 없는가 — email/이름/전화/토큰 패턴 재확인.
- 가능하면 게시 전 소스 파일을 브라우저로 열어 wire 가 카드를 관통하거나 라벨이 겹치면
  위치를 조정하고, 카드 클릭→포커스·패널·탭 전환이 도는지 확인한다.
- 추측으로 그린 컬럼/관계가 있으면 footer 에 명시. SSOT 가 운영DB 면 그 사실을 적는다.
