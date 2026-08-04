---
name: land
description: Land the open PRs you pushed from worktrees and bring local back in sync — PR 없는 브랜치는 push+PR 생성부터, CI 통과 후 squash 머지 → 기본 브랜치 pull → 머지된 브랜치 삭제 → 살아남은 브랜치 rebase. 독립/stacked PR 자동 감지·순서 머지, 리포트에 Linear Done 전이 + 잔여 작업 판정(git·Linear·handoff — 모두 완료면 완료 선언 + wt-sweep 안내). 유저가 PR 을 머지하고 로컬을 정리하려 하거나 구현을 막 끝내고 마무리를 신호할 때 — 'land'·'머지' 란 말이 없어도 — 적극 발동: "올린 PR들 머지하고 로컬 최신화해줘", "다 됐어", "작업 끝났어", "마무리하자", "ship it", "wrap up", "land my PRs and sync local". 비가역 동작은 내부 승인 게이트(Step 3 Confirm)가 막으므로 트리거 = 읽기전용 발견+플랜 제시+승인 대기 — 발동 자체는 안전하다. 워크트리·세션 기록 정리는 wt-sweep(land 는 워크트리를 건드리지 않는다), 아직 구현 중이면 구현을 먼저 끝내고, 미완 작업 재개는 handoff, carpdm-skills 스킬 배포는 ship(sync.sh 미러 선행 필요).
---

# Land — push 한 PR 을 머지하고 로컬을 안전하게 재동기화

당신은 워크트리 브랜치에서 개발하고, PR 을 줄줄이 push 한 다음 — 보통은 어느
브랜치가 무엇이었는지 기억이 없는 새 세션에서 — 그것들을 머지하고 로컬 트리를
정리하길 원한다: 기본 브랜치는 최신, 머지된 브랜치는 삭제, 살아남은
브랜치는 새 베이스 위로 rebase. 손으로 하면 까다롭고 틀리기 쉽다: stacked PR 을
순서를 어겨 머지하면 엉망이 되고, 실제로 랜딩되지 않은 브랜치를 삭제하면 작업을
잃는다. 가끔은 머지할 PR 이 아직 없다 — 브랜치에 커밋은 쌓였는데 안 올린 상태다.
그땐 머지 전에 PR 부터 올린다(Step 0).

이 스킬은 그 일을 절제된 파이프라인으로 수행한다. 작업 대부분이 **거의
비가역적**(머지, 브랜치 삭제, rebase)이므로 계약은 이렇다:
실제 상태를 발견하고, 안전한 순서를 정하고, **플랜을 보여주고 한 번의 승인을
받은 뒤**, 실행하고 보고한다. 절대 추측하지 말고, 절대 force 하지 말 것.

**워크트리는 건드리지 않는다.** 워크트리 제거·Claude Code 세션 기록 정리는
`wt-sweep` 스킬의 일이다 — land 는 머지·브랜치·rebase 까지만 하고, 잔여
워크트리는 Report 에 목록으로 남겨 wt-sweep 을 안내한다.

**Orca 통합(선택).** Orca 앱이 이 repo 를 관리 중이면 **워크트리 메타 한 지점**을
보강할 수 있다 — 감지 게이트·명령·금지는 `references/orca.md`(**lazy-read** — 감지
게이트가 거짓이면 이 파일을 읽지도 않는다). orca 는 git 을 대체하지 않는다: orca CLI 에
PR·머지·브랜치·rebase 명령이 없어 판정 SSOT 는 언제나 `gh`/`git` 이다.

## 안전 경계 — 무엇이든 하기 전에 읽을 것

| Action | 입장 |
|---|---|
| **절대 안 함** | 공유 브랜치에 `git push --force`, draft / CI 실패 / mergeable 아닌 PR 머지, PR 이 아직 열려 있는 브랜치 삭제, 기본 브랜치에 직접 커밋, 추측으로 conflict 해결 |
| **한 번 확인 후 실행** | 자기 feature 브랜치 push + `gh pr create`(Step 0), PR 머지, 머지된 로컬 브랜치 삭제, 머지된 자기 feature 브랜치의 remote 잔존 삭제(`git push origin --delete`), 살아남은 브랜치 rebase |
| **하지 않음 (wt-sweep 의 일)** | `git worktree remove`, Claude Code 세션 기록 삭제 — 잔여 워크트리는 Report 에 목록만 남기고 wt-sweep 안내 |
| **자유롭게 실행** | `gh pr list`, `git worktree list`, `git fetch`, `git rev-list --count`, `git ls-remote --heads`, `git merge-base --is-ancestor`, CI 상태 읽기, `git checkout <default>` + `git pull` (fast-forward), Orca 읽기(`orca status`/`worktree ps`)와 Orca 메타 write(`worktree set --comment`/`--workspace-status` — git 무영향, 실패해도 무시) |

