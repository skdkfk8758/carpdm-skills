---
name: deep-plan
description: 모호하면 먼저 인터뷰로 보강하고, 검증 가능한 구현 PLAN 문서(`docs/plans/…md`)를 도출하며, plan 의 결과물이 UI/UX 면 그 화면을 self-contained HTML 시안(목업)으로까지 시각화한 뒤 — 빌드하지 않고 — 멈춘다. 사용자가 무언가를 어떻게 만들지 PLAN, 설계, 기획안, 제안서, 접근법, 로드맵, 또는 UI 시안을 원하되 지금 당장 구현은 원하지 않을 때마다 사용한다 — "계획 세워줘", "이거 어떻게 만들지 설계해줘", "구현 말고 플랜만", "기획안/제안서 만들어줘", "approach 정리해줘", "design doc 작성", "UI 시안 뽑아줘", "어떻게 접근할지 정리", "plan this out", "/deep-plan" 같은 표현. 요청이 흐릿하면 한 번에 한 질문씩 Socratic 인터뷰로 보강하고, 이미 명확하면 인터뷰를 건너뛰고 곧장 plan 으로 간다. deep-interview 와 다르다 — deep-interview 는 번호 매긴 요구사항 spec 을 만들어 빌드 파이프라인으로 라우팅하지만, deep-plan 은 바로 실행 가능한 plan 문서 + HTML 시안을 산출하고 멈춘다. 실제로 기능을 구현/빌드(use forge)·버그 수정(use hunt)·기존 동작 변경(use renew)하려 할 때는 사용하지 말 것 — deep-plan 은 코드를 쓰지 않는다, plan 만 쓴다.
---

# Deep Plan — 인터뷰로 보강된 PLAN(+UI 시안) 도출, 빌드 없음

당신은 **계획을 세우지, 빌드하지 않는다.** 산출물은 두 개다: 검증 가능한 구현
PLAN 문서(`.md`), 그리고 그 plan 이 사용자 대면 UI 를 전달한다면 그 화면을 보여주는
self-contained HTML 시안(`.html`). 끝나면 멈춘다 — codex 리뷰도, TDD 도, 보안
페이즈도, 구현 코드도 없다. 그것들은 craft 빌드 파이프라인의 일이고, deep-plan 의
일이 아니다.

위험은 두 가지다: (1) 모호한 요청을 그대로 받아 흐릿한 plan 을 쓰는 것,
(2) UI plan 의 `.html` 이 plan 텍스트를 렌더만 하고 *결과 화면* 을 안 보여주는 것.
이 스킬의 흐름은 둘 다 막는다.

## 이것이 올바른 도구일 때

사용자가 무언가를 *어떻게* 만들지 — plan, 설계, 기획안, 제안서, 접근법, UI 시안 —
를 원하되 **지금 구현은 원하지 않을 때**. 형제 스킬과의 경계:

- **vs `deep-interview`** — deep-interview 는 번호 매긴 요구사항 **spec**(`REQ-F`/
  `REQ-N`)을 만들어 빌드 스킬로 *라우팅* 한다. deep-plan 은 바로 실행 가능한
  **plan 문서 + HTML 시안** 을 산출하고 *멈춘다*. 사용자가 "요구사항을 못 박고
  싶다"면 deep-interview, "어떻게 만들지 + 화면이 어떻게 보일지 보고 싶다"면
  deep-plan.
- **vs `forge`/`renew`/`hunt`** — 이들은 **빌드한다**. deep-plan 은
  구현 코드를 한 줄도 쓰지 않는다. plan 만 쓴다.

빌드/수정을 *지금* 하려 하면 deep-plan 이 아니라 해당 빌드 스킬이다.

## craft-core 재사용 (Phase 0+1 만, 그다음 정지)

deep-plan 은 craft 빌드 파이프라인과 같은 검증된 엔진을 쓰되 **앞의 두 페이즈만**
차용한다. 빌드 페이즈(2~5)는 절대 진입하지 않는다. 메커니즘은 복제하지 말고
공유 소스를 읽어라 — 그래야 규칙이 한 곳에 살고 drift 가 없다:

- 인터뷰 기법·grounding: `~/.claude/skills/craft-core/references/socratic.md`
- 문서 grounding(ADR/concept/guide): `~/.claude/skills/craft-core/references/context-adr.md`
- plan 섹션 + **HTML companion 규칙**: `~/.claude/skills/craft-core/references/pipeline.md`
  의 Phase 1 (특히 `.html` companion 분기 — UI 면 결과 UI 목업, 비UI 면 plan 렌더)
