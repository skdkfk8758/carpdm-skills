# Craft Pipeline — Socratic → Adversarial Plan → Dynamic TDD → Secure Verify

`forge`(신규 기능), `renew`(기존 갱신),
`hunt`(버그 수정) 뒤에 있는 공유 4-phase 엔진. 호출 스킬이
작업유형 framing — 자신의 Socratic 초점과 TDD 사이클이 어디서 시작하는지 — 을 공급한다. 이 파일은
이들 모두가 돌리는 공통 척추다.

파이프라인의 핵심은 모호한 요청이 모호한 코드로 변하지 않게 하는 것이다:
요청은 *테스트 가능한 spec* 이 되고, spec 은 코드가 존재하기 전에 *공격받고*,
구현은 *test-first* 로 일어나며, *검증되고
안전*하기 전엔 아무것도 출시되지 않는다. phase 스킵은 사용자가 명시적으로 그렇게 말할 때만 허용된다 —
그렇지 않으면 스킬의 가치가 사라진다.

## Execution mode — linear (기본) vs orchestrated

기본적으로 이 엔진은 **linear** 로 돈다: 당신이, 이 단일 세션에서, 모든
phase 를 수행한다. 거의 모든 작업에 적합한 모드이며, 이 파일의 나머지는
이를 기술한다.

**orchestrated** 모드 — 영속적 멀티에이전트 설계 council +
dynamic-workflow 빌드 + 검증 패널 — 으로 에스컬레이트한다. 이는 두 가지 방식으로 요청된다:

- **명시적 신호** — "convene a design council", "full panel
  treatment", "팀으로 설계하고 워크플로로 구현해줘", "maximum rigor, spare no
  agents", "council 소집", 또는 요청 어디든 짧은 정규 키워드 **`[council]`** /
  **`--council`** 같은 표현. 직접 따른다 — 물어볼 필요 없다.
- **stakes 신호에 대한 제안** — 사용자가 council 을 요청하지 않았지만
  작업이 고위험이거나 긴장한 신호를 보일 때 ("이거 중요한데", "리스크 커서",
  "제대로 하고 싶어", "불안해", "this is critical", "don't get this wrong"), 또는
  작업이 객관적으로 고위험일 때 (auth / payments / 외부 호출자가 있는 계약 변경 /
  6+ 파일), Phase 1 전에 `AskUserQuestion` 으로 **한 번 제안한다**:
  대략 "고위험이라 멀티에이전트 council 모드로 갈 수도 있어요 (느리지만 적대적
  설계검토 + 구현 후 의도검증). 기본 linear로 갈까요, council로 갈까요?". 거부되거나
  답이 없으면 **linear** 를 기본으로 하고, 최대 한 번만 물어라 — 매 phase 마다
  다시 제안하지 말 것.

stakes 신호 없는 가벼운 "build X" / "fix Y" / "refactor Z" 는
에스컬레이션이 아니다 — 조용히 linear 로 유지한다. 이는 작업유형과 직교하는
강도(intensity) 선택이다: forge / renew / hunt 어느 것이든 두 모드 중 하나로 돌 수 있다.

에스컬레이트되면 `orchestrated.md` 를 읽고 아래 linear 지침 대신 그것의
team-mode + Workflow 토폴로지로 다섯 phase 를 구동한다. phase
*내용* 과 당신의 작업유형 Phase 1 초점 / Phase 3 TDD 진입점은
변하지 않는다 — 실행 구조만 다르다. 한 가지 모델 변경:
orchestrated 빌드는 **sonnet** 에서 돈다 (아래 linear Phase 3 은 opus 에서 돈다).

## Phase 0 — Frame & isolate

- 작업유형과 한 줄 목표를 사용자에게 되짚어준다.
- Isolation (프로젝트 룰): 6+ 파일, 아키텍처 변경, 또는 3+ 파일 리팩터
  → 편집 전에 worktree 로 브랜치한다. 스킵한다면, 첫 응답에서 이유를 말한다.
  1–2 파일 동일주제 변경은 현재 브랜치에 머물러도 된다.
