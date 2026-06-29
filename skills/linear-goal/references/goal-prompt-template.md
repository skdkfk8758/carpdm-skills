# Goal Prompt 템플릿 — 자율 실행 계약 (구 deep-prompt §3~4 흡수)

Phase 3 에서 읽는다. Goal Prompt 는 사람이 지켜보지 않는 동안 goal worker 가 가진
**유일한 계약**이다. 자율 실행 실패는 거의 항상 **약한 성공 기준**에서 온다 — 그래서
세 가지가 본문에 반드시 박혀 있어야 한다: ① 완료가 무엇인지(Success Criteria),
② 건드리면 안 되는 것(Constraints), ③ 완료/막힘을 실행기에 어떻게 신호하는지
(Done & Report). 백그라운드 분류기는 worker 의 **메시지 텍스트만** 읽어 상태를
판정한다(tool 출력·subagent 보고는 안 봄).

## 고정 템플릿 — 이 섹션 순서 그대로

`Objective / Success Criteria / Done & Report` 세 개는 **절대 빼지 않는다**(자율성의
척추). Out of Scope 가 자명하면 생략 가능.

```markdown
# Goal: <한 줄 제목 — 티켓 ID 포함, 예: [ADT-152] 격자 셀 클릭 팝업>

## Objective
<달성할 것 한 문장. 동사로 시작. 모호한 형용사("개선","정리") 금지 —
관찰 가능한 결과로.>

## Success Criteria
<티켓 AC/체크리스트를 1:1 매핑. 각 항목은 명령/파일/출력으로 참/거짓이 갈려야 함.>
- [ ] <검증 가능한 조건 1 — 예: `npm run build` 0 exit>
- [ ] <검증 가능한 조건 2 — 예: 격자 셀 클릭 시 DOM 에 `.cell-popup` 렌더>
- [ ] <시안 대조 항목(있으면) — 예: 시안의 요소 X·Y·Z 가 렌더 DOM 에 존재>

## Context
<repo, 관련 경로(file:line), 티켓 설명·코멘트·이슈관계 요약, 환경. worker 가
맨바닥에서 시작한다고 가정. brownfield 면 건드릴 영역만 Read/Grep 으로 확인한 것만.
시안을 만들었으면: UI 시각 타겟: <slug>-review.html (이 레이아웃·요소 기준)>

## Constraints
<사람 없이 도는 동안의 가드레일.>
- 지목된 영역만 수정, 그 밖은 읽기만
- 커밋은 해도 됨. **머지·develop/main push·배포·삭제·메일 발송 금지** — PR 까지만
- <티켓 특화 제약 — 예: 외부 DB 호스트 하드코딩 금지>

## Verification
<Success Criteria 와 1:1 대응하는 정확한 명령·관찰. worker 가 돌려 자가 판정.>
1. `npm run build` → 0 exit
2. <셀 클릭 후 DOM 확인 방법>

## Out of Scope
<명시적 비목표 — 범위 넘침 방지. 자명하면 생략.>

## Done & Report
이 goal 은 사람이 지켜보지 않는 백그라운드 잡으로 실행된다. 분류기는 네 **메시지
텍스트만** 읽으니 검증 결과·변경 요약을 반드시 텍스트로 다시 적어라.
- 완료 — Success Criteria 가 **전부 참**이면, 마지막 메시지를 `result:` 로 시작하는
  한 줄로 맺어라(달성 내용 + 핵심 수치). 이게 유일한 완료 신호다.
- 막힘 — 사람의 한 가지 행동(권한·결정·접근)이 있어야만 진행 가능하면 `needs input:`
  한 줄에 정확히 무엇이 필요한지.
- 불가 — 전제가 틀렸거나 구조적으로 불가능하면 `failed:` 한 줄에 이유.
그 외엔 Verification 을 돌려 Success Criteria 가 전부 참이 될 때까지 루프한다.
```

> 세 토큰(`result:`/`needs input:`/`failed:`)은 **글자 그대로** 박는다 — 실행기가
> emit 할 신호이지 다듬을 산문이 아니다. "Success Criteria 전부 참 → `result:`" 의
> 연결이 자율 루프 종료 조건을 런타임 완료 신호에 묶는 다리다.

## 검증 가능성 게이트 — Success Criteria 항목마다 5질문, 하나라도 No 면 다시 써라

