# Browser Verify Fallback — 브라우저 검증 2회 실패 시 ground-truth 전환

IMPORTANT: 브라우저 자동화(Claude-in-Chrome bridge·Playwright)는 검증 **수단**이지 검증 **자체**가 아니다. 실측: Chrome extension bridge 가 5회 재시도 내내 실패해 수동 DevTools 측정으로 넘어가기까지 시간을 통째로 태웠다. **도구가 막히면 빨리 포기하고 대체 경로로 검증을 완수한다** — 재시도는 검증이 아니다.

## 규칙

1. **2회 캡.** 같은 브라우저 도구 호출이 2회 연속 실패(무응답·bridge 에러·탭 invalid)하면 그 도구 재시도를 중단한다. 3회째 동일 호출 금지.
2. **Fallback 사다리 (위에서 아래로).**
   - Chrome bridge 실패 → **Playwright MCP** (독립 브라우저, bridge 무관).
   - 브라우저 전체 불가 → **curl/API 직접 호출** (응답 코드·payload·헤더 — transfer size·캐시 헤더류는 `curl -w`/`--compressed` 로 측정 가능).
   - 그것도 불가/부적합 → **git diff·테스트·DB 쿼리** ground-truth 로 검증 범위를 재정의.
3. **실패 명시 보고.** fallback 으로 내려갔으면 "브라우저 검증은 도구 실패로 미수행, X 로 대체 검증" 을 결과에 명시한다. 시각 확인(레이아웃·렌더링)이 검증 요건인데 대체 불가면 — green 으로 위장하지 말고 "수동 확인 필요" 로 남긴다.
4. **QA 런타임 에러 판정도 동일.** 브라우저發 에러 리포트는 hot-reload 타이밍 false positive 가능 — 재현 후 판단 (기존 메모리 컨벤션과 동일 방향).

## Anti-patterns

- bridge 실패를 3회+ 재시도하며 대기 — 2회 캡 위반.
- 브라우저 검증 실패를 침묵하고 나머지 green 만 보고 — "검증됨" 위장.
- fallback 없이 "브라우저가 안 돼서 검증 못 함" 으로 종료 — curl/테스트로 커버 가능한 범위까지 방기.

## Related

- Playwright MCP · `playwright-cli` 스킬 — 1차 fallback 경로.
