# Branch & Worktree — 상시 요약으로 부족할 때의 함정집

> **기본 규칙은 글로벌 `CLAUDE.md` §브랜치·worktree 에 있다**(trunk/release 라인 · force-push 금지 ·
> `<type>/<issue-id>-<topic>` · worktree 격리 · 착수 push + 상태 전이 · squash-only · back-merge 예외 ·
> node_modules 심링크 금지). 여기 있는 건 **그것만으로는 못 피하는 것**뿐이다 — 실측 함정과 경계 사례.
>
> vendor-neutral 기본값이다. 프로젝트 ADR(예: ADMap `docs/adr/041`)이 인스턴스화하며 충돌 시 프로젝트가 우선.

## 1. 트래커 자동연동은 두 전제가 모두 있어야 걸린다

① 트래커↔GitHub **integration 설치**, ② 브랜치/PR 에 **issue-id 존재**. 하나라도 없으면 자동연동은
일어나지 않고 **수동 갱신이 필수**다(상태 전이 + PR 링크 attachment).

그리고 자동화는 **원격 이벤트**(branch push · PR open · PR merge)에만 반응한다. `git worktree add -b`
/`checkout -b` 는 GitHub 에 아무것도 보내지 않는다 — issue-id 를 제대로 박아도 **push 전까지 이슈는
Backlog 에 그대로** 있다(실측 ADT-313: 로컬 브랜치 생성 후 `git ls-remote --heads` 의 `adt-*` 0개,
상태 Backlog · `startedAt: null`). **"자동연동이 안 걸린다"의 원인은 대개 네이밍이 아니라 이벤트 부재다.**

"branch → In Progress" 자동화는 팀 워크플로 설정에서 켜져 있어야 하고 기본 off 인 경우가 많다 —
토글에 기대지 말고 **직접 전이가 확정 경로**.

## 2. 열린 PR 이 있는 브랜치를 rename 하면 PR 이 닫힌다

