# Requirements: linear-register 이슈 본문 간결화 + 추천 섹션 kickoff 프롬프트화

> Crystallized from a deep-interview on 2026-07-31. Final ambiguity: 12% (target ≤ 20%).
> Type: brownfield. Rounds: 9. Status: draft.
> 대상 스킬의 기존 요구사항 기록: `skills/linear-register/SPEC.md` (REQ-F-001~015 / REQ-N-001~004).
> 본 spec 의 ID 는 그 뒤를 이어 붙인다(REQ-F-016+ / REQ-N-005+) — 기존 ID 재번호 금지.

## 1. Goal & scope

linear-register 가 등록하는 Linear 이슈 본문을 **사람이 열어서 바로 이해하는 짧은 문서**로
바꾼다. 근본 필요: 이슈는 기계 입력이 아니라 **사람 독자용 문서**이고, 착수 직전의 상세
플래닝은 별도 스킬(아래 E)이 다시 수행할 예정이므로, 이슈 본문이 설계 문서 분량을 떠안을
이유가 없다. 함께 `## 추천` 을 "스킬 이름 나열"에서 **그대로 붙여넣어 착수하는 kickoff
프롬프트**로 바꾸고, 규칙이 실제로 지켜지도록 생성·승인·검증 3지점에 강제를 건다.

**In scope:** A 모델 스위치 · B 본문 간결화(헤딩 화이트리스트 + 분량 상한 + 문체) ·
C `## 추천` 개편 · D 파급 정리(SPEC·검증 절·linear-groom 공유 SSOT).
**Out of scope:** E(codex 이슈 기반 플래닝 스킬) 자체의 설계 — 본 spec 은 **경계 한 줄만**
기술한다. `linear-goal` 내부 동작 변경. 이미 등록된 이슈의 소급 정리(linear-groom 소관).
분할 모드(plan-split.md)의 슬라이스 분해 로직.

## 2. Topology

Round 0 에서 고정, R4 에서 E 추가:

| Component | Status | One-line role |
|-----------|--------|---------------|
| A 모델 스위치 | active | `model: fable` → `sonnet` (linear-register + linear-groom) |
| B 본문 간결화 | active | 헤딩 4개 고정 + 분량 상한 숫자 + 쉬운 문체 |
| C 추천 개편 | active | `## 추천` = 권장 스킬 1줄 + 붙여넣기용 kickoff 프롬프트 |
| D 파급 정리 | active | SKILL.md 검증 절 · SPEC.md 갱신 · 공유 SSOT 반영 |
| E codex 플래닝 스킬 | **deferred** | 착수 직전 이슈 → codex 재플래닝. 본 spec 은 경계만 명시, 설계는 별도 세션 |

## 3. Functional requirements

