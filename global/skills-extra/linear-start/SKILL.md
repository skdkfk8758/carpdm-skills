---
name: linear-start
description: >-
  Linear 이슈를 1건 또는 N건 실제로 착수시켜 PR 까지 끌고 간다 — 결정 갈래·부족한 컨텍스트를 전부 선인터뷰로 확정하고, 이슈당 worktree 를 하나씩 파고(브랜치는 type/issue-id-topic 규약, 최신 trunk 기준), 착수 push + Linear In Progress 전이 후, worktree 마다 Agent worker 를 병렬 spawn 해 구현→테스트→커밋→push→PR 을 돌리고, 메인이 worker 자가보고를 재검증한다. **발동 신호는 이슈 키(ADT-441·REV-14·SMF-8·adt-499 같은 ABC-123 꼴) + 착수 의도** 조합이다 — "착수", "작업 시작", "티켓 잡고 구현 들어가자", "브랜치 파서 구현까지", "오늘 다 끝내야 됨", "세 개 동시에", "병렬로 돌려줘", "각자 트리에서", "인프로그레스로 바꾸고 시작", "start these issues", "work on AUT-31 and AUT-33 in parallel worktrees", "branch and implement it". 'linear'·'worktree'·'병렬' 이란 단어가 없어도, 이슈 키와 만들겠다는 의도만 있으면 적극 트리거한다. 반대로 이슈를 **읽기만** 하거나(내용·수용 기준 조회), 계획만 원하거나(linear-replan), 무엇부터 할지 고르는 것이거나(linear-prioritize), 이미 올라간 PR 머지·로컬 동기화이거나(land), 신규 이슈 등록(linear-register)·백로그 그루밍(linear-groom)·워크트리 청소(wt-sweep)이거나, 원인만 찾는 진단이거나, 이슈 없이 그냥 코드를 짜 달라는 요청이면 트리거하지 않는다.
---

# linear-start — 이슈 N건을 워크트리로 갈라 병렬 착수

이슈를 자율 실행에 넘길 때 실제로 터지는 실패는 코딩 실력이 아니라 **미확정 갈래**다.
worker 는 사람에게 물을 수 없으므로, 이슈 본문에 남은 "그래서 어느 쪽으로?"가 그대로
worker 의 추측이 되고, 병렬 N개면 N개의 서로 다른 추측이 된다.

그래서 이 스킬의 순서는 고정이다: **전부 묻고 → 전부 확정하고 → 그 다음에야 갈라 띄운다.**
worktree 격리와 병렬성은 그 뒤에 오는 기계적 단계일 뿐이다.

> 자매 관계: 계획만 = `linear-replan` · 우선순위 선정 = `linear-prioritize` ·
> 머지·정리 = `land` · 워크트리 청소 = `wt-sweep` · 이슈 등록 = `linear-register`.

## 안전 불변식 — 먼저 읽을 것

- **미확정 갈래가 1개라도 남으면 spawn 하지 않는다.** 전항목 확정이거나, 사용자가 명시로
  위임해 **봉인**된 상태(승인 표에 봉인 항목 명시)여야 한다. 조용한 봉인 금지.
- **메인 워크트리에서는 코드를 건드리지 않는다.** 메인 체크아웃은 trunk 로 남고, 모든
  편집은 linked worktree 안에서만 일어난다.
- **비가역은 게이트 뒤에만.** worktree 생성·push·Linear 전이·PR 생성·이슈 코멘트는 Step 5
  승인 표를 통과한 뒤에만 실행한다.
- **머지는 이 스킬의 일이 아니다.** worker 는 PR 생성에서 멈춘다. 머지는 `land`.
- **worker 자가보고를 완료로 인정하지 않는다.** [DONE] 이라고 적혀 있어도 메인이 git
  diff·테스트를 직접 재실행해 확인한 것만 완료다(Step 7).

## Step 0 — 입력 판정 + 프리플라이트

**① 이슈 확보.** 이슈 ID(`ADT-435`)·URL·세션 배너에서 대상을 모은다. 대상이 불명확하고
사용자가 "다음 거 몇 개"류로 말했으면 이 스킬로 고르지 말고 **`linear-prioritize` 로
라우팅하고 멈춘다** — 무엇을 할지 고르는 것은 그쪽 일이다.

