---
name: deep-plan
description: 사용자의 요청문을 codex 로 두 번 깎아 자율 에이전트가 먹을 수 있는 Goal Prompt 로 만들고, 그 과정에서 codex 가 지목한 컨텍스트 갭을 인터뷰로 채운 뒤, 프롬프트(`-prompt.md`) + 구현 PLAN(`.md`) + 통합 뷰(`.html`)를 산출하고 빌드하지 않고 멈춘다. 사용자가 plan/설계/기획안/제안서/접근법/로드맵/UI 시안을 원하되 지금 구현은 원하지 않을 때 사용 — "계획 세워줘", "어떻게 만들지 설계해줘", "구현 말고 플랜만", "기획안 만들어줘", "UI 시안 뽑아줘", "design doc 작성", "어떻게 접근할지 정리", "plan this out", "/deep-plan" 같은 표현. 번호 매긴 요구사항 spec 결정화는 deep-interview, 프롬프트 한 덩어리만 필요하면 deep-prompt, 실제 구현/버그수정/기존 동작 변경은 forge/hunt/renew — deep-plan 은 코드를 쓰지 않는다, 프롬프트와 plan 만 쓴다.
---

# Deep Plan — codex 메타프롬프팅 → 갭 인터뷰 → PLAN(+시안), 빌드 없음

당신은 **계획을 세우지, 빌드하지 않는다.** 사용자가 던지는 한 문단짜리 요청은 자율
실행 계약으로는 약하다 — 그 약함을 사람이 스스로 보기는 어렵다. 그래서 이 스킬은
두 번째 모델(codex)에게 요청문을 먼저 넘겨 **구체적 갭 목록**으로 약함을 드러내게
하고, 그 목록만큼만 사용자를 인터뷰한 뒤, 다시 codex 에게 돌려 최종 프롬프트를
확정한다. 산출물은 셋: 실행 계약인 Goal Prompt(`-prompt.md`), 설계 근거인
PLAN(`.md`), 사람이 보는 통합 뷰(`.html`).

codex 는 여기서 **메타프롬프터**로만 쓴다 — craft 빌드 파이프라인의 *적대적 플랜
리뷰*(Phase 2)는 돌리지 않는다. TDD 도, 보안 페이즈도, 구현 코드도 없다.

막아야 할 실패 셋: (1) 깎이지 않은 요청문이 그대로 자율 에이전트 goal 칸에 들어가
에이전트가 완료를 판정하지 못하는 것, (2) 갭을 모르는 채 인터뷰가 표류하는 것,
(3) UI plan 의 `.html` 이 plan 텍스트를 렌더만 하고 *결과 화면*을 안 보여주는 것.

## 경계

- **vs `deep-interview`** — 그쪽은 번호 매긴 요구사항 **spec**(`REQ-F`/`REQ-N`)을
  만들어 빌드 스킬로 라우팅한다. deep-plan 은 실행 프롬프트 + plan + 시안을
  산출하고 멈춘다.
- **vs `deep-prompt`** — 그쪽은 **프롬프트 한 덩어리만**(짧은 명료화 + 고정 템플릿).
  deep-plan 은 codex 2패스로 프롬프트를 깎고 **PLAN·시안까지** 낸다. 사용자가
  "goal 프롬프트만" 원하면 그쪽이 맞다 — 여기로 끌어오지 말 것.
- **vs `forge`/`renew`/`hunt`** — 그쪽은 빌드한다. deep-plan 은 구현 코드를 한 줄도
  쓰지 않는다.

## SSOT lazy-load — 해당 분기에 진입할 때만 읽는다

메커니즘은 복제하지 말고 공유 소스를 읽어라(규칙이 한 곳에 살아야 drift 가 없다).
단 **eager 하게 전부 읽지 마라** — 아래 표의 시점에 도달했을 때만 그 파일을 읽는다.
경로 약칭: `cc` = `~/.claude/skills/craft-core/references`, `di` =
`~/.claude/skills/deep-interview/references`.

