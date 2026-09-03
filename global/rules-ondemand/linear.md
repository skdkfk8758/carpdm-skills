# Linear — 조회 스코프 + 등록 진입점

> 조회와 등록은 같은 세션에서 연속으로 일어난다(백로그 훑고 → 빠진 걸 등록). 한 파일로 둔다.

## 1. 조회 — 현재 repo 팀으로 스코프 (역방향)

IMPORTANT: 이슈를 **조회·리스트업**할 때(`list_issues`, 백로그 훑기, "이슈 뭐 있어" 류)는
전 워크스페이스를 긁지 말고 **현재 작업 중인 repo 의 팀으로 좁힌다.**

1. **현재 repo 해소** — `git rev-parse --show-toplevel`(worktree 면 메인 repo 루트). 못 구하면 cwd.
2. **역매핑 repo→team** — `~/.claude/linear-repo-map.json` 의 `teamRoutes[].repo`(없으면
   `projectExceptions[].repo`)가 현재 경로와 일치하는 엔트리 → 그 `teamId`.
   워크트리 경로는 `<repo>/.claude/worktrees/...` 형태이므로 **prefix 매칭**.
3. **스코프 적용** — `list_issues` 에 `teamId` filter. `projectExceptions` 매칭이면 팀 전체가 아니라
   그 `projectId` 로 좁힌다.
4. **예외**
   - 현재 repo 가 맵에 없음 → 전체 조회로 폴백하되 **"어느 팀 기준인지 불명 — 전체 조회"임을 출력**하고
     필요하면 팀을 사용자에게 확인.
   - 사용자가 명시적으로 다른 팀/전체를 요청 → 그 지시 우선. 현재-repo 스코프는 기본값이지 강제가 아니다.

예: repo `Intelligence-Auth` → `AUT` 팀 · `Intelligence-SSOT` → `SSO` 팀.

## 2. 등록 — `linear-register` 스킬 필수 경유

IMPORTANT: 이슈를 **생성**하는 모든 경우는 `linear-register` 스킬을 경유한다.
`mcp__linear__save_issue`(생성 = `id` 없이)를 스킬 없이 직접 호출하지 않는다.
"리니어에 등록", "티켓으로 올려줘", "이슈 만들어줘" 류면 — 스킬 이름이 안 나와도 — 이 스킬을 먼저 호출한다.

**직접 호출하면 빠지는 것**: ① repo→팀 라우팅 ② 전 상태 중복 대조 + 생성 전 확인 게이트
③ 의존 체인의 Linear 네이티브 관계 세팅 ④ 본문 계약 검증(`validate_issue_body.py`).
스킬은 feature/bug/research 템플릿 중 가장 작은 것 + team-scope + 기본 state=Backlog 를 emit 한다.
본문 계약 SSOT 는 `~/.claude/skills/linear-register/references/human-issue-writing.md` —
`## 추천`·`## 다음 작업`·kickoff 프롬프트·`[AUTO]`/`[HUMAN]` 은 본문 금지 항목이다.
착수 프롬프트는 등록 시점이 아니라 `goal-prompt` 가 이슈를 읽어 그 자리에서 만든다.

대형 plan/spec 을 여러 이슈로 쪼개야 하면 `deep-plan` 으로 분할한 뒤 개별 등록한다 —
`linear-register` 자체에 분할 모드는 없다.

| 작업 | 경로 |
|---|---|
| 이슈 **등록** | **`linear-register` 스킬** |
| 이슈 **조회** | 위 §1 스코프 규칙 |
| 백로그 재배치·보강 | `linear-groom` 스킬 |

> **예외 — `orca-linear`**: `orca linear create` 는 별도 런타임(Orca IDE CLI)이라 MCP 경유 강제 밖이다.
> Orca 세션에서 티켓을 만들 때만 쓰고, 일반 Claude Code 흐름은 단일 진입점을 따른다.

## 3. 상태는 코드 PR 로 자동 안 바뀐다

트래커 자동연동의 전제·실패 모드는 `branch-worktree-strategy.md` §1 — 요약하면
**integration + issue-id 둘 다 있어야 걸리고, 원격 이벤트(push/PR)가 없으면 아무 일도 안 난다.**
착수(In Progress)·완료(Done) 전이는 **직접** 하는 것이 확정 경로다.

## 강제 (hook — 비차단)

`guard-linear-register-nudge.sh`(PreToolUse `mcp__linear__save_issue`) 가 생성 호출에 stderr nudge.
스킬 자신이 `save_issue` 를 호출하므로 하드 블록은 불가하다 — **리마인드일 뿐, 실제 경유는 AI 가 한다.**
끄기: `GUARD_LINEAR_REGISTER_NUDGE_DISABLE=1`.

## Anti-patterns

- 현재 repo 팀이 맵에 있는데 전 워크스페이스를 긁어 노이즈 유발.
- 폴백 전체 조회를 "어느 팀인지 불명"이라 알리지 않고 조용히 수행.
- `save_issue` 직접 호출로 등록 — 위 4가지가 통째로 빠진다.
- PR 을 올렸으니 상태가 바뀌었을 것이라 가정 — §3.

## Related

- `~/.claude/linear-repo-map.json` — repo↔team 매핑 SSOT.
- `~/.claude/skills/linear-register/SKILL.md` — 등록 스킬 본체.
- `branch-worktree-strategy.md` §1 — 자동연동 전제·이벤트 부재 함정.
