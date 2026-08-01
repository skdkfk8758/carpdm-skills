# linear-replan 스킬 저작 — 착수 직전 Linear 이슈를 codex 로 인터뷰형 재플래닝

> Linear: ADT-435. Goal Prompt: `2026-08-01-linear-replan-skill-prompt.md` (실행 계약 —
> 자율 에이전트 goal 칸에 통째로 들어간다). 본 PLAN 은 설계 근거(사람 검토용).
> deep-plan fable×2 debate 4비트 — 저자 갭 7 + 비평자 BLOCKING 5·갭 2, 전부 원장 닫힘.

## Goal (testable success criteria)

`skills/linear-replan/` 스킬이 저작되어: Linear 이슈 번호 → `codex exec` 재플래닝 →
결정 갈래 체크리스트를 AskUserQuestion 인터뷰로 전항목 확정 → 착수 계획 문서 1개
(`docs/plans/<issue-id>-kickoff.md`) → 승인 게이트 후 이슈 코멘트 첨부 — 를 지시하는
SKILL.md 가 CI 3종을 통과하고 필수 블록 9개를 전부 갖춘다. "done" 의 SSOT 는 아래
Acceptance — Goal Prompt 의 Success Criteria 는 그 `[AUTO]` 항목의 재서술이다.

## Scope (IN / OUT)

**IN**
- `skills/linear-replan/SKILL.md` 신규 저작 (+필요 시 `references/`)
- README.md 스킬 표 행 추가 + "N개 스킬" 카운트 갱신
- 워크플로 6단계 인코딩: codex 프리플라이트 → 이슈 fetch+grounding → codex exec
  (3분 watchdog) → 체크리스트 인터뷰(결정 갈래·전항목 확정·봉인 규칙) → kickoff
  문서 저장 → 승인 게이트 후 코멘트 첨부 + output-contract 종료

**OUT**
- 스킬의 실제 *실행* (사용 시점 일)
- linear-goal·deep-plan·craft-core 수정 — **linear-goal 진입 라우팅(spec-thin/
  oversized → replan) 갱신은 후속 이슈** (비평자 GAP 6 결정)
- Linear write 일체 (저작 잡 기준 — 런타임 동작 인코딩과 구분)
- codex 플러그인 복구, install.sh/sync.sh 변경, live `~/.claude/skills/` 편집

## Files (verified — path : why it changes)

| 경로 | 왜 |
|---|---|
| `skills/linear-replan/SKILL.md` | 신규 — 스킬 본체 (frontmatter `name: linear-replan` + `description:` 디스앰비규에이션 포함) |
| `README.md` | 스킬 표 행 + 카운트 (누락 시 `guard-readme-fresh` 가 PR 차단 — 실측 규약) |

읽기 전용 참조(실존 확인됨): `skills/linear-goal/SKILL.md` · `skills/linear-goal/references/routing.md`
(rubric·goal-ready 4기준 — 이 세션 실측) · `skills/deep-plan/SKILL.md` ·
`skills/craft-core/references/linear.md`(MCP graceful SSOT) · `references/output-contract.md`(종료 규격) ·
`scripts/ci/*.js` 3종.

## 핵심 설계 결정 (debate + 인터뷰 확정)