- **Linear binding (optional, graceful).** 이 작업에 연결된 Linear 이슈가 있으면
  — 사용자가 이슈 ID/URL 을 줬거나, 이어받은 PLAN `.md` 에 deep-plan 이 적어둔
  sub-issue 가 있으면 — `~/.claude/skills/craft-core/references/linear.md` 를 읽고
  그 활성 이슈를 **In Progress 로 자동 전이**한다. Linear MCP 미설치이거나 연결된
  이슈가 없으면 **묻지 말고** Linear 없이 평소대로 진행한다 — Linear 는 워크플로를
  증강할 뿐 게이트하지 않는다. 상태 전이 실패는 빌드를 막지 않는다(경고만).

## Phase 1 — Socratic 인터뷰 → 플랜

**요구사항이 이미 확정됐으면 스킵.** 사용자가
`deep-interview` 요구사항 spec (예: 번호 매겨진
`REQ-F`/`REQ-N` 항목과 요구사항별 acceptance 가 있는 `docs/specs/<slug>.md`) 을 가리키거나, 건네주면, 그것을
완료된 Phase-1 산출물로 취급한다 — 재인터뷰를 **하지** 말 것. 읽고, 코드와 여전히
일치하는지 확인하고 (가벼운 ground-check, 새 인터뷰 아님), 그 요구사항을
spec 으로 이어가서, 곧장 Phase 2 로 간다. 이미 확정된 spec 에 대해
인터뷰를 재실행하는 것은 이중인터뷰 anti-pattern 이다. 이 phase 의 나머지는
그런 spec 이 없을 때만 적용된다.

같은 규칙이 **`deep-plan` PLAN** 에도 적용된다. 사용자가 `deep-plan` 이 만든
PLAN (`docs/plans/<…>.md` — Goal / Scope / Files / Steps / **Acceptance(=eval 항목)**
섹션, 그리고 UI 면 곁의 `.html` 시안) 을 가리키거나 건네주면, 그것을 완료된 Phase-1
산출물로 취급한다 — 재인터뷰 **금지**, ground-check 만 (코드와 여전히 일치하는지).
PLAN 의 **Acceptance 항목이 곧 이 빌드가 Phase 4 에서 하나씩 닫을 eval 체크리스트**다
— 그대로 이어받는다. Acceptance 가 `[AUTO]`/`[HUMAN]` 태그 없이 왔으면(구버전
deep-plan) 지금 한 번 아래 태그 규칙으로 빠르게 분류해 태그만 붙인다 (재인터뷰 아님).
곁에 `.html` 시안이 있으면 그것이 **승인된 mockup**(visual 계약)이다 — Phase 3 가
거기에 충실히 구현하고 Phase 4 시안 충실도 게이트가 대조한다.

`socratic.md` 를 읽어라. **먼저 ground 하고, 그다음 물어라:** 작업이
건드리는 코드 (가능하면 프로젝트 code-graph/LSP, 아니면 Read/Grep) 와 관련된
기존 프로젝트 문서 — ADR/concept **그리고 guide/reference 트리**
(`docs/guides/`, `docs/reference/`) (`context-adr.md`) — 를 scope-read 한다.
그래야 질문이 코드에 anchor 되고 플랜이 standing 결정과 문서화된 절차를
재론하지 않고 존중한다. 그다음 Socratic
질문법으로 요청을 낯선 사람에게 건넬 수 있는 spec 으로 변환한다. **이 phase 에서는
구현 코드를 쓰지 말 것.**

다음을 모두 진술할 수 있을 때까지 (20개 질문 폭탄이 아니라 작고 집중된 클러스터로)
질문을 계속한다:

- **Goal** 을 검증 가능한 성공 기준으로 ("returns 400 on empty body", 아니라
  "handles bad input").
- **Scope IN / OUT** — 이 변경이 무엇을 하고 명시적으로 무엇을 건드리지 않는가.
- **영향받는 파일 & 계약** — Read/Grep 으로 검증, 절대 추측 금지. 열어보지 않은
  파일이나 심볼을 거명하는 것은 Phase-1 실패다.
