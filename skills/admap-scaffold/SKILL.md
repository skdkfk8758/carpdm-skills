---
name: admap-scaffold
description: ADMap(map.adtype.work) 지도가 이미 올라간 정적 HTML 프로젝트 폴더를 만든다 — v1 API 로 style 스냅샷을 받아 굽고, 페르소나 세그먼트 기반 인터뷰로 켤 레이어를 고르고, 서버 없이 더블클릭으로 열리는 배포 가능한 폴더(index.html·style.js·data/·media/·README·오버레이 규칙·CLAUDE.md·정적전용 가드 훅·verify.mjs)를 산출한 뒤, 그 폴더로 이동해 오버레이 작업을 이어간다. 애드타입 기획자가 광고주 제안용 지도 페이지를 시작할 때 사용 — "지도 페이지 만들어줘", "OOH 제안용 지도 띄워줘", "매체평가 지도 시작해줘", "ADMap 지도 붙인 html 만들어줘", "지도 프로젝트 스캐폴딩", "start a map page with ADMap" 같은 표현. 기존 폴더에 자기 데이터(매체 포인트·구역·히트맵)를 얹는 작업은 이 스킬이 아니라 산출된 OVERLAY-RULES.md 를 읽고 진행한다. ADMap 코드베이스 자체를 고치는 일에는 쓰지 말 것.
---

# ADMap Scaffold

기획자가 광고주 제안용 지도 페이지를 **지도가 뜨는 지점까지** 규칙적으로 시작하게 한다.
요구사항 SSOT: ADMap repo `docs/specs/planner-map-scaffold-skill/spec.md`.

## Quick start

```bash
node scripts/set-key.mjs --show            # 키 설정됐는지 확인 (마스킹 출력)
node scripts/catalog.mjs                   # 세그먼트 트리 + 미배정 레이어 목록 (JSON)
node scripts/build.mjs --out ./spotify-ooh --title "스포티파이 OOH 매체평가"
```

인자 없이 `build.mjs --out <dir>` 만 줘도 동작한다 — 레이어를 안 고르면 스냅샷 그대로 굽는다.

## API key

`ADMAP_API_KEY` 환경변수 하나만 쓴다. 스킬 파일에도, 산출물에도 키를 **절대 쓰지 않는다**.
심는 자리·교체·문제해결은 [KEY-SETUP.md](KEY-SETUP.md) 에 전부 있다. 요약:

```bash
echo -n admap_xxxx | node scripts/set-key.mjs --stdin   # 검증 + 백업 후 ~/.claude/settings.json 에 저장
```

프로젝트 `.claude/settings.json`·`.env`·산출 폴더에는 넣지 않는다(전부 git 또는 공개 배포 대상).

## Workflow

1. **키 확인** — `set-key.mjs --show`. 미설정이면 멈추고 사용자에게 요청한 뒤, 값을 받으면
   `set-key.mjs --stdin` 으로 세팅한다. 다른 파일에 손으로 쓰지 말 것.
2. **카탈로그 조회** — `node scripts/catalog.mjs`. 출력은 `{ segments[], unassigned[] }`.
3. **레이어 인터뷰 (2단, `AskUserQuestion`)**
   - ① 세그먼트: 대분류 → 소분류 다중선택. 선택된 소분류의 `layerIds` 가 켜진다.
     **`segments` 가 비어 있으면(실측: 현재 `main` 은 0개) 이 단계를 건너뛴다** — 없는 선택지를 지어내지 말 것.
   - ② 미배정: 어느 세그먼트에도 안 묶인 레이어를 flat 으로 추가 선택. `category` 로 묶어 보여주면 읽기 쉽다.
   - 사용자가 건너뛰면 **아무것도 바꾸지 않는다**(스냅샷 그대로).
   - 선택 대상은 카탈로그에 나온 레이어뿐이다. 배경 캔버스(도로·건물 등 `scope=system`)는
     카탈로그에 없어 절대 꺼지지 않는다. 단 `category: "basemap"` 인 개별 피처(공항·활주로·
     지하철역 등)는 카탈로그에 **포함되므로** 선택 대상이다 — 두 축이 다르다.
4. **건별 메타 수집** — 프로젝트명·페이지 타이틀·중심좌표·줌. 미지정이면 기본값(서울시청 z11).
5. **빌드** — `node scripts/build.mjs --out <dir> --title <t> [--selected id1,id2] [--center lng,lat] [--zoom n]`
6. **검증 결과 보고** — build.mjs 가 정적 검증(필수 파일·style.js 무손상·file:// 회귀·키 노출·
   동봉 verify.mjs 자가 실행)을 수행하고 실패 시 exit 1. 결과를 그대로 전달한다.
7. **이동 + 이어서 작업** — 산출 폴더로 `cd` 하고, 산출된 `CLAUDE.md` 와 `OVERLAY-RULES.md` 를
   **Read 한 뒤** 사용자의 오버레이 작업을 그 자리에서 이어간다. `index.html` 더블클릭으로
   열린다는 것도 알린다.
   - **훅 로드 타이밍 주의:** 산출된 `.claude/settings.json` 훅(프레임워크 차단·Stop 검증)은
     그 폴더에서 **새 세션을 열어야** 강제된다 — 훅은 세션 시작 시 로드되므로 현 세션의 `cd` 로는
     안 걸린다. 현 세션은 방금 Read 한 CLAUDE.md 불변식을 스스로 지키고, 작업 마무리마다
     `node verify.mjs` 를 직접 실행해 Stop 훅을 대신한다. 사용자에게 "다음부터는 이 폴더에서
     Claude 를 열면 가드가 자동"이라고 안내한다.

