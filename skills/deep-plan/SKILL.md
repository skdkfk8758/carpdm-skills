---
name: deep-plan
description: 사용자의 요청문을 fable 저자 × fable 비평자(별 좌석) debate 로 깎아 자율 에이전트가 먹을 수 있는 Goal Prompt 로 만들고, 그 과정에서 두 좌석이 지목한 컨텍스트 갭을 인터뷰로 채운 뒤, 프롬프트(`-prompt.md`) + 구현 PLAN(`.md`) + 통합 뷰(`.html`)를 산출하고 빌드하지 않고 멈춘다. 사용자가 plan/설계/기획안/제안서/접근법/로드맵/UI 시안을 원하되 지금 구현은 원하지 않을 때 사용 — "계획 세워줘", "어떻게 만들지 설계해줘", "구현 말고 플랜만", "기획안 만들어줘", "UI 시안 뽑아줘", "design doc 작성", "어떻게 접근할지 정리", "plan this out", "/deep-plan" 같은 표현. 번호 매긴 요구사항 spec 결정화는 deep-interview, 프롬프트 한 덩어리만 필요하면 deep-prompt, 실제 구현/버그수정/기존 동작 변경은 forge/hunt/renew — deep-plan 은 코드를 쓰지 않는다, 프롬프트와 plan 만 쓴다.
---

# Deep Plan — fable×2 debate 메타프롬프팅 → 갭 인터뷰 → PLAN(+시안), 빌드 없음

당신은 **계획을 세우지, 빌드하지 않는다.** 사용자가 던지는 한 문단짜리 요청은 자율
실행 계약으로는 약하다 — 그 약함을 사람이 스스로 보기는 어렵다. 그래서 이 스킬은
**두 좌석의 debate** 로 요청문을 깎는다: fable 서브에이전트가 초안을 쓰고(저자),
**codex CLI**(가용 시 — 다른 모델의 교차 판단) 또는 fable 서브에이전트(폴백)가
skeptic 좌석에서 그것을 공격하며 갭을 보태고(적대 비평자 — Step 2 경로 규칙), 갭
union 만큼 사용자를 인터뷰한 뒤, 저자가 반영하고 비평자가 최종 verdict 를 낸다.
산출물은 셋: 실행 계약인 Goal Prompt(`-prompt.md`), 설계 근거인 PLAN(`.md`),
사람이 보는 통합 뷰(`.html`).

좌석을 나누는 이유: 한 컨텍스트가 자기 초안을 채점하면 승인으로 수렴한다. 별
컨텍스트 + skeptic 역할이어야 채점이 성립하고, 비평 좌석이 **다른 모델**이면
(codex 경로) 공유 맹점까지 잡는다 — fable 폴백은 그보다 약한 장치라는 것을 알고
쓴다(Step 2 이력). **이 debate 가 플랜 적대리뷰의
소유자다** (2026-07-29 — 빌드 파이프라인 Phase 2 는 이 verdict 기록을 보고 재리뷰를
스킵하는 게이트로 축소됐다). TDD 도, 보안 페이즈도, 구현 코드도 없다.

막아야 할 실패 넷: (1) 깎이지 않은 요청문이 그대로 자율 에이전트 goal 칸에 들어가
에이전트가 완료를 판정하지 못하는 것, (2) 갭을 모르는 채 인터뷰가 표류하는 것,
(3) 두 좌석이 스타일 논쟁으로 라운드를 태우는 것(→ BLOCKING 규약 + 고정 왕복),
(4) UI plan 의 `.html` 이 plan 텍스트를 렌더만 하고 *결과 화면*을 안 보여주는 것.

## 경계

- **vs `deep-interview`** — 그쪽은 번호 매긴 요구사항 **spec**(`REQ-F`/`REQ-N`)을
  만들어 빌드 스킬로 라우팅한다. deep-plan 은 실행 프롬프트 + plan + 시안을
  산출하고 멈춘다.
- **vs `deep-prompt`** — 그쪽은 **프롬프트 한 덩어리만**(짧은 명료화 + 고정 템플릿).
  deep-plan 은 debate 로 프롬프트를 깎고 **PLAN·시안까지** 낸다. 사용자가
  "goal 프롬프트만" 원하면 그쪽이 맞다 — 여기로 끌어오지 말 것.
- **vs `forge`/`renew`/`hunt`** — 그쪽은 빌드한다. deep-plan 은 구현 코드를 한 줄도
  쓰지 않는다. 이 debate 의 verdict 기록이 그쪽 Phase 2 스킵 신호다(§Step 5).

## SSOT lazy-load — 해당 분기에 진입할 때만 읽는다

메커니즘은 복제하지 말고 공유 소스를 읽어라(규칙이 한 곳에 살아야 drift 가 없다).
단 **eager 하게 전부 읽지 마라** — 아래 표의 시점에 도달했을 때만 그 파일을 읽는다.
경로 약칭: `cc` = `~/.claude/skills/craft-core/references`, `di` =
`~/.claude/skills/deep-interview/references`, `dp` = `~/.claude/skills/deep-prompt`.

