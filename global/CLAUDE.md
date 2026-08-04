# Global Guidance — Claude Code

> Lean harness. **기본 시스템 프롬프트·`settings.json`·ponytail 이 이미 하는 말은 여기 적지 않는다.**
> 상시 로딩은 이 파일 한 장뿐 — 상세 룰은 `rules-ondemand/`(필요할 때만 Read, 상시 비용 0).
> 프로젝트 `.claude/CLAUDE.md` 가 본 파일을 override (CWD 가까운 것 우선).

## Language
AI 응답 = 한국어(`settings.json` 이 주입). 코드 주석·문서 = 영어. 커밋 메시지 = 한국어.
기술 용어·코드 식별자는 원문 유지. 한국어 표기는 맞춤법·받침 정확히.

## 진단 — 코드 확인 전 단언 금지
라이브러리·경로·구현을 언급하기 **전에** Read 또는 Grep 으로 실제 소스를 확인한다.
이름·메모리 snapshot 기반 추측 단언 금지. 불확실하면 "확인 필요"라고 명시한다.
앞선 진단이 틀렸음을 발견하면 조용히 덮어쓰지 말고 **명시 철회**한다 — "앞서 X 라고 한 것은 틀렸다, 실제는 Y다".
그 틀린 주장 위에서 이미 수행한 작업(수정·커밋·보고)이 있으면 **파급과 되돌림 필요 여부를 같이** 보고한다.

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

### 코드 턴 종료 보고 (2+ 파일 OR 커밋 OR 테스트 실행 시)
존재하는 행만. 박스문자·공백정렬 금지(랩핑되면 깨진다):
```
**결과**
- **변경** — N files (+A/−D) · <브랜치>
- **커밋** — N · <hash>                       (커밋했을 때만)
- **테스트** — <러너 X/X> · <타입체크>         (돌렸을 때만)
- **검증 커맨드** — `<실행한 명령>` → <실제 출력 수치>
- **잔여** — [HUMAN] 남은 수동 확인 · 없으면 "없음" 명시
```
**검증 커맨드 행이 핵심**("됐음" 금지, 실제 출력만). **잔여 행은 생략 불가** — 없으면 "없음"이라 쓴다.
안 한 것의 행을 빈칸·추정으로 채우지 않는다.

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

## 훅 — 차단은 3개뿐, 나머지는 리마인드
차단(`exit 2`): 보호 브랜치 직접 작업 · 파괴 명령(`rm -rf`·`DROP`·force-push) · worktree 삭제.
나머지 훅(파일 크기·verify swallow·Linear 상태·수용 기준 등)은 **stderr nudge** 다 — "막히니까 괜찮다"고 가정하지 말 것.

## 위임
`Agent` 는 사용자가 요청했을 때만. 몇 tool call 이면 메인이 직접 — 자기 작업 더블체크용 위임 금지.
예외: *독립 컨텍스트가 목적*인 검증(적대 리뷰의 역할 분리)은 더블체크가 아니라 역할 분리.

## 메모리
`~/.claude/projects/<cwd-slug>/memory/MEMORY.md` (프로젝트별 auto-load).

## graphify
`/graphify` 입력 시 다른 일보다 먼저 Skill 도구로 `graphify` 호출.
