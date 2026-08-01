# next.config + 의존성 노트

이 문서는 포털 3종(Scalar `/docs` · OpenAPI `/api/openapi.json` · MDX `/guide/*`)을
대상 Next.js App Router 프로젝트에 올리기 위해 필요한 **next.config 설정**과 **npm 의존성**을
정리한 reference 다. 코드 템플릿은 `assets/` 하위에, 빌드 설정은 여기서 다룬다.

레퍼런스 출처: Intelligence-Auth `next.config.ts` + `package.json` (검증된 형상).

## next.config.ts — MDX 등록 + APP_VERSION 주입

MDX 가이드 라우트(`/guide/*`)를 페이지로 컴파일하고, 대시보드 deploy stamp 에 쓸
`APP_VERSION` 을 빌드타임에 주입하는 설정이다. 핵심 4지점:

- `pageExtensions` — `.md`/`.mdx` 를 페이지로 취급(가이드 MDX 콘텐츠 라우트).
- `createMDX` — `@next/mdx` 래퍼로 MDX 페이지 확장자/로더 등록.
- `experimental.mdxRs` — Rust MDX 컴파일러. Turbopack 에서는 `@mdx-js/loader`
  webpack 로더가 안 돌기 때문에 가이드 콘텐츠를 `mdxRs` 로 컴파일한다.
- `env.APP_VERSION` — `package.json` 의 version 을 읽어 런타임 `process.env.APP_VERSION`
  으로 노출(`getDeployInfo` 가 읽음). `APP_ENV`(dev/prod)는 배포 런타임이 별도 주입한다.

```ts
import type { NextConfig } from 'next';
import createMDX from '@next/mdx';

// Build-time version injection for the dashboard deploy stamp. APP_VERSION is read
// from package.json here and surfaces at runtime as process.env.APP_VERSION
// (getDeployInfo). APP_ENV (dev/prod) is injected separately by the deploy runtime.
const pkg = require('./package.json') as { version: string };

const nextConfig: NextConfig = {
  // Self-contained server bundle (.next/standalone) for a slim Docker runtime image.
  output: 'standalone',
  // Allow .md/.mdx files to be treated as pages (the /guide MDX content routes).
  pageExtensions: ['ts', 'tsx', 'js', 'jsx', 'md', 'mdx'],
  // Build-time env: stamp the package version so the sidebar version pill is correct.
  env: { APP_VERSION: pkg.version },
  // Pin the workspace root to this worktree. Without it, Next infers the root from
  // the nearest parent lockfile and may pick the repo-parent dir (wrong root in a
  // git worktree setup).
  turbopack: { root: __dirname },
  // Rust MDX compiler — the @mdx-js/loader webpack loader does not run under
  // Turbopack, so the guide content (plain prose + code blocks) compiles via mdxRs.
  experimental: { mdxRs: true },
};

// createMDX wraps the config to register the MDX page extensions / loader. Options
// stay empty: mdxRs handles compilation and the guide uses no remark/rehype plugins.
const withMDX = createMDX({});

export default withMDX(nextConfig);
```

> 주의:
> - `output: 'standalone'` 과 `turbopack.root` 는 Intelligence-Auth 의 Docker/worktree
>   환경 고유 설정이다. 대상 프로젝트가 Docker standalone 빌드나 git worktree 를 쓰지
>   않으면 이 두 줄은 빼도 무방하다. MDX 포털에 **필수인 것은 `pageExtensions` ·
>   `createMDX` · `experimental.mdxRs` · `env.APP_VERSION`** 4지점이다.
> - 기존 `next.config` 가 있으면 위 4지점만 머지한다(파일 통째 교체 금지).

## 필요한 npm 의존성

Intelligence-Auth `package.json` 의 실제 버전이다. 포털 3종에 직접 필요한 패키지만 추린다.
대상 프로젝트의 Next/React 메이저가 다르면 `@next/mdx` · `@scalar/api-reference-react`
버전을 그 메이저에 맞춰 조정한다.

### dependencies

| 패키지 | 버전 | 역할 |
| --- | --- | --- |
| `@scalar/api-reference-react` | `^0.9.46` | `/docs` Scalar API 레퍼런스 — **React 임베드**(page.tsx). 지속 CTA 바를 위에 두려면 route-handler 가 아닌 임베드가 필요. **engines.node >=22** ⚠ |
| `@asteasolutions/zod-to-openapi` | `^8.5.0` | zod SSOT → OpenAPI 3 문서 생성(registry/document) |
| `zod` | `^4.4.3` | 요청 검증 + OpenAPI 스키마 SSOT |
| `@next/mdx` | `^16.2.9` | `createMDX` — MDX 페이지 등록 |
| `@mdx-js/loader` | `^3.1.1` | MDX webpack 로더(non-Turbopack 경로) |
| `@mdx-js/react` | `^3.1.1` | MDX 런타임 React 바인딩 |

### devDependencies

| 패키지 | 버전 | 역할 |
| --- | --- | --- |
| `@types/mdx` | `^2.0.14` | `mdx-components.tsx` 의 `MDXComponents` 타입 |

### 설치 한 줄

```bash
npm i @scalar/api-reference-react@^0.9.46 @asteasolutions/zod-to-openapi@^8.5.0 \
  zod@^4.4.3 @next/mdx@^16.2.9 @mdx-js/loader@^3.1.1 @mdx-js/react@^3.1.1
npm i -D @types/mdx@^2.0.14
```

> `zod` 는 보통 이미 깔려 있다 — 그 경우 메이저(v4)가 맞는지만 확인하고 중복 설치는 건너뛴다.
> `@asteasolutions/zod-to-openapi` v8 은 zod v4 를 요구하므로 zod v3 프로젝트면 zod 업그레이드가
> 선행돼야 한다(`extendZodWithOpenApi` 호환).

## ⚠ node >=22 필수 (Scalar React 임베드)

`@scalar/api-reference-react`(→ `@scalar/api-reference@1.59.x` 등)는 **`engines.node >=22`**
다. 빌드/런타임 node 가 20 이면 docker `npm ci` 가 **exit 1**(로컬 node22 에서는 통과해
놓치기 쉽다 — Docker/CI 에서만 터진다). 대상 프로젝트의 모든 node 핀을 22 로 올린다:

- `Dockerfile`: 모든 `FROM node:20*` → `FROM node:22*` (deps/build/runner 스테이지 전부).
- CI/release 워크플로의 컨테이너 `image: node:20` → `node:22`.
- Next.js 16 은 node 22(현 LTS) 지원 — 업그레이드 자체는 안전. 로컬에서 `next build` +
  테스트로 검증.

## ⚠ self-hosted 러너 디스크 — 빌드 캐시 prune

Scalar 임베드는 무거워(`@scalar/api-reference` ~수백 MB 의존성) docker 빌드 레이어/캐시가
빠르게 쌓인다. persistent self-hosted 러너면 **"no space left on device"** 로 배포가 깨진다.
배포 워크플로의 build 앞에 압력 기반 prune 스텝을 둔다(태그된 롤백 이미지는 보존):

```yaml
- name: Free disk (prune stale docker cache)
  run: |
    docker container prune -f || true
    docker image prune -f || true          # dangling(untagged)만 — latest/버전 롤백 보존
    USE=$(df -P / | awk 'NR==2 {print $5}' | tr -dc '0-9')
    if [ "${USE:-0}" -ge 80 ]; then docker builder prune -af || true   # 압력 높으면 전체 캐시
    else docker builder prune -f --filter "until=72h" || true; fi       # 평상시 오래된 캐시만
    df -h / | tail -1
```
