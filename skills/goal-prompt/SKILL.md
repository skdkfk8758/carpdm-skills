---
name: goal-prompt
model: fable
description: 메타프롬프팅으로 자율 에이전트(orca goal 잡·claude -p) 또는 새 대화형 세션이 그대로 먹을 Goal Prompt 파일 1개를 만든다 — 시작부 페르소나, Karpathy 운영 규율, ponytail·paperthin·Matt Pocock 빌드 흐름이 맞물린 Working Method, 사람 없이 판정 가능한 Success Criteria. 부족하거나 결정이 필요한 컨텍스트는 Pocock grilling 규율의 갭 인터뷰(design tree·프론티어 라운드·문항마다 권장답, 사실은 내가 결정은 사용자)로 채우고, 프롬프트 1장 크기를 넘으면 wayfinder·deep-plan·grilling 으로 라우팅한다. "goal 프롬프트 만들어줘", "이 작업 프롬프트로 써줘", "자율 에이전트한테 던질 프롬프트 짜줘", "메타프롬프팅 해줘", "orca 잡에 넣을 프롬프트", "새 세션에 붙여넣을 프롬프트", "write me a goal prompt for X", "turn this into an agent prompt", "/goal-prompt" 에 — 'goal' 이란 말이 없어도 "에이전트에게 시킬 프롬프트" 의도면 — 트리거. 구현 코드는 쓰지 않는다. plan 문서+시안까지 원하면 deep-plan, 번호 매긴 요구사항 spec 은 deep-interview.
---

# Goal Prompt — 메타프롬프팅 → 갭 인터뷰 → 프롬프트 1파일

당신은 **프롬프트를 쓰지, 작업을 하지 않는다.** 사용자가 던진 한 문단은 자율 실행
계약으로는 약하다 — 페르소나가 없어 에이전트가 트레이드오프마다 흔들리고, Success
Criteria 가 없어 done 을 스스로 못 판정하고, 레포 사실이 없어 추측으로 움직인다. 이
스킬은 그 문단을 **한 파일**로 깎는다: Persona → Operating discipline(Karpathy) →
7섹션 계약 → Slices(2+ 슬라이스일 때) → Working Method(ponytail·paperthin·Pocock
결합) → Done & Report. 갭은 인터뷰로 닫고, 못 닫은 갭은 assumption 으로 이름 붙여
싣는다.

**vs `deep-plan`** — 그쪽은 fable×2 debate 로 프롬프트+PLAN+HTML 3파일. 여기는
프롬프트 1파일만, debate 없이 갭 인터뷰 + 2-렌즈 자가검토. deep-plan 경계문이 "goal
프롬프트만 원하면 여기 아님"이라 비워둔 자리다. **vs `mattpocock-skills:grilling`** —
Step 3 은 grilling 규율(design tree·프론티어·권장답)을 7갭 상한으로 돌리는 것이다.
상한을 넘는 트리는 grilling 자체나 `/wayfinder` 로 라우팅한다(Step 3-7).

## SSOT lazy-load — 해당 시점에만 읽는다

| 시점 | 파일 |
|---|---|
| Step 4 조립 | `references/prompt-template.md` (골격 — autonomous 본문 + interactive 부록) |
| Step 4 Working Method · Step 5 렌즈 검토 | `references/working-method.md` (압축문 + 결합표 + 렌즈 체크리스트) |
| Step 7 종료 보고 | `~/.claude/references/craft/output-contract.md` |
| Step 7 다음 스킬 제안 | `~/.claude/skills/deep-interview/references/next-skill-routing.md` |

없으면 그 사실을 한 줄로 말하고 같은 원리를 직접 적용한다.

## 흐름

### Step 0 — Frame (readchk 방식)

- 요청을 **내 말로 재진술**한다. 컨텍스트로 해소되는 건 묻지 않는다. 살아남은
  갈래만 Step 2 갭으로 넘긴다.
- **소비자 판정** — `autonomous`(orca goal 잡·`claude -p`·백그라운드 worker, 사람
  없음) / `interactive`(사람이 새 세션에 붙여넣고 지켜봄). 문맥에 "orca/백그라운드/
  잡/자율/사람 없이" 면 전자, "새 세션/붙여넣기/내가 볼게" 면 후자. 둘 다 없으면
  Step 3 첫 배치에 1문항. 프롬프트 본문은 두 변형이 **같고**, interactive 만 부록
  3~4줄이 붙는다(골격 참조) — 변형 혼재 실수를 구조로 막는다.
