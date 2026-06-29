---
name: linear-goal
description: Linear 이슈 1건을 받아 goal 자율 실행에 최적화된 Goal Prompt 로 메타프롬프팅하고, 그 결과물 시안(UI 면 mockup, 비-UI 면 로직·구조 약도)을 Goal Prompt 와 함께 단일 HTML 로 제시해 승인받은 뒤, repo 라우팅·worktree 분기를 검증하고 goal worker 백그라운드 잡을 실행해 PR 까지 가는 오케스트레이터. 사용자가 Linear 티켓을 자동개발로 굴리고 싶어 할 때 사용 — "ADT-211 goal 로 돌려줘", "이 티켓 메타프롬프트해서 시안 보여주고 진행", "리니어 이슈 자율개발 시작", "티켓 하나 줄게 시안 만들어서 승인받고 goal 진행", "ADT-N 작업해줘(시안 먼저)" 같은 표현. 티켓 ID(ADT-211 등)나 붙여넣은 티켓 텍스트를 주며 "goal/자율/백그라운드로", "시안 먼저 보고 승인", "Goal Prompt 만들어서 진행" 류로 말하면 — 'linear-goal'·'스킬'이라는 말을 안 써도 — 트리거한다. harness-class(estimate≥5·cross-cutting·전면개편·research)로 판정되면 goal 강행 대신 harness-run 을 추천하고 멈춘다. 티켓 없는 일반/단발성 Goal Prompt 텍스트만 원할 때(use deep-prompt), 모호한 아이디어 결정화(use deep-interview), 직접 기능 빌드/버그수정(use forge/hunt), 열린 PR 머지·정리(use land)에는 쓰지 말 것 — linear-goal 은 '티켓→시안 승인→자율 goal 실행→PR' 한 흐름을 엮는다.
---

# linear-goal — Linear 티켓을 시안 승인 게이트로 묶어 자율 goal 실행

사용자가 Linear 티켓 하나를 던진다. 그걸 그대로 goal 칸에 넣으면 자율 에이전트는
*언제 끝났는지 모른 채* 표류하고, 사람은 무엇이 만들어질지 **보지 못한 채** 결과를
떠안는다. 이 스킬은 그 사이에 **시각 승인 게이트**를 넣는다: 티켓을 검증 가능한
Goal Prompt 로 바꾸고, 만들어질 것의 시안(UI mockup 또는 로직/구조 약도)을 Goal
Prompt 와 함께 한 장의 HTML 로 보여주고, 사용자가 승인하면 — 그때서야 — worktree
분기를 검증하고 goal worker 를 자율 실행한다.

핵심 가치는 글쓰기가 아니라 **세 가지를 한 흐름으로 묶는 것**이다: ① Linear 의
실제 필드(AC·라벨·estimate·첨부)를 Goal Prompt 에 정확히 녹이고, ② 사람이 *볼 수
있는* 시안으로 false-done 을 사전 차단하고, ③ goal worker 가 헛돌지 않도록
worktree 가 실제로 준비됐는지 확인한 뒤에만 띄운다.

> 이 스킬은 `deep-prompt`(범용 의도→Goal Prompt+시안)의 **Linear 특화 자매 스킬**
> 이다 — 티켓 없는 일반 goal 은 deep-prompt, Linear 티켓 1건을 시안 승인 게이트로
> 묶어 자율 실행까지 가는 건 linear-goal. dispatch 라우팅(이슈→repo, goal/harness
> 판정)은 `references/routing.md`(SSOT)를 Phase 2 에서 돈다.

## 안전 불변식 — 먼저 읽을 것

이 스킬은 비가역·외부발신 행위(Linear 상태 전이, worktree 생성, 백그라운드 잡
spawn)를 **사용자 승인 뒤에만** 한다. 절대 자동으로 하지 않는 것:

- **PR 머지 / develop·main 직접 push / 배포** — human merge-gate (ADR-041). 머지와
  Linear "Done" 전이는 `land`/사람 몫. 이 스킬은 **In Review 까지만** 간다.
- **승인 전 어떤 mutation 도** — fetch·시안 생성까지는 read-only. Linear 전이·
  worktree·goal worker 는 전부 승인 게이트(Phase 5) 통과 후.
- **harness-class 티켓을 goal 로 강행** — 어려운 티켓을 goal 로 보내면 false-done
  PR 이 되어 사람이 미묘한 오류를 떠안는다. 판정해서 추천만 하고 멈춘다(Phase 2).

## 워크플로 — 6 페이즈, 순서대로

진입 시 이 6페이즈를 `TodoWrite` 로 시드해 단계 스킵을 막는다(Phase 6 은 **동기
spawn** 과 **비동기 PR critic** 두 항목으로 — 후자는 worker 완료 notification 뒤
후속 턴에 처리). 각 페이즈는 다음으로 넘어가기 전에 산출물을
확인한다. Phase 1~4 는 read-only + 파일 생성뿐 — mutation 은 Phase 5 승인 뒤
Phase 6 에서만.

