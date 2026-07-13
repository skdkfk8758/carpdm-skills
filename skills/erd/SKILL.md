---
name: erd
description: DB 스키마(라이브 DB 접속·마이그레이션·ORM 모델·repository 코드·산문·PLAN 문서)를 입력으로 받아, 인터랙티브 ERD(엔티티 관계도)를 Claude Artifact(캔버스)로 게시한다. dbdiagram 풍 테이블 카드(컬럼·타입·PK/FK 아이콘·NN/UQ pill + 적재량 배지) + SVG 자동 라우팅 관계선(실 FK/위계/deprecated/soft 4종 + crow's foot)에, 테이블 클릭 시 연결된 테이블만 하이라이트하는 포커스 모드와 우측 상세 패널(구조 탭=전체 컬럼·제약·관계, 데이터 탭=적재량·마스킹된 샘플 rows), 테이블 검색, 그리고 진단 패널(ACID 갭 분석 — FK/CHECK/UNIQUE 제약 부재·고아값 실카운트·트랜잭션 미래핑·엔진 설정 + 구조 개선 — 테이블 분할·정규화·삭제 후보, 실측 근거 기반 제안)까지 갖춘 단일 self-contained 페이지다. 접속 정보(.env DATABASE_URL·docker-compose·프레임워크 설정)가 있거나 사용자가 connection string 을 주면 실제 DB 에 읽기 전용으로 붙어 information_schema introspection + 테이블별 적재량·샘플(PII 마스킹)을 수집해 현재 운영 스키마 그대로 그린다(접속 전 확인, credential 비노출, 쓰기·DDL 금지). 사용자가 DB 스키마·테이블 관계·엔티티 관계를 그림으로 보고 싶어 하거나, ERD/관계도/스키마 다이어그램/DB 구조도를 그려 달라고 할 때마다 사용한다 — "이 마이그레이션으로 ERD 그려줘", "DB 스키마 관계도", "실제 DB 접속해서 ERD 그려줘", "운영 DB 스키마 보고 관계도", "테이블 관계 시각화", "엔티티 관계도 만들어줘", "스키마 다이어그램 뽑아줘", "DB 구조 그림으로 보여줘", "테이블 데이터도 같이 보여줘", "DB 개선점/최적화 방안도 같이", "ACID 관점에서 우리 DB 분석해줘", "테이블 정리·분할 제안해줘", "draw an ERD", "/erd" 같은 표현. 마이그레이션 디렉토리나 모델 파일을 가리키며 "이거 관계 어떻게 돼 있어 그림으로" 라고 해도 마찬가지다. 코드를 빌드/수정(use forge/renew/hunt)하거나, 추출된 디자인 시스템을 재현(use imprint)하거나, 일반 UI 를 창작(use frontend-design)하는 데는 사용하지 말 것 — erd 는 스키마를 도식으로 그릴 뿐 마이그레이션을 작성하거나 DB 를 바꾸지 않는다.
---

# ERD — DB 스키마를 인터랙티브 Artifact 관계도로

DB 스키마를 받아 **Claude Artifact(캔버스)로 게시되는 인터랙티브 ERD** 를 그린다.
처음 보는 개발자가 열어서 바로 이해하는 게 품질 기준이다:

- **다이어그램** — dbdiagram 풍 테이블 카드(전 컬럼 + PK/FK 아이콘 + NN/UQ pill +
  헤더 적재량 배지) + SVG 자동 라우팅 관계선(4종 색 + crow's foot).
- **클릭 포커스** — 테이블 클릭 시 그 테이블·연결선·1홉 이웃만 선명, 나머지 dim.
  배경 클릭/ESC 로 해제.
- **상세 패널** — 클릭 시 우측 슬라이드 패널. 탭 [구조]=전체 컬럼·제약·관계 목록
  (관계의 테이블명 클릭 → 그쪽으로 포커스 점프), [데이터]=적재량 + 마스킹된 샘플 rows.
- **검색** — 헤더 검색창, Enter 로 매칭 테이블에 포커스 + 스크롤 이동.
- **진단** — ACID 갭 분석 + 구조 개선(테이블 분할·정리 후보) 제안. 헤더 [진단 N건]
  버튼 → 좌측 패널(축별 그룹: A/C/I/D/구조, 근거·영향·개선안), 문제 테이블 카드엔
  ⚠ 배지(클릭 시 그 테이블 진단만 필터).
- **테마** — Artifact 뷰어의 라이트/다크를 자동 추종.

**스키마를 그리지, 스키마를 바꾸지 않는다** — 마이그레이션 작성·DB 변경은 이 스킬의
일이 아니다.

핵심 자산은 `assets/erd-template.html` 이다. 토큰 CSS(라이트/다크)·아이콘·**SVG wire
엔진 + 포커스/패널/검색 인터랙션**은 검증된 채로 들어 있어 매번 다시 짜지 않는다 —
당신이 채우는 건 `DATA` 객체(tables/edges)·그룹 라벨·레이아웃 좌표뿐이다. 엔진 JS 를
손으로 다시 쓰면 미묘하게 틀어진다; verbatim 으로 보존한다.

## 흐름

### Step 1 — 스키마 재구성 + 적재 데이터 수집 (추측 금지)

입력 소스에서 테이블·컬럼·관계를 실제로 확인한다 — `~/.claude/skills/erd/references/schema-discovery.md`
를 Read 해 소스별(**라이브 DB introspection** / 마이그레이션 / ORM 모델 / repository 코드
/ 산문·PLAN) 추출법과 테이블 분류·edge kind 판정·레이아웃·검증 기준을 따른다. 열어보지
않은 테이블/컬럼/관계를 그리는 것은 실패다. 불확실하면 footer 에 한계를 명시한다.

**라이브 DB 가 가능하면 그게 SSOT 다.** 코드베이스에 접속 정보(`.env` `DATABASE_URL`,
docker-compose, 프레임워크 설정)가 있거나 사용자가 connection string 을 주면, 실제 DB 에
붙어 **읽기 전용**으로 다음을 수집한다:

1. **스키마** — `information_schema`/카탈로그 introspection (테이블·컬럼·PK/UQ/FK).
2. **적재량** — 테이블별 row count. 통계 기반 추정치가 기본(대형 테이블 count(\*) 는
   느리고 DB 에 부담), 정확/추정 여부를 `rowsExact` 로 구분해 담는다.
3. **샘플 데이터** — 테이블별 `LIMIT 5`. **PII 성 컬럼은 수집 직후 마스킹**하고,
   마스킹 완료된 값만 `DATA.sample` 에 넣는다 — 원본 값이 Artifact 에 실리면 안 된다.
   수집 쿼리·마스킹 규칙은 schema-discovery.md §0b.

안전 수칙 (어기면 사고):
- **읽기 전용만** — introspection SELECT/`SHOW`/`PRAGMA`/`db pull`. 쓰기·DDL 절대 금지.
- **접속 전 확인** — host 가 localhost 가 아니거나 이름에 `prod`/`live` 가 보이면 운영
  DB 로 간주하고 접속 전 사용자에게 명시 확인. 로컬/replica/스테이징을 우선 권한다.
- **credential 비노출** — 비번·전체 connection string 을 출력·footer 에 찍지 않는다.
- **한계** — introspection 은 강제된 FK 만 본다. soft 참조·deprecated 는 안 잡히므로
  코드 소스를 병행한다.

**DB 접속이 불가한 정적 소스(마이그레이션·ORM)만 있을 때**도 데이터 탭은 유지한다 —
`rows: null`, `sample: null` 로 두면 템플릿이 "적재 정보 없음 — 정적 소스 기반" 안내를
자동 표시한다. 데이터 탭을 빼거나 UI 를 바꾸지 않는다(생성물 간 일관성).

**렌더 범위는 전체 스키마가 기본이다** — 클릭 포커스·검색이 탐색을 담당하므로 현행
중심+1홉으로 미리 좁히지 않는다. 단 **40+ 테이블 초대형**이면 사용자에게 범위(도메인
단위 분할 등)를 먼저 확인한다 — 좌표 손배치가 그 규모에선 품질을 잃는다.

### Step 1.5 — 진단 (ACID 갭 + 구조 개선)

스키마·데이터를 손에 쥔 김에 **진단**을 돌린다 — schema-discovery.md §5 의 축별
휴리스틱(C=제약 부재·고아값, A=트랜잭션 미래핑, I=동시성 제어 부재, D=엔진 설정,
S=넓은 테이블 분할·삭제 후보)과 증거 쿼리(전부 읽기 전용)를 따라 `DATA.findings` 를
채운다. 원칙:

- **실측 근거 필수** — finding 마다 evidence 에 쿼리 결과·스키마 사실을 그대로.
  확인 안 된 문제를 지어내지 않는다. 이슈가 없으면 findings 는 빈 배열(정상).
- **제안이지 단정 아님** — 특히 삭제 후보는 proposal 에 liveness 3증거 절차를 포함하고
  "지워도 됨" 이라 쓰지 않는다. 의도적 트레이드오프(BASE 성 설계) 가능성도 병기.
- 소스가 정적(코드·마이그레이션)뿐이면 가능한 축만 진단한다 — A/I 는 코드 grep,
  C 의 고아값 실카운트·D 는 라이브 DB 전용. 못 돌린 축은 지어내지 말고 생략.

### Step 2 — 템플릿 채우기 (DATA 객체)

`assets/erd-template.html` 를 산출 경로로 복사한 뒤 placeholder 를 채운다. CSS 토큰·
`<script>` 엔진(렌더·wire·포커스·패널·검색)은 **건드리지 않는다**. 카드 HTML 을 손으로
쓰지 않는다 — 카드·패널 모두 `DATA` 객체에서 스크립트가 생성한다.

| placeholder | 채울 것 |
|---|---|
| `{{TITLE}}` / `{{HEADER_H1}}` / `{{HEADER_SUB}}` | 문서 제목·헤더 제목(중심 테이블 `<b>` 강조)·한 줄 부제(출처 포함) |
| `{{STAGE_W}}` / `{{STAGE_H}}` | 모든 카드를 감싸는 stage 픽셀 크기 (schema-discovery 레이아웃 기준) |
| `{{GROUP_LABELS}}` | 도메인 그룹마다 `<div class="grp-label" style="left:..;top:..">한글 그룹명</div>` |
| `{{DATA_TABLES}}` | 테이블당 객체 하나 — 아래 표기. 도메인 그룹별로 묶고 각 묶음 위에 한글 섹션 주석 |
| `{{DATA_EDGES}}` | `['자식테이블','부모테이블','라벨','kind'],` 줄들. kind ∈ `fk`/`hier`/`dep`/`soft`. 종류별 묶음 + 한글 주석 |
| `{{DATA_FINDINGS}}` | Step 1.5 진단 결과 — `{axis, sev, tables, title, evidence, impact, proposal}` 객체들(스펙은 템플릿 주석·schema-discovery §5). 없으면 비움 |
| `{{NOTES}}` / `{{FOOTER}}` | (선택) 결정·collapse 맥락 메모 / 비고·한계·출처 |

**`DATA.tables` 항목** (템플릿 상단 주석에도 동일 스펙 있음):

```js
{ id:'users',            // 테이블명 그대로 — edges 가 이 id 로 참조 (오타 = 선·포커스 누락)
  cls:'hub',             // ''(일반) | 'hub' | 'lookup' | 'dep' — 판정 기준은 schema-discovery
  x:560, y:150,          // 카드 절대좌표 (레이아웃은 손으로)
  rows:1204,             // 적재 건수. 모르면 null (정적 소스)
  rowsExact:true,        // true=정확값 / false=추정치(통계 기반)
  comment:'회원 계정',    // 테이블 설명 — 한글
  columns:[
    {n:'id', t:'bigint', pk:true},
    {n:'brand_id', t:'bigint', fk:'brands.id', nn:true},
    {n:'category', t:'varchar', soft:'tool_categories.slug'},
    {n:'email', t:'varchar', uq:true, c:'로그인 식별자'},   // c = 한글 코멘트
    {n:'a', t:'int', uq:'(a, b)'},                          // 복합 UQ 는 문자열로
  ],
  sample:{ cols:['id','email','created_at'],
           rows:[[1,'k***@d***.net','2026-01-03'], ...] },  // 마스킹 완료값만. 없으면 null
},
```

카드에는 컬럼이 30개까지 보이고 초과분은 "…외 N개" 로 접힌다(전체는 패널 구조 탭) —
이 임계는 템플릿 `CARD_COL_LIMIT` 이 처리하므로 데이터는 늘 전 컬럼을 넣는다.

#### 결과물 주석·설명은 한글로 (필수)

생성된 ERD 는 그 자체로 읽히는 도식 문서다 — 그 안의 **모든 설명적 주석과 사람이 읽는
텍스트를 한국어로** 쓴다(글로벌 "code comments=English" 는 skill 소스에 적용되고, 여기
대상은 *사용자에게 전달되는 ERD 결과물*이다). 구체적으로:

- **`{{DATA_TABLES}}` 그룹 주석** — 도메인 그룹별로 묶고 각 묶음 위에 한글 섹션 주석
  (`// ===== 허브 (도구 카탈로그) =====`). 영어 그룹명 금지.
- **`{{DATA_EDGES}}` 주석** — 관계를 종류별(fk/hier/dep/soft)로 묶고 각 묶음 위에 한글
  한 줄 주석(예: `// 실 FK — 도구 카탈로그 참조`). 비자명한 관계는 줄 끝 한글 꼬리 주석.
- **`comment`/`c` 필드·`.note` 블록·`{{FOOTER}}`** — 테이블/컬럼 설명, 결정·deprecation
  맥락, 비고·한계·출처 모두 한국어 산문. 추측으로 그린 부분의 한계 명시도 한글.
- **`findings` 의 `title`/`evidence`/`impact`/`proposal`** — 진단 텍스트 전부 한국어 산문
  (SQL 키워드·컬럼명·수치는 원문).
- **그룹 라벨(`grp-label`)도 한글 우선** — 영어 보조가 필요하면 괄호로(예: `분류축 (LOOKUP)`).
  템플릿의 시각 라벨(카드 태그 허브/분류축/폐기 예정·범례·진단 축 헤더)은 이미 한글이다 —
  영어로 되돌리지 않는다.
- 식별자·타입 키워드(`bigint`/`varchar`/`CASCADE`)·제약 pill(`NN`/`UQ`)은 원문 유지.

템플릿 엔진 `<script>` 의 기존 주석은 이미 한글이다 — verbatim 보존(재작성 금지).

### Step 3 — 토큰 충실도 (DESIGN.md 가 있으면)

컨텍스트에 `DESIGN.md`/추출 디자인 시스템이 있으면 `:root` 와 `[data-theme]` 블록의
브랜드 색 토큰을 그 값으로 덮어쓴다(라이트/다크 양쪽 모두 — 한쪽만 바꾸면 테마 전환 시
어긋난다). 없으면 템플릿 중립 기본을 그대로 둔다. **레이아웃·아이콘·edge·인터랙션
토큰은 항상 보존** — 이건 도식 문법이지 브랜드가 아니다.

### Step 4 — 검증하고 Artifact 로 게시

1. **id 정합** — 모든 `DATA.edges` 의 from/to 가 `DATA.tables` 의 `id` 와 일치하는지
   확인(오타 = 그 선·포커스 누락). grep 으로 기계 대조한다.
2. **소스 파일 위치** — 기본은 scratchpad(`<scratchpad>/erd/<중심>-erd.html`).
   deep-plan 이 호출했을 때는 plan 과 같은 디렉토리에 `<basename>-erd.html` 로 둬
   재게시 소스를 남긴다.
3. **Artifact 게시** — Artifact 도구로 publish 한다. 게시 전 `artifact-design` 스킬
   로드 요구가 있으면 따르되, ERD 는 검증된 템플릿이 디자인 그 자체다 — 템플릿 구조를
   재설계하지 않는다. `favicon` 은 `"🗄️"` 고정(재게시에도 동일 유지), `description` 은
   "<중심> ERD — 테이블 N개, 관계 M건" 한 줄. 같은 ERD 갱신이면 같은 파일 경로로 재게시
   (새 경로 = 새 URL).
4. **보고** — `~/.claude/skills/craft-core/references/output-contract.md` 의 고정
   블록으로 보고한다(미설치면 같은 형식 직접 적용):

```
result: <중심 테이블> ERD 게시 — N 테이블 / M 관계, 출처 <경로 또는 live DB>

산출물 — 열기:
- ERD Artifact  →  <artifact URL>
- (소스: <소스 파일 경로> — 갱신 시 재게시용)
```

## Anti-patterns

- **엔진 JS 재작성** — 템플릿 `<script>`(렌더·wire·포커스·패널·검색)는 verbatim 보존. 손으로 다시 쓰면 틀어진다.
- **카드 HTML 손작성** — 구버전 방식. 카드·패널은 `DATA` 에서 생성된다 — HTML 을 직접 넣으면 패널·포커스와 어긋난다.
- **열어보지 않은 테이블/컬럼/관계를 그리기** — Step 1 에서 실제 소스 확인. 불확실은 footer 에 명시.
- **마스킹 전 원본 샘플을 DATA 에 넣기** — Artifact 는 호스팅된다. PII 마스킹은 수집 직후, `DATA` 에는 마스킹 완료값만.
- **대형 테이블에 count(\*)** — 수백만 행 테이블 정확 카운트는 DB 부담. 통계 추정치 + `rowsExact:false` 가 기본.
- **자동 레이아웃(force-directed 등) 도입** — YAGNI. 위치는 손으로, 엔진은 wire·인터랙션만 자동.
- **미리 스코프 축소** — 포커스·검색이 탐색을 담당한다. 40+ 초대형만 사용자와 범위 협의.
- **근거 없는 finding 지어내기** — 진단은 실측(쿼리 결과·스키마 사실·코드 grep)이 있는 것만. 이슈 0건 = 빈 배열이 정답.
- **삭제 후보를 "지워도 됨" 으로 단정** — liveness 3증거 절차 없이 drop 권고 금지 (실사고 전례).
- **마이그레이션/DDL 작성** — erd 는 그리기만. 스키마 변경이 필요하면 forge/renew.
- **라이브 DB 에 쓰기·DDL 실행** — introspection·SELECT(LIMIT)만. `INSERT`/`ALTER`/`DROP` 절대 금지. 운영 DB 는 접속 전 확인, credential 비노출.
- **`edges` id 오타** — `tables[].id` 와 정확히 일치해야 선이 그려진다. 게시 전 반드시 기계 대조.
- **결과물 주석·note·footer 를 영어로** — 산출 ERD 의 설명 텍스트는 한국어가 기본(Step 2 규칙).
