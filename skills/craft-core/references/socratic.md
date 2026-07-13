# Socratic Questioning — 모호한 요청을 테스트 가능한 spec 으로

목표: spec 을 강요하는 게 아니라 사용자의 머릿속에서 끄집어내는 것. 당신이 묻고, 그들이
답하고, 그 답이 플랜이 된다. 낯선 사람이 검증할 수 있는 acceptance
기준을 쓸 수 있을 때 멈춘다 — 그 전도, 한참 후도 아니다.

## 어떻게 돌리는가

- **작고 집중된 클러스터** (2–4 질문) 로 묻는다, 20개 질문 벽이 아니라.
  각 클러스터는 현재 가장 큰 단일 unknown 을 겨냥해야 한다.
- 선택지가 몇 개의 구체적 옵션 사이라면, 사용자가 산문을 타이핑하는 대신
  고르도록 `AskUserQuestion` 도구를 쓴다.
- 가정을 소리 내어 탐색한다: 사용자가 무언가를 사실로 진술하면, 되비춘다 —
  "이건 X 가 성립한다고 가정합니다; 안 그러면 설계가 Y 로 바뀝니다."
- 메모리가 아니라 코드에 대해 검증한다 — 먼저 읽어라 (아래 "묻기 전에 읽어라"
  참조). 질문이 코드나 기존 문서로 답할 수 있는 것이라면 (이 엔드포인트가 존재하나?
  현재 반환 타입은? ADR 가 이미 이걸 정했나?),
  사용자에게 묻기 전에 직접 답한다.
- 멈춤 조건: 모든 Phase-1 플랜 섹션을 채울 수 있다. 그 지점을 넘는 질문은
  rigor 가 아니라 마찰이다. 비trivial 작업의 경우, spec 을 완료로 선언하기 전에
  아래 completeness sweep 를 돌려라.

## 묻기 전에 읽어라 (질문을 ground 하라)

