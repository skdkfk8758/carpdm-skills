---
name: linear-goal
description: >-
  Linear 이슈 1건을 가볍게 자율 실행하는 오케스트레이터 — fetch → `## 추천` 라우팅 + harness 안전판정 → 이슈의 `## 작업 내용`/`## 수용 기준`을 Goal Prompt 로 매핑 → 확인 게이트 → worktree 분기·검증 → goal worker 백그라운드 잡 → PR(In Review 까지만). "ADT-211 goal 로 돌려줘", "이 티켓 해줘", "이슈대로 구현해줘" 처럼 'linear-goal' 이란 말이 없어도 트리거. 세션에 `Linked Linear issue: <ID>` 배너가 있으면 "이거 진행해줘"/"작업 시작해" 만으로 그 이슈 대상. harness-class(estimate≥5·cross-cutting·전면개편)면 harness-run 추천하고 멈춤. 일반 Goal Prompt 는 deep-prompt, 직접 빌드/버그수정은 forge/hunt, 이슈 등록은 linear-register, PR 머지는 land.
---

# linear-goal — Linear 티켓을 경량 게이트로 묶어 자율 goal 실행

사용자가 Linear 티켓 하나를 던진다. 그걸 그대로 goal 칸에 넣으면 자율 에이전트는
*언제 끝났는지 모른 채* 표류하고, 사람은 무엇이 만들어질지 모른 채 결과를 떠안는다.
이 스킬은 그 사이에 **가벼운 확인 게이트 + 안전 검증**을 넣는다: 이슈를 검증 가능한
Goal Prompt 로 조립하고, repo·worktree·종료조건을 사람이 한 번 확인하면 — 그때서야 —
worktree 분기를 검증하고 goal worker 를 자율 실행한다.

핵심은 **재작성이 아니라 재사용**이다. `linear-register` 가 만든 이슈는 이미
`## 작업 내용`·`## 수용 기준`·`## 추천`(어느 스킬로 갈지)·체인이면 `## 다음 작업`을
갖는다 — 이 구조를 **그대로 Goal Prompt 로 매핑**한다. 무거운 메타프롬프트·시안·적대
critic 은 없다. 그 무게가 필요한 디자인-리스크 큰 작업은 애초에 harness-class 로
판정돼 `harness-run` 으로 빠진다(Phase 2).

> 자매 관계: 티켓 신규 등록 = `linear-register`(거기 `## 추천` 이 이 스킬을 가리킨다) ·
> 티켓 없는 일반 goal = `deep-prompt` · 어려운 티켓 = `harness-run` · PR 머지 = `land`.

## 안전 불변식 — 먼저 읽을 것

비가역·외부발신 행위(Linear 상태 전이, worktree 생성, 백그라운드 잡 spawn)는
**사용자 확인 뒤에만**. 절대 자동으로 하지 않는 것:

- **머지 / develop·main 직접 push / 배포** — human merge-gate (ADR-041). 이 스킬은
  **In Review 까지만**. 머지·Linear "Done" 은 `land`/사람 몫.
- **확인 전 어떤 mutation 도** — fetch·Goal Prompt 조립까지는 read-only. Linear 전이·
  worktree·worker spawn 은 전부 Phase 4 확인 게이트 통과 후.
- **harness-class 티켓을 goal 로 강행** — false-done PR 이 되어 사람이 미묘한 오류를
  떠안는다. 판정해서 추천만 하고 멈춘다(Phase 2). 추천 섹션이 빌드 스킬을 가리켜도
  안전 판정이 상위 — `## 추천` 은 모델 판단이고 harness 게이트는 hard rule 이다.
- **worktree 검증 실패 시 worker spawn** — 엉뚱한 트리/develop 위 자율작업 방지. hard gate.
- **수용 기준 미충족 상태로 PR/종료** — `## 수용 기준`(=Success Criteria)이 100% 검증되지
  않았는데 PR 을 열거나 작업을 완료(In Review)로 올리지 않는다. **PR 직전 이슈 수용 기준을
  재확인**해 하나라도 미체크·미충족이면 PR 을 **중지하고 사용자에게 안내**한다
  (`~/.claude/rules/acceptance-criteria-gate.md` G2). 검증이 종료를 선행한다 — hard gate.

## 워크플로 — 4 페이즈, 순서대로

진입 시 네이티브 Task 도구(`TaskCreate`)로 4페이즈 체크리스트를 시드한다(Phase 4 는
**동기 spawn** + **비동기 In Review** 두 항목). 각 페이즈 진입 시 `TaskUpdate`
`in_progress`, 완료 시 `completed` — 경계마다 빠짐없이(대화턴 진행 표시). worker
백그라운드 구간은 "비동기 In Review" 항목 하나를 in_progress 로 유지하고 완료
notification 턴에서 닫는다(그동안 Task 세분 금지 — 메인 루프가 갱신 못 한다).
Phase 1~3 은 read-only + 파일 생성뿐 — mutation 은 Phase 4 확인 뒤에만.

