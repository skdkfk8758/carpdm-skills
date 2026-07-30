# Requirements: UserPromptSubmit 프롬프트 인테이크 계측기

> Crystallized from a deep-interview on 2026-07-30. Final ambiguity: 19% (target ≤ 20%).
> Type: brownfield. Rounds: 7. Status: draft.

## 1. Goal & scope

들어오는 사용자 프롬프트가 "그대로 진행해도 되는 요청"인지 "요구사항을 먼저 확인해야
할 요청"인지를 판정하고 싶다는 것이 원래 요구였다. 인터뷰 결과 그 판정을 **지금 짓지
않는다** — 대신 판정에 쓸 신호를 4주간 계측해, 이 훅이 만들 가치가 있는지를 데이터로
먼저 결정한다. 즉 이 spec 의 산출물은 분류기가 아니라 **분류기의 타당성을 재는
계측기**다.

성공은 "모호한 프롬프트를 잡는다"가 아니라 "4주 뒤 `verb=build & specifics=0` 프롬프트의
base rate 를 숫자로 말할 수 있다"이다.

**In scope:** UserPromptSubmit 훅에서의 신호 계측 · JSONL 로깅 · base rate 집계 ·
폐기/진행 판정 게이트.

**Out of scope (확정):**
- 프롬프트 차단 (exit 2) — 오탐률 미지 상태의 차단은 비대칭 리스크 (R4)
- nudge/경보 출력 — Phase 1 은 출력 0. 켤지 여부는 Phase 3 결정 (R5)
- 훅 내부의 클래스 라벨링 — 라벨 규칙을 훅에 박으면 과거 로그가 옛 규칙으로 굳어
  재해석 불가 (R6)
- 목표 명확성(축②) 판정 — 결정론 휴리스틱의 원리적 한계 (R3)
- `claude -p` 서브호출 등 LLM 경유 판정 — 프롬프트마다 수초 지연 (R1 기각)

## 2. Topology

| Component | Status | One-line role |
|-----------|--------|---------------|
| A 판정 주체(엔진) | active | 훅 안 결정론 휴리스틱 — bash/python, 정규식·사전 매칭만 |
| B taxonomy + 신호 | active | 문자열에서 실제 관측 가능한 raw 신호 필드 정의 |
| C 주입 액션 + 탈출구 | active | Phase 1 = 출력 0(계측만) · 로그 스키마 · 비활성 스위치 |
| D 기존 판정자 정합 + 은퇴 | active | skill-first·deep-* 게이트와의 관계 · base rate 게이트 · 폐기 기준 |

## 3. Functional requirements