| 읽는 시점 | 파일 |
|---|---|
| Step 0 문서 grounding 시 | `cc/context-adr.md` |
| Step 1 codex 호출 직전 (첫 1회) | `cc/codex-review.md` 의 "어떻게 호출하는가" 절 + `~/.claude/skills/deep-prompt/SKILL.md` 의 "고정 템플릿 채우기"·"검증 가능성 게이트" 절 |
| Step 4 PLAN 작성 직전 | `cc/pipeline.md` 의 Phase 1 (plan 섹션 + HTML companion + Eval 패널 규칙) |
| Step 5 UI 목업을 **그릴 때만** | `~/.claude/skills/mockup/references/design-context.md` |
| Step 5 ERD 분기 **진입 시만** | `~/.claude/skills/erd/SKILL.md` + `assets/erd-template.html` + `references/schema-discovery.md` |
| Step 6 종료 보고 직전 | `cc/output-contract.md` |
| Step 6.5 Linear 등록 제안 시만 | `cc/linear.md` |
| Step 7 다음 스킬 추천 직전 | `di/next-skill-routing.md` |

`cc/codex-review.md` 에서 가져오는 것은 **호출 규약**(plugin root 해소·`task` /
`task --resume-last`·stdout↔stderr 분리·read-only 규칙)뿐이다. 그 파일의 적대적
리뷰 프롬프트·수렴 핑퐁 계약은 이 스킬 것이 아니다 — 가져오지 말 것.

파일이 없으면(해당 스킬 미설치) 그 사실을 말하고 같은 원리를 직접 적용한다.

> 모델 노트: PLAN 본문·시안은 이 스킬에서 추론 밀도가 가장 높은 산출물이다. 세션
> 모델이 최상위 티어(fable/opus 급)가 아니면 Step 4+5 를 `Agent`(`model: 'fable'`,
> 미가용 시 `'opus'` 재시도 — 폴백 사실 보고) 서브에이전트 하나로 위임한다. 프롬프트에는
> 본문 대신 경로와 결정 digest 만 싣고, 에이전트 산출을 메인이 Read 로 검증한다.
> 최상위 티어면 인라인로 그대로 작성한다(위임은 재직렬화 손실만 남긴다).

## 흐름

### Step 0 — Frame & ground

- 작업유형과 한 줄 목표를 사용자에게 되짚는다.
- **Ground first.** plan 이 건드릴 코드(가능하면 code-graph/LSP, 아니면 영향 반경에
  한정한 Read/Grep — 절대 레포 전체 아님)와 관련 기존 문서(ADR/concept/guide —
  `context-adr.md`)를 scope-read 한다. plan 은 standing 결정을 존중하고, 파일/계약을
  추측이 아니라 실제로 anchor 한다. 이 grounding 은 Step 1 codex 프롬프트의
  `<repo-context>` 로도 들어가므로 여기서 부실하면 갭 목록이 부실해진다.
- worktree 는 만들지 않는다 — deep-plan 은 코드를 편집하지 않는다.

### Step 1 — codex R1: 메타프롬프팅 (요청문 → 초안 + 갭 목록)

**입력은 사용자의 요청문 원문이다.** 프롬프트 초안을 따로 써 오라고 요구하지
않는다 — 사용자가 스킬을 부를 때 쓴 그 문장이 곧 입력이다.

`cc/codex-review.md` 의 호출 규약대로 **codex-companion 을 Bash 로 직접** 호출한다
(`codex:rescue` 경유 아님 — 그 계약은 실패 시 부분 결과를 버린다):

```bash
ROOT=$(ls -d ~/.claude/plugins/cache/openai-codex/codex/*/ | sort -V | tail -1)
CLAUDE_PLUGIN_ROOT="$ROOT" node "$ROOT/scripts/codex-companion.mjs" task --effort medium \
  "<R1 프롬프트>" > <scratch>/dp-meta-r1-out.txt 2> <scratch>/dp-meta-r1-err.txt
```

- **read-only 로 유지** — `--write` 를 붙이지 않고, 프롬프트에도 평이한 말로
  *"Do not edit, create, or delete any files."* 라고 쓴다.
- **마스킹 (송신 전 필수)** — codex 는 외부 모델이다. `<repo-context>` 에
  secret·credential·내부 호스트·PII 를 넣지 않는다 — 경로·계약 형태·standing 결정
  요약만. Step 6.5 Linear 첨부의 마스킹 게이트와 동형이다.
- **effort 는 medium 기본.** 보안 경계·외부 계약·마이그를 수반하는 요청만 상향.
- **watchdog** — background + 진행 감시. 마지막 진행 후 3분 무소식이면 kill, hard
  cap 20분. kill 시 stderr 파일에서 부분 결과를 회수한다. SSOT:
  `~/.claude/rules/delegated-review-watchdog.md`.

