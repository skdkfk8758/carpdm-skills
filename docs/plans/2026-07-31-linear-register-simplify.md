# linear-register 이슈 본문 간결화 + 추천 kickoff 프롬프트화

> 요구사항 SSOT: `docs/specs/linear-register-simplify.md` (deep-interview 9라운드,
> ambiguity 12%). 본 PLAN 은 그 spec 의 구현 계획 — 재인터뷰 없이 ground-check 만 수행.

## Goal (testable success criteria)

linear-register 가 등록하고 linear-groom 이 보강하는 Linear 이슈 본문이 **항상 4섹션 ·
600자 이내 · 파일경로 0개**로 유지되고, `## 추천` 이 **붙여넣어 바로 착수하는 kickoff
프롬프트**를 모든 이슈에 담는다. 규칙 준수는 생성(상한)·승인(게이트 미리보기)·종료
(검증 절 카운트) 3지점에서 강제된다.

## Scope (IN / OUT)

**IN**
- 이슈 본문 템플릿 재정의 (헤딩 화이트리스트 + 분량 상한 + 문체 규칙)
- `## 추천` 포맷 재정의 (권장 1줄 + kickoff 코드블록, boilerplate·대안 삭제)
- 분할 모드 확장 헤딩 폐지 (네이티브 관계로 대체)
- 확인 게이트에 본문 전문 미리보기 추가
- 검증 절 카운트 항목 추가
- `model:` fable → sonnet (register + groom)
- **[범위 확장 — 승인 필요]** groom enrichment-template 을 같은 4섹션으로 통일

**OUT**
- `linear-goal` 내부 동작 변경 (경계 1줄 명시만)
- 이미 등록된 이슈 소급 정리
- E(codex 이슈 플래닝 스킬) 설계
- 분할 모드 슬라이스 분해 로직 (`plan-split.md` §1~4)
- `[AUTO]`/`[HUMAN]` 2분류 → craft 3분류(`[AGENT]` 추가) 정렬 — 별건

## Files (verified — path : why it changes)

| # | 경로 | 왜 |
|---|---|---|
| 1 | `skills/linear-register/SKILL.md` | frontmatter model · 본문 템플릿(76-110) · 조건부 섹션 규칙 · Step 2 설명(47) · Step 3 게이트(59-63) · Step 4 체인(70) · 검증 절(114) · 경계 절(27-28) |
| 2 | `skills/linear-register/references/recommend-section.md` | §A 추천 포맷 · §B 전방 포인터 · §C UI 한 줄 (공유 SSOT — groom 도 이 파일을 읽음) |
| 3 | `skills/linear-register/references/plan-split.md` | §5 확장 템플릿의 `## Parent`/`## Blocked by` 폐지, 본문 템플릿 정렬 |
| 4 | `skills/linear-register/references/dedup-grouping.md` | §4 게이트 표시 포맷에 본문 전문 미리보기 |
| 5 | `skills/linear-groom/SKILL.md` | frontmatter model · surgical 규칙의 `## 배경` 참조(46) · 보강 요지 표 헤더(204) |
| 6 | `skills/linear-groom/references/enrichment-template.md` | 채울 섹션을 4섹션으로 통일 (범위 확장분) |
| 7 | `skills/linear-register/SPEC.md` | REQ-F-016~023 / REQ-N-005~008 편입 + 개정 이력 |

## 보존 계약 (MUST survive — characterization 대상)

개편이 조용히 깨면 안 되는 것들. 각각은 grep 으로 검증 가능한 불변식이다.