| ID | Requirement (the system SHALL…) | Priority | Acceptance criteria | Origin |
|----|----------------------------------|----------|---------------------|--------|
| REQ-F-001 | UserPromptSubmit 훅으로 등록되어 모든 사용자 프롬프트에 대해 JSONL 레코드 **정확히 1건**을 append 한다 | Must | 프롬프트 3회 제출 후 로그 파일 라인 수가 정확히 3 증가 (`wc -l`) | R6 |
| REQ-F-002 | 레코드는 정확히 다음 키 집합을 갖는다 — `ts`·`session_id`·`cwd`·`agent_id`·`agent_type`·`prompt_len`·`prompt_head`·`banner_stripped`·`verb_class`·`specifics_count`·`has_path`·`has_number`·`has_error_text`·`has_backtick`·`scope_word_hits`·`vague_word_hits`·`is_question`·`is_slash_command` | Must | 레코드 키 집합이 스키마와 **정확히 일치** — 누락·추가 모두 실패. 타입도 스키마와 일치 | R6 (P2 리뷰 B11·B13 로 개정) |
| REQ-F-003 | `verb_class` 는 `build`·`fix`·`change`·`explain`·`none` 중 하나로 분류된다 (동사 키워드 사전 매칭, 복수 매칭 시 첫 매칭 우선) | Must | "로그인 기능 추가해줘"→`build` / "500 에러 나"→`fix` / "이 룰 설명해줘"→`explain` / "안녕"→`none` | R3 |
| REQ-F-004 | `specifics_count` 는 구체 지시자 출현 횟수의 합이다 — 파일경로(`*.확장자` 또는 `/` 포함 토큰) · 백틱 인용 · 숫자 리터럴 · 에러문 패턴(`Error`·`Exception`·HTTP 3자리 코드) · 대문자 식별자 | Must | `"guard-file-size.sh 의 300 을 500 으로"` → `specifics_count ≥ 3` | R3 |
| REQ-F-005 | 훅은 stdout 에 **아무것도 출력하지 않는다** (Phase 1) | Must | 훅을 직접 실행한 결과 stdout 이 빈 문자열 (`[ -z "$(bash hook.sh <<< "$payload")" ]`) | R5 |
| REQ-F-006 | 훅은 클래스 라벨(`interview`/`proceed`/`plan`, `VAGUE`/`CLEAR`)을 **계산하지도 기록하지도 않는다** | Must | 훅 소스에 라벨 상수·판정 분기가 존재하지 않음 (grep 으로 확인) · 로그 레코드에 라벨 필드 없음 | R6 |
| REQ-F-007 | **집계 스크립트가** 같은 `session_id` 안에서 직전 레코드로부터 120초 이내 도착한 짧은(60자 미만) 정정형 발화(`아니`·`그게 아니라`·`다시`·`말고`)를 사후 계산한다. **훅은 이 필드를 계산하지 않는다** | Should | 다른 세션 레코드가 인접해 있어도 같은 세션 쌍만 카운트 — 교차 세션 오탐 0 | R7 (P2 리뷰 B8 로 개정: 훅→집계 이동. 동시 세션·백그라운드 잡이 공유 JSONL 을 쓰므로 "마지막 줄 = 내 직전 프롬프트" 가 성립하지 않는다) |
| REQ-F-008 | base rate 집계 스크립트가 로그를 읽어 `verb_class ∈ {build,change} & specifics_count=0` 인 레코드의 전체 대비 비율을 출력한다 | Must | 스크립트 실행 → `N건 / 전체 M건 = X.X%` 형태 출력. 로그 0건이면 "샘플 없음" 명시 후 exit 0 | R7 |

## 4. Non-functional requirements

| ID | Category | Requirement | Acceptance criteria | Origin |
|----|----------|-------------|---------------------|--------|
| REQ-N-001 | Performance | 훅 실행이 **100ms 이내**에 끝난다 — 매 프롬프트마다 도는 경로라 지연이 곧 상시 비용 | `time` 으로 10회 측정, 최댓값 < 100ms | R1 |
| REQ-N-002 | Reliability | 어떤 실패에서도 **항상 `exit 0`** — 파싱 실패·디스크 오류·권한 문제 모두 조용히 삼키고 프롬프트 흐름을 막지 않는다 | 로그 디렉토리를 읽기전용으로 만든 뒤 훅 실행 → exit code 0 | R1 |
| REQ-N-003 | Compatibility | 기존 UserPromptSubmit 훅(`linear-banner-autostart.sh`)과 공존하며 그 동작에 영향을 주지 않는다 | 배너 포함 프롬프트 제출 시 Linear 자동전이가 여전히 동작 + 신규 로그도 1건 기록 | R7 |
| REQ-N-004 | Observability | 로그는 append-only JSONL 1파일. 경로 `~/.claude/logs/prompt-intake/records.jsonl` | 파일 존재 + 각 라인이 독립 파싱 가능한 JSON | R6 |
| REQ-N-005 | Security | 프롬프트 **원문 전체를 저장하지 않는다** — 앞 120자 truncate + 저장 직전 시크릿 패턴 redaction. **전문 SHA-256 은 저장하지 않는다**(집계·라벨링 어디에도 안 쓰이면서 짧은 프롬프트는 사전공격으로 복원됨) | 200자 프롬프트 → `prompt_head` ≤ 120 · `prompt_sha` 키 **부재** · 시크릿 접두 프롬프트(`sk-`·`ghp_`·`AKIA`·`Bearer `) → `prompt_head` 에 원값 미포함 | R7 (P2 리뷰 B7 로 개정) |
| REQ-N-007 | Security | 로그 파일 권한 `0600`, 부모 디렉토리 `0700` — `os.open(..., O_WRONLY\|O_APPEND\|O_CREAT, 0o600)` 명시 지정 | `stat -f %Lp` 로 파일 `600` · 디렉토리 `700` | P2 리뷰 B4 (실측: `open('a')` 기본값은 `0644`/`0755`) |
| REQ-N-006 | Lifecycle | 비활성 스위치 `PROMPT_INTAKE_DISABLE=1` 이 설정되면 즉시 exit 0 | 환경변수 설정 후 프롬프트 제출 → 로그 라인 증가 0 | R5 |

