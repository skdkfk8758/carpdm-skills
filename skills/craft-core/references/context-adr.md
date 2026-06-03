# Context & ADR — grounding 을 위해 읽고, 영속적 결정을 위해 쓴다

두 가지 일, 둘 다 forge/renew/reshape/hunt 가 공유한다:

- **Read (Phase 1 grounding)** — 사용자에게 무엇이든 묻기 전에, 프로젝트의
  기존 결정, 도메인 context, 문서화된 절차 (guide/reference) 를 읽어
  질문이 정해진 것을 재론하지 않고 플랜이 standing 결정이나 문서화된
  how-to 와 모순되지 않게 한다.
- **Write (Phase 5 wrap)** — 작업이 기억할 가치 있는 결정을 했거나 재사용
  가능한 지식을 확립했을 때, *다음* 세션이 추론을 다시 하지 않도록
  기록한다.

이 스킬들은 글로벌하므로 (프로젝트 간 사용), 여기 모든 것은
하드코드가 아니라 **convention-detecting** 이다. 프로젝트가 쓰는 것을 감지하고;
없을 때 우아하게 폴백한다.

## 먼저 컨벤션을 감지하라

- ADR: `docs/adr/` 디렉토리 (그리고 보통 `docs/adr/INDEX.md` 같은 registry)
  가 있나? 있으면, 그 번호 매기기, 파일명 패턴
  (`NNN-slug.md`), frontmatter, status 필드를 정확히 따른다 — 기존 파일에
  맞추고, 새 형태를 발명하지 말 것.
- Concept/context: `docs/concepts/` (또는 프로젝트의 등가 지식
  트리) 가 있나? 그 페이지 포맷을 메모한다.
- Guide & reference: `docs/guides/` (how-to / runbook / tutorial) 나
  `docs/reference/` (API surface, 외부 자료 포인터) 가 있나? 이것들은 작업이
  따라야 할 *문서화된 절차와 계약* 을 담는다 — ADR/concept 뿐 아니라 이것들도
  확인하라.
- 아무것도 없으면: 일회성을 위해 docs 트리를 제조하지 말 것. 진짜 ADR 감
  결정이 실제로 생길 때만 `docs/adr/` 시작을 제안하라;
  아니면 스킵하고 wrap-up 에서 결정을 요약만 하라.

## grounding 을 위해 읽기 (Phase 1)

Socratic 클러스터 전에:

- ADR registry 를 훑는다 (`ls docs/adr/`, 이 작업 영역을 건드리는 것을 읽는다).
  플랜은 **standing ADR 을 존중**해야 한다; 작업이 하나와 모순된다면, 소리 내어
  말하고 사용자와 해결하라 — 기록된 결정을 조용히 override 하지 말 것.
- 관련 `docs/concepts/` 페이지를 읽어 도메인 어휘와 제약을 파악하고,
  질문이 프로젝트 용어를 쓰고 이미 적힌 것을 묻지 않게 한다.
- `docs/guides/` 와 `docs/reference/` 에서 이 영역을 다루는 기존 how-to, runbook,
  문서화된 계약을 확인한다. guide 가 이미 절차를 규정하면, 플랜은 그걸
  따라야 한다 (또는 왜 벗어나는지 명시적으로 밝혀라) —
  문서가 이미 정한 플로우를 재발명하지 말 것.
- 이것을 코드 읽기와 짝지어라 (`socratic.md` → "묻기 전에 읽어라"): 코드는
  *무엇인지*, ADR/concept 는 *왜 그런지*, guide/reference 는
  *어떻게 하기로 돼 있는지* 를 말해준다.

## ADR 작성 (Phase 5) — ADR 감일 때만

ADR 은 **아키텍처적이고 되돌리기 어려운** 결정을 기록한다 — 계약,
경계, 기술/패턴 선택, 미래 코드가 따라야 할 정책. 대부분의 작업은 하나를
요하지 **않는다**; 일상적 작업을 위한 ADR 의 벽은 registry 를 오염시킨다.
다음일 때 쓴다:

- 작업이 진짜 아키텍처 대안 사이에서 골랐을 때 (그리고 나중에 누군가
  "왜 이렇게?" 라고 물을 때), 또는
- Phase 2 codex 가 플랜이 아키텍처 결정을 한다고 플래그했을 때, 또는
- 사용자가 명시적으로 기록할 결정으로 framing 했을 때.

어떻게 (감지된 컨벤션을 따른다; 아래 형태는 흔한 것):

1. 번호를 매긴다: next = `ls docs/adr/[0-9]*.md | tail -1` + 1.
2. `docs/adr/NNN-slug.md` 를 프로젝트의 frontmatter (title, type, created,
   related, tags) 와 status (기본 **Proposed**) 와 함께. 본문: Context → Decision →
   Consequences (또는 기존 ADR 이 쓰는 무엇이든 — 맞춰라).
3. **registry 관리**: 같은 commit 에서 `docs/adr/INDEX.md` 에 행을 추가한다 —
   index 에 없는 ADR 은 보이지 않는다. 이 결정이 더 오래된 ADR 을 supersede 하거나
   amend 하면, 양방향으로 링크하고 옛것의 status 를 갱신한다.

## concept 작성 (Phase 5) — 재사용 가능한 지식을 위해

작업이 **2+ 미래 페이지가 참조할** 도메인 지식이나 context (데이터 모델,
invariant, glossary 용어, layer 경계) 를 확립했을 때,
`docs/concepts/<slug>.md` 로 프로젝트 페이지 포맷에 기록한다. 거의 중복을
만드는 것보다 **기존 concept 갱신**을 선호하라. 일회성,
단일 사용 context 는 플랜에 inline 으로 남긴다 — 승격하지 말 것.

## 태스크별 ADR 감 (호출 스킬이 이걸 날카롭게 한다)

- **forge** — 새 아키텍처 패턴, 의존성, 외부 계약 →
  ADR. 기존 레일 위의 평범한 기능 → ADR 없음.
- **renew** — 진짜 결정인 계약/behavior 변경 (auth 모델
  교체, API envelope 변경, 마이그레이션 전략) → ADR.
- **reshape** — 보통 **ADR 없음** (behavior 불변). 예외: 리팩터가
  미래 코드가 따라야 할 *구조적 패턴을 채택* (예: "modular monolith", "writer SSOT") →
  ADR.
- **hunt** — 보통 **ADR 없음**. 예외: 수정이 미래 코드가 존중해야 할
  standing invariant 나 정책 ("all sum-zero inputs normalize to uniform") 을
  확립 → ADR.

## Anti-patterns

- 일상적 작업에 ADR 작성 → registry 노이즈; 독자가 신뢰를 멈춘다.
- INDEX.md 행 없는 새 ADR 파일 → 결정이 찾을 수 없다.
- 기존 ADR 나 concept 가 이미 답하는 것을 사용자에게 묻기 → 보지
  않은 것처럼 보인다.
- standing ADR 에 반해 조용히 계획하기 → 대신 충돌을 surface 하라.
- 기존 concept 페이지를 갱신하는 대신 중복하기.
