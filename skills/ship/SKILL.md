---
name: ship
description: carpdm-skills 레포 전용 배포 — 라이브 `~/.claude/skills/` 변경을 repo 로 미러 → PR → CI 대기 → 1회 승인 게이트 → squash 머지 → 로컬 재동기화. "이 스킬 변경 PR 올리고 머지까지", "ship 해줘", "스킬 동기화 배포", "CI 통과하면 머지하고 정리" 에 사용. `sync.sh --push`(CI·승인 게이트 없는 즉시 머지)와 달리 CI 와 승인을 기다린다. 스킬 내용 편집 자체나 범용 PR/워크트리 정리(land)에는 쓰지 말 것.
---

# Ship — 스킬 변경을 PR→CI→머지→정리로 배포

이 레포는 스킬 배포 레포다. 개발 루프는 라이브 `~/.claude/skills/<name>/` 를 편집한
뒤 그것을 repo 로 미러하고 PR 로 올려 머지하는 것. `sync.sh --push` 는 이걸 한방에
하지만 **PR 생성과 동시에 즉시 머지**해 CI·검토 게이트가 없다. ship 은 같은 일을
하되 **CI 통과를 기다리고, 머지 전에 한 번 멈춰 승인을 받는다** — "PR 올리고
land 까지" 를 안전한 한 흐름으로 잇는다.

머지·브랜치 삭제는 거의 비가역이므로 계약은 land 와 같다: 발견하고, PR 을 올리고,
CI 를 기다리고, **플랜을 보여주고 한 번의 승인을 받은 뒤**, 머지하고 정리하고
보고한다. 추측하지 말고, force 하지 말 것.

## 안전 경계

| Action | 입장 |
|---|---|
| **절대 안 함** | `git push --force`, CI 실패/대기 중 머지, master 직접 커밋, dirty 워크트리 `--force` 제거 |
| **한 번 확인 후 실행** | PR 머지, 머지된 sync 브랜치 삭제 |
| **자유롭게 실행** | drift 확인, `sync.sh --pr-only`(미러+PR), `gh pr checks`, master `pull --ff-only` |

CI 가 실패하거나 머지가 막히면: 중단하고, PR·브랜치를 복구 가능한 상태로 남기고,
보고할 것. 머지 안 된 브랜치는 절대 삭제하지 말 것.

## 파이프라인

### 1. Discover — 라이브↔repo drift 확인

무엇을 배포하는지 먼저 본다 (읽기 전용):

- `cd <repo>` 후 `bash sync.sh` (플래그 없음) — 미러 dry 효과로 staged 변경을 보여준다.
  변경이 없으면 `No changes — repo already up to date.` → 배포할 게 없다, 멈추고 보고.
- `git status -sb` / `git log origin/master..HEAD --oneline` — 이미 커밋됐는데 미push
  인 게 있는지.
- 열린 sync PR 이 이미 있는지: `gh pr list --author @me --state open --json number,headRefName`.
  있으면 새로 만들지 말고 그 PR 의 CI 부터 본다 (3 단계로).
- **`skills/` 밖 변경 주의 (이 스킬의 경계).** sync.sh 와 이 스킬의 2 단계는
  `git add -A skills` 만 stage 한다 — 루트 `sync.sh`/`README.md`/`rules/project.md`
  등 `skills/` 밖 변경은 **누락한다**. 그런 메타 변경이 섞여 있으면 ship 으로
  흘리지 말고, 메타 변경을 먼저 수동 커밋(`git add -A` + 브랜치 + PR)한 뒤
  ship 으로 *스킬만* 배포하거나, 한 번에 수동 PR 로 묶는다.

기본 브랜치는 `gh repo view --json defaultBranchRef -q .defaultBranchRef.name` 로 (하드코딩 금지).

### 2. Mirror + open PR — 머지하지 않음

`bash sync.sh --pr-only` 를 실행한다. 이것은 라이브→repo 미러, 타임스탬프 커밋,
`chore/sync-<ts>` 브랜치 push, PR 생성까지 하고 **머지는 하지 않는다**. 출력에서
브랜치명(`BR`)과 PR URL 을 회수해 다음 단계로 넘긴다. 변경이 없으면 sync.sh 가
`No changes` 로 빠지니 그땐 멈추고 보고.

### 3. Wait for CI — 통과를 기다림

`gh pr checks <BR> --watch` 로 체크가 결론날 때까지 기다린다.

- 모든 필수 체크 통과 → 4 단계로.
- **필수 체크가 없으면** `gh pr checks` 가 `no checks` 류로 즉시 반환한다 — 대기 없이
  4 단계로 (이 레포는 현재 CI 가 가벼울 수 있다).
- 체크 **실패** → 머지하지 말 것. 어떤 체크가 왜 실패했는지 보고하고 멈춘다. 브랜치·
  PR 은 그대로 두어 사용자가 고치게 한다 (라이브 수정 → `sync.sh` 재미러 → 같은 PR 갱신).

### 4. Confirm — 하나의 플랜, 하나의 승인

머지 전에 단일 플랜을 보여주고 승인을 받는다 (유일한 게이트):

```
PR #<n> (<BR>) — CI 통과. 머지하면:
  - squash 머지 + remote 브랜치 삭제
  - master pull --ff-only
  - 로컬 sync 브랜치 <BR> 삭제
Proceed?
```

승인 전엔 머지하지 않는다.

### 5. Merge + sync local

1. `gh pr merge <BR> --squash --delete-branch` — squash 머지 + remote 브랜치 제거.
2. `git checkout <default> && git pull --ff-only origin <default>` — master 최신화.
   (여기서 절대 커밋하지 말 것 — branch-protection 가드.)
3. `git branch -d <BR>` 로 로컬 sync 브랜치 삭제. squash 머지라 `-d` 가 거부할 수
   있다(squash 는 브랜치를 조상이 아니게 만든다) — 그땐 `gh pr view <n> --json state`
   로 `MERGED` 를 확인한 뒤 `git branch -D <BR>`. 머지가 그 삭제를 뒷받침한다.
4. `git remote prune origin` 으로 남은 remote-tracking 정리.

sync 브랜치는 항상 단일·독립이라 stack 처리·rebase 는 없다. (여러 PR/워크트리를
범용으로 정리해야 하면 그건 `land` 의 일이다.)

### 6. Report

머지된 PR 번호, CI 결과, 정리된 브랜치를 짧게 요약한다.

마지막 메시지는 `result:` 한 줄로 못 박는다
(`~/.claude/skills/craft-core/references/output-contract.md` L1 — 전 스킬 공통,
백그라운드 잡 완료 신호). self-contained 로 (예:
`result: PR #N 머지 — CI 통과 후 squash, master 동기화, sync 브랜치 정리`). 산출물이
git 상태 변화라 열기 블록(L2)·다음 스킬 제안(L3)은 적용 안 한다. CI 실패나 머지
막힘으로 멈췄으면 `result:` 가 아니라 진행 상태로 보고한다(미납품).

## 이 스킬이 틀린 선택일 때

- 스킬 *내용* 을 작성·수정하려는 것이지 배포가 아닐 때 → 라이브 SKILL.md 직접 편집.
- 이미 머지된 여러 PR/워크트리를 범용으로 정리할 때 → `land`.
- 빠른 경로로 CI·승인 게이트 없이 즉시 머지해도 될 때 → `bash sync.sh --push`.