**작성자/critic 다이어드**: 작성(Phase 3 프롬프트)·시안(Phase 4)·구현(Phase 6)은
초안을 만든 뒤 **독립 비판 리뷰어**가 적대적으로 공격하고 결함을 반영하는 루프로
돈다 — `references/adversarial-review.md` SSOT. critic 은 항상 별도 `Agent`
서브에이전트(독립 컨텍스트)다.

> **초안 전 실측(ground-first)**: 작성자는 초안을 쓰기 전에 건드릴 대상의 구체 사실 —
> 정확한 파일 경로, 스타일/로직이 *실제로* 어디 사는지, 데이터 타입·필드 — 를
> `grep`/`Read` 로 못박는다(이름·기억 추측 금지, 글로벌 진단 룰). critic 의 일은
> *의미* 공격이지 `index.css` vs `artwork.css` 같은 기본 위치 오류 줍기가 아니다 —
> 작성자가 실측을 빼먹으면 critic 라운드가 그걸로 소진된다.

### Phase 1 — Intake (티켓 확보)

입력이 둘 중 하나다:

- **티켓 ID** (예 `ADT-211`) → Linear MCP(`mcp__linear*__get_issue` 등)로 fetch.
  **반드시 읽는 필드**: 제목, 설명, Acceptance Criteria/체크리스트, 라벨
  (`area:*`·`agent:goal/harness`·`ext:*`), estimate, 첨부 이미지/스크린샷, 코멘트,
  이슈 관계(blocks/blockedBy/relates), `project.id`·`team.key`.
- **붙여넣은 텍스트** → fetch 없이 그 내용을 입력으로. (ID 가 없으니 라벨/estimate/
  project 기반 라우팅은 사용자에게 확인.)

첨부 이미지가 있으면 시안(Phase 4)의 시각 레퍼런스로 인용할 수 있게 기록해 둔다.

### Phase 2 — Route & gate (repo 확정 + goal/harness 판정)

`references/routing.md` 를 읽고 그대로 적용한다 (dispatch 라우팅 SSOT).

1. **repo 확정** — `team.key`(우선) 또는 `project.id`(projectExceptions) 로
   `~/.claude/linear-repo-map.json` 조회. `repo: null` 이거나 uncertain 이면
   **진행 거부** 또는 사용자 확인 후에만 계속.
2. **goal/harness 판정** — routing.md 의 rubric 을 위에서 아래로 평가.
   **harness-class**(라벨 `agent:harness` · estimate≥5 · `area:*` 2개 이상 ·
   "마이그/전면/research/spike" 류 · AC 없고 본문 빈약)면 **여기서 멈추고**
   "이 티켓은 goal 부적합 — `harness-run` 권장 (사유: …)" 을 출력한다. goal 강행
   금지.
3. goal 적합이면 라우팅 결과(repo / worker=goal / 사유)를 한 줄로 보고하고 Phase 3.

### Phase 3 — 메타프롬프팅 (티켓 → Goal Prompt)

`references/goal-prompt-template.md` 를 읽고 그 고정 템플릿(7섹션)으로 Goal Prompt
`.md` 를 작성한다. Linear 특화 매핑:

- **티켓 AC/체크리스트 → `## Success Criteria`** 로 1:1 직접 매핑. 각 항목은
  관찰 가능해야 한다(template 의 "검증 가능성 게이트" 5질문 통과). 이게 자율 루프의
  종료 조건이다.
- **설명·코멘트·이슈 관계 → `## Context`**. brownfield 면 ground-first(위) — 건드릴
  파일의 **실제 경로·관련 타입/필드를 Read/Grep 으로 확인한 사실만** Context 에 적는다
  (전체 스캔 금지, 추측 금지). "대상 파일은 X" 라고 쓰기 전에 그 X 를 열어 봤어야 한다.
- **`## Done & Report`** 에 실행기 신호 토큰(`result:`/`needs input:`/`failed:`)을
  글자 그대로 박는다 — 백그라운드 분류기는 메시지 텍스트만 읽는다.
- **`## Constraints`** 에 안전 기본값: 지목 영역만 수정, 비가역·외부발신(머지/push/
  배포/삭제) 금지 — 변경만 두고 보고.

작성한 Goal Prompt 초안은 `references/adversarial-review.md` 의 다이어드로 검증한다:
**독립 critic 서브에이전트**가 Phase 3 rubric(5질문 게이트·AC 1:1 커버·토큰·모호
동사 0)으로 공격 → 결함 반영 → 재검(blocking 0 또는 2라운드 cap). Goal Prompt 는
자율 worker 의 유일 계약이라 여기가 최고 레버리지 — 빈 칭찬 통과 금지.

