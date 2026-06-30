---
name: land
description: Land the open PRs you pushed from worktrees and bring local back in sync — 새 세션에서 머지 가능한 PR 들을 (CI 통과 후 squash 로) 머지하고, 기본 브랜치를 pull 하고, 머지된 로컬 브랜치를 삭제하고, 머지된 워크트리를 제거하고, 랜딩되지 않은 브랜치는 rebase 한다. 아직 PR 이 없는 브랜치(커밋은 쌓였는데 안 올린 상태)면 머지 전에 push + PR 생성부터 한다. 유저가 열린 PR 을 MERGE / LAND 하고 로컬 git 상태를 CLEAN UP 하려 할 때, 또는 작업한 브랜치를 PR 로 올려 머지까지 한 흐름으로 가려 할 때 사용 — "올린 PR들 머지하고 로컬 최신화해줘", "PR 다 머지하고 브랜치/워크트리 정리", "merged 브랜치 prune하고 master 당겨줘", "이 브랜치 PR 올려서 머지까지 해줘", "워크트리 개발 끝났으니 정리", "land my PRs and sync local", "push my branch as a PR and land it" 같은 표현. 특히 forge·hunt·renew·harness 같은 빌드 흐름으로 구현/수정 작업을 막 끝낸 직후 — 유저가 "다 됐어", "작업 끝났어", "구현 완료", "이제 정리하자", "마무리하자", "머지하자", "올려서 머지까지", "PR 올려줘", "브랜치 정리해줘", "ship it", "wrap up", "let's land this" 처럼 작업 마무리를 신호하면 — 명시적으로 'land'·'머지'라는 단어가 없어도 — 이 스킬을 적극적으로 떠올려라(자동 발동을 의도). 머지·브랜치 삭제 같은 비가역 동작은 내부 승인 게이트(Step 3 Confirm)가 막아 주므로, 트리거는 곧 "읽기전용 상태 발견 + 플랜 제시 + 승인 대기"일 뿐이라 적극적으로 발동해도 안전하다. 단 유저가 아직 구현 중이면(코드를 더 쓰고 있거나, 테스트가 안 끝났거나, PR 을 아직 안 올렸고 올릴 의사도 없으면) 트리거하지 말 것 — 그건 forge/hunt/renew 의 영역이다. PR 이 독립적인지 stacked(한 PR 이 다른 PR 위에 쌓인 것)인지 자동 감지해 올바른 순서로 머지한다. 코드를 작성하거나, 기능을 빌드하거나(forge 사용), 버그를 고치거나(hunt 사용), 미완 작업을 재개/복원(handoff 사용)하는 데에는 사용하지 말 것 — land 는 (필요하면 PR 을 올린 뒤) 머지하고 로컬 트리를 깨끗이 하는 것이지, 그 안의 작업 자체를 다루는 게 아니다. 이 레포(carpdm-skills)의 스킬 변경 배포는 sync.sh 미러가 필요하므로 land 가 아니라 ship 을 쓴다.
---

# Land — push 한 PR 을 머지하고 로컬을 안전하게 재동기화

당신은 워크트리 브랜치에서 개발하고, PR 을 줄줄이 push 한 다음 — 보통은 어느
브랜치가 무엇이었는지 기억이 없는 새 세션에서 — 그것들을 머지하고 로컬 트리를
정리하길 원한다: 기본 브랜치는 최신, 머지된 브랜치와 워크트리는 제거, 살아남은
브랜치는 새 베이스 위로 rebase. 손으로 하면 까다롭고 틀리기 쉽다: stacked PR 을
순서를 어겨 머지하면 엉망이 되고, 실제로 랜딩되지 않은 브랜치를 삭제하면 작업을
잃는다. 가끔은 머지할 PR 이 아직 없다 — 브랜치에 커밋은 쌓였는데 안 올린 상태다.
그땐 머지 전에 PR 부터 올린다(Step 0).

이 스킬은 그 일을 절제된 파이프라인으로 수행한다. 작업 대부분이 **거의
비가역적**(머지, 브랜치 삭제, 워크트리 제거, rebase)이므로 계약은 이렇다:
실제 상태를 발견하고, 안전한 순서를 정하고, **플랜을 보여주고 한 번의 승인을
받은 뒤**, 실행하고 보고한다. 절대 추측하지 말고, 절대 force 하지 말 것.

## 안전 경계 — 무엇이든 하기 전에 읽을 것