## 5. Constraints & assumptions

**Constraints**
- 훅은 bash/python3 만 사용 — 외부 의존성 0 (`linear-banner-autostart.sh` 와 동일 규율)
- `~/.claude` 는 git 추적되지 않음 (실측) — 훅 소스의 이력 안전망 없음. spec·집계
  스크립트는 carpdm-skills 에 두고 훅 본체만 `~/.claude/hooks/` 에 배치
- 글로벌 룰 "신규 룰은 은퇴 조건 의무" 적용 대상 — 리뷰 시점 없는 상시 잡 금지

**Assumptions resolved**
- *"UserPromptSubmit 에서 분류한다"* → 훅은 LLM 이 아니라 셸이므로 의미 판정 불가.
  결정론 휴리스틱으로 확정, 대신 판정을 Phase 3 으로 미룸 (R1)
- *"nudge 를 주면 행동이 바뀐다"* → 반례 존재(`karpathy-core.md` 의 "critical 룰 95%
  무시" 실측). 가정을 채택하지 않고 **측정 대상으로 강등** (R4 contrarian)
- *"3클래스가 필요하다"* → 결정론 휴리스틱은 축②를 못 보므로 (a)/(c) 분리 불가.
  계측 모드에서는 라벨 자체를 훅에서 빼고 사후 재해석에 맡김 (R4→R6)
- *"정답 라벨이 있어야 측정된다"* → base rate 3구간 중 2구간(<2%, >30%)은 정답 없이
  결정된다. 라벨링은 5~15% 구간에서만 지불 (R7)

**Residual ambiguity**
- **원문 보존 범위 (REQ-N-005 영향).** 앞 120자 truncate + redaction 으로 확정.
  base rate 집계(REQ-F-008)에는 충분하지만, 5~15% 구간 진입 시 수동 라벨링 정확도가
  truncate 로 떨어질 수 있다. **리스크**: 4주 뒤 라벨링 단계에서 앞 120자로 판정이
  안 되면 재계측 4주가 추가된다. (P2 리뷰 B7: 앞 120자는 시크릿 포획 확률이 가장
  높은 구간이지만, 배너 오염 사후 식별과 라벨링의 유일한 재료라 삭제하지 않고
  redaction 으로 대응.)
- ~~**리뷰 실행 주체.**~~ **해소** — Linear 이슈 + due 2026-08-27 로 확정(빌드 Step 9).
- **UserPromptSubmit 발화 범위 (신규, P2 리뷰 B13).** 이 훅이 subagent·`claude -p`·
  automation 경로에서도 발화하는지 공식 문서에 없다. 발화하면 base rate 분모가 사람
  프롬프트가 아니게 된다. **완화**: `cwd`·`agent_id`·`agent_type` 을 기록해 오염 시
  집계에서 제외 가능하게 했다 — 4주 뒤 로그를 보면 실측으로 판정된다.
- **`specifics_count` 사전 경계.** 무엇을 구체 지시자로 셀지 REQ-F-004 에 초안을
  뒀으나 튜닝 없이 확정한 값이다. **리스크**: 이 정의가 틀리면 base rate 자체가
  무의미해진다(단일 판정 로직이므로 blast radius 최대).

## 6. Context (brownfield)

인터뷰 중 실제로 읽은 코드에 근거:

- **`~/.claude/hooks/linear-banner-autostart.sh`** — 유일한 기존 UserPromptSubmit 훅.
  참조 패턴 확정: stdin 으로 JSON payload 수신(`prompt`·`session_id` 키) → 환경변수로
  전달(heredoc 이 stdin 점유) → `sys.exit(0)` 무조건 → 실패는 로그 파일로만. 신규 훅은
  이 구조를 그대로 따른다. (REQ-N-002, REQ-N-003 제약)
- **`~/.claude/settings.json` `hooks.UserPromptSubmit`** — 배열이며 현재 2엔트리
  (linear-banner-autostart + Orca `claude-hook.sh`). 신규 훅은 3번째로 append.
  기존 엔트리 순서·동작 변경 금지. (REQ-N-003)
- **기존 판정자 2개 (D 컴포넌트).** `~/.claude/rules/skill-first-workflow.md` 가
  "비trivial → 스킬 경유"를, deep-plan/deep-interview 가 자체 적응형 게이트("crisp 하면
  인터뷰 스킵")를 이미 수행한다. 본 계측기는 **셋째 판정자가 아니다** — Phase 1 은
  판정하지 않으므로 충돌 없음. Phase 3 에서 nudge 를 켜기로 하면 그때 skill-first 와의
  역할 분담을 재설계해야 한다(현 spec 범위 밖).
- **`~/.claude/logs/`** — 기존 로그 관례 존재(`linear-autostart/`). 신규 경로
  `prompt-intake/` 를 같은 규약으로 추가. (REQ-N-004)

## 7. Traceability — clarity trail

| Round | Ambiguity | Targeted dimension | Requirements pinned |
|-------|-----------|--------------------|---------------------|
| 0 | 58% | topology lock | A / B / C / D 전부 active |
| 1 | 47% | A.constraints (type 2) | REQ-N-001, REQ-N-002 — 엔진=결정론 휴리스틱 |
| 2 | 47% | B.goal (type 1) | — (예시 요청으로 전환) |
| 3 | 41% | B.goal (type 1) | REQ-F-003, REQ-F-004 — 축① 정규식 가능 / 축② 불가 |
| 4 | 33% | C.goal (type 6 + **contrarian**) | Out-of-scope 확정: 3클래스·차단 |
| 5 | 28% | C.goal | REQ-F-005 — 계측기 모드, 출력 0 |
| 6 | 24% | D.goal (**simplifier**) | REQ-F-001, REQ-F-002, REQ-F-006 — 라벨링 삭제 |
| 7 | 19% | D.criteria | REQ-F-007, REQ-F-008 — base rate 게이트, 정답 라벨 유예 |

## 8. Handoff

Recommended next skill: **`/forge`** — 존재하지 않는 훅 스크립트 + 집계 스크립트를
새로 만드는 작업이다(신규 기능). 규모는 작다(훅 1개 · 스크립트 1개 · settings.json
1행) — 강도는 **linear** 로 충분하며 council/orchestrated 는 과투자.

**Treat this spec as the completed requirements step.** forge 는 기본적으로 자체 Socratic
인터뷰를 돌린다 — **건너뛸 것**. 위 번호 매긴 요구사항을 못 박힌 Phase-1 산출물로
그대로 넣고 plan review 로 직행하라. 재인터뷰 금지.

**빌드 전 해소 권장:** §5 잔여 ambiguity 3건 중 "리뷰 실행 주체"는 코드가 아니라
운영 결정이므로 forge 진입 전에 정하는 편이 싸다 — 안 정하면 REQ-N-006 계열
요구사항이 하나 빈 채로 빌드된다.
