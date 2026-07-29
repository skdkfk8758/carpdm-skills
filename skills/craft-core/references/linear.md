# Linear 통합 — MCP 감지 → 이슈 등록(plan) → 상태 전이(build)

`deep-plan`(plan→이슈 등록) 과 craft consumer(`forge`/`renew`/`hunt` — 빌드 중
상태 전이)가 공유하는 Linear 연동 SSOT. 직접 호출하지 않는다 — 해당 스킬이
필요할 때 lazy-load 한다. 이 한 장이 세 가지를 정의한다: (1) Linear MCP 감지 +
미설치 시 가이드/스킵, (2) PLAN → Linear 이슈 트리 등록, (3) 빌드 중 상태 자동 전이.

이 파일을 craft-core 에 두지만 **엔진(pipeline) 의존이 아니다** — output-contract
와 같은 공유 reference 한 장이다. 복제 금지: deep-plan 도 forge/renew/hunt 도
land 도 이 한 소스를 읽는다(drift 차단).

## 핵심 불변식 (먼저 읽을 것)

- **이슈 생성은 외부 write → 항상 확인 게이트.** 만들 트리를 미리보기로 보이고
  동의받은 뒤에만 생성한다. 추측으로 이슈를 쏟아내지 말 것.
- **상태 전이는 자동.** 라벨/상태 변경은 저위험이라 매번 묻지 않는다 — *생성*만
  확인하고, 전이(In Progress/In Review/Done)는 자동으로 흘린다.
- **Linear 없으면 graceful.** MCP 미설치이거나 활성 이슈가 없으면 막지 말고
  평소대로 진행한다 — plan 은 그대로 산출되고, 빌드는 평소 파이프라인으로 돈다.
  Linear 는 워크플로를 *증강* 하지 *게이트* 하지 않는다.

## 1. MCP 감지

Linear 를 건드리기 전에 연결을 확인한다:

- 컨텍스트의 available tools 에 Linear MCP 도구(`mcp__linear__*` 류)가 있는지 본다.
  도구가 **deferred** 목록에만 보이면 `ToolSearch` (`query: "linear"`) 로 스키마를
  로드한 뒤 사용한다.
- 불확실하면 `claude mcp list` 로 linear 항목 존재를 확인한다.

세 결과로 분기한다:

- **연결됨** → §2(등록) / §3(전이) 진행.
- **미설치** → §1a 가이드를 한 번 출력하고 스킵을 제안.
- **설치됐으나 미인증** → 세션에서 `/mcp` 로 OAuth 인증하라고 한 번 안내. 인증 전엔
  스킵 가능.

### 1a. 미설치 시 — 가이드 한 번 + 스킵 (막지 말 것)

Linear MCP 가 없으면 다음을 **한 번** 안내하고, 사용자가 설치/스킵을 택하게 한다:

```
Linear MCP 미설치. 설치하려면:
  claude mcp add --transport http linear-server https://mcp.linear.app/mcp
그다음 Claude Code 세션에서 /mcp 로 OAuth 인증.
```

(공식 원격 서버 — `mcp.linear.app/mcp`, HTTP transport, OAuth 2.1. 설치 명령·URL 은
검증된 값이니 임의로 바꾸지 말 것.)

사용자가 "스킵"/"나중에" 하면 Linear 단계 없이 진행한다. 설치를 택하면 인증 뒤
§2 로 돌아온다. **설치를 강요하지 말 것** — 가이드는 일회성이고, 거부는 정상 경로다.

## 2. PLAN → Linear 이슈 트리 (deep-plan 등록 단계)

PLAN 문서가 완성된 뒤(deep-plan), 이를 Linear 작업 트리로 등록할지 **제안**한다
(자동 등록 금지). 사용자가 동의할 때만 생성한다.

**팀/프로젝트 해석.** 어느 team(필요하면 project)에 넣을지 한 번 확인한다 — 이름을
추측하지 말고 실제 도구(`list_teams` 류)로 후보를 조회해 보이고 고르게 한다.
사용자가 이미 team/project 를 말했으면 재질문하지 않는다.

**트리 모양 — parent 1 + Step별 sub-issue:**

- **parent issue** — title = PLAN 의 topic. description = Goal(검증 가능 성공 기준)
  + Scope IN/OUT 요약 + PLAN 문서 경로(`docs/plans/…md`). UI plan 이면 승인된
  시안 `.html` 경로도 적는다.
