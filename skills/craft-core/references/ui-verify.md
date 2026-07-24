# UI 인수 검증 — 시안 갭 분석 + 인터랙션 실구동 (공유 SSOT)

IMPORTANT: 이 파일은 **구현이 끝난 UI 를 사람이 쓰듯 실제로 눌러 확인하고, 승인 시안과의
갭을 표로 못 박는** 절차의 단일 SSOT 다. 소비자: `pipeline.md` Phase 4(forge / hunt /
renew) · `orchestrated.md` §4 Stage B · `linear-goal` Phase 3 Goal Prompt. **복제 금지 —
소비자는 이 파일을 읽어 따르고, 절차를 자기 파일에 재기술하지 않는다.**

존재 이유: 테스트 수트 green 은 *코드가 스스로에 대해* 맞다는 신호이고, 렌더 스크린샷은
*그려진다*는 신호다. 둘 다 **"submit 버튼을 눌렀을 때 실제로 저장되는가"** 를 말해주지
않는다. 시안 대조도 스크린샷 한 장으론 정적 초기 상태만 본다 — hover/focus/error/loading
상태는 눌러봐야 나온다. 이 두 구멍(동작 미검증 · 상태 미대조)이 "테스트 다 통과했는데
버튼이 안 먹는다"의 구조적 원인이다.

## 0. 적용 판정 (먼저)

**돈다** — 이번 변경이 사용자 대면 UI 표면을 추가·수정했고, 그 표면에 **인터랙티브 요소가
1개 이상**(버튼 · form · input · select · 링크 네비게이션 · 토글 · 모달 트리거) 있을 때.
시안(승인 mockup) 유무와 무관 — 시안이 없으면 Part C(갭 분석)만 생략하고 Part A/B 는 돈다.

**안 돈다** — 순수 백엔드/API/DB/CLI/라이브러리 변경, 인터랙티브 요소가 0인 정적 표시
변경(카피 문구 한 줄 · 색상 토큰 교체). 이때는 pipeline 의 기존 런타임 스모크로 충분하며
이 파일을 읽지 않는다.

**부분 적용** — 변경이 UI+백엔드 혼합이면 UI 표면에만 적용한다. **이번 diff 가 만든/바꾼
요소만** 대상이다 — 기존 화면 전수 회귀는 이 게이트의 일이 아니다(범위 폭발).

## 1. Part A — 인터랙션 인벤토리 (구동 전, 필수)

구동 대상을 **diff 에서 기계적으로 뽑아** 목록화한다. 목록 없이 눌러보면 "눌러본 것만
검증됨"이 되고 빠진 게 안 보인다.

diff 의 추가·수정 파일에서 아래를 Grep/Read 로 수집:

- `<button>` · `<a href>` · `onClick` / `onPress` / `@click` 핸들러
- `<form>` · `onSubmit` · `<input>` / `<select>` / `<textarea>` / `<input type=checkbox|radio>`
- 라우팅 트리거(`navigate(` · `router.push` · `<Link>`)
- 모달/드로어/토스트 오프너, 토글·탭 전환

각 항목을 한 줄로 적는다 — **`요소 · 기대 동작 · 관찰 가능한 성공 신호`**:

```
1. [저장] 버튼 · 폼 제출 → POST /api/x 200 + 성공 토스트
2. email input · 빈값 submit → 인라인 에러 "이메일을 입력하세요"
3. [취소] 버튼 · 모달 닫힘 + 입력값 초기화
```

**성공 신호는 관찰 가능해야 한다** — "동작함" 금지. DOM 변화 · 네트워크 요청 · URL 변화 ·
콘솔 무에러 중 최소 하나로 진술한다(karpathy 원칙 4).

인벤토리가 **비면** 적용 판정이 틀린 것이다 — §0 으로 돌아가 비적용 처리하고 그 사실을
기록한다.

## 2. Part B — 실구동 (chrome MCP)

dev 서버(또는 정적 빌드)를 띄우고 브라우저에서 인벤토리를 하나씩 **실제로 조작**한다.
도구는 `mcp__claude-in-chrome__*` — 이름은 아래가 정확한 것들이다(추측 금지):

