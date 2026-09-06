# Global Guidance — Claude Code

> Lean harness. **기본 시스템 프롬프트·`settings.json`·ponytail 이 이미 하는 말은 여기 적지 않는다.**
> 상시 로딩은 이 파일 + 아래 import 1편뿐 — 상세 룰은 `rules-ondemand/`(필요할 때만 Read, 상시 비용 0).
> 프로젝트 `.claude/CLAUDE.md` 가 본 파일을 override (CWD 가까운 것 우선).

@~/.claude/rules/response-format.md

## Language
AI 응답 = 한국어(`settings.json` 이 주입). 코드 주석·문서 = 영어. 커밋 메시지 = 한국어.
기술 용어·코드 식별자는 원문 유지. 한국어 표기는 맞춤법·받침 정확히.

## 진단 — 코드 확인 전 단언 금지
라이브러리·경로·구현을 언급하기 **전에** Read 또는 Grep 으로 실제 소스를 확인한다.
이름·메모리 snapshot 기반 추측 단언 금지. 불확실하면 "확인 필요"라고 명시한다.
앞선 진단이 틀렸음을 발견하면 조용히 덮어쓰지 말고 **명시 철회**한다 — "앞서 X 라고 한 것은 틀렸다, 실제는 Y다".
그 틀린 주장 위에서 이미 수행한 작업(수정·커밋·보고)이 있으면 **파급과 되돌림 필요 여부를 같이** 보고한다.

**결론 전 증거 표.** 인프라 토폴로지·설정 상태·"가능한가" 판정처럼 틀리면 비싼 주장은,
권고를 쓰기 **전에** 표로 먼저 낸다 — `주장 | 실행한 명령 | 출력 발췌 | Verified/Inferred/Unknown`.
Inferred·Unknown 행은 권고 본문에 넣지 않는다(넣으려면 먼저 확인해 Verified 로 올린다).
문서·핸드오버에 실릴 주장이면 예외 없다 — 틀린 주장이 산출물로 굳으면 회수 비용이 몇 배다.

**"불가능"·"막혔다" 는 최후 판정이다.** 선언 전에 인증·우회 경로를 전부 시도하고, 각각의 실제 에러를 적는다:
(1) `gh auth status`/`glab auth status` 와 `~/.config` 의 기존 토큰, (2) 환경변수 PAT(GITHUB_TOKEN·GITLAB_TOKEN),
(3) `gh api`/`glab api` REST 직접 호출, (4) `kubectl port-forward` 로 내부 엔드포인트, (5) Cloudflare Access 서비스 토큰.
다섯 중 무엇을 시도했고 각각 어떤 에러였는지 없이 "못 한다"고 보고하지 않는다.

## 브랜치 · worktree
- trunk = `develop`(원격 SSOT) · `main` = release/deploy 라인. 둘 다 **force-push 금지**.
- 브랜치명 `<type>/<issue-id>-<topic>` — 이슈ID 없으면 트래커 자동연동이 안 걸린다.
- **새 브랜치 격리는 예외 없이 worktree** (`git worktree add -b <type>/<topic> <dir>`). 메인 체크아웃은 항상 trunk.
  유일 예외: 이미 체크아웃된 브랜치에 **동일 토픽** 1-2 파일 이어 커밋.
- 착수 = `git push -u origin <branch>` + 트래커 상태 **직접** In Progress 전이. 로컬 브랜치는 원격 이벤트가 0이라 자동연동이 안 걸린다.
- PR base=trunk, **squash 머지만**. 예외: PR base back-merge(head 브랜치 push)는 허용 — 호스트가 mergeability 를 재계산할 유일 경로.
- worktree 간 `node_modules` 심링크 공유 금지 (Vite/Vitest 모듈해석 붕괴).
- 상세 → `rules-ondemand/branch-worktree-strategy.md`