**② Linear MCP.** 감지·미설치 처리는 `~/.claude/references/craft/linear.md` §1 그대로
(복제 금지). 팀 스코프는 현재 repo → team 역매핑(같은 파일 §1).

**③ repo 상태.** 메인 repo 루트(`git rev-parse --show-toplevel`)와 trunk 를 확인한다.
`git fetch origin <trunk>` 를 먼저 돌린다 — **stale 로컬 trunk 위에 워크트리를 파면 N개
브랜치가 전부 과거에서 출발한다.**

**④ 동시성 상한.** 이슈 5건을 넘으면 그대로 진행하지 말고 몇 건까지 이번에 돌릴지 묻는다.
worktree N개는 디스크·install·포트를 N배로 쓴다.

## Step 1 — 이슈별 갭 스캔 (spawn 전, 메인이 직접)

이슈마다 본문·AC·라벨·관계를 읽고, **레포에서 건드릴 반경만** Read/Grep 으로 실측한다
(레포 전수 스캔 아님). 여기서 뽑는 것은 두 가지뿐이다:

| 뽑는 것 | 정의 | 처리 |
|---|---|---|
| **결정 갈래** | 사람이 골라야 실행이 갈리는 것 (스키마 형태, 라이브러리, UX 분기, 범위 경계) | Step 2 인터뷰 의제 |
| **부족 컨텍스트** | 사실 확인이면 되는 것 (파일 위치, 기존 패턴, 계약) | 인터뷰 아님 — **메인이 레포에서 직접 확인**해 채운다 |

검증 항목·테스트 목록·"확인했나요" 류는 갈래가 아니다. 그건 worker 의 verify 로 내려간다.

**oversized 판정.** estimate ≥ 5 · cross-cutting 전면 개편 · 마이그레이션/대량 삭제 등
비가역 신호가 있는 이슈는 **이 스킬로 자율 실행하지 않는다.** 해당 이슈만 목록에서 빼고
`linear-replan`(착수 계획) 또는 `deep-plan`(설계) 으로 라우팅한다고 보고한다 — 나머지
이슈는 그대로 진행한다.

## Step 2 — 전 이슈 일괄 선인터뷰 (AskUserQuestion)

Step 1 의 결정 갈래 전부가 의제다. **이슈 경계를 넘어 한 번에 묶는다** — 사용자를 이슈마다
다시 붙잡지 않는 것이 일괄 인터뷰의 이유다.

- 독립 갈래는 `AskUserQuestion` **1콜 최대 4질문**으로 배칭. 질문 헤더에 이슈 ID 를 넣어
  어느 티켓 얘기인지 즉시 보이게 한다.
- 선택지는 **레포 실측 또는 이슈 본문에서 도출된 것만**. 창작한 옵션으로 묻지 않는다.
- 의존 갈래(앞 답에 따라 질문이 달라지는 것)만 직렬로.
- **탈출구 — 봉인.** 사용자가 "나머지는 알아서"를 선언하면 잔여 갈래를 추천값으로 봉인하고
  인터뷰를 끝낸다. 봉인 항목은 Step 5 승인 표와 Linear 코멘트에 **확정이 아님을 명시**해
  적는다.

인터뷰가 끝나면 각 이슈에 대해 **확정 결정 목록**이 하나씩 생긴다. 이것이 worker 프롬프트의
핵심 화물이다.

## Step 3 — 브랜치·워크트리 배치 결정 (아직 만들지 않는다)

**브랜치명** — `<type>/<issue-id 소문자>-<topic>` (예 `feat/adt-435-csv-export`).
issue-id 가 없으면 트래커 자동연동이 안 걸린다(`branch-worktree-strategy.md` §1).
type 은 Linear 라벨에서: bug→`fix` · feature→`feat` · chore/refactor→그대로.

**워크트리 위치** — repo 마다 배치 관례가 다르다. `git worktree list --porcelain` 으로
기존 워크트리 경로를 보고 그 관례를 따른다. 선례가 없으면 `<repo>/.claude/worktrees/<브랜치
slug>`. **경로 패턴을 하드코딩하지 않는다** — 관례가 다른 repo 에서 형제 워크트리를 오염시킨
실측 사고가 있다(`cc-worktree.md`).