- **sub-issue (PLAN Step 하나당 하나)** — parent 아래에 단다. title = 그 Step 요약.
  description = 그 Step 의 verify check + 연관 Acceptance(=eval) 항목을
  `[AUTO]`/`[HUMAN]` 태그째 적는다. Step↔Acceptance 매핑이 모호하면 추측하지 말고
  Step 의 verify 만 적고 Acceptance 칸은 비운다.

이 레포의 결정은 **Step 단위 sub-issue** 다(Acceptance 단위로 쪼개지 않는다 —
Acceptance 는 sub-issue body 에 참조로 들어간다). Step 이 곧 atomic 작업 단위라
빌드 스킬이 sub-issue 하나씩 집어 작업하기 자연스럽다.

**생성 전 확인 게이트.** 만들 트리(parent 제목 + sub 제목 목록)를 미리보기로 보이고
"이대로 N개 이슈를 생성할까요?" 동의를 받는다. 생성 후 parent/sub 의 URL 을
사용자에게 반환하고, **각 sub-issue 의 ID/URL 을 PLAN `.md` 본문에 적어** 둔다 —
이게 plan↔build 연결고리다(빌드 스킬이 §3 에서 이걸 집어 쓴다).

**작은 plan 예외.** Step 이 1개이거나 매우 작으면 parent 없이 단일 이슈로 만든다 —
트리 과투자 회피(deep-plan 의 flat 분기와 같은 정신).

## 3. 빌드 중 상태 자동 전이 (forge / renew / hunt)

빌드 스킬은 **활성 Linear 이슈가 있을 때만** 상태를 옮긴다. 없으면 Linear 를 무시하고
평소대로 빌드한다(graceful — Linear 부재가 빌드를 막지 않는다).

**활성 이슈 결정:**

- 사용자가 이슈 ID/URL 을 줬거나, PLAN `.md` 에 §2 가 적어둔 이슈가 있으면 그것.
- sub-issue 단위로 작업하면(권고), 지금 구현 중인 Step 에 대응하는 sub-issue 가
  활성. Phase 3 의 task split 이 PLAN Step 과 정렬되므로 sub-issue 와도 정렬된다.
- 활성 이슈가 없거나 모호하면 **묻지 말고** Linear 없이 진행한다(빌드는 완수).

**전이 맵 (자동):**

| 시점 | 전이 |
|---|---|
| 빌드 시작 (pipeline Phase 0 bind) | → In Progress |
| Phase 4 verify green + Acceptance 닫힘 | → In Review |
| 머지/완료 (`land` 머지 또는 사용자가 완료 커밋) | → Done |

정확한 상태 이름은 워크스페이스마다 다르다 — `list_issue_statuses`(또는 동등 도구)로
실제 상태를 조회해 가장 가까운 것에 매핑한다(진행 중 / 검토 / 완료 류). 하드코딩한
"In Progress" 문자열을 그대로 set 하지 말 것.

전이는 저위험이라 자동이지만, **전이 실패(권한·네트워크)가 빌드를 막아선 안 된다** —
경고만 남기고 빌드를 계속한다. 상태 한 칸이 안 옮겨진 것 때문에 구현이 멈추는 건
본말전도다.

### 3a. 전이 시 코멘트 — 상태칸이 못 담는 맥락만

상태 전이는 *어디까지 왔나*만 말한다. 다음 사람이 알아야 할 **블로커·미완·범위 밖**이
있으면 같은 전이에서 이슈에 코멘트를 남긴다 — 그래야 `In Review`/`Done` 이 미해결
사항을 조용히 덮지 않는다. 전이와 마찬가지로 저위험 write 라 **묻지 말고 자동**.

**언제 코멘트(전이마다가 아니라, 담을 게 있을 때만):**

| 전이 | 코멘트할 것 (있을 때만) |
|---|---|
| → In Progress | 보통 불요. 단 착수 시 발견한 범위 변경·차단요소가 있으면 1줄 |
| → In Review | 검증 방식(어떤 게이트 green), 의도적 범위 밖(YAGNI 로 뺀 것) |
| → Done | **머지 산출물 요약 + 코드 밖 남은 후속**(operator ops·프로비저닝·외부 등록), 알려진 한계 |

**무엇을 담나** — 다음 reader 가 코드를 안 봐도 서는 self-contained 한 줄들:
머지된 것(PR 링크), 검증 결과, **차단 중인 코드 밖 후속**(체크박스), 의도적 미구현(사유).
판단 기준: "이 칸으로 옮겨졌는데 reader 가 놀랄 미해결이 있나?" 없으면 코멘트 안 함.