### Phase 1 — Intake (티켓 확보)

- **티켓 ID**(예 `AUT-25`) → Linear MCP(`mcp__linear__get_issue`, `includeRelations:true`)로
  fetch. 읽는 필드: 제목·설명·라벨(`area:*`·`agent:*`)·estimate·첨부·관계(blocks/blockedBy/parent)·
  `team.key`·`project.id`.
- **붙여넣은 텍스트** → fetch 없이 그대로 입력(ID 없으니 repo 는 Phase 2 에서 사용자 확인).
- 이슈가 `## 작업 내용`/`## 수용 기준`/`## 추천`/`## 다음 작업` 구조를 가지면(=
  linear-register 산출물) 그게 경량화의 핵심 입력 — Phase 3 에서 직접 매핑한다.
- **세션 이름 설정 (fetch 직후 즉시 — 백그라운드 잡일 때).** 티켓 ID·제목을 확보한 지금
  바로 이 세션 이름을 `[<issue-id>] <작업요약>`(예 `[ADT-272] persona POI z-order`)으로
  rename 한다. `~/.claude/skills/craft-core/references/session-rename.md`(공유 SSOT)의
  atomic snippet 그대로(`state.json` `name` + `nameSource:"user"`). **Phase 4(spawn)까지 미루지 않는 이유**: 세션이 확인 게이트에서
  멈추거나 조회로 흘러도 잡 리스트에 티켓이 박혀 있어야 한다. 비mutation(로컬 메타데이터)
  이라 확인 게이트 전에 실행해도 안전. 잡 컨텍스트 아니거나(`$CLAUDE_JOB_DIR` 없음) 붙여넣은
  텍스트라 ID 가 없으면 생략. 실패해도 hard gate 아님 — note 만 남기고 계속.

### Phase 2 — Route & gate (repo 확정 + goal/harness 판정)

`references/routing.md` 를 읽고 그대로 적용한다 (dispatch 라우팅 SSOT).

1. **repo 확정** — `team.key`(또는 projectExceptions 의 `project.id`)로
   `~/.claude/linear-repo-map.json` 조회. `repo:null`·uncertain·외부/운영-요청이면
   거부 또는 사용자 확인.
2. **goal/harness/spec-thin 판정** — routing.md rubric 을 위에서 아래로. **harness-class**면
   **여기서 멈추고** "이 티켓은 goal 부적합 — `harness-run` 권장 (사유: …)" 출력.
   **spec-thin**(AC 없음 + 본문 빈약)이면 역시 멈추고 `linear-groom` 보강 또는
   `deep-plan` 을 권장한다(보강 후 재판정이 정경로). goal 강행 금지.
3. 이슈에 `## 추천` 이 있으면 그 라우팅을 **참고 신호**로 본다(예: 추천이 `/hunt` →
   worker 가 버그수정 모드). 단 위 harness 판정이 상위 — 추천이 빌드를 가리켜도
   estimate≥5/cross-cutting 이면 harness 로 멈춘다.

### Phase 3 — Goal Prompt 조립 (메타프롬프트 아님 — 이슈 구조 재사용)

`references/goal-prompt-template.md` 의 7섹션 스켈레톤에 이슈 필드를 **직접 매핑**한다:

- **작업 본문**(`## 작업 내용`(+있으면 `## 배경`) = register·groom 공통 코어 헤딩)
  → `## Objective` + `## Context`. 레거시 groom 이슈의 `## 작업 범위` 도 같은 의미로 받는다(하위호환).
- **수용 기준**(`## 수용 기준` = register·groom 공통; 체크박스. 레거시 `## Acceptance` 도 받음)
  → `## Success Criteria` 로 1:1. 자율 루프의 종료 조건이다. `[AUTO]`/`[HUMAN]` 마커가
  있으면 보존. 관찰 가능하면 그대로 옮기고, "잘 동작" 류로 모호한 **그 항목만** 관찰
  가능하게 보정(template 의 검증 가능성 5질문). 전체 재작성·적대 critic 은 하지 않는다 — 이미 구조화됐다.
  Goal Prompt 에 **PR 전 게이트**를 표준으로 박는다: worker 는 각 Success Criteria 를 관찰
  가능하게 검증(테스트/런타임)한 **뒤에만** PR 을 연다. **PR 직전 이슈 수용 기준을 재확인해
  100% 충족이 아니면 PR 을 열지 말고 `needs input:` 으로 어느 항목이 왜 미충족인지 보고하고
  멈춘다**(검증이 종료를 선행 — `~/.claude/rules/acceptance-criteria-gate.md`).
