---
name: linear-replan
description: >-
  착수 직전에 Linear 이슈 1건(또는 짧은 자유 요구사항 텍스트)을 codex 로 재플래닝해 착수 계획 문서 1개를 만든다 — codex exec 로 플랜 초안 + 결정 갈래 체크리스트를 받고, 그 체크리스트를 AskUserQuestion 인터뷰로 전항목 확정한 뒤, 이슈 모드면 승인 게이트 후 확정 플랜을 이슈 코멘트로 첨부한다(이슈 본문·상태는 건드리지 않음). "이 티켓 어떻게 할지 먼저 정해줘", "ADT-435 착수 계획 짜줘", "구현 전에 갈래 정리해줘", "replan", "이거 시작하기 전에 결정할 것들 물어봐줘" 같은 표현에 사용. 계획이 확정되면 실행은 linear-goal 로 넘긴다. 이슈가 아직 없는 대형·고위험 설계나 전면 개편의 플랜·시안 산출은 deep-plan, 신규 이슈 등록은 linear-register, 백로그 보강은 linear-groom.
---

# linear-replan — 착수 직전 재플래닝: codex 초안 → 갈래 인터뷰 → 착수 계획 1장

Linear 이슈 본문은 **의도적으로 얇다**(헤딩 화이트리스트 + 길이 상한 + 산문 내 파일경로
금지 — `linear-register` 계약). 그래서 등록 시점엔 깔끔하던 티켓이 막상 착수하려는 순간
"그래서 어디를 어떻게 고치지"라는 갭을 남긴다. 이 스킬이 그 갭을 **착수 시점에만** 메꾼다:
이슈를 가져와 레포에서 실측 grounding 하고, `codex exec` 로 다른 모델의 플랜 초안 +
**결정 갈래 체크리스트**를 받고, 그 갈래를 사람에게 전항목 물어 확정하고, 결과를 착수 계획
문서 1장으로 남긴다.

핵심은 **결정을 사람에게서 뽑는 것**이다. 플랜을 예쁘게 쓰는 게 목적이 아니라, 자율 실행이
표류하는 원인(미확정 갈래가 본문에 남아 있는 것)을 착수 전에 0으로 만드는 게 목적이다.

> 자매 관계: 확정된 계획의 실행 = `linear-goal` · 이슈 없는 대형 설계·시안 = `deep-plan` ·
> 신규 이슈 등록 = `linear-register` · 기존 백로그 보강 = `linear-groom`.

## 안전 불변식 — 먼저 읽을 것

- **이슈 본문·상태를 수정하지 않는다.** 이 스킬이 Linear 에 쓰는 것은 **코멘트 1건**뿐이고,
  그것도 Step 5 승인 게이트 뒤에만. 본문 재작성·상태 전이(In Progress 등)·라벨 변경은 이
  스킬의 일이 아니다(전이는 `linear-goal`/빌드 파이프라인 몫).
- **코드를 한 줄도 바꾸지 않는다.** 산출은 계획 문서 1개(+선택 코멘트 1건). 구현은
  `linear-goal`·`forge`/`hunt`/`renew` 가 한다.
- **codex 없이 진행하지 않는다.** codex 경유의 교차모델 초안이 이 스킬의 존재 이유다 —
  프리플라이트 실패면 Claude 단독으로 몰래 대체하지 말고 정지하고 라우팅한다(Step 0).
- **체크리스트를 미확정인 채 문서로 내보내지 않는다.** 전항목 확정이거나, 사용자가 명시로
  위임해 **봉인**된 상태(문서에 봉인 항목 명시)여야 한다.

## Step 0 — codex 프리플라이트 + 입력 모드 판정

**① codex 프리플라이트.** `command -v codex`(필요 시 `codex doctor`)로 CLI 가용성을
확인한다.

**PATH 조회 실패 = 불가로 확정한다.** 다른 설치본을 찾아 나서지 않는다 — `ls
/opt/homebrew/bin/codex`, `find / -name codex`, npx·절대경로 실행 등으로 우회하면 이
프리플라이트는 아무것도 막지 못한다(실측 2026-08-03: PATH 에서 codex 를 뺀 세션이
`which -a codex` → `codex not found` 를 받고도 `/opt/homebrew/bin/codex` 를 찾아내
그대로 실행했다). 사용자가 그 경로를 **명시로 준 경우만** 예외다.

불가하면 **안내 한 줄 + 깨끗한 정지**:

> codex CLI 가 없어 재플래닝을 돌릴 수 없습니다(이 스킬은 codex 교차모델 초안이 전제).
> 설치 후 재실행하거나, **Claude 단독 재플래닝이 필요하면 `deep-plan`** 으로 진행하세요.

정지란 문서·코멘트를 아무것도 만들지 않고 끝내는 것이다. 조용한 폴백 금지.

**② 입력 모드 판정.**

| 입력 | 모드 | 동작 |
|---|---|---|
| 이슈 ID(`ADT-435`)·이슈 URL·세션의 `Linked Linear issue` 배너 | **이슈 모드** | Step 1 fetch + Step 5 코멘트 첨부 |
| 짧은 **자유 요구사항** 텍스트 (이슈 없음) | **텍스트 모드** | fetch·코멘트 생략 — 텍스트 자체가 입력, kickoff 문서로 종료 |

**대형·고위험 요구사항은 텍스트 모드로 받지 않는다** — 전면 개편·다중 표면 cross-cutting·
비가역(스키마 apply·대량 삭제) 신호가 보이면 `deep-plan` 라우팅을 제안하고 멈춘다(아래
§경계와 같은 기준). 텍스트 모드는 "이슈로 만들기 전에 갈래부터 정리하고 싶은 소형 요구사항"
전용이다.

## Step 1 — 입력 확보 + 레포 grounding

- **[이슈 모드]** Linear MCP 로 이슈를 fetch 한다(제목·본문·라벨·estimate·관계). MCP 감지와
  미설치 시 처리는 `~/.claude/skills/craft-core/references/linear.md` §1 그대로 —
  **MCP 미설치면 가이드 한 번 + 정지**한다(이 스킬은 이슈 입력이 없으면 성립하지 않는다).
  절차를 여기 복제하지 말고 그 파일을 읽어라.
- **[텍스트 모드]** fetch 생략 — 사용자가 준 요구사항 텍스트가 곧 입력이다.
- **공통 — 레포 grounding(양 모드 필수).** 건드릴 반경만 Read/Grep 으로 실측한다(레포 전체
  스캔 아님). 파일 경로·함수·계약은 **읽은 것만** 적는다. 이 grounding 이 부실하면 codex 가
  존재하지 않는 파일 위에 플랜을 세운다.

## Step 2 — codex exec 로 초안 + 결정 갈래 체크리스트

프롬프트를 **stdin 으로 파이프**해 `codex exec` 를 비인터랙티브로 호출한다. 프롬프트에
싣는 것: 입력(이슈 본문 또는 요구사항 텍스트) + Step 1 grounding digest(경로·계약 — secret·
내부 호스트 마스킹) + 아래 산출 계약.

```
<output>
1) DRAFT PLAN — 착수 계획 초안. 각 Step 에 verify(그 Step 이 됐다는 관찰 가능한 확인)를 붙일 것.
2) DECISIONS — 이 계획을 실행하기 전에 사람이 골라야 하는 결정 갈래만. 각 항목:
   질문 1줄 + 선택지(레포 실측 또는 요청문에서 도출된 것만) + 초안값(당신의 추천) + 그 근거 1줄.
   검증 항목·테스트 항목·확인 절차는 여기 넣지 말 것 — 갈래가 아니다.
</output>
Do not edit, create, or delete any files. Answer in text only.
```

**watchdog 의무.** `codex exec` 는 Bash background 실행 + 진행 감시로 돌리고, **무진행
8분+ 또는 hard cap 12분이면 kill** 한다. `timeout` 래핑은 그 위에 얹는 보조 수단이며
**macOS 에는 `timeout` 이 기본 설치돼 있지 않다**(coreutils 필요 — 실측 2026-08-03:
`exit=127 command not found: timeout` 으로 watchdog 이 통째로 무산). 쓰려면 존재를
먼저 확인하고, 없으면 background + 감시만으로 진행한다. 규약 SSOT 는 글로벌
`~/.claude/rules-ondemand/delegated-review-watchdog.md` — 읽고 그대로 따른다. kill 되면
1회만 재시도하고, 그래도 무진행이면 그 사실을 보고하고 정지한다(Claude 단독 대체 금지 —
불변식).

read-only 계약: codex 산출은 **텍스트만** 취한다. 작업 트리 변경이 감지되면 폐기하고 정지.

## Step 3 — 체크리스트 인터뷰 (AskUserQuestion, 전항목 확정)

Step 2 의 DECISIONS 가 인터뷰의 유일한 의제다.

