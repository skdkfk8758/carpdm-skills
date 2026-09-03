# Next-skill routing — deep-* · goal-prompt 공통 다음 단계 추천 규격 (SSOT)

> 이 파일이 `deep-interview` · `deep-plan` · `goal-prompt` 의 **종료 직전 "다음 스킬
> 추천"** 단일 소스다. 세 스킬 모두 이 규칙을 읽어 적용한다 — 복제하지 말 것(drift
> 차단). 한쪽만 바꾸지 말고 이 파일을 바꿔라.
>
> 이 파일은 **종료 후** 라우팅이다. 인터뷰 **진입** 판단(어떤 인터뷰로 시작하나)은
> 글로벌 `~/.claude/rules-ondemand/interview-routing.md` — 여기 재기술하지 않는다.

산출물(spec · PLAN · Goal Prompt)을 다 만든 뒤, 사용자가 *다음에* 무엇으로 이어가면
좋을지 한 번 추천한다. 목적은 산출물을 막다른 길로 두지 않고 가장 자연스러운 다음
워크플로로 손을 건네는 것이다. **추천만 한다 — 절대 자동 시작하지 않는다.**

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
(`plugin:skill` 네임스페이스 형, 예: `mattpocock-skills:grilling`,
`skill-creator:skill-creator`)도 bare-name 스킬과 **동등한 후보다** — 형식이 다르다고
배제하지 말 것.

**available-skills 에 안 보이는 스킬 두 부류:**
- `disable-model-invocation: true` 스킬(`/grill-with-docs` · `/to-tickets` · `/wayfinder`
  · `/hate` 등) — 모델이 Skill 도구로 못 부른다. **"사용자가 타이핑"** 형태로만 제안하고
  `AskUserQuestion` 옵션 라벨에 그 사실을 적는다.
- 미설치 스킬 — 이름을 지어내지 않는다. 표에 있어도 목록에 없으면 후보가 아니다.

## valid-next 필터 — "다음 행동" 이 될 수 있는 것만

available-skills 는 40+ 개일 수 있다. 대부분은 이 산출물의 *다음 단계* 가 아니다.
다음만 후보로 남기고 나머지는 자동 배제한다:

- **후보 가능** — 이 spec/plan/prompt 를 *입력으로 받아 전진*시키는 스킬: 빌드
  (메인 직접 구현 · `mattpocock-skills:tdd` · `/implement`), plan 화·다중 이슈 분해
  (`deep-plan` · `/to-tickets`), 단건~소수 이슈 등록(`linear-register`), **자율 실행**
  (Orca goal 카드에 `-prompt.md` 통째 — 사용자 조작 · 이슈 키 기반이면 `linear-start`),
  조사(`mattpocock-skills:research`), 설계 검증
  (`mattpocock-skills:prototype`), 빌드 전 **plan 압박 검증**(`mattpocock-skills:grilling`
  · `/hate`) 등. (검증은 산출물을 입력으로 받아 *더 단단하게* 전진시키므로 후보다 —
  빌드처럼 코드를 내지 않을 뿐.)
- **후보 아님(배제)** — 산출물의 다음 단계가 될 수 없는 운영/유틸 스킬:
  `sweep`/`land`/`ship`/`handoff`/`wt-sweep`/`caveman`/`statusline-setup`/`update-config`
  등. 한 번도 추천하지 말 것. **인터뷰 스킬끼리의 재진입**(deep-interview 뒤
  deep-interview · 이미 grilling 한 뒤 `/grill-me`)도 배제 — 이중 인터뷰.

판단 기준 한 줄: *"이 스킬이 방금 만든 산출물을 받아 의미 있게 다음으로
나아가게 하는가?"* 아니면 후보가 아니다.

## 2-tier 후보군

### Tier 1 — 빌드 단축 경로 (산출물이 명백히 빌드 작업일 때)

