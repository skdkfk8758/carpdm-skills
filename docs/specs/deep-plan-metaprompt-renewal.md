# Requirements: deep-plan 리뉴얼 — codex 메타프롬프팅 + 갭 인터뷰 파이프라인

> Crystallized from a deep-interview on 2026-07-21. Final ambiguity: 17% (target ≤ 20%).
> Type: brownfield. Rounds: 5. Status: draft.

## Amendment 2 (2026-07-21) — fable×codex debate 전환

같은 날 후속 인터뷰(G1~G5, 5라운드)로 codex 단독 2패스를 **교차모델 debate** 로 개정:

- **G1** 저자 = 항상 fable 서브에이전트(`dp-author`, 메인 겸직 금지 — 독립성 우선, 비용 수용) / codex = 적대 비평자.
- **G2** 비평 반영 기준 = `[BLOCKING]`(소비자 계약 위반 — 의무 반영) / `[SUGGESTION]`(저자 재량 + 기각 사유 1줄). 무태그 = SUGGESTION 강등. 취향 진동 차단.
- **G3** 델타 판정 게이트 — BLOCKING 0 + 인터뷰 무변경이면 반영·verdict 스킵(4→2비트). 왕복 상한 고정 2회, 수렴 루프 금지, 미해소 BLOCKING 은 assumption 승격.
- **G4** codex 불가 폴백 = 두 번째 fable 비평자 승계(구 "Claude 단독" 폐기). 강등 명시 보고.
- **G5** codex effort = medium 기본 + 보안·계약·마이그 시 high (현행 계승).
- 갭 인터뷰 의제 = 양측 갭 **union·dedup** (상한 7 유지). Step 재번호 0~8.
- REQ-F-002/004(구 R1/R2 계약)는 본 개정으로 대체됨 — Step 1(fable 초안)/Step 2(codex 비평)/Step 4(반영+verdict)가 승계.

## 1. Goal & scope

deep-plan 을 "요청문을 그대로 받아 PLAN 을 쓰는 스킬"에서 "요청문을 **codex 로 두 번
깎아** 자율 에이전트가 먹을 수 있는 Goal Prompt 로 만들고, 그 과정에서 codex 가 지목한
컨텍스트 갭을 사용자 인터뷰로 채운 뒤, 프롬프트 + PLAN + 통합 뷰를 산출하는 스킬"로
바꾼다. 근본 필요: 사람이 던진 한 문단짜리 요청은 자율 실행 계약으로는 약하다 —
두 번째 모델(codex)이 그 약함을 *구체적 갭 목록*으로 드러내야 인터뷰가 겨눌 곳이 생긴다.

**In scope:** deep-plan `SKILL.md` 개정 — 메타프롬프팅 단계 신설(A/B), 갭 인터뷰로의
인터뷰 기계 단일화(C), 3파일 산출물 계약(D), Linear 첨부 확장(F).

**Out of scope:**
- 새 스킬 분리 / `deep-prompt` 로의 이관 — R0 에서 in-place 리뉴얼로 확정.
- codex **적대적 플랜 리뷰**(craft Phase 2) 도입 — deep-plan 은 여전히 빌드 파이프라인이 아니다.
- `deep-prompt` 자체 수정 — 템플릿은 참조만, 그 스킬은 손대지 않는다.
- craft-core `codex-review.md` 수정 — 호출 규약을 *읽어 쓰되* 그 파일은 forge/renew/hunt 소유.

### 전제 정정 (인터뷰 중 실측)

요청 (1) "codex 비판적 플랜리뷰 제거" 는 **이미 참이었다.** `grep -rn codex ~/.claude/skills/deep-plan/`
= 1건, `SKILL.md:10` 의 *배제 선언*("codex 리뷰도 … 없다")뿐. 제거할 로직은 존재하지 않았고,
오히려 본 리뉴얼이 codex 를 다른 용도(메타프롬프팅)로 재도입하므로 그 문장은 **삭제가 아니라
개정** 대상이 된다 → REQ-F-009.