- **엣지 케이스 & 실패 모드.**
- **보안 surface** — 이 변경이 노출하거나 의존하는 모든 입력, auth 경계, secret,
  외부 호출.
- **YAGNI 삭제** — 이 변경이 orphan 으로 만드는 데드 경로, 같은 변경에서
  제거 ("나중 PR" 아님).

플랜을 `docs/plans/YYYY-MM-DD-<topic>.md` (또는 프로젝트가 그걸 쓴다면
`.planning/<phase>/`) 에 쓴다. 섹션:

```
# <topic>
## Goal (testable success criteria)
## Scope (IN / OUT)
## Files (verified — path : why it changes)
## Steps (each step → its verify check)
## Risks
## Security surface
## YAGNI (deletions in this change)
## Acceptance (the checks that mean "done" — each a numbered, single, checkable
##   condition tagged [AUTO] or [HUMAN]; the skill's acceptance / regression /
##   characterization test IS the item, not vague prose like "handles errors")
```

각 Acceptance 항목 앞에 **`[AUTO]` 또는 `[HUMAN]`** 태그를 붙인다 (예:
`1. [AUTO] 빈 비번 → 400` / `2. [HUMAN] 로그인 후 대시보드 화면이 안 깨짐`):

- **`[AUTO]`** — 결정론적·회귀민감·보안·계약 수준. Phase 3 자동 테스트가 커버해야 한다.
- **`[HUMAN]`** — 시각 판단·UX 의도·카피 톤·주관적 사용성, 또는 자동화 비용이 가치를
  크게 초과하는 일회성 검증. Phase 3 테스트 의무에서 제외하되 Phase 4 보고에 노출한다.
- **보안 불변식**(auth / payment / crypto / permission 경계)은 절대 `[HUMAN]`-only 금지 —
  항상 `[AUTO]` 로 잠근다.

`.md` 와 나란히, 같은 경로에 `.html` 확장자로 리뷰 친화적 HTML companion 을
쓴다 (`docs/plans/YYYY-MM-DD-<topic>.html`). 브라우저에서 바로 열리도록
self-contained 하게 만든다 (inline `<style>`, 외부 asset 없음). companion 이
*보여주는* 것은 플랜이 사용자 대면 UI 를 전달하는지에 달려 있다:

- **UI / 프론트엔드 플랜** (화면, 컴포넌트, 페이지, 플로우, 또는 보이는
  UX 변경): companion 은 **플랜이 구현된 후 사용자가 보게 될 결과 UI 의
  목업** 이다 — 플랜 텍스트의 렌더링이 아니라. 실제 인터페이스 (chrome, pane,
  컨트롤, 상태) 를 배치하고, UX 를 명확히 하는 곳에서는 inline `<script>` 로 가볍게
  인터랙티브하게 만들어 핵심 인터랙션이 기술만 되지 않고 시연되게 한다.
  출시된 제품으로 오인되지 않게 목업임을 눈에 띄게 표시한다. 플랜의 테이블은
  `.md` 에 남는다; `.html` 은 결과의 그림이다.
- **비 UI 플랜** (리팩터, 백엔드, DB 마이그레이션, API/계약 변경, 인프라):
  "결과 UI" 가 존재하지 않으므로, companion 은 **플랜의 렌더링**
  이다 — 새 내용 없이, 그냥 리뷰용으로 Markdown 을 시각화: 각 섹션을
  heading + 블록으로, Scope IN/OUT 과 Steps→verify 쌍을 테이블로, 파일 경로는
  코드 스타일로.

플랜이 혼합이면 (백엔드 작업이 있는 UI 변경), UI 는 목업으로 만들고 그 아래
비 UI 섹션은 플랜 렌더링으로 둔다. Phase 2 에서 codex 평결이 `.md` 에
들어오면, 둘이 동기 유지되도록 `.html` 을 갱신한다.