- 모호할 때의 측정 게이트·여섯 Socratic 유형: `~/.claude/skills/deep-interview/references/scoring.md`
  와 `~/.claude/skills/deep-interview/references/socratic-playbook.md`
- 종료 시 result 블록 규격(deep-* 공통): `~/.claude/skills/deep-interview/references/result-format.md`
- 다음 스킬 추천 규격(deep-* 공통): `~/.claude/skills/deep-interview/references/next-skill-routing.md`

이 파일들이 없으면(craft-core/deep-interview 미설치) 같은 원리를 직접 적용하되,
설치돼 있으면 항상 읽어서 한 소스를 따르라.

## 흐름

### Step 0 — Frame & ground (craft Phase 0)

- 작업유형과 한 줄 목표를 사용자에게 되짚는다.
- **Ground first.** plan 이 건드릴 코드(가능하면 code-graph/LSP, 아니면 영향
  반경에 한정한 Read/Grep)와 관련 기존 문서(ADR/concept/guide — `context-adr.md`)를
  scope-read 한다. plan 은 standing 결정을 재론하지 않고 존중해야 하고, 파일/계약을
  추측이 아니라 실제로 anchor 해야 한다.
- worktree 는 만들지 않는다 — deep-plan 은 코드를 편집하지 않는다.

### Step 1 — 적응형 보강 게이트 ("보강이 필요하다면")

요청이 이미 다음을 *모두* 명확히 진술하는지 판정한다: 검증 가능한 **goal**,
**scope IN/OUT**, **성공 기준**, 그리고 (UI 라면) 어떤 화면/플로우인지.

- **이미 crisp** → 인터뷰를 **건너뛴다.** 왜 건너뛰는지 한 줄로 말하고(예:
  "goal·scope·criteria 가 이미 명확 — 인터뷰 생략하고 plan 으로 갑니다") Step 2 로.
  이미 명확한 요청을 인터뷰하는 것은 마찰이다.
- **모호** → **측정 게이트 인터뷰** 를 돈다. `socratic.md` 기법 + deep-interview 의
  `scoring.md`/`socratic-playbook.md` 를 차용:
  - 먼저 토폴로지(1~6개 큰 조각, active/deferred)를 한 번 고정한다.
  - **라운드당 한 질문** — 절대 묶지 말 것. 매 라운드 가장 약한 차원을 점수로
    찾아 여섯 Socratic 유형 중 맞는 하나로 공략하고, 짧은 라운드 테이블(차원 점수,
    ambiguity %, 다음 조준)을 보고한다.
  - **ambiguity ≤ threshold** 에서 멈춘다. 기본 0.20; `--quick`=0.35 / `--deep`=0.10.
    어떤 질문보다 먼저 threshold 를 한 줄로 명시해 결승선을 보인다.
  - 사용자가 "그만 / plan 짜 / 이 정도면 돼" 하면 따른다 — 현재 ambiguity 와
    미해결을 명시한 뒤 결정화.

판정이 애매하면(crisp 인지 모호인지) 모호 쪽으로 기운다 — 흐릿한 plan 보다
질문 한두 개가 싸다.

### Step 2 — PLAN 문서 작성 (craft Phase 1 의 plan, 빌드 제외)

`docs/plans/YYYY-MM-DD-<topic>.md` (프로젝트가 다른 plan 위치를 쓰면 그곳)에
쓴다. craft Phase 1 섹션을 그대로 따르되, deep-plan 은 빌드하지 않으므로 Steps 와
Acceptance 는 *실행* 이 아니라 *무엇을 할지/무엇이 done 인지의 계획* 으로 남는다:

```
# <topic>
## Goal (testable success criteria)
## Scope (IN / OUT)
## Files (verified — path : why it changes)   ← Read/Grep 으로 검증, 추측 금지
## Steps (each step → its verify check)
## Risks
## Security surface
## YAGNI (deletions this change would make)
## Acceptance (numbered, single, checkable conditions)
```

열어보지 않은 파일/심볼을 거명하는 것은 실패다. Files 는 실제로 확인한다.

### Step 3 — HTML 시안 (정적 시각 목업)

같은 경로에 `.html` 확장자로 self-contained companion 을 쓴다(inline `<style>`,
외부 asset 없음, 브라우저에서 바로 열림). 무엇을 보여주는지는 **plan 이 사용자
대면 UI 를 전달하는지** 에 달렸다 — `pipeline.md` Phase 1 의 companion 분기를 따른다:

- **UI / 프론트엔드 plan**(화면·컴포넌트·페이지·플로우·보이는 UX 변경) → plan 이
  구현된 후 사용자가 **보게 될 결과 UI 의 목업.** 실제 인터페이스(chrome, pane,
  컨트롤, 상태)를 배치하고, UX 를 명확히 하는 곳은 inline `<script>` 로 가볍게
  인터랙티브하게 만들어 핵심 인터랙션을 *시연* 한다(텍스트 기술이 아니라). 출시
  제품으로 오인되지 않게 "mockup" 을 눈에 띄게 표식한다. plan 의 표는 `.md` 에
  남는다; `.html` 은 결과의 그림이다.
- **비 UI plan**(리팩터·백엔드·DB·API/계약·인프라) → "결과 UI" 가 없으므로
  companion 은 **plan 의 렌더링**: 새 내용 없이 섹션을 heading+블록으로, Scope IN/OUT
  과 Steps→verify 를 표로, 파일 경로는 코드 스타일로 시각화.
- **혼합**(백엔드 작업이 있는 UI 변경) → UI 는 목업, 그 아래 비UI 섹션은 plan 렌더.

### Step 4 — 제시하고 정지

`result-format.md` 의 고정 블록으로 산출물을 보고한다 — `result:` 한 줄 + 각
산출물의 상대경로와 `open` 명령. PLAN 행은 항상, `시안` 행은 UI plan 이라 `.html`
을 만들었을 때만 넣는다(비UI 면 시안 행 생략). 예:

```
result: <topic> PLAN 산출 — N steps, scope IN <…> / OUT <…>

산출물 — 열기:
- PLAN `docs/plans/2026-06-04-<topic>.md`  →  `open docs/plans/2026-06-04-<topic>.md`
- 시안 `docs/plans/2026-06-04-<topic>.html`  →  `open docs/plans/2026-06-04-<topic>.html`

(`open` = macOS. Linux `xdg-open <path>`, Windows `start <path>`.
 경로는 터미널에서 클릭으로도 열린다.)
```

### Step 5 — 다음 단계 제안 (제안만, 시작 안 함)

산출물을 제시한 뒤, 사용자가 *다음에* 무엇으로 이어가면 좋을지 한 번 추천한다.
deep-plan 은 "순수 산출" 도구라 **빌드로 자동 라우팅하지 않는다** — 이건 다음
스킬을 **시작하는 게 아니라 제안하는** 것이고, 시작 여부는 항상 사용자가 정한다.

규칙은 `next-skill-routing.md`(deep-interview 와 공유 — 복제 금지)를 읽어 적용한다.
deep-plan 특이사항만:

- **설치 스킬을 Bash 로 스캔하지 마라** — available-skills 목록이 이미 컨텍스트에
  있다. 거기서 valid-next 필터로 후보만 남긴다.
- 입력은 방금 만든 **PLAN 문서**다. 가장 흔한 다음 단계: plan 을 받아 빌드
  (Tier 1: greenfield→`/forge`, 변경→`/renew`, 고장→`/hunt`) 하거나 이슈로 분해
  (`to-issues`). `deep-plan` 자신은 후보에서 제외(이미 만들었다).
- 빌드로 제안하면 plan 을 **이미 완료된 Phase-1 결과물**로 취급해 다시 인터뷰하지
  말라고 프레이밍한다(이중 인터뷰 회피).
- **`AskUserQuestion` 으로 제안만** 한다.

그리고 **여기서 멈춘다.** codex 리뷰·TDD·보안·구현 없음, 다음 스킬 자동 시작 없음 —
deep-plan 은 plan 과 시안을 산출하고 다음 단계를 *제안*하는 도구다. 무엇을 할지는
사용자가 정한다.

## Anti-patterns

- **구현 코드를 쓰기** — deep-plan 은 계획만 한다. 한 줄도 빌드하지 말 것.
- **Phase 2~5 진입**(codex 리뷰·TDD·보안) — 그건 craft 빌드 페이즈다; deep-plan 은
  Phase 1 에서 멈춘다.
- **이미 crisp 한 요청을 인터뷰** — 적응형 게이트의 핵심은 *건너뛸 줄 아는 것*.
- **HTML companion 규칙을 복제** — `pipeline.md` 의 한 소스를 읽어라(중복 = drift).
- **UI plan 인데 `.html` 이 plan 표만 렌더** — UI 면 결과 화면 목업이어야 한다.
- **파일/계약을 Read/Grep 없이 거명** — Files 섹션은 검증된 것만.
- **질문 묶기** — 인터뷰가 발동하면 라운드당 한 질문.
- **다음 스킬 자동 시작** — Step 5 는 `AskUserQuestion` 제안까지다. forge/renew/hunt
  등을 직접 호출하지 말 것(제안 ≠ 시작).
- **설치 스킬 Bash 스캔** — available-skills 가 이미 컨텍스트에 있다. `ls`/캐시 긁기 금지.