| 읽는 시점 | 파일 |
|---|---|
| Step 0 입력이 Linear 이슈 참조일 때 | `~/.claude/skills/linear-goal/references/routing.md` §goal-ready |
| Step 0 문서 grounding 시 | `cc/context-adr.md` |
| Step 2 비평자 기동 직전 (첫 1회) | `cc/adversarial-review.md` 의 "어떻게 돌리는가" 절 |
| Step 5 PLAN 작성 직전 | `cc/pipeline.md` 의 Phase 1 (plan 섹션 + HTML companion + Eval 패널 규칙) |
| Step 6 UI 목업을 **그릴 때만** | `~/.claude/skills/mockup/references/design-context.md` |
| Step 6 ERD 분기 **진입 시만** | `~/.claude/skills/erd/SKILL.md` + `assets/erd-template.html` + `references/schema-discovery.md` |
| Step 7 종료 보고 직전 | `cc/output-contract.md` |
| Step 7.5 Linear 등록 제안 시만 | `cc/linear.md` |
| Step 8 다음 스킬 추천 직전 | `di/next-skill-routing.md` |

fable 저자에게는 `dp/SKILL.md` 의 "고정 템플릿 채우기"·"검증 가능성 게이트" 절
**경로를 프롬프트에 실어** 서브에이전트가 직접 읽게 한다(메인이 본문을 중계하지
않는다 — 재직렬화 손실 회피). `cc/adversarial-review.md` 에서 가져오는 것은 **리뷰어
기동 규약**(read-only·역할 명시·대상을 경로로·1회)뿐이다. 그 파일의 리뷰 프롬프트·
원장 계약은 이 스킬 것이 아니다 —
가져오지 말 것(debate 는 자체 BLOCKING/SUGGESTION·왕복 규약을 쓴다).

파일이 없으면(해당 스킬 미설치) 그 사실을 말하고 같은 원리를 직접 적용한다.

> 모델 노트: **저자는 세션 모델과 무관하게 항상 fable 서브에이전트다**(메인 겸직
> 금지 — 저자를 orchestrator 편향에서 분리한다). `Agent`(`model: 'fable'`, 미가용
> 시 `'opus'` 재시도 — 폴백 사실 보고)로 띄운다. Step 5 의 PLAN 작성은 종전대로:
> 세션이 최상위 티어(fable/opus 급)면 메인 인라인, 아니면 fable 서브에이전트 위임.
> Step 6 ③ 시안은 티어와 무관하게 **병렬 서브에이전트가 기본**(Step 6 참조).

## 흐름

### Step 0 — Frame & ground

- 작업유형과 한 줄 목표를 사용자에게 되짚는다.
- **Linear 이슈 입력이면 readiness 게이트 먼저.** 입력이 Linear 이슈(ID 언급 또는
  세션 `Linked Linear issue` 배너)면 fetch 후 `routing.md` §goal-ready(이때 읽는다)로
  판정한다. **goal-ready**(실측 증거 + 측정가능 AC + 범위 밖 + 해석 단일 — 4개 전부)
  면 재플래닝은 중복이다 — plan 을 만들지 말고 `linear-goal`(또는 이슈 `## 추천` 의
  실행 스킬) 직행을 `AskUserQuestion` 으로 제안하고 멈춘다. 사용자가 명시적으로
  plan 을 원하면(override) 계속. 4개 미달이면 평소 플로우 — 이슈 본문을 요청문
  입력으로 삼는다. Linear MCP 부재·routing.md 미설치면 게이트 생략(같은 원리 직접
  판단, 그 사실 한 줄 보고).
- **Ground first.** plan 이 건드릴 코드(가능하면 code-graph/LSP, 아니면 영향 반경에
  한정한 Read/Grep — 절대 레포 전체 아님)와 관련 기존 문서(ADR/concept/guide —
  `context-adr.md`)를 scope-read 한다. plan 은 standing 결정을 존중하고, 파일/계약을
  추측이 아니라 실제로 anchor 한다. 이 grounding 요약이 debate 양측 프롬프트의
  `<repo-context>` 로 들어가므로 여기서 부실하면 갭 목록이 부실해진다.
- worktree 는 만들지 않는다 — deep-plan 은 코드를 편집하지 않는다.

### Step 1 — debate ① fable 초안 (저자)

**입력은 사용자의 요청문 원문이다.** 프롬프트 초안을 따로 써 오라고 요구하지
않는다 — 사용자가 스킬을 부를 때 쓴 그 문장이 곧 입력이다.

`Agent` 로 fable 저자를 띄운다(`name: 'dp-author'` — Step 4 반영 때 `SendMessage`
로 같은 에이전트를 재개해 컨텍스트를 유지한다). 프롬프트는 slim 하게 — 본문 대신
경로와 digest 만:

- 요청문 원문(verbatim) + Step 0 grounding digest(경로·계약·standing 결정).
- 템플릿 SSOT 경로: `~/.claude/skills/deep-prompt/SKILL.md` 의 "고정 템플릿
  채우기"(7섹션) + "검증 가능성 게이트"(항목당 5질문) 절을 읽고 따르라고 지시.
- 산출 계약: ① 7섹션 DRAFT PROMPT (소비자 = 사람 없는 자율 에이전트 — Success
  Criteria 가 스스로 done 판정·루프 탈출을 가능하게) ② GAPS — 번호 매김, **최대
  7건**, 영향 큰 순, 각각 질문 형태 한 사실, `[CODE]`(레포 읽으면 답 나옴) /
  `[HUMAN]`(요청자만 답 가능) 태그.

