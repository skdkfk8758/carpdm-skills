---
name: hunt
description: >-
  재현 우선, 회귀 잠금 파이프라인으로 BUG 를 고친다 — 정확한 재현과 근본 원인을 고정하는 소크라테스식 인터뷰 → dynamic-workflow TDD(실패하는 회귀 테스트 먼저) → codex diff 리뷰 포함 보안 검증. 사용자가 무언가 BROKEN, 실패, 에러, 크래시, throw, 잘못된 결과 반환, 멈춤, 또는 예기치 않게 동작한다고 보고하며 고치고 싶어 할 때마다 사용한다 — "X is broken", "Y throws on Z", "why does this return null", "the page crashes when…", "this used to work and now…", "getting a 500 from…", "이거 왜 안 돼", "버그 고쳐줘", "에러 나", "500 떠", "화면 깨졌어", "갑자기 안 되네", "예전엔 됐는데 지금 안 돼" 같은 표현. 새 기능을 만들거나(use forge), 동작하는 기능을 의도적으로 변경하는(use renew) 데에는 사용하지 말 것.
---

# Hunt — 버그 수정

버그 수정의 두 가지 실패 양상은: 원인 대신 증상을 고치는 것, 그리고 나중에 조용히
되살아나는 방식으로 고치는 것이다. 파이프라인은 둘 다 막는다 — 재현할 수 없는 것은
고칠 수 없으므로 원인은 먼저 증거로 고정되어야 하고, 수정은 이전엔 실패하고 이후엔
통과하는 회귀 테스트로 잠긴다.

`~/.claude/skills/craft-core/references/pipeline.md` 의 공유 엔진을 실행하라
(먼저 읽을 것). 그 안에서 다음 hunt 고유 강조점을 적용한다:

## 실행 모드 (linear 고정)

**linear 고정** — 버그 수정에 council 은 대부분 과투자다. hard bug 의 정답은
council 이 아니라 아래 `diagnose` 선행·병렬 가설 fan-out 이다(둘 다 이 스킬에
이미 있다). `[council]`/`--council` 명시 요청 시에만 orchestrated
(`pipeline.md` Execution mode).

## Phase 1 — Socratic focus (see craft-core/references/socratic.md)

- **Exact reproduction** — 그것을 유발하는 정확한 단계, 입력, 환경. 재현할 수 없다면
  그것이 사용자와 함께 가장 먼저 해결할 일이다; 볼 수 없는 버그의 수정을 추측하지 말 것.
- **Expected vs actual** — 무엇이 일어나야 하는지, 무엇이 일어나는지, 실제
  에러 메시지 / 스택 / 잘못된 출력을 정확히 인용 (의역하지 말 것).
- **Scope & onset** — 얼마나 광범위한지, 언제부터인지, 그 무렵 무엇이 바뀌었는지.
- **Root-cause hypothesis** — 코드 안의 실제 원인까지 추적하라 (호출자/영향은 graph/LSP
  먼저, 아니면 Read/Grep) 그리고 에러 자체의 어휘로; 이 영역을 이미 문서화한
  ADR/concept 가 있는지 확인 (`context-adr.md`). 신뢰도를 진술하라; 추측이면 그렇게
  말하고 수정을 계획하기 전에 검증하라. 추적하지 않은 증상을 고치는 것이 버그 수정이
  실패하는 가장 흔한 경로다.
- **ADR-worthy?** 보통 **아니오**. 예외: 수정이 향후 코드가 지켜야 할 항구적
  invariant/정책을 수립하는 경우 → Phase 5 에서 ADR 기록.
- **Blast radius & edge inputs (type 5)** — 근본 원인이 그 밖에 무엇을 건드리는지,
  그리고 수정이 깨뜨려서는 안 되는 edge input (새 회귀 없음). 마무리 전에 완전성
  sweep 을 실행해, 수정이 하나의 버그를 다른 버그와 맞바꾸지 않도록 하라.

### 막힌 재현·원인은 diagnose 로 선행 (optional — hard bug 한정)

