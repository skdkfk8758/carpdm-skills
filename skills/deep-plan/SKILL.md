---
name: deep-plan
description: 모호하면 먼저 인터뷰로 보강하고, 검증 가능한 구현 PLAN 문서(`docs/plans/…md`)를 산출하며 — plan 결과물이 UI 면 결과 화면의 self-contained HTML 시안까지 — 빌드하지 않고 멈춘다. 사용자가 plan/설계/기획안/제안서/접근법/로드맵/UI 시안을 원하되 지금 구현은 원하지 않을 때 사용 — "계획 세워줘", "어떻게 만들지 설계해줘", "구현 말고 플랜만", "기획안 만들어줘", "UI 시안 뽑아줘", "design doc 작성", "어떻게 접근할지 정리", "plan this out", "/deep-plan" 같은 표현. 번호 매긴 요구사항 spec 결정화는 deep-interview, 실제 구현/버그수정/기존 동작 변경은 forge/hunt/renew — deep-plan 은 코드를 쓰지 않는다, plan 만 쓴다.
---

# Deep Plan — 인터뷰로 보강된 PLAN(+UI 시안) 도출, 빌드 없음

당신은 **계획을 세우지, 빌드하지 않는다.** 산출물은 두 개다: 검증 가능한 구현
PLAN 문서(`.md`), 그리고 plan 이 사용자 대면 UI 를 전달한다면 그 화면을 보여주는
self-contained HTML 시안(`.html`). 끝나면 멈춘다 — codex 리뷰도, TDD 도, 보안
페이즈도, 구현 코드도 없다(그것들은 craft 빌드 파이프라인의 일).

막아야 할 실패 두 가지: (1) 모호한 요청을 그대로 받아 흐릿한 plan 을 쓰는 것,
(2) UI plan 의 `.html` 이 plan 텍스트를 렌더만 하고 *결과 화면*을 안 보여주는 것.

## 경계

- **vs `deep-interview`** — 그쪽은 번호 매긴 요구사항 **spec**(`REQ-F`/`REQ-N`)을
  만들어 빌드 스킬로 라우팅한다. deep-plan 은 실행 가능한 **plan 문서 + 시안**을
  산출하고 멈춘다.
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
| Step 1 인터뷰가 **발동할 때만** | `cc/socratic.md` + `di/scoring.md` + `di/socratic-playbook.md` |
| Step 2 PLAN 작성 직전 | `cc/pipeline.md` 의 Phase 1 (plan 섹션 + HTML companion + Eval 패널 규칙) |
| Step 3 UI 목업을 **그릴 때만** | `~/.claude/skills/mockup/references/design-context.md` |
| Step 3 ERD 분기 **진입 시만** | `~/.claude/skills/erd/SKILL.md` + `assets/erd-template.html` + `references/schema-discovery.md` |
| Step 4 종료 보고 직전 | `cc/output-contract.md` |
| Step 4.5 Linear 등록 제안 시만 | `cc/linear.md` |
| Step 5 다음 스킬 추천 직전 | `di/next-skill-routing.md` |

파일이 없으면(해당 스킬 미설치) 그 사실을 말하고 같은 원리를 직접 적용한다.

> 모델 노트: PLAN 본문·시안은 이 스킬에서 추론 밀도가 가장 높은 산출물이다. 세션
> 모델이 최상위 티어(fable/opus 급)가 아니면 Step 2+3 을 `Agent`(`model: 'fable'`,
> 미가용 시 `'opus'` 재시도 — 폴백 사실 보고) 서브에이전트 하나로 위임한다. 프롬프트에는
> 본문 대신 경로와 결정 digest 만 싣고, 에이전트 산출을 메인이 Read 로 검증한다.
> 최상위 티어면 인라인로 그대로 작성한다(위임은 재직렬화 손실만 남긴다).

## 흐름

### Step 0 — Frame & ground

- 작업유형과 한 줄 목표를 사용자에게 되짚는다.
- **Ground first.** plan 이 건드릴 코드(가능하면 code-graph/LSP, 아니면 영향 반경에
  한정한 Read/Grep — 절대 레포 전체 아님)와 관련 기존 문서(ADR/concept/guide —
  `context-adr.md`)를 scope-read 한다. plan 은 standing 결정을 존중하고, 파일/계약을
  추측이 아니라 실제로 anchor 한다.
- worktree 는 만들지 않는다 — deep-plan 은 코드를 편집하지 않는다.

### Step 1 — 적응형 보강 게이트

요청이 이미 다음을 *모두* 명확히 진술하는지 판정한다: 검증 가능한 **goal**,
**scope IN/OUT**, **성공 기준**, (UI 라면) 어떤 화면/플로우인지.

- **이미 crisp** → 인터뷰를 **건너뛴다.** 왜 건너뛰는지 한 줄로 말하고 Step 2 로.
  이미 명확한 요청을 인터뷰하는 것은 마찰이다.