`gh api …/branches/{b}/rename`(또는 로컬 rename + force)은 열린 PR 의 head ref 를 따라가지 **않고**
구 브랜치를 삭제해 **PR 을 CLOSED 시킨다**(실측: PR #422 closed → #423 재생성).

**브랜치명은 PR 생성 전에 확정한다.** 이미 PR 이 열린 뒤 연동용으로 바꿔야 하면 rename 후
**새 PR 생성 + 트래커 attachment 교체**가 불가피하다.

## 3. PR base back-merge — 절차와 금지 명령

conflict 해소는 **base 를 head 브랜치로 back-merge** 하는 것이다:
`git fetch origin <base>` → `git merge --no-ff --no-edit FETCH_HEAD` → 해소 → `git push origin <head>`.

- head 가 trunk 인 **release-promotion PR**(`develop`→`main`)에서 이 push 는 "trunk 직접 push 금지"의
  **예외**다 — push 없이는 호스트가 mergeability 를 재계산하지 않는다. 예외 범위는 **back-merge 커밋 한 개뿐**.
- back-merge 커밋은 **squash-only 대상이 아니다** — PR 머지가 아니라 브랜치 동기화다.
- **호스트가 보고한 conflict 가 실제로는 안 날 수 있다**(mergeability 캐시 stale). 실측(review-radar):
  PR 은 conflict 보고 → 로컬 back-merge 는 ort 자동해결(1 file). **자동해결이라도 push 해야** 호스트
  상태가 갱신된다 — "충돌 없었으니 할 일 없음"이 아니다.
- 해소 중 `git reset --hard`·`git checkout .`·`git restore .`·`git stash`·`merge --abort` **금지** —
  무관한 uncommitted 작업을 날린다. 시작 전 `git status` 로 위험 노출부터 확인.
- 버전·릴리스 메타(`package.json` version 등) 충돌은 **release 라인(main) 값이 정답** — trunk 값으로 되돌리지 않는다.

**폐지 기준**: repo 가 release-promotion 모델을 버리면(`main` 단일 trunk) 본 절 삭제.

## 4. 장수 통합브랜치가 만드는 것 — 의미 충돌

feature 브랜치는 trunk 로 **최소 일 1회** 통합하고 동시 활성 <3개를 지향한다(DORA: 짧은 브랜치 수명이
배달성능과 상관). 장수 통합브랜치는 **릴리스 스테이징 한정 예외**이지 기본이 아니다 — 여러 미완 feature 를
장기 적재하면 병렬 브랜치가 base 아닌 **서로에 대해** 발산한다.

그때 나오는 게 **의미(semantic) 머지 충돌**이다: 텍스트는 깨끗한데 시스템이 깨진다(한 브랜치가
`role→tier` 리네임, 다른 브랜치가 `role` 참조). 자동탐지 도구는 미성숙하다(정탐 ~1/3) —
**self-test 커버리지 + 짧은 브랜치 + 잦은 통합**이 유일한 방어다.

버전번호 박은 trunk 이름(`feat/1.2.0`)은 "일시적" 오해를 부르고 장수 통합브랜치로 굳는다.
`main` 이 trunk 뒤로 수백 커밋 뒤처지는 "죽은 main" 도 같은 병의 반대편이다.

## 5. 마이그레이션 — 타임스탬프 prefix + slow-lane

**5a. 파일 충돌 제거.** 신규 마이그는 정수 순차(`030_`) 대신 **`YYYYMMDDHHMMSS_<slug>`**.
두 브랜치가 동시에 추가해도 초 단위로 달라 충돌·수동 리넘버가 구조적으로 소멸한다.
러너는 전체 파일명 PK + lexical `.sort()` 여야 호환(정수 파싱 금지). 기존 정수 파일은 리네임하지 않는다.

**5b. 코드 머지빈도 ≠ 운영DB 적용빈도.** trunk-based 의 "작게 자주 머지"는 **코드**에만 적용된다.
공유 운영DB 는 대체불가·비가역이라 apply 는 별도 단계다.
- 마이그 파일 머지(fast-lane) ↔ 운영DB apply(slow-lane) **분리**.
- 운영 apply 는 자동 `migrate:up` 지양 — 개별 `psql -f` 후 `information_schema` 검증.
  한 PR 에 다수 마이그를 묶지 않는다(apply 순서·롤백 단위 보존).

## 6. CI 타입체크 사각

monorepo 에서 root `build` 가 일부 workspace 만 타입체크하면 나머지 패키지의 tsc 에러가 **green 으로
머지된다**. 모든 workspace 의 typecheck 를 CI required check 로 명시한다(예: web `build` + `api:build`).

## 7. 한계 — CI green 은 "머지 차단됨"이 아니다

PRIVATE repo + GitHub Pro 미보유면 `branch protection`·`ruleset` API 가 **403**이다. 즉 CI 가 red 여도
**GitHub 이 머지를 차단할 권한이 없다** — required check 가 아니라 **advisory**.
검증: `gh api .../branches/main/protection` → `403 Upgrade to GitHub Pro`.

그 전까지 자동 강제는 로컬 `guard-branch-protection` 훅(호출자 머신 한정)뿐이고,
나머지(squash·worktree·CI green)는 **사람·AI 규율**이다. 서버사이드 차단을 원하면 public 전환 또는 Pro 가 전제.

## Anti-patterns

- 버전번호 박은 영구 trunk — 의미충돌·번호충돌 재생산.
- 메인 체크아웃에 plain feature 브랜치 쌓기 — uncommitted 노출 + trunk 위치 흔들림.
- 신규 마이그를 정수 순차 prefix 로 — 병렬 브랜치 충돌·수동 리넘버.
- root build 가 일부 workspace 만 타입체크 — 나머지 tsc 에러 green 머지.
- **CI green 을 "머지 차단됨"으로 착각** — Pro/public 아니면 advisory.
- back-merge push 를 "trunk 직접 push 금지" 위반으로 오인해 멈춤 — §3 예외.
- 호스트가 자동해결로 conflict 를 안 냈다고 back-merge 를 push 안 함 — PR 은 계속 conflict 로 남는다.
- 열린 PR 이 있는 브랜치를 rename — PR 이 닫힌다(§2).

## Related

- 프로젝트 인스턴스: ADMap `docs/adr/041-branch-worktree-strategy.md` (실측 근거 D1~D9).
- `cc-worktree.md` — worktree 웹개발 환경(포트/도메인/.env 툴킷).
- `land-preflight.md` — PR/머지/배포 진입 직전 체크.