갭 목록 없이 초안만 오면 실패로 친다 — 갭을 요구하는 한 문장으로 한 번 재요청.

### Step 2 — debate ② 적대 비평 (비평자 — codex 우선, fable 폴백)

**비평자 좌석은 codex CLI 가 1차다** — 다른 모델의 독립 판단(교차모델)이 역할
프레이밍보다 강한 독립성 장치이므로, 가용하면 항상 codex 를 쓴다. 프리플라이트
`command -v codex` 실패·미인증·무응답이면 **fable 폴백**(아래)으로 내려가고 폴백
사실을 보고한다.

> **교차모델 좌석 이력.** 2026-07-30 codex *플러그인* 은퇴로 fable×2 가 유일 경로가
> 됐었다("잃은 것: 교차모델성"). 2026-08-01 **plain `codex exec` CLI 직호출**로
> 교차모델 좌석을 복원했다 — 플러그인 없이 동작함을 실측(CLI v0.145.0 ·
> `~/.codex/auth.json` 인증 · stdin 파이프). 플러그인 revert 는 더 이상 복원 경로가
> 아니다.

**codex 경로 (1차):**

- 아래 비평 프롬프트를 **stdin 으로 파이프**해 `codex exec` 를 호출한다 —
  `codex exec -` 형태, Bash **background** 실행.
- **watchdog 의무** — 위임 리뷰 호출이므로 글로벌
  `~/.claude/rules-ondemand/delegated-review-watchdog.md` 를 Read 하고 따른다:
  진행 감시 + **무진행 8분+/hard cap 12분 kill**(임계는 룰이 SSOT — 조이면 정상
  추론 구간을 오판 kill 한다). kill 됐으면 fable 폴백으로 내려간다(정지 아님 —
  deep-plan 은 codex 없이도 완주한다).
- read-only 유지 — 프롬프트의 *"Do not edit, create, or delete any files."* 문장이
  계약이다. codex 산출은 답변 텍스트만 취한다(작업 트리 변경이 감지되면 폐기하고
  fable 폴백).
- Step 4 ④ 최종 verdict 재호출은 **stateless** — 1차 비평 전문 + 최종 프롬프트·
  PLAN **경로**를 다시 실어 새 `codex exec` 로 판정받는다(세션 재개에 의존하지
  않는다 — resume 지원 여부를 단언하지 않음).

**fable 폴백 (codex 불가 시):**

두 번째 fable 서브에이전트를 비평자 좌석에 띄운다 — `Agent`(`model: 'fable'`,
`name: 'dp-critic'`), skeptic 프레이밍 + 아래 산출 계약. 저자(`dp-author`)와 **별
컨텍스트**여야 한다(같은 에이전트에 자기 비평을 시키면 debate 가 아니다).

- **read-only 로 유지** — 프롬프트에 평이한 말로 *"Do not edit, create, or delete any
  files."* 라고 쓴다.
- **역할을 명시하라** — 같은 모델이므로 skeptic 역할 프레이밍이 유일한 독립성 장치다.
  이걸 빼면 비평이 초안 승인으로 수렴한다.

비평 프롬프트는 **두 경로 공통**, compact 한 XML-태그 형태 — fable 초안 전문 +
원 요청문 + repo-context 를 싣고, 산출 계약을 강제한다:

```
<task>
Adversarially critique the draft Goal Prompt below. It was written by a separate
author agent for an autonomous build agent. You are the skeptic seat: your job is
to find what is WRONG or MISSING, not to approve. Review and write only in your
answer — do NOT edit, create, or delete any files.
</task>
<contract>
The deliverable is a Goal Prompt for a FUTURE autonomous build agent that runs
AFTER a separate PLAN document is approved. Any "do not implement" phrasing in
the raw request applies to the current planning session only, NOT to the
prompt's consumer — implementation-oriented Objective/Verification is the
intended contract. Do not flag that as goal inversion.
</contract>
<raw-request>…요청문 원문…</raw-request>
<draft-prompt>…fable 초안 전문…</draft-prompt>
<repo-context>…Step 0 digest — secret·내부 호스트 제외(마스킹)…</repo-context>
<output>
1) CRITIQUE — numbered findings. Tag each item:
   [BLOCKING] = breaks the consumer contract (unverifiable Success Criteria,
   goal inversion, missing loop-exit, contradicts the repo facts). MUST be fixed.
   [SUGGESTION] = style/taste/ordering. Author may reject with one-line reason.
2) GAPS — additional missing facts the draft's gap list did not catch. Same
   rules: at most 7 total across both lists, question form, [CODE]/[HUMAN] tag.
</output>
```

태그 없는 비평 항목이 오면 SUGGESTION 으로 강등 처리한다(의무 반영은 명시적
BLOCKING 만 — 취향 진동 차단). `<contract>` 블록은 생략 금지 — 실측(2026-07-21
첫 debate 런): 이 블록 없이 보내자 비평자가 "구현하지 마"를 소비자 계약으로 오독해
BLOCKING 9건 중 6건이 거짓 goal-inversion 이었다. 계약을 처음부터 실으면 그 노이즈가
안 생긴다.

