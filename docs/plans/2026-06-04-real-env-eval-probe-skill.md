# real-env eval probe 스킬 (REQ-F-006)

> deep-plan 산출. 입력: `docs/specs/usage-insight-hardening.md` REQ-F-006 (Phase-1 완료물).
> 비-UI(스킬 저작) → HTML 시안 없음. 빌드는 이 문서 범위 밖 — plan 까지만.

## Goal (testable success criteria)

carpdm-skills 컨벤션의 신규 스킬을 저작해, 스킬 트리거를 **실제 설치 상태**(`~/.claude/skills/` 에 형제 스킬들과 함께 깔린 상태)에서 측정한다. skill-creator eval 의 격리-주입 빈틈을 메워 두 가지를 산출한다:
- (a) **트리거 매칭 정확도** — 대상 스킬이 should-trigger query 에서 실제로 발화하는 비율
- (b) **sibling-skill 경쟁** — should-not-trigger(또는 발화 실패) query 에서 *어느 형제 스킬이 가로챘는지* 캡처

성공 = 실제 설치 환경에서 query 세트를 돌려 (a)(b)를 함께 보고하고, false 0/100 같은 격리-주입 artifact 를 구조적으로 회피한다.

## Scope (IN / OUT)

**IN:**
- 신규 스킬 디렉토리 1개(`skills/<name>/`): SKILL.md + references + 경량 측정 스크립트.
- 실제 설치 상태에서 `claude -p`(stream-json)로 발화 스킬을 캡처하는 probe 로직.
- 트리거 정확도 + sibling 경쟁 이중 측정 + 결과 보고.
- README 스킬 표·카운트, install.sh done echo 갱신(guard-readme-fresh 통과).

**OUT:**
- description 자동개선 루프 — skill-creator `improve_description.py`/`run_loop.py` 가 이미 함. probe 는 *측정*만, 개선은 기존 도구나 수동에 위임.
- HTML 벤치마크 뷰어 — skill-creator `eval-viewer` 재사용 가능, 재구현 안 함.
- 즉시묶음(REQ-F-001~005) — 별도 완료됨(커밋 7d3a734 + 글로벌 rules).

## Files (verified — path : why it changes)

기존(조사로 검증됨 — 참조용, 수정 안 함):
- `~/.claude/plugins/.../skill-creator/scripts/run_eval.py` : stream-json trigger 감지 기법의 참조 출처(복제 아님, 기법만 차용). 격리-주입 방식이라 sibling 측정엔 부적합 — 그래서 신규 작성.
- `~/.claude/plugins/.../skill-creator/scripts/run_loop.py` : OUT 근거(개선 루프 이미 존재).

신규(생성 대상):
- `skills/<name>/SKILL.md` : 스킬 진입점(frontmatter name 영어 + description 한국어 트리거, 본문 한국어).
- `skills/<name>/references/methodology.md` : 두 측정축(트리거 정확도/sibling 경쟁) 방법론 + eval set 포맷.
- `skills/<name>/scripts/real_env_probe.py` : 실제 설치 상태에서 `claude -p` 실행, 발화 스킬 캡처.
- `README.md` : 스킬 표 행 추가 + 카운트(13→14). guard-readme-fresh 차단 회피.
- `install.sh` : done echo 의 스킬 목록·카운트 갱신(기능 영향 없음, 표기만).

## 핵심 설계 결정 (plan 추천 — 사용자 확정 필요)

### D1: eval 엔진 — 자체 경량 스크립트 (추천: B)

| 안 | 내용 | trade-off |
|---|---|---|
| A | skill-creator `run_eval.py` 를 import/호출 + real-env wrapper | DRY. 단 plugin 절대경로 의존(cache/marketplace 이중 경로로 불안정) — craft-core 절대경로 결합의 fragility 교훈과 동일 리스크 |
| **B (추천)** | 자체 경량 `real_env_probe.py` — `claude -p stream-json` 직접, 설치 상태 발화 캡처 | standalone(imprint/deep-interview 패턴 일치). 핵심 로직(설치 상태에서 *어느* 스킬 발화 캡처)이 run_eval 의 격리-주입과 정반대라 어차피 재사용분이 적음. stream 파싱 ~100줄 복제가 유일 비용 |
| C | 순수 procedural 마크다운 — Claude 가 직접 `claude -p` 던지고 관찰 | 스크립트 0. 단 20 query 병렬 불가, 측정 정밀도·재현성 낮음 |

**추천 B 근거:** real-env 측정은 run_eval 의 설계 전제(스킬 1개 격리)와 충돌한다 — 재사용해도 핵심을 새로 써야 한다. plugin 경로 의존(A)은 이 레포가 craft-core 에서 이미 겪는 절대경로 fragility 를 하나 더 늘린다. C 는 병렬·정밀도에서 spec 의 "자동 측정" 요건에 못 미친다.