R1 프롬프트는 compact 한 XML-태그 operator 형태로 쓴다 — codex 가 여기 가장 잘
응답한다. 적응하되 다섯 블록은 유지한다:

```
<task>
Rewrite the raw request below into a Goal Prompt for an autonomous Claude Code
build agent, and list what context is missing. Review and write only in your
answer — do NOT edit, create, or delete any files.
</task>
<raw-request>…사용자 요청문 원문…</raw-request>
<repo-context>…Step 0 요약 — secret·credential·내부 호스트 제외(위 마스킹)…</repo-context>
<target-format>
7 sections: Objective / Success Criteria / Context / Constraints / Verification /
Out of Scope / Done & Report. The consumer is an autonomous agent with no human
present: Success Criteria must let it decide "done" alone and exit the loop.
</target-format>
<output>
1) DRAFT PROMPT — the 7-section draft, best effort with what is known.
2) GAPS — numbered, AT MOST 7, ranked by impact (highest first). Each gap = ONE
   missing fact that would change the prompt, phrased as a question. Tag [CODE]
   if reading the repo could answer it, [HUMAN] if only the requester can.
</output>
```

**갭 목록 없이 초안만 오면 실패로 친다** — 그 경우 갭을 요구하는 한 문장을 덧붙여
R1 을 한 번 재호출한다(이 재호출은 2패스 카운트에 넣지 않는다).

**폴백.** codex 미설치·호출 실패·watchdog kill 로 산출을 못 얻으면 **Claude 자체
메타프롬프팅으로 강등**하고 — 같은 7섹션 초안 + 갭 목록을 직접 만든다 — 그 사실을
*"codex 미사용, Claude 단독 산출"* 로 명시 보고한다. 스킬을 중단하지 않는다.

### Step 2 — 갭 인터뷰 (인터뷰 기계는 이것 하나뿐)

R1 갭 목록이 인터뷰의 유일한 의제다. 별도 모호성 점수·임계값을 두지 않는다 —
**갭 목록 소진**이 종료 게이트다.

1. **`[CODE]` 갭은 내가 닫는다.** Read/Grep 으로 답하고, 사용자에게 묻지 않는다.
   무엇을 어떻게 닫았는지 한 줄로 보고한다. 코드가 이미 답하는 것을 사람에게 묻는
   것은 순수 마찰이다.
2. **`[HUMAN]` 갭만 사용자에게 — 라운드당 한 질문.** 절대 묶지 말 것. 묶으면
   사용자가 전 영역에 얕게 답하고 어느 것도 깊이 생각하지 않는다.
   - **결정형**(답 공간이 닫힘: A 냐 B 냐) → `AskUserQuestion`.
     **Anchoring 가드**: 옵션은 **사용자가 이미 말한 것 또는 코드에서 실측한 것**
     에서만 도출한다. 창작한 옵션은 유도 질문의 UI 판이다 — 도출할 출처가 없으면
     그 질문은 생성형이니 산문으로 물으라.
   - **생성형**(구체 예시·수치·근거·워크플로 묘사) → 산문.
3. **이미 답한 것을 다시 묻지 않는다.** 사용자는 물은 것보다 많이 답한다 — 한 답이
   다른 갭까지 닫으면 그 사실을 말하고 그 갭도 닫는다.
4. **라운드 보고 1~2줄** — 방금 닫힌 갭, 남은 갭 수, 다음 조준. 진행감이자 조기
   오해 검출이다.
5. **탈출구** — 사용자가 "그만 / 이 정도면 돼" 하면 따른다. 남은 갭은 최종 프롬프트의
   Constraints 에 *assumption* 으로, PLAN 의 Risks 에 잔여 리스크로 명시한다.
6. **상한 방어** — codex 가 상한(7)을 넘겨 갭을 내면 상위 7개만 의제로 삼고,
   나머지는 assumption 승격을 제안한다. 인터뷰가 갭 개수에 볼모잡히지 않게 한다.

갭이 처음부터 0개면 인터뷰를 통째로 건너뛰고 그 사실을 한 줄로 말한다.

