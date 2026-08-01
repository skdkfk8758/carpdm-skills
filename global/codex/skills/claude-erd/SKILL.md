---
name: claude-erd
description: Imported Claude skill for generating self-contained HTML ERDs from verified schema sources.
---

# ERD — DB 스키마를 self-contained HTML 관계도로

DB 스키마를 받아 한 파일짜리 HTML ERD 를 그린다. 산출물은 외부 의존 없이 브라우저에서
바로 열리는 `.html` 하나 — 테이블은 컬럼명·타입·아이콘이 달린 dbdiagram 풍 카드, 관계는
SVG 로 자동 라우팅되는 베지어 곡선(4종 색 + crow's foot)이다. **스키마를 그리지, 스키마를
바꾸지 않는다** — 마이그레이션 작성·DB 변경은 이 스킬의 일이 아니다.

핵심 자산은 `assets/erd-template.html` 이다. 토큰 CSS·아이콘(mask)·**SVG wire 엔진(베지어
라우팅 + crow's foot 글리프)** 은 검증된 채로 들어 있어 매번 다시 짜지 않는다 — 당신이
채우는 건 테이블 카드·`EDGES` 배열·그룹 라벨·레이아웃뿐이다. 베지어/글리프를 손으로 다시
쓰면 미묘하게 틀어진다; 엔진은 verbatim 으로 보존한다.

## 흐름

### Step 1 — 스키마 재구성 (추측 금지)

입력 소스에서 테이블·컬럼·관계를 실제로 확인한다 — `/Users/carpdm/.codex/skills/claude-erd/references/schema-discovery.md`
를 Read 해 소스별(**라이브 DB introspection** / 마이그레이션 / ORM 모델 / repository 코드
/ 산문·PLAN) 추출법과 테이블 분류·edge kind 판정·레이아웃·검증 기준을 따른다. 열어보지
않은 테이블/컬럼/관계를 그리는 것은 실패다. 불확실하면 footer 에 한계를 명시한다.

**라이브 DB 가 가능하면 그게 SSOT 다.** 코드베이스에 접속 정보(`.env` `DATABASE_URL`,
docker-compose, 프레임워크 설정)가 있거나 사용자가 connection string 을 주면, 실제 DB 에
붙어 `information_schema`/카탈로그를 **읽기 전용**으로 introspection 해 현재 운영 스키마
그대로를 얻는다(마이그레이션 drift 없음). 단:

- **읽기 전용만** — introspection SELECT/`SHOW`/`PRAGMA`/`db pull`. 쓰기·DDL 절대 금지.
- **접속 전 확인** — host 가 localhost 가 아니거나 이름에 `prod`/`live` 가 보이면 운영
  DB 로 간주하고 접속 전 사용자에게 명시 확인. 로컬/replica/스테이징을 우선 권한다.
- **credential 비노출** — 비번·전체 connection string 을 출력·footer 에 찍지 않는다.
- **한계** — introspection 은 강제된 FK 만 본다. soft 참조·deprecated 는 안 잡히므로
  코드 소스를 병행한다. 상세 쿼리·안전수칙은 schema-discovery.md §0.

scope 가 큰 스키마(테이블 20+)면 사용자에게 **무엇을 중심으로** 그릴지 먼저 확인한다 —
전부 그리면 읽히지 않는다. 중심 hub + 직접 관계 1홉이 보통 맞다.

### Step 2 — 템플릿 채우기

`assets/erd-template.html` 를 산출 경로로 복사한 뒤 placeholder 6개를 채운다. CSS 토큰·
아이콘(mask)·`<script>` 엔진(베지어 라우팅 + crow's foot 글리프)은 **건드리지 않는다**.

placeholder 를 실제 내용으로 바꾸면서, 각 placeholder **위의 작성 안내 주석 블록**
(`<!-- ===== TABLES — ... -->`, `<!-- ===== GROUP LABELS — ... -->`, `<!-- ===== NOTES
... -->` 같은 가이드)은 **결과물에서 제거**한다 — 그건 작성자용 비계이지 전달물의
일부가 아니다. 산출 ERD 에는 아래 "결과물 주석" 규칙대로 쓴 **실제 한글 섹션 주석만**
남긴다.

| placeholder | 채울 것 |
|---|---|
| `{{TITLE}}` / `{{HEADER_H1}}` / `{{HEADER_SUB}}` | 문서 제목·헤더 제목(중심 테이블 `<b>` 강조)·한 줄 부제(출처 경로 포함) |
| `{{STAGE_W}}` / `{{STAGE_H}}` | 모든 카드를 감싸는 stage 픽셀 크기 (schema-discovery 레이아웃 기준) |
| `{{GROUP_LABELS}}` | 도메인 그룹마다 `<div class="grp-label" style="left:..;top:..">NAME</div>` |
| `{{TABLES}}` | 테이블당 `.tbl` 카드 하나 (분류 클래스 + 컬럼 li). 템플릿 주석에 행 구조 예시 있음 |
| `{{EDGES}}` | `['t_from','t_to','label','kind'],` 줄들. kind ∈ `fk`/`hier`/`dep`/`soft` |
| `{{NOTES}}` / `{{FOOTER}}` | (선택) 결정·collapse 맥락 메모 / 비고·한계·출처 |

**시각 어휘** (템플릿 CSS 에 정의됨, schema-discovery 에 판정 기준):

- 테이블 클래스 — `hub`(도메인 중심·녹색) / `lookup`(분류축·보라) / `dep`(deprecated·적색) / 없음(일반·슬레이트).
- 컬럼 행(li) 구조 — 좌측 `.l`(컬럼명 `.cn` + 선택 아이콘) ⟶ 우측 `.ty`(데이터 타입 + 선택 제약 pill). dbdiagram 풍 가독성.
  - PK 행: `<li class="pk">` (컬럼명 bold).
  - 아이콘 `.ic` — `ic-pk`(열쇠) / `ic-fk`(링크) / `ic-soft`(링크·연보라, FK 없는 값참조) / `ic-note`(노트, `title=` 로 코멘트 툴팁). 컬럼명 바로 뒤에 인라인.
  - 제약 pill `.pill` — 타입 우측 회색 알약 `NN`(NOT NULL) / `UQ`(UNIQUE). 복합 UQ 는 한 행에 `(a, b)`.
  - 코멘트를 **보이게** 하려면 `.ty` 다음에 `<div class="cmt">설명</div>` (행 아래 전폭, `↳` prefix). 짧으면 `ic-note` 의 `title` 툴팁으로 갈음.
- 관계선 — `fk` green / `hier` gray / `dep` red dashed / `soft` purple dashed. 끝점에 **crow's foot**(자식=갈래발 many / 부모=단일 바 one)이 자동으로 붙는다(`from`=자식, `to`=부모).
- 카드 id 는 `t_<table>`; `EDGES` 가 이 id 로 참조한다. **id 오타 = 그 선 안 그려짐.**

#### 결과물 주석·설명은 한글로 (필수)

생성된 `.html` 은 그 자체로 읽히는 도식 문서다 — 그 안의 **모든 설명적 주석과 사람이
읽는 텍스트를 한국어로** 쓴다. 이건 스킬 산출물 정책이다(글로벌 "code comments=English"
는 skill 소스에 적용되고, 여기 대상은 *사용자에게 전달되는 ERD 결과물*이다 — 한국어
사용자용이고 참고 ERD 도 한글 주석·메모·footer 를 쓴다). 구체적으로:

- **그룹 섹션 주석** — `{{TABLES}}` 안에서 테이블을 도메인 그룹별로 묶고 각 묶음 위에
  한글 섹션 주석을 단다. 영어 그룹명 금지:
  ```html
  <!-- ===== 허브 (도구 카탈로그) ===== -->
  <!-- ===== 분류축 (LOOKUP) ===== -->
  <!-- ===== 위계 (조직 계층) ===== -->
  ```
- **EDGES 주석** — `{{EDGES}}` 안에서 관계를 종류별(fk/hier/dep/soft)로 묶고 각 묶음
  위에 한글 한 줄 주석으로 무엇을 뜻하는지 단다(예: `// 실 FK — 도구 카탈로그 참조`,
  `// soft 참조 — FK 없이 slug 값 매칭`). 비자명한 관계는 그 줄 끝에 한글 꼬리 주석.
- **`.note` 블록·`{{FOOTER}}`** — 결정·collapse·deprecation 맥락, 비고·한계·출처를
  모두 한국어 산문으로. 추측으로 그린 부분의 한계 명시도 한글.
- 컬럼 li 의 `.cmt` 코멘트·`title` 툴팁·보조 텍스트(`SET NULL`, `link 전용` 등)도
  사람이 읽는 부분이므로 한글이 자연스러우면 한글(식별자·타입 키워드 `bigint`/`varchar`
  /`CASCADE`, 제약 pill `NN`/`UQ` 등은 원문 유지).

엔진 `<script>` 안의 영어 기술 주석(`// perimeter point ...`)은 verbatim 보존
대상이라 건드리지 않는다 — 한글화하지 말 것(엔진은 손대지 않는 게 원칙).

### Step 3 — 토큰 충실도 (DESIGN.md 가 있으면)

컨텍스트에 `DESIGN.md`/추출 디자인 시스템이 있으면 `:root` 의 색·타이포 토큰을 그 값으로
덮어쓴다(참고 ERD 가 "DESIGN.md mirror" 로 한 것처럼). 없으면 템플릿 중립 기본을 그대로
둔다. **레이아웃·아이콘·뱃지·edge 토큰은 항상 보존** — 이건 도식 문법이지 브랜드가 아니다.
ERD 는 리뷰용 도식이라 imprint 수준의 token-traceability 까지는 과투자다 — 색만 맞춘다.

### Step 4 — 검증하고 제시

schema-discovery 의 검증 절을 돈다: 모든 `EDGES` id 가 실제 카드 id 와 일치하는지,
브라우저로 열어 wire 가 카드를 관통하거나 라벨이 겹치지 않는지(겹치면 위치 조정 — 엔진은
load/resize 에 자동 재실행). 그 뒤 `/Users/carpdm/.codex/skills/claude-craft-core/references/output-contract.md`
의 고정 블록으로 보고한다(L1 `result:` + L2 열기 블록; erd 는 L3 비적용 — 산출 단발형).
미설치면 같은 형식을 직접 적용:

```
result: <중심 테이블> ERD 산출 — N 테이블 / M 관계, 출처 <경로>

산출물 — 열기:
- ERD `<상대경로>.html`  →  `open <상대경로>.html`

(`open` = macOS. Linux `xdg-open <path>`, Windows `start <path>`.)
```

산출 경로 기본은 `docs/preview/<중심>-erd.html`(프로젝트가 다른 preview/diagram 위치를
쓰면 그곳). deep-plan 이 호출했을 때는 plan 과 같은 디렉토리·basename 에 `-erd.html`.

## Anti-patterns

- **SVG wire 엔진을 다시 짜기** — 템플릿 `<script>` 는 verbatim 보존. 베지어를 손으로 쓰면 틀어진다.
- **열어보지 않은 테이블/컬럼/관계를 그리기** — Step 1 에서 실제 소스 확인. 불확실은 footer 에 명시.
- **자동 레이아웃(force-directed 등) 도입** — YAGNI. 위치는 손으로, 엔진은 wire 만 자동.
- **거대 스키마를 통째로** — 20+ 테이블을 한 장에 다 넣으면 안 읽힌다. 중심 + 1홉으로 좁히거나 보조군을 한 카드로 접는다.
- **마이그레이션/DDL 작성** — erd 는 그리기만. 스키마 변경이 필요하면 forge/renew.
- **라이브 DB 에 쓰기·DDL 실행** — introspection(읽기 전용 SELECT/`SHOW`/`PRAGMA`)만. `INSERT`/`ALTER`/`DROP` 등 절대 금지. 운영 DB 는 접속 전 확인, credential 은 출력·footer 에 비노출.
- **`EDGES` id 오타** — `t_<table>` 카드 id 와 정확히 일치해야 선이 그려진다. 그린 뒤 반드시 검증.
- **결과물 주석·`.note`·footer 를 영어로** — 산출 ERD 의 설명 텍스트는 한국어가 기본(Step 2 규칙). 단 엔진 `<script>` 의 영어 기술 주석은 verbatim 보존(한글화 금지).
