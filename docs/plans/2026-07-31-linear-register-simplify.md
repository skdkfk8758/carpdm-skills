# linear-register 이슈 본문 간결화 + 추천 kickoff 프롬프트화

> 요구사항 SSOT: `docs/specs/linear-register-simplify.md` (deep-interview 9라운드,
> ambiguity 12%). 본 PLAN 은 그 spec 의 구현 계획 — 재인터뷰 없이 ground-check 만 수행.

## Goal (testable success criteria)

linear-register 가 등록하고 linear-groom 이 보강하는 Linear 이슈 본문이 **고정 헤딩
화이트리스트(항상 3 + 조건부 2) · 600자 이내 · 산문 내 파일경로 0개**로 유지되고,
`## 추천` 이 **붙여넣어 바로 착수하는 kickoff 프롬프트**를 모든 이슈에 담는다. 규칙
준수는 생성(상한)·승인(게이트 미리보기)·종료(검증 절 카운트) 3지점에서 강제된다.
`>` 인용줄과 fenced 코드블록은 carve-out(규칙 대상 밖).

## Scope (IN / OUT)

**IN**
- 이슈 본문 템플릿 재정의 (헤딩 화이트리스트 + 분량 상한 + 문체 규칙 + carve-out)
- `## 추천` 포맷 재정의 (권장 1줄 + kickoff 코드블록, boilerplate·대안 삭제)
- 분할 모드 확장 헤딩 폐지 (네이티브 관계로 대체)
- 확인 게이트에 본문 전문 미리보기 추가
- 검증 절 카운트 항목 추가
- `model:` fable → sonnet (register + groom)
- **[범위 확장 — 승인됨]** groom enrichment-template 을 같은 헤딩 계약으로 통일 +
  원본을 이슈 코멘트로 이관

### 적대 리뷰 반영 (2026-07-31 · 1-pass · 9건)

리뷰가 뒤집은 R2 결정 3건 — 전부 "간결화로 지웠는데 실제 소비처가 있더라" 형태:

- **`## 범위 밖` 존속(조건부)** — `linear-goal/references/routing.md:83` goal-ready
  기준 #3 이 이 헤딩 리터럴이고, `:63-69` ‡ 가드의 "범위 모호" 판정에도 걸린다.
  비용 1~2줄. (B1)
- **`> 출처:` 존속** — `>` 인용 1줄이라 폐지 이득 ≈0 인데 genesis 추적만 잃는다. (B8)
- **groom 원본 → 이슈 코멘트 이관** — `linear-groom/SKILL.md:43-44,282` 의 원본 보존
  불변식. groom 은 `save_issue(id=기존)` 로 description 을 통째 교체하므로 행선지
  없는 폐지는 작성자 스크린샷 소실이다. (B2)

그리고 **carve-out 신설** — `>` 인용줄과 fenced 코드블록은 헤딩 화이트리스트·자수
상한·경로 금지 **대상 밖**이다. 이게 없으면 유지하기로 한 `> Plan-reviewed:`(플랜
경로 포함)가 "파일경로 0개" 규칙과 자기모순이다. (B6)

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
| 5 | `skills/linear-groom/SKILL.md` | frontmatter model · 원본 보존 불변식(43-44) · healthy 센티널 레거시 인식(46) · 보강 요지 문구(146-147, 204) · anti-pattern(282) |
| 6 | `skills/linear-groom/references/enrichment-template.md` | 채울 섹션을 register 화이트리스트로 통일 + 원본 코멘트 이관 (9-11, 19-45, 53, 62) |
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
| P9 | `## 범위 밖` 헤딩 (조건부) | `linear-goal/references/routing.md:83` goal-ready #3 · `:63-69` ‡ "범위 모호" 가드 | 화이트리스트에 존속 (B1) |
| P10 | `## 다음 작업` 의 kickoff 프롬프트 | `linear-goal/SKILL.md:96`(Objective 시드) · `:188`(사용자 제시) · REQ-F-009 | §B 코드블록 존속 (B4) |
| P11 | groom 원본 보존 불변식 | `linear-groom/SKILL.md:43-44` · anti-pattern `:282` | 본문→코멘트 이관, 소실 0 (B2) |
| P12 | groom healthy 센티널의 레거시 인식 | `linear-groom/SKILL.md:46` — 기존 백로그 전부 `## 배경` 보유 · REQ-N-007 | 레거시 헤딩도 structure 로 계속 인정 (B7) |