**질문 불가 컨텍스트(자율/백그라운드 — `harness-run` ②, 백그라운드 잡, `$CLAUDE_JOB_DIR`)
에서는 인터뷰를 돌리지 않는다.** 물을 사람이 없는 구간에서 `AskUserQuestion` 은 hang
이거나 헛프롬프트다. 그 경우: `[CODE]` 갭은 평소대로 읽어서 닫고, `[HUMAN]` 갭은
**전부 assumption 으로 승격**해 최종 프롬프트 Constraints + PLAN Risks 에 명시한 뒤
Step 3 으로 간다. 산출물 보고에 *"자율 컨텍스트 — [HUMAN] 갭 N건을 assumption 으로
승격"* 을 남겨 사람이 나중에 그 목록을 볼 수 있게 한다. 이 분기는 harness-run 의
"사람 프롬프트 0" 계약을 깨지 않기 위한 것이다.

### Step 3 — codex R2: 최종 프롬프트 확정 (같은 스레드 재개)

**스킵 게이트 — 접을 델타가 없으면 R2 를 돌리지 않는다.** 갭이 0개였거나(인터뷰
미발동) 인터뷰 답변·`[CODE]` 보정이 아무것도 바꾸지 않았으면 **R1 초안이 곧 최종
프롬프트다** — 델타 없는 `--resume-last` 는 수 분짜리 낭비다. 스킵 사실을 한 줄
보고하고 Step 4 로 간다. crisp 한 요청의 빠른 경로가 이것이다.

델타가 있으면: 인터뷰 답변을 원장으로 묶어 **같은 스레드에 되돌린다.** codex 는
이전 라운드 컨텍스트를 유지하므로 델타만 넘기면 된다. 원장은 갭 번호 대응으로:
`GAP 3 → 답: …` 한 줄씩 + `[CODE]` 갭은 `GAP 1 → 코드 실측: …` 로.

```bash
CLAUDE_PLUGIN_ROOT="$ROOT" node "$ROOT/scripts/codex-companion.mjs" task --resume-last \
  "<R2 프롬프트>" > <scratch>/dp-meta-r2-out.txt 2> <scratch>/dp-meta-r2-err.txt
```

R2 가 낼 것 둘: ① 갭이 반영된 **최종 프롬프트**(같은 7섹션) ② **자기 R1 갭이 실제로
닫혔는지 항목별 verdict**. 두 번째가 핵심이다 — 자기가 물은 것을 자기가 채점하게
해야 "답을 받았는데 프롬프트에 안 들어간" 누락이 잡힌다.

**codex 패스는 최대 2회다**(스킵 게이트로 1회가 될 수 있다). 수렴 핑퐁으로 늘리지
않는다. R2 verdict 에 미해소 갭이 남으면 세 번째 호출 대신 — 그 갭을 프롬프트
Constraints 의 assumption + PLAN Risks 로 승격시키고 진행한다. 남은 것을 숨기지
말고 이름을 붙여 앞으로 들고 간다. **R2 이후 프롬프트를 손봐야 하면**(Step 4 PLAN
작성이 드러낸 어긋남 등) 3차 호출 없이 Claude 가 직접 수정하고 수정 사실을 보고에
남긴다 — codex 의 자기 갭 검증은 R2 시점 산출까지만 커버한다는 것을 안다.