## 2. Topology

Round 0 에서 고정:

| Component | Status | One-line role |
|-----------|--------|---------------|
| A 입력 계약 | active | 무엇이 메타프롬프팅 입력인가 — 사용자 요청문 원문 |
| B codex 엔진 | active | R1 fresh + R2 `--resume-last` 2회 고정 패스, read-only |
| C 갭 인터뷰 | active | codex 갭 목록을 라운드당 1질문으로 소진 (유일한 인터뷰 기계) |
| D 산출물 | active | `-prompt.md` + `.md`(PLAN) + `.html`(통합 뷰) |
| E 스킬 경계 | active | deep-plan in-place 리뉴얼 (새 스킬·이관 아님) |
| F 후반부 | active | Step 4.5 Linear + Step 5 라우팅 유지, Linear 에 산출물 첨부 추가 |

## 3. Functional requirements

| ID | Requirement (the system SHALL…) | Priority | Acceptance criteria | Origin |
|----|----------------------------------|----------|---------------------|--------|
| REQ-F-001 | 스킬 진입 시 **사용자 요청문 원문**을 메타프롬프팅 입력으로 캡처한다. 별도 프롬프트 초안을 요구하지 않는다 | Must | SKILL.md 에 "입력 = 사용자 요청문 원문" 이 명시되고, 초안 붙여넣기를 요구하는 문장이 0건 | R1 |
| REQ-F-002 | codex **R1(fresh)** 을 호출해 ① Goal Prompt 초안 ② **부족 컨텍스트 갭 목록**(번호 매김) 두 산출을 받는다 | Must | R1 프롬프트 형태가 SKILL.md 에 명시되고, 두 산출을 모두 요구하는 문구 존재. 갭 목록이 없으면 실패 처리 | R3 |
| REQ-F-003 | R1 갭 목록을 **라운드당 한 질문**으로 소진할 때까지 사용자를 인터뷰한다. 결정형은 `AskUserQuestion`, 생성형은 산문 | Must | SKILL.md 인터뷰 단계가 "묶어 묻지 않는다" 를 명시하고, 종료 조건이 "갭 목록 소진" 단일 기준 | R2 |
| REQ-F-004 | codex **R2(`--resume-last`)** 를 호출해 인터뷰 답을 반영한 **최종 프롬프트**를 받고, codex 가 자기 R1 갭이 닫혔는지 검증하게 한다 | Must | SKILL.md 에 `--resume-last` 호출과 "자기 갭 해소 검증" 지시가 명시. 총 codex 패스 = 정확히 2회(수렴 핑퐁 아님) | R3 |
| REQ-F-005 | 최종 프롬프트를 `docs/plans/YYYY-MM-DD-<topic>-prompt.md` 에 **잡음 0 순수 프롬프트**로 쓴다 — 그 파일을 통째로 자율 에이전트 goal 칸에 먹일 수 있어야 한다 | Must | 파일에 메타 해설·라운드 기록·경로 안내가 없고 프롬프트 본문만 존재 | R5 |
| REQ-F-006 | PLAN 을 `docs/plans/YYYY-MM-DD-<topic>.md` 에 **현행 8섹션 유지**로 쓴다 (Goal/Scope/Files/Steps/Risks/Security surface/YAGNI/Acceptance) | Must | 현행 SKILL.md Step 2 섹션 목록이 그대로 남아 있고 Acceptance 의 `[AUTO]`/`[HUMAN]` 태그 규칙도 유지 | R0 |
| REQ-F-007 | `docs/plans/YYYY-MM-DD-<topic>.html` 를 **통합 뷰**로 쓴다: 최종 프롬프트(복사 가능) + PLAN 렌더 + Acceptance 체크리스트 패널 + (UI plan 이면) 결과 화면 목업. self-contained, 외부 asset 0 | Must | UI 판정과 무관하게 `.html` 이 항상 1개 생성되고, 프롬프트 블록을 포함. UI plan 이면 목업 섹션 추가 존재 | R5 |
| REQ-F-008 | 현행 **Step 1 적응형 보강 게이트(ambiguity ≤ 0.20 Socratic 루프)** 를 통째로 삭제한다 | Must | SKILL.md 에서 `ambiguity`·`--quick`·`--deep`·차원 점수표 언급 0건. lazy-load 표에서 `cc/socratic.md`·`di/scoring.md`·`di/socratic-playbook.md` 3행 제거 | R2 |
| REQ-F-009 | `SKILL.md:10` 의 "codex 리뷰도 … 없다" 문구를 개정해, **codex 메타프롬프팅은 하되 codex 적대적 플랜 리뷰는 안 한다**로 구분한다 | Must | 개정 후 문장이 두 용도를 구분해 서술. "codex 없음" 단정 0건 | R0 |
| REQ-F-010 | Step 4.5 Linear 등록 시 **3산출물을 이슈에 첨부**한다 — `.md` 2개는 파일 업로드(`prepare_attachment_upload`→`create_attachment_from_upload`), `.html` 은 Artifact URL 링크 첨부(`create_attachment`) | Must | SKILL.md Step 4.5 에 첨부 절차가 명시되고, 첨부 실패가 등록 자체를 롤백하지 않음(경고 후 진행) | R0 |
| REQ-F-011 | Step 5 다음 스킬 라우팅을 **현행 유지**한다 — `next-skill-routing.md` 참조, `AskUserQuestion` 제안만, 자동 시작 금지 | Must | 현행 Step 5 본문이 실질 변경 없이 유지 | R0 |
| REQ-F-012 | codex companion 미설치·호출 실패 시 **Claude 자체 메타프롬프팅으로 강등**하고 그 사실을 사용자에게 명시 보고한다 — 스킬을 중단하지 않는다 | Should | 폴백 경로가 SKILL.md 에 존재하고 "codex 미사용, Claude 단독 산출" 고지 문구를 요구 | 관례(R3 파생) |
| REQ-F-013 | 기존 **ERD companion 분기**(스키마/BE 데이터 모델 수반 시 `-erd.html`)를 유지한다 | Should | 현행 ERD 분기 문단이 남아 있고 산출 경로 규칙 불변 | R0 |
| REQ-F-014 | **질문 불가 컨텍스트**(`harness-run` ②·백그라운드 잡·`$CLAUDE_JOB_DIR`)에서는 갭 인터뷰를 돌리지 않고 `[HUMAN]` 갭 전부를 assumption 으로 승격한 뒤 진행한다 | Must | SKILL.md Step 2 에 해당 분기가 존재하고, 승격 사실을 보고에 남기라는 지시 포함. harness-run 의 "사람 프롬프트 0" 계약 불변 | Phase 4 (plan defect) |

