# probe 스킬 — real-env 트리거 eval (REQ-F-006)

> deep-plan 산출 → forge Phase 2(codex) 반영본. 입력: `docs/specs/usage-insight-hardening.md` REQ-F-006/REQ-N-003.
> 비-UI(스킬 저작) → HTML 시안 없음. 스킬명 `probe` 확정, eval 엔진 D1=B(자체 경량 standalone) 확정.

## Goal (testable success criteria)

carpdm-skills 컨벤션의 신규 스킬 `probe` 를 저작해, 스킬 트리거를 **실제 설치 상태**(`~/.claude/skills/` 에 형제들과 함께 깔린 상태)에서 측정한다. 산출:
- (a) **트리거 매칭 정확도** — 대상 스킬이 should-trigger query 에서 실제 발화한 비율
- (b) **sibling-skill 경쟁** — query 별로 *실제 발화한 모든 스킬*을 캡처해, 대상이 아닌 형제가 가로챈 경우를 드러냄

성공 = 실제 설치 환경에서 query 세트를 돌려 (a)(b)를 **outcome class 별로 분리**해 보고하고, 인프라 실패(timeout/error)와 측정 artifact 를 정상 점수와 구분한다.

## Scope (IN / OUT)

**IN:** 신규 스킬 `skills/probe/`(SKILL.md + references/methodology.md + scripts/real_env_probe.py); 실제 설치 상태에서 `claude -p` stream-json 으로 발화 스킬 캡처; outcome 분류 + 이중 측정 + 진단 보고; 환경 snapshot; README 표·카운트, install.sh done echo.

**OUT:** description 자동개선 루프(skill-creator `improve_description.py` 가 함); HTML 벤치마크 뷰어(skill-creator `eval-viewer` 재사용); 즉시묶음 REQ-F-001~005(별도 완료, 커밋 7d3a734).

## Files (verified — path : why it changes)

기존(조사로 검증 — 참조용, 수정 안 함):
- `~/.claude/plugins/.../skill-creator/scripts/run_eval.py` : stream-json 파싱의 **참조 계약**(B6). line 129-168 의 stream_event/assistant tool_use 파싱(`Skill.input.skill`, `Read.input.file_path`)이 sibling 캡처가 가능함을 입증하는 근거. 단 격리-주입이라 sibling 측정엔 부적합 → 신규 작성.

신규(생성 대상):
- `skills/probe/SKILL.md` : 진입점(name 영어 + description 한국어 트리거, 본문 한국어).
- `skills/probe/references/methodology.md` : 두 측정축, eval set 포맷, outcome 분류, skill-creator eval 과의 차이, artifact 진단 원리.
- `skills/probe/scripts/real_env_probe.py` : 실제 설치 상태 `claude -p` 실행 + 발화 스킬 캡처 + outcome 분류 + snapshot.
- `skills/probe/scripts/test_parser.py` : 저장된 raw stream fixture 에 대한 파서 단위 테스트(B2/B6).
- `skills/probe/references/fixtures/` : 캡처한 raw stream-json 샘플(outcome class 별).
- `README.md` : 스킬 표 행 + 카운트(구현 시점 실제 `skills/` 개수로 산정 — 하드코딩 금지, B-NB1).
- `install.sh` : done echo 목록·카운트 갱신(표기만).

## codex review — round 1 (verdict + 반영)

codex 적대 리뷰(2026-06-04, ~2분, watchdog 10분 내 완료) 8 BLOCKING / 5 NON-BLOCKING. 모두 반영:

- **B1/B6 sibling attribution 미증명** → Step 1 **스파이크**(구현 전 raw stream 캡처 + 추출 규칙 확정) 신설. fixture + 파서 테스트로 계약 고정.
- **B2 verify 가 핵심 주장 미증명** → Acceptance 를 outcome class 별 실제 run + fixture 파서 테스트로 강화.
- **B3 artifact 감지/retry 누락(REQ-F-006 갭)** → Step 5 진단 로직 + Acceptance 4 신설.
- **B4 환경 드리프트** → Step 4 시작/끝 snapshot(skill 이름 + SKILL.md 해시), 변하면 run invalid.
- **B5/B7 outcome 뭉갬 / error 미분리** → outcome 스키마(아래) + Step 3.
- **B8 untrusted eval-set** → Security surface 재작성.
- NON-BLOCKING 1~5 → README 카운트 동적 산정, D2 확정, cost 기본값(worker 소수·dry-run·예상 세션 수 경고), per-query 변동 보고, frontmatter parse check.

## Outcome 스키마 (B5/B7 — 측정의 핵심)

query 당 결과는 단일 "발화 스킬명"이 아니라:
```
{ query, should_trigger, target,
  triggered_skills: [],        # 발화한 모든 스킬(순서 보존)
  target_triggered: bool,
  sibling_triggered: [],       # 대상 아닌 발화 스킬
  unknown_skill_events: [],    # Skill/Read 인데 스킬명 정규화 실패
  state: "target_only" | "sibling_only" | "target_plus_sibling" | "none" | "error" | "timeout" | "parse_error" }
```
정확도·sibling 집계는 `state ∈ {error,timeout,parse_error}` 를 **제외**(invalid)하고 산정. invalid 는 별도 보고.

## Steps (each step → its verify check)

