# linear-register 통합 개편 — to-issues 흡수 + Triage 기본 + dedup/그루핑

> deep-plan 산출 (2026-07-21). 인터뷰 6라운드, 최종 ambiguity 16% (target ≤ 20%).
> 대상: `~/.claude/skills/` 라이브 트리 (carpdm-skills repo 로 ship 미러).

## Goal (testable success criteria)

1. `to-issues` 스킬이 `linear-register` 안으로 흡수된다 — 단일 진입점, 두 모드
   (단건~소수 등록 / plan 분할 등록). `to-issues` 디렉토리·참조는 같은 변경에서 소멸.
2. 모든 신규 이슈가 기본 `state: "Triage"` 로 생성된다 (양 모드 동일).
   Triage 미활성 팀은 팀 기본 state 폴백 + 게이트/보고에 명시.
3. 등록 전 팀 스코프 **미완 이슈**(Triage/Backlog/Todo/In Progress/In Review)와
   신규 이슈를 비교해:
   - **dedup**: 유사 후보를 확인 게이트에 병합 표시, 이슈별 4택
     (그대로 등록 / 스킵 / 기존 이슈 보강 / relatedTo 연결 등록).
   - **그루핑**: 유사 이슈들의 project·label 분포 근거로 신규 이슈의
     project + `area:*` 라벨을 제안. 적합 클러스터 없고 신규 이슈가 응집하면
     **새 프로젝트/라벨 신설 제안** (승인 후에만 생성).

## Scope (IN / OUT)

**IN:**
- `linear-register` SKILL.md 개편 (모드 분기 + Triage + dedup/그루핑 단계)
- references 신규 2개: `plan-split.md` (to-issues 이관), `dedup-grouping.md`
- SPEC.md 개정 (REQ 추가·F-007 개정)
- `to-issues/` 삭제 + 외부 참조 7곳 포인터 교체
- `~/.claude/rules/linear-register-mandatory.md` 단일 진입점으로 개정
- ship 으로 carpdm-skills 미러 반영

**OUT:**
- `linear-groom`/`linear-goal`/`linear-prioritize` 자체 로직 변경 (참조 줄만 교체)
- `guard-linear-register-nudge` 훅 (이름 유지로 무변경)
- 코어 헤딩 계약 변경 (`## 작업 내용`/`## 수용 기준`/`## 추천` — 하류 소비자
  linear-goal·harness 가 의존, 불변)
- 유사도 판정의 수치 임계값/알고리즘화 — 모델 판단 (후보 최대 3건/이슈 표시)

## Files (verified — path : why it changes)

| 경로 | 변경 |
|---|---|
| `~/.claude/skills/linear-register/SKILL.md` (82줄) | 개편 — description 에 to-issues 트리거 흡수, 워크플로에 모드 분기·2.5단계(dedup/그루핑)·Triage 기본 |
| `~/.claude/skills/linear-register/references/plan-split.md` | 신규 — to-issues 의 vertical-slice 규칙·HITL/AFK·quiz·의존순 발행 이관 (`setup-matt-pocock-skills` 의존 줄은 이관하지 않음 — Linear-native) |
| `~/.claude/skills/linear-register/references/dedup-grouping.md` | 신규 — 비교 스코프·게이트 4택·그루핑 제안·신설 제안 규칙 |
| `~/.claude/skills/linear-register/references/recommend-section.md` (L21, L74) | `to-issues` 언급 → "linear-register plan 분할 모드" |
| `~/.claude/skills/linear-register/SPEC.md` | REQ-F-007(to-issues 위임→내부 분할 모드) 개정 + REQ 신규(Triage/dedup/그루핑) |
| `~/.claude/skills/to-issues/` (SKILL.md 90줄 단일) | **삭제** (같은 변경) |
| `~/.claude/rules/linear-register-mandatory.md` | "이슈 생성 진입점 2개 수렴" → 단일 진입점, 표의 to-issues 행 제거 |
| `~/.claude/skills/linear-groom/SKILL.md` L10 | 포인터 교체 |
| `~/.claude/skills/linear-prioritize/SKILL.md` L118 | 포인터 교체 |
| `~/.claude/skills/deep-interview/SKILL.md` L194 | 포인터 교체 |
| `~/.claude/skills/deep-plan/SKILL.md` L181 | 포인터 교체 |
| `~/.claude/skills/deep-interview/references/next-skill-routing.md` L33·L68·L131 | 포인터 교체 |
| `~/Workspace/carpdm-skills/` (미러) | ship 으로 동기 (sync.sh 미러 → PR → CI → 승인 → squash) |