| ID | Requirement (the system SHALL…) | Priority | Acceptance criteria | Origin |
|----|----------------------------------|----------|---------------------|--------|
| REQ-F-016 | 이슈 본문 헤딩을 화이트리스트로 고정 — `## 작업 내용` · `## 수용 기준` · `## 추천` + disclaimer 1줄이 **항상**, `## 다음 작업` 은 체인일 때만. `## 배경` · `## 범위 밖` · `> 출처:` 는 **폐지**하고, 화이트리스트 밖 헤딩 신설을 금지 | Must | 등록된 이슈 본문의 `^## ` 헤딩 집합 ⊆ {작업 내용, 수용 기준, 추천, 다음 작업}; 그 외 헤딩 0개; `## 배경`/`## 범위 밖`/`> 출처:` 출현 0회 | R2 |
| REQ-F-017 | 본문에 **숫자 분량 상한**을 적용 — `## 작업 내용` ≤ 3줄 · `## 수용 기준` ≤ 5항목 · 본문 전체(코드블록·disclaimer 제외) ≤ 600자 | Must | 등록 이슈에서 작업 내용 줄수 ≤3, 수용 기준 항목수 ≤5, 코드블록 제외 본문 문자수 ≤600. 초과 시 등록 전 축약 | R9 |
| REQ-F-018 | 본문 문장을 **비전문 독자 기준**으로 작성 — 파일경로·라인번호·심볼명·약어를 본문에서 배제하고, 도메인 용어가 불가피하면 괄호로 쉬운 말 병기 | Must | 본문에 `path/to/file.ts:123` 형태의 경로·라인 참조 0개; 한 문장이 두 개 이하 절로 구성; 처음 등장하는 도메인 약어에 괄호 설명 존재 | R1,R4 |
| REQ-F-019 | `## 추천` 을 **권장 스킬 1줄 + 시작 프롬프트 코드블록 1개**로 재정의 — `대안:` 줄과 `해당 repo 의 .claude/skills 도 확인` boilerplate 줄을 삭제하고, kickoff 프롬프트를 **체인 이슈뿐 아니라 모든 이슈**에 부착 | Must | 등록 이슈마다 `## 추천` 내 권장 스킬 1줄 + 붙여넣기 가능한 코드블록 1개 존재; `대안:` 0회; boilerplate 문구 0회 | R7 |
| REQ-F-020 | Step 3 확인 게이트에서 **생성될 본문 전문**을 승인 전에 제시 — 현행 "제목 + 유사·배치 표시"에 본문 미리보기를 추가 | Must | 게이트 출력에 각 이슈의 본문 전문 포함; 사용자가 승인 전 분량·문체를 눈으로 판정 가능 | R9 |
| REQ-F-021 | SKILL.md `## 검증` 절에 **세는 항목**을 추가 — 화이트리스트 밖 헤딩 0개 · 분량 상한 준수 · disclaimer 존재 · 추천 코드블록 1개 | Must | 검증 절에 위 4항목이 카운트 가능한 형태로 기재; 종료 보고에서 각 항목 판정 | R9 |
| REQ-F-022 | 이슈 본문이 **사람용 요약**임을 전제로, 자율 실행(`linear-goal`) 착수 전 상세 플래닝이 별도 단계임을 SKILL.md 경계 절에 1줄 명시 | Should | SKILL.md `## 경계` 에 "이슈 본문은 사람용 요약 — 착수 직전 상세 플래닝은 별도(E)" 취지 1줄 존재 | R4 |
| REQ-F-023 | `## 수용 기준` 의 `[AUTO]`/`[HUMAN]` 마커는 **유지** — 간결화 대상에서 제외 | Must | 축약 후에도 각 수용 기준 항목에 마커 존재(`acceptance-criteria-gate` 파싱 보존) | R2 |

## 4. Non-functional requirements

| ID | Category | Requirement | Acceptance criteria | Origin |
|----|----------|-------------|---------------------|--------|
| REQ-N-005 | Configuration | `linear-register` · `linear-groom` 양쪽 frontmatter `model:` 을 `sonnet` 으로 전환 | 두 SKILL.md 의 `model:` 값이 `sonnet`; 그 외 frontmatter 키 무변경 | R8 |
| REQ-N-006 | Compatibility | `references/recommend-section.md` 는 register·groom 공유 SSOT — C 변경은 그 파일 한 곳에서만 하고 복제하지 않는다 | recommend-section.md 개정 1곳; SKILL.md 들은 포인터만 보유; groom 산출물도 동일 포맷 | R6 |
| REQ-N-007 | Compatibility | 이미 등록된 이슈를 소급 수정하지 않는다 | 본 변경 배포 후 기존 이슈 본문 `updatedAt` 변화 0건 | R6 |
| REQ-N-008 | Traceability | 헤딩·분량 규칙 변경을 `skills/linear-register/SPEC.md` 개정 이력에 반영하고, 폐지된 REQ(배경·범위 밖·출처 관련)를 재번호 없이 *개정* 표기 | SPEC.md 에 2026-07-31 개정 항목 + 영향 REQ 명시; 기존 ID 재번호 0건 | R9 |