### D2: 스킬명 (추천: `probe`)

carpdm 스킬명은 한 단어(forge/hunt/renew/land/summon/imprint/sweep). 후보: `probe`(추천, 간결·측정 함의) / `trial` / `proof`. description 이 "스킬 트리거 real-env eval" 을 명시하므로 이름 자체는 짧게. **확정 전까지 plan 은 `<name>` 으로 둠.**

## Steps (each step → its verify check)

1. D1·D2 확정(사용자) → verify: 스킬명·엔진 방식 결정됨.
2. `skills/<name>/scripts/real_env_probe.py` 작성 — eval set(JSON: `{query, should_trigger, target}`) 입력, 각 query 를 실제 설치 상태에서 `claude -p --output-format stream-json` 실행, 발화한 스킬명을 stream event(Skill/Read tool_use)에서 캡처 → verify: 알려진 query(예: "interview me about X")로 돌려 `deep-interview` 가 잡히는지 실측.
3. sibling 경쟁 집계 — should_trigger=true 인데 대상 미발화 시 *실제 발화 스킬* 기록, should_trigger=false 시 발화한 형제 분포 출력 → verify: 일부러 모호한 query 로 가로채기 캡처 확인.
4. `references/methodology.md` — 두 측정축 정의, eval set 포맷, skill-creator eval 과의 차이(격리 vs real-env), false 0/100 artifact 회피 원리 → verify: (a)(b) + 차이 명시.
5. `SKILL.md` 본문(한국어) + frontmatter(name 영어, description 한국어 트리거 — undertrigger 설계, 형제 스킬과 트리거 경쟁 회피) → verify: 작성언어 정책(project.md) 통과, node --check 미사용(python 스크립트라 무관).
6. `README.md` 스킬 표 행 + 카운트(13→14), `install.sh` done echo → verify: `bash .claude/hooks/guard-readme-fresh.sh` 또는 PR 생성 시 차단 없음.
7. 설치(`bash install.sh`) 후 probe 1회 자기검증 → verify: eval set 으로 (a)(b) 보고 출력.

## Risks

- **비용/시간:** query 당 `claude -p` 1회 × runs_per_query. 20 query × 3 = 60 세션. 병렬(ProcessPoolExecutor)로 완화하나 토큰·시간 비용 실재 — eval set 크기 가이드 필요.
- **재현성:** real-env 는 사용자 실제 스킬 세트에 의존 → 환경마다 결과 다름. 이건 *의도된* 특성(real-env 가 목적)이나 절대 기준선이 아님을 methodology 에 명시.
- **CLI 출력 포맷 결합:** stream-json 파싱은 `claude` CLI 출력 스키마에 의존. CLI 변경 시 깨짐 — run_eval.py 도 같은 리스크를 짐(참조처 명시로 추적 가능하게).
- **중첩 실행:** `claude -p` 를 Claude Code 세션 안에서 실행 — run_eval.py 처럼 `CLAUDECODE` env 제거 필요(미제거 시 guard 충돌).

## Security surface

- `real_env_probe.py` 가 `claude -p` subprocess 실행. query 는 사용자 제공 eval set(신뢰 입력). 외부 네트워크 발신 없음 — 전부 로컬 CLI.
- 임시 파일 없음(run_eval 의 `.claude/commands/` 주입과 달리 real-env 는 기존 설치 그대로 사용 → 정리 부담·name-collision 원천 제거).
- subprocess env 에서 `CLAUDECODE` 제거 외 환경 변조 없음.

## YAGNI (deletions this change would make)

- 신규 스킬이므로 삭제 대상 없음. 단 **재구현 금지** 목록(OUT 과 동일): description improver, HTML 뷰어, train/test split — skill-creator 가 이미 제공하므로 probe 에 복제하지 않는다.

## Acceptance (numbered, single, checkable conditions)

1. `skills/<name>/` 설치 후 eval set 의 should-trigger query 에서 대상 스킬 발화율(트리거 정확도)을 수치로 출력한다.
2. should-not-trigger(또는 대상 미발화) query 에서 *실제 발화한 형제 스킬명*을 캡처해 보고한다(sibling 경쟁).
3. (a) 트리거 정확도와 (b) sibling 경쟁 분포를 한 결과에 함께 낸다.
4. skill-creator 플러그인 미설치 상태에서도 독립 동작한다(D1=B 시).
5. `README.md` 스킬 표·카운트가 갱신되어 guard-readme-fresh 를 통과한다.
6. SKILL.md 가 레포 작성언어 정책(name 영어 / 본문·description 한국어)을 지킨다.

## 다음 (이 plan 의 범위 밖)

빌드하려면 `/forge` 에 이 plan + spec REQ-F-006 을 Phase-1 완료물로 넘긴다(재인터뷰 금지, 곧장 plan review→TDD). D1·D2 확정이 선행.