- 체인 `## 다음 작업` 의 kickoff 프롬프트가 있으면 Objective 시드로 활용.
- **표준 Constraints** 박기: 지목 영역만 수정, 머지/push/배포/삭제 금지 — 변경만 두고 보고.
- **`## Done & Report`** — 검증 결과를 메시지 텍스트로 재진술 + 상태 신호 한 줄
  (`result:`/`needs input:`/`failed:` — 리터럴 파싱 계약이 아니라 오독 방지 컨벤션;
  현행 완료 판정은 평가 모델의 시맨틱 판독). 의미론 SSOT 는 template 참조.
- brownfield 면 ground-first: Context 에 적을 파일 경로·타입은 `grep`/`Read` 로 확인한 것만
  (이름·기억 추측 금지, 글로벌 진단 룰). 추측 경로는 worker 를 헛돌게 한다.

### Phase 4 — 경량 확인 게이트 + 실행 핸드오프 (확인 뒤에만 — mutation 구간)

**확인 게이트(HTML/시안 없음):** 다음을 한 블록으로 제시하고 대기한다. **단일 승인 게이트는 `AskUserQuestion`**(승인 / 거부+피드백 선택지)으로 구조화해 응답 파싱을 견고하게 한다:

> 진행 예정: **repo** `<repo>` / **worktree** `feat/<issue-id>-<topic>` /
> **Goal Prompt** Objective 1줄 + Success Criteria N개 + worker=`deep-worker`. 진행?

- **거부 + 피드백** → Goal Prompt 를 그 피드백만 반영해 갱신하고 다시 제시(루프).
- **승인** → 아래 동기 블록.

**동기 (승인 → spawn, 순서대로·각 단계 성공 확인 후 다음):**

1. **세션 이름 — Phase 1 에서 이미 설정됨.** fetch 직후 rename 했으므로 여기선 재실행하지
   않는다(이름이 비어 있거나 placeholder 면 그때만 craft-core `session-rename.md` 로 보정).
2. **Linear → In Progress** (티켓 ID 있을 때만).
3. **worktree 분기** — `EnterWorktree` 또는 `git worktree add -b feat/<issue-id>-<topic> <dir>`
   (branch-worktree-strategy §5: 메인은 develop 유지, 새 브랜치는 worktree 격리).
4. **worktree 검증 — hard gate** — `git -C <dir> rev-parse --abbrev-ref HEAD` == 기대 브랜치.
   **실패면 worker 를 절대 띄우지 않고** 중단·보고.
5. **goal worker spawn** — worktree 안에서 Phase 3 Goal Prompt 를 task 로 하는 백그라운드 잡:
   `Agent` 의 `run_in_background:true`, agentType `deep-worker`(가용) 또는 general-purpose
   (subagent-invocation R6). worker 는 자율로 돌아 **PR 까지만** 연다(머지 금지) — 단
   **PR 직전 이슈 수용 기준을 재확인해 100% 검증·충족일 때만** PR 을 열고, 미충족이면 PR 을
   중지하고 `needs input:` 으로 미충족 항목을 보고한다(Phase 3 Goal Prompt 에 박힌 게이트). spawn 직전
   Goal Prompt `.md` 를 worktree 안으로 복사한다.
   - **STATUS_LOG 기본 주입 (progress.md P3)** — worker 프롬프트 헤더에
     `STATUS_LOG=<worktree>/logs/agents/goal-<issue-id>-<ts>.status.log` 를 넣는다
     (subagent-invocation R8 을 opt-in 아닌 기본으로). append 규율은 R8 그대로 —
     ≤20 스텝 줄 + 종료 `[DONE]`/`[FAIL]` 마커 1회. 상세는
     `~/.claude/skills/craft-core/references/progress.md` §P3(복제 금지).
6. **동기 종료** — `result:` 한 줄(repo + worktree + worker 잡 핸들 + Linear 상태) +
   **관전 명령 1줄**(`tail -f <status.log 경로>` — progress.md P3). 백그라운드
   잡은 완료 시 하니스가 자동 알린다(동기 폴링 금지). 사용자가 도중에 진행을 물으면
   status log 꼬리(최근 ~5줄)를 읽어와 요약한다 — 완료 판정은 아님(R9: idle ≠ 완료,
   `[DONE]` + git diff·verify 재실행으로만 판정).

**비동기 (worker 완료 notification 도착 시 — 후속 턴):**

