# Branch & Worktree Strategy — 범용 trunk-based + worktree 격리

IMPORTANT: 본 룰은 단일 레포(monorepo 포함) trunk-based 워크플로의 **vendor-neutral** 기본값이다. 특정 프로젝트의 ADR(예: ADMap `docs/adr/041`)이 본 룰을 인스턴스화한다 — 프로젝트 룰이 충돌 시 우선. 강제 메커니즘 없음(아래 한계 참조) — 사람·AI 규율 + CI 게이트에 의존.

> 근거: DORA/Accelerate(짧은 브랜치 수명 <1일·동시 활성 <3개가 배달성능과 상관), trunk-based(monorepo 기본값), 장수 통합브랜치 = 머지 통증의 단일 구조원인. 실측 종합은 인스턴스 ADR 참조.

## 1. 브랜치 라인 — 2-line trunk + release

| 브랜치 | 역할 |
|---|---|
| `develop` (또는 default) | 통합 trunk·원격 SSOT. 작은 PR 잦은 통합. CI push 트리거 + dev 자동배포 |
| `main` | release/deploy 라인. 태그(`v*`) push 가 prod 배포 트리거 |

- **버전번호 박은 trunk 이름 금지** (`feat/1.2.0` 류). "일시적" 오해를 부르고 장수 통합브랜치로 굳는다. trunk 는 의미 이름(`develop`).
- `main` 이 trunk 뒤로 수백 커밋 뒤처지는 "죽은 main" 패턴 경계 — release/deploy 라인으로 살아 있게 유지.

## 2. 브랜치 네이밍 — Conventional Commits type + 트래커 이슈ID

`feat/<topic>` `fix/<topic>` `refactor/<topic>` `chore/<topic>` `docs/<topic>`. 머지 메시지 type 과 일치 → 트리아지 스캔성.

### 2a. 이슈가 있으면 브랜치명에 issue-id 포함 (트래커 자동연동)

IMPORTANT: Linear 등 트래커 이슈에 묶인 작업은 **브랜치명에 issue-id 를 박는다** — `feat/<issue-id>-<topic>`
(예: `feat/adt-182-admap-layer-contract`) 또는 트래커가 제안하는 `<user>/<issue-id>-<topic>`
(예: `carpdm/adt-182-…`) 중 택1. issue-id 가 없으면 PR↔이슈 **자동연동이 안 걸려** 이슈가 Backlog 에 남고
PR 이 첨부되지 않는다. `guard-branch-linear-naming` 훅이 브랜치 생성 시 누락을 nudge(비차단).

- **자동연동 전제 2가지**: ① 트래커↔GitHub **integration 설치**, ② 브랜치/PR 에 **issue-id 존재**. 둘 중
  하나라도 없으면 자동연동 안 됨 → **수동 갱신 필수**(상태 전이 + PR 링크 attachment).
- **트래커는 코드 PR 로 자동 안 바뀐다.** PR 생성·머지는 트래커 경계 — 상태(착수→In Progress, 머지+검증→
  Done)와 PR 링크를 **직접** 갱신한다. `guard-linear-state-nudge` 훅이 commit/`gh pr create`/`gh pr merge`
  에서 리마인드(비차단). nudge 는 리마인드일 뿐 — 실제 갱신은 사람/AI 가 한다.

### 2b. 함정 — 열린 PR 이 있는 브랜치를 rename 하면 PR 이 닫힌다