1. **스파이크(구현 전 계약 고정, B1/B6).** 알려진 query 3종(`deep-interview` 확실 트리거 / zero-trigger / 모호한 sibling 트리거)으로 `claude -p --output-format stream-json --include-partial-messages` 를 실제 실행해 raw stream 을 `references/fixtures/` 에 저장. 추출 규칙 확정: `Skill.input.skill`, `Read.input.file_path`→스킬명 정규화(경로에서 `skills/<name>/` 추출), 정규화 실패 시 unknown, multiple events 는 모두 기록. → verify: 3 fixture 각각에서 기대 triggered_skills 가 규칙으로 추출됨.
2. `real_env_probe.py` 골격 — eval set(JSON: `{query, should_trigger, target}`) 입력, query 당 `claude -p` 실행(CLAUDECODE env 제거, timeout, harmless cwd), stream 파싱은 Step 1 규칙. → verify: 단일 query 실행이 outcome 스키마 dict 반환.
3. outcome 분류 + error/timeout/parse 분리(B7) — claude -p 비정상 종료/timeout/JSON 파싱 실패를 각 state 로, no-trigger 와 구분. → verify: timeout(인위적 짧은 timeout)이 `state:"timeout"` 으로, 정상 미발화가 `state:"none"` 으로 분류.
4. 환경 snapshot(B4) — run 시작/끝에 `~/.claude/skills/*/SKILL.md` 이름+해시 캡처, 다르면 결과를 invalid 표기하고 snapshot 을 결과에 포함. → verify: 중간에 파일 변경 시뮬레이트하면 invalid 플래그.
5. artifact 진단/retry(B3) — 전 query no-event(파서 스키마 깨짐 의심), all-false/all-true 의심 패턴, 0 recognizable event 면 점수 대신 진단 emit + 선택적 retry. → verify: fixture 로 스키마 깨짐 주입 시 진단 출력(정상 0점 아님).
6. 집계·보고 — (a) 정확도 (b) sibling 분포 + per-query 변동(B-NB4) + invalid/예상 세션 수 경고(B-NB3). → verify: 다회 run eval set 에서 (a)(b)+변동 출력.
7. `test_parser.py` — fixture 대상 파서 단위 테스트(claude 호출 없음, 빠름·결정적). → verify: `python skills/probe/scripts/test_parser.py` green.
8. `methodology.md` + `SKILL.md`(한국어, 트리거 description) — frontmatter name 영어. → verify: frontmatter parse check 가 `name`/`description` 존재 + 금지된 번역 키 없음 확인(REQ-N-003, B-NB5). node --check 미사용.
9. `README.md` 표 행 + 카운트(`skills/` 실제 개수 산정), `install.sh` echo. → verify: guard-readme-fresh 차단 없음.

## Risks

- **비용/시간:** query × runs 회 `claude -p`. 기본 worker 소수 + dry-run(세션 수만 출력) + 실행 전 예상 세션 수 경고로 완화(B-NB3).
- **재현성:** real-env 는 설치 세트 의존 — snapshot(Step 4)으로 *통제*하되 절대 기준선 아님을 methodology 명시.
- **CLI 포맷 결합:** stream-json 파싱은 `claude` CLI 스키마 의존(run_eval.py 동일 리스크). Step 1 fixture + Step 5 smoke(0 event 시 거부)로 silent false 방지(B6).

## Security surface

- `real_env_probe.py` 가 `claude -p` subprocess 실행. **eval query 는 untrusted prompt 로 취급(B8)** — query 가 도구 호출·파일 읽기·repo 변경을 유발할 수 있음(argv 는 shell injection 만 막지 prompt/tool abuse 는 못 막음). 완화: harmless cwd(임시 빈 디렉토리)에서 실행, CLI 가 지원하면 도구 제한/제한 권한 모드, timeout 강제, stderr 캡처.
- subprocess env 에서 `CLAUDECODE` 제거 외 변조 없음. 외부 네트워크 발신 없음(로컬 CLI).
- 임시 command 주입 없음(run_eval 의 `.claude/commands/` 방식과 달리 기존 설치 그대로 사용 → name-collision 원천·정리 부담 제거).

## YAGNI (deletions this change would make)

- 신규 스킬이라 삭제 대상 없음. **재구현 금지**(OUT): description improver, HTML 뷰어, train/test split — skill-creator 제공분 복제 안 함.

## Acceptance (numbered, single, checkable conditions)

1. eval set 의 should-trigger query 에서 대상 스킬 발화율(정확도)을 수치로 출력하되, invalid(error/timeout/parse) run 을 제외하고 별도 보고한다.
2. query 별로 `triggered_skills`/`sibling_triggered` 를 캡처해, 대상 아닌 형제가 가로챈 경우를 outcome state 와 함께 보고한다.
3. outcome 을 `target_only/sibling_only/target_plus_sibling/none/error/timeout/parse_error` 로 분류한다(단일 "발화 스킬명"으로 뭉개지 않음).
4. 파서 스키마 깨짐·0 recognizable event·all-false 의심을 정상 0점이 아니라 **진단**으로 emit 한다(REQ-F-006 artifact 감지).
5. run 시작/끝 설치 스킬 snapshot 을 캡처하고, 변하면 결과를 invalid 표기한다.
6. `test_parser.py` 가 fixture 에 대해 green(claude 호출 없이 결정적).
7. skill-creator 플러그인 미설치에서도 독립 동작(D1=B).
8. `README.md` 표·카운트 갱신 → guard-readme-fresh 통과.
9. SKILL.md frontmatter parse check: name 영어 / description·본문 한국어(REQ-N-003).

## 다음 (이 plan 의 범위 밖)

forge Phase 3(dynamic TDD, opus)이 이 plan 을 계약으로 구현. Step 1 스파이크가 첫 task(계약 고정), 이후 outside-in TDD.