### Step 4 — PLAN 문서 작성

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
## Acceptance / Eval (numbered, single, checkable; 각 항목에 [AUTO] 또는 [HUMAN] 태그)
```

열어보지 않은 파일/심볼을 거명하는 것은 실패다. Files 는 실제로 확인한다.

프롬프트와 PLAN 의 역할 분담: **프롬프트가 실행 계약**(자율 에이전트가 받는 것),
**PLAN 이 설계 근거**(사람이 검토하는 것). "done" 의 **SSOT 는 PLAN 의 Acceptance**
다 — 프롬프트의 Success Criteria/Verification 은 Acceptance 의 `[AUTO]` 항목을
재서술한 것이어야 하며(`[HUMAN]` 항목은 자율 에이전트가 스스로 검증 못 하므로 제외),
항목 수·내용이 어긋나면 프롬프트 쪽을 고친다(Step 3 규칙 — Claude 직접 수정, 3차
codex 호출 아님). 두 소비자가 같은 장부를 봐야 한다: 자율 에이전트=프롬프트,
빌드 스킬 Phase 4=Acceptance.

**Acceptance 항목이 곧 eval 항목이다** — 빌드 스킬(forge/renew/hunt)이 구현 후
Phase 4 에서 하나씩 검증해 닫을 체크리스트. `[AUTO]`=결정론·회귀·보안·계약(자동
테스트로 잠금), `[HUMAN]`=시각·UX 의도·주관(빌드 후 사람과 walk). 태그 규칙 SSOT 는
`pipeline.md` Phase 1. 별도 "eval" 개념을 새로 만들지 말 것 — Acceptance 가 그 자리다.

### Step 5 — 산출 3파일

같은 디렉토리·같은 basename 으로 셋을 쓴다.

**① `docs/plans/YYYY-MM-DD-<topic>-prompt.md` — 순수 프롬프트.**
파일 전체가 그대로 자율 에이전트 goal 칸에 들어갈 수 있어야 한다. 프론트매터·메타
해설·라운드 기록·경로 안내를 넣지 않는다. 7섹션 본문만.

**② `docs/plans/YYYY-MM-DD-<topic>.md` — PLAN.** Step 4 산출.

**③ `docs/plans/YYYY-MM-DD-<topic>.html` — 통합 뷰 (항상 생성).**
self-contained(inline `<style>`, 외부 asset 0). 세 영역 필수:

- **최종 프롬프트** — 복사 가능한 `<pre>` 블록으로 통째. 사람이 여기서 집어 간다.
- **PLAN 렌더** — 섹션 heading + Steps→verify 표 + 파일 경로 코드 스타일.
- **Eval 체크리스트 패널** — Step 4 의 Acceptance 항목을 `[AUTO]`/`[HUMAN]` 태그와
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
`~/.claude/rules/html-mockup-artifact.md`.

#### ERD companion — plan 이 DB 스키마/BE 데이터 모델을 수반하면 (UI 판정과 별개)

plan 이 **새 테이블·컬럼·관계 또는 BE 데이터 모델 변경**을 수반하면 ERD 를 별도
HTML 로 생성한다 — 비UI plan 이라도 ERD 는 실제 도식 가치를 준다("데이터가 어떻게
엮일지"). 생성 방법은 `erd` 스킬 3파일(이때 읽는다)을 그대로 따른다. 스키마는
Step 0 에서 Read 한 마이그레이션/모델에서 재구성한다(못 본 테이블/관계는 그리지
않고 footer 에 한계 명시). 산출은 같은 디렉토리·basename 에 `-erd.html`, 역시
Artifact publish. 판정: 스키마/관계가 plan 의 핵심이면 그린다 — 컬럼 한둘 추가뿐이면
과투자(생략, plan 텍스트로 족). `erd` 미설치면 그 사실을 말하고 생략.

### Step 6 — 제시하고 정지

`output-contract.md`(이때 읽는다)의 고정 블록으로 보고한다 — `result:` 한 줄 + 각
산출물의 상대경로. 프롬프트·PLAN 행은 항상(`open` 명령 동반), `시안`·`ERD` 행의
딜리버러블은 Step 5 에서 publish 한 **artifact URL** 이다. 예:

```
result: <topic> 프롬프트+PLAN 산출 — codex 2패스, 갭 N건 해소, N steps, scope IN <…> / OUT <…>

산출물 — 열기:
- 프롬프트 `docs/plans/2026-06-04-<topic>-prompt.md`  →  `open docs/plans/2026-06-04-<topic>-prompt.md`
- PLAN `docs/plans/2026-06-04-<topic>.md`  →  `open docs/plans/2026-06-04-<topic>.md`
- 통합 뷰 `docs/plans/2026-06-04-<topic>.html`  →  <artifact URL>

