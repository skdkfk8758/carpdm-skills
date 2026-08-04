---
name: wt-sweep
description: PR 머지 없이 워크트리만 치우는 경량 정리 — 현재 repo 의 잔여·세션 워크트리(EnterWorktree 가 repo 루트 안에 만든 skdkfk8758/* 류 포함)를 전수 발견 → clean/dirty/미머지/라이브세션attach 분류 → AskUserQuestion 인터뷰 승인 → 워크트리+로컬+remote 브랜치, 그리고 승인 시 해당 Claude Code 세션 기록(~/.claude/projects/<slug>)과 이미 지워진 워크트리의 고아 세션 기록까지 제거한다. dirty·라이브 attach 는 무조건 보존, 미머지 커밋은 보존+라우팅 제안, force 절대 금지, 세션 기록은 인터뷰 승인 없이 절대 삭제 안 함. "워크트리 정리해줘", "세션 워크트리 치워줘", "안 쓰는 worktree 지워줘", "워크트리 청소", "쌓인 워크트리 없애줘", "이 세션이 만든 워크트리 정리", "클로드 세션 기록 정리해줘", "워크트리랑 세션 같이 치워줘", "clean up worktrees", "remove stale worktrees" 에 — 'wt-sweep' 이란 말이 없어도 — 트리거. PR 을 머지하고 로컬 동기화까지 원하면 land, 오래된 문서·로그 정리는 sweep, 구현·수정은 메인 직접 구현.
---

# wt-sweep — 세션 워크트리 청소

이 스킬은 얇은 진입점이다. 정리 절차의 SSOT 는
`references/sweep-mode.md` (`~/.claude/skills/wt-sweep/references/sweep-mode.md`)
— **그 파일을 읽고 그대로 수행한다**(복제 금지 — 절차는 그 한 장에만 둔다).

여기엔 스코프 계약만 둔다:

- **현재 repo(cwd 의 git repo) 한정.** 다른 repo 의 워크트리는 거기서 재실행한다.
- **전수 제시가 기본.** 이 대화 세션이 만들었거나 작업한 워크트리는 후보 표에 그
  사실을 표기하되(1차 후보 근거), `git worktree list` 전수를 함께 제시하고
  사용자가 최종 선택한다 — 자동 판정으로 후보를 좁히지 않는다.
- **머지·PR 생성 안 함.** 열린 PR 이 걸린 워크트리를 만나면 land 를 안내한다.
- **안전 불변식**: dirty·라이브 세션 attach 는 무조건 제외+보고(`--force` 금지),
  미머지 커밋은 보존+라우팅(land PR화 또는 명시적 폐기 결정), 제거는
  AskUserQuestion 인터뷰 승인 후 `GUARD_WORKTREE_OK=1 git worktree remove` 로만
  — 상세는 sweep-mode.md.
- **Claude Code 세션 기록도 정리 범위.** 제거하는 워크트리의
  `~/.claude/projects/<slug>` 세션 dir 와 repo 스코프 고아 세션 dir 를 함께
  후보로 올린다 — 단 git 안전망 없는 완전 비가역이라 인터뷰(Q2) 승인분만 삭제,
  기본은 보존. 절차·불변식은 sweep-mode.md §세션 기록 정리 SSOT.

sweep-mode.md 를 읽을 수 없으면 같은 원리를 직접 적용하되 안전
경계(force 금지·인터뷰 게이트·dirty/미머지 보존)는 동일하게 지킨다.
