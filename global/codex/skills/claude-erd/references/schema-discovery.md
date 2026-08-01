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
-- 테이블
SELECT table_name FROM information_schema.tables
WHERE table_schema='public' AND table_type='BASE TABLE' ORDER BY table_name;
-- 컬럼 (타입·nullable·default)
SELECT table_name, column_name, data_type, is_nullable, column_default
FROM information_schema.columns WHERE table_schema='public'
ORDER BY table_name, ordinal_position;
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
`referential_constraints` 에서.

**SQLite** (`sqlite3 <file.db>`): `SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';`
(`sqlite_%` 내부 테이블 — `sqlite_sequence`/FTS shadow 등 — 제외)
→ 테이블별 `PRAGMA table_info(<t>);`(컬럼·PK), `PRAGMA foreign_key_list(<t>);`(FK·on_delete),
`PRAGMA index_list(<t>)`+`index_info`(UNIQUE).

**ORM/프레임워크 폴백** (CLI 없거나 접속만 코드로 가능할 때): Prisma `npx prisma db pull`
→ `schema.prisma` 재생성 후 소스 2 로 읽기, Django `python manage.py inspectdb`,
Rails `rails db:schema:dump` → `db/schema.rb`. introspection 결과 산출물을 소스로 다시 읽는다.

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

- 카드 폭 228px 고정, 높이는 컬럼 수에 따라 가변. **카드 간 가로 ≥ 280px, 세로 ≥
  150px 간격**을 둬 wire 와 라벨이 겹치지 않게.
- **hub 를 중앙**에, 참조하는 테이블들을 주변에 그룹별로 군집. 같은 도메인 그룹
  (lookup / entitlement / hierarchy 등)은 한 영역에 모으고 `grp-label` 한 줄을 위에 둔다.
- `.stage` 의 `{{STAGE_W}}`/`{{STAGE_H}}` 를 모든 카드를 감싸도록 설정(가장 오른쪽
  카드 left+228+여백, 가장 아래 카드 top+높이+여백). 너무 작으면 잘리고, 너무 크면 빈
  공간이 휑하다.
- 테이블이 ~12개 넘어 한 화면이 빡빡하면 보조 테이블 군을 "persona_* 트리 (10 tables)"
  처럼 **한 카드로 접어** 대표 나열한다(참고 ERD 의 `persona_tree` 패턴).

## 검증 (그린 뒤)

- 모든 `EDGES` 의 from/to id 가 실제 `.tbl` id(`t_<name>`)와 일치하는가 — 오타 한 글자면
  그 wire 가 안 그려진다.
- 브라우저로 열어 wire 가 카드를 관통하거나 라벨이 겹치면 위치를 조정(엔진 재실행 자동).
- 추측으로 그린 컬럼/관계가 있으면 footer 에 명시. SSOT 가 운영DB 면 그 사실을 적는다.
