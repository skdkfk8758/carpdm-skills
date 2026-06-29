# 작성자·비판 리뷰어 다이어드 — 독립 critic 으로 false-done 선제 차단 (Phase 3·4·6 공통)

Phase 3·4·6 에서 읽는다. 작성자는 자기 추론에 anchoring 한다 — 자기가 쓴 Goal
Prompt 의 구멍, 자기가 그린 시안의 모호함을 *같은 컨텍스트*에서는 못 본다. 그래서
**독립 컨텍스트의 비판 리뷰어**를 항상 붙인다. 이게 가장 비싼 실패(어려운 걸 goal
로 보내 미묘한 오류를 사람이 떠안는 false-done)를 사람 게이트 *이전에* 정조준해
걸러내는 장치다.

레버리지 순: **Goal Prompt(자율 worker 의 유일 계약) > 시안(시각 계약) > 구현 PR.**

## 메커니즘 — 항상 두 역할

1. **작성자(writer)** 가 초안을 만든다. 메인 루프가 직접 쓴다(티켓 컨텍스트를 이미
   쥐고 있어 효율적). 깨끗한 컨텍스트 초안이 굳이 필요하면 writer 서브에이전트로
   분리해도 되지만 기본은 메인 루프 = 작성자/통합자.
2. **비판 리뷰어(critic)** = **독립 서브에이전트**(`Agent`, fresh 컨텍스트). 초안을
   *공격*하도록 프롬프트한다 — 아래 페이즈별 rubric 으로 **구체적·위치 명시 결함만**
   반환. 불확실하면 "수정 필요" 가 기본값. **빈 칭찬·"좋아 보임" 은 리뷰 실패** —
   구체 blocking 결함이 없으면 "blocking 없음" 으로 *명시적 판정*하라고 강제한다.
3. 메인 루프가 결함을 반영해 **수정**하고 critic 을 **재spawn**. blocking 결함 0
   또는 **2라운드 cap** 까지 루프.
4. cap 도달 시 남은 우려는 **숨기지 않는다** — 사람 게이트(Phase 5)에 그대로 노출.
   (구현 PR critic 은 Phase 6 비동기 — In Review 전환과 함께 findings 를 사람에게.)

**독립성 불변식**: critic 은 초안을 쓴 컨텍스트와 *반드시 다른* **독립 컨텍스트**여야
한다 — 독립이 적대 리뷰의 전부다. Phase 3·4 는 별도 `Agent` 서브에이전트 호출,
Phase 6(구현 PR)은 별도 서브에이전트 또는 빌트인 `/code-review`(자체적으로 diff 를
fresh 분석하므로 독립성 충족) 중 하나. 같은 턴에서 자기검토하면 anchoring 이 그대로
남아 무의미하다. critic 에는 **초안 본문(파일 경로)·diff(worktree 경로)만** 주고
작성자의 추론 과정은 넘기지 않는다 — 결론을 보고 독립적으로 공격해야 한다.

## 페이즈별 critic rubric (critic 서브에이전트 프롬프트에 박는 공격점)

- **Phase 3 (Goal Prompt)** — *"이 프롬프트로 자율 worker 가 false-done 낼 구멍은?"*
  ① Success Criteria 가 5질문 게이트(관찰가능·Verification 짝·에이전트 권한 내·
  이분법·루프 종료)를 항목마다 전부 통과하나, ② 티켓 AC 를 1:1 커버하나(빠진 AC
  없나), ③ Constraints 가 비가역/외부발신(머지·push·배포·삭제)을 다 막나,
  ④ `result:`/`needs input:`/`failed:` 토큰이 글자 그대로 박혔나, ⑤ 모호한 동사
  ("개선/정리/안전하게")가 0 인가. 하나라도 구멍이면 위치를 짚어 반환.

- **Phase 4 (시안)** — *"worker 가 이 시안에서 못 짚을 모호함은?"*
  ① 주요 상태 커버(빈/로딩/에러/채워짐), ② DESIGN 토큰 충실(추측한 색·폰트·간격
  없나 — 대상 repo 토큰과 일치하나), ③ 시안의 핵심 요소가 Goal Prompt Success
  Criteria 에 *관찰 가능한 대조 항목*으로 묶였나(안 묶이면 시안은 장식), ④ 비-UI 면
  로직 약도가 티켓 산출물과 일치하나(엉뚱한 계약 그리지 않았나).

- **Phase 6 (구현 PR)** — worker 가 PR 을 연 **뒤(비동기)**, diff 를 Goal Prompt 의
  Success Criteria·Constraints 대조로 공격: ① SC 미충족 항목, ② 범위 넘침(지목 영역
  밖 수정), ③ Constraints 위반(머지/push/삭제/외부 호스트 하드코딩), ④ 명백한
  정확성 결함. 빌트인 `/code-review` 를 critic 으로 써도 된다. findings 를 Linear
  In Review 전환과 함께 사람에게 보고 — **자동 머지·자동 수정 절대 금지**.

## Anti-patterns

- critic 을 같은 컨텍스트 자기검토로 — anchoring 그대로, 적대 리뷰가 죽는다.
- 무한 루프 — 2라운드 cap, 남은 우려는 사람에게 노출(숨기면 게이트가 거짓).
- 빈 칭찬 통과 — 구체 위치 명시 결함 강제, 없으면 "blocking 없음" 명시 판정.
- 작성자 추론을 critic 에 통째로 넘김 — 결론(초안 파일)만 줘서 독립 공격 유도.
- 구현 PR critic 의 findings 로 자동 머지/자동 수정 — human merge-gate 붕괴.