## 검증 — green 은 가설이다
- 판정 명령에 `|| echo`·`|| true`·`| tail` 금지(종료 코드가 삼켜진다). green 선언 전 자가 점검: **"이 명령이 실패했다면 지금 출력이 달랐을 것인가?"**
- 마이그레이션 exit 0 = "실행됨"이지 "적용됨"이 아니다. 적용 증거는 대상 DB 직접 조회.
- 게이트 green 은 **자기 claim 만** 증명한다 — 타입체크는 런타임을, unit 은 실 DB·브라우저를, 배포 성공은 user outcome 을 증명하지 않는다.
- 이슈의 **수용 기준 = 완료 게이트**. 검증이 체크를 선행하고, 하나라도 미충족이면 PR 생성·머지·Done 전이를 **중지하고 어느 항목이 왜 미충족인지 보고**한다. AC green 은 보안 통과가 아니다(authz·injection·secret 은 AC 밖 — 직교 게이트로 별도 확인).
- **턴 종료 보고 형식은 `rules/response-format.md` §A 가 SSOT** (이 파일이 import 하므로 상시 로드).
  파일 변경·커밋·테스트를 한 턴은 §A 5블록으로 닫는다 — **검증**은 명령 원문+실제 수치,
  **남은 것**은 `[필수]`/`[선택]` 접두 필수(생략 불가, 없으면 "없음"), **다음**은 잔여와 겹치지 않는다.

## 온디맨드 룰 라우팅 (JIT — 상시 로드 안 됨)
**아래 상황에 진입하면 해당 파일을 Read 하고 진행.** 각 행은 요약이지 본문 대체가 아니다.

| 결정 상황 | Read (`~/.claude/rules-ondemand/`) |
|---|---|
| 브랜치·worktree·머지 판단 | `branch-worktree-strategy.md` · `cc-worktree.md` |
| PR·머지·배포 플로우 진입 | `land-preflight.md` |
| DB/테이블/대량 데이터 삭제 직전 | `db-drop-preflight.md` |
| JS ORM/DB 레이어·마이그 apply | `orm-stack.md` |
| `.env*` 수정 | `env-file-discipline.md` |
| Linear 이슈 등록 / 조회 | `linear.md` |
| 브라우저 도구 2회 연속 실패 | `browser-verify-fallback.md` |
| HTML 시안 산출 | `html-mockup-artifact.md` |
| 새 프로젝트 문서 구조 세팅 · SPEC/PLAN 작성 | `knowledge-folders.md` |
| 플러그인 스킬 설치·업데이트·안 보이는 스킬 추적 | `plugin-layout.md` |
| 계획·설계 확정 직전 · 문서 압축/재배열 (paperthin `/hate`·`/prism` 등 유저 전용 12종) | `paperthin-routing.md` |
| 모호한 요청에 인터뷰가 필요할 때 — 어느 인터뷰 스킬로 들어가나(deep-interview·grilling·`/grill-with-docs`·goal-prompt…) | `interview-routing.md` |

## 브라우저 — aside 강제
웹페이지 작업·컨트롤·검증은 **aside MCP**(`mcp__aside__repl`, Playwright 내장) 사용.
claude-in-chrome 통합은 제거됨(`settings.json claudeInChromeDefaultEnabled: false`) + 재등장 대비 훅 차단.
사용자가 실제 Chrome 로그인 세션을 명시 요구할 때만: 설정 `true` + `touch ~/.claude/.allow-chrome-mcp` + 새 세션(끝나면 원복).
2회 연속 실패 시 → `rules-ondemand/browser-verify-fallback.md`.

## 훅 — 차단은 4개뿐, 나머지는 리마인드
차단(`exit 2`): 보호 브랜치 직접 작업 · 파괴 명령(`rm -rf`·`DROP`·force-push) · worktree 삭제 · claude-in-chrome MCP(→ aside).
나머지 훅(파일 크기·verify swallow·Linear 상태·수용 기준 등)은 **stderr nudge** 다 — "막히니까 괜찮다"고 가정하지 말 것.

## 위임
`Agent` 는 사용자가 요청했을 때만. 몇 tool call 이면 메인이 직접 — 자기 작업 더블체크용 위임 금지.
예외: *독립 컨텍스트가 목적*인 검증(적대 리뷰의 역할 분리)은 더블체크가 아니라 역할 분리.

## 메모리
`~/.claude/projects/<cwd-slug>/memory/MEMORY.md` (프로젝트별 auto-load).

## graphify
`/graphify` 입력 시 다른 일보다 먼저 Skill 도구로 `graphify` 호출.
