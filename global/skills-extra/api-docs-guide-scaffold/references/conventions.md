# 문서 포맷·섹션 규약

이 형상의 "동일한 포맷·스펙"을 결정하는 규약. 새 프로젝트에 깔 때 이 구조를 따른다.

## 0. 두 종류의 문서 — 역할 분리

- **`/docs` (Scalar)** = 엔드포인트별 **기계적 명세**(요청/응답 스키마·상태코드). zod SSOT 생성.
- **`/guide` (MDX)** = **연동 방법**(플로우·코드 예제·함정·end-to-end). 사람이 쓴다.

가이드 개요에서 "개별 엔드포인트 명세는 [API 레퍼런스](/docs) 를 본다"로 둘을 교차 참조한다.
같은 정보를 양쪽에 중복하지 않는다.

## 1. 공통 규약 섹션 (가이드 개요에 항상)

대상 프로젝트의 실제 계약에 맞춰 채우되, 이 항목들은 통합자가 반드시 알아야 한다:

- **에러 봉투** — 실패 응답은 모두 `{ "error": "<code>" }`. 상태코드 + `error` 문자열로 분기.
- **ID 경계 타입** — DB 가 64bit(Int8) ID 면 JSON 경계에서 **문자열**로 다룬다(정밀도 손실 방지).
  이 프로젝트 고유 규약이 있으면 명시(예: verify 응답의 `sub` 만 number 복원).
- **인증 매개체** — 세션 쿠키/토큰/키 각각의 이름·속성(HttpOnly·SameSite·Secure)·전달 방법.

## 2. baseURL 표 (가이드 개요)

환경별 base URL 을 표로. 예제는 `<BASE>` 치환 규약을 명시(`<API_KEY>`·`<TICKET>` 등은
placeholder, 실제 비밀값을 코드/로그에 남기지 않는다).

| 환경 | baseURL |
| --- | --- |
| 로컬 dev | `http://localhost:<PORT>` |
| dev 배포 | `https://<DEV_HOST>` |
| prod 배포 | `https://<PROD_HOST>` |

## 3. Day-0 부트스트랩 섹션 (가이드 개요)

새 팀이 **시작 자체를 못 하는** 닭-달걀(계정 발급·사전 등록이 권한 필요)을 푼다. 무엇을
누구에게(채널/담당자) 요청하는지 표로. 권한 모델(예: 생성·등록은 operator 전용, 새 팀은
요청만)을 명시. 이 섹션이 "다른 팀이 바로 적용 가능"을 가르는 핵심이다.

## 4. 시나리오 페이지 구조 (각 `/guide/<scenario>/page.mdx`)

연동 시나리오 하나당 한 페이지. 각 엔드포인트를 이 골격으로:

```
## N. <동작> — `<METHOD> <path>`
- **요구사항**: <세션/권한/선행조건>
- **요청 body**: `{ ... }`
- **성공**: `<status> { ... }`

```bash
curl ...   # → <status> { ... }
```

```ts
const res = await fetch(...);  // 주석으로 성공 응답 shape
```

### <동작> 실패 코드
| 상태 | `error` | 원인 |
| --- | --- | --- |
| `4xx` | `code` | ... |
```

- **curl + ts 쌍**을 항상 같이(서버-서버·브라우저 양쪽 독자).
- **실패 코드 표**는 코드를 합치는 의도(예: 열거 방지로 여러 원인을 한 코드로)까지 콜아웃으로.
- **함정 콜아웃**(`>` blockquote)으로 1회성·단일소비·선행조건 같은 비자명 동작을 짚는다.

## 5. end-to-end 빠른시작 (`/guide/quickstart/page.mdx`)

조각난 시나리오를 **처음부터 끝까지 한 흐름**으로. 단계마다 **실행 주체**(관리자/너희 팀/수신
측)를 표시. 권한 없는 단계(operator 작업)는 "참고용"으로 표시하되 무슨 일이 일어나는지 보여준다.

## 6. 상호 CTA (세 표면 양방향)

세 표면이 서로 막다른 길이 되지 않게 한다:

- **대시보드/홈 → guide·docs**: Sidebar 에 "통합 가이드" 링크 + "API Docs ↗"(외부탭) 링크.
- **guide → docs·콘솔**: GuideNav 하단에 "API 레퍼런스 (/docs) ↗" + "운영 콘솔 ↗".
- **/docs(Scalar) → guide·콘솔**: Scalar 를 **page 로 임베드**(`@scalar/api-reference-react`)하고
  그 위에 **지속 CTA 헤더 바**를 둔다(`docs/layout.tsx`). route-handler(전체 페이지 takeover)는
  chrome 에 링크를 못 달아 — info.description 마크다운 링크는 Introduction 화면에만 떠서
  엔드포인트를 탐색하면 사라진다. 지속 CTA 가 필요하면 임베드+헤더 바가 유일한 길.
  (보조로 `info.description` 맨 앞 마크다운 링크 `'**[← 통합 가이드](/guide)** · **[운영 콘솔](/)**\n\n'`
  도 같이 두면 raw 스펙 다운로드/타 뷰어에서도 링크가 남는다.)

## 7. MDX 앵커 주의 (mdxRs)

`next.config` 가 `experimental: { mdxRs: true }`(Rust 컴파일러)면 rehype-slug 같은 JS 플러그인이
안 돈다 → heading 에 `id` 가 안 붙는다 → 페이지 내 `#fragment` 앵커 링크가 스크롤 타깃이 없다.
**교차 링크는 `#fragment` 없이 페이지 단위로** 건다(`/guide` O, `/guide#day-0` X). rehype-slug 가
꼭 필요하면 mdxRs 를 끄고 `@mdx-js/loader` 로 가야 하는데, 보통 그럴 가치 없다.

## 8. 한국어 문체

- summary·가이드 본문: 한국어. 기술 용어·식별자(`audience`·`bearer`·`operator`·`SSO`·`session_token`)
  는 원문 유지. 받침·맞춤법 정확히.
- **코드 주석(`//`)은 영어**(언어정책). 번역 대상은 Scalar/가이드에 렌더되는 문자열만.
- 에러 코드는 보존(→ `env-gate.md` §4).