- **런 사이징** (modelchk 방식) — 위험·복잡도를 한 번 읽어 `tier`(fast/standard/
  frontier)·`effort`(glance/measured/thorough/exhaustive) 를 정한다. 이 값은 **프롬프트
  본문에 넣지 않는다** — 소비 에이전트는 자기 모델을 못 바꾸고, 이 값을 읽는 launcher
  가 실재하는지 확인된 바 없다. 잡을 띄우는 사람이 보도록 Step 7 보고에만 한 줄.
  벤더 모델명은 쓰지 않는다.

### Step 1 — Ground (Karpathy: 추측 금지)

**입력이 Linear 이슈 키면**(`ABC-123` 꼴) 먼저 `get_issue` 로 본문과 네이티브 관계를
읽는다. `linear-register` 계약상 그 본문은 이 골격을 먹이도록 쓰여 있다 — `## 목적`/
`## 문제`/`## 확인할 질문` → Objective, `## 작업 내용`/`## 조사 범위` → Slices 또는 Step,
`## 재현 방법` → Context(재현 테스트의 입력 — 슬라이스가 아니다, Operating discipline 4),
`## 완료 조건` 체크박스 → **Success Criteria 로 그대로 승격**(판정
가능하게 쓰여 있다는 전제 — 주관 표현이 남아 있으면 `[HUMAN]` 갭으로 올린다), `## 범위
밖` → Out of Scope, `## 참고` → Context 링크. `blockedBy` 가 미완이면 Context 에
`Blocked by` 를 적고, 이슈 URL 을 Context 마지막 줄에 남긴다. 이슈에 없는 것(영향
반경·검증 명령·seam·BASE SHA)은 아래대로 레포에서 실측한다 — 이슈 본문은 그것을
담지 않는 계약이다.

**아래 실측은 `gp-ground` 서브에이전트가 별 컨텍스트에서 수행한다.** 산출물은 짧은
1파일인데 그걸 쓰려고 지침·ADR·러너·prior art 를 다 읽는다 — 읽은 원문이 메인
컨텍스트에 남을 이유가 없다. 글로벌 `CLAUDE.md` §위임의 예외("*독립 컨텍스트가 목적*")에
해당한다: 더블체크가 아니라 컨텍스트 분리가 목적이다.

```
Agent({ name: 'gp-ground', model: 'sonnet', subagent_type: 'general-purpose' })
```

- **`Explore` 를 쓰지 않는다** — 그 에이전트는 "결론만, 파일 덤프는 말고" 가 설계 목적이라
  아래 리터럴 반환 계약과 충돌한다. 브리프 첫 줄에 **읽기 전용**(편집 금지)을 못 박는다.
- **`model` 을 반드시 명시한다.** 생략하면 부모 세션 모델을 상속하는데(실측), 이 스킬은
  `model: fable` 로 핀돼 있어 기계적 읽기에 판단 모델을 쓰게 된다.
- **같은 이름을 다시 spawn 하지 않는다** — latest wins 라 재개 경로가 끊긴다. 재조회는
  Step 3 처럼 `SendMessage({to:'gp-ground'})` 로 한다.
- **인라인으로 하는 경우 둘** — ① 영향 반경이 자명해 Read 2~3콜이면 끝날 때(위임 왕복이
  절감보다 비싸다) ② `Agent` 가 없거나 spawn 이 실패할 때. 어느 쪽이든 그 사실을 Step 7
  보고에 한 줄.

**반환 계약 — 리터럴만, 산문 요약 금지.** Step 1 의 불변식은 "읽지 않은 파일·명령을
프롬프트에 쓰는 것은 실패"인데, 서브가 요약해 넘기면 메인은 읽지 않은 것을 프롬프트에
쓰게 된다. 그래서 `gp-ground` 는 **프롬프트에 그대로 복사될 문자열**만 돌려준다 —
경로, 명령 문자열 원문, seam 식별자, BASE SHA, ADR 번호. "verify 스크립트가 있다" 같은
문장은 실패다("`pnpm verify` → exit 0" 이 정답). 확인 못 한 항목은 채우지 말고
`미확인` 으로 표시해 Step 2 갭으로 올린다.

