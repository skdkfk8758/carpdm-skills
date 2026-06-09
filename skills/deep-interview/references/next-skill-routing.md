# Next-skill routing — deep-* 공통 다음 단계 추천 규격 (SSOT)

> 이 파일이 `deep-interview` 와 `deep-plan` 의 **종료 직전 "다음 스킬 추천"** 단일
> 소스다. 두 스킬 모두 이 규칙을 읽어 적용한다 — 복제하지 말 것(drift 차단).
> 한쪽만 바꾸지 말고 이 파일을 바꿔라.

산출물(spec 또는 PLAN)을 다 만든 뒤, 사용자가 *다음에* 무엇으로 이어가면 좋을지
한 번 추천한다. 목적은 산출물을 막다른 길로 두지 않고 가장 자연스러운 다음 워크플로
로 손을 건네는 것이다. **추천만 한다 — 절대 자동 시작하지 않는다.**

## 메커니즘 — 설치 스킬을 스캔하지 마라

후보 스킬을 찾으려고 `ls ~/.claude/skills/` 나 플러그인 캐시를 Bash 로 긁지 말 것.
설치된 모든 스킬의 `name`+`description` 은 **이미 당신의 컨텍스트(available-skills
목록)에 항상 주입돼 있다** — 그게 스킬 트리거가 동작하는 원리 그 자체다. 그 목록을
읽어 고르라. Bash 스캔은 description 이 없고, 플러그인 스킬을 놓치며, 환경마다
깨진다 — 더 나쁘다.

**예시 테이블이 아니라 그 목록이 후보 출처다.** 아래 Tier 1/Tier 2 표는 *매핑 형태
예시*일 뿐 후보 목록이 아니다 — LLM 은 프롬프트 안 예시에 anchor 해 표에 적힌 몇몇
로컬 스킬만 반복 추천하는 실패가 흔하다. 추천 전 **반드시** 컨텍스트의 available-skills
목록을 실제로 훑어 valid-next 후보를 그 자리에서 재선정하라. 플러그인 스킬
(`plugin:skill` 네임스페이스 형, 예: `codex:rescue`, `understand-anything:understand`,
`skill-creator:skill-creator`)도 bare-name 스킬과 **동등한 후보다** — 형식이 다르다고
배제하지 말 것.

## valid-next 필터 — "다음 행동" 이 될 수 있는 것만

available-skills 는 40+ 개일 수 있다. 대부분은 이 산출물의 *다음 단계* 가 아니다.
다음만 후보로 남기고 나머지는 자동 배제한다:

- **후보 가능** — 이 spec/plan 을 *입력으로 받아 전진*시키는 스킬: 빌드
  (`forge`/`renew`/`hunt`), plan 화(`deep-plan`), 이슈/PRD 분해(`to-issues`/`to-prd`),
  조사(`deep-research`), UI 탐색(`prototype`/`frontend-design`/`imprint`),
  빌드 전 **plan 압박 검증**(`grill-me`/`grill-with-docs`) 등. (검증은 산출물을 입력으로
  받아 *더 단단하게* 전진시키므로 후보다 — 빌드처럼 코드를 내지 않을 뿐.)
- **후보 아님(배제)** — 산출물의 다음 단계가 될 수 없는 운영/유틸 스킬:
  `sweep`/`land`/`handoff`/`caveman`/`statusline-setup`/`update-config` 등. 한 번도
  추천하지 말 것.

판단 기준 한 줄: *"이 스킬이 방금 만든 산출물을 받아 의미 있게 다음으로
나아가게 하는가?"* 아니면 후보가 아니다.

## 2-tier 후보군

### Tier 1 — 정확 매칭 빌드 단축 경로 (산출물이 명백히 빌드 작업일 때)

산출물이 드러낸 작업 성격이 빌드(새 기능/변경/고장)로 **명백할 때만** 해당하는
단축 경로다. high-signal 인 이유는 작업 성격을 빌드 스킬에 정밀 매핑하고 아래
"이중 인터뷰 회피" 핸드오프를 함께 싣기 때문이다. 단 이것은 *단축*일 뿐 Tier 2
열거를 건너뛰는 면허가 아니다 — 빌드가 명백하지 않거나 분해/조사/프로토타입 같은
다른 전진 경로가 더 맞을 수 있으면 Tier 2 후보를 반드시 함께 본다.

| 산출물이 드러낸 것… | 라우팅 | 적합도 |
|---|---|---|
| 존재하지 않는 **새** 능력 (greenfield) | **`/forge`** | best |
| 기존 기능 **변경** — 동작 이동, 호출자 깨질 수 있음 (brownfield) | **`/renew`** | strong |
| 고칠 **고장난** 무언가 | **`/hunt`** | weak — hunt 는 요구사항이 아니라 재현+근본원인을 원함; 보통 `/hunt` 직행 |

### Tier 2 — valid-next 전체 후보 (항상 함께 열거, 글로벌·플러그인 포함)

Tier 1 단축이 명백하더라도, 컨텍스트의 available-skills 목록에서 valid-next 후보를
**실제로 열거**한다 — 글로벌·플러그인 스킬을 모두 포함해서. 아래는 *형태 예시*일 뿐
고정 목록이 아니다(그때 설치된 것에서 고르라; 표에 없어도 valid-next 면 후보다):