**동조 감시.** 비평이 BLOCKING 0건 + SUGGESTION 만으로 오면 그게 "초안이 좋다"는
증거가 아니다. 그 경우 **갭 목록이 비어 있는지**로 가른다: 갭도 0건이면 skeptic
프레이밍이 먹지 않은 것이므로 "무엇이 이 초안을 깨뜨리는가" 한 문장으로 **1회
재요청**한다. 재요청도 0건이면 그 사실을 Step 8 보고에 명시한다. 이 감시는 **fable
폴백에서 특히 필수**다(같은 모델의 자기 승인이 주 실패 모드) — codex 경로는
교차모델이라 구조적으로 완화되지만 감시 자체는 생략하지 않는다.

### Step 3 — 갭 인터뷰 (union — 인터뷰 기계는 이것 하나뿐)

저자 갭 + 비평자 갭을 **union·dedup** 한 목록이 인터뷰의 유일한 의제다. 별도
모호성 점수·임계값을 두지 않는다 — **갭 목록 소진**이 종료 게이트다.

1. **`[CODE]` 갭은 내가 닫는다.** Read/Grep 으로 답하고, 사용자에게 묻지 않는다.
   무엇을 어떻게 닫았는지 한 줄로 보고한다.
2. **`[HUMAN]` 갭만 사용자에게 — 독립 갭은 배칭, 의존 갭만 직렬.** 사람 응답
   대기가 총 실행시간의 최대 항목(실측 46m 중 ~21m)이므로, **서로 독립인 갭은 한
   라운드에 묶는다**:
   - **결정형**(답 공간이 닫힘) → `AskUserQuestion` **1콜 최대 4질문**으로 배칭.
     **Anchoring 가드는 질문별로 그대로**: 옵션은 사용자가 이미 말한 것 또는 코드
     실측에서만 도출. 출처 없으면 생성형이니 산문.
   - **생성형**(구체 예시·수치·근거·워크플로 묘사) → 산문 — 역시 독립이면 번호
     목록으로 한 메시지에 묶는다.
   - **의존 갭만 직렬** — 질문 자체가 다른 갭의 답에 따라 달라지는 것. debate 갭은
     사전 열거된 목록이라 대부분 독립이다(질문이 답에서 창발하는 deep-interview 와
     구조가 다름 — 그쪽의 라운드당-1질문 규칙을 여기 가져오지 말 것).
3. **이미 답한 것을 다시 묻지 않는다.** 한 답이 같은 배치의 다른 질문까지 닫으면
   그 답을 우선하고 중복 답은 종합 시 폐기 — 그 사실을 한 줄로 말한다.
4. **라운드 보고 1~2줄** — 방금 닫힌 갭, 남은 갭 수, 다음 조준.
5. **탈출구** — 사용자가 "그만 / 이 정도면 돼" 하면 따른다. 남은 갭은 최종 프롬프트
   Constraints 에 *assumption* 으로, PLAN Risks 에 잔여 리스크로 명시한다.
6. **상한 방어** — union 이 7건을 넘으면 상위 7건만 의제로 삼고, 나머지는
   assumption 승격을 제안한다.

갭이 처음부터 0개면 인터뷰를 통째로 건너뛰고 그 사실을 한 줄로 말한다.

**질문 불가 컨텍스트(자율/백그라운드 — 백그라운드 잡,
`$CLAUDE_JOB_DIR`)에서는 인터뷰를 돌리지 않는다.** `[CODE]` 갭은 평소대로 읽어서
닫고, `[HUMAN]` 갭은 **전부 assumption 으로 승격**해 최종 프롬프트 Constraints +
PLAN Risks 에 명시한 뒤 Step 4 로 간다. 보고에 *"자율 컨텍스트 — [HUMAN] 갭 N건을
assumption 으로 승격"* 을 남긴다. 자율 잡의 "사람 프롬프트 0" 계약을 깨지
않기 위한 분기다.

### Step 4 — debate ③④ 반영 + 최종 verdict (델타 판정 게이트)

**델타 판정 먼저 — 접을 델타가 없으면 여기서 debate 를 끝낸다.** 비평에
BLOCKING 0건 **그리고** 갭 인터뷰·`[CODE]` 보정이 아무것도 바꾸지 않았으면
**fable 초안이 곧 최종 프롬프트다**(2비트 종료 — crisp 요청의 빠른 경로). 스킵
사실을 한 줄 보고하고 Step 5 로 간다.

**소형 plan 적응(3비트) — 델타가 있어도 ④ 를 생략할 수 있다.** 예상 Steps ≤ 3
**AND** BLOCKING ≤ 2 **AND** 보안 표면 없음이면, ③ 반영까지만 돌고 ④ 최종
verdict 를 생략한다 — 메인이 원장(BLOCKING→처리·GAP→답)을 항목별로 자가검증하고
*"3비트 종료(소형 적응) — 최종 채점 생략"* 을 명시 보고한다. 채점 손실이
트레이드오프이므로 **BLOCKING ≥ 3 또는 보안 표면이 있으면 항상 4비트**.