(`open` = macOS. Linux `xdg-open <path>`, Windows `start <path>`.)
```

codex 폴백이 발동했으면 그 사실을 `result:` 아래 한 줄로 반드시 덧붙인다.

### Step 6.5 — Linear 작업 등록 (optional, 확인 게이트)

산출물 제시 후, Linear 작업 트리(parent 1 + PLAN Step 당 sub-issue 1)로 등록할지
**제안**한다. 메커니즘은 `cc/linear.md`(이때 읽는다) 그대로: ① MCP 감지 — 미설치면
가이드 한 번 + 스킵 제안(막지 않음) ② 만들 트리 미리보기 → 동의받은 **뒤에만**
생성(외부 write 라 자동 등록 금지) ③ 생성 후 sub-issue ID/URL 을 PLAN `.md` 에 기록.

**산출물 첨부 (동의 시).** parent 이슈에 셋을 붙인다:

- `-prompt.md` · `.md` — 파일 업로드: `prepare_attachment_upload` →
  `create_attachment_from_upload`.
- `.html` — Artifact URL 링크: `create_attachment`.
- 업로드가 막히면(플랜·권한) 셋 다 Artifact URL 링크로 강등하고 그 사실을 말한다.
- **첨부 실패가 등록을 롤백하지 않는다** — 경고만 남기고 진행.

**마스킹 게이트 (첨부 전 필수).** Linear 는 외부 서비스이고 올린 내용은 캐시·인덱싱
돼 삭제해도 남는다. 첨부 직전 산출물에 credential·PII·내부 URL·DB dump 가 박혔는지
검사하고, 발견되면 **첨부를 보류**한 뒤 사유를 보고한다
(`~/.claude/rules/acceptance-criteria-gate.md` G3 동형).

판정: PLAN 이 2+ Step 이면 제안 가치 있음, 1 Step 사소 plan 이면 단일 이슈 또는
생략. 등록 실패/스킵이 deep-plan 의 성공을 깎지 않는다 — 산출물 자체가 이미 완성됐다.

### Step 7 — 다음 단계 제안 (제안만, 시작 안 함)

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
  자율 실행(`linear-goal`·`harness-run`)으로 제안하면 `-prompt.md` 를 그대로 goal 로
  먹이면 된다고 짚는다 — 그게 그 파일의 존재 이유다.
- **`AskUserQuestion` 으로 제안만** 한다.

그리고 **여기서 멈춘다.** 다음 스킬 자동 시작 없음 — 무엇을 할지는 사용자가 정한다.

## Anti-patterns

- **구현 코드를 쓰기 / craft Phase 2~5 진입** — deep-plan 은 Phase 1 에서 멈춘다.
- **codex 를 적대적 플랜 리뷰어로 쓰기** — 여기서 codex 의 일은 메타프롬프팅
  뿐이다. 플랜 리뷰는 forge/renew/hunt 의 Phase 2 소관.
- **codex 패스를 3회 이상 늘리기 / 델타 0 인데 R2 돌리기** — 최대 2회, 접을 델타가
  없으면 1회에서 끝낸다. 미해소 갭은 세 번째 호출이 아니라 assumption·Risks 승격으로
  처리한다.
- **`<repo-context>` 에 secret·credential·내부 호스트 포함** — codex 는 외부 모델,
  송신 전 마스킹 필수.
- **프롬프트 Success Criteria 와 PLAN Acceptance 를 따로 진화시키기** — SSOT 는
  Acceptance, 어긋나면 프롬프트를 고친다.
- **갭 목록 없이 인터뷰 시작** — 의제 없는 인터뷰가 표류의 정의다.
- **`[CODE]` 갭을 사용자에게 묻기** — 먼저 읽고, 코드가 대신 못 하는 결정만 물으라.
- **갭 질문 묶기 / 창작한 옵션으로 결정형 질문** — 라운드당 하나, 옵션은 실측에서만.
- **SSOT eager 일괄 읽기** — 위 표의 시점 전에 reference 를 몰아 읽는 것은 토큰
  낭비다. 분기에 진입할 때만 읽는다.
- **`-prompt.md` 에 해설·메타 섞기** — 그 파일은 통째로 goal 칸에 들어가야 한다.
- **UI plan 인데 `.html` 이 plan 표만 렌더** — UI 면 결과 화면 목업이어야 한다.
  반대로 DB/BE plan 인데 스키마가 핵심인 경우 ERD 미생성도 실패.
- **DESIGN.md 가 있는데 손으로 mockup**(토큰 위반 — design-context 절차로) /
  슬림 UI 에 `frontend-design`/`prototype` 과투자(inline 스케치로 족).
- **파일/계약을 Read/Grep 없이 거명** — Files 섹션은 검증된 것만.
- **codex 폴백을 조용히 수행** — 강등했으면 반드시 보고한다.
- **다음 스킬 자동 시작 / 설치 스킬 Bash 스캔.**