`gp-ground` 에게 주는 브리프 = 아래 **처음 4항목** + 요청문 원문 + repo 루트. 영향 반경에
한정, 레포 전체 아님. **5항목(소비 환경의 스킬)은 위임하지 않는다** — 그 판정이 세션의
available-skills 목록에 의존하는데 서브에이전트의 목록은 메인과 다를 수 있다. Bash 1콜이라
메인이 직접 한다:

- 지침·어휘·standing 결정: 루트 `CLAUDE.md`/`AGENTS.md`, `CONTEXT.md`, `docs/adr/*`.
  여기서 **페르소나의 우선순위**(정확성/속도/호환…)를 읽어낼 수 있으면 페르소나는
  `[CODE]` 갭이다 — 묻지 않는다.
- 검증 수단: verify 스크립트, 테스트 러너·타입체크·린트의 **실제 명령 문자열**.
  프롬프트 Verification 은 이걸 그대로 쓴다.
- 영향 반경: 바뀔 소스 **+ 테스트가 놓일 디렉터리 + lockfile/생성물**(신규 테스트·
  handoff 파일이 범위 침범으로 오판되지 않게 반경에 미리 넣는다). 기존 **seam**
  (테스트가 관측하는 공개 경계)과 유사 테스트(prior art).
- 슬라이스 실측: 작업이 tracer bullet(전 계층 관통·단독 검증·fresh 컨텍스트 하나
  크기) **1개**인지 **2+** 인지. 2+ 면 Step 4 에서 `## Slices` 섹션이 생긴다.
- **브랜치명 (메인이 직접 정한다 — launcher 에 맡기지 않는다):** 이슈 키가 있으면
  `<type>/<issue-id>-<topic>`, 없으면 `<type>/<topic>`(글로벌 브랜치 규약). 프롬프트
  Context 의 `branch:` 에 리터럴로 적는다 — `{{…}}` 가 남은 채 산출되면 소비자가 그
  문자열을 그대로 읽는다(채워 줄 launcher 는 실재 확인된 바 없다).
- 소비 환경의 스킬 **(메인이 직접 — 위임 금지)**: 자동 스킬(`tdd`·ponytail·paperthin 자동 16종)은 컨텍스트의
  available-skills 목록으로, 유저 전용 12종(`hate`·`feynman`…)은 목록에 안 뜨므로
  `test -f ~/.claude/skills/<name>/SKILL.md` 로 존재만 확인(Bash 1콜에 여러 이름 —
  이것이 설치 스킬 Bash 스캔의 유일한 예외). **`code-review` 는 이름 충돌** —
  세션의 `/code-review` 는 빌트인 correctness 리뷰이고 Pocock 2축(Standards+Spec)은
  `~/.claude/skills/code-review/SKILL.md` 에 `Standards` 문자열이 있을 때만이다.
  기본은 2축 인라인(결합표 행 6).

읽지 않은 파일·명령을 프롬프트에 쓰는 것은 실패다 — **위임했어도 마찬가지다.**
`gp-ground` 가 리터럴 대신 산문을 돌려주면 그 항목은 "확인됨" 이 아니라 미확인이다:
한 번만 리터럴을 다시 요구하고(`SendMessage`), 그래도 안 오면 갭으로 올린다. 확인 못 한
건 갭이다. 대상 트리가
dirty 면(남의 미커밋 작업) 실측 기준은 **HEAD 커밋**이다 — 미커밋 코드를 사실로 적으면
소비자가 다른 base 에서 그 파일을 못 찾는다. 기준 SHA 를 Context 에 적는다.

### Step 2 — 초안 + 갭 트리 (Pocock grilling: design tree)

골격을 머릿속에서 채우며 **채울 수 없는 칸**을 갭으로 뽑는다:

