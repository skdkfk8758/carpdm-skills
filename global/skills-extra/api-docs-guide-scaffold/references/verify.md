# 스캐폴드 후 검증 체크리스트

깔고 나서 이 순서로 확인한다. 게이트는 라이브 행동까지 봐야 한다(빌드만으론 §2 함정을 못 잡음).

## 1. 빌드 · 타입

- [ ] `npx tsc --noEmit` clean (또는 프로젝트 typecheck 스크립트).
- [ ] `next build` 성공. **빌드 출력에서 `/guide/*` 가 `ƒ`(dynamic)인지 확인** — `○`(static)면
      force-dynamic 이 안 먹은 것(env-gate §2). route handler `/docs`·`/api/openapi.json` 은 `ƒ`.
- [ ] 게이트 단위테스트 green (`isGuideEnabled`: dev/local→true, prod→false).

## 2. 로컬 (next dev — APP_ENV unset → local)

- [ ] `/guide` 200 렌더(nav·개요).
- [ ] `/docs` 200, Scalar 가 스펙 로드("could not be loaded" 아님 — 로드 실패면 `/api/openapi.json`
      이 404/에러인지 본다) **AND styled 렌더**(plain 텍스트 리스트면 style.css 미import).
- [ ] `/docs` 상단에 지속 CTA 바("← 통합 가이드 · 운영 콘솔")가 보이고, 엔드포인트를 클릭해
      탐색해도 **사라지지 않는다**(헤더 바가 Scalar 밖에 있으므로).
- [ ] `/api/openapi.json` 200, `servers[]` 포함, 모든 도메인 path 등록됨.
- [ ] Scalar curl 예제가 host 포함(상대경로 아님 → servers[] 적용 확인).

## 3. 게이트 라이브 (배포 후, 또는 APP_ENV 주입해 로컬 시뮬)

핵심: **prod 에서 정적 우회가 없는지**가 가장 중요한 검증이다.

- [ ] dev 배포(`APP_ENV=dev`): `/guide`·`/docs`·`/api/openapi.json` 전부 **200**.
- [ ] prod 배포(`APP_ENV=prod`): 셋 다 **404**. 특히 `/guide`·`/guide/<하위>` 전부 404 인지
      개별 확인(force-dynamic 누락 시 여기만 200 으로 샌다).

로컬 시뮬: `APP_ENV=prod next build && APP_ENV=prod next start` 후 `/guide` curl → 404 여야 정상.

## 4. 상호 CTA

- [ ] 대시보드/홈 → guide·docs 링크 동작.
- [ ] guide → docs·콘솔 링크 동작.
- [ ] `/docs` Introduction 상단에 가이드·콘솔 복귀 링크 보임.

## 흔한 실패 → 원인

| 증상 | 원인 |
| --- | --- |
| dev 배포에서 docs/guide 가 404 | 게이트가 NODE_ENV 기준(env-gate §1) — APP_ENV 로 전환 |
| prod 에서 page(/guide·/docs)만 200 | 그 layout 의 force-dynamic 누락(env-gate §2) |
| Scalar "Document could not be loaded" | `/api/openapi.json` 이 404/에러 — 그 라우트 게이트·생성 확인 |
| curl 예제가 `curl /api/...` (host 없음) | OpenAPI servers[] 누락(env-gate §3) |
| 문서에 있는 엔드포인트가 docs 에 안 뜸 | document.ts 가 그 schemas/<domain> 을 import 안 함(structure 와이어링) |
| **/docs 가 unstyled plain 텍스트** | page.tsx 가 `@scalar/api-reference-react/style.css` 미import(SKILL §함정 5) |
| **docker `npm ci` exit 1 (CI/배포만, 로컬 OK)** | 빌드 node 가 20 — Scalar 임베드는 node>=22(next-config-and-deps.md) |
| **배포 "no space left on device"** | persistent 러너 디스크 full — deploy 에 prune 스텝(next-config-and-deps.md) |