산출물이 드러낸 작업 성격이 빌드(새 기능/변경/고장)로 **명백할 때만** 해당하는
단축 경로다. 종전 `forge`/`renew`/`hunt` 파이프라인은 은퇴했다(#167) — 빌드는
**메인이 직접** 한다. 단 이것은 *단축*일 뿐 Tier 2 열거를 건너뛰는 면허가 아니다 —
빌드가 명백하지 않거나 분해/조사/프로토타입 같은 다른 전진 경로가 더 맞을 수 있으면
Tier 2 후보를 반드시 함께 본다.

| 산출물이 드러낸 것… | 라우팅 | 비고 |
|---|---|---|
| 한 세션에 담기는 빌드(새 기능·변경) | **메인 직접 구현** — plan mode → 구현 → `/code-review` | 기본값. 스킬 아님 |
| 같은 빌드를 **테스트 우선**으로 | `mattpocock-skills:tdd` (모델 발동) | red-green 슬라이스 |
| 트래커 세팅된 repo 에서 **티켓 단위 빌드** | `/to-tickets` → `/implement` (사용자 타이핑) | `/setup-matt-pocock-skills` 선행 필요 |
| 고칠 **고장난** 무언가 | `mattpocock-skills:diagnosing-bugs` (모델 발동) | 요구사항이 아니라 재현+근본원인을 원함 — 보통 인터뷰 없이 직행 |

### Tier 2 — valid-next 전체 후보 (항상 함께 열거, 글로벌·플러그인 포함)

Tier 1 단축이 명백하더라도, 컨텍스트의 available-skills 목록에서 valid-next 후보를
**실제로 열거**한다 — 글로벌·플러그인 스킬을 모두 포함해서. 아래는 *형태 예시*일 뿐
고정 목록이 아니다(그때 설치된 것에서 고르라; 표에 없어도 valid-next 면 후보다).
호출 형태는 2026-09-03 실측 — 플러그인 업데이트로 바뀔 수 있으니 목록에서 재확인.

| 산출물/다음 의도… | 라우팅 | 호출 형태 |
|---|---|---|
| plan 을 독립적으로 grab 가능한 **Linear 이슈 트리로 분해** | `deep-plan` (Step 4.5 — `linear.md` §2 트리 등록) | 모델 발동 |
| spec 을 **blocking edge 달린 tracer-bullet 티켓**으로 분해 | `/to-tickets` | 사용자 타이핑 · 트래커 setup 선행 |
| 단건~소수 이슈 **등록** | `linear-register` | 모델 발동 |
| Goal Prompt(`-prompt.md`)를 **자율 실행** | Orca goal 카드에 파일 통째 붙여넣기 — 모델이 띄우는 경로 없음 | 사용자 조작 |
| Linear 이슈(키 있음)를 **자율 착수** — 프롬프트 파일 없이 | `linear-start` — 이슈 본문에서 자기 worker 프롬프트를 만든다, `-prompt.md` 는 읽지 않는다 | 모델 발동 |
| 빌드 전 plan/design 을 **결정트리 압박·구멍 찾기** | `mattpocock-skills:grilling` | 모델 발동 |
| 위 + repo 에 **CONTEXT.md·ADR 흔적** 남기며 | `/grill-with-docs` | 사용자 타이핑 |
| 계획을 실제 공수 들이기 직전 **철거 반사** | `/hate` (paperthin) | 사용자 타이핑 |
| 인터뷰가 **`[THIRD]` 갭**(답이 제3자에게)을 남겼다 | `/to-questionnaire` | 사용자 타이핑 |
| 빌드 전 **사실 조사·1차 출처 검증** 이 먼저 필요 | `mattpocock-skills:research` | 모델 발동(백그라운드) |
| 커밋 전 **버릴 프로토타입**으로 설계 검증 | `mattpocock-skills:prototype` | 모델 발동 |
| 용어·엔티티가 흔들려 **도메인 모델/ADR** 부터 | `mattpocock-skills:domain-modeling` | 모델 발동 |
| **새 UI 미감 창작**(자유 디자인) | `frontend-design` | 모델 발동 |
| 코드베이스 **구조 파악**이 먼저 | `graphify` | 모델 발동 |
| (deep-interview 한정) 빌드 전 **plan 문서/시안** 먼저 | `deep-plan` | 모델 발동 |
| (deep-interview 한정) spec 을 **자율 에이전트 프롬프트**로 | `goal-prompt` | 모델 발동 |

## 규모 신호 — 분해를 함께 제안할 때

종전 craft 엔진의 linear/council 강도 추천은 엔진과 함께 은퇴했다. 남는 판단은 하나 —
**한 세션에 담기는가**. 인터뷰/plan 이 측정한 신호로 판정하고, 아니면 빌드 대신
**분해**(`deep-plan` Step 4.5 · `/to-tickets`) 또는 **병렬 착수**(`linear-start` N건)를
앞세운다:

- 넓은 토폴로지(4~6 상호의존 컴포넌트) · 멈출 때 잔여 ambiguity · 힘든 수렴(많은
  라운드, challenge mode 발동) · 횡단 non-functional(보안/마이그레이션/호환성).
- 신호가 없으면 "한 세션 빌드" 라 말하고 넘어가라 — 분해는 공짜가 아니다.

## 이중 인터뷰 회피 — 핸드오프 프레이밍

다음 스킬 다수가 *자체* 갭 인터뷰를 갖는다(`goal-prompt` Step 3 · `deep-plan` 갭
인터뷰 · `linear-replan` 체크리스트 · `mattpocock-skills:grilling`). 순진하게 핸드오프하면
사용자가 두 번 인터뷰받는다. 그러니 추천은 다음 스킬에게 이 산출물을 **이미 확정된
입력**으로 취급하고 인터뷰를 스킵하라고 알려야 한다. 예:

> "요구사항은 `docs/specs/<slug>.md` 에 못 박혔습니다(ambiguity <N>%). 그 spec 을
> 확정 입력으로 삼아 구현으로 가세요 — 다시 인터뷰하지 말고. grilling 으로 압박하려면
> spec 의 Residual ambiguity 항목만 프론티어로."

`/to-spec` 은 "인터뷰 없음, 합성만" 이라 deep-interview 뒤에는 중복이다(이미 spec 이
있다) — 후보에서 뺀다.

## 제시 — AskUserQuestion, 추천만

`AskUserQuestion` 전에 짧게: available-skills 목록에서 valid-next 를 통과하는 후보를
**열거**하고 각 한 줄로 적합도를 매겨 상위 2~3 을 고른다. Tier 1 단축이 정확 매칭이
아니면, 표에 없는 글로벌/플러그인 스킬을 최소 하나 검토 대상에 넣어 예시-anchor 를
깬다(억지로 추천하라는 게 아니라 *고려*하라는 것 — 안 맞으면 떨군다).

그렇게 추린 뒤 `AskUserQuestion` 으로 추천한다. 사용자 타이핑 전용 스킬은 옵션 라벨에
`(사용자가 /이름 타이핑)` 을 붙인다 — 선택돼도 모델이 시작할 수 없음을 미리 보이게.
결정은 항상 사용자가 한다 — 절대 다음 스킬을 자동 시작하지 말 것. 매칭되는 스킬이
설치돼 있지 않으면, 그 사실을 말하고 산출물 파일을 그대로 넘기라(폴백).

## 호출 스킬별 차이

- **deep-interview** — 입력 = 번호 매긴 요구사항 **spec**. 주 경로는 메인 직접 구현이고,
  `deep-plan`(빌드 전 plan/시안) · `goal-prompt`(자율 에이전트 프롬프트) ·
  `mattpocock-skills:grilling`(Residual ambiguity 압박)도 valid 후보다. `[THIRD]` 잔여가
  있으면 `/to-questionnaire`(타이핑)를 함께. spec 을 만든 *목적*이 빌드로의
  핸드오프이므로 추천은 적극적이다.
- **deep-plan** — 입력 = **PLAN 문서 + Goal Prompt(`-prompt.md`)**(+UI 시안).
  deep-plan 은 "순수 산출" 도구라 자동 라우팅하지 않는다 — 이 추천은 **제안일 뿐
  시작이 아니다**. `deep-plan` 자신은 후보에서 제외(이미 만들었다). 흔한 다음 단계
  셋: ① plan 을 받아 메인이 빌드, ② 이슈로 분해(`deep-plan` Step 4.5 — 이미 등록했으면
  `linear-start`), ③ **자율 실행** — `-prompt.md` 는 애초에 자율 에이전트 goal 칸에
  통째로 들어가라고 만든 파일이다 — Orca goal 카드(사용자 조작). Step 7.5 에서 Linear
  이슈로 등록됐으면 `linear-start` 로 그 이슈를 착수하는 경로도 후보에 넣되, linear-start
  는 **이슈 본문**으로 worker 프롬프트를 만들지 `-prompt.md` 를 읽지 않는다고 명시한다
  (프롬프트 내용이 이슈 본문에 없으면 유실).
- **goal-prompt** — 입력 = **Goal Prompt 1파일**. autonomous 소비자면 Orca goal 카드에
  붙여넣기(사용자 조작)가 사실상 유일한 다음 단계 — 그것을 첫 옵션에. `linear-start` 는
  `-prompt.md` 를 읽지 않으므로 후보가 아니다.
  interactive 면 "새 세션에 붙여넣기" + 첫 체크포인트(`/hate`) 안내. `deep-plan` 은
  후보에서 제외(goal-prompt 는 deep-plan 이 과한 경우 고른 것).
