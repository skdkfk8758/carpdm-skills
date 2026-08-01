# 파일 레이아웃 · 와이어링

원형 프로젝트(Intelligence-Auth)의 실제 트리. 새 프로젝트도 이 배치를 따른다.

```
app/
├── docs/
│   ├── layout.tsx                 # force-dynamic + APP_ENV 게이트 + 지속 CTA 헤더 바
│   └── page.tsx                   # 'use client' Scalar 임베드 + style.css 명시 import
├── api/openapi.json/route.ts      # OpenAPI 문서 서빙 (route handler, 게이트: APP_ENV prod → 404)
└── guide/
    ├── layout.tsx                 # export const dynamic='force-dynamic' + 게이트 + 셸
    ├── GuideNav.tsx               # 섹션 nav + docs·콘솔 CTA
    ├── page.mdx                   # 개요(규약·baseURL·Day-0·다음단계)
    ├── quickstart/page.mdx        # end-to-end 예제
    └── <scenario>/page.mdx        # 시나리오별(여러 개)
mdx-components.tsx                  # @next/mdx: MDX 요소 → 스타일 컴포넌트 매핑
next.config.*                      # pageExtensions + createMDX (+ mdxRs)
src/lib/
├── openapi/
│   ├── zod.ts                     # openapi 확장된 z 재export (단일 import 지점)
│   ├── registry.ts                # OpenAPIRegistry 1개 + errorResponse/jsonResponse 헬퍼 + ErrorResponse
│   ├── document.ts                # buildOpenApiDocument: generator + info + servers[] + 스키마 모듈 import(side-effect)
│   └── schemas/<domain>.ts        # zod 스키마 register + registry.registerPath(...) (도메인별)
└── dashboard/
    ├── deploy-info.ts             # resolveDeployEnv(APP_ENV) — 게이트의 환경 신호 소스
    └── guide-gate.ts              # isGuideEnabled(appEnv)
test/
└── dashboard/guide-gate.spec.ts   # 게이트 단위테스트 (APP_ENV 케이스)
```

## 와이어링 핵심

- **SSOT 단일성**: zod 스키마가 런타임 검증(route 의 `safeParse`)과 OpenAPI 문서를 **동시에**
  공급한다. route 가 import 하는 바로 그 스키마를 `registry.register` 한다 → 문서와 검증이 절대
  어긋나지 않는다.
- **side-effect import**: `document.ts` 가 `import './schemas/<domain>'` 로 각 도메인 모듈을
  불러야 그 모듈의 `registry.registerPath(...)` 가 실행되어 레지스트리가 채워진다. import 안 하면
  그 도메인 path 가 문서에서 통째로 빠진다.
- **헬퍼 2개**(`registry.ts`):
  - `jsonResponse(description, schema)` — 성공 응답 1개.
  - `errorResponse(description)` — `{error}` 봉투 응답. description 에 **에러 코드 보존**(env-gate §4).
- **게이트 술어는 순수 함수**로 분리(`resolveDeployEnv`/`isGuideEnabled`) → 단위테스트 가능.
  side-effect(`notFound()`)는 layout 에서만.

## 도메인 스키마 모듈 패턴 (`schemas/<domain>.ts`)

```ts
import { z } from '../zod';
import { registry, errorResponse, jsonResponse } from '../registry';

export const FooBody = registry.register('FooBody', z.object({ ... }));  // route 도 import
const FooResponse = z.object({ ... });

registry.registerPath({
  method: 'post', path: '/api/foo',
  summary: '<한국어 동작>',
  request: { body: { content: { 'application/json': { schema: FooBody } } } },
  responses: {
    200: jsonResponse('<한국어 성공>', FooResponse),
    400: errorResponse('invalid_body — 요청 형식 오류'),
  },
});
```