`gh api …/branches/{b}/rename`(또는 로컬 rename+force) 은 열린 PR 의 head ref 를 따라가지 **않고** 구 브랜치를
삭제해 **PR 을 CLOSED 시킨다**(실측: PR #422 closed → #423 재생성). 그러니 **브랜치명은 PR 생성 전에 확정**한다.
이미 PR 이 열린 뒤 연동용으로 이름을 바꿔야 하면, rename 후 **새 PR 생성 + 트래커 attachment 교체**가 불가피하다.

## 3. 머지 정책 — squash-only PR

- PR 기반(base=trunk), **squash 머지만** 허용. repo 설정에서 merge-commit·rebase off.
- trunk·release 라인 **직접 push 금지**, **force-push 예외없이 금지**.
- 선형 히스토리 유지 → 롤백·bisect 단순.

## 4. 짧은 브랜치 — 통합브랜치는 예외

- feature 브랜치는 짧게 살리고 trunk 로 **최소 일 1회** 통합. 동시 활성 브랜치 <3개 지향.
- 장수 통합브랜치는 **릴리스 스테이징 한정 예외**이지 기본이 아니다. 여러 미완 feature 를 장기 적재하면 병렬 브랜치가 base 아닌 서로에 대해 발산 → 머지 충돌·의미충돌 재생산.
- **의미(semantic) 머지 충돌**(텍스트는 깨끗한데 시스템이 깨짐 — 한 브랜치가 `role→tier` 리네임, 다른 브랜치가 `role` 참조)은 자동탐지 도구가 미성숙(정탐 ~1/3). **self-test 커버리지 + 짧은 브랜치 + 잦은 통합**으로 방어.

## 5. Worktree = 모든 새 브랜치 격리의 단일 경로

- 새 브랜치를 만들어 작업을 **격리하는 모든 순간**은 예외 없이 worktree 로 분기(`git worktree add -b <type>/<topic> <dir>`). 파일 수 무관 — 단계 구분 없음.
- 메인 워크트리(레포 루트 체크아웃)는 **항상 trunk(`develop`)** 에 둔다. 메인에 plain feature 브랜치를 만들어 작업하지 않는다.
  - 이유: ① 동시 세션/백그라운드 잡의 `reset`/`checkout` 에 uncommitted 작업이 통째로 노출(commit-isolation 통증), ② `git worktree list` 의 trunk 위치가 흔들려 분기 기준 모호.
- **유일 예외(격리 아님)**: 이미 체크아웃된 브랜치에서 **동일 토픽** 1-2 파일 이어 커밋. 새 브랜치를 만드는 게 아니므로 현 워크트리에서 직접 커밋.
- 워크트리 명은 AI/사람이 짓되 **typed 접두**(`feat/...`) 권장 — 자동 생성명(`worktree-...`)은 `/` 못 써 type prefix 가 죽는다.

### 5a. node_modules 심링크 공유 금지 (npm/Vite/Vitest)

worktree 간 `node_modules` 를 심링크로 공유하면 **Vite/Vitest 모듈해석이 깨진다.** worktree 별 독립 설치가 기본(설치 비용 감수).
- deps 변경 PR 머지 후 main tree 에서 `npm install` 1회는 정상 — `tsx: command not found` 류 부팅실패는 미설치 탓이지 버그 아님.
- 설치 비용이 실제 병목이면 **pnpm 전환**(global virtual store — worktree 마다 심링크만 두어 구조적 해소) 별도 검토.

## 6. 마이그레이션 규율 (DB 있는 프로젝트)

### 6a. 타임스탬프 prefix (파일 충돌 제거)
신규 마이그는 정수 순차(`030_`) 대신 **`YYYYMMDDHHMMSS_<slug>`** prefix. 두 브랜치 동시 추가해도 초 단위로 달라 충돌·수동 리넘버가 구조적으로 소멸. 러너는 전체 파일명 PK + lexical `.sort()` 여야 호환(정수 파싱 금지). 기존 정수 파일은 리네임하지 않음(YAGNI, 혼재 정렬 안전).

### 6b. slow-lane (코드 머지빈도 ≠ 운영DB 적용빈도)
trunk-based 의 "작게 자주 머지"는 **코드**에만 적용. 공유 운영DB 는 대체불가·비가역이라 apply 는 별도 단계.
- 마이그 파일 머지(fast-lane) ↔ 운영DB apply(slow-lane) 분리.
- 운영 apply 는 자동 `migrate:up` 지양 — 개별 `psql -f` apply 후 `information_schema` 검증. 한 PR 에 다수 마이그 묶지 않기(apply 순서·롤백 단위 보존).

## 7. CI 타입체크 사각 — 전 workspace 검증

monorepo 에서 root `build` 가 일부 workspace 만 타입체크하면 나머지 패키지의 tsc 에러가 green 머지된다. **모든 workspace 의 typecheck 를 CI required check 로** 명시(예: web `build` + `api:build`). 인스턴스 ADR 의 #196 사례 참조.

## 8. 한계 — 서버사이드 강제는 GitHub Pro/public 전제

IMPORTANT: PRIVATE repo + GitHub Pro 미보유면 `branch protection`·`ruleset` API 가 **403**(설정 불가). 즉 CI 가 red 여도 **GitHub 이 머지를 차단할 권한이 없다** — required check 가 아니라 **advisory**. 검증: `gh api .../branches/main/protection` → `403 Upgrade to GitHub Pro`.
- 그 전까지 유일한 자동 강제 = 로컬 `guard-branch-protection` 훅(직접 push 차단, 호출자 머신 한정) + 로컬 verify. 나머지(squash·worktree·CI green)는 **사람·AI 규율**.
- 서버사이드 머지차단을 원하면 **repo public 전환 또는 Pro** 가 전제.

## Anti-patterns

- 버전번호 박은 영구 trunk(`feat/1.2.0`) — 의미충돌·번호충돌 재생산.
- 메인 체크아웃에 plain feature 브랜치 쌓기 — uncommitted 노출 + trunk 위치 흔들림.
- worktree 간 node_modules 심링크 공유 — Vite/Vitest 모듈해석 붕괴.
- 신규 마이그를 정수 순차 prefix 로 — 병렬 브랜치 충돌·수동 리넘버.
- root build 가 일부 workspace 만 타입체크 — 나머지 tsc 에러 green 머지.
- CI green 을 "머지 차단됨"으로 착각 — Pro/public 아니면 advisory.

## Related

- 프로젝트 인스턴스 예: ADMap `docs/adr/041-branch-worktree-strategy.md` (실측 근거·D1~D9 SSOT).
- CI/CD 파이프라인 템플릿: `~/.config/cicd-template/` (본 전략의 배포 구현부).
- `~/.claude/rules/commit-isolation.md` — uncommitted 노출 최소화 (§5 근거).
- `~/.claude/rules/cc-worktree.md` — worktree 웹개발 환경(포트/도메인/.env).