### Phase 4 — 시안 생성 (모든 티켓이 시각 산출물을 가짐)

`references/mockup-conventions.md` 를 읽고 적용한다. **결과물 종류로 분기**:

- **UI 결과물**(페이지·컴포넌트·대시보드·패널·모달·레이아웃) → self-contained
  HTML **mockup**. 핵심 요소·레이아웃·상태(빈/로딩/에러/채워짐). brownfield 면
  ground-first — **실제 스타일 파일을 찾아**(예: 토큰이 `index.css` 인지 컴포넌트
  로컬 css 인지 grep 으로 확정) 색·폰트·구조의 *실값*을 Read 해 맞춘다. 추측한 색/
  레이아웃은 거짓 시각 계약 — 승인자가 안 만들어질 화면을 승인하게 된다.
- **비-UI 결과물**(백엔드·데이터·인프라) → 구현될 로직의 **약식 시각화**: 약식
  API 계약, DB 스키마 약도, 인프라/플로우 구조도 중 티켓에 맞는 것. **표상 수준**
  (실제 introspect 아님 — 티켓이 만들 구조의 약도). 정밀 ERD 가 꼭 필요하면 `erd`
  스킬 위임을 제안.

시안 초안도 다이어드로 검증한다: **독립 critic 서브에이전트**가 Phase 4 rubric(상태
커버·DESIGN 토큰 충실·시안 요소↔Success Criteria 대조 묶임·비-UI 약도 정확성)으로
공격 → 결함 반영 → 재검(2라운드 cap). `references/adversarial-review.md`.

### Phase 5 — 승인 게이트 (단일 HTML 검토 → 승인 또는 피드백 루프)

시안과 Goal Prompt 전문을 **하나의 self-contained HTML** 로 합쳐 사용자에게
제시한다(`<slug>-review.html`). 상단에 시안(또는 로직 약도), 하단에 Goal Prompt
전체를 가독성 있게 렌더. 외부 asset 0, 더블클릭으로 열림.

제시는 **`SendUserFile`** 로 review HTML 을 surface 한다 — `open <path>` 텍스트
안내보다 산출물을 직접 띄우는 게 승인 게이트의 "볼 것"에 맞는다. visualize
MCP(`mcp__visualize__show_widget`)가 가용하면 mockup 을 챗 **인라인 프리뷰**로
추가 렌더해 즉시성을 높인다(미가용 환경이면 SendUserFile 만으로 충분 — graceful).
**HTML 파일은 항상 유지** — worker 가 Goal Prompt Context 의 "UI 시각 타겟"으로 이
파일을 참조하므로 widget 이 파일을 대체하지 않는다. 그 뒤 응답을 기다린다:

- **승인** → Phase 6.
- **거부 + 피드백 1줄** → 그 피드백을 반영해 **Goal Prompt 와 시안을 둘 다 재생성**
  하고 HTML 을 다시 제시한다(승인까지 루프). 한쪽만 고치지 않는다 — 둘은 한 계약이다.

mutation 은 아직 없다. 사용자가 승인을 명시하기 전에는 Phase 6 으로 가지 않는다.

### Phase 6 — 실행 핸드오프 (승인 뒤에만 — mutation 구간)

goal worker 는 **백그라운드 잡**이라 PR 은 이 턴이 끝난 뒤에 열린다. 그래서 Phase 6
은 **동기 블록(이 턴에 spawn 까지)** 과 **비동기 블록(worker 완료 notification 시)**
으로 갈린다 — 둘을 한 턴에 동기로 적던 옛 기술은 백그라운드 잡 동작과 어긋난다.

**동기 (승인 → spawn, 순서대로·각 단계 성공 확인 후 다음):**

1. **Linear → In Progress** (티켓 ID 있을 때만; 텍스트 입력이면 생략).
2. **worktree 분기** — `EnterWorktree` 또는 `git worktree add -b
   feat/<issue-id>-<topic> <dir>`. branch-worktree-strategy §5: 메인은 develop
   유지, 새 브랜치는 worktree 격리.
3. **worktree 검증 — hard gate** — `git -C <dir> rev-parse --abbrev-ref HEAD` ==
   기대 브랜치인지 확인. **검증 실패면 goal worker 를 절대 띄우지 않고** 중단·
   보고한다(REQ-N-002).