## 4. Non-functional requirements

| ID | Category | Requirement | Acceptance criteria | Origin |
|----|----------|-------------|---------------------|--------|
| REQ-N-001 | Reliability | codex 호출은 background + 진행 감시. 마지막 진행 후 3분 무소식이면 kill, hard cap 20분. kill 시 stderr 부분 결과 회수 후 REQ-F-012 폴백 | Must | SKILL.md 가 `~/.claude/rules/delegated-review-watchdog.md` 를 참조하고 cap 값을 명시 | 관례 |
| REQ-N-002 | Security | codex 는 read-only — `--write` 미사용 + 프롬프트에 "Do not edit, create, or delete any files" 명시 | Must | 두 조건이 SKILL.md 호출 규약에 문자로 존재 | 관례 |
| REQ-N-003 | Maintainability | 메커니즘 복제 금지 — codex 호출 규약은 `cc/codex-review.md`, 프롬프트 템플릿은 `deep-prompt/SKILL.md` 를 **lazy-load 참조**한다. 본문 인라인 복제 0 | Must | SSOT 표에 두 행이 추가되고, SKILL.md 본문에 템플릿 7섹션 정의를 복제한 문단 0건 | R4 |
| REQ-N-004 | Security | Linear 첨부 전 산출물에 credential·PII·내부 URL 노출 검사. 발견 시 첨부 보류 + 사유 보고 | Must | Step 4.5 에 마스킹 게이트 문장 존재 (`acceptance-criteria-gate.md` G3 동형) | 관례 |
| REQ-N-005 | Compatibility | 기존 deep-plan 산출 경로 컨벤션(`docs/plans/YYYY-MM-DD-<topic>.*`)과 Artifact publish 규칙(`html-mockup-artifact.md`)을 깨지 않는다 | Must | `.md`/`.html` basename 규칙 불변, `.html` 은 여전히 Artifact publish 대상 | R5 |