> 공유 브랜치 force-push 금지·squash-only·trunk 직접 push 금지의 SSOT = `~/.claude/rules-ondemand/branch-worktree-strategy.md` §3. 프로젝트별 override 판단 시 그 규칙을 따른다.

브랜치는 **그 PR 이 머지되었을 때만**(또는 PR 이 없고 유저가 확인했을 때만)
삭제해도 안전하다. "머지된 것 같다"는 충분하지 않다 — 브랜치 이름이 아니라
`gh`/git 으로 검증할 것. 무엇이든 모호하면(예상치 못한 열린 PR, dirty 워크트리,
PR 없는 브랜치) 진행하지 말고 **멈추고 물어볼 것**.

CI 가 실패하거나, 머지가 막히거나, rebase 가 conflict 를 만나면: **그 항목을
중단하고, 복구 가능한 상태로 남기고, 보고하고, 아직 안전한 것으로 넘어갈 것.**
막힌 PR 하나 때문에 전체 실행을 중단하지 말고, 유저 없이 `rebase --abort` 하거나
conflict 를 버리지 말 것 — 유저가 해결하고 싶어 할 수 있다.

머지할 PR 이 없으면(Discover 에서 열린 PR 0건 + raise 후보 0건) 할 일이 없다 —
그 사실을 보고하고, 잔여 워크트리가 보이면 `wt-sweep` 을 안내하고 멈춘다.

## 파이프라인

### 0. Raise — 아직 PR 이 없는 브랜치를 올린다 (해당될 때만)

가끔은 머지할 PR 이 아직 없다 — 워크트리/현재 브랜치에 커밋은 쌓였는데 PR 을 안
올린 상태다. 그러면 머지 전에 먼저 PR 을 만든다. **이미 PR 이 다 올라가 있으면 이
단계를 통째로 건너뛰고 곧장 1. Discover 로 간다** — 이 스킬의 평소 경로다.

올릴 후보 탐지(읽기 전용):

- `git fetch --prune` 후, 기본 브랜치보다 앞선 커밋이 있는 로컬 브랜치를 찾는다:
  각 브랜치에 대해 `git rev-list --count <default>..<branch>` 가 0 보다 크면 후보.
  기본 브랜치 자신과 default 의 조상(앞선 커밋 0)은 제외.
- 그중 **열린 PR 이 없는 것만** 추린다 — `gh pr list --author @me --state open --json headRefName`
  의 head 에 없는 브랜치. 이미 PR 이 있으면 raise 가 아니라 머지 대상(1 단계)이다.
- 후보가 없으면 raise 할 게 없다 → 1. Discover 로.

올릴 후보가 있으면, 머지 플랜과 **별개로** raise 플랜을 보여주고 한 번 승인받는다
(PR 생성은 외부 발신이라 게이트가 필요하다. 이건 4 단계의 머지 승인과 다른
게이트다 — 사이에 CI 가 돈다):

```
PR 없는 브랜치를 올린다 (base = <default>):
  feat/layerdock   (5 commits ahead)  → push + PR
  fix/tooltip-z    (2 commits ahead)  → push (이미 origin 에 있음) + PR
Proceed?
```

**승인은 3 단계 Confirm 과 같은 방식으로 받는다 — 게이트 형태를 비대칭으로 두지 말 것.**
raise 후보가 2건 이상이면 대화형 세션에서 `AskUserQuestion` `multiSelect`(각 브랜치 = 한
항목, 기본 전체 선택)로 제시한다. 자유 텍스트 "Proceed?" 는 유저가 일부만 올리려 할 때
프롬프트를 왕복하게 만드는데, 그 통증은 머지 승인이든 raise 승인이든 똑같다. 후보가
1건이면 텍스트 확인으로 족하다. **백그라운드 잡(`$CLAUDE_JOB_DIR` 존재)이면
`AskUserQuestion` 을 쓰지 말고** 텍스트 플랜 + `needs input:` 경로를 유지한다.

