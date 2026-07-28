# Worktree 격리 — 공유 SSOT

> 격리 절차의 단일 소스. `pipeline.md`(Phase 0)·`orchestrated.md`(§0)·`harness-run`(G0)·
> `linear-goal`(승인 후 동기 블록)이 이 한 장을 읽는다 — **복제 금지**(drift 차단).
> output-contract·linear 와 같은 포지션: craft-core 에 두지만 **엔진 의존 아닌 공유 reference**.

근거 룰: `~/.claude/rules/branch-worktree-strategy.md` §5(새 브랜치 격리는 예외 없이
worktree, 메인 워크트리는 trunk 유지) + `commit-isolation.md`(uncommitted 노출 최소화).

## Step 1 — 현재 위치 감지

지금 세션이 **메인 워크트리**인지 **linked 워크트리**인지 먼저 판정한다. Orca 카드나 이전
세션이 이미 워크트리를 잡아 놨을 수 있고, 그때 또 분기하면 워크트리 안에 워크트리를 판다.

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

## Step 2 — 분기

| Step 1 결과 | 현재 브랜치 | 행동 | Step 3 의 기대 브랜치 |
|---|---|---|---|
| **linked 워크트리** | feature 브랜치 | `git worktree add` **하지 않는다** — 그 워크트리를 채택 | 현재 브랜치 |
| **linked 워크트리** | base(`develop`/`main`/`master`) | 격리가 아니다 → 새로 분기 | 새 브랜치 |
| **메인 워크트리** | 무관 | `git worktree add -b <branch> <dir>` 로 분기 | 새 브랜치 |

- **브랜치명**: `<type>/<topic>`. Linear 이슈ID 가 있으면 `<type>/<issue-id>-<topic>`
  (`branch-worktree-strategy` §2a — 없으면 PR↔이슈 자동연동이 안 걸린다).
  type = `feat`(forge/신규) · `fix`(hunt) · `refactor`|`feat`(renew) · 하니스는 `feat/<slug>`.
- **디렉토리**: repo 컨벤션이 있으면 그것(`.claude/worktrees/<type>+<topic>` 등),
  없으면 `../<repo>--<slug>`.
- `EnterWorktree` 는 deferred 도구(먼저 `ToolSearch` 로 로드)이고 **이미 워크트리면 거부**된다
  → `git worktree add` 를 1순위로 쓴다.
- 메인세션이 이 워크트리에 있어야 이후 dev/council/Workflow 가 거기서 돈다(Workflow agent 의
  cwd 는 launch 시점 메인세션 cwd 로 pin 된다).

## Step 3 — verify-or-STOP (생략 불가)

```
git -C <dir> rev-parse --abbrev-ref HEAD
```

Step 2 표의 **기대 브랜치와 불일치면 STOP** — 편집·구현·worker spawn 을 시작하지 않고
보고한다. 분기를 skip 한 경로(이미 linked + feature 브랜치)에서도 이 검증은 돈다.

이 검증을 빠뜨리면 빌드가 메인트리/trunk 에서 돌아 격리가 붕괴한다 — "확실히 분리"의
핵심은 분기가 아니라 **이 verify** 다. 호출처가 백그라운드 잡을 띄우는 경우(linear-goal 의
goal worker, harness-run 의 dev-eval-loop)에는 **hard gate** 로 취급한다: 검증 실패면 잡을
절대 띄우지 않는다.

## 예외 — 이어 커밋

이미 linked 워크트리이고 **동일 토픽 1–2 파일 이어 커밋**이면 Step 2 skip 이 정상 경로다
(§5 유일 예외). 이때도 Step 3 은 돌고, 현 트리를 유지하는 이유를 첫 응답에 한 줄 명시한다.

## 호출처별 추가 계약

- **harness-run**: 격리 후 eval 산물(`.eval/`)을 **워크트리 밖** `evalDir`
  (`<worktree>/../.eval-<slug>/`)로 옮긴다 — dev 워크트리에 oracle 이 0이어야 한다
  (REQ-F-008/N-001). 이 경로 규칙은 워크트리 존재를 전제하므로 Step 2~3 을 생략할 수 없다.
- **linear-goal**: Step 3 실패 = worker spawn 금지(hard gate).
- **pipeline / orchestrated**: 격리 직후 `session-rename.md`(백그라운드 잡일 때) → Linear
  binding 순으로 진행한다.