재현이 불안정하거나(간헐적·환경 의존·race) 근본 원인이 위 1-패스 추적으로 안
잡히는 hard bug 면, 수정을 계획하기 전에 `diagnose` 스킬의 체계적 루프
(reproduce → minimise → hypothesise → instrument)를 선행해 원인을 증거로 고정하라.
hunt 의 Phase 1 추적은 원인이 한 번에 보이는 흔한 경우를 위한 것이고, diagnose 는
그게 막힐 때만 — 대부분 버그는 여기까지 안 간다(둘을 겹쳐 돌리지 말 것). 원인이
증거로 고정되면 hunt 로 돌아와 Phase 3 회귀 테스트부터 이어간다.

### Parallel hypothesis diagnosis (optional — multi-candidate bugs only)

원인에 **두 개 이상의 그럴듯한 후보**가 있고 각각을 추적하는 비용이 비쌀 때
(예: migration, ORM 매핑, env var, 또는 race 일 수 있는 500), 첫 추측에 닻을 내리지
말 것. `Workflow` 도구로 가설당 에이전트 하나씩 fan out 하여 각자 자기 후보를
**독립적으로** 추적하게 하라 — 이들은 서로 대화하지 않는다. 교차 대화가 이 방식이
깨뜨리려는 앵커링을 다시 들여오기 때문이다. 각자는 증거를 반환한다: 정확한 코드
경로, 그것이 설명하는 재현, 그리고 설명하지 못하는 것. 그다음 당신은 증거를 저울질해
재현이 실제로 뒷받침하는 원인을 고른다 — 수정을 계획하기 전에 확인하라.

버그가 하나의 명백한 원인으로 추적될 때는 이것을 건너뛰어라 — 대부분이 그렇고,
신뢰도 높은 단일 추적에는 패널이 필요 없다. 이것은 독립 증거를 위한 hub-and-spoke
fan-out 이지 peer team 이 아니다; 독립성이 가치의 전부다.

## Phase 3 — TDD entry point (see craft-core/references/dynamic-tdd.md)

Task 1 은 **버그를 재현하는 실패하는 회귀 테스트**다 — 현재 코드에 대해 정확히
보고된 이유로 실패한다. 그다음에야 그 테스트가 green 이 될 때까지 수정을
구현하고, 다른 어떤 테스트도 회귀하지 않았음을 확인하라. 회귀 테스트가 스위트에
남아 있는 것이 버그의 재발을 막는다.

수정은 최소로, 근본 원인을 겨냥하라 — 버그 수정은 주변 코드를 리팩터링할 면허가
아니다.

## Phase 3.5 — Simplify review pass (see craft-core/references/simplify-pass.md)

수정이 green 이 되면, Phase 4 이전에 *방금 변경한 diff* 가 정리(simplify)가 필요한지
검토하고, 필요하면 `/simplify` 스킬로 동작 보존 정리(재사용/단순화/효율)를 **한 번
제안한다** (기본 off). simplify 는 방금 바뀐 코드만 보므로 surgical 한 수정의 범위를
넘지 않는다 — 주변 미변경 코드로 번지지 않는다. diff 가 사소하거나 사용자가 거절하면
건너뛴다.

Phase 0, 4, 5 는 공유 파이프라인 그대로 실행된다. **Phase 2 는 hunt 에서 무조건
스킵이다** (`pipeline.md` Phase 2 판정 1 — 재현 테스트가 이미 oracle, 설계 결함은
Phase 4 의 codex diff 리뷰가 잡는다).

## Anti-patterns (hunt 고유 — 공유분은 pipeline.md)

- **추적 안 된 증상 수정** — 근본 원인을 코드까지 증거로 고정하기 전에 수정에 들어가면
  증상만 옮긴다. 원인이 1-패스로 안 잡히면 `diagnose` 선행.
- **회귀 테스트 없이 "고쳤다"** — Task 1 은 버그를 재현하는 실패하는 회귀 테스트다. 그게
  스위트에 남아야 재발을 막는다 — 스위트에 안 남기면 조용히 되살아난다.