## Step 4 — 승인 표 (단일 게이트)

여기까지는 읽기 전용이다. 이 표를 통과해야 비가역 동작이 시작된다.

```
| 이슈 | 브랜치 | 워크트리 | 확정 결정(요약) | 봉인 |
|---|---|---|---|---|
| ADT-435 | feat/adt-435-csv-export | .claude/worktrees/adt-435-csv-export | 스트리밍 응답 · 헤더 한글 | — |
```

표 아래에 함께 제시하고 **한 번에** 승인받는다:

- 이번 실행에서 할 일 — worktree N개 생성 · 착수 push · Linear In Progress 전이 ·
  worker N개 spawn · 완료 시 PR 생성 (머지는 하지 않음)
- 제외한 이슈와 사유 (oversized → 라우팅 대상)
- 이슈에 붙일 **확정 결정 코멘트 본문** (Step 5 에서 첨부)

승인 없이 다음 Step 으로 가지 않는다. 사용자가 일부만 승인하면 그 부분집합으로 진행한다.

## Step 5 — 착수 (워크트리 생성 → push → In Progress → 코멘트)

이슈마다 순서대로:

1. **워크트리 생성** — `git worktree add -b <branch> <dir> origin/<trunk>`.
   base 를 `origin/<trunk>` 로 명시하는 것이 Step 0-③ fetch 와 짝이다.
   worktree 간 `node_modules` 심링크 공유 금지. `.env*` 는 post-checkout 훅이 복사한다
   (`cc-worktree.md` — husky repo 는 install 시점 연결이라 훅이 안 돌 수 있으니, 워커
   프롬프트에 "`.env` 없으면 메인 워크트리에서 복사" 를 넣는다).
2. **착수 push** — `git push -u origin <branch>`. 커밋이 아직 없어도 브랜치는 올라간다.
   **이 원격 이벤트가 없으면 트래커 자동연동은 아무것도 하지 않는다**(§1 실측).
3. **Linear 전이** — 상태를 In Progress 로 **직접** 전이한다. branch→상태 자동화는 기본 off
   인 경우가 많아 토글에 기대지 않는다.
4. **확정 결정 코멘트 첨부** — Step 4 에서 승인받은 본문. credential·PII·내부 URL 이
   섞였으면 첨부를 보류하고 사유를 보고한다(Linear 는 외부 서비스 — 올린 것은 지워도 남는다).
   말미에 AI 산출 disclaimer 1줄. 첨부 실패는 스킬 실패가 아니다 — 경고만 남기고 계속.

## Step 6 — worker 병렬 spawn

이슈당 Agent 서브에이전트 1개를, **한 메시지에 전부** 띄운다(그래야 동시에 돈다).
`subagent_type: general-purpose` · `model: 'fable'` (worker 는 세션 모델과 무관하게 fable 로
고정한다), worktree 는 이미 있으므로 `isolation` 옵션은 쓰지 않는다.

프롬프트 계약 — 이 화물이 부실하면 worker 는 추측한다:

```
작업 디렉토리: <워크트리 절대경로>   ← 여기 밖의 파일을 편집하지 말 것
브랜치: <branch>   (이미 생성·push 됨. 브랜치를 바꾸거나 rebase 하지 말 것)
이슈: <ID> <제목>
<이슈 본문>

확정 결정 — 사용자가 이미 고른 것이다. 다시 판단하지 말고 그대로 구현할 것:
- <갈래> → <확정값> (근거)
- <봉인 항목> → <추천값 채택, 미확정>

레포 grounding (메인이 실측한 것):
- <경로> — <역할/계약>

수행:
1. 구현 — 위 확정 결정대로. 기존 패턴을 따를 것(위 경로부터 읽고 시작).
2. 테스트 — 비자명 로직에는 실행 가능한 확인을 하나 남긴다. 프로젝트 러너로 실행.
3. 커밋 — 한국어 커밋 메시지. 논리 단위로 나눈다.
4. push + PR 생성 — base=<trunk>, 제목에 <ID> 포함. 머지하지 말 것.

금지: 머지 · force-push · 다른 워크트리/메인 체크아웃 편집 · 이슈 본문 수정 ·
      확정 결정 뒤집기 · 사용자에게 질문(대답해 줄 사람이 없다)

막히면: 추측으로 밀지 말고 그 지점에서 멈추고 [BLOCKED] 로 보고할 것.

보고 형식 (마지막 메시지):
[DONE] 또는 [BLOCKED] 또는 [FAIL]
- 변경: N files (+A/−D)
- 커밋: <hash 목록>
- PR: <url>
- 검증 커맨드: <실행한 명령> → <실제 출력 수치>
- 미해결: <있으면. 없으면 "없음">
```