## 5. Constraints & assumptions

- **Constraints:**
  - 그릇은 **deep-plan in-place**. 새 스킬 생성·`deep-prompt` 이관 금지 (R0).
  - codex 패스는 **정확히 2회**. 수렴 핑퐁(codex-review 방식)은 채택하지 않는다 — 비용/시간 (R3).
  - 인터뷰 기계는 **1개**. 갭 인터뷰 외 다른 인터뷰 루프를 두지 않는다 (R2).
  - deep-plan 은 여전히 **코드를 쓰지 않는다** — craft Phase 2~5 진입 금지 (불변).
- **Assumptions resolved:**
  - "codex 플랜리뷰 제거" → 제거할 로직 부재, 문구 개정으로 축소 (§1 전제 정정).
  - "프롬프트 입력" → 사용자 요청문 원문 (R1, 붙여넣기 초안 아님).
  - "1차 메타프롬프팅" 의 2차 존재 전제 → 참, codex R2 가 담당 (R3).
  - "AI 에게 주기 좋은" 의 AI → Claude Code 빌드 스킬/자율 에이전트 → rubric = deep-prompt 7섹션 템플릿 (R4).
- **Residual ambiguity:**
  - **REQ-F-010 첨부 방식**은 인터뷰가 아니라 MCP 도구 실측(`prepare_attachment_upload` 존재)으로 정한 기본값이다. 파일 업로드가 Linear plan/권한에서 막히면 3개 모두 Artifact URL 링크로 강등 — 그때 재확인 필요.
  - **REQ-F-012 폴백**도 관례 파생. codex 부재가 잦으면 "폴백 대신 중단" 이 나을 수 있음(품질 위장 방지) — 실사용 후 재검토.
  - **비UI plan 의 `.html`**: 현행 정책은 "비UI 면 companion 생략" 인데 REQ-F-007 은 프롬프트 뷰 때문에 항상 생성으로 바꾼다. 비UI plan 에서 이 파일이 실제로 읽히는지는 미검증 — 안 읽히면 조건부로 되돌릴 것.

## 6. Context (brownfield)

인터뷰 중 실제로 읽은 것:

- `~/.claude/skills/deep-plan/SKILL.md` (201줄) — 개정 대상 본체. 영향 지점:
  - `:10` codex 배제 선언 → REQ-F-009
  - `:31-40` SSOT lazy-load 표 → REQ-F-008(3행 삭제) + REQ-N-003(2행 추가)
  - `:61-80` Step 1 적응형 보강 게이트 → REQ-F-008 로 전면 삭제
  - `:82-106` Step 2 PLAN 8섹션 → REQ-F-006 으로 보존
  - `:108-144` Step 3 시안/ERD 분기 → REQ-F-007(항상 생성으로 변경) + REQ-F-013(ERD 보존)
  - `:146-160` Step 4 output-contract 보고 → 3산출물로 확장
  - `:162-170` Step 4.5 Linear → REQ-F-010 첨부 추가
  - `:172-187` Step 5 라우팅 → REQ-F-011 무변경