**Eval 체크리스트 패널 (companion 타입과 무관 — 항상).** companion 종류가
무엇이든, `.html` 은 플랜의 **Acceptance(=eval) 항목** 을 체크리스트 패널로 렌더한다 —
각 항목을 그 `[AUTO]`/`[HUMAN]` 태그와 함께 보여, 리뷰어가 "구현이 끝나면 무엇으로
done 을 측정하는지" 를 시안·플랜과 **나란히** 본다. UI companion 이면 목업 옆/아래
패널로, 비UI 면 plan 렌더 안의 한 섹션으로. SSOT 는 `.md` 의 Acceptance 섹션이고 이
패널은 그 렌더 뷰다 (`.md` 가 바뀌면 패널도 갱신 — 위 동기 규칙과 같다). 이 패널이
빌드 스킬 Phase 4 가 항목별로 닫을 바로 그 eval 장부의 사람용 그림이다.

Phase 2 전에 사용자에게 플랜 확인을 요청한다. 사용자가 보지 못한 플랜은
플랜이 아니다.

## Phase 2 — Adversarial plan review (codex)

`codex-review.md` 를 읽어라. 플랜을 codex 에게 적대적 리뷰어로서 넘긴다 —
그 일은 무엇이 잘못됐는지 찾는 것이다: 숨은 가정, 누락된 엣지 케이스, 보안
구멍, 더 단순한 경로, scope creep, **그리고 플랜이 ADR 가 필요한 아키텍처
결정을 하거나 standing ADR 과 충돌하는지**. 모든 *blocking* 발견을 플랜에
다시 접어 넣는다. codex 가 blocking 이의를 제기하지 않거나 2 라운드를
마칠 때까지 재리뷰한다. 각 라운드의 평결을 플랜에 기록한다.

## Phase 3 — Dynamic workflow: task split + TDD (opus)

`dynamic-tdd.md` 를 읽어라. `Workflow` 도구로 승인된 플랜을 atomic
태스크로 쪼개고 각각을 엄격한 TDD 사이클 — **red → green →
refactor** — 로 구동하되 구현 에이전트는 `model: 'opus'` 로 핀한다. 태스크들을
pipeline 하고; 태스크는 자신의 테스트가 green 일 때만 완료된다. 플랜이
계약이다: 각 구현 에이전트는 코드를 쓰기 전에 승인된 플랜 (`.md`) 과
관련 프로젝트 guide (`docs/guides/`) 를 다시 읽고, 플랜에 없는 것은 Phase 1 로
돌아가지 않고서는 구현하지 않는다.

**UI / 프론트엔드 작업의 visual 레이어.** 빌드가 사용자 대면 UI(화면·컴포넌트·
페이지)를 만들면 behavior 와 미감을 **분리**해 다룬다 — TDD(red→green→refactor)는
*behavior*(상태·props·이벤트·데이터·접근성 계약)를 잠그고, *visual/미감* 레이어는
디자인 스킬로 빌드해 plan 단계의 시안과 일치시킨다(미감은 테스트로 단언하지 않는다).
빌드가 미감을 새로 발명해 합의된 시안과 따로 노는 것이 가장 흔한 UI 빌드 실패다 —
다음으로 라우팅한다:

- **승인된 mockup 이 있으면**(deep-plan companion `.html` / 이전 시안) → 그것에
  **충실히 구현**한다. 시안이 곧 visual 계약이다.
- **`DESIGN.md` / 추출 디자인 시스템이 있으면** → `imprint` 로 토큰 충실 재현
  (raw hex/px 하드코딩 0 — 모든 값이 token 으로 역추적).
- **mockup 도 디자인 시스템도 없는 net-new UI** → `frontend-design` 으로 고품질
  visual 레이어를 만든다(제네릭 AI 미감 회피).

매칭 디자인 스킬이 미설치면 그 원칙(시안/토큰 충실, 제네릭 미감 회피)을 직접 적용한다.
비 UI 빌드(백엔드·리팩터·CLI 등)는 이 분기와 무관 — 평소 TDD 그대로.

