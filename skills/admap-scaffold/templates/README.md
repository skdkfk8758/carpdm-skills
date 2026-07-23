# {{TITLE}}

ADMap 지도 기반 정적 페이지. 빌드 스텝 없음 — 폴더 그대로 열고, 폴더 그대로 배포한다.

## 구성

| 파일 | 역할 |
| --- | --- |
| `index.html` | 지도 페이지 본체 |
| `style.js` | ADMap 지도 스타일 **스냅샷** (생성 시점에 고정, `window.__ADMAP_STYLE__`) |
| `data/` | 자기 데이터(geojson 등)를 넣는 자리 |
| `media/` | 이미지 넣는 자리 |
| `OVERLAY-RULES.md` | 자기 데이터를 얹을 때의 규칙 — 작업 전 반드시 읽을 것 |
| `CLAUDE.md` · `.claude/` | AI(Claude Code) 작업용 — 이 폴더에서 세션을 열면 규칙이 자동 적용되고, 프레임워크 도입·`style.js` 편집이 훅으로 차단됨 |
| `verify.mjs` | 작업 후 재검증: `node verify.mjs` (좌표계·더블클릭 회귀·키 노출 등) |

## 여는 법

**`index.html` 을 더블클릭하면 그냥 열립니다.** 지도 스타일을 `style.js`(`<script src>`)로
두어 `file://` 의 fetch 차단(CORS)을 피했습니다. 지도 타일·아이콘은 원격 CDN 이
`origin: null` 을 허용하므로 로컬에서도 뜹니다.

**단, `data/*.geojson` 을 `fetch()`/`addSource({data:'./data/...'})` 로 얹으면 그 순간
`file://` 에서 막힙니다.** 오버레이를 붙일 때는 둘 중 하나 —

- geojson 을 `.js` 로 감싸 `<script src>` 로 로드 (더블클릭 유지, `OVERLAY-RULES.md` 참조)
- HTTP 서버로 열기

```bash
# 이 폴더에서
python3 -m http.server 8000
# 또는
npx serve .
```

→ 브라우저에서 `http://localhost:8000`

## 배포

정적 파일뿐이라 아무 정적 호스팅에나 이 폴더째 올리면 됩니다.
`CLAUDE.md`·`.claude/`·`verify.mjs` 는 AI 작업용이라 배포에서 빼도 됩니다(포함돼도 무해 — 비밀 없음).

- **Netlify** — app.netlify.com → Add new site → Deploy manually → 폴더 드래그&드롭
- **Vercel** — 이 폴더에서 `npx vercel`
- **GitHub Pages** — 내용을 저장소에 push → Settings → Pages → 브랜치 지정
- **사내 웹서버(Nginx/Apache/IIS/S3)** — 웹 루트에 그대로 복사

인터넷 연결이 필요합니다 — 지도 라이브러리(unpkg CDN)와 지도 타일(ADMap CDN)을 원격에서 받습니다.

## 지도 스타일이 낡았다면

`style.js` 는 **이 폴더를 만든 시점의 스냅샷**입니다. ADMap 에서 레이어가 추가·수정돼도
이 파일은 자동으로 바뀌지 않습니다. 최신 상태가 필요하면 스캐폴드 스킬을 **다시 실행해
새 폴더를 만들고** 자기 작업물을 옮기세요. `style.js` 를 손으로 편집하지 마세요.

레이어를 켜고 끄는 것도 스캐폴드 단계에서 결정됩니다 — 꺼진 레이어는 삭제된 게 아니라
`layout.visibility: "none"` 으로 숨겨져 있습니다.