- **페르소나 초안** — 직함이 아니라 **무엇을 중시하고 트레이드오프에서 어느 쪽으로
  기우는지**가 알맹이다(예: "결제 경로 담당 — 정확성 > 속도, 모르는 상태는 실패로
  취급"). 레포 문서가 우선순위를 말하면 `[CODE]`(그대로 채움), 아니면 `[HUMAN]`.
- **갭 규칙** — 최대 7건, 영향 큰 순, 각각 **질문 형태의 사실 하나**. 태그 4종:
  `[CODE]` 레포 실측으로 닫힘 · `[DOCS]` 외부 1차 출처(라이브러리·API 동작)로 닫힘 ·
  `[HUMAN]` 결정 — 요청자만 답한다 · `[THIRD]` 답이 요청자가 아닌 제3자에게 있다.
  전형적 `[HUMAN]`: 페르소나(문서 근거 없을 때), Out of Scope 경계, seam 선택(후보
  둘 이상), 성공 판정 수치, **push/PR 생성 권한**(외부 write 는 요청자만 답한다),
  소비자(미판정 시), 2+ 슬라이스를 프롬프트 1개(`## Slices`)로 갈지 N 파일로 쪼갤지.
- **의존 표시 `after:`** — 답이 다른 갭의 옵션이나 존재를 바꾸는 선행 갭을 각 갭에
  적는다. 이것이 design tree 다. 전형: 페르소나 → SC 수치·seam 옵션, 소비자 → push/PR
  권한, 슬라이스 수 → 분할 여부. `after:` 없는 갭이 루트.
- **권장답 의무** — 모든 `[HUMAN]` 갭에 내 권장답 + 근거 한 줄(grounding 실측·페르소나
  우선순위·ponytail 최단 경로 중 무엇에서 왔는지). 권장답을 못 쓰는 갭은 결정 갭이
  아니라 조사 부족이다 — `[CODE]`/`[DOCS]` 로 되돌려 먼저 캔다. 권장답이 있어야 Step 3
  의 "질문 불가 컨텍스트" 에서 assumption 이 추측이 아니라 근거 있는 선택이 된다.

### Step 3 — 갭 인터뷰 (grilling 규율: 사실은 내가, 결정은 사용자, 프론티어 단위 라운드)

1. **사실 갭은 내가 닫고, 블로킹하지 않는다.** `[CODE]` → `gp-ground` 재개
   (`SendMessage`) 또는 인라인 Read/Grep. `[DOCS]` → `mattpocock-skills:research` 가
   있으면 백그라운드로 띄우고(산출 `.md` 경로를 Context 에 인용), 없으면 context7·
   WebFetch 인라인. 사실 갭이 도는 동안 **그것에 `after:` 가 안 걸린 `[HUMAN]` 프론티어를
   먼저 묻는다** — 조사 완료를 기다리며 사용자를 세워두지 않는다. 닫힌 사실은 한 줄로 보고.
2. **프론티어 = `after:` 가 전부 닫힌 `[HUMAN]` 갭. 한 라운드에 프론티어 전부, 그 밖은
   다음 라운드.** 결정형은 `AskUserQuestion` 1콜 최대 4문항 — **첫 옵션 = 권장답에
   `(권장)` 표기, description 에 근거 한 줄**. 생성형(수치·예시·워크플로)은 산문 번호
   목록에 문항마다 `➡️ 권장:` 한 줄. 의존 갭을 같은 라운드에 넣으면 아직 안 들은 답을
   추측한 채 묻는 것이다(실측: 독립 4문항 1콜은 정상 동작). 옵션은 사용자가 이미 말한
   것 또는 코드·문서 실측에서만 — 출처 없으면 산문.
3. **라운드 끝마다 `locked:` 1줄** — 이번까지 확정된 결정 누적 + 답이 새로 연 갭.
   새 갭은 트리에 `after:` 달아 추가(누계 7건 상한 유지). **이미 답한 것을 다시 묻지
   않는다** — 한 답이 다른 갭까지 닫으면 그 사실을 `locked:` 에.
3.5. **답이 반경·seam 을 바꾸면 `gp-ground` 를 재개한다** — `SendMessage({to:'gp-ground'})`
   로 바뀐 seam 주변만 추가 실측을 시킨다(같은 이름 재spawn 금지 — 재개해야 앞서 읽은
   컨텍스트가 살아 있다). 인라인으로 grounding 했으면 여기서도 인라인.
4. **용어 갭 → domain-modeling 방식.** `[HUMAN]` 갭이 과부하 명사("account" 가 둘)·
   `CONTEXT.md` 용어와의 충돌이면 그 문항에 정식 용어 제안을 싣는다(`mattpocock-skills:
   domain-modeling` 의 "challenge against the glossary"). 확정된 용어는 프롬프트 Context
   에 쓰고, `CONTEXT.md` 가 있는 레포면 기록을 **제안만**(쓰기는 승인 후).
5. **`[THIRD]` 는 기다리지 않는다.** 권장답으로 assumption 승격 + 소유자 이름을 적고,
   interactive 면 `/to-questionnaire` 타이핑을 한 줄 제안(사용자 전용 스킬 — 모델이 못
   부른다). 답이 오면 프롬프트 재생성이 아니라 assumption 한 줄 교체.
6. **실행해야만 답이 나오는 갭**(상태 모델이 맞는 느낌인가·UI 가 어떻게 보여야 하나) —
   goal-prompt 는 코드를 쓰지 않으므로 둘 중 하나를 사용자에게: (a) 지금
   `mattpocock-skills:prototype` 으로 답을 얻고 돌아온다(사람이 있을 때만) / (b) 프롬프트
   **Slice 1 을 spike 슬라이스**로 — SC 에 판정 조건, 실패면 partial. 기본은 (b).
7. **라우팅 아웃 — 프롬프트 1장 크기가 아닐 때.** 라운드 3 뒤에도 루트 갭(`after:` 없는)이
   계속 생기거나 갭 누계가 7 을 넘으면 멈추고 `AskUserQuestion` 으로 제안한다: 한 세션에
   안 담기는 안개 → `/wayfinder`(타이핑) · plan+debate 가 필요 → `deep-plan` · 여기서 끝까지
   털고 싶다 → `mattpocock-skills:grilling` 호출(상한 없는 같은 규율 — 끝나면 Step 4 재개,
   재인터뷰 없음). 자동 시작 없음. 사용자가 처음부터 "grill" 이라 했으면 7 번을 먼저.
8. **종료 = 프론티어가 비었을 때.** 탈출구 — "이 정도면 돼" 하면 따른다. 남은 갭은
   **권장답으로** Constraints 의 `assumption:` 에 승격 — 숨기지 않고 이름을 붙인다.
9. **질문 불가 컨텍스트**(이 스킬 자체가 백그라운드 잡 안 — `$CLAUDE_JOB_DIR`, Claude Code
   `--bg` 세션이 세팅하는 변수)면
   인터뷰 없이 `[HUMAN]`·`[THIRD]` 전부 권장답으로 assumption 승격, 보고에 명시.
   권장답 없는 승격은 금지(Step 2 규칙으로 되돌린다).

갭 0건이면 인터뷰를 건너뛰고 그 사실을 한 줄로.

### Step 4 — 조립

`prompt-template.md` 를 이때 읽고 채운다. 규칙:

- **Success Criteria 는 사람 없이 판정 가능한 형태만** — 명령+기대 출력, 테스트
  이름, 파일 존재, 수치. "잘/깔끔/정상" 금지. 주관·외부 승인 항목은 Done & Report
  의 "사람 확인 요청" 으로.
- **범위 검증은 BASE SHA 리터럴 기준** — Working Method 첫 줄이 `git rev-parse HEAD`
  출력을 보고에 리터럴로 적게 하고(셸 변수는 tool call 간 안 남는다), SC 마지막·
  Verification·2축 리뷰가 전부 `git diff --stat <BASE_SHA>` **+ `git status --porcelain`**
  쌍을 쓴다 — diff 는 미추적 신규 파일(새 테스트·handoff)을 안 보여준다(실측: 신규
  파일 생성 후 `git diff --stat <SHA>` 출력 0줄). `...HEAD` 는 커밋된 것만 비교하므로
  커밋 전 판정에 쓰지 않는다.
- **2+ 슬라이스면 `## Slices`** — 순서·`Blocked by`·슬라이스별 verify·슬라이스당
  커밋 1. Operating discipline 4 의 `Step → verify:` 목록이 곧 이 섹션이다(따로 짜지
  않음 — 수평 슬라이싱 차단).
- **Working Method 는 `working-method.md` §4 결합표로** — 설치 확인된 스킬은 이름
  발동 + 폴백을 같은 줄에. 폴백 없는 줄은 결합표 위반.
- **길이 — 파일당 4000자 권장(`LC_ALL=en_US.UTF-8 wc -m` 기준, 공백 포함).** 하드
  상한이 아니다. **실측(2026-09-03, Claude Code CLI 2.1.259):** autonomous 소비자는
  `claude --bg "<프롬프트>"` 백그라운드 잡(세션에 `CLAUDE_JOB_DIR` 세팅 — Orca 가 아니라
  Claude Code 의 변수)이고, 12,167자 프롬프트가 잘림 없이 세션 첫 user 메시지로 도착했다
  (트랜스크립트 문자 수 일치). 입력 상한은 셸 `ARG_MAX`(macOS `getconf` 1,048,576 바이트)
  뿐 — 4000 은 소비 에이전트의 집중을 위한 권장이지 시스템 한도가 아니다. 원칙 전문을
  붙여넣지 않는다. 권장을 넘으면 순서대로 압축 — ① Context 실측 인용 → 경로 포인터,
  ② Working Method 결합표 줄의 설명 prose 삭제(발동+폴백만 남김), ③ 그래도 크면
  슬라이스 경계로 N 파일 분할(Step 6). 압축이 실측·SC 를 깎으면 길이를 택하지 않는다.
  `LC_ALL` 을 고정하는 이유: `LC_ALL=C` 면 `wc -m` 이 바이트를 세어 한글이 3배로
  잡힌다(실측 5자 → 15).
- 언어: 산문 한국어, 식별자·명령·경로 원문. 사용자가 영어를 원하면 그대로.

### Step 5 — 2-렌즈 자가검토 (+ sip)

`working-method.md` §5 체크리스트를 Karpathy 렌즈·Pocock 렌즈로 한 바퀴, 발견은 즉시
반영. 프롬프트 파일은 artifact 이므로 `sip` 이 설치돼 있으면 여기서 발동(유저 전용
스킬은 부르지 않는다). 사용자가 "철저히/리뷰 붙여" 를 **요청했을 때만** 두 렌즈를
별 `Agent`(read-only, 렌즈 체크리스트 + 초안 경로) 로 병렬 — BLOCKING 만 의무 반영,
왕복 1회.

### Step 6 — 파일 산출

`docs/plans/YYYY-MM-DD-<topic>-prompt.md` (프로젝트가 다른 plan 위치를 쓰면 그곳 —
deep-plan 과 같은 규약이라 하류 도구가 동일 취급). N 파일 분할이면 `-prompt-01.md`… —
뒤 파일의 Context 에 "Blocked by: `-prompt-<N-1>` 의 완료 커밋이 내 BASE" 를 적는다.
**파일 전체가 그대로 goal 칸에 들어간다** — 프론트매터·메타 해설·인터뷰 기록을 넣지
않는다. 인터뷰 결과는 본문(Context/Constraints assumption)에 녹아 있어야 한다.
쓴 뒤 파일마다 `LC_ALL=en_US.UTF-8 wc -m <file>` 을 실행해 출력을 보고에 리터럴로
적는다. 4000 초과면 Step 4 압축 순서를 한 번 적용하고, 그래도 넘으면 그 사실과 사유를
보고에 적고 산출한다(권장이지 게이트가 아니다).

### Step 7 — 종료 보고 + 다음 단계 제안

`output-contract.md`(이때 읽는다): `result:` 1줄 + 산출물 열기 블록 + `AskUserQuestion`
다음 스킬 제안(`next-skill-routing.md` 를 읽어 available-skills 목록에서 재선정).
autonomous → **Orca goal 카드에 파일을 통째로 붙여넣는다**고 짚는다(사용자 조작 —
모델이 띄우는 경로는 없다). `linear-start` 는 후보가 **아니다** — 그 스킬은 이슈 본문에서
자기 worker 프롬프트를 만들지 `-prompt.md` 를 읽지 않는다(SKILL.md 에 소비 기술 0건).
interactive → 새 세션에 붙여넣으라고, 첫 체크포인트(`/hate`)가 어디인지 한 줄.

보고에 싣는 것: 소비자 변형, grounding 경로(`gp-ground` 위임 / 인라인 + 그 이유),
tier/effort(런 사이징 — 잡 띄울 때 참고), 인터뷰 라운드 수·닫은 갭 수(태그별),
assumption 승격 목록(권장답 출처 포함), `[DOCS]` research 산출 경로, 라우팅 아웃 제안
여부(`/wayfinder`·`deep-plan`·grilling), 3 패밀리(ponytail·paperthin·Pocock) 중
**미설치라 인라인으로 대체한 것**, 슬라이스 수.

`result:` emit 뒤 제안하고 **여기서 멈춘다** — 다음 스킬 자동 시작 없음.
