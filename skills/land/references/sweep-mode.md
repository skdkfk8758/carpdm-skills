# Sweep 모드 — PR 플로우 없이 워크트리만 정리

land 의 cleanup-only 경로. 진입은 둘: ① `wt-sweep` 스킬(정리 전용 트리거), ② land
실행 중 머지할 PR 이 0건인데 잔여 워크트리만 있을 때 자동 분기. Step 0~4(머지
플로우)를 통째로 건너뛰고 아래만 수행한다. 머지하지도, PR 을 만들지도 않는다.

## 왜 별도 경로인가

세션 워크트리(EnterWorktree/agent isolation 산물 — `skdkfk8758/*` 류 브랜치, repo
루트 **안** 디렉토리)는 push 도 PR 도 없다. land 의 자연 경로("올린 PR 랜딩")에 안
걸려 조용히 쌓인다(실측 2026-07-23: ADType 2개 + Intelligence-Auth 1개 방치, 후자는
미머지 8커밋). "워크트리만 치우고 싶다"에 머지 파이프라인 전체는 과하다 — 그래서
발견→분류→인터뷰→제거만 도는 짧은 경로를 둔다.

## 절차

### 1. Discover (읽기 전용, 현재 repo 한정)

- 기본 브랜치: `gh repo view --json defaultBranchRef`. remote 없으면
  `git symbolic-ref refs/remotes/origin/HEAD`, 그것도 없으면 로컬
  develop/main/master 존재 확인 순 — 하드코딩 금지.
- `git worktree list --porcelain` 전수. 메인 워크트리는 후보 아님.
- 각 워크트리에 대해:
  - **dirty**: `git -C <path> status --porcelain` — 비어 있지 않으면 dirty.
  - **ahead**: `git rev-list --count <default>..<branch>` — 0 이면 브랜치의 모든
    커밋이 default 에 포함(안전 삭제 근거). 단 squash 머지로 랜딩된 브랜치는
    ahead>0 이어도 이미 실렸을 수 있다 — PR 이 있으면 `gh pr view <branch>
    --json state` 의 `MERGED` 가 판정 근거다.
  - **remote 잔존**: `git ls-remote --heads origin <branch>`.
  - **열린 PR**: `gh pr list --head <branch> --state open` — 있으면 이 모드 대상이
    아니다(land 본 플로우 안내).
- 이 대화 세션이 만들었거나 작업한 워크트리를 알면 그 사실을 표에 표기한다(1차
  후보 근거). 단 자동 판정으로 후보를 좁히지 않는다 — **전수 제시가 기본**이다.
  컨텍스트가 요약됐을 수 있고, 다른 세션 산물도 같은 정리 시점의 후보다.

### 2. Classify

| 상태 | 처분 |
|---|---|
| clean + ahead 0 (또는 PR `MERGED`) | 삭제 후보 — 인터뷰에서 "(Recommended)" 표시 |
| dirty | 후보 제외 + Report 플래그. `worktree remove --force` 절대 금지 |
| clean + ahead>0 + PR 없음 | 보존 + 라우팅 — "N커밋 미머지: land(PR화) 또는 명시적 폐기 결정 필요" |
| 열린 PR 있음 | 이 모드 밖 — land 본 플로우로 안내 |

"머지됨 + clean" 은 브랜치 수명 판정일 뿐 **"사용 중 아님"을 보장하지 않는다** —
다른 라이브 세션의 cwd 일 수 있다(guard-worktree-remove 훅이 생긴 실사고). 그래서
분류가 아무리 확실해도 제거는 반드시 인터뷰를 거친다.

### 3. Interview (guard-worktree-remove 계약)

- 삭제 후보를 `AskUserQuestion`(multiSelect) 으로 제시 — 워크트리별 한 옵션,
  라벨=경로, description=브랜치 + 판정 근거(clean·ahead 0 등). 후보 0건이면 인터뷰
  없이 Report 로 직행.
- 백그라운드 잡(`$CLAUDE_JOB_DIR` 존재)이면 인터뷰 불가 → 제거 전면 보류, 목록과
  "다음 대화형 세션에서 정리 필요"만 보고.

### 4. Remove — 선택된 것만, 순서 고정

워크트리 → 로컬 브랜치 → remote 순(체크아웃된 브랜치는 삭제 불가라 워크트리 먼저):

1. `GUARD_WORKTREE_OK=1 git worktree remove <path>` — 마커는 인터뷰 승인 후에만
   붙인다. 선부착 금지. 선택 해제된 워크트리는 건드리지 않고 잔여로 보고.
2. `git branch -d <branch>` — ahead 0 이면 조상이라 `-d` 가 통과한다. 거부하면
   squash 랜딩 여부를 `gh pr view <n> --json state`(`MERGED`) 로 확인한 뒤에만
   `-D`. 증거 없으면 브랜치를 보존하고 보고한다 — 그게 진짜 "랜딩 안 됨" 신호다.
3. remote 잔존 시 `git push origin --delete <branch>` (자기 feature/세션 브랜치
   한정, force 아님).
4. `git worktree prune` 으로 마무리.

### 5. Report (축약)

제거한 워크트리/브랜치, dirty 로 제외된 것, 미머지로 보존+라우팅 제안된 것, 선택
해제 잔여를 명시한다 — 아무것도 조용히 빠져나가지 않게. 마지막 줄은 `result:`
(output-contract L1), 예:

```
result: 워크트리 2개 정리 (브랜치 2 로컬+remote 삭제) — 미머지 1개 보존(land 필요), dirty 0
```
