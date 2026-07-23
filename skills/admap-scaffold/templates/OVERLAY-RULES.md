# 오버레이 작업 규칙 — {{PROJECT}}

이 폴더는 `admap-scaffold` 로 만들어졌다. 지도는 이미 뜬다. 여기서부터 매체 포인트·구역
폴리곤·히트맵 같은 **자기 데이터**를 얹는 것이 남은 일이다.

**AI 에게 작업을 시킬 때는 이 문서를 먼저 읽히세요.** 아래 규칙을 지키면 다음 사람이
열어도 구조가 같고, 스캐폴드를 다시 돌려도 작업물을 그대로 옮길 수 있다.

## 하지 말 것

- **`style.js` 를 편집하지 않는다.** ADMap 스타일 스냅샷이고 스캐폴드가 다시 굽는 대상이다.
  손댄 내용은 재생성 시 전부 사라진다. 오버레이는 전부 `index.html` 에서 추가한다.
- **`style.js` 를 `style.json` + `fetch` 로 되돌리지 않는다.** 그러면 `file://` 더블클릭이
  깨진다 — maplibre 가 style URL 을 `fetch()` 로 읽는데 `file://` origin 은 브라우저가 막는다.
- **ADMap 레이어를 지우거나 이름을 바꾸지 않는다.** 안 보이게 하려면 `visibility` 만 바꾼다.
- **CDN 버전을 임의로 올리지 않는다.** `maplibre-gl@{{MAPLIBRE_VERSION}}` / `pmtiles@{{PMTILES_VERSION}}` 은
  이 `style.js` 를 만든 ADMap 과 맞춘 버전이다.
- **빌드 도구를 도입하지 않는다.** 이 폴더는 정적 파일만으로 배포된다.

## 파일 두는 자리

| 종류 | 자리 | 예 |
| --- | --- | --- |
| 벡터 데이터 | `data/` | `data/media-points.geojson` |
| 이미지 | `media/` | `media/gangnam-01.jpg` |

경로는 항상 상대경로(`./data/...`)로 참조한다. 절대경로 금지.

## geojson 로딩 방식 — 더블클릭을 지킬지 먼저 정한다

이 폴더는 서버 없이 `index.html` 더블클릭으로 열린다(스타일을 `style.js` 로 굽기 때문).
그런데 **`data/*.geojson` 을 URL 로 주면 `file://` 에서 막힌다** — maplibre 가 그 URL 을
`fetch()` 로 읽고, 브라우저는 `file://` origin 의 로컬 fetch 를 차단한다.

| 방식 | 더블클릭 | 쓸 때 |
| --- | --- | --- |
| A. geojson 을 `.js` 로 감싸 `<script src>` | 됨 | 기획자가 파일만 열어 보는 게 기본일 때 (권장) |
| B. `data: './data/x.geojson'` URL | 안 됨 (서버 필요) | 어차피 서버·호스팅에 올려 쓸 때 |

A 방식은 데이터 파일을 이렇게 둔다 — `data/media-points.js`:

```js
window.MEDIA_POINTS = { "type": "FeatureCollection", "features": [ /* ... */ ] };
```

`index.html` 에 `<script src="./data/media-points.js"></script>` 를 추가하고
`data: window.MEDIA_POINTS` 로 넘긴다. 전역 이름은 `SCREAMING_SNAKE_CASE`,
`__ADMAP_STYLE__` 과 겹치지 않게 짓는다.

**두 방식을 한 폴더에서 섞지 않는다.** 하나라도 B 가 있으면 그 폴더는 서버 없이는 안 뜬다.

## 좌표계

GeoJSON 은 **EPSG:4326 (경위도, `[경도, 위도]` 순서)** 이어야 한다. 한국 공공데이터는
EPSG:5179 인 경우가 있는데, 그대로 넣으면 지도에 아무것도 안 보인다. 변환 후 넣을 것.

## 레이어 추가 컨벤션

`index.html` 의 `map.on('load', ...)` 안에서 추가한다.

```js
map.on('load', () => {
  map.addSource('media-points', {
    type: 'geojson',
    data: './data/media-points.geojson',
  });

  map.addLayer({
    id: 'media-points-circle',
    type: 'circle',
    source: 'media-points',
    paint: {
      'circle-radius': 6,
      'circle-color': '#03C75A',
      'circle-stroke-width': 2,
      'circle-stroke-color': '#ffffff',
    },
  });
});
```

네이밍 규칙:

- **source id** = 데이터 성격 그대로, kebab-case (`media-points`, `commercial-zone`).
- **layer id** = `<source-id>-<타입>` (`media-points-circle`, `commercial-zone-fill`,
  `commercial-zone-line`). 한 소스에서 여러 레이어를 뽑을 때 충돌하지 않는다.
- **`admap-` 접두사 금지.** ADMap 레이어와 헷갈린다.

렌더 순서가 중요하면 `map.addLayer(def, beforeId)` 로 기존 레이어 아래에 끼운다.

## 켜고 끄기

토글 UI 가 필요하면 자기 오버레이 레이어에만 건다.

```js
map.setLayoutProperty('media-points-circle', 'visibility', on ? 'visible' : 'none');
```

## 확인

작업 후 두 가지를 한다.

1. **`node verify.mjs`** — 정적 재검증. style.js 무손상·file:// 회귀·A/B 혼용·API key 노출·
   `data/` 좌표계(EPSG:5179 오탑재)를 잡는다. FAIL 이면 고치고 재실행. (이 폴더에서 연
   Claude Code 세션은 종료 시 훅이 자동 실행한다.)
2. **브라우저 육안 확인** — A 방식이면 `index.html` 더블클릭, B 방식이면
   `python3 -m http.server 8000`. 콘솔 에러 0 을 확인한다. 정적 검증이 못 잡는
   실렌더 실패(타일 404·데이터 경로 오타)는 눈으로만 잡힌다.