4. **goal worker spawn** — worktree 안에서 Phase 3 Goal Prompt 를 task 로 하는
   백그라운드 잡: **`Agent` 의 `run_in_background: true`** (1순위 CC 빌트인). 장기·
   자가검증 루프이므로 `deep-worker`(가용하면 그 agentType, 아니면 general-purpose)
   로 라우팅한다(subagent-invocation R6). worker 는 자율로 돌아 **PR 까지만** 연다
   (머지 금지 — Goal Prompt Constraints).
   - spawn 직전: Goal Prompt `.md` 와 `<slug>-review.html` 을 worktree 안으로
     복사한다(또는 Goal Prompt Context 가 절대경로로 가리키게). worker 는 worktree
     cwd 에서 도므로 "UI 시각 타겟" 파일이 그 안에 실제로 있어야 연다.
   - 여기서 동기 블록 종료. `result:` 한 줄(라우팅 repo + worktree + goal worker
     잡 핸들 + Linear 상태)로 보고한다. `run_in_background` 잡은 **완료 시 하니스가
     자동으로 알린다**(동기 폴링 금지) — 그 notification 이 도착한 **후속 턴**에서
     비동기 블록을 돈다.

**비동기 (worker 완료 notification 도착 시 — 후속 턴):**

5. **구현 PR critic** — worker 가 PR 을 열면, `references/adversarial-review.md` 의
   Phase 6 rubric 으로 **독립 리뷰어**(독립 컨텍스트 — 별도 서브에이전트 또는 빌트인
   `/code-review`)가 diff 를 Goal Prompt 의 Success Criteria·Constraints 대조로
   공격한다(SC 미충족·범위 넘침·Constraints 위반·정확성 결함). 서브에이전트로 돌리면
   worktree 경로를 주어 diff 를 읽게 한다. findings 는 자동 머지/수정에 쓰지 않고
   사람에게 보고만 한다.
6. **Linear → In Review** + PR 링크 attach + critic findings 코멘트. **Done 전이·
   머지는 하지 않는다**(머지=land/사람).

각 보고는 `~/.claude/skills/craft-core/references/output-contract.md` 의 종료 블록을
따른다: `result:` 한 줄 + 산출물(Goal Prompt `.md` · review HTML, 비동기 턴이면
PR 링크 · critic findings) 열기 행.

## Anti-patterns

- **승인 전 mutation** — fetch·시안까지는 read-only. Linear 전이·worktree·goal
  worker 를 승인 전에 하면 시각 게이트가 무의미해진다.
- **worktree 검증 생략하고 goal worker spawn** — 분기가 실패했는데 worker 가 뜨면
  엉뚱한 트리/develop 위에서 자율 작업한다. 검증은 hard precondition.
- **harness-class 를 goal 강행** — false-done PR. 판정해서 추천하고 멈춰라.
- **머지/Done 자동화** — human merge-gate 붕괴. In Review 까지만.
- **검증 불가 Success Criteria** — 티켓 AC 를 "잘 동작" 류로 옮기면 자율 루프가
  못 끝난다. template 의 "검증 가능성 게이트" 5질문을 통과시켜 관찰 가능하게.
- **비-UI 에 억지 mockup / 시안을 SC 에 안 묶기** — 비-UI 는 로직 약도다(UI mockup
  아님). 그리고 시안의 핵심 요소를 Success Criteria 에 *관찰 가능한* 대조 항목으로
  묶지 않으면 장식일 뿐이다.
- **티켓 필드 누락** — AC·라벨·estimate·첨부를 안 읽고 제목만으로 프롬프트 쓰기.
  그게 "Linear 최적화"의 알맹이다 — 전부 읽어 녹여라.
- **실측 없이 초안(경로·토큰 추측)** — "대상은 `index.css`" 처럼 안 열어 보고 단언하면
  critic 라운드가 기본 위치 오류로 소진된다. ground-first: 경로·타입·토큰을 grep/Read
  로 못박은 뒤 작성.
- **critic 을 같은 컨텍스트 자기검토로** — 다이어드는 critic 이 **독립 컨텍스트**
  (Phase 3·4 별도 `Agent`, Phase 6 별도 서브에이전트 또는 `/code-review`)라야 산다.
  같은 턴 자기검토는 anchoring 그대로라 무의미.
- **백그라운드 spawn 인데 PR/In Review 를 동기로 적기** — worker 완료 전엔 PR 이
  없다. Phase 6 의 비동기 블록(5·6)은 완료 notification 때 돈다.

## References

- `references/goal-prompt-template.md` — Goal Prompt 7섹션 고정 템플릿 + 검증
  가능성 5질문 게이트 + 작동 예시. Phase 3 에서 읽는다.
- `references/mockup-conventions.md` — UI mockup / 비-UI 로직·구조 약도 HTML 규칙
  + 단일 review HTML 합치기. Phase 4~5 에서 읽는다.
- `references/routing.md` — linear-repo-map 조회(repo 확정) + goal/harness rubric.
  dispatch 라우팅 SSOT (linear-dispatch 룰은 조회-스코프 전용 별개 관심사). Phase 2 에서 읽는다.
- `references/adversarial-review.md` — 작성자/critic 다이어드 프로토콜 + 페이즈별
  공격 rubric. Phase 3·4·6 에서 읽는다.