- **모호** → **측정 게이트 인터뷰**를 돈다(위 표의 인터뷰 SSOT 3개를 이때 읽는다):
  - threshold 는 **묻지 않는다** — 기본 0.20 으로 시작하고, 첫 고지 줄에 명시한다:
    *"Target: ambiguity ≤ 0.20 (`--quick`=0.35 / `--deep`=0.10 으로 조정 가능)."*
  - 먼저 토폴로지(1~6개 큰 조각, active/deferred)를 한 번 고정한다.
  - **라운드당 한 질문** — 절대 묶지 말 것. 매 라운드 가장 약한 차원을 점수로 찾아
    여섯 Socratic 유형 중 맞는 하나로 공략하고, 짧은 라운드 테이블(차원 점수,
    ambiguity %, `locked:` 확정 결정, 다음 조준)을 보고한다. 결정형 질문(닫힌 답
    공간)은 `AskUserQuestion`, 생성형은 산문 — 규칙은 playbook §답 형태.
  - **ambiguity ≤ threshold** 에서 멈춘다. 사용자가 "그만 / plan 짜 / 이 정도면 돼"
    하면 따른다 — 현재 ambiguity 와 미해결을 명시한 뒤 결정화.

판정이 애매하면(crisp 인지 모호인지) 모호 쪽으로 기운다 — 흐릿한 plan 보다 질문
한두 개가 싸다.

### Step 2 — PLAN 문서 작성

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

**Acceptance 항목이 곧 eval 항목이다** — 빌드 스킬(forge/renew/hunt)이 구현 후
Phase 4 에서 하나씩 검증해 닫을 체크리스트. `[AUTO]`=결정론·회귀·보안·계약(자동
테스트로 잠금), `[HUMAN]`=시각·UX 의도·주관(빌드 후 사람과 walk). 태그 규칙 SSOT 는
`pipeline.md` Phase 1. 별도 "eval" 개념을 새로 만들지 말 것 — Acceptance 가 그 자리다.

### Step 3 — HTML 시안 (조건부)

**UI 판정 먼저.** plan 이 사용자 대면 UI(화면·컴포넌트·페이지·플로우·보이는 UX
변경)를 전달하는가?

- **UI / 혼합 plan** → plan 과 같은 경로에 `.html` 확장자로 self-contained
  companion(inline `<style>`, 외부 asset 0)을 쓴다. 내용은 plan 이 구현된 후
  사용자가 **보게 될 결과 UI 의 목업** — 실제 인터페이스(chrome, pane, 컨트롤,
  상태)를 배치하고, UX 를 명확히 하는 곳은 inline `<script>` 로 핵심 인터랙션을
  *시연*한다. "mockup" 표식 눈에 띄게. 혼합 plan 이면 UI 는 목업, 그 아래 비UI
  섹션은 plan 렌더. companion 형식·Eval 체크리스트 패널 규칙 SSOT 는 `pipeline.md`
  Phase 1(이미 Step 2 에서 읽음).
  - **충실도** — 목업을 그리기 전에 `design-context.md`(이때 읽는다)를 따라
    프로젝트 DESIGN.md·토큰·기존 화면 어휘를 추출하고 토큰 검증한다. 시안 즉흥
    창작이 구현 괴리의 근원. 전문 스킬 라우팅(§6: net-new UI → `frontend-design`,
    다안 비교 → `prototype`, 추출 디자인 재현 → `imprint`)은 `AskUserQuestion`
    제안만 — 자동 시작 금지, 미설치면 inline 폴백.
  - **Eval 패널** — Step 2 의 Acceptance 항목을 `[AUTO]`/`[HUMAN]` 태그와 함께
    체크리스트로 렌더한다. SSOT 는 `.md` Acceptance, 패널은 렌더 뷰.
  - **Artifact publish** — 시안을 쓴 직후 `Artifact` 도구로 publish 한다. 사용자
    리뷰 딜리버러블은 **artifact URL**(로컬 `.html` 은 유지 — 하니스 입력).
    갱신 시 같은 파일 경로로 재-publish 해 URL 유지. 규칙 SSOT:
    `~/.claude/rules/html-mockup-artifact.md`.
- **비UI plan**(리팩터·백엔드·DB·API/계약·인프라) → **companion 기본 생략**
  (deep-plan 정책 — `pipeline.md` 의 plan-render 분기는 사용자가 시각 렌더를
  원할 때만). Step 4 보고에 "원하면 plan 렌더 HTML 도 생성 가능" 한 줄만 남긴다.
  `.md` 를 heading/표로 다시 그린 렌더는 기본 경로에서 비용 대비 가치가 없다.

#### ERD companion — plan 이 DB 스키마/BE 데이터 모델을 수반하면 (UI 판정과 별개)