## Steps (each step → its verify check)

> verify 판정은 `! grep -rq …`(부재) / `grep -rq …`(존재) 형태로 쓴다 — `grep -c … = 0`
> 은 0건에서 exit 1 을 내 `&&` 체인을 오염시키고, 디렉토리 대상은 `-r` 없이 하위
> 디렉토리를 뒤지지 않는다(실측: `grep -c '## 현황' skills/linear-groom/` 이
> `references/enrichment-template.md` 를 놓쳤다). (B5)

1. **본문 템플릿 재정의** — `SKILL.md:76-110` 교체. 헤딩 화이트리스트 =
   {`## 작업 내용`, `## 수용 기준`, `## 범위 밖`, `## 추천`, `## 다음 작업`} —
   앞 셋 중 `작업 내용`·`수용 기준`·`추천` + disclaimer 는 **항상**, `범위 밖`(P9)·
   `다음 작업`·`> 출처:` 는 조건부. `## 배경` **만** 폐지. 분량 상한 3종 + 문체 규칙 +
   **carve-out**(`>` 인용줄·fenced 코드블록은 헤딩·자수·경로 규칙 밖) 명시.
   → verify: `! grep -q '## 배경' skills/linear-register/SKILL.md`;
   `## 작업 내용`·`## 수용 기준`·`## 추천`·`## 범위 밖`·`[AUTO]`·`AI 가 등록·작성`·
   `carve-out` 관련 문구 전부 존재(P1~P3·P9).
2. **`## 추천` 포맷 재정의** — `recommend-section.md` §A 를 권장 1줄 + `시작 프롬프트:`
   코드블록으로. `대안:` 줄과 로컬 boilerplate 줄 삭제. **§B 는 kickoff 코드블록을
   유지**(P10 — §A 는 *이 이슈*, §B 는 *다음 이슈* 프롬프트로 서로 다르다) 하되 포맷만
   새 계약에 맞춘다.
   → verify: `! grep -rq '대안:' recommend-section.md`;
   `! grep -rq '로컬 툴도 확인' recommend-section.md`; §A·§B 각각 코드블록 예시 1개 이상.
3. **분할 모드 정렬** — `plan-split.md:57-78` 에서 `## Parent`/`## Blocked by` 삭제,
   본문 템플릿을 새 화이트리스트로. `> Plan-reviewed:` 유지(P4 — carve-out 대상).
   → verify: `! grep -rq '## Parent\|## Blocked by' plan-split.md`;
   `grep -rq 'Plan-reviewed' plan-split.md`.
4. **게이트 미리보기** — `dedup-grouping.md` §4 포맷 개정: 각 이슈 본문 전문을
   **`AskUserQuestion` 직전 메시지에 이슈별 fenced 블록**으로 출력하고, 질문 선택지는
   승인/거부(+유사 시 4택)만 담는다(B9 — 선택지 텍스트에 N건 본문은 안 들어간다).
   `SKILL.md:59-63` Step 3 문장도 정렬.
   → verify: §4 예시가 "직전 메시지 fenced 블록 + 별도 AskUserQuestion" 2단 구조를
   실제로 보여줌; SKILL.md Step 3 에 그 순서 명시.
5. **검증 절 카운트 항목** — `SKILL.md:114` 에 4항목 추가(화이트리스트 밖 헤딩 0개 ·
   분량 상한 준수 · disclaimer 존재 · 추천 코드블록 1개).
   → verify: 검증 절에 4항목 리터럴 존재.
6. **경계 1줄** — `SKILL.md:27-28` 에 "이슈 본문은 사람용 요약 — 착수 직전 상세 플래닝은
   별도 단계" 명시.
   → verify: 경계 절에 해당 문장 존재.
7. **모델 전환** — `linear-register/SKILL.md:3` · `linear-groom/SKILL.md:3` `model: sonnet`.
   → verify: `grep '^model:' skills/linear-register/SKILL.md skills/linear-groom/SKILL.md`
   둘 다 sonnet.
