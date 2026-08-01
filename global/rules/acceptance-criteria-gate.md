# Acceptance-Criteria Gate — 수용 기준 체크 = 완료/PR 게이트

IMPORTANT: 이슈·티켓의 **수용 기준(Acceptance Criteria / 테스트 항목 / 체크박스)** 은 장식이
아니라 **완료 게이트**다. 작업을 완료로 선언하거나, PR 을 올리거나, 이슈를 Done 으로
전이하기 전에 — 각 항목을 **관찰 가능하게 검증**하고, 검증된 항목만 체크한다. 하나라도
미검증·미체크면 완료가 아니다.

## 왜 (실측 인스턴스)

SUR-26(survey-radar, 2026-06-30): 수용 기준 3개가 **미체크인 채 Done + PR 머지**됐다. 그중
#3 "다른 군집 카드 description 일관"은 실제로 **미충족**이었고 — 같은 description 렌더가 개요 탭
`Consumer.tsx` 에 복제돼 말줄임/툴팁이 빠져 있었다. 체크박스를 검증했더라면 그 자리에서 잡혔을
누락이, 검증 생략 탓에 "완료"로 위장돼 사용자에게 넘어갔다. 검증 누락 → 거짓 완료 → 미묘한
회귀 전파.

## 규칙

### G1: 검증이 체크를 선행한다
- 각 수용 기준을 **관찰 가능한 검증**(테스트 통과·런타임 확인·재현 시나리오)으로 통과시킨 뒤
  체크한다. 검증 없이 체크 금지(거짓 완료). 코드만 작성하고 "됐을 것"으로 체크하지 않는다.
- 모호한 항목("잘 동작")은 검증 가능한 형태로 먼저 보정한 뒤 검증한다(karpathy 원칙 4).

### G2: 미충족이면 완료/PR/Done 중지 + 사용자 안내
- 작업 종료·**PR 생성**·이슈 Done 전이 **직전에 수용 기준을 다시 확인**한다. 체크가 100%
  아니면 — 하나라도 미검증·미충족이면 — **그 행위를 중지**하고, 어느 항목이 왜 미충족인지
  사용자에게 안내한 뒤 멈춘다. 미충족 항목을 남긴 채 진행하지 않는다.
- "다음 PR 에서 채우겠다" 금지(`yagni-core.md` 와 동형 — 다음 PR 은 오지 않는다).

### G3: 체크는 검증 + 반영 후 사실로 기록
- 검증 통과 + 변경이 대상 브랜치에 반영된 뒤 체크박스를 `[x]` 로 갱신한다. 검증 근거(테스트
  결과·런타임 증거)를 코멘트로 남기면 추적이 산다.
- **증거 첨부 시 secret 마스킹 필수.** 테스트 로그·런타임 스크린샷·재현 출력을 이슈/PR
  코멘트에 붙일 때 토큰·PII·내부 URL·DB dump 가 박히지 않게 마스킹한다. 외부 서비스(Linear·
  GitHub)에 올린 내용은 캐시·인덱싱돼 삭제해도 남는다 — 첨부 전 노출 검사.

### G4: 보안은 AC 와 직교 — 끼워넣지 말고 병행한다
- **기능 AC green ≠ 보안 통과.** AC 는 "기능 동작"을 잠근다. authz 우회·injection·secret 노출은
  AC 에 적혀 있지 않으면 통째로 빠진다. AC 체크박스 100% 를 "완료"로 선언해도 보안은 사각으로 남는다.
- **보안 민감 이슈는 별도 게이트 필수.** auth/권한·데이터·입력처리·외부발신을 건드리는 이슈는
  PR 전 `security-review`(diff 보안) 또는 `fortify`(운영 5축)를 **직교 게이트**로 통과한다.
  AC 항목으로 대체 불가 — 둘을 섞으면 둘 다 샌다.
- **재현 검증은 격리 환경에서.** 버그 재현 검증이 운영DB·실데이터를 건드리면 비가역
  (`branch-worktree-strategy.md` §6b slow-lane 동형). 검증은 격리 환경에서 돌린다.

## 적용 범위

이슈/티켓 기반 작업 전반 — forge·hunt·renew·linear-goal·land, 그리고 수용 기준·AC·
체크리스트가 있는 모든 작업. 스킬별 hard gate 는 각 SKILL 이 인스턴스화한다(예: linear-goal
은 PR 전 수용 기준 100% 게이트).

## 강제 (hook 자동 — 비차단 nudge)

- `guard-acceptance-criteria-nudge.sh`(PostToolUse Bash) — `gh pr create`/`gh pr merge` 에
  연결 이슈ID(브랜치/명령)가 잡히면 "수용 기준 검증·체크했나?" stderr 리마인드. **비차단**
  (`exit 0`) — 훅은 각 항목의 충족 여부를 판정할 수 없다(맥락 판단: 테스트 통과? 런타임 확인?).
  실제 게이트(G1~G3)는 본 룰을 읽은 사람/AI 가 수행한다. 끄기: `GUARD_ACCEPTANCE_NUDGE_DISABLE=1`.
- 짝 훅 `guard-linear-state-nudge.sh` 는 같은 경계에서 *상태 전이*(In Progress/Done)를 리마인드 —
  본 훅은 *수용 기준 체크박스 검증*을 리마인드(서로 보완, 둘 다 비차단).

## Anti-patterns

- 수용 기준 미체크인 채 Done/머지 — 미충족이 거짓 완료로 위장(SUR-26).
- 검증 없이 체크박스만 `[x]` — 거짓 완료.
- "코드 썼으니 됐을 것" 으로 런타임/테스트 검증 생략.
- 미충족 항목을 알면서 PR 강행 — G2 위반.
- AC green 을 보안 통과로 착각 — authz·injection·secret 누락이 사각으로 통과(G4 위반).
- 검증 증거에 토큰·PII·DB dump 를 마스킹 없이 첨부 — 외부 서비스 캐시에 영속 노출(G3 위반).

## Related

- `~/.claude/rules/karpathy-core.md` 원칙 4(Goal-Driven: define success criteria, loop until verified) — 본 룰의 상위.
- `~/.claude/skills/linear-goal/SKILL.md` — PR 전 수용 기준 100% 게이트 인스턴스.
- `~/.claude/rules/yagni-core.md` — "다음 PR 에서" 금지 동형 근거.
- `~/.claude/skills/fortify/SKILL.md` · 빌트인 `security-review` — G4 직교 보안 게이트(짝).
- `~/.claude/rules/branch-worktree-strategy.md` §6b — 재현 검증 격리·운영DB slow-lane 근거.
