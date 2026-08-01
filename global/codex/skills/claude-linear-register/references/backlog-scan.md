# Backlog Scan — 팀 스코프 + 미완 이슈 전수 수집 (SSOT)

> `linear-groom`(Step 1)·`linear-prioritize`(Step 1~2)가 공유하는 수집 절차 —
> **복제 금지**, 이 파일을 읽고 그대로 적용한다.
> 예외: `linear-register` 자신의 dedup 조회는 의도적으로 **전수가 아니다**
> (상한 100건·최근 갱신순 — `dedup-grouping.md` §1). 여기 절차로 덮어쓰지 말 것.

## A. 팀 스코프 해소

1. **repo 컨텍스트가 있으면 repo-map 역매핑 우선** — `git rev-parse --show-toplevel`
   로 현재 repo 루트(worktree 면 메인 repo) → `~/.claude/linear-repo-map.json` 의
   `teamRoutes[].repo`(없으면 `projectExceptions[].repo`) prefix 매칭 → `teamId`
   (`linear-dispatch.md` 룰과 동형).
2. **매칭 실패 또는 repo 무관 그루밍**이면 `list_teams` — 팀이 하나면 그걸 쓰고,
   여럿이면 어느 팀인지 사용자에게 한 번 확인.
3. 어느 경로든 **멋대로 전 워크스페이스를 긁지 않는다.**

> **team ≠ repo 혼재 주의:** 일부 팀(예 ADM)은 한 팀에 provider/consumer 두 repo
> 이슈가 섞인다. repo-map 의 `note` 를 읽고 이슈 본문으로 현재 repo 소속을 판별한다.
> 현재 repo 작업이 아닌 이슈는 버리지 말고 "다른 repo(cross-team)" 로 명시 구분한다.

## B. 미완 이슈 전수 수집

- `mcp__linear__list_issues {team, limit:100+}`. **미완** = `statusType` 이
  `completed`/`canceled` 가 **아닌** 것(triage·backlog·unstarted·started).
- **`hasNextPage=true` 면 `cursor` 로 다음 페이지를 끝까지 긁어 전수를 확보한다.**
  잘린 채 분석하면 거짓 계획(prioritize)·조용한 누락 그루밍(groom)이 된다.
- **대형 응답은 파일로 오프로드된다**(토큰 한도). 전체를 Read 하지 말고 필요 필드만
  추출한다:

```bash
jq -r '.issues[]
  | select(.statusType=="backlog" or .statusType=="unstarted"
        or .statusType=="started" or .statusType=="triage")
  | [.id, .status, (.project//"NO_PROJECT"), (.parentId//"-"),
     (.projectMilestone.name//"-"), .title] | @tsv' "$FILE" | sort
jq -r '.hasNextPage' "$FILE"   # 페이징 확인
```

- 응답은 **null 필드의 키를 통째 생략**한다(`project` 없는 이슈엔 키 자체가 없음) —
  `//"기본값"`(jq)·`i.get(...)`(python) 류 기본값 처리 필수.

## C. 상세 fetch 정책

- list 의 `description` 으로 충분한 판정(tier 분류·키워드 대조 등)은 추가 fetch 없이.
- **전체 본문·관계가 필요한 이슈만** `get_issue {id}` — 관계(`blockedBy`/`blocks`)는
  list 에 안 실리고, `parentId` 만으론 cross-team 블록을 못 잡는다. 전건 `get_issue`
  는 조회 폭주 — 필요 확정분만.
