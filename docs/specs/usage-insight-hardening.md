# Requirements: usage-insight 기반 워크플로 경화(hardening) — rules 3 + 기존수정 2 + 신규 스킬 1

> Crystallized from a deep-interview on 2026-06-04. Final ambiguity: 18% (target ≤ 20%).
> Type: brownfield. Rounds: 5. Status: draft.

## 1. Goal & scope

Claude Code usage insight 리포트(`report-2026-06-04-122918.html`)가 드러낸 실제 마찰(friction)을 — 추측이 아니라 측정된 신호로 — 영속 지침·기존수정·신규 스킬로 전환한다. 핵심 발견: 리포트가 "스킬/에이전트로 만들라"고 부추긴 것 *대부분은 이미 생태계에 존재*(`land`·`skill-creator`·craft `orchestrated`)하거나 rule 한 줄로 족하다. 진짜 신규 가치는 단 하나 — skill-creator eval 의 synthetic-only 빈틈을 메우는 real-env trigger probe.

**In scope:** 글로벌 rule 2개(early-commit, delegated-review watchdog), 프로젝트 rule 1개(authoring 검증), 기존 파일 수정 2개(`craft-core/references/codex-review.md`, `install.sh`), 신규 스킬 1개(real-env eval probe).
**Out of scope:**
- interview-to-ship 자율 파이프라인 신규 스킬 (C4) — deep-interview 라우팅 + craft `orchestrated` + `land` 가 이미 커버; 유일 신규였던 watchdog 은 C2 로 흡수됨.
- `.bak` 자동삭제 hook — 근본 원인(install.sh 가 백업 생성)을 직접 고치므로 hook 불필요.
- 신규 에이전트 — 인터뷰 결과 에이전트가 될 만한 빈틈 없음(C2 watchdog 도 지침으로 충분). 억지로 만들지 않음.

## 2. Topology

Round 0 에서 4개 active 로 고정 → 인터뷰 중 C4 가 C2 로 흡수.

| Component | Status | One-line role |
|-----------|--------|---------------|
| C1 동시성/worktree 안전 | active | uncommitted 노출 시간을 줄여 동시세션 reset 피해 방지 |
| C2 delegated-review 복원력 | active | 위임 리뷰(codex 등) hang/false 에 timeout+fallback+재검증 |
| C3 authoring 검증 | active | carpdm-skills 고유 검증(node --check 함정, real-env eval) |
| ~~C4 interview-to-ship 자율 파이프라인~~ | deferred→C2 | 신규 가치는 watchdog 뿐 → C2 로 흡수, 독립 산출물 불필요 |

## 3. Functional requirements