| # | 보존 대상 | 왜 (누가 의존하나) | 검증 |
|---|---|---|---|
| P1 | `## 작업 내용` · `## 수용 기준` **헤딩명** | `linear-goal` 이 Goal Prompt 로 매핑 (SKILL description 명시) | 두 헤딩이 템플릿에 리터럴로 존재 |
| P2 | 수용 기준의 `[AUTO]`/`[HUMAN]` 마커 | `acceptance-criteria-gate` 자율/사람 게이팅 | 템플릿 예시에 마커 존재 |
| P3 | disclaimer `> AI 가 등록·작성` | REQ-F-011 (기존 spec) | 템플릿에 존재 |
| P4 | `> Plan-reviewed:` 마커 | craft `pipeline.md` Phase 2 가 재리뷰 스킵 판정 | plan-split.md 에 마커 규칙 존속 |
| P5 | `recommend-section.md` = 단일 SSOT | register·groom 양쪽이 읽음 (복제 금지) | 두 스킬이 포인터만 보유, 포맷 복제 0 |
| P6 | 기본 `state: "Backlog"` + 폴백 | REQ-F-012 | SKILL.md Step 4 무변경 |
| P7 | dedup 4택 (등록/스킵/기존 보강/연결) | REQ-F-013 | dedup-grouping.md §4 표 존속 |
| P8 | 팀 라벨셋 실측 규칙 (§1.5) | REQ-F-014 라벨 오염 방지 | dedup-grouping.md §1.5 무변경 |

## Steps (each step → its verify check)

1. **본문 템플릿 재정의** — `SKILL.md:76-110` 을 4섹션 고정 + 분량 상한 + 문체 규칙으로
   교체. `## 배경`·`## 범위 밖`·`> 출처:` 폐지.
   → verify: `grep -c '## 배경\|## 범위 밖\|> 출처:' skills/linear-register/SKILL.md` = 0;
   P1·P2·P3 리터럴 존재.
2. **`## 추천` 포맷 재정의** — `recommend-section.md` §A 를 권장 1줄 + `시작 프롬프트:`
   코드블록으로. `대안:` 줄과 로컬 boilerplate 줄 삭제. §B 는 전방 포인터 1줄만
   (kickoff 프롬프트는 §A 가 전 이슈에 부여하므로 §B 복제는 YAGNI).
   → verify: `grep -c '대안:\|.claude/skills.*도 확인' recommend-section.md` = 0;
   §A 에 코드블록 예시 존재.
3. **분할 모드 정렬** — `plan-split.md:57-78` 에서 `## Parent`/`## Blocked by` 삭제,
   본문 템플릿을 4섹션으로. `> Plan-reviewed:` 는 유지(P4).
   → verify: `grep -c '## Parent\|## Blocked by' plan-split.md` = 0;
   `grep -c 'Plan-reviewed' plan-split.md` ≥ 1.
4. **게이트 미리보기** — `dedup-grouping.md` §4 포맷에 각 이슈의 **본문 전문** 블록 추가.
   `SKILL.md:59-63` Step 3 문장도 정렬.
   → verify: §4 예시에 본문 블록 존재; SKILL.md Step 3 에 "본문 전문" 문구 존재.
5. **검증 절 카운트 항목** — `SKILL.md:114` 에 4항목 추가(화이트리스트 밖 헤딩 0개 ·
   분량 상한 준수 · disclaimer 존재 · 추천 코드블록 1개).
   → verify: 검증 절에 4항목 리터럴 존재.
6. **경계 1줄** — `SKILL.md:27-28` 에 "이슈 본문은 사람용 요약 — 착수 직전 상세 플래닝은
   별도 단계" 명시.
   → verify: 경계 절에 해당 문장 존재.
7. **모델 전환** — `linear-register/SKILL.md:3` · `linear-groom/SKILL.md:3` `model: sonnet`.
   → verify: `grep '^model:' skills/linear-{register,groom}/SKILL.md` 둘 다 sonnet.
8. **groom 정렬 (범위 확장)** — `enrichment-template.md:19-45` 를 4섹션으로 통일
   (`## 배경`·`## 현황 (실측)`·`## 원본 (작성자 입력)` 폐지), `groom/SKILL.md:46,146-147,204`
   의 참조 문구 정렬.
   → verify: `grep -c '## 현황\|## 원본\|## 배경' skills/linear-groom/` = 0.
9. **SPEC 편입** — `linear-register/SPEC.md` 에 개정 이력 + REQ-F-016~023 / REQ-N-005~008.
   기존 ID 재번호 0건.
   → verify: 기존 REQ-F-001~015 문자열 전부 존속; 신규 ID 12개 존재.
10. **검증 스위트** — `node scripts/ci/validate-skills.js` · `check-invisible-chars.js` ·
    `catalog.js` 3종 green.
    → verify: exit 0 ×3.

## Risks

