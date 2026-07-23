# {{TITLE}} — ADMap 정적 지도 페이지

`admap-scaffold` 산출 폴더. **빌드 스텝 없는 정적 HTML** — 이 성질을 깨는 작업은 전부 금지다.
오버레이 작업 규칙 SSOT 는 아래 문서다. 작업 전 반드시 따를 것.

@OVERLAY-RULES.md

## 불변식

- **프레임워크·번들러·패키지 도입 금지.** vite/react/next/nuxt/astro, `npm install`/`npm create`,
  `package.json` 생성 전부 안 된다. `.claude/hooks/guard-static-only.mjs` 훅이 차단한다.
  산출물은 정적 파일(html/js/css/geojson)만이다.
- **`style.js` 편집 금지.** ADMap 스타일 스냅샷 — 스캐폴드 재실행이 다시 굽는 대상이다.
  오버레이는 전부 `index.html` 에서 추가한다.
- **`index.html` 더블클릭(file://)으로 열리는 상태 유지.** 로컬 파일 `fetch` 금지 —
  geojson 은 `.js` wrapper(A 방식)가 기본이다. 상세는 OVERLAY-RULES.md.
- **ADMap 레이어는 지우지 않는다.** 숨기려면 `visibility` 만 바꾼다.

## 작업 후 검증

```bash
node verify.mjs
```

정적 검증(필수 파일·style.js 무손상·file:// 회귀·A/B 혼용·API key 노출·geojson 좌표계)을
재실행한다. FAIL 이면 고치고 다시 돌린다. Stop 훅이 세션 종료 시 자동 실행하기도 한다.
실렌더(타일 404·라벨 미표시)는 못 잡으니 브라우저 육안 확인은 별도다.
