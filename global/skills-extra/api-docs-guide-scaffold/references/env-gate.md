# 환경 게이트 — APP_ENV · force-dynamic · servers[]

세 표면(`/docs`·`/api/openapi.json`·`/guide/*`)은 **로컬·dev 배포에만 노출하고 prod 에서는
404** 한다. 비밀값은 없지만(전부 placeholder) 내부 API 표면·연동 절차를 공개 prod 에 띄우지
않으려는 의도다. 이 게이트는 만들 때 두 번 틀렸던 자리라, **왜** 이렇게 하는지까지 박아둔다.

## 1. 게이트는 `APP_ENV` 로 — `NODE_ENV` 가 아니다

직관적으로 `NODE_ENV === 'production'` 으로 prod 를 막고 싶어진다. **틀린다.**

Docker 배포 이미지는 `ENV NODE_ENV=production` 이고, **dev 배포와 prod 배포가 같은 이미지**를
쓴다. 그래서 dev 배포(예: `dev.auth.example`)도 런타임 `NODE_ENV==='production'` 이다. NODE_ENV
로 게이트하면 **dev 배포에서도 문서가 전부 404** 되어, 정작 보여줘야 할 dev 에서 안 보인다.

대신 **배포 환경 신호 `APP_ENV`** 를 쓴다. CI/배포가 컨테이너에 주입한다:

```
# deploy.yml (재사용 워크플로) — 환경별로 dev/prod 주입
docker run ... -e APP_ENV=${{ inputs.environment }} ...
```

→ dev 배포 `APP_ENV=dev`, prod 배포 `APP_ENV=prod`, 로컬 `next dev` 는 **unset**.

순수 매핑 함수로 분리해 단위테스트 가능하게 한다(`deploy-info.ts`):

```ts
export type DeployEnv = 'dev' | 'prod' | 'local';
export function resolveDeployEnv(raw: string | undefined): DeployEnv {
  if (raw === 'dev') return 'dev';
  if (raw === 'prod') return 'prod';
  return 'local'; // unset/unknown → local (안전: 절대 throw 안 함)
}
```

게이트 술어:

```ts
// guide-gate.ts — prod 만 막고 local·dev 는 노출
import { resolveDeployEnv } from './deploy-info';
export function isGuideEnabled(appEnv: string | undefined): boolean {
  return resolveDeployEnv(appEnv) !== 'prod';
}
```

> **대상 프로젝트가 APP_ENV 를 안 주입하면** 모든 환경이 'local'로 떨어져 prod 에도 노출된다.
> 스캐폴드 시 배포 워크플로의 `docker run`(또는 동등 지점)에 `-e APP_ENV=<env>` 가 있는지
> 확인하고, 없으면 사용자에게 "이걸 주입해야 prod 가 막힌다"고 명시한다.

## 2. page 계열(`/guide` AND `/docs`) layout 에 `export const dynamic = 'force-dynamic'`

**이게 빠지면 게이트가 prod 에서 무력화된다.** 실제로 이 형상에서 prod 에 가이드가 공개
노출된 사고가 났다. `/docs` 도 (route handler 가 아니라) Scalar 를 임베드한 **page** 라 동일
함정을 가진다 — 두 layout 모두에 적용한다.

원인: `/guide/*` MDX 페이지는 기본적으로 **정적 prerender** 된다. layout 의 `notFound()` 게이트가
`process.env.APP_ENV` 를 **빌드 시점**에 읽는데, 빌드 땐 APP_ENV 가 unset → `local` → 게이트
통과 → 페이지가 **정적 HTML 로 구워진다**. 런타임에 정적 HTML 을 그대로 서빙하므로 런타임
`APP_ENV=prod` 는 영영 검사되지 않는다. (반면 `/docs`·`/api/openapi.json` 은 **route handler =
dynamic** 이라 매 요청 평가되어 정상 404 였다 — 그래서 증상이 "guide 만 200, docs 는 404"로
나타난다.)

해결: 가이드 세그먼트를 dynamic 으로 강제한다.

```ts
// app/guide/layout.tsx 최상단
export const dynamic = 'force-dynamic';
```

→ `/guide/*` 가 매 요청 렌더 → 게이트가 런타임 `APP_ENV` 평가 → prod 404. 빌드 출력에서
`○ /guide`(static)가 `ƒ /guide`(dynamic)로 바뀌면 적용된 것.

> route handler(`/api/openapi.json`)는 본래 dynamic 이라 force-dynamic 불필요.
> **정적 prerender 되는 page 계열(`/guide/*` MDX, `/docs` 임베드 page)에** 이 함정이 있다.

## 3. OpenAPI `servers[]` — 없으면 curl 이 host 없는 상대경로

Scalar 는 `info` 만 있고 `servers` 가 없으면 curl/Test Request 샘플을 `curl /api/auth/login`
처럼 **host 없이** 렌더한다 — 복붙해도 안 돌아간다. `document.ts` 에 환경별 base URL 을 넣는다:

```ts
return generator.generateDocument({
  openapi: '3.0.3',
  info: { /* ... */ },
  servers: [
    { url: 'http://localhost:<PORT>', description: '로컬 dev (next dev)' },
    { url: 'https://<DEV_HOST>', description: 'dev 배포' },
    { url: 'https://<PROD_HOST>', description: 'prod 배포' },
  ],
});
```

## 4. errorResponse 의 에러 코드 문자열 보존

`errorResponse('invalid_body')` 의 `'invalid_body'` 는 Scalar 응답 설명으로 노출되는 동시에
**실제 API 가 반환하는 `{ "error": "invalid_body" }` 의 계약 값**이다. 번역/리네임하면 문서가
실제 동작과 어긋난다. 한국어화할 땐 **코드를 보존하고 설명을 뒤에 덧붙인다**:

```ts
400: errorResponse('invalid_body — 요청 body 형식 오류'),
401: errorResponse('invalid_credentials — 아이디/비밀번호 불일치(계정 열거 방지)'),
```

복수 코드도 코드는 그대로: `errorResponse('invalid_scope / invalid_scope_id — 필드별 검증 실패')`.

## 게이트가 걸리는 4개 파일 (전부 같은 정책)

| 파일 | 종류 | 게이트 코드 |
| --- | --- | --- |
| `app/api/openapi.json/route.ts` | route handler | `if (resolveDeployEnv(process.env.APP_ENV) === 'prod') return 404` |
| `app/docs/layout.tsx` | layout(+force-dynamic) | `if (resolveDeployEnv(process.env.APP_ENV) === 'prod') notFound()` |
| `app/guide/layout.tsx` | layout(+force-dynamic) | `if (!isGuideEnabled(process.env.APP_ENV)) notFound()` |
| (단위테스트) `guide-gate.spec.ts` | test | APP_ENV dev/prod/unset 케이스 |

> `src/lib/auth/session-cookie.ts` 같은 곳의 `secure: NODE_ENV==='production'`(쿠키 Secure
> 플래그)는 **건드리지 않는다** — HTTPS dev 배포에서도 Secure 쿠키가 맞으므로 NODE_ENV 가 옳다.
> NODE_ENV→APP_ENV 전환은 **문서 노출 게이트에만** 적용한다.