## 5. Constraints & assumptions

- **Constraints:**
  - 스킬은 마크다운 산출물 — 빌드·런타임 없음. 강제는 규칙 문서 + 게이트 + 자가 검증뿐이고,
    **Linear 본문을 검사하는 자동 훅은 존재하지 않는다**(`scripts/ci/` 3종은 스킬 파일만 검증).
  - `references/recommend-section.md` 는 `linear-groom` 과 공유 — 단독 개정 불가(REQ-N-006).
  - `## 작업 내용`/`## 수용 기준` 은 `linear-goal` 이 Goal Prompt 로 매핑하는 소스라 헤딩명 변경 금지.

- **Assumptions resolved:**
  - "초등학생도 이해"의 대상 = 문체 + 섹션 수 **둘 다** (R1 확정).
  - 이슈 본문은 **사람 독자용**이고 기계용 상세는 다운스트림 플래닝이 담당 (R4 확정).
  - E 는 이번 범위 밖 — 경계만 명시 (R4 확정).
  - "sonnet 이면 글이 간결해진다"는 전제는 **기각** — 간결함은 템플릿 규칙(REQ-F-016~018)에서
    나온다. sonnet 전환은 비용·속도 목적으로 별개 채택 (R8).

- **Residual ambiguity:**
  1. **`> 출처:` 폐지로 genesis 역추적 상실** — 영향 REQ-F-016. spike·리포트·plan·메모리에서
     파생된 이슈가 "왜 생겼는지"를 잃는다. 완화 후보(미결정): Linear 네이티브 attachment 로
     이전, 또는 E 플래닝 스킬이 착수 시 재수집. **위험: 중간.**
  2. **파일경로 0개 규칙(REQ-F-018)이 버그 이슈의 유용한 단서를 지운다** — SSO-67 류는 경로가
     실제로 도움이 됐다. 상세가 E 로 이전된다는 전제가 깨지면 이 규칙이 손실로 바뀐다.
     **위험: 중간 — E 설계 시 재검토 대상.**
  3. **sonnet 다운그레이드가 dedup·추천 판정 품질에 미치는 영향 미측정** — 영향 REQ-N-005.
     `recommend-section.md` §A 와 `dedup-grouping.md` 유사도 판정은 모두 모델 판단이다.
     오판정 비용(중복 이슈·틀린 추천)은 사람이 치른다. **위험: 중간 — 전환 후 관찰 필요.**
  4. **codex 형상 불일치** — `codex` CLI 0.145.0 과 codex 스킬은 이 세션에 로드돼 있으나
     `~/.claude/plugins/installed_plugins.json` · `settings.json` `enabledPlugins` 에 항목이
     없다(레포 `rules/project.md` §2 는 "2026-07-30 codex 플러그인 은퇴"로 기록). **E 설계
     착수 전 선결 확인 항목.** 본 spec 의 A~D 는 codex 에 의존하지 않으므로 영향 없음.

## 6. Context *(brownfield)*

인터뷰 중 실제로 읽은 것:

- `skills/linear-register/SKILL.md:3` — `model: fable` (REQ-N-005 대상).
- `skills/linear-register/SKILL.md:76-110` — 현행 본문 템플릿 7블록 + 조건부 규칙
  (REQ-F-016/017/018 대상).
- `skills/linear-register/SKILL.md:59-63` — Step 3 확인 게이트. 포맷이
  `<팀>/<프로젝트>/state/N건 — [제목 + 유사·배치 표시]` 로 **본문 미포함**(REQ-F-020 근거).
- `skills/linear-register/SKILL.md:114` — 현행 `## 검증` 절. 세는 항목 6종이나 분량·헤딩
  항목 없음(REQ-F-021 대상).
