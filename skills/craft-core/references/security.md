# Secure Verify

Phase 4 는 무언가 출시되기 전에 변경이 동작하고 AND 안전함을 증명한다. 두 부분이
함께 돈다: 프로젝트의 기능 검증 게이트, 그리고 diff 에 대한 보안 pass.
그 안에 SQL injection 이 있는 green 테스트 스위트는 완료가 아니다.

## 1. 기능 게이트

프로젝트의 표준 검증 경로를 돌린다. 프로젝트가 하나 정의하면 (예:
`verify.sh`, `make verify`, 또는 문서화된 명령), 그걸 쓴다 — 어떤 체크가
적용되는지 이미 안다. 아니면 명백한 등가물을 돌린다: tests, typecheck,
lint, build. 이 중 하나라도 red 인 동안 아무것도 진행하지 않는다.

## 2. diff 에 대한 보안 pass

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

## 3. 각 발견을 적대적으로 검증하라

보안 이슈를 진짜로 보고하기 전에, **반박**을 시도하라: 입력이 실제로
도달 가능한가? 실제로 신뢰할 수 없나? 이미 그걸 무력화하는 상류 체크가
있나? 불확실하면 "반박됨" 을 기본으로 — false-positive 발견의 벽은 짧은
참 하나보다 나쁘다, 사용자가 리포트를 무시하도록 훈련시키기 때문이다.
반박 시도에서 살아남은 발견만 보고하라, 각각 file:line 과 왜 exploit 가능한지와
함께.

## Output

리포트: 기능 게이트 결과 (체크별 pass/fail), 보안 평결 (clean, 또는
살아남은 발견을 severity + location 과 함께), 그리고 의식적으로 수용하는 잔여
리스크. 무언가 red 면, 증거와 함께 평이하게 말하라 —
부분 pass 를 "done" 으로 절대 올림하지 말 것.