**진행 감시.** worker 는 백그라운드로 돌고 완료 시 알림이 온다. 알림 없이 짐작해서
"끝났을 것"이라고 쓰지 않는다.

## Step 7 — 메인 재검증 (worker 보고는 증거가 아니다)

worker 마다 [DONE] 을 받으면, 메인이 그 워크트리에서 직접 확인한다:

- `git -C <워크트리> log --oneline origin/<trunk>..HEAD` — 커밋이 실제로 있는가
- `git -C <워크트리> diff --stat origin/<trunk>...HEAD` — 보고한 변경 규모와 일치하는가
- worker 가 적은 **검증 커맨드를 메인이 다시 실행** — 같은 결과가 나오는가
- PR URL 이 실제로 열려 있는가 (`gh pr view`)

불일치하면 [DONE] 을 취소하고 그 이슈를 미완으로 보고한다. `|| true`·`| tail` 로 종료 코드를
삼키지 않는다.

Linear 상태는 **PR 이 열린 것까지 확인된 이슈만** In Review 로 전이한다. Done 전이는 머지
후이므로 이 스킬이 하지 않는다(`land` 의 몫).

## 종료 출력

`~/.claude/references/craft/output-contract.md` 를 따른다(복제 금지) — 코드를 바꾼 스킬이므로
**R 결과 보드 → V 검증 체크리스트 → N 다음 단계 → L1 `result:`** 순서.

- **R 보드** — 이슈별 1행: 브랜치 · 변경 규모 · 커밋 · PR · 메인 재검증 결과([DONE] 자가보고와
  재검증이 갈리면 재검증 값이 진실).
- **V 체크리스트** — `[사용자 직접 확인 필요]` 는 생략 불가(없으면 "없음" 명시).
- **N 블록** — 필수에 열린 PR → `/land`, 권장에 랜딩 후 `wt-sweep`.

## Anti-patterns

- **미확정 갈래를 남긴 채 spawn** — N개 worker 가 N개의 다른 추측을 커밋한다. 이 스킬의 존재
  이유가 여기다.
- **인터뷰를 이슈마다 쪼개 사용자를 계속 붙잡기** — 일괄 배칭이 기본이다.
- **로컬 trunk 위에 워크트리 생성** — fetch 없이 파면 브랜치 전부가 과거에서 출발한다.
- **착수 push 생략** — 원격 이벤트가 0이라 트래커는 이슈가 시작된 줄 모른다(Backlog 그대로).
- **워크트리 경로 하드코딩** — repo 마다 배치가 다르다. `worktree list` 로 관례를 읽는다.
- **worker 자가보고를 그대로 완료 처리** — [DONE] 은 주장이지 증거가 아니다(Step 7).
- **worker 에게 머지·force-push 허용** — 되돌리기 어려운 구간을 사람 없이 통과한다.
- **oversized 이슈를 그대로 자율 실행** — 전면 개편은 worker 프롬프트 한 장에 안 담긴다.
  `linear-replan`/`deep-plan` 으로 뺀다.
- **메인 워크트리에서 편집** — 메인 체크아웃은 trunk 로 남는다.
- **SSOT 절차 복제** — Linear MCP 감지·팀 라우팅·종료 출력은 경로로 참조한다.

## References

- `~/.claude/references/craft/linear.md` §1 — Linear MCP 감지·repo→team 스코프.
- `~/.claude/references/craft/output-contract.md` — 종료 출력(R/V/N/L1).
- `~/.claude/rules-ondemand/branch-worktree-strategy.md` §1 — 자동연동 전제·이벤트 부재 함정.
- `~/.claude/rules-ondemand/cc-worktree.md` — 워크트리 포트·도메인·`.env` 복사 훅과 한계.
- `~/.claude/references/craft/worktree.md` — 격리 게이트 SSOT(이 스킬은 생성권 예외).