7. **결과 보드 + PR 게이트 분기.** 먼저 **결과 보드**(output-contract §R — 복제 금지)를
   emit 한다. linear-goal 정체성 행: `worker`([DONE]/[FAIL] 자가보고 · status log 스텝 수 ·
   자가보고 테스트 수) · `메인 재검증`(git diff 파일 일치 · verify 명령 재실행 실측 —
   R9: 자가보고만으론 완료 불인정). 공통 행: Acceptance(N/N + 검증 근거) · 납품(PR ·
   Linear 상태) · 잔여(머지=사람 · critic 없음) · 체인(다음 이슈). 그 다음 분기:
   - worker 가 PR 을 열었으면(수용 기준 100% 검증 통과) → **Linear → In Review** + PR 링크
     attach + 충족된 수용 기준 체크박스 `[x]` 갱신 + **결과 보드를 이슈 코멘트로**
     (`linear.md` §3b — 검증 근거 코멘트를 보드가 흡수, 별도 산문 재작성 금지·마스킹).
     **Done 전이·머지는 하지 않는다**(머지=land/사람).
   - worker 가 수용 기준 미충족으로 PR 을 중지(`needs input:`)했으면 → **In Review 로 올리지
     말고** 미충족 보드(어느 항목이 왜)를 사용자에게 안내 + 같은 실패 보드를 이슈 코멘트로
     남기고 멈춘다(acceptance-criteria-gate G2 · §3b 실패 기록).
8. 이슈에 체인 `## 다음 작업` 이 있었으면, **다음 이슈 id + kickoff 프롬프트를 사용자에게 제시**
   ("다음: <next-id> — `linear-goal <next-id>` 로 이어가기"). 자동 시작은 안 함.

> PR diff 적대 리뷰가 필요하면 빌트인 `/code-review` 를 **수동**으로 돌리길 권한다 —
> 경량 흐름이라 자동 critic 은 기본 드롭(필요 시 opt-in).

각 보고는 `~/.claude/skills/craft-core/references/output-contract.md` 의 종료 블록을 따른다:
`result:` 한 줄 + 산출물(Goal Prompt `.md`, 비동기 턴이면 PR 링크) 열기 행.

## Anti-patterns

- **확인 전 mutation** — fetch·조립까지 read-only. Linear 전이·worktree·worker 를 확인 전에 하면 게이트가 무의미.
- **worktree 검증 생략하고 spawn** — 분기 실패 시 엉뚱한 트리에서 자율작업. hard precondition.
- **harness-class 를 goal 강행** — false-done PR. 판정해서 추천하고 멈춰라(`## 추천` 이 빌드를 가리켜도 안전 게이트가 상위).
- **머지/Done 자동화** — human merge-gate 붕괴. In Review 까지만.
- **이슈 구조 무시하고 메타프롬프트 재작성** — linear-register 이슈는 이미 `## 작업 내용`/`## 수용 기준`이 있다. 재사용이 이 리뉴얼의 핵심 — 다시 쓰지 말고 매핑하라.
- **검증 불가 Success Criteria** — `## 수용 기준`을 그대로 옮기되 "잘 동작" 류 모호 항목만 관찰 가능하게 보정.
- **실측 없이 Context 경로 추측** — ground-first: 경로·타입을 grep/Read 로 못박은 뒤 적어라.
- **백그라운드 spawn 인데 PR/In Review 를 동기로 적기** — worker 완료 전엔 PR 이 없다. 7·8 은 완료 notification 때.
- **수용 기준 검증 없이 PR/In Review** — `## 수용 기준` 체크가 100% 아닌데 PR 을 열거나 In Review
  로 올리지 마라. PR 직전 재확인해 미충족이면 중지·안내(`acceptance-criteria-gate.md` G2). SUR-26
  은 미체크인 채 Done 돼 #3 미충족(개요 탭 누락)이 거짓 완료로 위장된 실측 사례.
- **검증 없이 체크박스만 `[x]`** — 거짓 완료. 관찰 가능한 검증(테스트/런타임) 통과 후에만 체크.

## References

- `references/routing.md` — linear-repo-map 조회(repo 확정) + goal/harness rubric. Phase 2 에서 읽는다.
- `references/goal-prompt-template.md` — Goal Prompt 7섹션 고정 템플릿 + 검증 가능성 5질문 게이트. Phase 3 에서 **스켈레톤**으로 읽는다(이슈 필드를 채워 넣는 용도 — 재작성 아님).
- `~/.claude/skills/craft-core/references/session-rename.md` — 세션 rename 공유 SSOT(포맷 표에 linear-goal 행). **Phase 1(fetch 직후)에서 읽고 즉시 적용**한다.