워크플로는 구현 / 검증 에이전트를 기본 subagent 로 돌린다 — 프롬프트가 곧 계약이다.
정확한 골격은 `dynamic-tdd.md` / `orchestrated.md` 참조. (에이전트
"cleanup" 단계는 존재하지도 필요하지도 않다 — 워크플로 subagent 는 일회성이고 유일한
영속 에이전트인 orchestrated council 은 §5 에서 정리된다.)

## Phase 3.5 — Simplify review pass (forge / renew / hunt)

`simplify-pass.md` 를 읽어라. `forge` / `renew` 구현이나 `hunt` 수정이 Phase 3 에서
green 이 된 후: 방금 작성한 diff 가 정리(simplify)가 필요한지 검토하고, 필요하면
`/simplify` 스킬로 behavior-preserving 정리 — 재사용/단순화/효율/altitude — 를
`AskUserQuestion` 으로 **한 번 제안** (기본 off) 후 돌린다. `/simplify` 미설치 시
같은 정리를 직접 수행 (`convention-guide.md`, 프로젝트 lint/rule 및 `docs/guides/`
참조). Phase 3 테스트가 behavior 핀이다; 정리 후 테스트가 red 가 되면 그 단계가
behavior 를 바꾼 것이다 — 되돌린다. trivial 변경, 거부, 또는 정리할 게 없으면 곧장
Phase 4 로 스킵.

## Phase 4 — Secure verify & intent conformance

`security.md` 를 읽어라. 프로젝트 검증 게이트 (tests / typecheck / lint /
build), diff 에 대한 **correctness 리뷰** (`/code-review` — 테스트가 못 잡은 버그만,
effort 는 실행 모드를 따름; 발견은 바로 고치지 말고 회귀 테스트 먼저), 그리고
diff 에 대한 **보안 pass** 를 돌린다. correctness·보안 발견 모두 진짜로 보고하기
전에 적대적으로 검증한다 (반박을 시도). 아무것도 red 로 출시하지 않는다.
출시 전에, 플랜의 **Acceptance(=eval) 항목을 명시적 완료 장부로 삼아 하나씩**
닫는다 (plan 이 deep-plan 에서 왔으면 사용자가 시안에서 본 그 eval 패널이 이 장부의
그림이다 — 같은 항목을 닫는 것이다). 태그별로 **하이브리드**로 검증한다:

- **`[AUTO]` 항목** — Phase 3 테스트로 자동 pass / fail. fail 이면 confirmed gap →
  아래 loop-back 으로 Phase 3 재진입해 그 항목만 다시 green (사람 개입 없이 자동).
- **`[HUMAN]` 항목** — 자동 단정 불가라 `not-run` 으로 흘리지 말고 **사용자와 하나씩
  walk** 한다: 항목을 보여주고, (UI 면) 빌드 결과를 시안에 대조한 소견을 곁들여,
  `pass / 조정 필요 / 잔여 리스크로 수용` 중 하나를 사용자와 합의한다. "조정 필요" 는
  confirmed gap 으로 Phase 3 재진입, "잔여 리스크 수용" 만 wrap 에 남긴다 (출시 막는
  red 아님). 합의 없이 조용히 not-run 으로 넘기지 말 것.

eval 장부가 닫히는 조건: **모든 `[AUTO]` 항목 green AND 모든 `[HUMAN]` 항목이
사용자와 walk 되어 pass 또는 명시 수용**. 보안 불변식은 `[HUMAN]`-only 금지라 항상
`[AUTO]` 로 자동 잠긴다 (Phase 1 규칙).

### Intent & conformance 판정 — loop-back 게이트

verify(tests / correctness / security) 와 Acceptance 체크가 green 이어도, 그것은
빌드가 *plan 의도대로* 지어졌다는 보장이 아니다 — 테스트는 통과하면서 plan Goal
에서 벗어날 수 있고, 빌드가 합의된 시안과 따로 놀 수 있다(가장 흔한 UI 빌드 실패).
그래서 출시 직전, 너 자신이 designer 모자를 쓰고(linear 에선 plan 을 쓴 게 너 자신
이라 의도를 보유한다) 빌드 결과를 plan 의도에 대조한다. orchestrated 의 §4 Stage B
intent judgment 를 단일 세션용으로 경량화한 것이다.

