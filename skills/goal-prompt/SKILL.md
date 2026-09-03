---
name: goal-prompt
model: fable
description: 메타프롬프팅으로 자율 에이전트(orca goal 잡·claude -p) 또는 새 대화형 세션이 그대로 먹을 Goal Prompt 파일 1개를 만든다 — 시작부 페르소나, Karpathy 운영 규율, ponytail·paperthin·Matt Pocock 빌드 흐름이 맞물린 Working Method, 사람 없이 판정 가능한 Success Criteria. 부족하거나 결정이 필요한 컨텍스트는 갭 인터뷰로 채운다. "goal 프롬프트 만들어줘", "이 작업 프롬프트로 써줘", "자율 에이전트한테 던질 프롬프트 짜줘", "메타프롬프팅 해줘", "orca 잡에 넣을 프롬프트", "새 세션에 붙여넣을 프롬프트", "write me a goal prompt for X", "turn this into an agent prompt", "/goal-prompt" 에 — 'goal' 이란 말이 없어도 "에이전트에게 시킬 프롬프트" 의도면 — 트리거. 구현 코드는 쓰지 않는다. plan 문서+시안까지 원하면 deep-plan, 번호 매긴 요구사항 spec 은 deep-interview.
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
프롬프트만 원하면 여기 아님"이라 비워둔 자리다.

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

**아래 실측은 `gp-ground` 서브에이전트가 별 컨텍스트에서 수행한다.** 산출물은 4000자
미만 1파일인데 그걸 쓰려고 지침·ADR·러너·prior art 를 다 읽는다 — 읽은 원문이 메인
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

### Step 2 — 초안 + 갭 열거

골격을 머릿속에서 채우며 **채울 수 없는 칸**을 갭으로 뽑는다:

- **페르소나 초안** — 직함이 아니라 **무엇을 중시하고 트레이드오프에서 어느 쪽으로
  기우는지**가 알맹이다(예: "결제 경로 담당 — 정확성 > 속도, 모르는 상태는 실패로
  취급"). 레포 문서가 우선순위를 말하면 `[CODE]`(그대로 채움), 아니면 `[HUMAN]`.
- **갭 규칙** — 최대 7건, 영향 큰 순, 각각 **질문 형태의 사실 하나**, `[CODE]`/
  `[HUMAN]` 태그. 전형적 `[HUMAN]`: 페르소나(문서 근거 없을 때), Out of Scope 경계,
  seam 선택(후보 둘 이상), 성공 판정 수치, **push/PR 생성 권한**(외부 write 는
  요청자만 답한다), 소비자(미판정 시), 2+ 슬라이스를 프롬프트 1개(`## Slices`)로
  갈지 N 파일로 쪼갤지.

### Step 3 — 갭 인터뷰

1. **`[CODE]` 는 내가 닫는다** — Read/Grep 으로. 사용자에게 묻지 않고 한 줄로 보고.
2. **`[HUMAN]` 만 사용자에게.** 결정형은 `AskUserQuestion` 1콜 최대 4문항, 생성형
   (수치·예시·워크플로)은 산문 번호 목록. **페르소나 문항이 다른 갭의 옵션을
   바꾸면 첫 배치 단독** — 그 답("정확성 > 속도")이 SC 수치·seam 옵션을 좌우할 때
   같은 배치에 묶으면 의존 갭을 병렬로 묻는 셈이다. 소비자 문항처럼 다른 갭과
   독립이면 한 배치로(실측: 4문항 1콜이 정상 동작).
   옵션은 사용자가 이미 말한 것 또는 코드 실측에서만 — 출처 없으면 산문.
3. **이미 답한 것을 다시 묻지 않는다.** 한 답이 다른 갭까지 닫으면 그 사실을 한 줄로.
3.5. **답이 반경·seam 을 바꾸면 `gp-ground` 를 재개한다** — `SendMessage({to:'gp-ground'})`
   로 바뀐 seam 주변만 추가 실측을 시킨다(같은 이름 재spawn 금지 — 재개해야 앞서 읽은
   컨텍스트가 살아 있다). 인라인으로 grounding 했으면 여기서도 인라인.
4. **탈출구** — "이 정도면 돼" 하면 따른다. 남은 갭은 Constraints 의 `assumption:`
   으로 승격 — 숨기지 않고 이름을 붙인다.
5. **질문 불가 컨텍스트**(이 스킬 자체가 백그라운드 잡 안 — `$CLAUDE_JOB_DIR`)면
   인터뷰 없이 `[HUMAN]` 전부 assumption 승격, 보고에 명시.

갭 0건이면 인터뷰를 건너뛰고 그 사실을 한 줄로.

### Step 4 — 조립

`prompt-template.md` 를 이때 읽고 채운다. 규칙:

- **Success Criteria 는 사람 없이 판정 가능한 형태만** — 명령+기대 출력, 테스트
  이름, 파일 존재, 수치. "잘/깔끔/정상" 금지. 주관·외부 승인 항목은 Done & Report
  의 "사람 확인 요청" 으로.
- **범위 검증은 BASE SHA 리터럴 기준** — Working Method 첫 줄이 `git rev-parse HEAD`
  출력을 보고에 리터럴로 적게 하고(셸 변수는 tool call 간 안 남는다), SC 마지막·
  Verification·2축 리뷰가 전부 `git diff --stat <BASE_SHA>`(작업트리 대 BASE — 미커밋
  포함)를 쓴다. `...HEAD` 는 커밋된 것만 비교하므로 커밋 전 판정에 쓰지 않는다.
- **2+ 슬라이스면 `## Slices`** — 순서·`Blocked by`·슬라이스별 verify·슬라이스당
  커밋 1. Operating discipline 4 의 `Step → verify:` 목록이 곧 이 섹션이다(따로 짜지
  않음 — 수평 슬라이싱 차단).
- **Working Method 는 `working-method.md` §4 결합표로** — 설치 확인된 스킬은 이름
  발동 + 폴백을 같은 줄에. 폴백 없는 줄은 결합표 위반.
- **길이 — 파일당 4000자 미만(`wc -m` 기준, 공백 포함) 하드 상한.** 원칙 전문을
  붙여넣지 않는다. 초과하면 순서대로 압축 — ① Context 실측 인용 → 경로 포인터,
  ② Working Method 결합표 줄의 설명 prose 삭제(발동+폴백만 남김), ③ 그래도 초과면
  슬라이스 경계로 N 파일 분할(Step 6). 상한은 goal 칸 입력 한도라 넘기면 잘려 들어간다.
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
쓴 뒤 파일마다 `wc -m <file>` 을 실행해 출력을 보고에 리터럴로 적는다 — 4000 이상이면
산출 완료가 아니다(Step 4 길이 압축 순서로 되돌아간다).

### Step 7 — 종료 보고 + 다음 단계 제안

`output-contract.md`(이때 읽는다): `result:` 1줄 + 산출물 열기 블록 + `AskUserQuestion`
다음 스킬 제안(`next-skill-routing.md` 를 읽어 available-skills 목록에서 재선정).
autonomous → 자율 실행 스킬(`linear-start`·orca goal 잡)에 파일을 goal 로 먹인다고
짚는다. interactive → 새 세션에 붙여넣으라고, 첫 체크포인트(`/hate`)가 어디인지 한 줄.

보고에 싣는 것: 소비자 변형, grounding 경로(`gp-ground` 위임 / 인라인 + 그 이유),
tier/effort(런 사이징 — 잡 띄울 때 참고), 닫은 갭 수, assumption 승격 목록, 3 패밀리
(ponytail·paperthin·Pocock) 중 **미설치라 인라인으로 대체한 것**, 슬라이스 수.

`result:` emit 뒤 제안하고 **여기서 멈춘다** — 다음 스킬 자동 시작 없음.