일반적 질문 ("bad input 에 뭐가 일어나야 하나?") 은 일반적 답을 얻는다.
*ground 된* 질문 ("`getPlan` 은 현재 missing id 에 `None` 을 반환하고
`report.summarize` 는 그걸 `[]` 로 매핑한다 — 유지할까, 아니면 지금 raise 할까?") 은
결정을 얻는다. 차이는 먼저 읽었다는 것이다. Socratic 클러스터 전에,
작업이 건드리는 영역을 scope-read 한다:

- **코드** — 프로젝트에 코드 인텔리전스가 있으면 쓴다: code-graph MCP
  (`semantic_search_nodes`, caller/callee 용 `query_graph`, `get_impact_radius`)
  또는 LSP, 이는 caller 와 blast radius 를 싸게 준다. 없으면 Read/Grep 으로
  폴백한다. impact radius 를 통해 작업이 건드리는 것으로 scope 한다 —
  레포 전체를 읽지 말 것.
- **결정, context & guide** — 관련된 기존 ADR 와 concept
  페이지를 읽어 정해진 것을 재론하지 않고, `docs/guides/` /
  `docs/reference/` 에서 이 작업이 따라야 할 문서화된 절차나 계약을
  확인한다 (`context-adr.md` 참조). 코드는 *무엇인지*; ADR/concept 는 *왜인지*;
  guide/reference 는 *어떻게 하기로 돼 있는지* 를 말해준다.

그다음 각 질문을 찾은 것에 anchor 한다. 이것이 한 번에 끝내는 가장 큰
지렛대다: 대부분의 재작업은 기존 코드에 대한 잘못된 가정이나 잊힌 이전 결정에서
오고, 먼저 읽으면 어떤 질문을 묻기 전에 둘 다 죽인다.

## 여섯 질문 유형 (gap 을 덮어라, 전부 암송하지 말 것)

당신이 던지는 모든 질문은 여섯 고전적 Socratic 유형 중 하나다:

1. **명료화 (Clarification)**
2. **가정 탐색 (Probing assumptions)**
3. **이유 & 증거 탐색 (Probing reasons & evidence)**
4. **대안 관점 (Alternative viewpoints)**
5. **함의 & 결과 (Implications & consequences)**
6. **질문을 질문하기 (Question the question)**

각 유형의 정의·예시 모음·가장 약한 차원에 맞는 선택법은 6-유형 단일 SSOT
`~/.claude/skills/deep-interview/references/socratic-playbook.md` 에 산다 — 여기
복제하지 않는다(개정 시 그 파일만 고친다). 매 라운드 현재 가장 약한 차원을 가장 잘
비집어 여는 유형을 고르라.

## 작업유형 강조 (호출 스킬이 설정)

- **forge** → 유형 1 & 5: 아직 존재하지 않는 것의 IO 계약과 성공
  지표를 못 박는다.
- **renew** → 유형 2, 4 & 5: 현재 behavior 중 보존돼야 할 것 대 바뀔 것,
  누가 의존하는지, 변경이 견뎌야 할 worst-case/엣지 입력을 surface 한다.
- **hunt** → 유형 1, 3 & 5: 정확한 재현과 증거 기반 근본
  원인, 그리고 수정이 깨면 안 되는 blast radius / 엣지 입력을 얻는다.

## 멈추기 전에 — completeness sweep (비trivial 작업)

"테스트 가능" 은 "완전" 과 다르다: spec 이 깔끔하게 읽혀도 빌드 중에
재작업 라운드를 강요하는 엣지 케이스를 빠뜨릴 수 있다. 궁극적 목표는 작업을
한 번에 끝내는 것이므로, 비trivial 작업 (대략 3+ 파일, 또는 진짜 실패 모드가 있는
무엇이든) 에서 spec 을 완료로 선언하기 전에, 마지막 클러스터를 하나 돌려라 —
사용자가 말하지 않았지만 구현이 부딪힐 것을 surface 한다:

- **엣지 & 실패 입력** — 이것이 견뎌야 할 최악, 가장 빈, 가장 큰, 가장 동시적
  입력, 그리고 실패 시 뭘 하는가 (raise? default? retry?).
- **비기능 제약** — 이 작업이 그럴듯하게 건드리는 것만:
  성능/스케일, 보안, backward-compatibility, 에러/로그 동작.
- **명시적 out-of-scope** — 이것이 하지 **않을** 것을 거명하고, 사용자와
  확인해서, scope creep 이 나중에 그걸 다시 열 수 없게 한다.

각 답을 방향만이 아니라 *정밀하게* 핀한다 — 정밀성은 계약의 일부이고,
반쯤 핀된 답은 여전히 Phase 2 에 발견을 남긴다. 답이 계약 결정을 함의하면,
정확한 형태를 쓴다:

- "raises an error" 가 아니라 정확한 예외 — 거명, `ValueError` 대
  `TypeError`, 어떤 입력이 어떤 것을 trigger 하는지.
- "a cap (e.g. 1000)" 가 아니라 정확한 상수 — 코드에 들어가는 literal 숫자.
- 입력이 그걸 바꿀 수 있을 때 "a list" 가 아니라 정확한 반환 타입/shape —
  예: "always a new `list`", "a slice of the input" 아님.

이건 추가 질문이 아니라 기록 규율이다: 대부분은 사용자가 답할 게 아니라 당신이
결정하고 적을 것들이다. 차원은 당신이 묻는 것; 정밀성은 당신이 핀하는
것이다. 차원을 거명하지만 "TypeError/ValueError" 나 "e.g. 1000" 을
느슨하게 남기는 sweep 는 여전히 리뷰에서 blocking 발견을 끈다 — gap 은
coverage 가 아니라 정밀성이었다.

이게 자리값을 하는 이유: 미명세 엣지는 Phase 2 에서 codex 의
"이건 미명세다" 발견으로 surface 한다 — 그러나 codex 는 사용자에게 물을 수
없으므로, 또 한 라운드나 추측을 강요한다. 여기서 물으면 그 gap 을 미리
닫는데, 그게 바로 한 번에 끝내는 성공이 필요로 하는 것이다. 한 클러스터 (2–4
질문) 로 유지하라; 마찰만 더할 진짜 trivial (T1, 1–2 파일) 작업에는 스킵한다.

## Anti-patterns

- 모든 질문을 한 번에 쏟기 → 사용자가 disengage 하고 얕게 답한다.
- 코드가 이미 답하는 것을 묻기 → 보지 않은 것처럼 보인다.
- "make it better / handle errors / clean it up" 을 spec 으로 받기 → 이것들은
  테스트 가능하지 않다; 그렇게 될 때까지 밀어붙여라.
- 영원히 질문하기 → spec 이 테스트 가능해지면, 플랜으로 넘어가라.