| Action | 입장 |
|---|---|
| **절대 안 함** | 공유 브랜치에 `git push --force`, draft / CI 실패 / mergeable 아닌 PR 머지, PR 이 아직 열려 있는 브랜치 삭제, 기본 브랜치에 직접 커밋, 추측으로 conflict 해결 |
| **한 번 확인 후 실행** | 자기 feature 브랜치 push + `gh pr create`(Step 0), PR 머지, 머지된 로컬 브랜치 삭제, `git worktree remove`, 살아남은 브랜치 rebase |
| **자유롭게 실행** | `gh pr list`, `git worktree list`, `git fetch`, `git rev-list --count`, CI 상태 읽기, `git checkout <default>` + `git pull` (fast-forward) |

브랜치는 **그 PR 이 머지되었을 때만**(또는 PR 이 없고 유저가 확인했을 때만)
삭제해도 안전하다. "머지된 것 같다"는 충분하지 않다 — 브랜치 이름이 아니라
`gh`/git 으로 검증할 것. 무엇이든 모호하면(예상치 못한 열린 PR, dirty 워크트리,
PR 없는 브랜치) 진행하지 말고 **멈추고 물어볼 것**.

CI 가 실패하거나, 머지가 막히거나, rebase 가 conflict 를 만나면: **그 항목을
중단하고, 복구 가능한 상태로 남기고, 보고하고, 아직 안전한 것으로 넘어갈 것.**
막힌 PR 하나 때문에 전체 실행을 중단하지 말고, 유저 없이 `rebase --abort` 하거나
conflict 를 버리지 말 것 — 유저가 해결하고 싶어 할 수 있다.

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

승인 후 각 후보를:

- push 안 됐으면 `git push -u origin <branch>` (force 금지 — 자기 feature 브랜치
  일반 push 만).
- `gh pr create --base <default> --head <branch> --fill` 로 PR 을 연다(draft 아님).
  제목/본문은 커밋에서 뽑는 `--fill` 이 기본 — 유저가 따로 주면 그걸 쓴다.
- base 는 항상 기본 브랜치. raise 는 **독립 PR(→default)만** 만든다 — stacked PR 을
  새로 *설계*하지 않는다(그건 워크트리 작업 시점의 일이다). 이미 stacked 로 올라온
  PR 의 머지 순서 처리는 2~4 단계가 한다.

raise 한 PR 들은 이제 열린 PR 이므로, 이어지는 1. Discover→Classify→Confirm→Merge 가
나머지와 똑같이 흡수한다. CI 는 4 단계의 머지 대기에서 함께 기다린다 — raise 가
CI 를 따로 기다리지 않는다.

### 1. Discover — 실제 상태 파악, 가정하지 말 것

다음(읽기 전용)을 실행해 무엇이든 건드리기 전에 그림을 그려라:

- `gh pr list --author @me --state open --json number,title,headRefName,baseRefName,isDraft,mergeable,mergeStateStatus,statusCheckRollup`
  — 열린 PR 들, head/base 브랜치, draft 플래그, 머지 가능성, CI 상태.
- `git worktree list` — 어떤 워크트리가 존재하고 각각 어떤 브랜치를 들고 있는지.
- `git branch --format '%(refname:short) %(upstream:short) %(upstream:track)'` — 로컬 브랜치와 그 추적 상태.
- `git fetch --prune` — remote ref 를 갱신하고 삭제된 remote-tracking 브랜치를 떨군다.

기본 브랜치는 `gh repo view --json defaultBranchRef` 로 식별할 것 (`master`/`main` 하드코딩 금지).

### 2. Classify — 독립적 vs stacked

각 열린 PR 에 대해 그 `baseRefName` 을 기본 브랜치와 비교한다:

- **base == default** → 독립적 PR. 머지 순서는 상관없다.
- **base == 다른 열린 PR 의 head** → stacked. PR 들이 체인을 이룬다; 아래에서 위로
  머지해야 하고, 각 머지마다 다음 PR 의 base 를 다시 가리켜 줘야 한다.

혼합도 정상이다 — 일부는 독립, 일부는 stacked. stack 체인을 topological sort 로
머지 순서를 만들고, 독립 PR 은 아무 데나 끼워 넣는다. stack 이 있을 때의 정확한
re-basing 동작은 `references/stacking.md` 참조.

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
  remove worktrees [../wt-login, ../wt-ratelimit], rebase surviving [refactor-auth] onto <default>