- **체크리스트 = 결정 갈래만.** 검증 항목·테스트 목록·"확인했나요" 류는 의제가 아니다
  (그건 계획 문서의 verify 로 들어간다). 갈래가 아닌 항목이 섞여 오면 인터뷰에서 빼고
  계획 본문으로 내린다.
- **전항목 확정까지 배칭.** 독립 갈래는 `AskUserQuestion` **1콜 최대 4질문**으로 묶는다.
  선택지는 codex 가 레포 실측·요청문에서 도출한 것만 — 창작한 옵션으로 묻지 않는다.
  의존 갈래(앞 답에 따라 질문이 달라지는 것)만 직렬로.
- **답 반영은 Claude 가 직접.** 항목별 답을 초안에 접는 것은 메인이 한다. **구조를 바꾸는
  큰 갈래**(Step 구성 자체가 달라지는 선택)일 때만 **codex 재호출 1회 한정** — 그 이상의
  핑퐁은 없다.
- **탈출구 — 봉인.** 사용자가 "나머지는 알아서" 를 선언하면 잔여 갈래를 **codex 초안값으로
  봉인**하고 인터뷰를 끝낸다. 봉인된 항목은 산출 문서에 `## 봉인 항목`(항목 + 채택된
  초안값 + 근거)으로 **반드시 명시**한다 — 조용한 봉인은 사용자가 고른 것으로 위장된다.

## Step 4 — 착수 계획 문서 1개 저장

- **[이슈 모드]** `docs/plans/<issue-id>-kickoff.md` (예 `docs/plans/ADT-435-kickoff.md`)
- **[텍스트 모드]** `docs/plans/<slug>-kickoff.md`

프로젝트가 다른 plan 위치를 쓰면 그곳. 문서 1개뿐이다 — 프롬프트/PLAN/HTML 3종 산출은
`deep-plan` 의 것이고 여기로 가져오지 않는다. 담을 것:

```
# <issue-id 또는 topic> 착수 계획
## 대상            ← 이슈 링크(이슈 모드) 또는 요구사항 원문(텍스트 모드)
## 확정 결정        ← 갈래별 [질문 → 확정값 → 근거]
## 봉인 항목        ← 있을 때만. 확정 아님을 명시
## Steps           ← 각 Step 에 verify 한 줄
## 대상 파일        ← Step 1 에서 실제로 Read/Grep 한 경로만
## 범위 밖
```

열어보지 않은 파일을 거명하면 실패다.

## Step 5 — [이슈 모드만] 승인 게이트 → 이슈 코멘트 첨부

확정 계획을 이슈에 **코멘트로** 붙인다. **본문은 수정하지 않는다** — 본문 계약(얇은 이슈)을
지키면서 착수 맥락만 덧붙이는 것이 코멘트를 쓰는 이유다.

1. **승인 게이트 (외부 write — 필수).** 붙일 코멘트 본문을 미리 보여주고
   `AskUserQuestion` 으로 승인/보류를 받는다. 승인 없이 첨부하지 않는다.
2. **마스킹 게이트.** Linear 는 외부 서비스이고 올린 내용은 캐시·인덱싱돼 삭제해도 남는다.
   credential·PII·내부 URL·DB dump 가 박혔으면 첨부를 보류하고 사유를 보고한다.
3. **AI disclaimer 1줄 부착** — 코멘트 말미에 이 계획이 AI 재플래닝 산출이며 사람 확인이
   전제라는 줄을 붙인다.
4. 첨부 실패(권한·네트워크)는 스킬을 실패로 만들지 않는다 — 경고만 남기고 문서 산출로 종료.

**[텍스트 모드]** 이 Step 을 통째로 건너뛴다(붙일 이슈가 없다).

## 종료 출력

`~/.claude/skills/craft-core/references/output-contract.md` 의 종료 블록을 따른다(복제 금지):
L1 `result:` 한 줄 + L2 산출물 열기 행(계획 문서 경로, 이슈 모드면 코멘트 URL) + L3 다음 스킬
제안(`AskUserQuestion` — 제안만, 자동 시작 없음).

L3 후보:

- **이슈 모드** → `linear-goal`(확정된 계획으로 자율 실행). 이 스킬의 산출이 그쪽의 갭을
  메꾼 상태이므로 재플래닝을 다시 돌리지 말라고 짚는다.
- **텍스트 모드** → `linear-register`(계획을 이슈로 등록) 또는 바로 빌드 스킬
  (`forge`/`hunt`/`renew`).

