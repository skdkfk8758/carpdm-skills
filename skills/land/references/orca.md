# Orca 통합 (선택) — 감지됐을 때만, 아니면 조용히 스킵

Orca 앱이 이 repo 를 관리 중일 때 land 의 세 지점을 보강한다. **Orca 는 git 을
대체하지 않는다** — orca CLI 에 PR·머지·브랜치·rebase·fetch 명령이 아예 없다(실측:
`orca --help` 전체 서브커맨드에 git porcelain 부재). 그러므로 판정 SSOT 는 언제나
`gh`/`git` 이고, orca 가 주는 것은 (a) 워크트리 메타 (b) Linear 전이 (c) CI 대기
오프로드 셋뿐이다.

## 감지 게이트 — 셋 다 참일 때만 이 파일의 나머지를 적용

1. `command -v orca` 가 존재.
2. `orca status --json` → `result.app.running == true` **그리고** `result.runtime.state == "ready"`.
3. `orca worktree current --json` 이 성공하거나, `orca repo list --json` 에 이 repo 가 있음.

하나라도 거짓이면 **묻지 말고 orca 경로 전체를 생략**한다 — Linear 와 같은 graceful
정책이다. orca 호출이 실패해도 머지·정리를 막지 않는다(note 1줄 남기고 계속).
Orca 를 **띄우지 말 것** — `orca open` 은 앱을 실행하는 부수효과다. 안 떠 있으면 스킵이지
기동 대상이 아니다.

## (a) 워크트리 메타 — Step 1 Discover · Step 6 Report

`orca worktree ps --json` 한 번으로 `git worktree list` 가 못 주는 필드를 얻는다.
**대체가 아니라 보강**이다 — `git worktree list` 는 그대로 돈다(Orca 밖 워크트리는 ps 에
안 나온다).

| 필드 | land 소비 |
|---|---|
| `branch` / `baseRef` | 브랜치↔워크트리 매핑 (path 문자열 대신 `branch:<b>` 셀렉터) |
| `displayName` | Report 의 사람이 읽는 이름 (경로 나열 대신) |
| `workspaceStatus` | 카드 상태 — `todo`/`in-progress`/`in-review`/`completed` |
| `linkedPR {number,state}` | **표시용만** — 아래 금지 항목 |
| `hasAttachedPty`·`liveTerminalCount`·`agents[].state` | 라이브 세션 attach 신호 — 그 워크트리는 건드리지 말 것 |
| `comment` | 진행 메모 |

`ps` 는 전 repo 의 워크트리를 낸다 — `repoId` 또는 `path` 접두로 **현재 repo 만 필터**한다.

**금지 — `linkedPR` 을 판정 근거로 쓰지 말 것.** 이건 Orca 자체 링크지 ground truth 가
아니다(실측: `linkedPR.state: "merged"` 인데 워크트리·브랜치가 살아 있는 행 존재). 브랜치
삭제 판정은 SKILL.md Step 5.2 그대로 `gh pr view <n> --json state` 가 SSOT 다
(verification-safety V1 — "머지된 것 같다"는 증거가 아니다).

**Report 잔여 워크트리 줄**은 경로 나열 대신:

```
잔여 워크트리  land 리뉴얼 (in-progress · 에이전트 1 attach · #451 merged)
```

**머지 후 카드 갱신 (저위험 write).** 머지된 PR 의 head 브랜치를 든 워크트리가 있으면:

```bash
orca worktree set --worktree branch:<headBranch> --workspace-status completed --comment "landed #<n>" --json
```

Orca 메타만 바꾸고 git 은 건드리지 않는다. 실패해도 무시하고 진행(gate 아님).
**워크트리 *제거* 는 여전히 하지 않는다** — `orca worktree rm` 은 land 의 명령이 아니다
(wt-sweep 단독 소관, SKILL.md 안전 경계 표).

## (b) Linear 전이 — Step 5.5 의 MCP 폴백

Linear MCP 가 **있으면 MCP 우선**(`craft-core/references/linear.md` 가 SSOT). MCP 가 없고
Orca 가 감지될 때만 이 경로를 쓴다:

```bash
orca linear team states --json                   # 상태명 실조회 (하드코딩 금지 요건 충족)
orca linear issue --json                         # 본문 — AC 체크박스 스캔용
orca linear status set --current --to <state>    # 전이
```

`--current` 는 **현재 워크트리에 링크된 Linear 이슈**를 대상으로 한다 — Orca 가
`linkedLinearIssue` 를 들고 있어 PR body/브랜치명 파싱보다 정확하다. 메인 체크아웃처럼
링크가 없는 위치에서 돌면 `--current` 대신 이슈 ID 를 직접 준다.

AC 체크박스 처리는 SKILL.md Step 5.5 그대로 — 미체크가 있으면 Done 대신 In Review 로 두고
`⚠ AC 미체크 n건` 표기. MCP·orca 둘 다 없으면 현행대로 전이 생략.

## (c) CI 대기 오프로드 — Step 4, 백그라운드 잡 한정

포그라운드 대화 세션은 **현행 폴링을 유지**한다(단순함이 낫다 — 유저가 보고 있는데 터미널을
띄울 이유가 없다). `$CLAUDE_JOB_DIR` 이 있는 백그라운드 잡에서만 대기를 Orca 터미널로 뺀다:

```bash
orca terminal create --worktree active --title "ci-<n>" --command 'gh pr checks <n> --watch' --json
orca terminal wait --terminal <handle> --for exit --timeout-ms 900000 --json
orca terminal read --terminal <handle> --json     # 종료 사유 확인 — exit 코드만 믿지 말 것
orca terminal close --terminal <handle> --json    # 판정 후 반드시 정리
```

- `--timeout-ms 900000` = SKILL.md 의 **PR당 15분 상한**과 같은 값. 상한 정책 자체는
  SKILL.md 가 SSOT — 여기서 다른 값을 쓰지 말 것. 타임아웃이면 그 PR 을 `## ⚠ 미완`(CI
  지연)으로 넘기고 다음 PR 로 간다.
- 터미널 핸들은 런타임 스코프다. Orca 재시작이나 `terminal_handle_stale` 이면
  `orca terminal list` 로 재취득하거나 **현행 `run_in_background` Bash 폴링으로 폴백**한다.
- 터미널을 남기지 말 것 — 판정 후 `terminal close`. 남은 터미널은 다음 land 실행의 노이즈다.
- `--auto` 머지가 걸려 있으면 `gh pr checks` 종료 후에도 GitHub 머지까지 시차가 있다 —
  종료 판정은 여전히 `gh pr view <n> --json state` 가 `MERGED` 인지로 한다.

## 이 파일이 하지 않는 것

- **git/PR 을 orca 로 대체** — 대응 명령이 없다. Step 0/2/4/5 의 `gh`·`git` 은 그대로다.
- **`orca worktree rm`** — 워크트리 제거는 wt-sweep 단독 소관.
- **승인 게이트 대체** — Step 0 raise 게이트와 Step 3 Confirm 은 그대로(AskUserQuestion /
  백그라운드 텍스트+`needs input:`).
- **`orca open`** — 안 떠 있는 Orca 를 띄우지 않는다.
