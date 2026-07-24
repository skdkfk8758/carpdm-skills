# Sweep 모드 — PR 플로우 없이 워크트리만 정리

`wt-sweep` 스킬의 절차 SSOT. 머지하지도, PR 을 만들지도 않는다 — 발견→분류→
인터뷰→제거만 도는 짧은 경로다. PR 머지·로컬 동기화가 필요하면 land 로 간다.

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
- **라이브 세션 attach + Claude Code 세션 기록**: §세션 기록 정리의 수집 절차를
  여기서 함께 돌린다 — 워크트리별 라이브 attach 여부(제외 근거) + 세션 기록 dir
  존재/크기, 그리고 repo 스코프 고아 세션 dir.

### 2. Classify

| 상태 | 처분 |
|---|---|
| clean + ahead 0 (또는 PR `MERGED`) | 삭제 후보 — 인터뷰에서 "(Recommended)" 표시 |
| dirty | 후보 제외 + Report 플래그. `worktree remove --force` 절대 금지 |
| **라이브 세션 attach** (cwd 매칭) | 후보 제외 + Report 플래그 — 제거하면 그 세션이 깨진다. dirty 와 동급 |
| clean + ahead>0 + PR 없음 | 보존 + 라우팅 — "N커밋 미머지: land(PR화) 또는 명시적 폐기 결정 필요" |
| 열린 PR 있음 | 이 모드 밖 — land 본 플로우로 안내 |

"머지됨 + clean" 은 브랜치 수명 판정일 뿐 **"사용 중 아님"을 보장하지 않는다** —
다른 라이브 세션의 cwd 일 수 있다(guard-worktree-remove 훅이 생긴 실사고). attach
감지(§세션 기록 정리)는 best-effort 필터일 뿐이라, 분류가 아무리 확실해도 제거는
반드시 인터뷰를 거친다.

### 3. Interview (guard-worktree-remove 계약)

- 삭제 후보를 `AskUserQuestion`(multiSelect) 으로 제시 — 워크트리별 한 옵션,
  라벨=경로, description=브랜치 + 판정 근거(clean·ahead 0 등). 후보 0건이면 인터뷰
  없이 Report 로 직행(단 세션 기록 후보만 있으면 Q2 단독으로 인터뷰).
- **세션 기록 후보가 있으면 같은 호출에 두 번째 질문(Q2, multiSelect)으로 얹는다**
  — 규칙은 §세션 기록 정리. 별도 프롬프트 왕복을 만들지 않는다.
- 백그라운드 잡(`$CLAUDE_JOB_DIR` 존재)이면 인터뷰 불가 → 제거 전면 보류(세션
  기록 포함), 목록과 "다음 대화형 세션에서 정리 필요"만 보고.

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
5. **세션 기록 삭제 — Q2 승인분만.** 워크트리 딸린 세션 dir 는 그 워크트리 제거가
   실제로 성공한 경우에만 `rm -rf ~/.claude/projects/<slug>`. 고아 세션 dir 는
   승인만으로 삭제. 세부 규칙(불변식 포함)은 §세션 기록 정리.

### 5. Report (축약)

제거한 워크트리/브랜치, dirty·라이브 attach 로 제외된 것, 미머지로 보존+라우팅
제안된 것, 선택 해제 잔여, 삭제/보존한 세션 기록(건수·용량)을 명시한다 — 아무것도
조용히 빠져나가지 않게. 마지막 줄은 `result:` (output-contract L1), 예:

```
result: 워크트리 2개 정리 (브랜치 2 로컬+remote 삭제, 세션 기록 3건 480MB 삭제) — 미머지 1개 보존(land 필요), dirty 0
```

## 세션 기록 정리 — Claude Code 세션도 워크트리와 함께

워크트리 cwd 마다 Claude Code 가 `~/.claude/projects/<slug>/` 에 세션 기록(jsonl
transcript — `claude --resume` 목록의 실체)을 남긴다. 워크트리만 지우면 이 dir 가
고아로 쌓인다(실측 2026-07-23: `~/.claude/projects` 287개 dir · 1.5GB). 여기 규칙이
SSOT 다.

### 수집 (Discover 에서 함께, 읽기 전용)

- **slug 계산**: 절대경로의 비영숫자를 전부 `-` 로 치환 —
  `printf '%s' "<abs-path>" | sed 's/[^A-Za-z0-9]/-/g'`
  (예: `/Users/x/repo/wt-1` → `-Users-x-repo-wt-1`). 비ASCII 경로는 치환 규칙이
  어긋날 수 있다 — 최종 판정은 항상 `[ -d ~/.claude/projects/<slug> ]` 실존 확인.
- **워크트리별 세션 dir**: slug dir 존재 시 세션 수(`ls *.jsonl | wc -l`)와 크기
  (`du -sh`)를 표에 기록.
- **라이브 attach 감지**: `lsof -d cwd -Fn 2>/dev/null | awk '/^n/{print substr($0,2)}' | sort -u`
  로 전 프로세스의 cwd 를 모아, 워크트리 경로와 같거나 그 아래면 attach 로 판정.
  프로세스명 필터(`-c claude`) 금지 — claude CLI 는 버전 바이너리·Orca 내장 등
  이름이 가변이고(실측), 셸/에디터가 들어앉은 경우도 제거하면 깨진다.
- **고아 세션 dir (repo 스코프)**: `ls ~/.claude/projects/` 에서 repo 루트 slug +
  `-` 프리픽스인 항목 중, ① 현존 워크트리 경로의 slug ② repo 아래 현존 디렉토리
  (`find <root> -type d`, `.git`/`node_modules` prune)의 slug 어느 쪽과도 일치하지
  않는 것 — 이미 제거된 워크트리의 잔재다. 판정이 애매하면(비ASCII 등) 후보에서
  뺀다 — 오탐 삭제보다 잔존이 낫다.

### 불변식

- **세션 기록 삭제는 git 안전망이 없다 — 완전 비가역.** 그래서 자동 삭제 절대
  금지, 인터뷰(Q2) 승인분만, 기본은 보존이다.
- **메인 repo 루트의 세션 dir (`~/.claude/projects/<repo-root-slug>`) 는 절대 후보
  아님** — 지금 이 세션이 그 안에 있다.
- **라이브 attach 판정된 워크트리의 세션 dir 는 Q2 옵션에 올리지 않는다.**
- **Q1 에서 해제된 워크트리의 세션은 Q2 에서 선택돼도 보존한다**(불일치 가드 —
  워크트리는 남기고 기록만 지우는 조합은 사용자가 명시 요청할 때만).

### 인터뷰 Q2 형식

라벨 = 워크트리 디렉토리명(고아는 `(고아) <추정 이름>`), description =
`~/.claude/projects/<slug>` + 세션 N개 · 크기. "(Recommended)" 는 **고아에만** —
방금 제거한 워크트리의 세션은 handoff/이력 가치가 남았을 수 있어 중립 제시.