| 목적 | 도구 |
|---|---|
| 탭 확보 | `tabs_context_mcp` → `tabs_create_mcp` (기존 탭 재사용 금지 — 사용자가 명시 요청할 때만) |
| 이동 | `navigate` |
| 요소 찾기(ref 획득) | `find`(자연어) 또는 `read_page` |
| 클릭·타이핑·스크린샷 | `computer` (`action: left_click` / `type` / `screenshot` / `hover` — **`take_screenshot` 이란 도구는 없다**) |
| form 값 세팅 | `form_input` (ref + value — select/checkbox 는 이쪽이 확실) |
| 결과 관찰 | `read_page`(DOM 변화) · `read_console_messages`(`onlyErrors:true`) · `read_network_requests`(`urlPattern` 으로 이번 API 만) |

절차 (항목당):

1. **before 관찰** — 필요하면 `computer screenshot` 또는 `read_page` 로 조작 전 상태 확보.
2. **조작** — 클릭/입력. 좌표 클릭보다 `find`/`read_page` 의 `ref` 를 쓴다(좌표는 렌더 흔들림에 취약).
3. **after 관찰** — 인벤토리에 적은 *그 성공 신호*를 확인한다. DOM 이면 `read_page`,
   API 면 `read_network_requests` 로 요청 URL+상태코드, 에러면 `read_console_messages`.
4. **판정 기록** — `pass` / `fail(관찰된 실제 결과)` / `blocked(사유)`.

**추가 필수 관찰 — 상태 축.** 인벤토리를 다 돌린 뒤 최소 이 셋은 유발해서 본다(해당하면):

- **에러 상태** — form 이 있으면 잘못된/빈 입력으로 1회 submit → 검증 메시지가 뜨는가.
- **로딩/비활성 상태** — 비동기 액션이 있으면 진행 중 disabled/스피너가 있는가(없으면 중복 제출 가능 → 발견).
- **콘솔** — 전 구동 끝나고 `read_console_messages({onlyErrors:true})` 1회. 새 에러 = fail.

### 안전 (비협상)

- **dev/로컬 환경만.** prod URL 구동 금지. 쓰기 경로는 dev 데이터로만.
- **파괴적 컨트롤 금지** — 삭제/결제/외부 발신 버튼은 **누르지 않는다**. 인벤토리에 있으면
  `blocked(파괴적 — 수동 확인 이관)` 으로 두고 §V `[사용자 직접 확인 필요]` 로 넘긴다.
- **JS `alert`/`confirm` 유발 금지** — 브라우저 모달이 뜨면 이후 도구 호출이 전부 막힌다.
  다이얼로그를 띄우는 컨트롤은 위 파괴적 컨트롤과 동일 처리.

### 폴백 사다리

브라우저 도구가 **2회 연속 실패**하면 재시도를 멈추고 내려간다 — 절차 SSOT 는
`~/.claude/rules-ondemand/browser-verify-fallback.md`(복제 금지). 요지: Chrome bridge 실패
→ Playwright → curl/API 직접 → 테스트·diff ground-truth. **내려갔으면 그 사실을 결과에
명시**하고, 시각/인터랙션 확인이 대체 불가한 항목은 green 으로 위장하지 말고 §V
`[사용자 직접 확인 필요]` 로 남긴다.

## 3. Part C — 시안 갭 분석 (승인 시안이 있을 때만)

승인 mockup(`deep-plan` companion `.html` · `mockup` 산출 시안 · 사용자가 준 시안)이
있으면, Part B 에서 띄운 **그 렌더를 재사용**해(이중 구동 불요) 시안과 대조한다. 대조는
스크린샷 vs 시안 **양쪽을 실제로 보고** 판정한다 — 코드만 읽는 대조는 폴백이다.

**초기 화면 한 장으로 끝내지 않는다.** 시안이 상태별 화면(에러 · 로딩 · 빈 상태 · hover)을
담고 있으면 Part B 에서 그 상태를 유발한 시점의 스크린샷으로 각각 대조한다 — 정적 대조가
놓치는 구멍이 여기다.

### 4축 + 갭 표

| 축 | 본다 |
|---|---|
| **구조** | 요소 유무·계층·순서. 시안에 있는데 구현에 없음/추가됨 |
| **레이아웃** | 정렬·간격·크기 비율·반응형 브레이크 거동 |
| **스타일** | 색·타이포·radius·shadow — 프로젝트 토큰 기준(raw hex 하드코딩은 그 자체가 갭) |
| **상태·전이** | hover/focus/disabled/error/loading/empty 가 시안대로 존재하는가 |

