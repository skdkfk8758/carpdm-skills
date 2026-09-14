# Global Guidance — Claude Code

> Lean harness. **기본 시스템 프롬프트·`settings.json` 이 이미 하는 말은 여기 적지 않는다.**
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

## 범위
- 사용자가 문제를 설명·질문·생각 중이면 산출물은 **평가**다 — 보고하고 멈춘다. 고치라고 할 때까지 수정하지 않는다.
- 작업 중 발견한 선재 버그·성능 문제·요청 밖 동작은 요청 동작이 그것 없이 성립하지 않을 때만 고치고, 나머지는 후속으로 보고한다. 모호하면 문구·주변 코드가 가장 직접 지지하는 해석 하나만 구현하고 그 가정을 보고에 적는다.

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
- **턴 종료 보고 형식은 `rules/response-format.md` §A 가 SSOT** (상시 로드). 파일 변경·커밋·테스트를 한 턴은 §A 5블록으로 닫는다.
  `남은 것`·`정리` 판정(세션 경계·남은 것 게이트·worktree 정리 판정)은 `rules-ondemand/response-format-close.md` — §A 를 처음 닫기 전에 Read.
  다음 작업을 제안·체이닝하지 않는다 — 남은 것은 이번 세션 `[필수]` 만, 필수 0건이면 턴 끝에 worktree 삭제 가능 여부를 알린다.

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
| 플러그인 스킬 설치·업데이트·안 보이는 스킬 추적 | `plugin-layout.md` |
| §A 작업 턴의 `남은 것`·`정리` 를 처음 쓰기 직전 | `response-format-close.md` |
| Fable 세션 — 첫 위임·구현 판단 전(절차·라우팅·게이트 해제) | `fable-delegation.md` |
| 복수 스텝 작업 착수·스텝 경계 판단 | `step-cadence.md` |

## 브라우저 — aside 강제
웹페이지 작업·검증은 **aside MCP**(`mcp__aside__repl`). claude-in-chrome 은 `guard-chrome-to-aside.sh` 가 차단한다 — 실제 Chrome 세션이 필요할 때만 `touch ~/.claude/.allow-chrome-mcp` + 새 세션(끝나면 원복). 2회 연속 실패 시 `rules-ondemand/browser-verify-fallback.md`.

## 모델 티어 — 단순은 싸게, 복잡은 비싸게
기본 세션 = opus. 인터뷰·설계·ADR 결정이 주가 되는 세션은 사용자가 `/model fable` 로 연다 — Fable 세션은 구현·대량 탐색·테스트 실행·커밋을 직접 하지 않고 워커에 위임한다(`rules-ondemand/fable-delegation.md` §0 이 SSOT, `guard-fable-cost-gate.sh` 가 차단). opus 세션에는 게이트가 없다.

| 일의 성격 | 누가 | 모델 |
|---|---|---|
| 단순 스텝 — 파일 3개 이하 · 설정값·문구·한 함수 수정 | 메인이 직접 | 세션 모델 |
| 읽기 전용 탐색·grep·로그·클러스터 조회 | `scout` | haiku |
| 문서·주석·테스트 추가 · 기계적 반복 편집 | `editor` | sonnet |
| 단순 변경을 위임해야 할 때(Fable 세션 · 병렬 처리) | `fixer` | sonnet |
| 복잡 구현 — 파일 4개 이상 · 인터페이스/데이터 모델/의존성 변경 · 인증/gitops/마이그레이션/삭제 | `implementer` | opus |
| 적대 리뷰 — gitops·마이그레이션·인증·삭제 변경 뒤 자동 | `reviewer` | opus |
| 관점 리뷰·리서치(Karpathy·Torvalds·Pocock·Hightower·Abramov) | `council-review` · `council-research` | sonnet |

**단순 = 세 조건 전부**: 파일 3개 이하 · 인터페이스/데이터 모델/의존성 무변경 · 인증/gitops/마이그레이션/삭제 아님. 하나라도 어기면 복잡이다 — 한 줄이어도 인가 경계나 설정 의미가 바뀌면 복잡. `Agent` 는 위 표에 해당할 때만 쓴다. 자기 작업 더블체크용 위임 금지 — 독립 컨텍스트가 목적인 리뷰만 예외.

## 짧은 호흡 — 스텝마다 확인
복수 스텝 작업은 착수 전 **3~7 스텝 계획**(스텝당 파일 ≤3·커밋 1)을 제시하고 승인받은 뒤 **스텝 1만** 실행한다. 스텝 끝 = §A 보고 + `다음 스텝` 1줄 + AskUserQuestion. 설계 결정이 나오면 먼저 ADR(`docs/adr/`)에 적고 그것을 목표로 삼는다.
`guard-step-scope.sh` 가 사용자 입력 한 번당 4개째 파일 편집을 차단한다(서브에이전트·`~/.claude`·스크래치패드 면제). 상세 `rules-ondemand/step-cadence.md`.

## 훅 — 차단은 8개뿐, 나머지는 리마인드
차단(`exit 2`): 보호 브랜치 직접 작업 · 파괴 명령(`rm -rf`·`DROP`·force-push) · worktree 삭제 · 시크릿 echo · claude-in-chrome MCP(→ aside) · **Fable 세션 구현 게이트**(§모델 티어) · **스텝 스코프**(사용자 입력당 4개째 파일 편집, §짧은 호흡) · **팀메이트 잔존**(Stop, 1회 — 남은 팀메이트를 `shutdown_request` 로 내리게 되돌린다).
나머지(파일 크기·verify swallow·Linear 상태·수용 기준 등)는 `[guard…]`·`[nudge]` 로 시작하는 **additionalContext 리마인드**다 — 받으면 따르고, "막히니까 괜찮다"고 가정하지 말 것.
새 넛지 훅은 `hooks/guards/lib-emit-context.sh` 로 낸다 — exit 0 + stderr 는 모델에 안 닿는다(2026-09-11 실측).

## graphify
`/graphify` 입력 시 다른 일보다 먼저 Skill 도구로 `graphify` 호출.

## Independent skill execution
Use available native capabilities and independent skills in each host. Do not assume a legacy orchestration runtime is installed. For authorized implementation, continue through verification and PR creation. Merge, deployment, branch/worktree deletion and history deletion require explicit requests covering the action and target; PR authorization alone does not cover them.