실측 근거: `mcp__linear__save_issue` 는 `state` 파라미터(type/name/ID) 지원 확인,
SSO 팀 `list_issue_statuses` 에 `Triage`(type: triage) 실재 확인.

## Steps (each step → verify)

1. **`references/plan-split.md` 작성** — to-issues Process §3~5 (tracer-bullet
   vertical slice 규칙, HITL/AFK, 분해 프리뷰 quiz, blocker-first 의존순 발행,
   이슈 템플릿의 `## Parent`/`## Blocked by` 확장 헤딩) 이관. 코어 헤딩 계약 문장 유지.
   → verify: 파일 존재 + `vertical`/`HITL`/`Blocked by` grep 히트.
2. **`references/dedup-grouping.md` 작성** — 규칙 고정:
   - 조회: `linear-repo-map.json` 역매핑 팀 → `list_issues` 미완 상태 필터,
     최근 갱신순 상한 100건 (대량 백로그 조회 폭주 방지).
   - dedup: 모델 판단 유사(제목+본문 요지), 이슈당 후보 ≤3건 게이트 표시,
     4택 액션 (등록/스킵/기존 보강=`save_issue` id 지정/`relatedTo` 연결 등록).
   - 그루핑: 유사 이슈 project·label 분포 → 제안 + 근거 이슈 ID 표시.
     응집 클러스터(≥3건 상호 유사) + 기존 적합 프로젝트 없음 → 신설 제안
     (`save_project`/`create_issue_label` 은 승인 후에만 호출).
   → verify: 파일 존재 + `100`/`relatedTo`/`신설` grep 히트.
3. **SKILL.md 개편** —
   - frontmatter description: to-issues 트리거 문구("이 플랜 이슈로 쪼개줘",
     "PRD 티켓으로 나눠줘", "break this spec into tickets" 등) 병합, to-issues
     위임 문장 제거.
   - 워크플로: Step 2 뒤에 **Step 2.5 비교(dedup+그루핑)** 삽입
     (`references/dedup-grouping.md` 포인터), Step 3 게이트에 dedup 후보·그루핑
     제안·state 표시 병합, Step 4 생성에 `state: "Triage"` 기본 + 미활성 폴백.
   - 모드 분기 절: 입력이 plan/spec/PRD 다중 분할이면 `references/plan-split.md`
     경로, 아니면 기존 단건 경로. 경계 절의 to-issues 추천 제거.
   → verify: `grep -c "Triage" SKILL.md ≥ 2`, `grep "plan-split" SKILL.md`,
     `grep "to-issues" SKILL.md = 0`.
4. **SPEC.md 개정** — F-007 을 "plan 분할은 내부 분할 모드로 처리" 로 개정,
   신규 REQ: Triage 기본(폴백 포함)·dedup 게이트 4택·그루핑 제안·신설 승인 게이트.
   → verify: `grep "Triage" SPEC.md` 히트, F-007 문구에 위임 표현 부재.
5. **recommend-section.md L21·L74 교체** → verify: 파일 내 `to-issues` 0회.
6. **외부 참조 7곳 교체** (groom L10 / prioritize L118 / deep-interview L194 /
   deep-plan L181 / next-skill-routing L33·68·131) — 문구는 "plan 분할 →
   `linear-register` (분할 모드)" 형태로.
   → verify: 각 파일 `to-issues` 0회.
