# UserPromptSubmit 프롬프트 인테이크 계측기

> Phase-1 산출물 = `docs/specs/prompt-intake-classifier.md` (deep-interview 7라운드,
> ambiguity 19%). 재인터뷰 없음 — 이 plan 은 그 spec 을 Files/Steps/Acceptance 로
> 실행 가능하게 옮긴 것이다.
>
> **v2 (Phase 2 적대 리뷰 반영).** high 3건이 초판 설계를 바꿨다 — 배포 경로(심링크
> → `global/` 미러), 배너 오염 제거, 실세션 발화 검증. 원장은 `## Plan review` 참조.

## Goal (testable success criteria)

UserPromptSubmit 훅이 모든 사용자 프롬프트에 대해 raw 신호 레코드 1건을 JSONL 로
append 하고, **stdout 에 아무것도 내지 않으며**, 어떤 실패에서도 `exit 0` 한다.
집계 스크립트가 그 로그에서 `verb_class ∈ {build,change} & specifics_count=0` 의
비율(base rate)을 출력한다.

성공 = "4주 뒤 base rate 를 숫자로 말할 수 있다". 분류·판정·경보는 이 빌드의
목표가 아니다.

## Scope (IN / OUT)

**IN**
- 훅 스크립트 1개 (raw 신호 계측 + JSONL append) — **python3 단독**, bash 래퍼 없음
- base rate 집계 스크립트 1개 (correction_flag 사후 계산 포함)
- `~/.claude/settings.json` UserPromptSubmit 배열에 엔트리 1개 추가
- `global/` 미러 갱신 (훅·집계·settings.json·README 매핑표)
- 훅 테스트 스크립트 1개 (repo 미러를 대상으로 — CI 가능)
- 4주 뒤 리뷰용 Linear 이슈 1건 (due 2026-08-27)

**OUT** (spec §1 확정)
- 프롬프트 차단 · nudge/경보 출력 · 훅 내부 클래스 라벨링 · 목표 명확성(축②) 판정
- `claude -p` 등 LLM 경유 판정
- 배포 자동화 스크립트 — `global/` 은 수동 미러가 규약이다 (README)
- 로그 로테이션 — 4주 상한이 사실상 존재 (YAGNI)

## Files (verified — path : why it changes)

`global/README.md` 실측: repo `global/` 은 `~/.claude/` 의 **수동 미러**이고
**SSOT 는 라이브** 쪽이다. 초판의 심링크 안은 이 규약을 뒤집고 브랜치 체크아웃에
끊기므로 폐기했다(B2).

| 경로 | 변경 | 이유 |
|---|---|---|
| `~/.claude/hooks/prompt-intake.py` | 신규 | 훅 본체 **라이브 SSOT**. python3 단독(shebang) — bash 래퍼 없음(B6) |
| `global/hooks/prompt-intake.py` | 신규 | 위의 repo 미러(복사). git 이력·리뷰용 |
| `~/.claude/scripts/prompt-intake-baserate.py` | 신규 | base rate 집계 라이브. `global/scripts/*` 매핑 관례 준수 |
| `global/scripts/prompt-intake-baserate.py` | 신규 | 위의 repo 미러 |
| `scripts/ci/test-prompt-intake.sh` | 신규 | 훅 acceptance 테스트. **repo 미러를 대상**으로 실행해 CI 에서 돌 수 있게 |
| `~/.claude/settings.json` | 편집 (1엔트리 append) | 실측: `hooks.UserPromptSubmit` = matcher 없는 `{"hooks":[{…}]}` 2엔트리. 3번째로 추가 |
| `global/settings.json` | 편집 (동일) | 미러 drift 방지(B10). 현재 미러는 2엔트리 |
| `global/README.md` | 편집 (매핑표 1행) | 현 매핑표에 `global/hooks/guards/*.sh` 만 있고 최상위 `global/hooks/*.py` 행이 없다 |
| `.github/workflows/ci.yml` | 편집 (스텝 1개) | **plan defect (C1)** — 초판이 빠뜨렸다. validate 잡이 node 3종만 돌아 이 테스트가 CI 밖에 있었다. 테스트가 모든 Acceptance 주장의 유일한 근거이므로 조용히 썩으면 안 된다 |