| # | 결정 | 근거 |
|---|---|---|
| D1 | codex 호출면 = plain `codex exec` (stdin 파이프), 플러그인 경로 참조 금지 | CLI 0.145.0 실측, 플러그인 2026-07-30 은퇴 |
| D2 | 체크리스트 = **결정 갈래만**, 전항목 확정, "나머지 알아서" 시 codex 초안값 **봉인**+문서 명시 | 갭 인터뷰 R1 — 검증 항목은 kickoff 문서의 AC 로 족함 |
| D3 | 답 반영 = Claude 직접, 구조 변경 갈래만 codex 재호출 **1회 한정** | 비용·지연 예측 가능성 우선, 모델 독립성은 초안에서 이미 확보 |
| D4 | 산출 소비 = 확정 플랜을 **이슈 코멘트 첨부** (승인 게이트 + disclaimer, 본문 무수정) | linear-goal 이 fetch 시 읽음, 본문 무수정 불변식과 양립 |
| D5 | codex 불가(미설치·미인증·hang) = 안내 한 줄(+deep-plan 라우팅) 후 **정지** — Claude 폴백 없음 | ADT-435 AC 그대로, codex 경유가 스킬 존재 이유 |
| D6 | `codex exec` 는 timeout/background+진행감시, **3분 무진행 kill** | delegated-review-watchdog 글로벌 룰 정합 (비평자 B4) |
| D7 | 진입 라우팅(linear-goal→replan) = 후속 이슈로 분리 | 기존 스킬 무수정 원칙, 단계적 배포 (비평자 GAP 6) |
| D8 | real-env probe = [HUMAN] 잔여 — 자율 잡은 live 설치 금지 유지 | PR #153 플로우와 동일 패턴 (비평자 GAP 7) |
| D9 | **입력 듀얼 모드** — 이슈 번호(이슈 모드) 또는 짧은 자유 요구사항 텍스트(텍스트 모드: fetch·코멘트 생략, L3=linear-register 등록 제안). 대형·고위험 텍스트는 deep-plan 라우팅 | 사용자 요청 (debate 종료 후 — 메인 직접 수정, 필수 블록 ⑩ 신설). 대가: 형제 오발화 표면 확대 → R2 완화(디스앰비규에이션·probe)가 더 중요해짐 |
| D10 | **은퇴/통합 조건을 SKILL.md 에 의무 명시** — 3개월 내 텍스트 모드 오발화 실측 또는 실사용 저빈도면 deep-plan 경량 모드 흡수 검토, codex CLI 가용성 소멸 시 스킬 폐지 (필수 블록 ⑪) | 글로벌 룰 수명 규율("신규 룰은 은퇴 조건 의무") 스킬판 — deep-plan 과의 통합 판정을 실측에 맡김 |

## Steps (each step → its verify check)

1. **경계 대상 Read** — `linear-goal/SKILL.md`+`routing.md`, `deep-plan/SKILL.md`,
   `craft-core/references/linear.md`·`output-contract.md`.
   → verify: 경계 절이 routing.md **포인터 + 기준명**(goal-ready 4기준·oversized-class)
   을 언급 — 실문구 verbatim 인용은 금지(SSOT 복제 금지 규율 — rubric 개정 시 stale
   복제본이 남는다. verdict SUGGESTION 2 반영).
2. **SKILL.md 저작** — frontmatter(name/description — linear-goal·deep-plan
   디스앰비규에이션 문자열 포함) + 워크플로 6단계 + 필수 블록 9개 + 불변식 리터럴
   `이슈 본문·상태를 수정하지 않는다`.
   → verify: Goal Prompt Verification 4~6 grep 셋 전부 매치.
3. **README 갱신** — 행 추가 + 카운트.
   → verify: `node scripts/ci/catalog.js` exit 0.
4. **CI 3종 + 경계 검증** — validate-skills / invisible-chars / catalog +
   `git diff --name-only $START_SHA..HEAD` 경로 확인.
   → verify: exit 0 ×3, diff 가 `skills/linear-replan/**`+`README.md` 외 0건.

## Risks

- **R1 (중)** — grep 기반 검증은 블록 *존재*를 보지 *품질*을 못 본다. 완화: [HUMAN]
  잔여 ①(ADT-435 AC3 — 실제 이슈 1건으로 산출 품질 확인)이 품질 게이트.
- **R2 (중→상향)** — 트리거 오발화: linear-goal/deep-plan/linear-register 형제와 표면
  인접(이 스킬군에서 실측된 문제). **D9 텍스트 모드가 deep-plan/deep-prompt 와 표면을
  추가로 겹치게 한다** — "이 요구사항 플래닝해줘" 류 발화의 귀속이 모호해짐. 완화:
  description 디스앰비규에이션 강제(SC — codex 경유·경량·착수 직전이라는 차별 축 명시)
  + [HUMAN] 잔여 ②(real-env probe 에 텍스트 모드 발화 케이스 추가).