7. **`to-issues/` 디렉토리 삭제** → verify: `ls ~/.claude/skills/to-issues` 부재 +
   `grep -rln "to-issues" ~/.claude/skills ~/.claude/rules` = 0 (worktree log 제외).
8. **룰 개정** (`linear-register-mandatory.md`) — "2개로 수렴" 단락·경계 표의
   to-issues 행 제거, 단일 진입점 + 분할 모드 언급.
   → verify: 룰 파일 `to-issues` 0회, "linear-register" 경유 의무 문장 유지.
9. **ship** — sync.sh 미러 → PR → CI → 승인 게이트 → squash 머지.
   → verify: carpdm-skills develop 에 반영 커밋 존재. [사용자 승인 게이트]

## Risks

- **트리거 라우팅 붕괴** — description 병합 시 to-issues 의 영문/국문 트리거 누락되면
  분할 요청이 스킬 미매칭. 대응: 기존 두 description 의 트리거 문구를 전수 병합.
- **dedup 오탐/누락** — 모델 휴리스틱이라 판정 불안정. 대응: 자동 액션 없음 — 항상
  게이트 표시 + 사용자 선택 (R2 결정). 오탐 비용 = 게이트 한 줄, 누락 비용 = 현행과 동일.
- **조회 폭주** — 팀 미완 이슈 수백 건이면 비교 비용 증가. 대응: 상한 100건 + 상태 필터.
- **하류 계약 파손** — linear-goal/harness 가 코어 헤딩·`[AUTO]/[HUMAN]` 마커 소비.
  대응: 템플릿 헤딩 불변 (Scope OUT 고정).
- **SKILL.md 비대** — 300줄 훅 경고선. 대응: 신규 로직은 references 2파일로 분리,
  SKILL.md 는 포인터만.

## Security surface

- 외부 write = Linear (이슈·관계·프로젝트/라벨 신설). 전부 기존 확인 게이트 뒤 —
  신설(프로젝트/라벨)도 승인 후에만 호출 (REQ-N-002 연장).
- AI disclaimer 줄 전 본문 유지. secret/PII 표면 없음 (이슈 본문은 사용자 제공 내용).

## YAGNI (deletions in this change)

- `~/.claude/skills/to-issues/` 전체 (SKILL.md 90줄) — 같은 변경에서 삭제.
- to-issues 의 `setup-matt-pocock-skills` 의존 줄 — 이관하지 않음 (Linear-native).
- `linear-register-mandatory.md` 의 "2-진입점 수렴" 단락 + 경계 표 to-issues 행.
- SKILL.md·recommend-section.md 의 to-issues 위임 문장 전부.

## Acceptance / Eval

1. [AUTO] `grep -rln "to-issues" ~/.claude/skills ~/.claude/rules` = 0 — 예외 2종:
   ① `linear-register-workspace/` 스냅샷·로그(휘발), ② linear-register SKILL.md
   frontmatter description 의 "(구 to-issues 흡수)" 1회(의도적 — 구 이름 기억
   사용자의 트리거 라우팅 보조). 위임/라우팅 포인터로서의 to-issues 참조는 0.
2. [AUTO] SKILL.md 에 `state: "Triage"` 기본 + 미활성 폴백 문장 + Step 2.5
   (dedup/그루핑) + plan 분할 모드 분기 존재 (grep).
3. [AUTO] 양 모드 이슈 템플릿에 코어 헤딩 3종 + `[AUTO]`/`[HUMAN]` 마커 유지 (grep).
4. [AUTO] 룰 파일이 단일 진입점을 기술하고 to-issues 행 부재.
5. [HUMAN] 단건 실전: 기존 유사 이슈 있는 제목으로 등록 시도 → 게이트에 dedup
   후보(≤3)+그루핑 제안(근거 ID 포함) 표시 → 승인 → Linear 에서 state=Triage 확인.
6. [HUMAN] 분할 실전: plan 문서 1건 → 슬라이스 프리뷰 quiz → 승인 → 의존순 발행,
   전건 Triage + 관계 세팅 확인.
7. [HUMAN] ship 머지 완료 (carpdm-skills develop 반영).