승인 후 각 후보를:

- push 안 됐으면 `git push -u origin <branch>` (force 금지 — 자기 feature 브랜치
  일반 push 만).
- `gh pr create --base <default> --head <branch>` 로 PR 을 연다(draft 아님). 유저가 제목/본문을
  주면 그걸 쓴다.
- **body 를 만들어서 넣을 것 — `--fill` 로 때우지 말 것.** `--fill` 은 body 를 커밋 메시지로
  채우는데, 그러면 **Step 6 Report 의 요약 수집이 항상 fallback(커밋 제목) 경로로 떨어진다**
  (Step 6 은 body 의 "변경/Summary" 섹션을 1순위로 읽는다). land 가 자기 손으로 만든 PR 이
  자기 changelog 품질을 깎는 셈이라, 최소 body 를 조립해 `--body` 로 넘긴다:
  - `## 변경` — `git log <default>..<branch> --oneline` 을 사람이 읽는 1~3줄로 압축.
  - `## 설계` — `git diff --name-only <default>..<branch>` 의 `docs/**`(특히 `plans/`·`specs/`·
    `adr/`)와 커밋 메시지에 박힌 이슈 ID/URL. **없으면 이 섹션 생략 — 추측해 만들지 말 것**
    (Step 6 의 수집 규칙과 같은 원칙).
  - 커밋이 1건이고 제목이 이미 충분하면 `--fill` 로 족하다 — 그 경우만 예외.
- base 는 항상 기본 브랜치. raise 는 **독립 PR(→default)만** 만든다 — stacked PR 을
  새로 *설계*하지 않는다(그건 워크트리 작업 시점의 일이다). 이미 stacked 로 올라온
  PR 의 머지 순서 처리는 2~4 단계가 한다.

raise 한 PR 들은 이제 열린 PR 이므로, 이어지는 1. Discover→Classify→Confirm→Merge 가
나머지와 똑같이 흡수한다. CI 는 4 단계의 머지 대기에서 함께 기다린다 — raise 가
CI 를 따로 기다리지 않는다.

### 1. Discover — 실제 상태 파악, 가정하지 말 것

**Preflight — 진행 불가 조건을 먼저 판정한다 (조용한 stall 금지).** 실측 통증:
remote 부재·예상외 브랜치 상태로 land 가 조용히 멈춰, 완성된 작업이 로컬
브랜치에만 남았다.