델타가 있으면(소형 적응 비해당 시) 나머지 2비트를 돈다:

- **③ fable 반영** — `SendMessage` 로 `dp-author` 를 재개(컨텍스트 유지), 원장을
  넘긴다: `BLOCKING n → 처리:` / `GAP n → 답:` / `[CODE] GAP n → 코드 실측:` 한
  줄씩. 규칙: **BLOCKING 은 의무 반영**, SUGGESTION 은 재량 — 기각 시 사유 1줄.
  산출 = 최종 7섹션 프롬프트 + 항목별 처리 원장.
- **④ 비평자 최종 verdict — Step 5 PLAN 작성 *후*에 돌린다.** codex 경로면
  **stateless 재호출** — 1차 비평 전문 + 최종 프롬프트·PLAN **경로**를 다시 실어
  새 `codex exec` 로(Step 2 규칙 — watchdog 동일); fable 폴백이면 `SendMessage` 로
  `dp-critic` 을 재개(컨텍스트 유지). 항목별 verdict 를 받는다:
  (a) 자기 BLOCKING·갭이 실제로 닫혔는지, (b) **PLAN 구체 공격** — 각 Step 의
  verify 가 그 Step 을 실제 증명하는지, Files 가 실존하는지(레포 실측 대조),
  Acceptance 가 검증 가능한지, 숨은 가정·누락 엣지·더 단순한 경로.
  채점자가 저자와 **다른 좌석**(별 컨텍스트 + skeptic 역할, codex 면 다른 모델)이라
  이 채점이 성립하고, (b) 가 빌드 파이프라인의 구체-플랜 적대리뷰를 대체한다
  (Phase 2 는 이 verdict 기록을 보고 스킵 — `pipeline.md` Phase 2 판정 2).
  **fable 폴백은 같은 모델이라 채점이 약하다** — 어느 경로든 (b) 의 Files 실존·
  verify 증명력은 verdict 를 믿지 말고 메인이 직접 대조한다(원장 규율,
  `cc/adversarial-review.md`).

**왕복은 고정 2회가 상한이다**(4비트; 델타 0 이면 1왕복 2비트). 수렴까지 돌지
않는다 — verdict 에 미해소 BLOCKING 이 남아도 3왕복 대신 프롬프트 Constraints 의
assumption + PLAN Risks 로 승격시키고 진행한다. 남은 것을 숨기지 말고 이름을 붙여
앞으로 들고 간다. **debate 종료 후 프롬프트를 손봐야 하면**(Step 5 PLAN 작성이
드러낸 어긋남 등) 추가 왕복 없이 메인 Claude 가 직접 수정하고 수정 사실을 보고에
남긴다 — 양측 검증은 debate 종료 시점 산출까지만 커버한다는 것을 안다.

### Step 5 — PLAN 문서 작성

`docs/plans/YYYY-MM-DD-<topic>.md` (프로젝트가 다른 plan 위치를 쓰면 그곳)에 쓴다.
craft Phase 1 섹션(`pipeline.md` — 이때 읽는다)을 따르되, deep-plan 은 빌드하지
않으므로 Steps 와 Acceptance 는 *실행*이 아니라 *무엇을 할지/무엇이 done 인지의
계획*으로 남는다:

```
# <topic>
## Goal (testable success criteria)
## Scope (IN / OUT)
## Files (verified — path : why it changes)   ← Read/Grep 으로 검증, 추측 금지
## Steps (each step → its verify check)
## Risks
## Security surface
## YAGNI (deletions this change would make)
## Acceptance / Eval (numbered, single, checkable; 각 항목에 [AUTO]/[AGENT]/[HUMAN] 태그)
```

열어보지 않은 파일/심볼을 거명하는 것은 실패다. Files 는 실제로 확인한다.

**길이 캘리브레이션 (Claude 5).** PLAN·프롬프트 길이는 내용이 요구하는 만큼만 —
filler 섹션·중복 요약·boilerplate 로 채우지 않는다(Claude 5 계열은 디스크 산출물이
길어지는 경향, 명시 보정).

프롬프트와 PLAN 의 역할 분담: **프롬프트가 실행 계약**(자율 에이전트가 받는 것),
**PLAN 이 설계 근거**(사람이 검토하는 것). "done" 의 **SSOT 는 PLAN 의 Acceptance**
다 — 프롬프트의 Success Criteria/Verification 은 Acceptance 의 `[AUTO]` 항목을
재서술한 것이어야 하며(`[HUMAN]` 항목은 자율 에이전트가 스스로 검증 못 하므로 제외),
항목 수·내용이 어긋나면 프롬프트 쪽을 고친다(Step 4 규칙 — 메인 직접 수정, 추가
왕복 아님). 두 소비자가 같은 장부를 봐야 한다: 자율 에이전트=프롬프트,
빌드 스킬 Phase 4=Acceptance.

**Acceptance 항목이 곧 eval 항목이다** — 빌드 스킬(forge/renew/hunt)이 구현 후
Phase 4 에서 하나씩 검증해 닫을 체크리스트. `[AUTO]`=결정론·회귀·보안·계약(자동
테스트로 잠금), `[AGENT]`=agent 실구동으로 검증 가능(브라우저 조작·curl·CLI —
빌드 스킬이 직접 닫음, 사람 몫 아님), `[HUMAN]`=순수 주관·실계정·외부 승인만
("agent 가 왜 못 하는가" 정당화 의무 — 애매하면 [AGENT]). 태그 규칙 SSOT 는
`pipeline.md` Phase 1. 별도 "eval" 개념을 새로 만들지 말 것 — Acceptance 가 그 자리다.

