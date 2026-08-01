# Linear Issue Scoping — 이슈 조회는 현재 repo 팀 기준

## Step L — 이슈 리스트업은 현재 프로젝트 기준 (역방향 스코프)

IMPORTANT: Linear 이슈를 **조회·리스트업**할 때(`list_issues`, 백로그 훑기, "이슈 뭐 있어" 류)는 전 워크스페이스를 긁지 말고 **현재 작업 중인 repo 의 팀으로 스코프를 좁힌다**.

1. **현재 repo 해소**: `git rev-parse --show-toplevel` 의 절대경로(worktree 면 메인 repo 루트). 못 구하면 cwd.
2. **역매핑 repo→team**: `~/.claude/linear-repo-map.json` 에서 `teamRoutes[].repo`(없으면 `projectExceptions[].repo`)가 현재 repo 경로와 일치하는 엔트리 → 그 `teamId`. (워크트리 경로는 `<repo>/.claude/worktrees/...` 형태이므로 prefix 매칭 — 경로가 어떤 `repo` 로 시작하면 그 팀.)
3. **스코프 적용**: `list_issues` 에 그 `teamId` 를 filter 로 넣어 조회. `projectExceptions` 매칭(예: ADSimulator_V2)이면 팀 전체가 아니라 그 `projectId` 로 좁힌다.
4. **예외**:
   - 현재 repo 가 맵에 없음 → 전 워크스페이스 조회로 폴백하되 **"어느 팀 기준인지 불명 — 전체 조회"임을 출력**하고, 필요하면 팀을 사용자에게 확인.
   - 사용자가 명시적으로 다른 팀/전체를 요청 → 그 지시 우선(현재-프로젝트 스코프는 기본값일 뿐 강제 아님).

> 예시(적용 형태): repo `Intelligence-Auth` → `AUT` 팀, repo `Intelligence-SSOT` → `SSO` 팀. 즉 그 repo 에서 "이슈 리스트업"은 기본으로 해당 팀 이슈만 조회. (본 룰은 글로벌 — 현재 repo 가 무엇이든 repo-map 역매핑이 기준이다.)

## Anti-patterns
- 현재 repo 팀이 맵에 있는데 전 워크스페이스를 긁어 노이즈 유발.
- 폴백 전체 조회를 "어느 팀인지 불명"이라 알리지 않고 조용히 수행.

## Related
- `~/.claude/linear-repo-map.json` — repo↔team 매핑 SSOT(짝).
- `~/.claude/rules/branch-worktree-strategy.md` §5 — worktree 분기·브랜치 네이밍.
