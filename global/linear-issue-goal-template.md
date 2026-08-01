# Goal Prompt — Linear 이슈 구현 (goal worker)

> 재사용 템플릿. `linear-dispatch` 가 **goal** 로 라우팅한 이슈에 사용. `{{PLACEHOLDER}}` 를 launcher 가 채워 백그라운드 goal 잡으로 실행.
> 형식 = deep-prompt 고정 템플릿(Objective/Success/Context/Constraints/Verification/Out of Scope/Done&Report).
> 자율 실행 — Success Criteria 충족까지 루프, 사람 개입 없음. **머지는 안 한다**(human-gate).

## Objective
Linear 이슈 `{{ISSUE_ID}}` 「{{ISSUE_TITLE}}」 을 `{{REPO}}` 에서 구현하고 머지 가능한 PR 까지 연다.

## Success Criteria (측정 가능)
- [ ] 이슈 본문의 acceptance criteria 전부 충족 (Context 참조).
- [ ] 신규/수정 동작에 대한 회귀 테스트 작성·통과.
- [ ] repo verify 게이트 green: `bash .claude/verify.sh` exit 0 (없으면 `npm run build && npm test` exit 0).
- [ ] 변경이 이슈 범위 내 — Out of Scope 침범 0.
- [ ] PR 생성됨(머지 X) + Linear 이슈에 PR 링크 코멘트.

## Context
- repo: `{{REPO}}` / worktree: `{{WORKTREE}}` / branch: `{{BRANCH}}`
- 이슈: `{{ISSUE_ID}}` {{ISSUE_TITLE}}
- acceptance / 본문:
{{ISSUE_BODY}}
- 규약: repo 루트 `CLAUDE.md`/`AGENTS.md` 먼저 읽고 따른다.

## Constraints
- worktree `{{WORKTREE}}` 안에서만 작업. repo 루트(통합 trunk) 직접 편집 금지.
- 브랜치 `{{BRANCH}}` (type + issue-id, 예 `feat/adt-152-...`). squash 전제.
- **머지 금지** — PR 만 연다(머지=사람 게이트).
- karpathy: surgical, 범위 밖 리팩터·추측 라이브러리 금지. 코드/경로 언급 전 Read/Grep.
- 외부 발신·파괴 작업(rm -rf / DROP / force-push) 금지.

## Verification
1. `bash .claude/verify.sh` 실행 (없으면 repo build+test).
2. 작성한 회귀 테스트 단독 실행 통과 확인.
3. FAIL 시 **1회만** 자가수정 후 재검증. 또 FAIL 이면 중단·실패요약 보고 — 무한루프 금지 (`~/.claude/rules/delegated-review-watchdog.md`).

## Out of Scope
- 이슈에 없는 기능·리팩터.
- 머지/배포/Linear 상태 전이(Done) — 사람 몫.
- `linear-repo-map.json`·`linear-dispatch.md` 수정.

## Done & Report
완료 시:
1. PR 열고 URL 확보.
2. Linear `{{ISSUE_ID}}` 에 코멘트: PR 링크 + 1줄 요약 + verify 결과.
3. 사람에게 보고: route=goal · PR URL · verify 통과 여부 · 미해결 있으면 명시. **머지 대기 상태로 종료.**