- **R1 (중)** — groom 범위 확장이 승인 안 되면 규칙이 반쪽. 등록은 4섹션인데 groom 보강 후
  6섹션으로 되돌아간다. 게이트에서 사용자 판단.
- **R2 (중)** — `> 출처:` 폐지로 genesis 역추적 상실(spec §5 잔여 1). 완화 미결정.
- **R3 (중)** — 파일경로 0개 규칙이 버그 이슈 단서 제거(spec §5 잔여 2). E 설계 시 재검토.
- **R4 (저)** — sonnet 다운그레이드가 dedup·추천 판정 품질에 영향(spec §5 잔여 3). 관찰 필요.
- **R5 (저)** — 이 레포는 Linear 본문을 검사하는 자동 훅이 없다. 강제는 규칙 문서 +
  게이트 + 자가 검증뿐 — 실효성은 다음 실제 등록 때 확인된다.

## Security surface

없음 — 마크다운 문서만 바뀐다. 외부 입력·auth 경계·secret·외부 호출 무관.
Linear MCP 호출 규약(승인 전 write 금지)은 무변경(P6·P7 보존).

## YAGNI (deletions in this change)

- `## 배경` · `## 범위 밖` · `> 출처:` 섹션 규칙 (register 템플릿)
- `## 현황 (실측)` · `## 원본 (작성자 입력)` (groom enrichment — 범위 확장 승인 시)
- `## Parent` · `## Blocked by` (분할 모드 — 네이티브 관계로 대체)
- `## 추천` 의 `대안:` 줄 · 로컬 스킬 boilerplate 줄
- `## 다음 작업` 의 kickoff 프롬프트 블록 (§A 가 전 이슈에 부여하므로 중복)

## Acceptance

1. `[AUTO]` `grep` 으로 `skills/linear-register/SKILL.md` 에 `## 배경`·`## 범위 밖`·
   `> 출처:` 출현 0회.
2. `[AUTO]` `skills/linear-register/SKILL.md` 템플릿에 `## 작업 내용`·`## 수용 기준`·
   `## 추천`·`> AI 가 등록·작성` 4개가 모두 존재하고, `[AUTO]`/`[HUMAN]` 마커 예시 존속(P1~P3).
3. `[AUTO]` `recommend-section.md` §A 에 `대안:` 0회, 로컬 boilerplate 문구 0회,
   `시작 프롬프트:` 코드블록 예시 1개 이상.
4. `[AUTO]` `plan-split.md` 에 `## Parent`·`## Blocked by` 0회, `Plan-reviewed` ≥1회(P4).
5. `[AUTO]` `SKILL.md` 본문 템플릿에 분량 상한 숫자 3종(작업 내용 ≤3줄 · 수용 기준 ≤5개 ·
   본문 ≤600자)이 리터럴로 명시.
6. `[AUTO]` `SKILL.md` 검증 절에 신규 4항목(헤딩 0개 · 상한 준수 · disclaimer · 추천
   코드블록) 존재.
7. `[AUTO]` `grep '^model:' skills/linear-register/SKILL.md skills/linear-groom/SKILL.md`
   → 둘 다 `sonnet`.
8. `[AUTO]` `dedup-grouping.md` §4 게이트 예시에 본문 전문 미리보기 블록 존재.
9. `[AUTO]` `SPEC.md` 에 REQ-F-016~023 · REQ-N-005~008 존재 + 기존 REQ-F-001~015 전부 존속.
10. `[AUTO]` `node scripts/ci/validate-skills.js` · `check-invisible-chars.js` ·
    `catalog.js` 3종 exit 0.
11. `[AGENT]` 새 규칙으로 **샘플 이슈 본문 1건을 실제 작성**해 4섹션·600자 이내·파일경로
    0개·추천 코드블록 1개를 만족함을 실측(Linear 에 쓰지 않는 드라이런).
12. `[AGENT]` (범위 확장 승인 시) `skills/linear-groom/` 에 `## 현황`·`## 원본`·`## 배경`
    출현 0회.
13. `[HUMAN]` 다음 실제 등록 때 Step 3 게이트의 본문 미리보기가 승인 판단에 실제로
    쓰이는지 — agent 가 대신 못 함(실제 등록 워크플로 + 사용자 판단 필요).

## Pipeline state
- phase: 1 (done) · mode: linear
- updated: 2026-07-31
