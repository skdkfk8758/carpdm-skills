# Requirements Spec Template — 인터뷰가 결정화되는 결과물

ambiguity 가 임계값을 넘으면(또는 cap 이 멈춤을 강제하면), 이 구조로 spec 을
작성하라. 그것은 **시스템 요구사항 문서**다: 모르는 사람이 — 또는 빌드 파이프라인이
— 그것을 차갑게 집어 들어, 번호 매긴 요구사항에 맞춰 구현하고, 인터뷰를 본 적 없이
각각을 검증한다.

모든 요구사항은 **안정적 ID**(`REQ-F-NNN` functional, `REQ-N-NNN`
non-functional)를 받는다. ID 는 추적성의 단위다: clarity trail 이 그것으로
역매핑되고, acceptance 가 그것에 매달리며, 빌더가 하나씩 체크할 수 있다. ID 가 한
번 할당되면, 절대 다시 번호 매기지 말 것 — 대신 새것을 덧붙이라, 그래야 코드,
커밋, 또는 하류 spec 의 참조가 절대 낡지 않는다.

모든 섹션을 채우라; 하나가 정말로 비어 있으면, 그것을 지우는 대신 `None` 이라고
쓰라, 그래야 독자가 그것이 잊힌 게 아니라 고려됐음을 안다.

## Path & naming

명백한 거처가 있으면 프로젝트가 spec 을 두는 곳에 저장하라 — 그 레이아웃을 쓰는
레포에서는 `docs/specs/`. 레포가 directory-per-spec 컨벤션(`docs/specs/<slug>/spec.md`)을
쓴다면, 따르라. 없으면 경로를 제안하고 쓰기 전에 사용자가 확정하게 하라. goal 의
slug 에서 이름 지으라, 예: `docs/specs/<slug>.md` 또는 `docs/specs/<slug>/spec.md`.

## Template

```markdown
# Requirements: <one-line title>

> Crystallized from a deep-interview on <date>. Final ambiguity: <N>% (target ≤ <T>%).
> Type: <greenfield | brownfield>. Rounds: <count>. Status: <draft | approved>.

## 1. Goal & scope

<One or two sentences: what the system is for and why. State the underlying need,
not just the feature — a stranger reads this and knows what success looks like.>

**In scope:** <the components / capabilities this spec covers>
**Out of scope:** <what this explicitly will NOT do, confirmed with the user, so
scope creep can't reopen it. `None` if nothing was excluded.>

## 2. Topology

The pieces this breaks into (locked in Round 0):

| Component | Status | One-line role |
|-----------|--------|---------------|
| <name>    | active | <what it does> |
| <name>    | deferred | <why out of scope for now> |

## 3. Functional requirements

What the system must *do*. One row per requirement; keep each atomic (one
testable behavior) so it can pass or fail on its own.

| ID | Requirement (the system SHALL…) | Priority | Acceptance criteria | Origin |
|----|----------------------------------|----------|---------------------|--------|
| REQ-F-001 | <single testable behavior, with exact values/shapes — not "handle errors"> | Must | <how a tester who never saw the interview verifies it: exact input → exact output/exception> | R<n> |
| REQ-F-002 | … | Should | … | R<n> |

Priority is MoSCoW: **Must** / **Should** / **Could** / **Won't (this round)**.
Origin is the interview round that pinned it — that's the traceability link.

## 4. Non-functional requirements

How well it must do it — only the dimensions this system plausibly touches. Skip
the ones that don't apply rather than padding with boilerplate.

| ID | Category | Requirement | Acceptance criteria | Origin |
|----|----------|-------------|---------------------|--------|
| REQ-N-001 | Performance | <e.g. p95 latency < 200ms at 100 rps> | <how it's measured> | R<n> |
| REQ-N-002 | Security | <e.g. input X is validated against Y before persistence> | <how it's verified> | R<n> |
| REQ-N-003 | Compatibility | <e.g. existing callers of Z keep current return shape> | <how it's verified> | R<n> |

Common categories: Performance/scale, Security, Compatibility/migration,
Reliability/error behavior, Observability, Accessibility.

## 5. Constraints & assumptions

- **Constraints:** <hard limits the design must respect — tech stack, deps,
  budget, deadlines, data residency.>
- **Assumptions resolved:** <each premise surfaced in the interview and how it
  was settled — "input is always valid UTF-8: confirmed" / "single-user: assumed,
  not guaranteed — see REQ-N-00x risk".>
- **Residual ambiguity:** <anything still vague at stop time, the requirement(s)
  it affects, and the risk. `None` if fully clear.>

## 6. Context *(brownfield only)*

<Integration points, behavior that must be preserved, blast radius — grounded in
the actual code read during the interview, with file/symbol references. Tie each
to the REQ it constrains.>

## 7. Traceability — clarity trail

| Round | Ambiguity | Targeted dimension | Requirements pinned |
|-------|-----------|--------------------|---------------------|
| 0 | — | topology lock | <components> |
| 1 | <N>% | <dim> | REQ-F-001 |
| … | | | |

## 8. Handoff

Recommended next step: <build directly in the main session (plan mode → implement
→ `/code-review`) | `/deep-plan` (plan doc / UI mockup first, build deferred)
| `goal-prompt` (turn this spec into an autonomous-agent prompt) | `grilling`
(pressure-test Residual ambiguity only) | `/to-tickets` (tracer-bullet tickets)
| carry elsewhere>, chosen from the nature of the work above.

**Treat this spec as the completed requirements step.** Whatever runs next must
not re-interview — feed these numbered requirements in as the pinned input and
go straight to implementation / planning.
```

## 잘 채우기

- **방향성이 아니라 정밀하게 못 박으라.** "REQ-F-003: raises `ValueError` on a
  negative amount" 가 "validates input" 을 이긴다. "REQ-N-001: caps at 1000 items"
  가 "has a limit" 를 이긴다. 정밀함이 *곧* 계약이다 — 반쯤 못 박힌 요구사항은
  빌더가 추측으로 채우는 틈을 남긴다.
- **요구사항당 한 동작.** 한 행이 두 검증 가능한 동작을 잇는 "and" 가 필요하면, 두
  ID 로 쪼개라. 원자적 요구사항은 깔끔하게 통과/실패하고; 복합적인 것은 절반의
  실패를 숨긴다.
- **Acceptance 는 요구사항당 필수.** acceptance criterion 없는 요구사항은
  요구사항이 아니라 소망이다 — 빌더가 다 됐음을 증명할 수 없다.
- **잔여 ambiguity 를 정직하게 앞으로 들고 가라.** 무언가 여전히 모호한 채 cap 에서
  멈췄다면, 그렇게 말하고 영향받는 REQ 를 명명하라. 자기 틈을 숨기는 spec 은
  그것을 프로덕션 깜짝쇼로 바꾸고; 명명된 틈은 처리된다.
- **추적성은 제값을 한다.** Origin 칼럼 + clarity trail 은 리뷰어가 *어떤* 질문이
  *어떤* 요구사항을 못 박았는지 보고, 실제 답 없이 통과된 REQ 를 잡아내게 한다.
