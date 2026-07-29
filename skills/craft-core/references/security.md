# Secure Verify

Phase 4 는 무언가 출시되기 전에 변경이 동작하고 AND 안전함을 증명한다. 세 부분이
함께 돈다: 프로젝트의 기능 검증 게이트, diff 에 대한 correctness 리뷰, 그리고 diff
에 대한 보안 pass. 테스트가 못 본 버그가 남은, 혹은 SQL injection 이 있는 green
테스트 스위트는 완료가 아니다.

**병렬 실행 (2026-07-29 — p4 직렬이 총 벽시계 23% 실측).** §1·§2·§3 은 서로
독립이고 전부 read-only 다(§2 codex read-only, §3 리뷰) — **§2 codex 를 Bash
`run_in_background` 로 먼저 띄운 뒤**(watchdog 포함, `codex-review.md` 계약)
§1 기능 게이트와 §3 보안 pass 를 그동안 돌린다. codex 완료 알림이 오면 원장
triage — codex 벽시계(medium 실측 206s)가 §1·§3 뒤로 숨는다. 단 **§4 반박
게이트와 발견 처리(red-first)는 셋이 모두 끝난 뒤** — 발견을 고치는 diff 변경이
병렬 중에 끼면 §1 green 이 무효가 된다.

## 1. 기능 게이트

프로젝트의 표준 검증 경로를 돌린다. 프로젝트가 하나 정의하면 (예:
`verify.sh`, `make verify`, 또는 문서화된 명령), 그걸 쓴다 — 어떤 체크가
적용되는지 이미 안다. 아니면 명백한 등가물을 돌린다: tests, typecheck,
lint, build. 이 중 하나라도 red 인 동안 아무것도 진행하지 않는다.

## 2. diff 에 대한 correctness 리뷰 — codex 1-pass (cross-model)

기능 게이트는 *작성된* 테스트가 통과함을 증명할 뿐, 테스트가 **놓친** 버그는
잡지 못한다 — 미테스트 분기, off-by-one, null/경계 처리, 잘못된 조건, 미묘한
race. 이 갭을 변경된 diff 에 대해 **codex 1-pass 리뷰**로 메운다. 같은 모델의
자기 리뷰(`/code-review`)보다 cross-model 독립성을 검증단에 두는 선택이다 —
구현을 쓴 가중치와 다른 가중치가 diff 를 읽는다(2026-07-29, Phase 2 적대리뷰의
상류 이동과 짝). 호출·마스킹·effort·verdict 파싱·watchdog·원장 규칙 SSOT 는
`codex-review.md` — 이 절은 diff 소비처의 델타만 정의한다.

- **대상 = 이 빌드의 diff.** `<task>` 에 브랜치/커밋 범위(`git diff <base>...HEAD`
  의 대상)를 명시하고 codex 가 repo cwd 에서 직접 읽게 한다. read-only + 마스킹
  게이트는 SSOT 그대로.
- **`<look_for>` — correctness 만.** 미테스트 분기, off-by-one, null/경계,
  잘못된 조건/연산자, 자원 누수, race, 테스트가 있어도 그 케이스를 실제로 못
  잡는 단언. 품질 (reuse / 단순화 / 효율 / altitude) 은 리뷰 대상이 아니다
  (원하면 빌드 후 `/simplify` — Phase 5 §N 권장 라우팅), 보안은
  아래 §3 이 본다 — 프롬프트에 "correctness bugs only, no quality/security
  nits" 로 좁혀 중복을 막는다.
- **effort 게이트** (`codex-review.md` 와 동일): 기본 `--effort medium`.
  보안 surface(auth / payment / 권한 경계)·외부 호출자 계약 변경·6+ 파일·
  orchestrated 모드만 `high`.
- **발견 처리 = red-first.** craft 는 test-first 다 — 원장에서 FIXED 로 닫으려면
  바로 고치지 말고 **실패 회귀 테스트를 먼저 (red) 쓰고 → fix → green**
  (TDD 사이클로 잠깐 Phase 3 으로 되돌아가는 셈). high 는 전부 닫은 뒤에만 wrap.