| 산출물/다음 의도… | 라우팅 |
|---|---|
| plan 을 독립적으로 grab 가능한 **이슈로 분해** | `to-issues` |
| 맥락을 **PRD 로 발행** | `to-prd` |
| 빌드 전 plan/design 을 **적대 압박테스트·결정트리 추궁** | `grill-me` / `grill-with-docs` |
| 빌드 전 **사실 조사·다출처 검증** 이 먼저 필요 | `deep-research` |
| 커밋 전 **버릴 프로토타입**으로 설계 검증 | `prototype` |
| **새 UI 미감 창작**(자유 디자인) | `frontend-design` |
| **주어진 DESIGN.md 충실 재현**(추출 디자인) | `imprint` |
| 코드베이스 **이해·구조 파악**이 먼저 (플러그인 예) | `understand-anything:understand` |
| 막힌 지점 **2nd-opinion·조사 위임** (플러그인 예) | `codex:rescue` |
| (deep-interview 한정) 빌드 전 **plan 문서/UI 시안** 먼저 | `deep-plan` |

## 강도(intensity)도 함께 추천 — 빌드로 라우팅할 때

craft 파이프라인(`forge`/`renew`/`hunt`)은 두 모드로 실행된다 — *linear*(기본,
단일 세션) 또는 *orchestrated*(멀티에이전트 디자인 council: 적대적 디자인 공격 +
빌드 후 intent 검증, 더 느리고 비쌈). 엔진은 보통 시작에서 차가운 "stakes signal"
로 모드를 추측하지만, 당신은 방금 그것을 측정/설계하느라 전 과정을 썼으니 판단을
앞으로 넘기라. **실제 디자인 리스크**가 드러났을 때만 council 을 추천하고, 아니면
기본값 linear(council 은 opt-in 이고 비싸다 — 명확·작은 작업에 밀어붙이지 말 것).

강한 council 신호: 멈출 때 잔여 ambiguity; 넓은 토폴로지(4~6 상호의존 컴포넌트);
힘든 수렴(많은 라운드, challenge mode 발동); 횡단 non-functional(보안/마이그레이션
/호환성); **산출물이 UI 시안과 기능 Acceptance 를 함께 가져 둘이 한 번에 맞아야
할 때**(시안 충실도가 핵심인 경우만 — 단순 CRUD 화면이나 미감이 부차적이면 제외,
안 그러면 거의 모든 풀스택 빌드가 council 로 과발화한다); **이번 맥락에 구현이
plan 을 벗어나거나 한 번에 완결되지 않을 우려가 드러난 경우**(과거 세션 이력을
추측하지 말 것 — 지금 대화/플랜에 실제로 드러난 신호만). 뒤 두 신호가 council 을
부르는 이유는 같다 — orchestrated 의 빌드-후 intent judgment loop(verify green
AND 살아있는 designer 가 confirmed gap 을 제기하지 않을 때까지 재구현)가 linear
엔 없는, 시안·plan 의도 이탈을 잡는 게이트이기 때문이다. 없으면 linear 라 말하고
넘어가라.

## 이중 인터뷰 회피 — 핸드오프 프레이밍

`forge`/`renew`/`hunt` 각각은 *자체* Socratic 요구사항 단계를 돌린다(공유 craft-core
Phase 1). 순진하게 핸드오프하면 사용자가 두 번 인터뷰받는다. 그러니 추천은 다음
스킬에게 이 산출물을 **이미 완료된 Phase-1 결과물**로 취급하고 곧장 plan review 로
건너뛰라고 알려야 한다. 예:

> "요구사항은 `docs/specs/<slug>.md` 에 못 박혔습니다(ambiguity <N>%). 그 spec 을
> Phase-1 결과로 써서 `/forge` 를 돌리세요 — 다시 인터뷰하지 말고; 다음으로 적대적
> plan review 로 가세요."

## 제시 — AskUserQuestion, 추천만

`AskUserQuestion` 전에 짧게: available-skills 목록에서 valid-next 를 통과하는 후보를
**열거**하고 각 한 줄로 적합도를 매겨 상위 2~3 을 고른다. Tier 1 단축이 정확 매칭이
아니면, 표에 없는 글로벌/플러그인 스킬을 최소 하나 검토 대상에 넣어 예시-anchor 를
깬다(억지로 추천하라는 게 아니라 *고려*하라는 것 — 안 맞으면 떨군다).

그렇게 추린 뒤 `AskUserQuestion` 으로 추천한다. 결정은 항상 사용자가 한다 — 절대 다음
스킬을 자동 시작하지 말 것. 매칭되는 스킬이 이 프로젝트에 설치돼 있지 않으면, 그
사실을 말하고 산출물 파일을 그대로 넘기라(폴백).

## 호출 스킬별 차이

- **deep-interview** — 입력 = 번호 매긴 요구사항 **spec**. Tier 1 빌드 라우팅이
  주 경로이고, `deep-plan`(빌드 전 plan/시안 먼저)도 valid 후보다. spec 을 만든
  *목적*이 빌드로의 핸드오프이므로 추천은 적극적이다.
- **deep-plan** — 입력 = **PLAN 문서**(+UI 시안). deep-plan 은 "순수 산출" 도구라
  자동 라우팅하지 않는다 — 이 추천은 **제안일 뿐 시작이 아니다**. `deep-plan` 자신은
  후보에서 제외(이미 만들었다). plan 을 받아 빌드(Tier 1)하거나 이슈로 분해
  (`to-issues`)하는 것이 가장 흔한 다음 단계다.
