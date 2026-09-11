---
name: relay
description: 계획(Claude)과 구현(Codex)을 번갈아 달리는 작업에서 돌아온 주자의 구간을 판정하고 다음 구간을 넘긴다 — 활성 work-order·goal-prompt 의 성공 기준을 git·PR·Linear 실측과 대조해 작업 단위(WU)마다 완료를 판정하고, 새로 완료된 WU 의 검증 명령을 trunk 기준 검증 워크트리에서 다시 돌리고, 남은 WU 를 선행 관계와 파일 겹침으로 병렬 물결로 나눠 담당 호스트(계획=Claude · 구현=Codex)와 새 세션에 붙여넣을 한 줄까지 안내한다. 상태 변경은 로컬 trunk fast-forward 하나뿐이다. "작업 완료했는데 확인해주고 다음작업 가이드해줘", "다 했어 다음 뭐 해", "PR 머지했어 확인해줘", "어디까지 됐는지 판정해줘", "relay", "done with this WU, what's next" 에 트리거. PR 머지·로컬 정리는 land, 워크트리 정리는 wt-sweep, 계획·프롬프트 작성은 goal-prompt·deep-plan, 사람 맥락 복원은 catchup.
---

# Relay — 돌아온 구간을 판정하고 다음 구간을 넘긴다

계획은 Claude 가, 구현은 Codex 가 번갈아 달린다. 한 주자가 돌아올 때마다 같은 일을 한다: **무엇이 끝났는지 증거로 판정**하고, **다음에 누가 무엇을 동시에 달릴지** 정한다. relay 는 그 한 바퀴를 매번 같은 절차로 돈다.

두 호스트가 같은 결과를 보도록 **진실은 저장소·PR·Linear 에만 있다.** relay 는 판정 결과를 파일로 남기지 않고 매번 다시 계산한다.

## 원칙

- **증거 없는 완료는 없다.** 판정표의 모든 행은 `기준 | 명령 | 관측 | 판정` 을 갖는다. 판정은 `통과`·`실패`·`미실행` 셋 중 하나이며, 돌리지 않은 것은 `미실행` 과 사유로 적는다.
- **바통만 넘긴다.** relay 가 바꾸는 상태는 로컬 trunk 체크아웃의 fast-forward 하나다(Step 5). 머지·브랜치/워크트리 삭제·배포·Linear 상태 전이는 해당 스킬로 안내한다(§라우팅).
- **책갈피는 로컬 trunk 위치다.** Step 0 에서 fast-forward 하기 전의 로컬 trunk SHA 가 "지난번에 본 곳"이다. 이 SHA 부터 `origin/<trunk>` 까지 들어온 머지가 **새로 완료**다. 로컬이 이미 최신이면 최근 24시간 안의 머지를 새로 완료로 본다.

## 절차

### Step 0 — 출발선

1. 저장소 루트와 trunk 를 정한다. trunk 는 레포 `CLAUDE.md`·`AGENTS.md` 의 trunk 표기가 우선이고, 없으면 원격 기본 브랜치다. 원격이 둘이면(예: GitHub origin + GitLab) 둘 다 기록한다.
2. `git fetch --all --prune` 후, trunk 가 체크아웃된 메인 워크트리의 HEAD SHA 를 **책갈피**로 적는다.
3. 호스트를 판별한다 — Claude Code 인지 Codex 인지. 도구 이름만 다를 뿐 절차는 같다(§호스트 경계).

완료 기준: trunk 이름 · 원격 목록 · 책갈피 SHA · `origin/<trunk>` SHA 가 적혀 있다.

### Step 1 — 활성 work-order 모으기