Proceed?
```

승인을 기다린다. 이것이 유일한 게이트다 — 그 후에는 무언가 중단되지 않는 한 추가 프롬프트 없이 실행한다.

### 4. Merge — squash, CI 대기

각 PR 을 순서대로: `gh pr merge <n> --squash --auto --delete-branch`.
`--auto` 는 필수 체크가 통과하면 GitHub 이 머지하게 한다; `MERGED` 가 되거나 체크가 실패할 때까지 `gh pr view <n> --json state,mergeStateStatus` 를 폴링한다. (레포에 필수 체크가 없으면 `mergeStateStatus` 가 `CLEAN` 이고 즉시 머지된다 — 대기 없음.) 레포에 auto-merge 가 꺼져 있으면 `--auto` 가 에러를 낸다 — 그땐 CI 가 green 인지 직접 확인한 뒤 `--auto` 없이 `gh pr merge <n> --squash --delete-branch` 로 머지한다.

`--delete-branch` 는 머지 시 remote 브랜치를 제거한다. 한 가지 편의: PR 의 head 브랜치가 **이 메인 워크트리에 현재 체크아웃된** 브랜치라면, `gh` 가 *로컬* 브랜치도 삭제하고 당신을 기본 브랜치로 전환시킨다 — 그래서 흔한 "내가 올라가 있는 브랜치를 머지" 케이스는 여기서 완전히 정리되고, 5 단계의 브랜치 삭제는 *다른* 워크트리에 사는 브랜치만 처리하면 된다. 다른 곳에 체크아웃된 브랜치는 `gh` 가 건드리지 않으므로 여전히 5 단계가 필요하다.

**stack** 의 경우, base PR 이 머지된 뒤 다음 PR 의 base 를 기본 브랜치로 다시 가리킨다(`gh pr edit <next> --base <default>`) — 머지하기 전에. 그러지 않으면 그 diff 가 틀린다. 자세한 내용과 엣지 케이스: `references/stacking.md`.

체크가 실패하거나 머지가 막히면, 그 PR 을 중단하고(그 위에 stacked 된 것도 함께 — 아직 머지될 수 없으므로), 보고하고, 아직 멀쩡한 독립 PR 로 계속 진행한다.

### 5. Sync local — pull, 브랜치 prune, 워크트리 제거, 살아남은 것 rebase

머지가 끝나면:

1. **기본 브랜치 Pull**: `git checkout <default> && git pull --ff-only`. (여기서 절대 커밋하지 말 것 — branch-protection 가드가 직접 작업을 막고, `--ff-only` 가 깨끗하게 유지한다.)
2. **머지된 워크트리를 먼저 제거하고, 그 다음 브랜치 삭제** — 순서가 중요하다: 워크트리에 체크아웃된 브랜치는 삭제할 수 없다. 랜딩된 브랜치를 가진 각 워크트리에 대해, **제거 전 `git -C <path> status --porcelain` 으로 깨끗한지 확인하라** — 비어 있지 않으면(커밋 안 된 작업) 멈추고 물어볼 것, 절대 `worktree remove --force` 로 밀지 말 것(stack 여부와 무관하게 항상 적용 — `references/stacking.md` "Dirty 워크트리 가드"는 이 규칙의 rebase 케이스 포함 상세본). 깨끗하면 `git worktree remove <path>` 한 뒤 브랜치를 삭제한다. 안전망으로 `git branch -d <branch>` (소문자)를 선호하라 — git 은 그 브랜치가 기본 브랜치의 조상이 아니면 거부한다. **하지만 squash 머지는 이 체크를 깬다**: squash 는 브랜치를 기본 브랜치 위의 하나의 새 커밋으로 접어 버려서, 원래 브랜치 커밋들은 조상이 *아니게* 되고 PR 이 정말로 머지됐어도 `-d` 가 거부한다. 그러므로: `-d` 가 거부하면 작업이 랜딩 안 됐다고 단정하지 말 것 — PR 에 대해 확인하라(`gh pr view <n> --json state` 가 `MERGED` 를 보여준다). 머지됐다면 `git branch -D <branch>` 가 안전하다; 그 삭제는 로컬 조상이 아니라 머지가 뒷받침한다. PR 이 머지되지 *않았는데* `-d` 가 여전히 거부할 때만 조사할 것(절대 `-D` 금지) — 그게 진짜 "이건 랜딩 안 됐다" 신호다.
3. **remote-tracking prune**: `git fetch --prune` / `--delete-branch` 가 이미 처리했다; 마지막 `git remote prune origin` 이 남은 것을 정리한다.
4. **살아남은 것 rebase**: 랜딩되지 않은 각 로컬 브랜치에 대해 `git rebase <default>`. conflict 시 멈추고 그 브랜치를 보고하라(유저가 해결하거나 요청 시 당신이 해결할 수 있게 rebase 를 진행 중으로 남겨 둘 것) — 복구 형태는 `references/stacking.md` 참조.
5. **Linear 이슈 Done 전이 (연결된 이슈가 있을 때만, graceful).** 머지된 PR 에
   연결된 Linear 이슈를 식별할 수 있으면(PR body/브랜치명이 이슈 URL/ID 를 참조하거나
   Linear GitHub 연동이 붙어 있으면) `~/.claude/skills/craft-core/references/linear.md`
   의 전이 맵대로 **Done 으로 옮긴다**. 이게 빌드(In Progress→In Review)에서 시작한
   라이프사이클의 마지막 칸이다. Linear MCP 미설치이거나 연결 이슈를 못 찾으면 **묻지
   말고 생략**한다 — Linear 전이는 머지/정리를 막지 않는다(저위험 부가 단계).

### 6. Report — 무엇이 랜딩됐고, 그 설계가 어디 있는지

land 는 보통 새 세션에서 돈다 — 유저는 방금 머지한 게 정확히 무엇이었고 그 설계
근거가 어디 적혀 있는지 기억이 흐릿하다. 그래서 report 는 단순 "머지함" 통보가
아니라, 나중에 다시 읽어도 무엇이 배에 실렸는지 알 수 있는 **짧은 변경 기록**이어야
한다. 각 머지된 PR 마다 ① 한 일 요약 ② 그 작업의 설계·문서 링크를 함께 붙인다.
이 메타데이터는 머지·브랜치 삭제 뒤에도 `gh pr view <n>` 으로 읽히므로 report
시점에 모아도 된다(머지 전 Discover 에서 미리 캐싱해 둬도 좋다).

**세션 이름 설정 — `result:` 직전 필수 선행 행동 (백그라운드 잡 + 1건 이상 머지일 때).**
이 세션이 백그라운드 잡으로 돌고 있고(`$CLAUDE_JOB_DIR` 존재) 실제로 1건 이상 머지됐으면,
**report 와 `result:` 를 내기 전에 먼저** 세션 이름을 랜딩 결과로 바꾼다 — 이것은 land 의
마지막 단계이지 선택적 아사이드가 아니다. 순서를 고정한다: **① 한 일 요약 수집 → ② rename
실행(아래) → ③ report 출력 → ④ `result:`**. rename 을 건너뛰고 곧장 report/`result:` 로
가지 말 것 — 이 스킵이 "land 후 이름이 안 바뀐다"의 원인이다.

- 실행: [`references/session-rename.md`](references/session-rename.md) 의 atomic snippet 그대로
  (`state.json` `name` 갱신 + `nameSource:"user"` — 하니스 auto-rename 차단). 포맷: 단일
  `landed #451 fix(make)`(연결 이슈 있으면 `landed [ADT-33] fix(make)`), 다수 `landed 3 PRs`.
