---
name: api-docs-guide-scaffold
description: >-
  Next.js App Router 프로젝트에 "개발자 포털" 3종 세트 — Scalar API 레퍼런스(/docs),
  zod-to-openapi 로 생성하는 OpenAPI 스펙(/api/openapi.json), MDX 통합 가이드(/guide/*) —
  를 동일한 포맷·스펙·환경 게이트로 SCAFFOLD 한다. 한 프로젝트에서 구축한 API 문서 형상을
  다른 프로젝트에도 일원화해 복제할 때 쓴다. 사용자가 API 문서·OpenAPI·Scalar·통합 가이드·
  연동 가이드·개발자 포털·API 레퍼런스를 새로 set up / build / scaffold / 깔아달라 하거나,
  "이 프로젝트에도 같은 API 문서 포맷으로", "다른 프로젝트에 docs랑 가이드 똑같이",
  "API 문서화 셋업", "통합 가이드 만들어줘", "OpenAPI 문서 깔아줘", "Scalar 붙여줘",
  "엔드포인트 연동 가이드 구축" 같이 말할 때마다 트리거한다 — "스킬"이나 "scaffold" 라는
  말을 안 써도, 부분적으로만 언급해도 마찬가지다. 기존 문서의 내용 한 줄 수정,
  단일 엔드포인트 추가, 일반 MDX 페이지 작성, Scalar 디버깅에는 쓰지 말 것 — 이 스킬은
  포털 인프라 전체를 새로 깔거나 다른 프로젝트로 복제하는 일을 한다.
---

# API Docs + Integration Guide Scaffold

Next.js App Router 프로젝트에 **개발자 포털**을 한 번에 깐다. 세 표면이 같은 스펙·게이트로
묶인다:

1. **`/docs`** — Scalar UI 가 OpenAPI 스펙을 렌더하는 API 레퍼런스(기계적 명세).
2. **`/api/openapi.json`** — zod-to-openapi 가 단일 SSOT 에서 생성하는 OpenAPI 3 문서.
3. **`/guide/*`** — MDX 통합 가이드(연동 방법·플로우·함정·end-to-end 예제).

세 표면 모두 **APP_ENV 환경 게이트**(local·dev 노출 / prod 404)와 **상호 CTA**로 이어진다.

이 스킬의 가치는 "한 번 구축한 형상을 다른 프로젝트에 정확히 복제"하는 데 있다. 그래서
**검증된 보일러플레이트 + 하드원 함정(gotcha) 회피책**을 자산으로 들고 있다. 새로 설계하지
말고 이 자산을 적응시켜라.

## 언제 이 스킬이 맞나

- 새 Next.js 프로젝트에 API 문서/가이드 인프라를 처음 깐다.
- 이미 한 프로젝트에 있는 포털 형상을 **다른 프로젝트에 동일 포맷으로 복제**한다.
- OpenAPI 스펙 생성 + Scalar UI + 통합 가이드를 묶어 세팅한다.

**안 맞을 때**: 기존 가이드 문장 수정(그냥 MDX 편집) · 단일 엔드포인트 스키마 추가(기존
`src/lib/openapi/schemas/*` 에 한 블록 추가) · Scalar 가 안 뜨는 버그 디버깅(`hunt`).

## 선행 확인 (가정하지 말 것)

스캐폴드 전에 대상 프로젝트에서 실측한다:

- **Next.js App Router 인가?** `app/` 디렉토리 + `next.config.*` 확인. Pages Router 거나
  Next 가 아니면 이 스킬의 코드 자산은 안 맞는다 — 멈추고 사용자에게 알린다.
- **패키지 매니저 / 설치 의존성** — `@scalar/api-reference-react`(node>=22), `@asteasolutions/zod-to-openapi`,
  `zod`, `@next/mdx`, `@mdx-js/loader`, `@mdx-js/react`, `@types/mdx` 가 필요. 이미 있는지 확인.
- **배포 환경 신호** — 이 게이트는 `APP_ENV`(런타임 env: `dev`/`prod`, 로컬 unset)에 의존한다.
  대상 프로젝트가 배포 시 `APP_ENV` 를 주입하는지 확인(없으면 게이트가 항상 'local'로 떨어져
  모든 환경에 노출됨 — 사용자에게 주입 지점을 알린다). 자세히 → `references/env-gate.md`.
- **언어** — 기본 한국어(summary·가이드 본문). 코드 주석은 영어. 사용자가 영어 문서를 원하면
  본문만 영어로.

확인이 끝나면 무엇을 깔고 무엇을 건드릴지 짧은 plan(파일 목록)을 보여주고 진행한다.

## 스캐폴드 순서

각 단계는 `assets/` 의 템플릿을 복사해 프로젝트에 맞게 치환한다. 플레이스홀더는 `<...>` 표기.

1. **OpenAPI SSOT** (`src/lib/openapi/`) — `assets/openapi/` 참조.
   - `zod.ts`(openapi 확장 z 재export) · `registry.ts`(단일 레지스트리 + 에러 봉투 헬퍼) ·
     `document.ts`(generator + info + **servers[]**) · `schemas/<domain>.ts`(도메인별 path 등록).
2. **스펙 라우트** `app/api/openapi.json/route.ts` — `assets/routes/openapi.json.route.ts.tmpl`.
3. **Scalar `/docs` (page 임베드)** — `app/docs/layout.tsx`(게이트 + force-dynamic + **지속 CTA 바**)
   + `app/docs/page.tsx`(`@scalar/api-reference-react` 임베드 + **style.css 명시 import**) +
   globals.css 에 docs-shell CSS. `assets/routes/docs.layout.tsx.tmpl` · `docs.page.tsx.tmpl` ·
   `docs-shell.css.tmpl`. (route-handler 방식은 폐기 — 전체 페이지 takeover 라 지속 CTA 를 못 단다.)
4. **환경 게이트 소스** `src/lib/dashboard/deploy-info.ts`(resolveDeployEnv) + `guide-gate.ts` —
   `assets/` 참조. 게이트의 함정은 **반드시** `references/env-gate.md` 를 먼저 읽고 적용.
5. **MDX 설정** — `next.config.*` 에 mdx 등록(`pageExtensions` + `createMDX`) + `mdx-components.tsx`.
6. **통합 가이드** `app/guide/` — `layout.tsx`(게이트 + **force-dynamic**) · `GuideNav.tsx` ·
   `page.mdx`(개요+Day-0+규약) · `quickstart/page.mdx`(e2e) · 시나리오별 `*/page.mdx`.
   포맷·섹션 규약 → `references/conventions.md`.
7. **상호 CTA** — 대시보드/홈 Sidebar → guide·docs 링크, GuideNav → docs·콘솔 링크,
   OpenAPI `info.description` 앞에 가이드·콘솔 복귀 마크다운 링크. → `references/conventions.md` §CTA.
8. **검증** — `references/verify.md` 의 체크리스트(빌드 + 게이트 라이브 확인)를 돌린다.

## 절대 틀리면 안 되는 함정 (요약 — 상세는 references/env-gate.md)

아래는 이번 형상을 만들며 실제로 prod 사고/배포 실패를 낸 지점이다. 그대로 따른다:

1. **게이트는 `APP_ENV` 로 — `NODE_ENV` 아님.** Docker 배포는 dev·prod 모두 `NODE_ENV=production`
   이라 NODE_ENV 로 게이트하면 dev 배포에서도 문서가 404 된다.
2. **`/guide` layout AND `/docs` layout 에 `export const dynamic = 'force-dynamic'`.** 둘 다
   page 라 없으면 빌드 시점(APP_ENV unset→통과)에 정적 prerender 되어 런타임 게이트를 우회 →
   **prod 에 노출**된다. (route handler 인 `/api/openapi.json` 은 본래 dynamic 이라 불필요.)
3. **OpenAPI 에 `servers[]` 필수.** 없으면 Scalar curl 예제가 host 없는 상대경로로 렌더돼
   바로 실행 불가.
4. **errorResponse 의 에러 코드 문자열은 보존.** `invalid_body` 등은 실제 API 가 반환하는
   `{error}` 값이라 번역/변경 금지 — 한국어 설명은 코드 뒤에 덧붙인다(`'invalid_body — 요청 형식 오류'`).
5. **Scalar 임베드는 `style.css` 명시 import.** `app/docs/page.tsx` 에서
   `import '@scalar/api-reference-react/style.css'`. 없으면 docs 가 unstyled plain 텍스트로
   렌더된다(콘솔 에러 없음 — JS 는 init 됨, CSS 만 빠짐).
6. **node >=22.** Scalar 임베드 의존성이 node 22 요구 → Dockerfile/CI 의 node 핀을 20→22.
   로컬(node22)은 통과하고 Docker(node20) `npm ci` 만 깨져 놓치기 쉽다. + persistent 러너는
   디스크 prune 스텝 필요(빌드 캐시 누적 → no space left). 둘 다 `assets/next-config-and-deps.md`.

## 참조 파일

- `references/conventions.md` — 문서 포맷·섹션 규약(에러 봉투·Int8 문자열 경계·baseURL 표·
  Day-0 부트스트랩·시나리오 페이지 구조·CTA 배치·한국어 문체).
- `references/env-gate.md` — APP_ENV 게이트 + force-dynamic + servers[] 의 **왜**와 정확한 코드.
- `references/structure.md` — 전체 파일 레이아웃과 각 파일의 역할·와이어링 순서.
- `references/verify.md` — 스캐폴드 후 검증 체크리스트.
- `assets/` — 복사용 보일러플레이트 템플릿(openapi/ routes/ guide/).