- `~/.claude/skills/craft-core/references/codex-review.md` — codex companion 직접 호출 규약 SSOT
  (plugin root 해소 `ls -d ~/.claude/plugins/cache/openai-codex/codex/*/ | sort -V | tail -1`,
  `codex-companion.mjs task` / `task --resume-last`, stdout=결과 / stderr=진행, read-only 규칙,
  XML-태그 operator 프롬프트 형태). REQ-N-002/REQ-F-002/004 가 여기 의존.
- `~/.claude/skills/deep-prompt/SKILL.md` — 7섹션 Goal Prompt 템플릿 + UI 면 §3.5 HTML 시안.
  REQ-N-003 의 참조 대상. **주의**: 이 스킬과 리뉴얼된 deep-plan 의 표면이 상당히 겹친다 —
  경계 문구를 양쪽 description 에 유지하지 않으면 트리거 충돌.
- `~/.claude/skills/deep-interview/references/{scoring,socratic-playbook}.md` — REQ-F-008 로
  deep-plan 에서의 참조가 끊긴다(deep-interview 자신은 계속 사용, 파일 삭제 아님).
- Linear MCP 도구 인벤토리 — `prepare_attachment_upload` / `create_attachment_from_upload` /
  `create_attachment` 존재 확인 → REQ-F-010 가능.

**Blast radius:** deep-plan `SKILL.md` + `evals/evals.json` + `carpdm-skills/skills/deep-plan/` 미러.

> **정정 (Phase 4 실측).** 이 절은 최초 작성 시 *"다른 스킬은 deep-plan 을 호출하지 않고
> Step 5 에서 추천만 하므로 하류 파손 없음"* 이라고 단언했으나 **틀렸다.**
> `harness-run/SKILL.md:36,59` 가 게이트 ② 에서 deep-plan 을 **자동(사람 프롬프트 0)** 으로
> 호출한다 — 새 갭 인터뷰가 그 자율 구간을 hang 시킬 수 있었다. REQ-F-014 가 이 결함을
> 막는다. 확신 표기 없이 단언한 것이 원인 — 동종 판단은 실측 후 진술할 것.

`evals/evals.json` 3건은 제거된 동작(ambiguity threshold·비UI companion 생략)을 단언하고
있었으므로 같은 변경에서 갱신됐다(YAGNI — 호출처 사라진 테스트는 그 자리에서 정리).

## 7. Traceability — clarity trail

| Round | Ambiguity | Targeted dimension | Requirements pinned |
|-------|-----------|--------------------|---------------------|
| 0 | 62% | topology lock + 전제 정정 | E/D/F 확정 → REQ-F-006, F-009, F-010, F-011, F-013 |
| 1 | 49% | goal (A 입력계약) | REQ-F-001 |
| 2 | 37% | criteria (C 인터뷰 게이트) | REQ-F-003, REQ-F-008 |
| 3 | 30% | constraints (B codex 엔진) | REQ-F-002, REQ-F-004, REQ-F-012, REQ-N-001 |
| 4 | 22% | criteria (프롬프트 rubric) — contrarian 발동 | REQ-N-003 |
| 5 | 17% | constraints (D 파일 구조) | REQ-F-005, REQ-F-007, REQ-N-005 |

## 8. Handoff

Recommended next skill: **`/renew`** — 기존 스킬(deep-plan)의 동작을 의도적으로 개편하고,
기존 호출 계약(산출 경로·Artifact publish·Step 5 라우팅)을 깨지 않는 것이 핵심이므로.

**Treat this spec as the completed requirements step.** renew 는 기본적으로 자체 Socratic
인터뷰를 돌린다 — **건너뛸 것.** 위 번호 매긴 요구사항을 못 박힌 Phase-1 산출로 먹이고 곧장
plan review 로 진행해, 같은 작업을 처음부터 다시 인터뷰하지 않는다.

배포 경로 주의: 편집 대상은 라이브 `~/.claude/skills/deep-plan/SKILL.md` 이고,
repo 미러는 `~/Workspace/carpdm-skills/skills/deep-plan/`. 반영 후 `ship` 스킬로 동기화.