## 산출 폴더

```
<out>/
├── index.html        # maplibre 5.21.0 + pmtiles 4.4.0, style: window.__ADMAP_STYLE__
├── style.js          # 생성 시점 스냅샷 (동결 — ADMap 변경은 재실행해야 반영)
├── data/             # 기획자 geojson 자리 (빈 폴더)
├── media/            # 기획자 이미지 자리 (빈 폴더)
├── README.md         # 여는 법 · 배포법 · 스냅샷 동결 고지
├── OVERLAY-RULES.md  # 오버레이 작업 규칙 SSOT (CLAUDE.md 가 import)
├── CLAUDE.md         # 그 폴더에서 열린 세션에 auto-load — 불변식 + @OVERLAY-RULES.md
├── verify.mjs        # 정적 재검증 (스냅샷 무손상·file://·A/B 혼용·키 노출·geojson 좌표계)
└── .claude/
    ├── settings.json              # PreToolUse 가드 + Stop 검증 훅 등록
    └── hooks/
        ├── guard-static-only.mjs  # 프레임워크·번들러·패키지 도입 + style.js 편집 차단
        └── verify-stop.mjs       # 세션 종료 시 verify.mjs 실행, FAIL 이면 종료 막고 피드백
```

## 불변식 (어기면 안 되는 것)

- **산출물에 API key 0개.** style 은 빌드시점에만 API 로 받는다. `index.html` 은 런타임에 ADMap API 를 부르지 않는다.
- **`file://` 더블클릭으로 열려야 한다.** 그래서 스타일을 `style.json` + fetch 가 아니라
  `style.js`(`window.__ADMAP_STYLE__`, classic `<script src>`)로 굽는다 — maplibre 는 style URL 을
  `fetch()` 로 읽는데 `file://` origin(null) 의 로컬 fetch 는 브라우저가 막는다. 원격 타일·스프라이트는
  ADMap CDN 이 `Access-Control-Allow-Origin: *` 라 origin null 도 통과한다(실측 2026-07-23, S3 206 응답).
  `index.html` 에 로컬 `fetch`/`style: './...'` 를 되살리면 검증이 FAIL 한다.
- **레이어를 지우지 않는다.** `layout.visibility` 만 바꾼다 — 선택 → `"visible"`, 미선택 → `"none"`.
  `layers`·`sources` 배열 길이와 순서는 원본과 동일하다.
- **패치는 양방향이다.** ADMap 은 published 레이어를 `visibility: "none"` 으로 내보내는
  경우가 있다(실측: `trade-areas`·`districts`). 끄기만 하면 "골랐는데 안 보이는" 결과가 난다.
- **매핑은 `metadata['admap:layerId']`.** `layer.id` 문자열 매칭 금지 — `__casing`·`__sN` 파생 레이어를 놓친다.
- **`admap:layerId` 없는 레이어는 건드리지 않는다** (`background` 등).
- **기존 폴더를 덮어쓰지 않는다.** `--out` 이 이미 있으면 중단.
- **프레임워크 프로젝트를 만들지 않는다.** `package.json`·번들러·빌드 스텝 없음. "html 만"의 정확한
  뜻은 **정적 파일만(html/js/css/geojson) + 빌드 스텝 0** 이다 — 오버레이 A 방식이 `data/*.js`
  wrapper 를 요구하므로 plain js 는 허용, 컴파일 필요물(jsx/tsx/ts/vue/svelte)과 패키지 도입만
  막는다. 산출된 `guard-static-only.mjs` 훅이 이 경계를 강제한다.
- **레퍼런스 zip 코드를 복사하지 않는다.** 구조·개념만 참조.

## 오버레이 작업의 경계

매체 포인트·구역 폴리곤·히트맵 등 기획자 자체 데이터를 얹는 규칙의 SSOT 는 산출된
`OVERLAY-RULES.md` 다 — 이 스킬은 그 규칙을 **만들 뿐 재기술하지 않는다**. 실제 오버레이
작업은 Workflow 7에 따라 같은 세션이 그 문서를 Read 하고 이어가거나, 나중에 그 폴더에서
열린 새 세션이 한다(CLAUDE.md 가 auto-load 로 같은 문서를 물려준다).

## 알려진 한계

- 검증은 **정적 체크만** — 타일 404·스프라이트 누락·라벨 미표시 같은 실렌더 실패는 못 잡는다. 기획자가 브라우저로 육안 확인해야 한다. (오버레이 이후 재검증은 동봉 `verify.mjs` — geojson 좌표계·A/B 혼용까지는 잡는다.)
- **오버레이 geojson 은 여전히 `file://` 를 깬다.** 스타일만 인라인했을 뿐, `data/*.geojson` 을
  URL 로 넘기면 그 fetch 가 막힌다. `OVERLAY-RULES.md` 가 A(=`.js` 로 감싸기)/B(=서버) 선택을 안내한다.
- **산출 훅은 Claude Code 세션 안만 방어한다.** 기획자가 터미널에서 직접 `npm create vite` 를
  치는 것은 못 막고, 스캐폴드 직후 같은 세션에서는 훅이 아직 로드 전이라 advisory(CLAUDE.md
  Read 준수)로만 동작한다(Workflow 7). 새 폴더의 프로젝트 훅은 첫 세션에서 승인 프롬프트가
  뜰 수 있다.
- 로컬 서버 스크립트를 넣지 않는다. 서버가 필요한 경우(오버레이 B 방식·사내 배포)는 README 안내를 따른다.
- 공용 키 1개를 여러 기획자가 공유한다 — per-user audit 분해가 안 된다.