8. **groom 정렬 (범위 확장)** — `enrichment-template.md` 채울 섹션을 register 화이트리스트로
   통일: `## 배경`·`## 현황 (실측)` 폐지(내용은 `## 작업 내용` 으로 흡수),
   **`## 원본 (작성자 입력)` 은 본문에서 빼되 보강 시 이슈 코멘트로 1회 이관**하고 본문엔
   남기지 않는다(P11 — 소실 0). `groom/SKILL.md` 편집 지점: `:43-44`(원본 보존 불변식을
   "코멘트 이관"으로 재기술) · `:46`(**레거시 헤딩 `## 배경`/`## 현황`/`## 원본` 도 계속
   structure=healthy 신호로 인정** — P12/REQ-N-007) · `:146-147` · `:204` · `:282`
   (anti-pattern 문구 정렬) · `enrichment-template.md:9-11,53,62`.
   → verify: `! grep -rq '## 현황' skills/linear-groom/`;
   `! grep -rq '^## 배경' skills/linear-groom/`;
   `grep -rq '코멘트' skills/linear-groom/references/enrichment-template.md`;
   `grep -rq '레거시' skills/linear-groom/SKILL.md`.
9. **SPEC 편입** — `linear-register/SPEC.md` 에 개정 이력 + REQ-F-016~023 / REQ-N-005~008.
   **기존 ID 재번호 0건**, 단 이번 변경이 무효화하는 Must 는 *(개정 2026-07-31)* 표기 +
   대체 REQ 지시를 단다 — **REQ-F-006**(boilerplate 줄 삭제 → REQ-F-019 로 대체),
   **REQ-F-005**(추천 포맷 변경 → REQ-F-019). REQ-F-009/010 은 P10 으로 kickoff 이
   존속하므로 개정 불요. (B3)
   → verify: 기존 REQ-F-001~015 ID 전부 존속 AND REQ-F-005·006 행에 개정 마커 존재
   AND 신규 ID 12개 존재.
10. **검증 스위트** — `node scripts/ci/validate-skills.js` · `check-invisible-chars.js` ·
    `catalog.js` 3종 green.
    → verify: exit 0 ×3.

## Risks

- ~~**R1**~~ — 해소: groom 범위 확장 승인됨 (Step 8).
- ~~**R2**~~ — 해소: `> 출처:` 는 인용줄 carve-out 으로 존속 (B8).
- **R3 (중)** — 파일경로 0개 규칙이 버그 이슈 단서 제거(spec §5 잔여 2). 완화: carve-out
  으로 fenced 코드블록은 예외라 재현 로그·스택은 코드블록에 남길 수 있다. 다만 산문 내
  `path:line` 은 여전히 금지 — E 설계 시 재검토.
- **R4 (저)** — sonnet 다운그레이드가 dedup·추천 판정 품질에 영향(spec §5 잔여 3). 관찰 필요.
- **R5 (저)** — 이 레포는 Linear 본문을 검사하는 자동 훅이 없다. 강제는 규칙 문서 +
  게이트 + 자가 검증뿐 — 실효성은 다음 실제 등록 때 확인된다.
- **R6 (저, 신규)** — groom 원본 코멘트 이관은 **write 1회 추가**(코멘트 생성)다. 승인
  게이트 뒤에서만 돌지만, 실패 시 원본이 본문에서 사라진 채 코멘트도 없는 상태가 될 수
  있다 → 이관 순서를 **코멘트 먼저, 본문 교체 나중**으로 고정해 방어(Step 8 지시에 포함).

## Security surface

없음 — 마크다운 문서만 바뀐다. 외부 입력·auth 경계·secret·외부 호출 무관.
Linear MCP 호출 규약(승인 전 write 금지)은 무변경(P6·P7 보존).

## YAGNI (deletions in this change)

- `## 배경` 섹션 규칙 (register 템플릿 — 내용은 `## 작업 내용` 첫 줄로 흡수)
- `## 현황 (실측)` (groom enrichment — 같은 흡수)
- `## 원본 (작성자 입력)` **본문 섹션** (groom — 코멘트로 이관, 내용 소실 0)
- `## Parent` · `## Blocked by` (분할 모드 — 네이티브 관계 `parentId`/`blockedBy` 로 대체)
- `## 추천` 의 `대안:` 줄 · 로컬 스킬 boilerplate 줄

**철회된 삭제(적대 리뷰 B1/B4/B8)** — 소비처 실존 확인으로 존속: `## 범위 밖`(P9) ·
`## 다음 작업` 의 kickoff 코드블록(P10) · `> 출처:`(carve-out).

## Acceptance

> 전 항목 검증 완료 2026-07-31 — 증거는 각 행 끝. `[AUTO]` 11/11 · `[AGENT]` 2/2 ·
> `[HUMAN]` 1건 §V 이관. 검증 러너: `scratchpad/verify-acceptance.sh` (전 항목 PASS, exit 0).

