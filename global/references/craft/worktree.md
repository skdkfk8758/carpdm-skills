# Worktree 격리 게이트 — 공유 SSOT

> **이 문서는 워크트리를 만들지 않는다. 검사만 한다.** 생성권은 사용자(Orca 카드)에게
> 있고, 스킬은 "격리된 트리에 있는가"만 확인해 통과시키거나 멈춘다.
>
> **`linear-goal`(승인 후 동기 블록)** 이 이 한 장을 읽는다 — **복제 금지**(drift 차단).
> 사람 없는 백그라운드 잡을 띄우므로 게이트가 hard gate 다.
>
> craft 빌드 엔진(`pipeline.md`·`orchestrated.md`)은 이 파일을 읽지 않는다 — forge/hunt/
> renew 는 대화형이라 글로벌 `branch-worktree-strategy.md` §5 +
> `guard-worktree-edit-isolation` 훅이 규범을 담당한다. 파일이 craft-core 에 있는 건
> output-contract·linear 와 같은 이유 — **공유 reference 컨테이너**이기 때문이다.

근거 룰: `~/.claude/rules/branch-worktree-strategy.md` §5(메인 워크트리는 trunk 유지) +
`commit-isolation.md`(uncommitted 노출 최소화).

## 왜 만들지 않고 검사만 하나

워크트리는 사용자가 Orca 카드로 직접 만든다. 스킬이 또 만들면 사용자가 의도하지 않은
이름·위치의 트리가 생기고, 이미 격리된 세션엔 워크트리를 겹쳐 판다.

반대로 검사까지 빼면 **메인 워크트리에서 백그라운드 잡이 trunk 를 자율 편집**한다.
"Orca 에서 열었다"는 격리를 보장하지 않는다 — Orca 는 메인 워크트리도 카드로 관리한다
(실측: 등록된 워크트리 19개 중 13개가 `isMainWorktree: true`, 그중 하나가 이 레포의
`master` 체크아웃).

## Step 1 — 현재 위치 감지

```
git rev-parse --path-format=absolute --git-dir --git-common-dir
```

두 줄이 **같으면 메인 워크트리**, **다르면 linked 워크트리**다(linked 는 `--git-dir` 이
`<common>/worktrees/<name>`). `--path-format=absolute` 가 상대·절대 혼재를 없애 준다 —
이걸 빼면 메인 repo 의 하위 디렉토리에서 `.git` vs `../.git` 로 갈려 오판한다.

**Orca 를 감지에 쓰지 말 것.** `orca worktree current --json` 의 `isMainWorktree` 는
Orca 가 만든 워크트리만 안다 — `git worktree add` 로 만든 워크트리 안에서 호출하면 경로
매칭으로 **메인을 반환한다**(실측: repo 하위 `.claude/worktrees/…` 에서 `isMainWorktree: true`).
`land/references/orca.md` 의 `linkedPR` 교훈과 동형 — Orca 메타는 보강이지 ground truth 가
아니다. 격리 여부는 위 git 명령이 SSOT.

## Step 2 — 게이트 판정

현재 브랜치는 `git rev-parse --abbrev-ref HEAD` 로 읽는다.

| Step 1 | 현재 브랜치 | 판정 |
|---|---|---|
| linked 워크트리 | feature 브랜치 | **통과** — 이 트리에서 진행 |
| linked 워크트리 | base(`develop`/`main`/`master`) | **STOP** — 격리가 아니다 |
| 메인 워크트리 | 무관 | **STOP** — trunk 체크아웃이다 |

**STOP 은 hard gate 다.** 백그라운드 잡(goal worker)을 **띄우지 않고**
사용자에게 넘긴다. 자동으로 `git worktree add` 하지 않는다 — 생성권은 사용자에게 있다.

STOP 메시지에는 사용자가 바로 쓸 수 있게 다음을 담는다:

- 현재 위치(메인/linked)와 브랜치 — 왜 멈췄는지의 증거
- 권장 브랜치명 — `<type>/<topic>`, Linear 이슈ID 가 있으면 `<type>/<issue-id>-<topic>`
  (`branch-worktree-strategy` §2a — issue-id 없으면 PR↔이슈 자동연동이 안 걸린다).
  linear-goal 은 `feat/<issue-id>-<topic>` 를 권한다.
- "Orca 카드로 워크트리를 만들고 그 세션에서 다시 실행해 달라"는 한 줄

## 호출처별 추가 계약

- **linear-goal**: STOP = goal worker spawn 금지.

## Anti-patterns

- STOP 대신 `git worktree add` 로 자동 분기 — 생성권은 사용자에게 있다.
- 메인 워크트리인데 "어차피 사용자가 Orca 로 열었을 것"으로 통과 — 등록된 워크트리
  13/19 가 메인이다. 등록 ≠ 격리.
- 게이트 자체를 생략 — 백그라운드 잡이 trunk 를 자율 편집한다(`commit-isolation.md`).
- 감지를 `orca worktree current` 로 — 실측 반례 있음(위 Step 1).