- **R3 (저)** — codex 출력 형식 비결정론(체크리스트 파싱). 완화: SKILL.md 가 codex
  프롬프트에 출력 계약(번호 목록·갈래 형태)을 지시하도록 인코딩 — 구현 에이전트 재량.
- **R4 (저)** — 이슈 코멘트가 길어져 이슈 가독성 저하. 완화: kickoff 문서 전문이
  아니라 요약+경로+핵심 결정만 코멘트로(상세는 구현 재량, 승인 게이트에서 사람이 봄).

## Security surface

없음(마크다운 저작). 단 인코딩되는 **런타임** 동작에 외부 write 1종(이슈 코멘트) —
승인 게이트 + AI disclaimer 의무를 SKILL.md 에 박는다(D4). 저작 잡 자체는 Linear
write 0회 (Goal Prompt Constraints).

## YAGNI (deletions this change would make)

없음 — 순수 신규. (linear-goal 라우팅 갱신을 이번에 안 하므로 기존 경로 삭제도 없음.)

## Acceptance / Eval

1. `[AUTO]` CI 3종 exit 0 (validate-skills · invisible-chars · catalog).
2. `[AUTO]` 필수 블록 9개 grep 전부 매치 (Goal Prompt Verification 4 의 패턴·범위 1:1).
3. `[AUTO]` description 디스앰비규에이션 — `^description:` 줄에 linear-goal·deep-plan 각 ≥1.
4. `[AUTO]` 불변식 리터럴 `이슈 본문·상태를 수정하지 않는다` ≥1.
5. `[AUTO]` `git diff --name-only $START_SHA..HEAD` 가 허용 2경로 외 0건 + porcelain 0줄.
6. `[HUMAN]` ADT-435 AC3 — 산출 kickoff 플랜이 실제 착수에 충분한지 이슈 1건으로 확인
   (agent 불가 — 착수 충분성은 착수해 본 사람의 판단).
7. `[HUMAN]` real-env probe — `bash install.sh` 후 트리거 정확 발화 + 형제 스킬
   오발화 없음 (agent 불가 — 자율 잡은 live 설치 금지, D8).

## Plan review — fable×2 debate 4비트 (2026-08-01)

- **비트 구성**: ① fable 초안(갭 7) → ② fable 비평(BLOCKING 5 · SUGGESTION 0 ·
  추가 갭 2) → 갭 인터뷰 2라운드(7건 확정, [CODE] 2건은 메인이 실측으로 닫음) →
  ③ 저자 반영(원장 14행 전부 처리) → ④ 비평자 최종 verdict(아래).
- **BLOCKING 처리**: B1 START_SHA diff 검증 교체 · B2 grep 범위 분리(본문/frontmatter)
  · B3 인터뷰 종료 조건 블록 신설 · B4 watchdog 블록 신설 · B5 MCP graceful 블록
  신설 — 전부 FIXED, 원장은 debate 기록 참조.
- **동조 감시**: 비평 BLOCKING 5건 — 동조 아님(재요청 불요).
- **미해소 assumption**: 없음 — 갭 7건 전원 사용자 확정, 봉인 항목 0.
- **④ 최종 verdict**: B1~B5 **전부 CLOSED** + 신규 BLOCKING 1건(FIX-FIRST) +
  SUGGESTION 2건. 신규 BLOCKING = Verification 5 의 `^description:` 단일행 grep 이
  레포 관례(`description: >-` folded — 형제 9개 실측)와 충돌해 거짓 FAIL. **메인이
  직접 검증(CONFIRMED — linear-goal:3 실측) 후 수정**: frontmatter 블록 추출 grep 으로
  교체 + 단일행 전제 금지 명시. SUGGESTION 2건 채택 — Step 1 verify 를 포인터+기준명으로
  (verbatim 인용 금지), Verification 7 에 리터럴 SHA 치환 주의. Files 실존·Acceptance
  검증 가능성·Steps verify 증명력은 비평자 실측 확인. 수정 후 상태 = **SHIP**
  (debate 2왕복 소진 — 수정은 규칙대로 메인 직접, 추가 왕복 없음).

## Pipeline state
- phase: deep-plan Step 6 (산출 3파일) · debate 4비트 닫힘 (verdict: SHIP)
- updated: 2026-08-01