- **조용히 생략하는 경우는 둘뿐**: 잡 컨텍스트 아님(`$CLAUDE_JOB_DIR` 없음) 또는 머지 0건.
  그 외엔 반드시 실행한다. 실행 자체가 실패하면(파일·권한) note 1줄 남기고 보고는 계속 —
  단 "실패해도 됨"이 "안 해도 됨"은 아니다.

각 머지된 PR 에 대해 모은다:

- **한 일 요약(1~2줄)**: `gh pr view <n> --json title,body,commits` 에서 압축한다.
  PR body 의 "변경/Summary" 섹션이나 커밋 메시지 제목들이 근거다. 진단·추측이 아니라
  실제 PR 내용을 근거로 — 없으면 커밋 제목을 그대로 쓴다.
- **설계·문서 링크**: PR body·커밋 메시지·변경 파일에서 설계 산출물을 긁는다 —
  - PR body/커밋 텍스트에 박힌 경로·URL: `docs/plans/…`, `docs/specs/…`, `docs/adr/…`,
    `docs/reference/…`, Linear 이슈(`ADT-\d+`, `linear.app/…`), 외부 설계 링크.
  - `gh pr view <n> --json files` 의 변경 파일 중 `docs/**`(특히 `plans/`·`specs/`·`adr/`) —
    그 작업의 설계 문서는 보통 같은 PR 안에 함께 들어온다.
  - 찾은 링크는 클릭 가능하게 — 레포 상대경로(예: `docs/plans/2026-06-29-x.md`)는
    마크다운 링크로, 이슈/PR 은 전체 URL 로. **없으면 생략한다 — 추측해 만들어내지 말 것.**