**언제 코멘트 안 함(노이즈 금지):** 깔끔하게 완결돼 담을 미해결이 없는 전이, 상태칸이
이미 말하는 것의 반복("Done 으로 옮김"), 코드에서 자명한 내용. 빈 코멘트는 마찰만 는다.

코멘트도 전이처럼 **실패해도 빌드를 막지 않는다**(경고 후 계속). `land` 의 Done 전이가
이 정책의 1차 소비처다 — 머지 후 코드 밖 후속이 남으면 Done 후속 코멘트가 짝이다.

### 3b. 결과 보드 코멘트 — 구현 스킬 wrap 시 (In Review 행 대체)

코드를 바꾼 스킬(forge/hunt/renew · linear-goal)이 작업을 끝낼 때,
활성 이슈가 있으면 **결과 보드**(`output-contract.md` §R)의 markdown 을 그 이슈에
코멘트로 남긴다 — **In Review 전이(§3)와 같은 wrap 시점, 같은 활성 이슈**의 원자 쌍.
§3a 표의 "→ In Review" 행은 이 보드 코멘트가 **대체**한다(검증 방식·범위 밖·잔여를
보드가 이미 구조화해 담으므로 별도 산문 코멘트를 또 쓰지 않는다). In Progress·Done
전이는 §3a 그대로.

- **본문 = 보드 + 검증 체크리스트 그대로.** 턴 출력의 R 보드 + §V 검증 체크리스트
  markdown 을 재사용한다 — 코멘트용 재작성 금지(이중 SSOT 방지, output-contract R
  규칙 6·V 규칙 5). §V 의 `- [ ]` 체크박스는 Linear 코멘트에서 실제 체크 가능 —
  **사용자 직접 확인 몫의 추적 표면**이 이슈에 남는다. 헤더 1줄
  (`## 빌드 완료 보고 — <skill> · <브랜치> · <커밋 range>`) + 말미 AI disclaimer 1줄
  (`— AI 생성 보고 (Claude Code · <skill>). 머지는 별도 승인.`)만 덧붙인다.
- **전이와 동급 자동.** 저위험 write 라 매번 묻지 않는다(생성 게이트 §2 와 위험 등급
  구분). 실패해도 wrap 을 막지 않는다(경고만).
- **마스킹 의무** (acceptance-criteria-gate G3) — 토큰·PII·내부 URL·DB dump 는 코멘트
  전 마스킹. 검증 커맨드 행의 credential 인자도 대상 — 외부 서비스 캐시에 영속 노출된다.
- **실패도 남긴다.** needs input(linear-goal) 의 실패 보드도
  동일하게 코멘트 — 실패 기록이 다음 시도의 컨텍스트다.
- graceful 불변식은 §1a/§3 그대로 — MCP 없거나 활성 이슈 없으면 묻지 말고 스킵.

## Anti-patterns

- **이슈를 확인 없이 자동 생성** — 외부 write 는 항상 게이트(§2). 미리보기 → 동의 → 생성.
- **Linear 미설치인데 plan/빌드를 중단** — graceful skip 이 원칙(§1a, §3). 증강이지 게이트가 아니다.
- **도구 이름 추측 단언** (`mcp__linear__create_issue` 등을 확인 없이 호출) — 실제
  available tools 에서 확인하거나 `ToolSearch` 로 로드한다. 이름은 서버 버전·워크스페이스마다 다를 수 있다.
- **상태 이름 하드코딩** — `list_issue_statuses` 로 실제 조회 후 매핑.
- **sub-issue 를 Acceptance 단위로 쪼개기** — 이 레포 결정은 Step 단위. Acceptance 는 sub-issue body 에 참조로.
- **전이를 매번 확인** — 생성만 확인, 전이는 자동(§3). 단계마다 묻는 건 마찰.
- **상태 전이 실패로 빌드 중단** — 경고만, 빌드 계속.
- **Done 으로 옮기며 코드 밖 미완(operator ops·프로비저닝·외부 등록)을 코멘트 없이 숨김** — Done 은 미해결을 덮는다. 남은 후속이 있으면 §3a 코멘트가 짝(land 1차 소비처).
- **담을 게 없는데 전이마다 코멘트** — 상태칸 반복·빈 코멘트는 노이즈. reader 가 놀랄 미해결이 있을 때만(§3a).