- **의도 일치 판정 (항상).** diff 를 plan Goal / Acceptance 에 비춰 각 deviation 을
  세 가지로 분류한다:
  - **Confirmed gap** — plan Goal/Acceptance 로부터의 진짜 deviation → 새 atomic
    태스크로 **Phase 3 으로 돌아간다** (그 delta 만 TDD 로 짓는다).
  - **Out of scope** — plan 이 의도적으로 제외한 올바른 behavior → 이유와 함께
    기록하고 기각한다.
  - **Plan defect** — 빌드는 맞지만 *plan* 이 무언가 빠뜨림 → plan 을 amend 하는
    짧은 Phase 1 micro-round, 그다음 그 delta 를 Phase 3.

  이 판정은 추가 에이전트 없이 메인 세션이 한다 — 이미 plan·diff 컨텍스트를 보유해
  싸다.

- **시안 충실도 게이트 (승인 mockup 이 있는 UI 작업만).** Phase 3 가 충실 구현
  하라고 지시한 승인 mockup(deep-plan companion `.html` / 이전 시안)이 있으면, 결과를
  그것에 직접 대조한다 — mockup 과 구현 코드/렌더를 비교해 레이아웃·간격·색·컴포넌트
  구조가 시안과 *일치*하는지 본다(미감 점수가 아니라 시안과의 일치; 시안이 곧 visual
  계약 — Phase 3 SSOT). 벗어난 부분은 confirmed gap 으로 친다. 이는 위 `[HUMAN]`
  not-run 과 구분된다 — 시안과의 *구조적 일치*는 메인이 객관 판정할 수 있어 게이트로
  치고, 순수 미감·UX 질감만 `[HUMAN]` 잔여 리스크로 남긴다. mockup 없는 net-new
  UI·비 UI 빌드엔 비적용.

  **대조 방법 — 실제 렌더 우선(vision).** 코드를 읽는 데 그치지 말고, 가능하면
  빌드 UI 를 실제로 띄워 *시각적으로* 대조한다: dev 서버 또는 정적 파일을 열고
  chrome MCP(`mcp__claude-in-chrome__take_screenshot` 또는 동등 도구)로 결과 화면을
  캡처해 승인 mockup `.html` 과 나란히 본다 — 레이아웃·간격·색·컴포넌트 구조의 어긋남은
  코드만 읽어선 놓치기 쉽다. 캡처한 스크린샷과 mockup 을 직접 비교해 deviation 을
  confirmed gap 으로 분류한다. chrome MCP 미설치·헤드리스 불가·렌더 불가 경로면
  코드/렌더 텍스트 대조로 폴백한다(게이트는 유지, 대조 방법만 격하한다).

- **게이트.** **verify green AND confirmed gap 없음**일 때만 출시한다. confirmed gap
  이 있으면 Phase 3(또는 plan defect 면 Phase 1 micro-round)으로 돌아가 delta 를 짓고
  Phase 4 를 다시 돈다 — orchestrated 의 Stage A→B→Phase 3→A loop 의 linear 대응이다.

- **한계 (정직히).** linear 엔 영속 designer 가 없어 **메인 세션이 designer 겸
  빌더**다 — 자기 빌드를 자기가 판정하는 self-judgment 라 독립성이 낮다(자기 구현을
  관대히 볼 편향). 의도 deviation 이 의심스럽거나 설계 리스크가 크면 orchestrated 로
  가라 — 거기선 빌드와 분리된 독립 designer + adversary 가 판정한다. 이 게이트는 그
  독립 판정의 *경량 근사*다.

## Phase 5 — Wrap

- 요약: 무엇이 바뀌었는지, 추가된 테스트, 보안 평결, intent-conformance 평결(해소한
  confirmed gap / 남은 시각 `[HUMAN]` 잔여 리스크), 잔여 리스크.