| ID | Requirement (the system SHALL…) | Priority | Acceptance criteria | Origin |
|----|----------------------------------|----------|---------------------|--------|
| REQ-F-001 | 글로벌 `~/.claude/rules/` 에 early-commit 규율 rule 을 추가한다: "장시간/멀티파일 작업은 즉시 첫 커밋으로 uncommitted 노출을 최소화; 동시세션 reset 위험 시에만 수동 worktree 격리." | Must | rule 파일이 존재하고 (a) early-commit 을 1차 방어로, (b) worktree 를 위험시 수동 보완으로 명시. `_ORDER.txt` 에 등재. | R3 |
| REQ-F-002 | 글로벌 `~/.claude/rules/` 에 delegated-review watchdog rule 을 추가한다: "codex/팀 등 위임 리뷰는 background 로 돌리고 10분 cap 으로 감시; 초과 시 kill → local multi-agent fallback → 결과 독립 재검증." | Must | rule 이 10분 cap, kill 동작, local fallback, 독립 재검증 4요소를 모두 명시. | R2 |
| REQ-F-003 | `~/.claude/skills/craft-core/references/codex-review.md` 에 REQ-F-002 의 watchdog 절차를 codex 호출 지점에 적용한다(background + Monitor 10분 → kill + 수동 리뷰 fallback). | Must | codex-review.md 의 codex 호출 단계에 10분 watchdog + fallback 절차가 명시적으로 박혀 있음. craft 파이프라인이 더 이상 무한 대기하지 않음. | R2 |
| REQ-F-004 | carpdm-skills `rules/project.md` 에 authoring 검증 규칙을 추가한다: "스킬 skeleton 은 `node --check` 로 검증 금지(async wrapper → false 'Illegal return statement'); 대체 검증법 사용. 스킬 eval 은 synthetic 단독 신뢰 금지 — real-env probe 병행." | Must | project.md 에 node --check 금지 사유 + 대체법, real-env eval 병행 규칙이 기술됨. `AGENTS.md` 재생성으로 미러. | R4 |
| REQ-F-005 | `install.sh` 가 기존 동명 설치물을 덮어쓸 때 `.bak-<ts>` 백업을 생성하지 않도록 수정한다(git history 가 안전망). | Must | install.sh 실행 후 `.bak-*` 파일이 생성되지 않음. 기존 동작 대비 백업 생성 코드 제거됨. project.md 의 install.sh 설명도 갱신. | R4 |
| REQ-F-006 | carpdm-skills 컨벤션(`skills/<name>/SKILL.md` + `references/`, 본문 한국어)으로 real-env eval probe 신규 스킬을 저작한다. 스킬은 (a) 설치 후 트리거 매칭 정확도, (b) sibling-skill 경쟁(다른 스킬 오발화)을 둘 다 측정하고, artifact(name-collision 등) 감지 시 재시도하는 eval loop 를 포함한다. | Must | `skills/<name>/` 존재, SKILL.md frontmatter `name`(영어)+`description`(한국어 트리거) 적격, references 에 eval 방법론 기술, 두 측정 축(트리거 정확도 + sibling 경쟁) 명시. README 스킬 표·카운트 갱신(guard-readme-fresh 통과). | R5 |

Priority: MoSCoW. Origin 은 못 박은 인터뷰 라운드.

## 4. Non-functional requirements

| ID | Category | Requirement | Acceptance criteria | Origin |
|----|----------|-------------|---------------------|--------|
| REQ-N-001 | 적합성(scope hygiene) | C3 검증 규칙은 carpdm-skills 고유이므로 글로벌이 아닌 프로젝트 rules 에만 둔다(node --check 는 JS 프로젝트에선 정상 — 글로벌 노이즈 금지). | REQ-F-004 산출물이 `~/.claude/rules/` 가 아니라 `rules/project.md` 에 위치. | R4 |
| REQ-N-002 | 신뢰성/회귀 | install.sh 백업 제거가 멱등성 안전망을 깨지 않아야 한다 — git 추적물은 history 가, 글로벌 미추적 수동편집은 사용자가 인지하도록 문서화. | project.md install.sh 설명이 "백업 미생성, git history 가 안전망" 으로 갱신되고, 미추적 수동편집 리스크가 명시됨. | R4 |
| REQ-N-003 | 적합성 | 신규 스킬(REQ-F-006)은 레포 작성언어 정책 준수 — 본문·description 한국어, `name`/frontmatter 키·식별자 영어. | SKILL.md 가 작성언어 정책(project.md §작성 언어 정책) 통과. | R5 |

## 5. Constraints & assumptions

- **Constraints:**
  - 글로벌 rules 는 `~/.claude/rules/` + `_ORDER.txt` concat 규약을 따른다(knowledge-folders 룰).
  - 신규 스킬은 craft-core 무의존 standalone 가능(eval probe 는 빌드 파이프라인 아님).
  - README guard(guard-readme-fresh)가 신규 스킬 행을 강제 — 같은 PR 에서 README 갱신 필수.