1. `origin/<trunk>` 트리에서 work-order 를 찾는다: `git ls-tree -r --name-only origin/<trunk>` 결과 중 `*work-order*.md`(`.moai/plans/`·`docs/plans/` 우선). 로컬 파일이 아니라 trunk 판을 읽는다 — 로컬 드리프트가 판정을 흔들지 않게 한다.
2. 각 work-order 에서 WU 표·권장 실행 순서·AC 정의·프롬프트 풀패스·"다른 트랙과의 연결"을 읽는다.
3. WU 마다 프롬프트 파일을 열어 추출한다: **브랜치**(`git worktree add -b <branch>`), **선행**, **소스 경로**(백틱 안 파일 경로), **성공 기준**, **검증 명령**(성공 기준 안의 `make …`·`pytest …`·`npm …`·`curl …`), **담당**(editor·fixer·implementer·scout·[HUMAN]).
4. 미완 WU 가 하나라도 있는 work-order 만 **활성**이다. 활성이 없으면 최근 머지·열린 PR 만 요약하고, 다음 계획은 goal-prompt·deep-plan 으로 라우팅한 뒤 끝낸다.

완료 기준: 활성 work-order 전부에 대해 WU 표(ID · 프롬프트 경로 · 브랜치 · 선행 · 소스 경로 · 검증 명령 · 담당)가 빈칸 없이 채워져 있다. 추출하지 못한 칸은 `확인 필요` 로 적는다.

### Step 2 — 실측 모으기

WU 마다 상태를 하나로 정한다: `머지됨(머지 SHA)` · `PR 열림(#번호)` · `브랜치만` · `미착수`.

- PR: GitHub 는 `gh pr list --state all --head <branch> --json number,state,mergedAt,mergeCommit`, GitLab 은 `glab mr list --source-branch <branch>`. 브랜치명이 다르면 PR 제목과 프롬프트 커밋 메시지로 대조한다.
- 원격 브랜치·워크트리: `git for-each-ref refs/remotes`, `git worktree list`.
- Linear: `~/.claude/linear-repo-map.json` 에 이 레포가 있고 Linear MCP 가 있으면 WU 와 연결된 이슈 상태를 읽는다. 매핑이나 MCP 가 없으면 `Linear: 건너뜀(사유)` 한 줄로 끝낸다.

완료 기준: 활성 WU 전부에 상태가 붙어 있고, `머지됨` 은 머지 SHA 가, `PR 열림` 은 번호가 있다.

### Step 3 — 판정

`머지됨` WU 마다 프롬프트의 성공 기준을 항목별로 대조한다.

- **문서형 기준**(파일 존재 · grep 개수 · 문장 일치 · 매핑표)은 `git show origin/<trunk>:<path>` 와 grep 으로 바로 판정한다.
- **코드형 기준**(테스트·빌드·린트)은 Step 4 에서 판정한다. 새로 완료가 아닌 WU 의 코드형 기준은 `이전 판정 유지 — 재실행 안 함` 으로 적는다.
- **운영·브라우저 기준**(배포 후 응답 시간, 화면 확인)은 `미실행 — 운영 검증 WU 담당` 으로 적는다.
- 성공 기준을 넘어선 변경(FROZEN 문서 수정, 범위 밖 파일)은 `git diff --stat <책갈피>..origin/<trunk>` 로 보고 관찰에 적는다.

완료 기준: `머지됨` WU 전부가 판정표에 있고, 모든 행에 명령과 관측이 있다.

### Step 4 — 새로 완료된 WU 의 검증 재실행

1. 대상은 **새로 완료**(원칙 3) 이면서 코드형 기준을 가진 WU 만이다.
2. 검증 워크트리를 재사용한다: 저장소 옆 `<레포>-relay-verify` 가 없으면 `git worktree add --detach <레포>-relay-verify origin/<trunk>` 로 만들고, 있으면 `git -C <레포>-relay-verify checkout --detach origin/<trunk>` 로 옮긴다. 이 워크트리는 커밋하지 않고 지우지도 않는다 — 다음 relay 가 의존성 설치를 재사용한다. 의존성은 이 워크트리 안에 따로 설치한다(워크트리 간 `node_modules` 공유 금지).
3. 프롬프트의 검증 명령을 그대로 실행하고 종료 코드와 핵심 수치(통과/실패 개수)를 적는다. 판정 명령에 `|| true`·`| tail` 을 붙이지 않는다 — 종료 코드가 삼켜진다.
4. 외부 자원이 필요한 명령(로컬 DB·에이전트·운영 API)이 준비되지 않았으면 `미실행 — <필요한 것>` 으로 적는다.