## 경계

- **vs `linear-goal`** — 그쪽은 **실행**이다(Goal Prompt 조립 → worker → PR). 이 스킬은 그
  앞단에서 이슈를 **goal-ready 로 끌어올린다**. 이슈가 이미 goal-ready
  (`skills/linear-goal/references/routing.md` §goal-ready — 실측 증거 + 측정 가능한 AC +
  범위 밖 + 해석 단일)면 재플래닝은 중복이다. 그땐 재플래닝하지 말고 `linear-goal` 직행을
  제안하고 멈춘다.
- **vs `deep-plan`** — 그쪽은 debate + PLAN + 프롬프트 + 시안까지 내는 무거운 설계 경로다.
  이슈가 **oversized-class**(estimate ≥ 5 · cross-cutting · 전면 개편·마이그레이션 · 비가역
  신호)이거나 텍스트 모드 입력이 그 규모면 이 스킬로 처리하지 않는다 — `deep-plan` 으로
  보내고(필요 시 `linear-register` 분할까지) 멈춘다. 판정 기준은 routing.md §Step 1 rubric
  을 그대로 쓴다(복제 금지).
- **vs `linear-register`** — 그쪽은 이슈를 **만든다**. 이 스킬은 이미 있는 이슈(또는 아직
  이슈가 아닌 요구사항)를 착수 가능하게 깎을 뿐 등록하지 않는다.
- **vs `linear-groom`** — 그쪽은 **백로그 전체**의 위생(배치·보강)이고 이슈 본문을 갱신한다.
  이 스킬은 **1건 · 착수 직전 · 본문 무수정**이다.

## 은퇴 조건

3개월 내 ① 텍스트 모드 오발화 실측(`deep-plan` 과 트리거 혼선) 또는 ② 실사용 저빈도면
`deep-plan` 경량 모드로의 흡수를 검토한다. codex CLI 가용성이 사라지면 스킬 자체를
폐지한다(codex 경유가 존재 이유). 근거: 글로벌 룰 수명 규율(신규 룰은 은퇴 조건 의무)의
스킬판 — 축적은 진보가 아니다.

## Anti-patterns

- **codex 불가인데 Claude 단독으로 조용히 재플래닝** — 교차모델이 존재 이유다. 정지하고
  `deep-plan` 으로 라우팅하라.
- **PATH 에 없자 절대경로·`find`·npx 로 우회 실행** — 프리플라이트를 무력화한다. PATH
  조회 실패는 그 자체로 종결 신호다(사용자가 경로를 명시로 준 경우만 예외).
- **goal-ready 이슈 재플래닝** — 이미 실측 증거·측정 가능 AC·범위 밖·단일 해석을 갖춘
  이슈를 다시 깎는 것은 중복 비용이다.
- **oversized 를 이 스킬로 강행** — 착수 계획 1장으로는 전면 개편을 담지 못한다.
- **체크리스트에 검증 항목 섞기** — 인터뷰가 결정이 아니라 확인 절차로 채워져 사람의 시간만
  태운다. 갈래만 묻는다.
- **미확정 갈래를 남긴 채 문서 산출 / 봉인을 문서에 안 적기** — 실행자가 추측하게 되고,
  봉인이 사용자의 선택으로 위장된다.
- **이슈 본문 수정·상태 전이** — 이 스킬은 코멘트 1건만 쓴다(승인 뒤).
- **승인 없이 코멘트 첨부** — 외부 write 는 게이트 뒤에만.
- **codex 무진행 방치** — 무진행 8분+/hard cap 12분이면 kill. 무한 대기는 자율 잡을 통째로 태운다.
- **codex 와 수렴 핑퐁** — 재호출은 구조를 바꾸는 큰 갈래에 한해 1회.
- **SSOT 절차 복제** — linear MCP 감지·종료 출력·goal-ready 판정은 경로로 참조한다.

## References

- `~/.claude/skills/craft-core/references/linear.md` — Linear MCP 감지·graceful 규약(Step 1).
- `~/.claude/skills/craft-core/references/output-contract.md` — 종료 출력 3레이어.
- `~/.claude/skills/linear-goal/references/routing.md` — §goal-ready(재플래닝 금지 신호) +
  §Step 1 rubric(oversized 판정). 경계 판단 시 읽는다.
- `~/.claude/rules-ondemand/delegated-review-watchdog.md` — codex 위임 호출 watchdog(Step 2).