1. `[AUTO]` `! grep -q '## 배경' skills/linear-register/SKILL.md` (배경만 폐지 —
   `## 범위 밖`·`> 출처:` 는 P9/B8 로 **존속**해야 하므로 0회 검사 대상 아님).
2. `[AUTO]` `skills/linear-register/SKILL.md` 템플릿에 `## 작업 내용`·`## 수용 기준`·
   `## 범위 밖`·`## 추천`·`> AI 가 등록·작성` 이 모두 존재하고 `[AUTO]`/`[HUMAN]` 마커
   예시 존속(P1~P3·P9).
3. `[AUTO]` `recommend-section.md` 에 `대안:` 0회, 로컬 boilerplate 문구 0회,
   §A·§B 각각 `시작 프롬프트:` 코드블록 예시 1개 이상(P10).
4. `[AUTO]` `plan-split.md` 에 `## Parent`·`## Blocked by` 0회, `Plan-reviewed` ≥1회(P4).
5. `[AUTO]` `SKILL.md` 본문 템플릿에 분량 상한 숫자 3종(작업 내용 ≤3줄 · 수용 기준 ≤5개 ·
   본문 ≤600자)과 **carve-out 규칙**(`>` 인용줄·fenced 코드블록 예외)이 리터럴로 명시(B6).
6. `[AUTO]` `SKILL.md` 검증 절에 신규 4항목(화이트리스트 밖 헤딩 0개 · 상한 준수 ·
   disclaimer · 추천 코드블록) 존재.
7. `[AUTO]` `grep '^model:' skills/linear-register/SKILL.md skills/linear-groom/SKILL.md`
   → 둘 다 `sonnet`.
8. `[AUTO]` `dedup-grouping.md` §4 예시가 "직전 메시지 이슈별 fenced 본문 블록 + 별도
   `AskUserQuestion`" 2단 구조를 보여줌(B9).
9. `[AUTO]` `SPEC.md` 에 REQ-F-016~023 · REQ-N-005~008 존재 AND 기존 REQ-F-001~015 ID
   전부 존속 AND REQ-F-005·REQ-F-006 행에 *(개정 2026-07-31)* 마커 + 대체 REQ 지시(B3).
10. `[AUTO]` `node scripts/ci/validate-skills.js` · `check-invisible-chars.js` ·
    `catalog.js` 3종 exit 0.
11. `[AGENT]` 새 규칙으로 **샘플 이슈 본문 1건을 실제 작성**해 화이트리스트 준수 ·
    본문(코드블록·인용줄 제외) ≤600자 · 산문 내 파일경로 0개 · 추천 코드블록 1개를
    만족함을 실측(Linear 에 쓰지 않는 드라이런).
12. `[AGENT]` `! grep -rq '## 현황' skills/linear-groom/` AND
    `! grep -rq '^## 배경' skills/linear-groom/` AND enrichment-template 에 원본
    **코멘트 이관** 지시 존재(P11) AND `groom/SKILL.md` 에 레거시 헤딩 healthy 인정
    문구 존재(P12).
13. `[HUMAN]` 다음 실제 등록 때 Step 3 게이트의 본문 미리보기가 승인 판단에 실제로
    쓰이는지 — agent 가 대신 못 함(실제 등록 워크플로 + 사용자 판단 필요).

## Plan review — 1-pass: 9건 (high 3 · med 5 · low 1), 전부 원장 닫힘

