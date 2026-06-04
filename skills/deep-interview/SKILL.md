---
name: deep-interview
description: 측정 가능한 ambiguity 점수로 게이트되어 요구사항이 명확해지는 정확한 시점에 — 그 이전이 아니라 — 멈추는, 한 번에 한 질문씩 진행하는 엄격한 Socratic 인터뷰를 실행해 모호한 아이디어를 검증 가능하고 빌드 준비가 된 spec 으로 끌어올린다. 사용자가 흐릿하거나 반쯤 형태만 잡힌 또는 야심 찬 아이디어를 들고 와서, 코드를 작성하기 전에 인터뷰받거나 질문받거나 "함께 생각을 정리"하고 싶어 할 때마다 사용한다 — "interview me about X", "help me think this through", "I have a rough idea for Y", "socratically question me", "pin down what I actually want", "deep dive on the requirements", "/deep-interview" 같은 표현. 여섯 가지 고전적 Socratic 질문 유형(clarification, probing assumptions, probing reasons/evidence, alternative viewpoints, implications/consequences, questioning the question)으로 대화를 이끌며, 먼저 컴포넌트 토폴로지를 고정한 뒤, spec 이 모르는 사람도 검증할 수 있을 만큼 명확해질 때까지 매 라운드 가장 약한 단일 차원을 공략한다. 아이디어가 정말로 모호하거나 클 때는 곧장 plan 으로 직행하기보다 이것을 우선한다. 작고 이미 명확한 작업, 알려진 버그 수정, 또는 빌드 파이프라인(forge/renew/hunt)이 이미 자체 요구사항 단계를 돌리고 있을 때는 사용하지 말 것.
---

# Deep Interview — 빌드 전 Socratic 모호성 해소

누군가 대부분 머릿속에만 존재하는 아이디어를 들고 온다. 위험은 그들이 설명을
못 한다는 게 아니라 — *어느 부분이 아직 모호한지를 그들 자신도 아직 모른다*는
것이고, 당신도 모른다는 것이다. 평범한 "뭘 원하세요?" 대화는 그걸 덮어버린다:
사용자는 침묵을 그럴듯하게 들리는 답으로 채우고, 당신은 고개를 끄덕이며, 모호함은
그대로 살아남아 빌드로 넘어가 10배의 비용을 치른다.

이 스킬은 두 가지를 동시에 해서 그것을 잡는다:

1. **모호성을 측정한다.** 매 라운드 spec 이 몇 개의 가중 차원에서 얼마나
   명확한지 점수를 매기고 단일 숫자로 보고한다. 인터뷰는 그 숫자에 *게이트*된다 —
   spec 이 증명 가능하게 명확해질 때 끝나는 것이지 사용자의 인내심이 바닥날 때
   끝나는 게 아니다.
2. **Socratic 방법으로 이끈다.** 각 질문은 여섯 가지 고전적 Socratic 유형 중
   하나이며, *가장 약한* 차원을 공략하도록 선택된다. 날카로운 질문 하나를 던지면
   그들이 답하고, 그 답이 점수를 올리며, 당신은 다시 조준한다. 사고는 사용자가
   하고, 당신은 압력과 구조를 공급한다.

산출물은 모르는 사람도 검증할 수 있는 결정화된 spec 과, 그것을 빌드하는 무언가로의
깔끔한 핸드오프다.

## 이것이 올바른 도구일 때

아이디어가 **정말로 모호하거나 크고** 잘못된 것을 빌드하는 비용이 실제일 때
손을 뻗으라. 작고 이미 명확한 작업(그냥 하라), 알려진 버그 수정(그건 다른 종류의
조사다), 또는 빌드 파이프라인이 이미 자체 요구사항 단계를 돌리고 있을 때는
건너뛰라 — 이중 인터뷰 하지 말 것.

## 여섯 가지 Socratic 질문 유형 — 당신의 유일한 도구

당신이 던지는 모든 질문은 이 중 하나다. 스스로에게 유형을 명명하는 것은 유도
질문이나 얄팍하게 가린 제안으로 표류하는 것을 막아준다. 매 라운드, *현재 가장 약한
차원*을 가장 잘 비집어 여는 유형을 고르라.