**debate verdict 를 PLAN 에 기록한다 (스킵 신호 — 의무).** PLAN 작성 직후 Step 4
④(위 규칙 — 최종 프롬프트 + PLAN 함께 채점)를 돌리고, 그 결과를 PLAN 말미에
`## Plan review` 섹션으로 남긴다 — 비트 수(2·3·4), BLOCKING 처리 요약, 미해소
assumption 목록. 2·3비트 종료(④ 생략)면 그 사유를 같은
섹션에 쓴다. 빌드 파이프라인 Phase 2 가 이 섹션의 실존으로 "상류 리뷰 있음"을
판정해 플랜 재리뷰를 스킵한다 — 섹션이 없으면 빌드에서 같은 플랜이 다시
리뷰된다(중복 비용).

### Step 6 — 산출 3파일

같은 디렉토리·같은 basename 으로 셋을 쓴다.

**① `docs/plans/YYYY-MM-DD-<topic>-prompt.md` — 순수 프롬프트.**
파일 전체가 그대로 자율 에이전트 goal 칸에 들어갈 수 있어야 한다. 프론트매터·메타
해설·라운드 기록·경로 안내를 넣지 않는다. 7섹션 본문만.

**② `docs/plans/YYYY-MM-DD-<topic>.md` — PLAN.** Step 5 산출.

**③ `docs/plans/YYYY-MM-DD-<topic>.html` — 통합 뷰 (항상 생성, 병렬 위임 기본).**
①·② 가 디스크에 있으면 ③(과 ERD companion)은 **fable 서브에이전트로 병렬 생성**
한다(`Agent` — ①②·design-context 경로를 프롬프트로 전달, 본문 붙여넣기 금지).
메인은 그동안 Step 4.5 Linear 제안·Step 7 보고를 준비하고, **Artifact publish 는
서브에이전트 완료 후 메인이 한다**(파일 SSOT 는 서브에이전트 산출). ③ 하나뿐이고
소형이면 메인 인라인도 가(위임 오버헤드가 이득을 넘는 경우).
self-contained(inline `<style>`, 외부 asset 0). 세 영역 필수:

- **최종 프롬프트** — 복사 가능한 `<pre>` 블록으로 통째. 사람이 여기서 집어 간다.
- **PLAN 렌더** — 섹션 heading + Steps→verify 표 + 파일 경로 코드 스타일.
- **Eval 체크리스트 패널** — Step 5 의 Acceptance 항목을 `[AUTO]`/`[HUMAN]` 태그와
  함께 렌더. SSOT 는 `.md` 의 Acceptance, 패널은 그 렌더 뷰.

**UI plan 이면 여기에 목업 영역을 더한다.** plan 이 사용자 대면 UI(화면·컴포넌트·
페이지·플로우·보이는 UX 변경)를 전달하면, 구현 후 사용자가 **보게 될 결과 UI 의
목업**을 실제 인터페이스(chrome, pane, 컨트롤, 상태)로 배치하고, UX 를 명확히 하는
곳은 inline `<script>` 로 핵심 인터랙션을 *시연*한다. "mockup" 표식 눈에 띄게.
그리기 전에 `design-context.md`(이때 읽는다)를 따라 프로젝트 DESIGN.md·토큰·기존
화면 어휘를 추출하고 토큰 검증한다 — 시안 즉흥 창작이 구현 괴리의 근원이다.
전문 스킬 라우팅(§6: net-new UI → `frontend-design`, 다안 비교 → `prototype`,
추출 디자인 재현 → `imprint`)은 `AskUserQuestion` 제안만 — 자동 시작 금지, 미설치면
inline 폴백.

**Artifact publish (의무).** `.html` 을 쓴 직후 `Artifact` 도구로 publish 한다.
사용자 리뷰 딜리버러블은 **artifact URL**(로컬 `.html` 은 유지 — 하니스 입력).
갱신 시 같은 파일 경로로 재-publish 해 URL 을 유지한다. 규칙 SSOT:
`~/.claude/rules-ondemand/html-mockup-artifact.md`.

#### ERD companion — plan 이 DB 스키마/BE 데이터 모델을 수반하면 (UI 판정과 별개)

