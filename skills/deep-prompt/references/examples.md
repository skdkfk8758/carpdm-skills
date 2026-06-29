# deep-prompt — 작동 예시

좋은 goal 프롬프트 2개, 그리고 약한 것을 고친 before/after 1개. 검증 가능성
5질문 루브릭은 SKILL.md §4 에 있다(여기 중복 안 둠 — drift 방지).

## 예시 1 — 버그 수정 (brownfield, 회귀 잠금)

입력: *"스테이징에서 로그인 가끔 500 나는 거 백그라운드로 고쳐줘"*

```markdown
# Goal: 로그인 간헐적 500 수정 + 회귀 테스트

## Objective
`POST /api/login` 이 동시 요청 하에서 간헐적으로 던지는 500 의 근본 원인을
고치고, 재현 회귀 테스트로 잠근다.

## Success Criteria
- [ ] 실패를 재현하는 테스트가 fix 이전엔 fail, 이후엔 pass
- [ ] `npm test -- auth` 전체가 0 exit
- [ ] 50 동시 로그인 요청 부하 스크립트가 500 을 0건 반환

## Context
- 핸들러: `src/routes/auth.ts:42` (`loginHandler`)
- 세션 쓰기: `src/lib/session.ts:18` — 동시성 의심 지점
- 테스트: `tests/auth/` (vitest)
- 로컬 재현: `npm run dev` 후 `scripts/load-login.sh`

## Constraints
- `src/lib/legacy-auth.ts` 는 읽기만 — 다른 플로우가 의존, 수정 금지
- 커밋·푸시·PR 생성 금지 — 변경만 워킹트리에 두고 보고
- 인증 스키마(DB) 마이그레이션 금지

## Verification
1. `npm test -- auth` → 0 exit
2. `bash scripts/load-login.sh 50` → "500 count: 0" 출력

## Out of Scope
- 로그인 UI·프론트 변경
- rate limiting 추가 (별도 작업)

## Done & Report
백그라운드 잡으로 실행된다 — 분류기는 메시지 텍스트만 읽으니 검증 결과를 텍스트로
다시 적는다.
- 완료(Success Criteria 전부 참): `result:` 한 줄 — 근본 원인 + 변경 파일 수 +
  회귀 테스트 경로.
- 재현 불가 등으로 막힘: `needs input:` 한 줄에 무엇을 시도했고 무엇이 필요한지.
- 구조적으로 불가능: `failed:` 한 줄에 이유.
```

왜 자율 실행되나: 세 기준 모두 명령으로 판정된다. 가드레일이 push·마이그레이션을
막는다. 완료는 `result:`, 재현 불가 시 `needs input:` 로 빠져나온다 — 분류기가
읽는 리터럴 신호다.

---

## 예시 2 — 문서 최신화 (greenfield-ish, 반복 작업)

입력: *"skills 폴더 새로 추가된 거 README 에 반영하는 거 자동으로 돌려줘"*

```markdown
# Goal: README 스킬 표를 skills/ 와 동기화

## Objective
`README.md` 의 스킬 표가 `skills/` 의 모든 디렉토리를 정확히 반영하도록
누락 행을 추가하고 카운트를 갱신한다.

## Success Criteria
- [ ] `skills/` 의 모든 디렉토리가 README 에 링크로 존재
- [ ] README 상단 스킬 카운트 숫자 = `skills/` 디렉토리 개수
- [ ] `.claude/hooks/guard-readme-fresh.sh` 가 0 exit (차단 없음)

## Context
- 표: `README.md` 의 "## Skills" 섹션
- 현재 스킬: `skills/*/` (각 디렉토리에 SKILL.md)
- 신선도 가드: `.claude/hooks/guard-readme-fresh.sh` 가 링크 존재를 검사

## Constraints
- 표의 기존 행 설명 문구는 보존 — 누락 행 추가만
- `skills/` 디렉토리 자체는 만들거나 지우지 말 것 (README 만 수정)
- 커밋·푸시 금지 — 변경만 두고 보고

## Verification
1. `bash .claude/hooks/guard-readme-fresh.sh` → 0 exit
2. `diff <(ls -d skills/*/ | wc -l) <(grep -c 'skills/' README.md)` 일치 확인

## Done & Report
백그라운드 잡으로 실행된다 — 검증 결과를 텍스트로 다시 적는다.
- 완료(가드 0 exit + 카운트 일치): `result:` 한 줄 — 추가한 행 수 + 갱신한 카운트.
- 가드가 계속 실패: `needs input:` 한 줄에 어느 스킬이 누락 판정됐는지.
```

왜 자율 실행되나: 완료 조건이 기존 가드 스크립트의 종료 코드 = 객관적 판정.
사람 판단 0. 완료/막힘이 분류기가 읽는 리터럴 토큰으로 신호된다.

---

## before/after — 약한 기준 고치기

입력: *"우리 API 코드 좀 깔끔하게 백그라운드로 정리해줘"*

### ✗ before (자율 실행 불가)

```markdown
## Objective
API 코드를 깔끔하게 개선한다.

## Success Criteria
- [ ] 코드가 더 읽기 쉬워짐
- [ ] 중복이 줄어듦
- [ ] 성능이 개선됨
```

문제: 세 기준 다 검증 불가. "읽기 쉬움"·"개선"은 누가 판정? 백그라운드 에이전트는
영원히 못 멈추거나, 아무거나 바꾸고 "됐다" 한다. "정리"가 동작을 바꿔도 되는지도
불명 — Constraints 공백.

### ✓ after (명료화 후)

deep-prompt 가 물을 것: *"동작은 그대로 유지하나요(리팩터), 아니면 바꿔도
되나요? 완료를 어떻게 확인하죠 — 통과시킬 테스트나 줄일 중복의 구체 위치는?"*

답: *"동작 그대로. `src/routes/` 세 파일에 같은 검증 로직 복붙돼 있는 거 헬퍼로
빼줘. 기존 테스트 다 통과하면 됨."*

```markdown
## Objective
`src/routes/{users,orders,products}.ts` 에 중복된 입력 검증 로직을
`src/lib/validate.ts` 단일 헬퍼로 추출하고 세 곳이 호출하게 바꾼다 — 동작 변화 0.

## Success Criteria
- [ ] 검증 로직이 `src/lib/validate.ts` 한 곳에만 존재 (세 파일에서 인라인 제거)
- [ ] 세 라우트가 모두 새 헬퍼를 import 해 호출
- [ ] `npm test` 전체가 추출 전후 동일하게 pass (0 exit)

## Verification
1. `grep -rn "function validateInput" src/routes/` → 0 매치 (인라인 사라짐)
2. `npm test` → 0 exit
```

핵심 전환: 모호한 형용사("깔끔") → 관찰 가능한 결과(`grep` 0 매치 + 테스트 통과).
이게 자율 에이전트가 혼자 끝낼 수 있는 유일한 형태다.