- 영속적 결정/지식 기록 (`context-adr.md`): 작업이 **ADR 감** 결정을
  했다면, `docs/adr/NNN-slug.md` 를 쓰고 registry 를 갱신한다;
  **재사용 가능한 context** 를 확립했다면, `docs/concepts/` 페이지를 쓰거나 갱신한다.
  진짜로 가치 있을 때만 — 일상적 작업에 문서를 제조하지 말 것.
- 사용자가 요청하지 않으면 commit 이나 push 하지 말 것.
- **Linear 상태 전이 (활성 이슈가 있을 때만).** Phase 0 에서 In Progress 로 옮긴
  활성 이슈가 있으면, verify 가 green 이고 Acceptance 장부가 닫힌 지금
  `linear.md` 의 전이 맵대로 **In Review 로 자동 전이**한다(Done 은 머지 시점 —
  `land` 가 처리). Linear 없거나 이슈 없으면 생략. 전이 실패는 wrap 을 막지 않는다.
- **완료 신호 (`result:` — 전 스킬 공통, `~/.claude/skills/craft-core/references/output-contract.md` L1):**
  마지막 메시지를 `result:` 한 줄로 못 박는다 — 무엇이 바뀌었는지 + 추가 테스트 +
  보안 평결(예: `result: <기능> 구현 — N 테스트 통과, 보안 pass`). 빌드형이라 산출물은
  커밋이므로 열기 블록 대신 변경 요약을 가리킨다(L2 비적용). 백그라운드 잡 classifier
  가 이 줄로 완료를 판정하니 글자 그대로 `result:` 로 시작하고 self-contained 로.
- **다음 스킬 제안 (post-build routing — 추천만, 자동 시작 금지):** 빌드 사이클이
  끝났으니 사용자가 다음에 무엇으로 이어가면 좋을지 *한 번* 제안한다. 산출물(spec/
  plan)을 받아 *전진*시키는 deep-* 의 next-skill-routing 과는 **맥락이 다르다** —
  여기는 *작업 사이클 종료* 라, 자연스러운 다음은 전진이 아니라 정리/랜딩이다:
    - 변경을 PR 로 push 했다 → `/land` (CI 통과 후 머지 + 로컬/워크트리 정리) 제안.
    - 시점 문서·로그가 쌓였다 (오래된 plan, 랜딩된 handoff, agent 로그) → `/sweep`
      (정리) 제안.
  위 `land`/`sweep` 은 *예시*일 뿐 고정 목록이 아니다 — available-skills 목록을 실제로
  훑어 정리/검증 성격의 후보를 열거하라. 글로벌·플러그인도 동등 후보다(예: 머지 전
  `/verify`·`/code-review` 로 변경 검증, `understand-anything:understand` 로 결과 구조
  파악). 두 이름에 anchor 되지 말 것.
  메커니즘은 next-skill-routing 과 동일하다 — `AskUserQuestion` 으로 추천만 하고,
  설치된 스킬은 available-skills 컨텍스트에서 읽으며 (`ls ~/.claude/skills/` Bash
  스캔 금지), **절대 자동 시작하지 않는다**. 제안할 자연스러운 다음이 없으면 (작은
  변경, push 안 함, 정리할 것 없음) 생략한다 — 매번 밀어붙이지 말 것.

## Anti-patterns (이 파이프라인 전체가 이것들을 막으려 존재한다)

- spec 이 테스트 가능해지기 전에 코딩 (Phase 1 스킵).
- 사용자의 첫 표현을 완전한 spec 으로 취급.
- "플랜이 괜찮아 보여서" codex 리뷰 스킵 — 플랜이 괜찮아 보일 때가
  바로 적대자가 가장 유용한 때다.
- Phase 3 에이전트가 `model: 'opus'` 대신 더 싼 tier 로 폴백하게 두기.
- 보안 pass 를 돌리지 않고 테스트 green 을 보고하기.