완료 기준: 새로 완료된 코드형 WU 의 검증 명령마다 종료 코드 또는 미실행 사유가 있다.

### Step 5 — 로컬 동기화

메인 워크트리가 trunk 에 있고 추적 파일 변경이 0 이면(`git status --porcelain --untracked-files=no` 가 빈 출력) `git pull --ff-only` 한다. 아니면 하지 않고 이유를 적는다. 미추적 항목(중첩 워크트리 디렉터리 등)은 fast-forward 를 막지 않는다.

완료 기준: 동기화 전후 SHA, 또는 건너뛴 이유.

### Step 6 — 다음 물결

1. **준비 집합**: 선행이 모두 `머지됨` 인 미착수 WU. 트랙 간 선행("다른 트랙과의 연결")도 선행으로 친다. `PR 열림` WU 는 물결에 넣지 않고 land 로 보낸다.
2. **물결 나누기**: 준비 집합 안에서 소스 경로가 겹치는 WU 는 같은 물결에 두지 않는다 — 머지 충돌을 미리 피한다. 겹치면 뒤 물결로 미루고 겹친 경로를 적는다.
3. **호스트 라우팅**: 문서·SPEC·설계·프롬프트 WU(담당 editor, "문서만") → **Claude**(Fable·Opus). 코드·설정 구현 WU(fixer·implementer) → **Codex**(gpt-6-astra). 운영 검증 WU(scout) → 어느 쪽이든, 사람 승인·배포·운영 데이터 적용은 `[HUMAN]` 으로 따로 뺀다. 사용자가 다른 분담을 말하면 그것을 따른다.
4. **우선순위**: 운영에서 지금 깨져 있는 것을 고치는 WU, 그리고 뒤 WU 를 가장 많이 푸는 WU 를 물결 맨 앞에 둔다. 한 줄 근거를 붙인다.
5. WU 마다 붙여넣기 한 줄을 만든다: `다음 프롬프트대로 진행해줘: <프롬프트 절대경로>`.

완료 기준: 준비 집합 전부가 물결에 배정되거나 미룬 이유가 있고, 준비되지 않은 WU 는 막고 있는 선행이 적혀 있다.

### Step 7 — 보고

`references/report-template.md` 의 형식으로 보고한다. 첫 문장은 결론(몇 개가 끝났고, 다음 물결이 몇 개인가)이다. 호스트의 응답 형식 규칙(`~/.claude/rules/response-format.md` 등)이 있으면 그 틀 안에 넣는다.

## 호스트 경계

- 셸·파일 읽기·git·`gh`·`glab` 만으로 전 절차가 돈다. 서브에이전트나 병렬 도구는 없어도 된다.
- Claude Code 는 Bash·Read 를, Codex 는 기본 셸을 쓴다. 사용자에게 물을 일이 생기면 Claude Code 는 AskUserQuestion, Codex 는 한 줄 질문을 쓴다.
- 인증이 없으면(`gh auth status`·`glab auth status` 실패) 그 원격의 PR 판정을 `미실행 — 인증 없음` 으로 두고 계속한다.

## 라우팅

| 이런 상황이면 | 이 스킬로 |
|---|---|
| 열린 PR 을 머지하고 로컬을 정리 | `land` |
| 머지된 WU 의 워크트리·브랜치를 치움 | `wt-sweep` |
| 운영 릴리즈 | `launch` |
| 활성 work-order 가 없어 다음 계획이 필요 | `goal-prompt` · `deep-plan` |
| Linear 백로그 전체의 우선순위 | `linear-prioritize` |
| 사람이 오래 떠나 있다 돌아와 맥락이 필요 | `catchup` |
