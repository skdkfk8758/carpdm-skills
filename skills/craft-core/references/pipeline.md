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
변하지 않는다 — 실행 구조만 다르다. 모델 tier 도 동일:
orchestrated 빌드도 linear Phase 3 과 같이 **opus** 에서 돈다 (linear 대비 달라지는 건 실행 구조 = team-mode council 토폴로지뿐).

## Task 진행 체크리스트 (전 phase 공통 — 항상)

파이프라인이 돌기 시작하면 사용자가 대화턴에서 진행을 따라갈 수 있도록, **Phase 0
진입 직후** 네이티브 Task 도구로 페이즈 체크리스트를 시드한다. (Phase 1 의 HTML
eval 체크리스트 패널과는 별개 개념 — 그건 Acceptance 장부의 그림이고, 이것은 세션
진행 표시다.)

- **생성** — `TaskCreate` 로 Phase 0~5 를 항목당 1페이즈로 시드한다(기본 5~10 항목,
  세분 포함 15 미만). 항목 텍스트는 self-contained 하게(예: "Phase 2 — codex 적대
  플랜 리뷰").
- **전이** — 각 페이즈 진입 시 `TaskUpdate` 로 `in_progress`, 그 페이즈의 verify 가
  닫힐 때 `completed`. 페이즈 경계마다 빠짐없이 — wrap 시점엔 전 항목 completed.
- **긴 페이즈(Workflow 한 방 구간 — Phase 3 등)** — 내부 진행을 Task 로 세분하지
  않는다(Workflow 실행 중 메인 루프가 잠들어 갱신 불가). 해당 페이즈 항목 하나를
  in_progress 로 유지하고, 대신 Workflow 스크립트의 `phase()`/`log()` 를 충실히
  작성해 진행트리가 그 구간의 라이브 표시를 담당하게 한다.
- 10분을 넘길 것으로 예상되는 페이즈 중 **메인 루프가 경계를 직접 제어하는** 것만
  내부 스텝 항목으로 쪼갤 수 있다.

## 타이밍 기록 (전 phase 공통 — 항상, 병목 실측용)

파이프라인 벽시계가 어디서 새는지는 추측이 아니라 실측으로 판정한다. 위 Task
체크리스트 전이와 **같은 시점**(각 phase 진입)에 `date +%s` 를 기록해 두고
(노트/변수로 충분 — 파일 불요), Phase 5 wrap 에서 phase 별 elapsed 를 계산해
`~/.claude/logs/craft-timing.jsonl` 에 한 줄 append 한다:

```json
{"ts":"<ISO 시각>","skill":"forge|hunt|renew","project":"<repo basename>","mode":"linear|orchestrated","phases":{"p1":<sec>,"p2":<sec>,"p3":<sec>,"p35":<sec>,"p4":<sec>},"humanWait":<sec>,"total":<sec>,"tasks":<Phase3 태스크 수>}
```

- **스키마 필수 준수** — `phases.p1~p5` 초와 `humanWait` 는 note 로 대체하지 않고
  숫자로 기록한다. 이 로그가 ETA 스냅샷(아래)의 원료라, 스키마를 벗어난 행은
  ETA 계산에서 버려진다(과거 행의 note-only drift 가 실측 교훈).
- **ETA 스냅샷 (progress.md P4)** — 각 phase 진입 시 이 jsonl 에서 같은
  `(skill, mode)` 의 phase 별 median 을 조회해 Task 항목 텍스트에 `est ~Xm` 부기
  + 경계 배너 1줄(`elapsed Xm · remaining ~Ym`). 표본 `n<3` 이면 표시하지 않는다.
  규칙 상세는 `~/.claude/skills/craft-core/references/progress.md` §P4 를 읽어
  따른다(복제 금지).

- **사람 대기는 기계 시간과 분리** — Phase 1 말미의 플랜 확인 대기, Phase 4 의
  `[HUMAN]` walk 대기처럼 사용자 응답을 기다린 구간은 그 phase 의 elapsed 에서
  빼거나 불가능하면 `"humanWait":<sec>` 로 별도 기록한다. 사람 대기를 파이프라인
  병목으로 오인하는 것이 이 계측의 가장 흔한 오염이다.
- 실패해도 hard gate 아님 — 기록 불가면 note 만 남기고 wrap 을 막지 않는다.
- 이 로그가 튜닝(모델 tier · phase 게이트) 의 유일한 근거 데이터다 — 계측 없는
  "느린 것 같다" 튜닝 금지.

## Pipeline state 기록 (전 phase 공통 — 세션 밖 재개 가능성)

Task 체크리스트(세션 UI — 다른 세션에선 안 보임)와 별개로, **plan `.md` 끝에
`## Pipeline state` 섹션**을 두고 **phase 경계마다 갱신**한다 (`.planning/` 컨벤션
레포면 그쪽 STATE.md 우선):

```
## Pipeline state
- phase: 3 (in progress) · mode: linear
- tasks: 3/5 green (t4 red — <사유>)
- workflow runId: wf_xxx        ← Phase 3 Workflow 시작 시 기록
- updated: <ISO 시각>
```

세션이 중간에 죽어도(컨텍스트 고갈·크래시) 다른 세션이 plan 문서만 읽고 정확한
지점에서 이어받는다 — Workflow 는 `resumeFromRunId` 로 완료 태스크를 캐시
재사용하므로 **runId 기록이 곧 재개 비용 절감**이다. 갱신 비용은 phase 당 Edit
1회. wrap 에서 마지막으로 `phase: 5 (done)` 으로 닫는다.

## Phase 0 — Frame & isolate

- 작업유형과 한 줄 목표를 사용자에게 되짚어준다.
- **Worktree 격리 (기본 필수 — verify-or-STOP).** forge/renew/hunt 는 실질 빌드라
  편집 전에 **새 워크트리로 격리**한다 (branch-worktree-strategy §5: 메인 워크트리는
  trunk 유지, 새 브랜치는 worktree). 메인 트리/trunk 에서 직접 편집하지 않는다.
  1. `git worktree add -b <type>/<topic> <dir>` — type = feat(forge)/fix(hunt)/refactor·feat(renew);
     Linear 이슈ID 있으면 `<type>/<issue-id>-<topic>`. (`EnterWorktree` 는 deferred 도구 +
     이미 워크트리면 거부 → `git worktree add` 1순위.)
  2. **검증 — 직후 `git -C <dir> rev-parse --abbrev-ref HEAD` 가 기대 브랜치인지 확인.
     아니면 STOP**(구현 시작 금지). 이 검증을 빠뜨리면 빌드가 메인트리/trunk 에서 돌아
     격리가 붕괴한다 — "확실히 분리"의 핵심은 이 verify-or-STOP 이다.
  - 유일 예외(§5): 이미 적절한 feature 워크트리/브랜치에 있고 **동일 토픽 1–2 파일 이어
    커밋** — 그때만 현 트리 유지하고 첫 응답에 이유를 명시한다. 그 외엔 격리한다.
- **Linear binding (optional, graceful).** 이 작업에 연결된 Linear 이슈가 있으면
  — 사용자가 이슈 ID/URL 을 줬거나, 이어받은 PLAN `.md` 에 deep-plan 이 적어둔
  sub-issue 가 있으면 — `~/.claude/skills/craft-core/references/linear.md` 를 읽고
  그 활성 이슈를 **In Progress 로 자동 전이**한다. Linear MCP 미설치이거나 연결된
  이슈가 없으면 **묻지 말고** Linear 없이 평소대로 진행한다 — Linear 는 워크플로를
  증강할 뿐 게이트하지 않는다. 상태 전이 실패는 빌드를 막지 않는다(경고만).
- **세션 이름 설정 (백그라운드 잡일 때 — 워크트리 분기 직후 즉시, Phase 1 진입 전).**
  `$CLAUDE_JOB_DIR` 가 있으면 이 세션 이름을 `[<key>] <짧은 목표>` 로 rename 한다 —
  `<key>` = 위 Linear 바인딩이 잡혔으면 이슈ID(예 `[ADM-55] Direct Paint 직접 스타일링`),
  아니면 worktype(예 `[forge] CSV 내보내기`). **항상 대괄호 prefix 로 통일**한다.
  `session-rename.md` 의 검증된 atomic snippet 그대로(`state.json` `name` + `nameSource:"user"`
  — 하니스 auto-rename 차단). 이 단계는 Phase 1 로 넘어가기 전에 실행한다 — 뒤로 미루면
  세션이 인터뷰로 흘러 누락된다. 잡 컨텍스트 아니면 조용히 생략, 실패해도 hard gate 아님 — note 만.

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
  **목업의 충실도는 별도 SSOT 를 따른다** — 그리기 전에
  `~/.claude/skills/mockup/references/design-context.md` 를 읽고 design context
  추출(토큰·기존 화면 어휘·하드룰) → 4축 계약 → 토큰 부분집합 검증
  (`check-tokens.sh`) + 실화면 대조를 수행한다. 시안이 프로젝트의 디자인 실체를
  읽지 않고 즉흥 창작되는 것이 시안↔구현 괴리의 근원이다(여기 절차를 복제하지
  말 것 — 그 파일이 정본).
- **비 UI 플랜** (리팩터, 백엔드, DB 마이그레이션, API/계약 변경, 인프라):
  "결과 UI" 가 없으므로 **companion 을 기본 생략**한다 — `.md` 를 heading/표로
  다시 그린 렌더는 빌드 중 리뷰에서 비용 대비 가치가 없다(사용자는 플랜 확인
  게이트에서 `.md` 를 본다). 플랜 확인 요청에 "원하면 plan 렌더 HTML 생성 가능"
  한 줄만 남기고, 사용자가 원할 때만 Markdown 시각화(섹션 heading+블록,
  Steps→verify 표, 파일 경로 코드 스타일)로 만든다.

플랜이 혼합이면 (백엔드 작업이 있는 UI 변경), UI 는 목업으로 만들고 그 아래
비 UI 섹션은 플랜 렌더링으로 둔다. Phase 2 에서 codex 평결이 `.md` 에
들어오면, 둘이 동기 유지되도록 `.html` 을 갱신한다.

**Eval 체크리스트 패널 (companion 을 만들 때는 항상).** companion 종류가
무엇이든, `.html` 은 플랜의 **Acceptance(=eval) 항목** 을 체크리스트 패널로 렌더한다 —
각 항목을 그 `[AUTO]`/`[HUMAN]` 태그와 함께 보여, 리뷰어가 "구현이 끝나면 무엇으로
done 을 측정하는지" 를 시안·플랜과 **나란히** 본다. UI companion 이면 목업 옆/아래
패널로, 비UI 면 plan 렌더 안의 한 섹션으로. SSOT 는 `.md` 의 Acceptance 섹션이고 이
패널은 그 렌더 뷰다 (`.md` 가 바뀌면 패널도 갱신 — 위 동기 규칙과 같다). 이 패널이
빌드 스킬 Phase 4 가 항목별로 닫을 바로 그 eval 장부의 사람용 그림이다.

**Artifact publish (companion 을 만들었으면 항상 의무).** `.html` companion 을
쓴 직후 `Artifact` 도구로 publish 하고, 사용자에게는 로컬 경로 대신 **artifact
URL 을 리뷰 딜리버러블로 제시**한다. 로컬 `.html` 은 삭제하지 않는다 — Artifact
는 파일에서 publish 되고, 하니스 eval(D 시안충실도)·Phase 3/4 가 로컬 파일을
입력으로 읽는다. `.md` 변경으로 `.html` 을 갱신하면 **같은 파일 경로로 재-publish**
해 URL 을 유지한다. 규칙 SSOT: `~/.claude/rules-ondemand/html-mockup-artifact.md`.

Phase 2 전에 사용자에게 플랜 확인을 요청한다. 사용자가 보지 못한 플랜은
플랜이 아니다.

## Phase 2 — Adversarial plan review (codex)

**소형·저위험 플랜은 스킵 게이트 (위임 리뷰 = 직렬 고정비 ~10–20분).** codex
리뷰는 라운드당 hard cap 20분 × 수렴 게이트(최대 4라운드)의 *직렬* 블록이다 —
소형 플랜에선 이 고정비가 효용을 초과한다. Phase 1 플랜이 확정되면 먼저 판정한다:

- **필수 (스킵 불가)** — 다음 중 하나라도 해당하면 리뷰를 돌린다: 보안 surface
  있음 (auth / payment / 권한 경계 / 외부 입력 처리 / secret), 외부 호출자가 있는
  계약 변경, DB 마이그레이션 포함, 6+ 파일, 사용자의 stakes 신호 ("이거 중요한데",
  "제대로 하고 싶어" 류), orchestrated 모드.
- **스킵 제안 가능** — 위 어디에도 안 걸리고 플랜이 소형 (≤3 파일 · 단일 도메인 ·
  계약 무변경) 이면, `AskUserQuestion` 으로 **한 번** 묻는다: "소형·저위험 플랜이라
  codex 적대 리뷰(~10–20분)를 스킵할 수 있어요. 스킵할까요, 돌릴까요?" — 스킵을
  recommended 로. 사용자가 리뷰를 원하면 돌린다.
- **질문 불가 컨텍스트** (백그라운드 잡 · 자율 실행) 에서는 기본값 = **리뷰 실행**
  (안전 쪽 폴백 — 묻지 못하면 스킵하지 않는다).

스킵했으면 플랜에 `## Codex review — skipped: <소형 게이트 사유 + 사용자 승인>` 을
기록하고 Phase 3 으로 간다. 스킵은 이 게이트 + 사용자 승인 경유만 — "플랜이
괜찮아 보여서" 는 사유가 아니다.

리뷰를 돌리는 경우: `codex-review.md` 를 읽어라. 플랜을 codex 에게 적대적 리뷰어로서 넘긴다 —
그 일은 무엇이 잘못됐는지 찾는 것이다: 숨은 가정, 누락된 엣지 케이스, 보안
구멍, 더 단순한 경로, scope creep, **그리고 플랜이 ADR 가 필요한 아키텍처
결정을 하거나 standing ADR 과 충돌하는지**. 리뷰는 converge-gated 핑퐁이다:
codex 의 verdict JSON(high 이슈)에 플랜 수정 + 응답 원장으로 답하고, 같은
스레드(`--resume-last`)에서 해소 여부를 검증받는다. high 0건 수렴 또는 캡
4라운드까지 — 상세 계약(원장·분쟁 에스컬레이션·watchdog)은 `codex-review.md`
가 SSOT. 각 라운드의 평결을 플랜에 기록한다.

## Phase 3 — Dynamic workflow: task split + TDD (opus)

`dynamic-tdd.md` 를 읽어라. `Workflow` 도구로 승인된 플랜을 atomic
태스크로 쪼개고 각각을 엄격한 TDD 사이클 — **red → green →
refactor** — 로 구동한다. 모델 규칙은 `dynamic-tdd.md` 가 SSOT: 구현은 무핀
(세션 상속, 세션이 opus 미만일 때만 상향 핀), verify 는 `haiku` 최저가 핀.
(opt-in: `--codex-build` 플래그 발동 시 green 스텝을 codex 로 위임하는 cross-model
빌드 레인 — SSOT `codex-build.md`. 기본 off, 미발동이면 위 표준 그대로.) 태스크들을
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
build — 단 Phase 3 최종 형제 게이트 이후 diff 무변경이면(simplify 스킵 등)
수트/typecheck 재실행은 생략하고 그 green 을 인용하며, 아직 안 돈 게이트만
돌린다), diff 에 대한 **correctness 리뷰** (`/code-review` — 테스트가 못 잡은 버그만,
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

**닫은 항목은 plan `.md` 에 사실로 기록한다** — 항목을 닫을 때마다 해당 Acceptance
줄에 `✓` + 검증 증거 1줄(테스트명/명령 결과/walk 합의)을 덧붙인다
(acceptance-criteria-gate G3: 체크는 검증 후 사실 기록). 문서만 봐도 무엇이
어떻게 검증됐는지 남는다 — 세션 밖 감사·재개의 근거.

### 런타임 스모크 — 전 빌드 공통 (실행 가능하면 항상)

테스트 수트 green 은 *코드가 스스로에 대해* 맞다는 신호이고, 스모크는 *실제로 뜨고
응답한다*는 신호다 — 별개라 수트가 스모크를 대체하지 않는다. Acceptance 장부를 닫기
전에 빌드 산출물을 실제로 1회 구동한다:

- **서버/API** — dev 서버 구동 → 이번 변경의 핵심 엔드포인트를 실호출(`curl`)해
  상태코드+응답 확인. dev 환경 한정 — prod 호출 금지.
- **UI** — 실제 렌더를 띄워 화면 확인(스크린샷). 승인 시안이 있으면 아래 시안 충실도
  게이트와 같은 렌더를 재사용한다(이중 구동 불요); **시안 없는 UI 도 렌더 확인은 한다**.
- **CLI/스크립트** — 대표 커맨드 1회 실행 → 실제 출력 확인.
- **라이브러리 전용** — 별도 구동면이 없으면 수트 green 이 곧 스모크 — 생략하고 그
  사실을 기록.

스모크는 **읽기전용·비파괴** — 데이터를 쓰는 경로는 dev/테스트 데이터로만. 실행
불가면(env/credential/DB 부재) 억지로 돌리지 말고 **skip + 사유 기록** — 그 확인은
검증 체크리스트(output-contract §V)의 `[사용자 직접 확인 필요]` 항목으로 이관한다.
실행한 명령과 실제 출력이 §V `[직접 테스트 완료]` 의 증거가 된다.

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

- **결과 보드 (output-contract §R — 고정 행 셋).** 산문 요약 대신
  `~/.claude/skills/craft-core/references/output-contract.md` §R 의 보드를 emit 한다
  (복제 금지 — 행 셋·6규칙은 거기가 SSOT): 변경 파일별 목록 · 커밋 · 정체성 행
  (forge=신규 표면 / hunt=재현→회귀 잠금 / renew=보존 계약) · 테스트 · 검증 커맨드
  (실행 명령+실제 출력 수치) · 결정(트레이드오프·ADR 여부) · 평결(보안·intent) ·
  Acceptance · **타이밍(phase 별 elapsed, est 대비 — 위 타이밍 기록 실측, jsonl 에만
  쌓지 말고 매 런이 자기 병목을 보고한다)**. 보드는 wrap 시점 1회, 검증 체크리스트(§V)·
  다음 단계 블록(§N) 위에 선다.
- **검증 체크리스트 블록 (output-contract §V — 보드 아래·§N 위).** Acceptance 장부와
  Phase 4 런타임 스모크 실측으로 §V 블록(자동 검증 완료 / 직접 테스트 완료 / 사용자
  직접 확인 필요)을 emit 한다 — 형태·6규칙은 §V 가 SSOT(복제 금지). `[사용자 직접
  확인 필요]` 는 항목 없어도 "없음" 명시. 활성 Linear 이슈가 있으면 아래 보드
  코멘트에 이 블록도 함께 실린다(`linear.md` §3b).
- **다음 단계 블록 (output-contract §N — 고정 3행, 항상 emit).** 체크리스트 아래·L1 `result:`
  바로 위에 `▶ 다음 단계` 블록(잔여/필수/권장)을 emit 한다 — 행 규칙·소스 매핑은 §N 이
  SSOT(복제 금지). 이 파이프라인의 전형 소스: 잔여 = Acceptance 장부의 [HUMAN] 항목·
  미검증 잔여(없으면 "없음 — ✅ 모든 작업 완료"), 필수 = push 된 열린 PR → `/land`·
  마이그 apply(없으면 "없음"), 권장 = `/code-review` — 머지 전 diff 검증 · `/sweep` —
  쌓인 시점 문서 정리, 처럼 **이유 1구절 동반**(§N 규칙 4 포맷). 잔여·필수 "없음"은
  Acceptance 장부를 실제로 닫은 결과만 — 스캔 없이 쓰지 말 것.
- 영속적 결정/지식 기록 (`context-adr.md`): 작업이 **ADR 감** 결정을
  했다면, `docs/adr/NNN-slug.md` 를 쓰고 registry 를 갱신한다;
  **재사용 가능한 context** 를 확립했다면, `docs/concepts/` 페이지를 쓰거나 갱신한다.
  진짜로 가치 있을 때만 — 일상적 작업에 문서를 제조하지 말 것.
- 사용자가 요청하지 않으면 commit 이나 push 하지 말 것.
- **Linear 상태 전이 + 결과 코멘트 (활성 이슈가 있을 때만).** Phase 0 에서 In Progress
  로 옮긴 활성 이슈가 있으면, verify 가 green 이고 Acceptance 장부가 닫힌 지금
  `linear.md` 의 전이 맵대로 **In Review 로 자동 전이**하고, **같은 시점에 위 결과
  보드+검증 체크리스트를 그 이슈 코멘트로 남긴다**(`linear.md` §3b — 보드 재사용·
  마스킹·AI disclaimer, 재작성 금지. §V 체크박스가 이슈에서 사용자 확인 몫의 추적
  표면이 된다). Done 은 머지 시점 — `land` 가 처리. Linear 없거나 이슈 없으면 생략.
  전이·코멘트 실패는 wrap 을 막지 않는다.
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
  스캔 금지), **절대 자동 시작하지 않는다**. **후보는 위 다음 단계 블록의 필수·권장
  행에서 뽑는다** — 블록에 없는 후보 제안 금지, 제안한 것을 블록에서 빠뜨리는 것도
  금지(§N 규칙 5). 제안할 자연스러운 다음이 없으면 (작은 변경, push 안 함, 정리할 것
  없음) AskUserQuestion 은 생략한다 — 블록은 그래도 emit 한다("없음" 명시).

## Anti-patterns (이 파이프라인 전체가 이것들을 막으려 존재한다)

- spec 이 테스트 가능해지기 전에 코딩 (Phase 1 스킵).
- 사용자의 첫 표현을 완전한 spec 으로 취급.
- "플랜이 괜찮아 보여서" codex 리뷰 스킵 — 플랜이 괜찮아 보일 때가
  바로 적대자가 가장 유용한 때다. 스킵은 Phase 2 의 소형·저위험 게이트 +
  사용자 승인 경유만 (보안 surface · 계약 변경 · 마이그 포함이면 스킵 불가).
- Phase 3 구현 에이전트를 세션보다 낮은 tier 로 다운그레이드 핀하기, 또는
  verify/tester 결정론 스테이지를 haiku 위 tier 로 돌리기 (모델 규칙 SSOT:
  `dynamic-tdd.md`).
- 보안 pass 를 돌리지 않고 테스트 green 을 보고하기.