plan 이 **새 테이블·컬럼·관계 또는 BE 데이터 모델 변경**을 수반하면 ERD 를 HTML 로
생성한다 — 비UI plan 이라도 ERD 는 실제 도식 가치를 준다("데이터가 어떻게 엮일지").
생성 방법은 `erd` 스킬 3파일(이때 읽는다)을 그대로 따른다. 스키마는 Step 0 에서
Read 한 마이그레이션/모델에서 재구성한다(못 본 테이블/관계는 그리지 않고 footer 에
한계 명시). 산출은 plan 과 같은 디렉토리·basename 에 `-erd.html`, 역시 Artifact
publish. 판정: 스키마/관계가 plan 의 핵심이면 그린다 — 컬럼 한둘 추가뿐이면
과투자(생략, plan 텍스트로 족). `erd` 미설치면 그 사실을 말하고 생략.

### Step 4 — 제시하고 정지

`output-contract.md`(이때 읽는다)의 고정 블록으로 보고한다 — `result:` 한 줄 + 각
산출물의 상대경로. PLAN 행은 항상(`open` 명령 동반), `시안`·`ERD` 행은 만들었을
때만 넣되 딜리버러블은 Step 3 에서 publish 한 **artifact URL** 이다. 예:

```
result: <topic> PLAN 산출 — N steps, scope IN <…> / OUT <…>

산출물 — 열기:
- PLAN `docs/plans/2026-06-04-<topic>.md`  →  `open docs/plans/2026-06-04-<topic>.md`
- 시안 `docs/plans/2026-06-04-<topic>.html`  →  <artifact URL>

(`open` = macOS. Linux `xdg-open <path>`, Windows `start <path>`.)
```

### Step 4.5 — Linear 작업 등록 (optional, 확인 게이트)

PLAN 제시 후, Linear 작업 트리(parent 1 + PLAN Step 당 sub-issue 1)로 등록할지
**제안**한다. 메커니즘은 `cc/linear.md`(이때 읽는다) 그대로: ① MCP 감지 — 미설치면
가이드 한 번 + 스킵 제안(막지 않음) ② 만들 트리 미리보기 → 동의받은 **뒤에만**
생성(외부 write 라 자동 등록 금지) ③ 생성 후 sub-issue ID/URL 을 PLAN `.md` 에
기록. 판정: PLAN 이 2+ Step 이면 제안 가치 있음, 1 Step 사소 plan 이면 단일
이슈 또는 생략. 등록 실패/스킵이 deep-plan 의 성공을 깎지 않는다 — PLAN 자체가
이미 완성된 산출물이다.

### Step 5 — 다음 단계 제안 (제안만, 시작 안 함)

`next-skill-routing.md`(이때 읽는다 — 기억으로 추천 금지, 기억은 로컬 스킬로
편향된다)를 따라 한 번 추천한다. 요점:

- **설치 스킬을 Bash 로 스캔하지 마라** — available-skills 목록이 이미 컨텍스트에
  있다. 그 목록에서 valid-next 후보를 재선정한다(글로벌·플러그인 포함, 예시 이름에
  anchor 금지). `deep-plan` 자신은 제외.
- 빌드가 명백하면 Tier 1 단축(greenfield→`/forge`, 변경→`/renew`, 고장→`/hunt`),
  아니면 Tier 2 전체 후보(`linear-register` 분할 모드·`deep-research` 등)를 함께 본다.
- 빌드로 제안하면 plan 을 **이미 완료된 Phase-1 결과물**로 취급해 다시 인터뷰하지
  말라고 프레이밍한다(이중 인터뷰 회피). Acceptance(=eval) 항목이 그 빌드가 Phase 4
  에서 닫을 체크리스트이고, UI 면 `.html` 시안이 승인된 visual 계약임을 함께 짚는다.
- **`AskUserQuestion` 으로 제안만** 한다.

그리고 **여기서 멈춘다.** 다음 스킬 자동 시작 없음 — 무엇을 할지는 사용자가 정한다.

## Anti-patterns

- **구현 코드를 쓰기 / craft Phase 2~5 진입** — deep-plan 은 Phase 1 에서 멈춘다.
- **SSOT eager 일괄 읽기** — 위 표의 시점 전에 reference 를 몰아 읽는 것은 토큰
  낭비다. 분기에 진입할 때만 읽는다.
- **이미 crisp 한 요청을 인터뷰 / 인터뷰 발동 시 질문 묶기.**
- **UI plan 인데 `.html` 이 plan 표만 렌더** — UI 면 결과 화면 목업이어야 한다.
- **비UI plan 에 companion 자동 생성** — 기본 생략이 정책. 반대로 DB/BE plan 인데
  스키마가 핵심인 경우 ERD 미생성도 실패.
- **DESIGN.md 가 있는데 손으로 mockup**(토큰 위반 — design-context 절차로) /
  슬림 UI 에 `frontend-design`/`prototype` 과투자(inline 스케치로 족).
- **파일/계약을 Read/Grep 없이 거명** — Files 섹션은 검증된 것만.
- **다음 스킬 자동 시작 / 설치 스킬 Bash 스캔.**