- `skills/linear-register/references/recommend-section.md:25-32` — `## 추천` 포맷 3줄
  (권장/대안/로컬 boilerplate). §B 는 kickoff 프롬프트를 **체인 이슈에만** 부여(REQ-F-019 대상).
- `skills/linear-groom/SKILL.md:3` — `model: fable` (REQ-N-005 동반 대상).
- `skills/linear-register/SPEC.md` — 기존 REQ-F-001~015 / REQ-N-001~004 (REQ-N-008 대상).

등록 실물 대조 (문제 확증):

- **SSO-67** — 템플릿 준수·짧음. 그럼에도 `## 추천` 3줄 중 `그 repo 로컬 스킬/에이전트
  (.claude/skills)도 확인.` 은 repo명 미치환 상태로 **정보량 0**. 단건이라 kickoff 프롬프트
  없음 → REQ-F-019 근거.
- **AUT-73** — 템플릿 **이탈**. 비표준 헤딩 2개(`## 현황 (실측)` · `## 원본 (작성자 입력)`)
  신설, `## 배경` 3문단, FK 5개를 파일:라인으로 나열(SKILL.md 는 "파일경로 지양"이라 적혀
  있으나 강제 없음), disclaimer 누락(REQ-F-011 위반), 본문 약 2,300자 → REQ-F-016/017/018/
  020/021 전부의 근거.

Blast radius: `linear-groom`(공유 SSOT + 모델), `linear-goal`(본문을 Goal Prompt 로 읽음 —
본문이 얇아지면 자율 실행 입력이 얇아진다 → REQ-F-022 로 경계 명시만, 동작 변경은 범위 밖).

## 7. Traceability — clarity trail

| Round | Ambiguity | Targeted dimension | Requirements pinned |
|-------|-----------|--------------------|---------------------|
| 0 | — | topology lock | A/B/C/D active |
| 1 | 63% | goal (B) | REQ-F-018 (문체+섹션 둘 다) |
| 2 | 52% | constraints (B) | REQ-F-016, REQ-F-023 |
| 3 | 39% | criteria (B) | — (출처 폐지 파급 flag) |
| 4 | 37% | constraints — **contrarian** | E deferred, REQ-F-022 |
| 5 | 33% | goal (C) | — (C 문제 규명 착수) |
| 6 | 30% | criteria (C) — **simplifier** | REQ-N-006 (SSOT 공유 확인) |
| 7 | 24% | criteria (C) | REQ-F-019 |
| 8 | 20% | goal (A) | REQ-N-005 |
| 9 | 12% | criteria (강제) | REQ-F-017, REQ-F-020, REQ-F-021, REQ-N-008 |

## 8. Handoff

Recommended next skill: **`/renew`** — 기존 스킬(linear-register + linear-groom)의 동작을
의도적으로 바꾸는 brownfield 개편이고, 하위 호환(REQ-N-006/007: 공유 SSOT 단일 개정, 기존
이슈 소급 무수정)이 핵심 제약이다. 강도는 **linear**(단일 세션) — 변경 대상이 마크다운 4개
파일이고 설계 리스크가 낮아 council 은 과투자.

**Treat this spec as the completed requirements step.** `/renew` 는 기본적으로 자체 Socratic
인터뷰를 돌린다 — **건너뛰라.** 위 번호 매긴 요구사항을 못 박힌 Phase-1 산출물로 넣고 곧장
plan review 게이트로 진행해, 같은 내용을 다시 인터뷰하지 말 것.

변경 예상 파일 (≤5):
1. `skills/linear-register/SKILL.md` — frontmatter model, 템플릿, 게이트, 검증, 경계
2. `skills/linear-register/references/recommend-section.md` — §A/§B 개편 (공유 SSOT)
3. `skills/linear-groom/SKILL.md` — frontmatter model
4. `skills/linear-register/SPEC.md` — 개정 이력 + REQ-F-016~023 / REQ-N-005~008 편입
