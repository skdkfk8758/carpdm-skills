# ADR 004 — 하네스 리뉴얼 2026-09 (모델 티어·스텝 규율·플랜류 은퇴·페르소나 council)

- Status: Accepted
- Date: 2026-09-14
- Context source: 14일 위임 ledger 실측 + `~/.claude/skills` 전수 카운트

## Context

리뉴얼 직전 14일치 위임 ledger 를 세니 **implementer(opus) 72건 · input 6.5억 토큰**으로
전체 위임 비용의 **84%** 였다. 모든 작업이 같은 티어의 같은 워커로 갔다는 뜻이다.

스킬은 **167종** 중 **80종이 프론트엔드 프리셋**이었다. 목록 비용만 내고 발화되지 않는다.
계획·인계를 문서로 굳히는 스킬(plan·goal·relay·handoff)은 산출물이 곧 재확인 대상이 됐다 —
문서가 코드보다 먼저 낡는다.

ADR 003 이 상시 로딩을 줄였다면, 이번은 **어디에 얼마짜리 모델을 태우는가**와 **한 턴이 얼마나 길어지는가**를 줄인다.

## Decision

### 1. 모델 티어 — 기본 세션은 opus, Fable 은 설계 전용

기본 세션을 Fable → **opus** 로 내리고, Fable 은 `/model fable` 로 들어가는 설계·인터뷰
세션에서만 쓴다. 워커는 성격별로 **haiku / sonnet / opus** 로 나누고, `fixer` 승격 기준을
5조건 → **3조건**(파일 3개 이하 · 인터페이스·데이터 모델·의존성 무변경 · 보안/gitops/삭제 제외)
으로 줄여 단순 변경이 opus 로 새지 않게 했다. 위치: `~/.claude/agents/*.md` · `settings.json`.
Codex 는 기본 **sol/medium**, `AGENTS.md` 재작성.

### 2. 짧은 호흡 — 사용자 입력당 편집 3파일

`guard-step-scope.sh` 가 **사용자 입력당 4개째 파일 편집을 차단**한다. 규율 본문은
`rules-ondemand/step-cadence.md`. 계획을 문서로 쓰는 대신 한 스텝을 작게 잘라 사람이
스텝마다 되돌릴 수 있게 하는 것이 목적이다.

### 3. 플랜 문서류 은퇴

스킬 110종 · 룰 4편 · Codex `plan`·`momus`·`metis` 에이전트 · Codex preflight/router 를
`~/.claude/backups/harness-renewal-2026-09-14/` 로 이동(`MANIFEST.tsv` 172줄).
이 레포에서는 배포 스킬 5종(`deep-plan`·`goal-prompt`·`relay`·`handoff`·`linear-replan`)이
빠져 **15 → 10종**. ADR 은 계획서가 아니라 **목표 지향** 문서로 쓴다.

### 4. 페르소나 council

`persona-{karpathy,torvalds,pocock,hightower,abramov}`(전부 sonnet, 읽기 전용)와 이들을
병렬로 부르는 `council-review`(diff·PR)·`council-research`(주제·기술 선택)를 둔다.
Codex 쪽도 `~/.codex/agents/persona-*.toml` 로 대칭. 시크릿 3건은 `~/.claude/secrets/` 로
이관해 설정 파일에서 뺐다. 프로젝트 온보딩은 `global/templates/project/`.

## Consequences

**얻는 것**: 단순 변경이 sonnet/haiku 로 내려가 위임 비용의 분모가 바뀐다. 한 턴이 짧아져
되돌릴 단위가 작아진다. 리뷰가 한 관점(모델 1개)이 아니라 다섯 관점으로 갈라진다.
스킬 목록이 167 → 59종으로 줄어 라우팅 오발화가 준다.

**잃는 것**:

- **자율 에이전트 장기 WU 파이프라인** — goal-prompt → 자율 실행 → relay 구간 판정의 고리가 끊긴다.
  긴 작업은 이제 사람이 스텝으로 잘라 준다.
- **handoff 문서** — `docs/handoff/` 인계본이 없다. 세션 재개는 Linear 이슈와 커밋 이력으로 한다.
- **Codex preflight 계약** — 실행 전 점검을 스킬이 아니라 `AGENTS.md` 규율로만 보장한다.

## 되살릴 조건

| 대상 | 되살릴 조건 |
|---|---|
| 플랜 문서 스킬 | 스텝 규율로 3회 이상 돌린 뒤 **계획 부재로 인한 재작업**이 실제로 관측되면 |
| `handoff` | 세션 경계에서 맥락 복원 실패가 2회 이상 나면 (Linear+커밋으로 안 되는 사례) |
| Codex `plan`·`momus`·`metis` | Codex 단독 장기 작업이 다시 주 사용 패턴이 되면 |
| 기본 세션 Fable | opus 기본에서 설계 품질 저하가 실제 오판으로 이어지면 |

복구는 `~/.claude/backups/harness-renewal-2026-09-14/MANIFEST.tsv`(172줄, `원경로/백업경로/종류`)의 역방향 복사다. 삭제가 아니라 이동이므로 원본은 그대로 있다.

## Steps (2026-09-14 실행)

- [x] 1. 모델 티어 재배치 — agents 정의·`settings.json`
- [x] 2. 워커 재정의 — `fixer` 3조건, 페르소나 5종 추가
- [x] 3. 스텝 규율 — `guard-step-scope.sh` · `rules-ondemand/step-cadence.md`
- [x] 4. 플랜 문서류 백업 이동 — MANIFEST 172줄
- [x] 5. Codex 대칭 — 기본 sol/medium · `AGENTS.md` 재작성 · persona terra
- [x] 6. 시크릿 3건 `~/.claude/secrets/` 이관 · 프로젝트 템플릿 세트
- [x] 7. `carpdm-skills` 미러 동기화 · 이 ADR · PR