plan 이 **새 테이블·컬럼·관계 또는 BE 데이터 모델 변경**을 수반하면 ERD 를 별도
HTML 로 생성한다 — 비UI plan 이라도 ERD 는 실제 도식 가치를 준다("데이터가 어떻게
엮일지"). 생성 방법은 `erd` 스킬 3파일(이때 읽는다)을 그대로 따른다. 스키마는
Step 0 에서 Read 한 마이그레이션/모델에서 재구성한다(못 본 테이블/관계는 그리지
않고 footer 에 한계 명시). 산출은 같은 디렉토리·basename 에 `-erd.html`, 역시
Artifact publish. 판정: 스키마/관계가 plan 의 핵심이면 그린다 — 컬럼 한둘 추가뿐이면
과투자(생략, plan 텍스트로 족). `erd` 미설치면 그 사실을 말하고 생략.

### Step 7 — 종료 보고 (빌드 없이 제시 — 턴은 여기서 안 끝난다)

`output-contract.md`(이때 읽는다)의 고정 블록으로 보고한다 — `result:` 한 줄 + 각
산출물의 상대경로. 프롬프트·PLAN 행은 항상(`open` 명령 동반), `시안`·`ERD` 행의
딜리버러블은 Step 6 에서 publish 한 **artifact URL** 이다. 예:

```
result: <topic> 프롬프트+PLAN 산출 — fable×2 debate N비트, 갭 N건 해소, N steps, scope IN <…> / OUT <…>

산출물 — 열기:
- 프롬프트 `docs/plans/2026-06-04-<topic>-prompt.md`  →  `open docs/plans/2026-06-04-<topic>-prompt.md`
- PLAN `docs/plans/2026-06-04-<topic>.md`  →  `open docs/plans/2026-06-04-<topic>.md`
- 통합 뷰 `docs/plans/2026-06-04-<topic>.html`  →  <artifact URL>

(`open` = macOS. Linux `xdg-open <path>`, Windows `start <path>`.)
```

Step 2 동조 감시에서 비평이 재요청 후에도 BLOCKING·갭 0건이었으면 그 사실을
`result:` 아래 한 줄로 반드시 덧붙인다(fable 폴백의 주 실패 모드). 비평 좌석이
어느 경로였는지(codex / fable 폴백 + 사유)도 한 줄로.
verdict 에 미해소 BLOCKING 이 assumption 으로 승격됐으면 그 목록도.

**이 보고를 emit 했다고 턴을 끝내지 마라.** "정지"는 빌드 미진입(craft Phase 2+
금지)을 뜻하지 턴 종료가 아니다 — 같은 턴에서 Step 7.5(Linear 등록 제안)와
Step 8(다음 스킬 추천)까지 마친 뒤에만 끝난다. 진짜 정지 지점은 Step 8 말미다.

### Step 7.5 — Linear 작업 등록 (optional, 확인 게이트)

산출물 제시 후, Linear 작업 트리(parent 1 + PLAN Step 당 sub-issue 1)로 등록할지
**제안**한다. 메커니즘은 `cc/linear.md`(이때 읽는다) 그대로 — 단 **이슈 생성 자체는
글로벌 룰(`linear-register-mandatory`)에 따라 `linear-register` 스킬을 경유**한다:
① MCP 감지 — 미설치면 가이드 한 번 + 스킵 제안(막지 않음) ② 만들 트리 미리보기 →
동의받은 **뒤에만** 생성(외부 write 라 자동 등록 금지) ③ 생성 후 이슈 ID/URL 을
PLAN `.md` 에 기록.

**산출물 첨부 (동의 시).** 이슈에 셋을 붙인다:

- `-prompt.md` · `.md` — 파일 업로드: `prepare_attachment_upload` →
  `create_attachment_from_upload` (prepare→PUT→finalize 를 파일당 순차 — 서명 URL
  60초 만료).
- `.html` — Artifact URL 을 `save_issue` 의 `links` 파라미터로 링크 첨부.
- 업로드가 막히면(플랜·권한) 셋 다 링크로 강등하고 그 사실을 말한다.
- **첨부 실패가 등록을 롤백하지 않는다** — 경고만 남기고 진행.

**마스킹 게이트 (첨부 전 필수).** Linear 는 외부 서비스이고 올린 내용은 캐시·인덱싱
돼 삭제해도 남는다. 첨부 직전 산출물에 credential·PII·내부 URL·DB dump 가 박혔는지
검사하고, 발견되면 **첨부를 보류**한 뒤 사유를 보고한다
(`~/.claude/rules/acceptance-criteria-gate.md` G3 동형).

판정: PLAN 이 2+ Step 이면 제안 가치 있음, 1 Step 사소 plan 이면 단일 이슈 또는
생략. 등록 실패/스킵이 deep-plan 의 성공을 깎지 않는다 — 산출물 자체가 이미 완성됐다.

### Step 8 — 다음 단계 제안 (제안만, 시작 안 함)

`next-skill-routing.md`(이때 읽는다 — 기억으로 추천 금지, 기억은 로컬 스킬로
편향된다)를 따라 한 번 추천한다. 요점:

- **설치 스킬을 Bash 로 스캔하지 마라** — available-skills 목록이 이미 컨텍스트에
  있다. 그 목록에서 valid-next 후보를 재선정한다(글로벌·플러그인 포함, 예시 이름에
  anchor 금지). `deep-plan` 자신은 제외.
- 빌드가 명백하면 Tier 1 단축(greenfield→`/forge`, 변경→`/renew`, 고장→`/hunt`),
  아니면 Tier 2 전체 후보(`linear-register` 분할 모드·`deep-research` 등)를 함께 본다.
- 빌드로 제안하면 산출물을 **이미 완료된 Phase-1 결과물**로 취급해 다시 인터뷰하지
  말라고 프레이밍한다(이중 인터뷰 회피). Acceptance(=eval) 항목이 그 빌드가 Phase 4
  에서 닫을 체크리스트이고, UI 면 `.html` 목업이 승인된 visual 계약임을 함께 짚는다.
  자율 실행(`linear-goal`)으로 제안하면 `-prompt.md` 를 그대로 goal 로
  먹이면 된다고 짚는다 — 그게 그 파일의 존재 이유다.
- **`AskUserQuestion` 으로 제안만** 한다.

그리고 **여기서 멈춘다 — 이곳이 유일한 정지 지점이다**(Step 7 보고는 정지가
아니다). 다음 스킬 자동 시작 없음 — 무엇을 할지는 사용자가 정한다.

## Anti-patterns

- **구현 코드를 쓰기 / craft Phase 2~5 진입** — deep-plan 은 Phase 1 에서 멈춘다.
- **goal-ready Linear 이슈 재플래닝** — 실측 증거·측정가능 AC·범위 밖·단일 해석을
  다 갖춘 이슈에 plan 재생성은 중복(Step 0 readiness 게이트 — routing.md §goal-ready).
  제안 없이 debate 로 직행하지 말 것.
- **비평자를 수렴 핑퐁 리뷰어로 쓰기** — 비평자의 일은 고정 비트
  debate 비평 + 최종 verdict 뿐이다. 수렴까지 도는 루프는 어디에도 없다
  (미해소 BLOCKING 은 assumption·Risks 승격 — Step 4 상한 규칙).
- **④ verdict 를 돌리고도 PLAN 에 `## Plan review` 섹션 미기록** — 스킵 신호가
  없으면 빌드 파이프라인이 같은 플랜을 다시 리뷰한다(중복 비용, Step 5 의무).
- **왕복 3회 이상 / 델타 0 인데 반영·verdict 비트 실행** — 상한 고정 2왕복(4비트),
  델타 없으면 1왕복(2비트)에서 끝낸다. 미해소 BLOCKING 은 추가 왕복이 아니라
  assumption·Risks 승격으로 처리한다.
- **SUGGESTION 을 의무 반영으로 승격 / 태그 없는 비평을 BLOCKING 취급** — 취향
  진동의 연료다. 의무는 명시적 BLOCKING 만, 무태그는 SUGGESTION 강등.
- **메인 루프가 저자 겸직** — 저자는 항상 fable 서브에이전트. orchestrator 가
  초안까지 쓰면 저자/중재자 분리가 무너진다.
- **비평 좌석 생략** — 비평자를 비운 채 초안을 최종으로 내보내지 않는다. debate 가
  아니라 단일 초안이 된다.
- **저자에게 자기 비평을 시킴** — `dp-author` 를 재개해 비평까지 받으면 별 컨텍스트가
  아니라 자기 승인이다. 비평자는 별도 좌석(codex 또는 `dp-critic`)이어야 한다 —
  fable 폴백에서는 좌석 분리가 유일한 독립성 장치다.
- **codex 가용한데 fable 폴백으로 직행** — 프리플라이트 없이 폴백을 기본값처럼 쓰면
  교차모델 독립성을 공짜로 버리는 것이다. 폴백은 프리플라이트 실패·watchdog kill
  때만, 사유 보고와 함께.
- **BLOCKING 0건을 "초안이 좋다"로 읽기** — 같은 모델의 동조일 수 있다. Step 2 동조
  감시(갭도 0건이면 1회 재요청, 그래도 0건이면 보고)를 건너뛰지 말 것.
- **프롬프트 Success Criteria 와 PLAN Acceptance 를 따로 진화시키기** — SSOT 는
  Acceptance, 어긋나면 프롬프트를 고친다.
- **갭 목록 없이 인터뷰 시작 / union·dedup 없이 양측 갭을 중복 질문** — 의제 없는
  인터뷰가 표류의 정의고, 같은 갭 두 번 묻기는 신뢰 붕괴다.
- **`[CODE]` 갭을 사용자에게 묻기** — 먼저 읽고, 코드가 대신 못 하는 결정만 물으라.
- **창작한 옵션으로 결정형 질문** — 옵션은 사용자 발화·코드 실측에서만 도출.
  (독립 갭 배칭은 Step 3 정책상 허용 — 의존 갭만 직렬.)
- **SSOT eager 일괄 읽기** — 위 표의 시점 전에 reference 를 몰아 읽는 것은 토큰
  낭비다. 분기에 진입할 때만 읽는다.
- **`-prompt.md` 에 해설·메타 섞기** — 그 파일은 통째로 goal 칸에 들어가야 한다.
- **UI plan 인데 `.html` 이 plan 표만 렌더** — UI 면 결과 화면 목업이어야 한다.
  반대로 DB/BE plan 인데 스키마가 핵심인 경우 ERD 미생성도 실패.
- **DESIGN.md 가 있는데 손으로 mockup**(토큰 위반 — design-context 절차로) /
  슬림 UI 에 `frontend-design`/`prototype` 과투자(inline 스케치로 족).
- **파일/계약을 Read/Grep 없이 거명** — Files 섹션은 검증된 것만.
- **폴백을 조용히 수행** — 강등했으면 반드시 보고한다.
- **다음 스킬 자동 시작 / 설치 스킬 Bash 스캔.**