발견을 표 하나로 못 박는다(산문 금지 — 후속 처리 단위가 행이다):

```
| # | 축 | 시안 | 구현 | 판정 | 처리 |
|---|-----|------|------|------|------|
| 1 | 구조 | 우측 필터 패널 | 없음 | gap | Phase 3 loop-back |
| 2 | 스타일 | --color-accent | #3b82f6 하드코딩 | gap | Phase 3 loop-back |
| 3 | 레이아웃 | 카드 간격 24px | 20px | 수용 | 잔여 리스크(사용자 합의) |
```

**판정 3분류** (pipeline 의 intent 판정과 같은 어휘):

- **gap** — 시안과의 객관적 불일치 → **confirmed gap**, Phase 3 로 돌아가 그 delta 만 짓는다.
- **out of scope** — 시안이 이번 범위 밖까지 그린 것 → 이유 적고 기각.
- **plan defect** — 구현이 맞고 *시안*이 틀림 → 시안을 amend(같은 파일 경로로 재-publish).

**미감·질감 판단**(폰트 무드, 카피 톤, "좀 답답해 보임")은 gap 이 아니라 `[HUMAN]` 항목이다
— 사용자와 walk 해 합의한다. 객관적 불일치만 게이트로 친다.

## 4. 게이트 (hard)

**출시 조건: 인벤토리 전 항목이 `pass` 이거나 명시 처리됐고 AND 갭 표에 미처리 `gap` 이
없을 것.**

- `fail` 1건 = confirmed gap → **Phase 3 loop-back**(그 항목만 TDD 로 고치고 Phase 4 재진입).
  green 으로 넘기지 않는다.
- `blocked`(파괴적 컨트롤 · 브라우저 불가 · env 부재) = 출시를 막지 않지만 **반드시** §V
  `[사용자 직접 확인 필요]` 로 이관한다 — 확인 방법 1구절과 함께. 조용히 사라지는 것이
  이 게이트의 유일한 실패 모드다.
- **인벤토리를 안 만들고 "몇 개 눌러봤음"으로 통과 선언 금지.** 인벤토리가 장부다.

### 증거 배출

이 게이트의 산출은 소비자의 종료 출력으로 흘러간다(`output-contract.md`):

- 구동해서 `pass` 한 항목 → §V `[직접 테스트 완료]` (조작 → 관찰된 실제 결과를 증거로).
- `blocked` 항목 → §V `[사용자 직접 확인 필요]` (체크박스 + 확인 방법).
- 갭 표의 `수용` 행 → 잔여 리스크로 §R 보드 평결에.

증거는 **관찰된 실제 출력**이어야 한다 — "버튼 정상" 금지, "저장 클릭 → POST /api/x 201,
토스트 노출 확인" 처럼(`~/.claude/rules/verification-safety.md` V1).

## Anti-patterns

- 스크린샷 한 장 찍고 "시안대로 나옴" — 상태별 화면 미대조, 동작 미검증.
- 테스트 수트 green 을 인터랙션 검증으로 갈음 — 별개 신호다(수트는 코드↔코드).
- 인벤토리 없이 눈에 띄는 버튼 몇 개만 클릭 — 빠진 게 안 보임.
- 브라우저 도구 3회+ 재시도 — 2회 캡 위반(fallback 룰).
- 파괴적/결제/외부발신 버튼을 "검증이니까" 클릭 — 절대 금지, 수동 이관.
- `blocked` 를 보고에서 누락 — 미검증이 검증됨으로 위장.
- 이번 diff 밖 기존 화면까지 전수 구동 — 범위 폭발, 이 게이트의 일 아님.

## Related

- `pipeline.md` Phase 4 — linear 소비자(forge/hunt/renew). 게이트 판정·loop-back 이 거기 물린다.
- `orchestrated.md` §4 Stage B — designer 가 이 결과를 intent 판정 입력으로 받는다.
- `output-contract.md` §V — 증거 배출처.
- `~/.claude/skills/mockup/references/design-context.md` — 시안 *제작* 충실도 SSOT(이 파일은 시안 *대조* 담당, 짝).
- `~/.claude/rules-ondemand/browser-verify-fallback.md` — 폴백 사다리 SSOT.
- `~/.claude/rules/verification-safety.md` V1 — 증거 무결성.