- `git remote -v` 가 비어 있으면 PR 흐름 자체가 불가 — 추측·재시도 없이 **즉시
  blocker 로 보고**하고 멈춘다(백그라운드 잡이면 `needs input:` 으로 "remote 없음
  — origin 설정 필요"). 부분 진행(로컬 정리만) 을 임의로 대체 실행하지 않는다.
- 메인 워크트리가 기본 브랜치 위가 아니면(다른 브랜치/detached) 그 사실을 플랜에
  명시한다. dirty 상태이기까지 하면 5 단계 pull 이 불가하므로 멈추고 보고 —
  절대 stash/reset 으로 임의 해소하지 말 것.

다음(읽기 전용)을 실행해 무엇이든 건드리기 전에 그림을 그려라:

- `gh pr list --author @me --state open --json number,title,headRefName,baseRefName,isDraft,mergeable,mergeStateStatus,statusCheckRollup`
  — 열린 PR 들, head/base 브랜치, draft 플래그, 머지 가능성, CI 상태.
  **`--author @me` 는 의도된 스코프다** — land 는 "당신이 워크트리에서 push 한 PR" 을
  랜딩하는 스킬이고, 남의 PR 을 머지하는 건 리뷰 권한 판단이 필요한 다른 일이다.
  그래서 팀 repo 에서 동료의 PR 은 보이지 않는 게 정상이다. 유저가 명시적으로 "전부"
  또는 특정 작성자를 지정하면 그때만 `--author` 를 풀거나 바꾼다. 스코프 때문에
  후보가 0건이면 "열린 PR 없음" 이 아니라 **"내 열린 PR 없음(스코프: @me)"** 로 보고해
  유저가 스코프를 의심할 수 있게 한다.
- `git worktree list` — 어떤 워크트리가 존재하고 각각 어떤 브랜치를 들고 있는지.
- `git branch --format '%(refname:short) %(upstream:short) %(upstream:track)'` — 로컬 브랜치와 그 추적 상태.
- `git fetch --prune` — remote ref 를 갱신하고 삭제된 remote-tracking 브랜치를 떨군다.
- **(Orca 감지 시)** `orca worktree ps --json` — 워크트리마다 branch·displayName·
  workspaceStatus·라이브 세션 attach(`hasAttachedPty`)·`linkedPR` 을 한 번에 준다.
  `git worktree list` 를 **대체하지 않고 보강**한다(Orca 밖 워크트리는 ps 에 안 나온다).
  `linkedPR` 은 표시용이지 판정 근거가 아니다 — 절차·필터·금지는 `references/orca.md`.

기본 브랜치는 `gh repo view --json defaultBranchRef` 로 식별할 것 (`master`/`main` 하드코딩 금지).

### 2. Classify — 독립적 vs stacked

각 열린 PR 에 대해 그 `baseRefName` 을 기본 브랜치와 비교한다:

- **base == default** → 독립적 PR. 머지 순서는 상관없다.
- **base == 다른 열린 PR 의 head** → stacked. PR 들이 체인을 이룬다; 아래에서 위로
  머지해야 하고, 각 머지마다 다음 PR 의 base 를 다시 가리켜 줘야 한다.

혼합도 정상이다 — 일부는 독립, 일부는 stacked. stack 체인을 topological sort 로
머지 순서를 만들고, 독립 PR 은 아무 데나 끼워 넣는다. stack 이 있을 때의 정확한
re-basing 동작은 `references/stacking.md` 참조.

**숨은 stack 검사 (base 가 전부 default 여도 필수).** `base == default` 만으로
독립이라 단정하지 말 것 — 실측 사고(#430/#431): 실제로는 stacked 인 두 브랜치를 둘 다
base=default 로 올리면, 부모를 squash 머지할 때 GitHub 이 자식을 **CLOSED**(머지 아님)
처리해 작업이 소실된다. base 가 default 인 PR 이 2건 이상이면 head 쌍마다 커밋 포함
관계를 검사한다: `git merge-base --is-ancestor <headA> <headB>` 가 참(또는
`git rev-list --count <headB>..<headA>` 이 0)이면 A 의 커밋이 B 에 포함된 것 —
"숨은 stack" 으로 승격한다. 승격 시: 자식 base 를 부모 브랜치로 re-point 하는 플랜을
명시하거나(4 단계처럼), 최소한 Confirm 플랜에 `⚠ 숨은 stack: #A ⊂ #B` 경고를 박아
부모 단독 머지가 자식을 닫지 않게 한다. 감지 절차 상세는 `references/stacking.md`.

이 검사는 base=default PR 이 n건이면 쌍마다 도는 **n(n−1)/2 회**다. 실무 n 은 한 자리라
무시해도 되지만, **n 이 8을 넘으면 전수 쌍 검사를 하지 말고** `git rev-list <default>..<head>`
로 각 head 의 커밋 집합을 한 번씩만 뽑아 포함 관계를 비교한다(n회 조회). 어느 경로든
**검사를 건너뛰지는 않는다** — 건너뛰면 #430/#431 사고가 그대로 재현된다. n 이 커서 다른
경로를 썼으면 Confirm 플랜에 그 사실을 한 줄 남긴다.

후보 집합에서 제외할 것: draft, 기다리지 말라고 들은 실패/대기 CI 의 PR,
`mergeable` 아닌 것 모두. 무엇을 왜 제외했는지 나열할 것.

단, **`mergeStateStatus` 가 `BLOCKED` 라고 stacked child 를 drop 하지 말 것** — stack 의
자식 PR 은 부모가 아직 머지 안 됐거나 base 가 default 가 아니면 GitHub 에서 흔히
`BLOCKED` 로 표시된다(`mergeable` 은 여전히 `MERGEABLE`). 이건 정상이고, 부모를
머지하고 base 를 re-point 하면(4 단계) 풀린다. 제외 판단은 `mergeStateStatus` 가
아니라 draft·CI 결론·`mergeable` 로 한다.

### 3. Confirm — 하나의 플랜, 하나의 승인

비가역 액션 전에 단일 플랜을 유저에게 보여줄 것:

```
Will merge (squash, after CI passes), in this order:
  #41 fix login redirect        (independent)
  #43 add rate-limit middleware (stack base) → then re-point #44 onto default
  #44 rate-limit config UI      (stacked on #43)
Skipping:
  #45 wip: dashboard            (draft)
  #46 refactor auth             (CI failing)
After merge, locally:
  pull <default>, delete merged branches [fix-login, rate-limit-mw, rate-limit-ui],
  rebase surviving [refactor-auth] onto <default>
Proceed?
```

승인을 기다린다. 이 승인 후에는 무언가 중단되지 않는 한 추가 프롬프트 없이 실행한다.

**대화형 세션에서는 승인을 AskUserQuestion 으로 구조화한다** — 자유 텍스트 "Proceed?"
는 유저가 일부만 승인(특정 PR 제외)하려 할 때 프롬프트를 왕복하게 만든다. 위 플랜을
낸 뒤, 머지 후보 PR 을 `multiSelect` 옵션으로(각 PR = 한 항목, 기본 전체 선택) 제시하면
부분 랜딩이 한 번에 끝난다. 유저가 일부를 해제하면 그 PR 은 이번 실행에서 제외한다.
**백그라운드 잡(`$CLAUDE_JOB_DIR` 존재)이면 AskUserQuestion 을 쓰지 말고** 기존 텍스트
플랜 + `needs input:` 경로를 유지한다(대화형 프롬프트가 잡을 멈춘다).

### 4. Merge — squash, CI 대기

각 PR 을 순서대로: `gh pr merge <n> --squash --auto --delete-branch`.
`--auto` 는 필수 체크가 통과하면 GitHub 이 머지하게 한다; `MERGED` 가 되거나 체크가 실패할 때까지 `gh pr view <n> --json state,mergeStateStatus` 를 폴링한다. (레포에 필수 체크가 없으면 `mergeStateStatus` 가 `CLEAN` 이고 즉시 머지된다 — 대기 없음.) 레포에 auto-merge 가 꺼져 있으면 `--auto` 가 에러를 낸다 — 그땐 CI 가 green 인지 직접 확인한 뒤 `--auto` 없이 `gh pr merge <n> --squash --delete-branch` 로 머지한다.

**폴링 간격·시간 캡 (CI hang 이 land 전체를 인질로 잡지 않게).** 폴링 간격은 CI 평균
소요에 맞추고(무의미한 초단위 폴링 금지 — 30s~1m 권장), **PR 당 15분 상한**을 둔다.
초과하면 그 PR 을 '미완'(CI 지연/hang)으로 보고(Report 의 `## Skipped`/`## ⚠ 미완`)하고
다음 안전한 PR 로 진행한다 — 무한 대기 금지.
**PR당 상한과 별개로 이 단계 전체에 총 45분 상한을 둔다.** per-item 상한만으로는 PR 5건일 때
최악 75분을 막지 못하고, 백그라운드 잡이 그동안 살아 점유한다. 총 45분을 넘기면 **대기를
중단하되 실행을 중단하지는 않는다** — 아직 머지 안 된 PR 들을 `## ⚠ 미완`(대기 상한 초과)으로
넘기고, 이미 머지된 것들의 정리를 위해 **5 단계로 진행한다**. 머지된 PR 을 정리 없이 남기는 게
기다리는 것보다 나쁘다.
백그라운드 잡이면 포그라운드 폴링 대신 `run_in_background` Bash 로 대기 명령을 띄우고
완료 시 재호출되는 경로를 쓴다(잡을 폴링으로 점유하지 않는다). 포그라운드 대화 세션은
현행 폴링 그대로. 상한 15분은 어느 경로든 동일하고, 본 SKILL 이 그 값의 SSOT 다.

`--delete-branch` 는 머지 시 remote 브랜치를 제거한다. 한 가지 편의: PR 의 head 브랜치가 **이 메인 워크트리에 현재 체크아웃된** 브랜치라면, `gh` 가 *로컬* 브랜치도 삭제하고 당신을 기본 브랜치로 전환시킨다 — 그래서 흔한 "내가 올라가 있는 브랜치를 머지" 케이스는 여기서 완전히 정리되고, 5 단계의 브랜치 삭제는 *다른* 워크트리에 사는 브랜치만 처리하면 된다. 다른 곳에 체크아웃된 브랜치는 `gh` 가 건드리지 않으므로 여전히 5 단계가 필요하다.

**stack** 의 경우, base PR 이 머지된 뒤 다음 PR 의 base 를 기본 브랜치로 다시 가리킨다(`gh pr edit <next> --base <default>`) — 머지하기 전에. 그러지 않으면 그 diff 가 틀린다. 자세한 내용과 엣지 케이스: `references/stacking.md`.

체크가 실패하거나 머지가 막히면, 그 PR 을 중단하고(그 위에 stacked 된 것도 함께 — 아직 머지될 수 없으므로), 보고하고, 아직 멀쩡한 독립 PR 로 계속 진행한다.

### 5. Sync local — pull, 브랜치 prune, 살아남은 것 rebase

머지가 끝나면 (아래 번호 항목은 다른 문서에서 `Step 5.1`~`5.5` 로 참조된다):

1. **기본 브랜치 Pull**: `git checkout <default> && git pull --ff-only`. (여기서 절대 커밋하지 말 것 — branch-protection 가드가 직접 작업을 막고, `--ff-only` 가 깨끗하게 유지한다.) **pull 전후 SHA 를 잡아, pulled range 에 lockfile 변경이 있으면 플래그한다** — pull 직전 `git rev-parse HEAD` 를 기억하고, pull 후 `git diff --name-only <before>..HEAD` 에 `package-lock.json`/`pnpm-lock.yaml` 이 있으면 deps 가 바뀐 것이다. worktree 별 `node_modules` 는 분리라 이 경우 main repo 에 `.bin` 미생성 → `make dev` 부팅 실패(`tsx: command not found`) 재발 위험(`branch-worktree-strategy.md` §5a). Report 에 `## ⚠ deps 변경` 섹션으로 lockfile 목록 + `npm install` 제안을 남긴다(마이그 플래그와 동형). 승인 하에 `npm install` 을 실행해도 되지만 임의 실행은 하지 않는다.
2. **머지된 로컬 브랜치 삭제 (워크트리는 건드리지 않는다)** — 안전망으로 `git branch -d <branch>` (소문자)를 선호하라 — git 은 그 브랜치가 기본 브랜치의 조상이 아니면 거부한다. **하지만 squash 머지는 이 체크를 깬다**: squash 는 브랜치를 기본 브랜치 위의 하나의 새 커밋으로 접어 버려서, 원래 브랜치 커밋들은 조상이 *아니게* 되고 PR 이 정말로 머지됐어도 `-d` 가 거부한다. 그러므로: `-d` 가 거부하면 작업이 랜딩 안 됐다고 단정하지 말 것 — PR 에 대해 확인하라(`gh pr view <n> --json state` 가 `MERGED` 를 보여준다). 머지됐다면 `git branch -D <branch>` 가 안전하다; 그 삭제는 로컬 조상이 아니라 머지가 뒷받침한다. PR 이 머지되지 *않았는데* `-d` 가 여전히 거부할 때만 조사할 것(절대 `-D` 금지) — 그게 진짜 "이건 랜딩 안 됐다" 신호다. **그 브랜치는 거기서 끝나지 않는다** — 랜딩되지 않았으므로 아래 4 항의 rebase 대상(survivor)이자 Step 6 잔여 판정 대상이다. "삭제 실패" 로 분류하고 흐름에서 떨구지 말 것(조용히 빠져나가는 항목 금지).
   - **워크트리에 체크아웃된 브랜치는 삭제할 수 없다** — 그 브랜치는 삭제를 시도하지 말고 건너뛰고, Report 의 잔여 워크트리 목록에 "브랜치 삭제 보류(워크트리 점유)" 로 남긴다. 워크트리 제거와 그 뒤 브랜치 삭제는 `wt-sweep` 의 일이다 — land 는 `git worktree remove` 를 실행하지 않는다.
3. **remote-tracking prune + remote 잔존 검사**: `git fetch --prune` / `--delete-branch` 가 이미 처리했다; 마지막 `git remote prune origin` 이 남은 것을 정리한다. 단 `--delete-branch` 는 head 브랜치가 워크트리/메인에 점유돼 있으면 remote 삭제를 **조용히 스킵**한다(실측: ADT-265 #458) — "옵션 줬으니 지워졌을 것"은 green 위장(verification-safety V1). 그러므로 머지된 각 PR 의 head 에 대해 `git ls-remote --heads origin <branch>` 로 검증하고, 비어 있지 않으면(=remote 에 잔존) `git push origin --delete <branch>`(자기 feature 브랜치 한정, force 아님)로 마저 지운다.
4. **살아남은 것 rebase**: 랜딩되지 않은 각 로컬 브랜치에 대해 `git rebase <default>`. conflict 시 멈추고 그 브랜치를 보고하라(유저가 해결하거나 요청 시 당신이 해결할 수 있게 rebase 를 진행 중으로 남겨 둘 것) — 복구 형태는 `references/stacking.md` 참조.
5. **Linear 이슈 Done 전이 (연결된 이슈가 있을 때만, graceful).** 머지된 PR 에
   연결된 Linear 이슈를 식별할 수 있으면(PR body/브랜치명이 이슈 URL/ID 를 참조하거나
   Linear GitHub 연동이 붙어 있으면) `~/.claude/references/craft/linear.md`
   의 전이 맵대로 **Done 으로 옮긴다**. 이게 빌드(In Progress→In Review)에서 시작한
   라이프사이클의 마지막 칸이다. Linear MCP 미설치이거나 연결 이슈를 못 찾으면 **묻지
   말고 생략**한다 — Linear 전이는 머지/정리를 막지 않는다(저위험 부가 단계).
   - **Done 전 수용 기준 체크박스 스캔 (글로벌 `CLAUDE.md` §검증 — 미충족이면 Done 중지).** 전이 직전
     이슈 본문의 체크박스(`- [ ]`/`- [x]`)를 확인한다 — 미체크 항목이 있으면 Done 대신
     그 이슈를 **In Review 로 두고**, Report 에 `⚠ AC 미체크 n건 (ISSUE-ID)` 로 표기한다
     (실측 SUR-26: 미체크 AC 가 Done+머지로 위장 통과). 침묵 전이는 제거하되 graceful
     정책은 유지 — 막지 않고 플래그만 한다(체크박스가 없거나 전부 `[x]` 면 그대로 Done).

### 6. Report — 무엇이 랜딩됐고, 그 설계가 어디 있는지

land 는 보통 새 세션에서 돈다 — 유저는 방금 머지한 게 정확히 무엇이었고 그 설계
근거가 어디 적혀 있는지 기억이 흐릿하다. 그래서 report 는 단순 "머지함" 통보가
아니라, 나중에 다시 읽어도 무엇이 배에 실렸는지 알 수 있는 **짧은 변경 기록**이다.

**이 시점에 `references/report-format.md` 를 읽고 그대로 따른다**(lazy-read — Step 6
전에 미리 읽지 않는다). 그 파일이 Step 6 의 SSOT 다: PR 마다의 수집 규칙, 세션 이름
설정, 잔여 작업 3-소스 판정, `▶ 다음 단계` 행 매핑, 조건부 섹션(마이그레이션 · deps
변경 · Skipped/미완 · Orca 워크트리), 카드형 렌더, `result:` 규격. 여기서 재기술하지
않는다.

이 단계에서 SKILL 이 보장할 것은 **순서와 누락 금지** 둘뿐이다:

- **고정 순서**: ① 한 일 요약 수집 → ② 세션 rename(백그라운드 잡 + 1건 이상 머지일 때,
  건너뛰지 말 것) → ③ report 본문 → ④ `▶ 다음 단계` 블록 → ⑤ `result:` 한 줄.
- **조용히 빠져나가는 항목 금지**: 대기 상한 초과 PR, conflict 로 멈춘 rebase, 삭제
  보류/거부된 브랜치, 마이그레이션 포함 PR, deps 변경은 전부 report 에 명시된다.
  머지 ≠ 적용, 랜딩 ≠ 완료 — 판정은 report-format.md 의 규칙대로 한다.

## 이 스킬이 틀린 선택일 때

- 워크트리·세션 기록을 치우려 할 때 → `wt-sweep`. land 는 워크트리를 건드리지
  않는다 — 머지 후 잔여 워크트리는 Report 에 목록만 남긴다.
- 유저가 변경을 *작성*하려는 것이지 머지하려는 게 아닐 때 → 메인이 직접 구현.
- 유저가 미완 작업을 재개하거나 어디까지 했는지 떠올리려 할 때 → `handoff`.
- 유저가 git 브랜치가 아니라 오래된 문서/로그를 치우려 할 때 → 이 스킬 아님(직접 정리).
- 배포할 게 이 레포(carpdm-skills)의 스킬 변경일 때 → `ship`. live↔repo `sync.sh`
  미러가 선행돼야 하는데 land 의 Raise 는 일반 브랜치 push 만 한다(미러 안 함).