포맷은 **카드형** — 맨 위 한눈 요약, 그 아래 PR 카드, 마지막에 휘발성 sync. 영속
changelog(Landed)를 시각적으로 1순위에, 운영 정리(Local sync)를 부차로 둔다. 머지 건수에
따라 두 형태로 graceful 하게 줄인다.

**다수 PR (2건+):**

```
🚢 Landed N · ⏭ Skipped M · 🔧 Synced
────────────────────────

## Landed

▸ [#451](PR 전체 URL) · fix(make)
  NestJS+Vite 잔재 제거 · make dev→npm run dev(next :3000) · find-free-port.sh 삭제
  ↳ [plan](docs/plans/2026-06-29-makefile-next.md) · ADT-33

▸ [#450](PR 전체 URL) · feat(api)
  …한 일 1~2줄, `·` 구분…
  ↳ [spec](docs/specs/…md) · ADT-31

## Skipped
⏭ [#46](PR 전체 URL) refactor auth — CI 실패 (재시도 후 다시 land)

## Local sync
develop `→ <sha>` · 워크트리 [stoic-wu] 제거 · [refactor-auth] rebase
```

**단일 PR** — 요약 헤더·구분선·섹션 헤딩 생략, 카드 1개 + sync 1줄로 압축:

```
🚢 Landed [#451](PR 전체 URL) · fix(make)
NestJS+Vite 잔재 제거 · make dev→npm run dev(next :3000) · find-free-port.sh 삭제
↳ [plan](docs/plans/2026-06-29-makefile-next.md) · ADT-33

🔧 develop `→ <sha>` · 워크트리 정리
```

포맷 규칙:

- **요약 헤더**(`🚢 Landed N · ⏭ Skipped M · 🔧 Synced`)는 **2건+ 일 때만**. 스크롤 없이
  카운트 한눈에. 단일 PR 은 생략.
- **구분선** = box-drawing `─` 반복. markdown `---` **금지** — 바로 위 요약줄을 setext
  H2 헤딩으로 오인 렌더한다. 단일 PR 은 구분선 자체를 생략.
- **카드 헤더** = `▸ [#N](url) · <type(scope)>` — PR 은 전체 URL 링크, type/scope 는 커밋
  제목에서. **한 일**은 헤더 아래 2칸 들여쓰기 `·` 구분 1~2줄. **설계·이슈 링크**는 `↳`
  줄로 분리(없으면 `↳` 줄 통째 생략 — 추측 금지, 위 수집 규칙 그대로).
- **글리프 고정**: 🚢 Landed · ⏭ Skipped · 🔧 Local/Synced. 그 외 이모지 남발 금지(노이즈).

미완 항목(conflict 로 멈춘 rebase, 막혀서 제외된 PR)은 `## Skipped` 또는 별도 `## ⚠ 미완`
섹션에 명시해 아무것도 조용히 빠져나가지 않게 할 것.

마지막 메시지는 `result:` 한 줄로 못 박는다(`~/.claude/skills/craft-core/references/output-contract.md`
L1 — 전 스킬 공통, 백그라운드 잡 완료 신호). 머지/정리 수치를 담되 self-contained 로
(예: `result: N개 PR 머지 — 로컬 <default> 동기화, M개 브랜치/워크트리 정리, K개 rebase`).
산출물이 git 상태 변화라 열기 블록(L2)·다음 스킬 제안(L3)은 적용 안 한다. conflict 로
멈춘 rebase 가 있으면 `result:` 가 아니라 진행 상태로 보고한다(미납품).

## 이 스킬이 틀린 선택일 때

- 유저가 변경을 *작성*하려는 것이지 머지하려는 게 아닐 때 → `forge` / `hunt` / `renew`.
- 유저가 미완 작업을 재개하거나 어디까지 했는지 떠올리려 할 때 → `handoff`.
- 유저가 git 브랜치가 아니라 오래된 문서/로그를 치우려 할 때 → `sweep`.
- 배포할 게 이 레포(carpdm-skills)의 스킬 변경일 때 → `ship`. live↔repo `sync.sh`
  미러가 선행돼야 하는데 land 의 Raise 는 일반 브랜치 push 만 한다(미러 안 함).