| id | 판정 | 근거 |
|---|---|---|
| B1 | FIXED | `routing.md:83` goal-ready #3 리터럴 확인 → `## 범위 밖` 조건부 존속(P9). 단 리뷰어의 "estimate 미설정→oversized 확정" 주장은 **부분 REJECTED** — `:63-69` ‡ 가드는 `estimate≥3` 만 배제하고 unset 은 허용한다(직접 인용 확인) |
| B2 | FIXED | `groom/SKILL.md:43-44,282` 원본 보존 불변식 확인 → 코멘트 이관으로 행선지 확보(P11), 순서는 코멘트 먼저(R6) |
| B3 | FIXED | `SPEC.md:47,54` 확인 → Step 9 에 REQ-F-005·006 개정 마커 추가, Acceptance 9 를 마커 존재까지 검사하도록 강화 |
| B4 | FIXED | `linear-goal/SKILL.md:96,188` 소비 확인 → §B kickoff 존속(P10). 내 YAGNI 판단이 틀렸다 |
| B5 | FIXED | 실증: `grep -c '## 현황' skills/linear-groom/` 이 `references/` 미탐지, `grep -c` 0건 exit=1 확인 → 전 verify 를 `! grep -rq` 형태로 교체 |
| B6 | FIXED | `> Plan-reviewed:` 가 경로 포함 → carve-out 신설(인용줄·코드블록 예외), Acceptance 5 에 반영 |
| B7 | FIXED | `groom/SKILL.md:46` 센티널 확인 → Step 8 에 레거시 헤딩 healthy 인정 명시(P12) |
| B8 | FIXED | `>` 인용 1줄 = 자수 이득 ≈0 확인 → `> 출처:` 존속 |
| B9 | FIXED | Step 3 게이트가 `AskUserQuestion`(`SKILL.md:59`) 확인 → 본문은 직전 메시지 fenced 블록, 선택지는 승인/거부만 |

## Pipeline state
- phase: 5 (done) · mode: linear · review: 1-pass 9건 원장 닫힘 · Acceptance 12/13 닫힘(1건 §V 이관)
- updated: 2026-07-31

## Acceptance 검증 결과 (2026-07-31)

| # | 태그 | 결과 | 증거 |
|---|---|---|---|
| 1 | AUTO | ✓ | `! grep -qE '^## 배경' register/SKILL.md` — 헤딩 0건 (백틱 인용 문구는 규칙 설명이라 대상 아님) |
| 2 | AUTO | ✓ | 작업 내용·수용 기준·범위 밖·추천·`[AUTO]`·disclaimer 전부 존재 (P1~P3·P9) |
| 3 | AUTO | ✓ | `대안:` 0회 · `로컬 툴도 확인` 0회 · `시작 프롬프트:` 2곳(§A·§B, P10) |
| 4 | AUTO | ✓ | plan-split 에 `^## Parent\|^## Blocked by` 0건 · `Plan-reviewed` 존속(P4) |
| 5 | AUTO | ✓ | `3줄`·`5개`·`600자`·`carve-out` 리터럴 존재 |
| 6 | AUTO | ✓ | 검증 절 ①~④ 항목 존재 (SKILL.md:158-160) |
| 7 | AUTO | ✓ | `model: sonnet` × 2 (register·groom) |
| 8 | AUTO | ✓ | dedup §4 에 `직전 메시지` + `AskUserQuestion` 2단 구조 |
| 9 | AUTO | ✓ | REQ-F-016~027·REQ-N-005~010 신설, 기존 F-001~015 전부 존속, F-005·006 개정 마커 |
| 10 | AUTO | ✓ | `validate-skills: OK — 25 skills valid` · `check-invisible-chars: OK — 158 files clean` · `catalog: OK — 25 skills, README.md in sync` (exit 0 ×3) |
| 11 | AGENT | ✓ | 실제 본문 작성 후 실측 — 헤딩 4개(화이트리스트 내) · 작업 내용 3줄 · 수용 기준 2개 · **385자**(carve-out 제외) · 산문 경로 0개 · 코드블록 1개. 기존 AUT-73 = 2,300자/헤딩 6개 |
| 12 | AGENT | ✓ | groom 에 `^## 현황\|^## 배경\|^## 원본` 0건 · enrichment-template 에 코멘트 이관 지시 · SKILL.md 에 레거시 healthy 인정 문구 |
| 13 | HUMAN | **이관** | 다음 실제 등록 시 게이트 미리보기 유용성 — 실제 Linear 등록 워크플로 + 사용자 판단 필요, agent 대행 불가 |

### 잔여 참조 sweep (correctness pass)

- 폐지 구조물(`## Parent`/`## Blocked by`/`대안:`) 잔여 참조: **설명 문맥 4건뿐**
  (전부 "구 X 는 폐지" 서술) — stale 0.
- register 템플릿을 읽는 타 스킬 14개 점검: `craft-core/linear.md` 는 `Plan-reviewed`
  마커·완료 코멘트 규약만 참조(둘 다 보존), `linear-goal/routing.md` 는 P9/P10 으로 보존,
  나머지는 템플릿 복제 없음. `scan-only.md:43` 의 요지 나열만 정렬(추가 수정).
- live `~/.claude/skills/craft-core/references/linear.md` ↔ repo drift 없음.