| # | 유형 | 무엇을 비집어 여는가 | 트리거 표현 |
|---|------|--------------------|--------------------|
| 1 | **Clarification** | 모호한 명사/동사; 실제 IO | "What exactly do you mean by X? Give me one concrete input and the output you'd want." |
| 2 | **Probing assumptions** | 사실로 받아들여진 진술되지 않은 전제 | "You're assuming X always holds — does it? What breaks if it doesn't?" |
| 3 | **Probing reasons & evidence** | 근거 없는 주장 | "What makes you confident that's true? Is there a case that already shows it?" |
| 4 | **Alternative viewpoints** | 터널 시야; 더 단순한 경로 | "Is there a simpler approach that avoids this entirely? Who would disagree with this choice?" |
| 5 | **Implications & consequences** | 하류/엣지 영향 | "If we do that, what's the worst input it now has to survive? What contract moves?" |
| 6 | **Question the question** | 잘못된 문제를 풀고 있음 | "What's the real goal behind this? If we solved that need another way, would this task still matter?" |

깊이 있는 가이드, 유형별 예시 모음, 선택 방법 — `references/socratic-playbook.md`. 라운드 1 전에 읽으라.

## 인터뷰, 페이즈별

상태는 대화 자체에 산다: 매 라운드 짧은 보고 테이블을 출력하며, 그 보고들이 *곧*
재개 가능한 기록이다. 숨겨진 상태 파일은 없다.

### Phase 0 — ambiguity 임계값 설정 (이것부터, 한 번)

인터뷰는 **ambiguity ≤ threshold** 일 때 끝난다. 기본 임계값은 **0.2**
(즉 약 80% 명확도에서 멈춤)다. 사용자는 실행마다 override 할 수 있다:

- `--quick` → threshold 0.35 (더 빠르고, 라운드 수 적고, 거친 spec)
- `--standard` / default → 0.20
- `--deep` → 0.10 (철저함; 모든 challenge mode 발동)

어떤 질문보다 먼저 임계값과 그 출처를 한 줄로 명시해, 사용자가 결승선을 알게
하라: *"Target: ambiguity ≤ 0.20 (standard). 이 선을 넘으면 멈추겠습니다."*

### Phase 1 — Orient (greenfield 대 brownfield)