## Steps (each step → its verify check)

1. **acceptance test 작성 (red)** — `test-prompt-intake.sh`: payload 주입 → JSONL +1 ·
   stdout 빈 문자열 · exit 0 · 스키마 키 일치.
   → verify: **스텁 훅**(`exit 0` 만 하는 빈 파일)을 대상으로 실행 → 각 케이스가
   *개별 단언 실패*로 FAIL(파일 부재의 exit 127 이 아님 — B12)
2. **payload 키 실측** — 훅 첫 구현에 raw payload 의 키 목록을 1회 로깅하는 경로를 넣고
   실제 프롬프트로 확인한다. `prompt`/`session_id` 는 UserPromptSubmit 고유 입력으로
   공식 문서화돼 있지 않고 근거가 기존 훅의 동작뿐이다(B3).
   → verify: 로그에 실제 키 목록 1줄 기록 · `prompt` 존재 확인 후 그 경로 제거
3. **훅 본체 구현 (green)** — python3 단독. stdin 직독 → **배너 스트립** → 신호 추출 →
   `os.open(..., 0o600)` 으로 JSONL append → 무출력 exit 0.
   → verify: `bash scripts/ci/test-prompt-intake.sh` 전 케이스 PASS
4. **배너 오염 제거** — Orca 가 세션 첫 프롬프트 앞에 배너를 주입한다
   (`linear-banner-autostart.sh:5-7` 이 직접 문서화). `Linked Linear issue: <ID>` +
   URL 줄 + 빈 줄을 결정론적으로 벗겨내고 `banner_stripped` 를 기록.
   `is_slash_command` 는 "**임의 줄**이 `/` 로 시작"으로 정의(배너 뒤 `/renew`).
   → verify: 배너만 있는 페이로드 → `specifics_count == 0` · `banner_stripped == true`
5. **신호 추출 정밀화** — `verb_class` 5분류, `specifics_count` 5소스, `prompt_head`
   redaction, `cwd`/`agent_id`/`agent_type` 기록(B13 — 사람/기계 프롬프트 사후 구분).
   → verify: spec REQ-F-003/004 예시 입력이 기대값 산출
6. **집계 스크립트** — base rate + 3구간 판정 문구. `correction_flag` 를 여기서
   **사후 계산**(`session_id` 그룹핑 + ts diff — 훅에 상태 파일을 두지 않는다, B8).
   → verify: 기대값 자명한 합성 로그(충족 3 + 미충족 7) → 출력이 **정확히**
   `3건 / 전체 10건 = 30.0%`. 0건 로그 → `샘플 없음` + exit 0
7. **미러 + 설치** — 라이브에 배치 → `global/` 로 복사 미러 → `settings.json` 양쪽
   3엔트리 → `global/README.md` 매핑표 1행.
   → verify: 라이브↔미러 `diff` 무출력 · `UserPromptSubmit` 제외 트리가 편집 전후
   **deep-equal**(포맷이 아니라 값 동등성)
8. **런타임 스모크** — 훅 직접 실행 + 집계 스크립트 실행 + 실세션 발화 확인 인계.
   → verify: 로그에 실 레코드 append · 집계 출력 정상 · 실세션 항목은 §V 이관
9. **리뷰 이슈 등록** — Linear 이슈(due 2026-08-27) + 본문에 집계 명령 박기.
   → verify: 이슈 ID 반환 후 재조회로 due date 확인

## Risks