- **Assumptions resolved:**
  - "리포트 제안 대부분이 신규 아티팩트를 요구한다": **반증됨** — 4영역 중 3개가 rule/기존수정으로 수렴, 신규 스킬은 1개뿐(R1~R5).
  - "worktree 자동격리를 기본 ON 으로 원한다": **반증됨** — 이 세션도 in-place 로 떴고, 사용자는 early-commit 우선 + 위험시 수동 worktree 선택(R3).
  - ".bak 은 cleanup hook 으로 해결": **반증됨** — 근본 원인(install.sh 백업 생성) 직접 수정으로 대체(R4).
  - "interview-to-ship 의 핵심은 단계 자동화": **반증됨** — 핵심은 단계 사이 복원력(watchdog)이며 그것은 C2 로 흡수(R1).
- **Residual ambiguity:** REQ-F-006 의 real-env probe 가 *실제로 트리거 매칭을 어떻게 자동 측정*하는지(설치 후 발화 시뮬레이션 메커니즘)는 medium clarity — 구현/plan 단계에서 결정. skill-creator 의 기존 eval 메커니즘 재사용 가능성 검토 필요. 영향 REQ: REQ-F-006.

## 6. Context *(brownfield)*

- **C2 적용점:** `~/.claude/skills/craft-core/references/codex-review.md` — 현재 `codex:rescue` 호출에 시간 가드 없음(리포트: 39분 hang). 보존할 것: 기존 codex 리뷰 산출물 형식; 추가할 것: watchdog+fallback. forge/hunt/renew + deep-plan 4종이 craft-core 절대경로로 결합 → codex-review.md 수정은 4종 모두에 전파(의도된 일관 적용).
- **C3 적용점:** `rules/project.md`(SSOT) → `AGENTS.md` 재생성 미러. `install.sh` 백업 로직(project.md 에 "멱등 — `.bak-<ts>` 백업 후 덮어씀" 으로 명시됨 → 이 문장도 갱신 대상).
- **C1 적용점:** 글로벌 `~/.claude/rules/` 신규 파일 + `_ORDER.txt`. 기존 `subagent-*`/`karpathy-core` 와 충돌 없음(새 관심사).
- **신규 스킬 적용점:** `skills/` 디렉토리 + `README.md` 스킬 표 + 카운트. `install.sh`/`sync.sh` 는 `*/` glob 이라 신규 디렉토리 자동 포함.

## 7. Traceability — clarity trail

| Round | Ambiguity | Targeted dimension | Requirements pinned |
|-------|-----------|--------------------|---------------------|
| 0 | — | topology lock | C1/C2/C3/C4 active |
| 1 | 76% | C4 goal (question-the-question) | C4→C2 흡수 확정 |
| 2 | 70% | C2 goal/형태 (alternatives) | REQ-F-002, REQ-F-003 (10분 cap, 기존수정) |
| 3 | 58% | C1 goal/강도 (assumptions) | REQ-F-001 (early-commit, rule) |
| 4 | 37% | C3 goal/거처 (assumptions) | REQ-F-004, REQ-F-005, REQ-N-001/002 |
| 5 | 22%→18% | C3 criteria + 원요청 충족 (question-the-question) | REQ-F-006, REQ-N-003 |

## 8. Handoff

산출물이 이질적이라 단일 빌드 스킬로 안 묶인다. 권장 분리:

- **REQ-F-006(신규 스킬)** → `/forge` (또는 `skill-creator`). 유일한 greenfield 저작 — 신규 가치 집중. residual ambiguity(probe 측정 메커니즘) 때문에 plan 먼저면 `/deep-plan`.
- **REQ-F-001~005(rule 2 + 프로젝트 rule 1 + 수정 2)** → `/renew` 1회 또는 직접 surgical 편집. 작고 명확(각 1~20줄)이라 풀 파이프라인은 과함 — 직접 편집 권장.

**강도: linear.** 토폴로지는 넓게 시작(4개)했으나 빠르게 수렴, challenge mode 미발동, 잔여 ambiguity 거의 0 → council 불필요. 명확하고 작은 작업.

**Treat this spec as the completed requirements step.** 권장 스킬은 자체 Socratic 인터뷰를 돌리는데 — 건너뛰라. 이 번호 매긴 요구사항을 못 박힌 Phase-1 산출물로 넣고 곧장 plan review 로 가라.