이 아이디어가 기존 코드베이스를 건드리는지(**brownfield**) 아니면 완전히 새로운
것인지(**greenfield**) 판단한다. brownfield 라면 *묻기 전에* 그것이 건드리는
영역을 scope-read 하라 — 근거 있는 질문("`getPlan` 은 오늘 없는 id 에 `None` 을
반환합니다 — 유지할까요, raise 할까요?")은 결정을 얻고, 일반적인 질문은 일반적인
답을 얻는다. 프로젝트의 코드 인텔리전스(code-graph MCP / LSP)가 있으면 사용하고,
없으면 Read/Grep 을 영향 반경에 한정해 쓰라 — 절대 레포 전체가 아니다. 이 선택은
scoring 공식도 결정한다(`references/scoring.md` 참조).

### Round 0 — 토폴로지 고정 (깊이 들어가기 전 단일 게이트)

무언가를 파고들기 전에, 사용자가 **최상위 컴포넌트 목록** — 아이디어가 나뉘는
1~6개의 큰 조각 — 을 확정하게 하라. 각각을 **active**(지금 못 박을 것) 또는
**deferred**(인정하되 이번 인터뷰 범위 밖)로 표시하라. 이건 단일 확인 질문이고,
중요하다: 그것 없이는 실제 모호함이 컴포넌트 C 에 숨어 있는데 컴포넌트 A 를 열
라운드 동안 완벽히 다듬느라 시간을 쓸 수 있다. 토폴로지는 당신이 가로질러 회전하는
지도다.

### Phase 2 — 인터뷰 루프 (라운드당 한 질문)

ambiguity ≤ threshold 가 될 때까지 반복:

1. **Score** 각 차원을 0–1 로 (goal / constraints / criteria, + brownfield 의
   경우 context) 매기고 ambiguity 를 계산한다. 공식과 차원 정의:
   `references/scoring.md`.
2. **Target** 가장 약한 active 컴포넌트의 가장 약한 차원. 어느 것인지와 *왜
   그것이 현재 병목인지*를 말하라 — 사용자가 그 논리를 볼 수 있어야 한다.
3. **Ask one question** — 절대 묶지 말 것. 그 차원을 가장 잘 공략하는 Socratic
   유형을 고르라(예: 약한 goal → 유형 1/6; 약한 constraints → 유형 2/5; 약한
   criteria → 유형 3/5).
4. **Report** 간결한 라운드 테이블: 차원 점수, ambiguity %, 어느 컴포넌트, 다음에
   무엇을 조준하는지.

라운드당 한 질문은 타협 불가다: 묶으면 사용자가 지금 가장 중요한 한 가지를 깊이
생각하는 대신 전 영역에 얕게 답하게 된다.

### Phase 3 — Challenge modes (깊이에서의 관점 전환)

ambiguity 가 완고하면, 문제는 대개 누락된 디테일이 아니라 잘못된 가정이다. 이것들을
라운드 임계값에서 각각 한 번씩 주입하라 — Socratic 유형 *위에* 얹힌다:

- **Round 4+ — Contrarian:** 핵심 가정을 정면 공격(Socratic 유형 2/4).
- **Round 6+ — Simplifier:** 그 복잡성이 정말 필요한지 탐색(유형 4/5).
- **Round 8+ — Ontologist:** 여전히 흐릿하면, 핵심 엔티티와 그 관계를 중심으로
  전체를 재구성(유형 1/6).

세부 사항과 예시 오프너: `references/socratic-playbook.md` (Challenge modes).

### 멈추기 — 게이트, 그리고 비상 탈출구

- **Primary:** ambiguity ≤ threshold → Phase 4 로 진행.
- **Soft cap (round 10):** 계속할지 지금 결정화할지 제안하며, 아직 무엇이
  모호한지와 멈출 때의 리스크를 명명.
- **Hard cap (round 20):** 현재 명확도로 결정화; spec 에 잔여 모호성을 명시적으로
  표시.
- **Early exit (round 3+):** 사용자가 "stop / build it / good enough" 이라고
  말하면, 따르라 — 현재 ambiguity 와 미해결 사항을 명시한 뒤 결정화.

### Phase 4 — 요구사항 spec 결정화

`references/spec-template.md` 를 사용해 **시스템 요구사항 문서**를 작성하라. 각
요구사항은 안정적 ID(`REQ-F-NNN` functional / `REQ-N-NNN` non-functional),
MoSCoW 우선순위, 자체 acceptance criterion, 그리고 그것을 못 박은 인터뷰 라운드로
역추적하는 Origin 칼럼을 갖는다. 템플릿은 또한 goal/scope, 고정된 토폴로지,
constraints, 해결된 assumptions, brownfield context, 그리고 clarity trail 을
담는다.

명백한 거처가 있으면 프로젝트가 spec 을 두는 곳에 저장하라(그 레이아웃을 쓰는
레포에서는 `docs/specs/` — 레포가 directory-per-spec 컨벤션을 쓴다면 따르라).
없으면 경로를 제안하고 쓰기 전에 사용자가 확정하게 하라. 이 파일은 시스템의
요구사항 기록으로 살아남도록 의도된 것이므로, 번호 매긴 ID 는 한 번 할당되면 안정적
으로 유지돼야 한다.

spec 을 쓴 직후 `references/result-format.md` 의 고정 블록으로 산출물을 보고한다 —
`result:` 한 줄(결정화 요약 + ambiguity %) + `SPEC` 행의 상대경로와 `open` 명령
(deep-plan 과 동일한 공통 포맷). 이 블록을 먼저 내고 **그다음에** Phase 5 의 다음
스킬 라우팅 추천을 잇는다 — result 블록이 라우팅을 대체하지 않는다.

### Phase 5 — 올바른 다음 스킬로 라우팅

이 스킬은 빌드하지 **않는다** — 요구사항 spec 을 만들어 그것을 빌드하는
파이프라인으로 라우팅한다. 인터뷰는 이미 작업의 *성격*을 드러냈고(Phase 1 의
greenfield/brownfield 판단 + goal), 그 성격은 특정 작업유형 스킬로 매핑된다.
분류한 뒤 `AskUserQuestion` 으로 추천하라 — 사용자가 선택하게 하고, 절대 자동
시작하지 말 것.

| 인터뷰가 드러낸 것… | 라우팅 | spec 이 주는 것 | 적합도 |
|---------------------|----------|------------------------|-----|
| 존재하지 않는 **새** 능력 (greenfield) | **`/forge`** | spec 이 *곧* 못 박힌 요구사항 | best |
| 기존 기능 **변경** — 동작이 옮겨가고 호출자가 깨질 수 있음 (brownfield) | **`/renew`** | 무엇이 바뀌어야 하고 무엇이 보존돼야 하는지 | strong |
| 고칠 **고장난** 무언가 | **`/hunt`** | 약한 매치 — hunt 는 요구사항이 아니라 재현 + 근본 원인을 원함; 보통 `/hunt` 로 직행 | weak |
| 빌드 전에 **구현 plan/설계 문서**(또는 UI 시안)를 먼저 원함 — 지금은 빌드 보류 | **`/deep-plan`** | spec 을 입력으로 받아 실행 가능한 PLAN 문서 + (UI 면) HTML 시안을 산출하고 멈춤 | strong |
| 코드가 아니거나, 이 세션을 떠남 | spec 파일 반환 | 사용자가 다른 곳으로 들고 감 | — |

**스킬뿐 아니라 강도도 추천하라.** craft 파이프라인은 두 모드 중 하나로 실행된다 —
*linear*(기본, 단일 세션) 또는 *orchestrated*(멀티에이전트 디자인 council:
적대적 디자인 공격 + 빌드 후 intent 검증, 더 느리고 더 비쌈). 엔진은 보통 그 시작에서
차가운 "stakes signal" 로 모드를 추측한다 — 하지만 당신은 방금 정확히 그것을
측정하느라 인터뷰 전체를 썼으니, 엔진이 추측하게 두지 말고 당신의 판단을 앞으로
넘기라. 인터뷰가 실제 디자인 리스크를 드러냈을 때만 **council** 을 추천하고,
그렇지 않으면 기본값 **linear**(council 은 opt-in 이고 비싸다 — 명확하고 작은
작업에 밀어붙이지 말 것). 강한 council 신호:

- **멈출 때 잔여 ambiguity** — 요구사항이 여전히 모호한 채로 cap 에 도달.
- **넓은 토폴로지** — 4~6개의 상호의존적 active 컴포넌트, 큰 디자인 표면.
- **힘든 수렴** — 많은 라운드, challenge mode 발동(특히 round 8+ 의 ontologist,
  즉 프레이밍 자체가 틀렸다는 뜻), 또는 요동치는 엔티티.
- **횡단 non-functional** — 컴포넌트를 가로지르며 한 디자인 선택이 파급되는
  보안 / 마이그레이션 / 호환성.

이것들이 없으면(명확하고, 빨리 수렴, 1~2 컴포넌트), linear 라고 말하고 넘어가라.
있으면, 핸드오프에서 신호를 명명하라, 예: *"6개 컴포넌트, REQ-N-002 가 여전히
무른 채로 18% 에서 멈춤 — council 모드로 `/forge` 를 돌릴 가치가 있음."* 결정은
여전히 사용자가 한다; 당신은 엔진에 정보에 근거한 판단을 넘기는 것이다.

**이중 인터뷰를 피하라.** forge / renew / hunt 각각은 *자체*
Socratic 요구사항 단계를 돌린다(공유 craft-core Phase 1, 그리고 orchestrated
모드의 융합된 council 루프). `/deep-plan` 도 모호하면 자체 적응형 인터뷰로
보강한다. 순진하게 핸드오프하면 사용자는 두 번 인터뷰받는다.
그러니 핸드오프는 다음 스킬에게 이 spec 을 **이미 완료된 Phase 1 산출물**로
취급하고 곧장 plan review 로 건너뛰라고 알려야 한다. 추천을 그렇게 프레이밍하라,
예:

> "요구사항은 `docs/specs/<slug>.md` 에 못 박혔습니다(ambiguity <N>%). 그 spec 을
> Phase-1 결과로 써서 `/forge` 를 돌리세요 — 다시 인터뷰하지 말고; 다음으로
> 적대적 plan review 로 가세요."

매칭되는 스킬이 이 프로젝트에 설치돼 있지 않으면, 번호 매긴 요구사항으로부터 만든
평범한 구현 plan 으로 폴백하거나, 그냥 spec 파일을 넘기라.

## Anti-patterns

- **질문 묶기** — 메커니즘 전체를 무력화; 라운드당 하나.
- **유도 질문** — "Postgres 를 써야 한다고 생각하지 않나요?"는 물음표를 단
  제안이다. 여섯 유형 안에 머물라.
- **Scoring theater** — 믿지도 않는 정밀해 보이는 숫자를 지어내기. 점수는 정직하게
  내린 판단이고, 그 일은 방향과 결승선을 보여주는 것이지 엄밀함을 가장하는 게
  아니다.
- **명확함을 넘어선 인터뷰** — ambiguity ≤ threshold 가 되면 멈추라. 더 묻는 것은
  성실함이 아니라 마찰이다.
- **Round 0 건너뛰기** — 토폴로지를 고정하기 전에 깊이 파는 것이 잘못된 컴포넌트를
  완벽히 다듬는 길이다.
- **코드가 이미 답하는 것을 묻기**(brownfield) — 먼저 읽고, 코드가 대신 못 하는
  결정을 물으라.