- **`specifics_count` 사전이 틀리면 base rate 전체가 무의미** (spec §5 잔여 #3).
  완화: raw 필드(`has_path`·`has_number`…)를 개별 저장해 사후 재조합 가능.
- **한글 어미 변화** — `추가해줘`/`추가하자`/`추가할래` 를 정규식으로 전부 못 잡는다.
  완화: 어간 부분매칭(`추가`). 미매칭은 `none` 으로 떨어져 base rate 를 **과소**추정
  (안전한 방향 — 과대추정이면 없는 문제를 만든다).
- **verb 우선순위 편향 (C8 수정 후 방향).** `build`/`change` 가 `fix` 를 앞선다. 즉
  "버그 고치는 기능 추가해줘" 류는 `build` 로 잡혀 base rate 분모·분자에 **포함**된다
  — 수정 전(`fix` 우선)이 zero-specifics build 요청을 통째로 탈락시켜 분자를 계통
  deflate 했던 것과 반대 방향의 편향이다. 이쪽을 택한 이유: 계측 목적이 "모호한 신규
  요청"을 세는 것이므로 build 를 놓치는 쪽이 더 해롭다. 4주 뒤 로그에서 `verb_class`
  분포로 실측 검증 가능.
- **UserPromptSubmit 이 subagent/headless 에서도 발화하는지 미문서화**(B13). 완화:
  `cwd`/`agent_id`/`agent_type` 를 기록해 오염 시 집계에서 제외 가능하게.
- **`settings.json` 동시 쓰기** — Claude Code 자신이 permission 승인 시 같은 파일을
  쓴다(가설, 신뢰도 중). 완화: 편집 전 백업 + 편집 후 즉시 deep-equal 검증.

## Security surface

- **프롬프트 원문 노출** — 유일한 실질 보안 표면. 통제 3겹:
  1. `prompt_head` 앞 120자만 저장, **전문 SHA-256 은 저장하지 않는다**(B7 — 목표에
     기여 0인데 짧은 프롬프트는 사전공격으로 복원됨)
  2. 저장 직전 시크릿 패턴 redaction (`sk-`·`ghp_`·`admap_`·`AKIA`·`Bearer `·
     `=` 뒤 40자+ 고엔트로피 토큰 → `[REDACTED]`)
  3. `os.open(..., O_WRONLY|O_APPEND|O_CREAT, 0o600)` + 디렉토리 `0o700` —
     실측상 `open('a')` 기본값은 `0644`/`0755` 라 명시 지정이 필수(B4)
- 외부 호출 없음 · 네트워크 없음 · secret 읽지 않음 · 쓰기 대상은 자기 로그 1개.
- `settings.json` 편집은 파괴적 — 백업 → 편집 → deep-equal 검증.
- `global/settings.json` 미러는 민감정보 0인 것만(README 규약) — `env.ADMAP_API_KEY`
  가 라이브에 평문 존재하므로 미러 커밋 전 grep 확인.

## YAGNI (deletions in this change)

순수 신규 — orphan 없음. 초판 대비 삭제한 것: 심링크 배포(B2) · bash 래퍼(B6) ·
`prompt_sha` 필드(B7) · 훅 내부 `correction_flag` 상태 파일(B8).

(4주 뒤 base rate 판정에서 폐기가 결정되면 이 빌드 전체가 삭제 대상 — spec 은퇴 조건.)

## Acceptance

1. ✓ `[AUTO]` payload 1건 주입 → JSONL 라인 수 정확히 +1 (REQ-F-001) — `A1`
2. ✓ `[AUTO]` 레코드 키 집합이 스키마와 **정확히 일치** (REQ-F-002, B11) — `A2` + `AT` 타입 단언
3. ✓ `[AUTO]` `build`/`fix`/`explain`/`none` 4케이스 (REQ-F-003) — `A3` ×4 + `AP` 우선순위 3케이스
4. ✓ `[AUTO]` `"guard-file-size.sh 의 300 을 500 으로"` → `specifics_count ≥ 3` (REQ-F-004) — `A4` (실측 3)
5. ✓ `[AUTO]` 훅 실행 stdout 이 빈 문자열 (REQ-F-005) — `A5`
6. ✓ `[AUTO]` 훅 소스에 라벨 리터럴 없음 · 레코드에 라벨 필드 없음 (REQ-F-006) — `A6` (ast 로 독스트링·주석 제거 후 검사)
7. ✓ `[AUTO]` **배너만** → `specifics_count == 0` · `banner_stripped == true` (B1) — `A7`/`A7b`
8. ✓ `[AUTO]` 배너 뒤 `/renew` → `is_slash_command == true` (B1) — `A8`
9. ✓ `[AUTO]` 합성 로그(충족 3 + 미충족 7) → **정확히** `3건 / 전체 10건 = 30.0%` (REQ-F-008, B9) — `A9`
10. ✓ `[AUTO]` 빈 로그 → `샘플 없음` + exit 0 (REQ-F-008) — `A10`
11. ✓ `[AUTO]` 훅 **작업** < 100ms (REQ-N-001) — `A11`. 인터프리터 기동(~50ms) baseline 차감 후 측정 (C1)
12. ✓ `[AUTO]` 실패 3케이스 exit 0 + 로그 증가 0 (REQ-N-002, B5/C6) — `A12a/b/c`
13. ✓ `[AUTO]` 1.5MB payload → exit 0 + 레코드 1건 (REQ-N-002, B6) — `A13` (실측 42ms)
14. ✓ `[AUTO]` 로그 파일 `0600` · 디렉토리 `0700` (B4) — `A14`, 라이브 실측 `600`/`700`
15. ✓ `[AUTO]` `prompt_head` ≤ 120 · `prompt_sha` 부재 · 시크릿 5종 redaction (REQ-N-005, B7/C4/C5) — `A15` + `AR` ×6(straddle·base64 포함) + `ARF` false-positive 가드
16. ✓ `[AUTO]` `PROMPT_INTAKE_DISABLE=1` → 증가 0 (REQ-N-006) — `A16` (대조군 포함)
17. ✓ `[AUTO]` 집계가 `session_id` 그룹핑으로 정정 사후 계산 (REQ-F-007, B8/C2) — `A17` + `AC` 경계 4케이스(gap 120/121, len 59/60)
18. ✓ `[AGENT]` `settings.json` 3엔트리 · 나머지 트리 **deep-equal** · 미러도 3엔트리 (REQ-N-003, B10) — 편집 시 `deep-equal: True`, 최종 확인 라이브/미러 각 3엔트리
19. ✓ `[AGENT]` 라이브↔미러 `diff` 무출력 — 훅·집계 각각 무출력 확인
20. ✓ `[AGENT]` payload raw 키 실재 확인 (B3) — 스모크에서 `session_id`/`cwd`/`prompt` 가 모두 값으로 기록됨
21. ✓ `[AGENT]` 리뷰 Linear 이슈 (B3) — **ADT-433** · due `2026-08-27` · Backlog, `get_issue` 재조회 확인
22. ⏳ `[HUMAN]` **이관** — 실세션 프롬프트 1건 → `records.jsonl` +1 & `prompt_len > 0` & 기존 Linear 자동전이 유지. agent 는 실세션 프롬프트를 발생시킬 수 없다(스모크는 훅을 직접 호출한 것이지 Claude Code 가 부른 게 아니다). 확인 방법은 §V 참조

**장부 상태**: `[AUTO]` 17/17 green · `[AGENT]` 4/4 green · `[HUMAN]` 1건 이관.
추가 검증(리뷰가 요구한 판별력): 총 **68 assertions**, repo 미러·라이브 양쪽 green.

## HTML companion

비UI 빌드(훅 스크립트 + CLI) — companion 생략(pipeline Phase 1 규칙). 원하면 plan
렌더 HTML 생성 가능.

## Plan review — 1-pass: 13건 (high 3 · med 7 · low 3) — 전건 FIXED

adversary 역할 subagent 1회. **cross-model 아님**(codex 은퇴) — 같은 모델이므로
아래 원장의 직접 검증 증거가 유일한 신뢰 층이다.

| id | 판정 | 근거 |
|---|---|---|
| B1 | FIXED | `linear-banner-autostart.sh:5-7` 이 "Orca prepends worktree metadata to the first prompt" 를 직접 문서화 — 배너가 `specifics_count` 를 부풀려 base rate 분자를 계통 deflate. Step 4 배너 스트립 + Acceptance 7·8 추가 |
| B2 | FIXED | **직접 검증**: `git ls-files global` → 17파일 추적 중, `global/README.md` 가 매핑표 + "SSOT 는 라이브" 명시. 현재 브랜치 `chore/codex-plugin-retire`(master 아님) — 심링크 끊김 실재. 심링크 폐기 → `global/` 복사 미러로 전환, Files 표 재작성 |
| B3 | FIXED | plan 초판이 spec REQ-N-003 의 "신규 로그도 1건 기록" 을 누락했음 확인. Acceptance 22 로 spec 원문 복원 + Step 2 payload 키 실측 추가 |
| B4 | FIXED | **직접 검증**: `open('a')` → 파일 `0o644` · 디렉토리 `0o755`(umask 022). `os.open(..., 0o600)` 명시 + Acceptance 14 |
| B5 | FIXED | **직접 검증**: `chmod 500` 디렉토리에서 기존 파일 append **성공**, 신규 생성만 `PermissionError` — 초판 Acceptance 10 은 어떤 실패 경로도 안 탔다. Acceptance 12 를 3케이스로 교체 |
| B6 | FIXED | **직접 검증**: `export HOOK_PAYLOAD` + heredoc 에 1.5MB → `rc=127`(리뷰어는 rc=1 이라 했으나 non-zero 라는 요지 유효). bash 래퍼 제거, python3 단독 + Acceptance 13 |
| B7 | FIXED | `prompt_sha` 가 집계식·라벨링 어디에도 안 쓰임 확인 — 기여 0, 짧은 프롬프트는 사전공격 복원 가능. 필드 삭제 + redaction 1패스 추가. `prompt_head` 는 B1 오염 식별 재료라 유지 |
| B8 | FIXED | plan 초판 Files 표에 상태 저장소 없음 확인. 공유 JSONL 마지막 줄은 동시 세션에선 남의 세션 — 훅에서 빼고 집계 사후 계산으로 이동(Acceptance 17) |
| B9 | FIXED | 초판 Step 4·Acceptance 8 이 출력 *형태*만 검사 — `0.0%` 뱉는 집계기도 통과. 기대값 자명 합성 로그 + 정확값 단언으로 교체 |
| B10 | FIXED | **직접 검증**: `settings.json` 441줄 · 19 top keys · `permissions.allow` 57 · `skillOverrides` 87 (리뷰어의 "allow 65" 는 부정확하나 요지 유효). deep-equal 검증 + `global/settings.json` 미러를 Files 표에 추가 |
| B11 | FIXED | spec REQ-F-002 의 13필드와 실제 레코드 필드가 불일치 확인. Acceptance 2 를 "키 집합 정확 일치" 로 강화 + spec 갱신 |
| B12 | FIXED | 초판 Step 1 verify 는 exit 127 로도 성립 — 스텁 훅 대상 개별 단언 실패로 교체 |
| B13 | FIXED | `cwd`/`agent_id`/`agent_type` 기록 추가(무비용). 오염 시 집계 제외 가능 |

**ADR 판단: 불필요.** B2 를 기존 `global/` 관례에 맞췄으므로 새 배포 모델 결정이
아니다. (심링크 안을 고수했다면 `global/README.md` 의 미러 모델 변경이라 ADR 이
필요했다.)

## Code review — Phase 4 §2: 9건 (high 2 · med 3 · low 4) — 전건 FIXED

`/code-review` 가 이 세션의 호출 가능 스킬 목록에 없어 `security.md` §2 **폴백 래더**
대로 adversary 역할 subagent 로 대체했다(그 사실을 여기 명시 — 계약 요구). 리뷰어가
**17개 뮤턴트로 테스트 판별력을 측정**했고 15개가 살아남았다 — 발견의 절반이
"구현 결함"이 아니라 "그 구현을 검증하지 못하는 테스트"였다.

| id | 판정 | 근거 |
|---|---|---|
| C1 | FIXED | **직접 검증**: `ci.yml` 이 node 3종만 실행 — 이 테스트를 안 부름. A11 은 인터프리터 기동(~50ms)을 재는 중이라 100ms 바에서 flaky. baseline 차감 방식으로 교체 + `ci.yml` 에 스텝 추가 |
| C2 | FIXED | `verdict()` 전체 무커버(본문을 상수로 바꿔도 통과)·correction 두 필터 무커버·redaction 5규칙 중 `sk-` 만 검증. verdict 구간표(2/5/15/30) + correction 경계(gap 120/121, len 59/60) + 규칙별 redaction 케이스 추가 |
| C3 | FIXED | 키 집합만 보고 **값을 아무도 안 봄** — `has_*` 전부 하드코딩해도 통과. 값+타입 단언 + negative control + verb 우선순위 케이스 추가 |
| C4 | FIXED | **직접 검증**: 111자 패딩 뒤 `AKIAIOSFODNN7EXAMPLE` → `prompt_head` 에 `AKIAIOSFO` **raw 저장**. `redact(text[:120+256])[:120]` 으로 순서 교정 |
| C5 | FIXED | **직접 검증**: AWS secret key `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` 가 **통째로 통과**(`/`·`+` 가 문자군에 없어 40자 미만으로 쪼개짐). base64 포함 + 혼합케이스·숫자 lookahead 조건으로 교체 — 동시에 git SHA·SCREAMING_SNAKE false positive 도 해소(라벨링 재료 보존) |
| C6 | FIXED | A12b 첫 케이스(`nonexistent-parent/deeper`)는 `makedirs(exist_ok=True)` 가 만들어버려 실패 경로가 아니었고 `rc` 는 죽은 대입. 케이스 삭제 + `로그 증가 0` 단언 추가 |
| C7 | FIXED | **직접 검증**: `1.96%` → 표시 `2.0%` / 판정 `<2% 폐기`. `round()` 를 한 번만 적용해 표시와 분기가 같은 값을 쓰게 수정 |
| C8 | FIXED | **직접 검증**: `에러 핸들링 추가해줘`·`에러 로그 포맷 바꿔줘`·`add error handling…` 셋 다 `fix` + `specifics 0` — base rate 분자에서 계통 탈락. `build`/`change` 를 `fix` 앞으로 이동 (아래 Risks 갱신) |
| C9 | FIXED | **직접 검증**: 현 정규식에서 cap 제거 시 13.9ms(100KB)·66.3ms(400KB). 내가 측정한 10.5초는 사실이지만 **옛 `PATH_RE`**(전체 문자열 대안) 탓이었다 — 주석이 원인을 틀리게 귀속했다. 주석 정정 |

**리뷰어가 반박한 것(발견 아님)**: `count_corrections` 의 세션 그룹핑, `verdict()`
경계값, `BANNER_RE` over-strip(실제 Orca 배너를 트랜스크립트에서 추출해 대조),
`append_record` 의 부분 쓰기.

## Pipeline state
- phase: 4 (done) · mode: linear
- review: P2 1-pass done (13건 FIXED) · P4 §2 1-pass done (9건 FIXED) — 미해소 high 0
- tests: 68/68 green (repo 미러 · 라이브 양쪽)
- updated: 2026-07-31
