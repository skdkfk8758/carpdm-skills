# Schema discovery — 스키마를 어디서 어떻게 재구성하나

ERD 를 그리려면 먼저 **테이블·컬럼·관계**를 확정해야 한다. 추측 금지 — 실제 소스를
Read/Grep 으로 확인한다(karpathy 원칙 1). 입력은 보통 다음 넷 중 하나다.

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