- **호출 횟수 = 빌드당 1회 고정.** loop-back(intent gap · 발견 fix)으로 diff 가
  변해도 codex 를 재호출하지 않는다 — delta 는 회귀 테스트 green + §4 반박 게이트 +
  로컬 검토로 닫는다(pipeline Phase 4 게이트의 delta-only 재진입 규칙과 같은 결정,
  재호출은 루프당 +5~15분에 발견 한계효용 낮음).
- **폴백 래더.** codex 불가(limit / hang-kill / 미설치) → `/code-review` 를
  "correctness 버그만" 으로 좁혀 호출 → 그것도 미설치면 위 `<look_for>` 카테고리를
  직접 훑는다. 어느 폴백이든 그 사실을 리포트에 명시한다.
- **계측 (은퇴 조건의 원료).** wrap 의 `craft-timing.jsonl` 행에 `p4Review`
  필드를 기록한다 — `{"source":"codex|code-review|manual","sec":<초>,
  "found":<발견 수>,"confirmed":<§4 반박 게이트 생존 수>}`. **은퇴 조건**: 1개월
  표본에서 codex 의 confirmed unique 발견율이 폴백(`/code-review`) 대비 우위가
  없으면 codex 를 기본에서 폴백으로 강등한다(글로벌 룰 수명 규율 — 축적 ≠ 진보).

발견은 §4 의 반박 게이트를 똑같이 통과해야 보고된다.

## 3. diff 에 대한 보안 pass

무거운 작업은 branch/diff 에 대해 **`security-review`** 스킬을 쓴다. 추가로,
가장 자주 무는 카테고리를 변경에서 눈으로 훑는다:

- **Injection** — 사용자 입력이 SQL / shell / eval 에 도달. SQL 은 parameterized
  쿼리만; 동적 식별자는 allowlist 에서 와야 하고, 절대 문자열
  보간된 입력에서 오면 안 된다.
- **AuthN / AuthZ** — 새 경로가 이웃과 같은 auth 를 강제하나?
  형제가 하는 체크를 건너뛰는 엔드포인트나 액션이 있나?
- **Secret & host** — 코드나 빌드된 번들에 credential, token, 하드코드된 인프라
  host 없음. 설정은 literal 이 아니라 env/proxy 에서 온다.
- **입력 검증** — 모든 외부 입력은 경계에서 검증 (schema /
  DTO), downstream 에서 신뢰하지 않음.
- **Path traversal / 파일 작업** — 사용자 제어 경로 sanitize.
- **안전하지 않은 deserialization / `eval`** — 신뢰할 수 없는 데이터에 대해 없음.
- **에러 & 로그 위생** — 에러가 stack trace, secret, 내부 구조를 클라이언트에
  누설하지 않음.
- **의존성** — 새 의존성은 필요하고 known-vulnerable 하지 않음.

프로젝트별 guardrail (예: 금지된 하드코드 host, service→DB 경계 룰) 을
존중하라 — 그것들은 이유가 있어 존재하고 게이트가 강제해야 한다.

## 4. 각 발견을 적대적으로 검증하라

correctness 든 보안이든 발견을 진짜로 보고하기 전에, **반박**을 시도하라: 입력이 실제로
도달 가능한가? 실제로 신뢰할 수 없나? 이미 그걸 무력화하는 상류 체크가
있나? (correctness 발견이면: 이 경로가 실제로 도달 가능한가? 기존 테스트가
정말 이 케이스를 못 잡나? 입력 제약이 그 분기를 애초에 배제하지 않나?)
불확실하면 "반박됨" 을 기본으로 — false-positive 발견의 벽은 짧은
참 하나보다 나쁘다, 사용자가 리포트를 무시하도록 훈련시키기 때문이다.
반박 시도에서 살아남은 발견만 보고하라, 각각 file:line 과 왜 exploit (또는
오작동) 가능한지와 함께.

## Output

리포트: 기능 게이트 결과 (체크별 pass/fail), correctness 평결 + 보안 평결
(각각 clean, 또는 살아남은 발견을 severity + location 과 함께), 그리고 의식적으로
수용하는 잔여 리스크. 무언가 red 면, 증거와 함께 평이하게 말하라 —
부분 pass 를 "done" 으로 절대 올림하지 말 것.