티켓 AC 를 그대로 옮기면 흔히 검증 불가다(AC 가 "사용자가 X 할 수 있다" 류). 저장
전, 각 Success Criteria 항목을 통과시킨다:

1. **관찰 가능한가** — 사람 판단 없이 명령 출력·파일 내용·종료 코드로 참/거짓이
   갈리나? ("안전해짐" ✗ / "11번째 요청에 429" ✓)
2. **Verification 짝이 있나** — 이 기준을 확인할 정확한 명령/관찰이 Verification 에
   있나?
3. **에이전트 권한 안인가** — 가진 도구·접근으로 실제 확인 가능한가?
4. **이분법인가** — 부분 충족이 모호하지 않나? "대부분 통과" → "모든 테스트 통과".
5. **루프를 끝내나** — 이 기준들이 다 참이면 worker 가 멈춰도 되나?

좋은 예: `tests/auth/ 모든 테스트 pass`, `429 가 11번째 요청에 반환`,
`grep -rn "validateInput" src/routes/ → 0 매치`.
나쁜 예: `로그인이 더 안전해짐`, `코드가 더 읽기 쉬워짐`, `성능 개선`.

## 저장

Goal Prompt 는 worktree 분기 전이라 아직 대상 repo 가 없을 수 있다 — scratchpad
또는 사용자 지정 위치에 `<slug>.md` 로 저장하고, Phase 6 worktree 생성 후 worker
task 에 그 내용을 전달한다. `<slug>` 는 Objective 에서 kebab-case (티켓 ID 포함
권장, 예 `adt-152-cell-popup`).

Context 가 "UI 시각 타겟: `<slug>-review.html`" 을 가리키면, Phase 6 spawn 직전에
그 HTML 을 worktree 안으로 복사한다 — worker 는 worktree cwd 에서 돌아 scratchpad
파일을 못 열기 때문이다. 복사하거나 Context 에 절대경로를 박아 worker 가 실제로
참조 가능하게 한다.

## 작동 예시

입력 티켓 (요약): *ADT-211 "격자 250m 셀 클릭 시 영역 프로파일 팝업" · area:map ·
estimate 2 · AC: ① 셀 클릭 시 팝업 ② 팝업에 OD top5 ③ 닫기 버튼*

```markdown
# Goal: [ADT-211] 250m 격자 셀 클릭 → 영역 프로파일 팝업

## Objective
지도의 250m 격자 셀을 클릭하면 해당 셀의 영역 프로파일(OD top5)을 보여주는 팝업을
렌더하고, 닫기 버튼으로 해제한다.

## Success Criteria
- [ ] `npm run build` 0 exit
- [ ] 셀 클릭 시 DOM 에 `.cell-profile-popup` 노드 1개 렌더 (없으면 fail)
- [ ] 팝업 내부에 OD origin top5 목록(li 5개) 표시
- [ ] 팝업의 닫기 버튼 클릭 시 `.cell-profile-popup` 제거
- [ ] 시안(adt-211-review.html)의 팝업 헤더·top5 리스트·닫기버튼 3요소가 렌더 DOM 에 존재

## Context
- repo: ADType-Intelligence (apps/next)
- 격자 렌더: apps/next/src/map/<grid layer> (Read 로 확인 후 정확 경로)
- OD 데이터: @api/* repository 경유
- UI 시각 타겟: adt-211-review.html

## Constraints
- apps/next/src/map 영역만 수정, 데이터레이어(apps/api)는 읽기만
- 머지·push·배포 금지 — PR 까지만
- 외부 DB 호스트 하드코딩 금지

## Verification
1. `npm run build` → 0 exit
2. dev 서버에서 셀 클릭 → DOM 에 `.cell-profile-popup` + li 5개 확인
3. 닫기 클릭 → 노드 제거 확인

## Done & Report
백그라운드 잡으로 실행 — 검증 결과를 텍스트로 다시 적는다.
- 완료(전부 참): `result:` 한 줄 — 변경 파일 + 팝업 구현 요약.
- 막힘: `needs input:` 한 줄.
- 불가: `failed:` 한 줄.
```

왜 자율 실행되나: 5 기준 모두 명령·DOM 으로 판정되고 시안 대조 항목이 관찰 가능
형태다. 가드레일이 머지·push 를 막는다. 완료는 `result:` 로 빠져나온다.
