---
name: linear-register
description: >-
  Linear 이슈 등록의 단일 진입점 — 단건~소수 네이티브 등록(Linear MCP)과 plan/spec/PRD
  다중 슬라이스 분할 등록(구 to-issues 흡수)을 모드 분기로 처리한다. 등록 전 기존 백로그와
  dedup·그루핑 대조(유사 이슈 게이트 표시 + project/라벨 배치 제안), 기본 state=Triage 등록,
  각 이슈에 적응형 `## 추천`(적합 스킬/에이전트) + 의존 체인이면 Linear 관계 세팅·전방
  포인터·kickoff 프롬프트를 함께 박는다. "리니어에 이슈 등록", "티켓 만들어줘", "이거 이슈로
  올려줘", "티켓 따줘", "까먹지 않게 적어둬", "이슈로 남겨놔", "TODO 로 올려놔", "file this as
  a Linear issue", 그리고 "이 플랜 이슈로 쪼개줘", "PRD 티켓으로 나눠줘", "작업 단위로 분할해서
  등록해줘", "슬라이스로 나눠줘", "이제 이슈로 만들어줘"(deep-plan/deep-interview 직후),
  "break this spec into tickets", "convert the plan into issues" — 대화 중 발견된 후속 작업
  포함, 'linear-register' 란 말이 없어도 트리거. 티켓 자율 빌드는 linear-goal, 기존 백로그
  재배치·보강은 linear-groom.
---

# linear-register

Linear 이슈 등록의 **단일 진입점**. 단건 등록과 plan 분할 등록을 모드로 나눠 처리하고,
각 이슈에 **다음 행동 가이드**(적합한 스킬/에이전트 추천 + 체인 전방 포인터)를 등록
시점에 함께 박는다. 등록과 "그래서 뭘로 이어가나" 사이의 끊김을 없앤다.
전체 요구사항: [SPEC.md](SPEC.md).

## 경계 (먼저 확인)

- 티켓 **자율빌드** → `linear-goal`. 기존 백로그 **재배치/보강** → `linear-groom`.
- 이 스킬은 이슈 **생성** 전담 — 단건이든 plan 분할이든 여기.

## 모드 판정 (진입 직후)

| 입력 | 모드 |
|---|---|
| 이슈 아이디어 1~소수 (대화 발견 후속 작업 포함) | **단건 모드** — 아래 워크플로 그대로 |
| 다단계 plan/spec/PRD 문서 (deep-plan 산출·설계 문서) | **분할 모드** — [references/plan-split.md](references/plan-split.md) 를 읽어 §1~4(vertical slice 초안 + 분해 quiz)를 먼저 돌리고, 승인된 슬라이스로 아래 Step 2.5 부터 합류 |

## 워크플로

### 1. 타깃 팀/프로젝트 해소 (REQ-F-002/003)

- 현재 repo (`git rev-parse --show-toplevel`, worktree 면 메인 repo) → `~/.claude/linear-repo-map.json` **역매핑**. `projectExceptions[].repo` 우선, 없으면 `teamRoutes[].repo` prefix 매칭 → `teamId`. (`linear-dispatch.md` 룰과 동형.)
- repo 가 맵에 없음 → **"어느 팀?" 사용자에게 질의**. 추측 등록 금지.
- 프로젝트는 Step 2.5 그루핑 제안이 1차 근거 — 제안 근거가 없으면 그 팀의 `mcp__linear__list_projects` 에서 고르거나 사용자 확인 (없으면 "프로젝트 없음" 명시).

### 2. 이슈 초안 작성 (REQ-F-005/006/011)

각 이슈 본문을 아래 **통합 템플릿**(register 표준 — linear-groom 도 같은 코어 헤딩 `## 작업 내용`/`## 수용 기준` 으로 수렴)으로. 수용 기준은 `[AUTO]`/`[HUMAN]` 마커를 단다(linear-goal 자율/사람 게이팅). `## 배경`·`## 범위 밖`·`> 출처:` 는 조건부(해당될 때만). **`## 추천`** 섹션이 핵심 — 생성 규칙은 [references/recommend-section.md](references/recommend-section.md) §A 를 읽어 따른다(SSOT, linear-groom 과 공유). 요지: 글로벌 스킬/에이전트 우선(모델 판단, 시작 매핑은 anchor 금지) → 프로젝트 로컬 포인터 부차(타repo 안 읽음, REQ-N-003). **UI/프론트엔드 이슈면** 같은 파일 §C(시안 선행 컨벤션 — 본문에 한 줄, 시안 생성은 착수 시점)도 적용한다. 분할 모드는 plan-split.md 의 확장 헤딩(`## Parent`/`## Blocked by`)을 추가로 쓴다.

### 2.5. Dedup + 그루핑 대조 (등록 전 필수)

[references/dedup-grouping.md](references/dedup-grouping.md) 를 읽어 따른다(SSOT). 요지:
팀 미완 이슈(최근 갱신순 ≤100건, Done·Canceled 제외)를 조회해 ① 이슈별 유사 후보
≤3건 판정(모델 판단, 자동 액션 없음) ② 유사 이슈들의 project·`area:*` 분포 근거로
배치 제안(응집 클러스터 + 기존 적합 없음 → 신설 제안). 결과는 Step 3 게이트에 병합
표시 — 유사 후보 있는 이슈는 이슈별 4택(등록/스킵/기존 보강/relatedTo 연결 등록).

### 3. 확인 게이트 — 쓰기 전 필수 (REQ-F-004, REQ-N-002)

`save_issue`(생성 = `id` 없이) **호출 전** 반드시 제시하고 대기. **단일 승인 게이트는 `AskUserQuestion`**(승인 / 거부+피드백 선택지)으로 구조화해 응답 파싱을 견고하게 한다. 게이트에는 dedup 후보·배치 제안·state 를 병합 표시한다(포맷: dedup-grouping.md §4):

> 등록 예정: **<팀>** / **<프로젝트>** / **state=Triage** / 이슈 **N건** — [제목 + 유사·배치 표시]. 진행?

사용자가 "바로 등록"이라 명시했으면 게이트 스킵(dedup 후보가 있으면 그 사실만 한 줄 보고). 그 외엔 승인 없이 쓰기 금지. 프로젝트/라벨 **신설** 제안이 승인에 포함될 때만 `save_project`/`create_issue_label` 호출.

### 4. 생성 + 체인 (REQ-F-001/008/009/010)

- `mcp__linear__save_issue`(**`id` 없이 = 생성**, `title`+`team` 필수) 로 생성. **기본 `state: "Triage"`** — 양 모드 동일. 팀에 Triage 미활성(`list_issue_statuses` 에 type `triage` 부재 또는 생성 에러)이면 `state` 생략(팀 기본)으로 폴백하고 그 사실을 보고에 명시. 사용자가 게이트에서 다른 state 를 지정하면 그것이 우선.
- **모든 생성 이슈에 `project` + `type` 라벨(bug/feature/chore 등) + `area:*` 라벨(9종) 필수 부착** — 배치는 Step 2.5 제안이 1차 근거, 근거 없고 `area` 판별 불가면 추측 말고 사용자에게 질의(`feedback_linear_label_on_create` 실측: 라벨 누락 이슈는 team+area 스코프 조회에서 유실). 우선순위(`priority` 0-4)는 이슈 타입상 명백할 때만 설정.
- **의존 체인이면**: 같은 `save_issue` 호출의 `blocks`/`blockedBy`/`relatedTo`/`parentId`(append-only)로 Linear 네이티브 관계를 세팅하고, 각 이슈(마지막 제외)에 [references/recommend-section.md](references/recommend-section.md) §B 의 `## 다음 작업`(전방 포인터 + kickoff 프롬프트)을 심는다. 분할 모드는 blocker 먼저 의존순 발행(plan-split.md §5).
- Step 2.5 에서 "기존 보강" 선택된 이슈는 신규 생성 대신 `save_issue`(id=기존)로 병합, "연결 등록" 은 생성 + `relatedTo` 세팅.
- 종료 응답에 **첫(또는 다음) 실행 가능 이슈의 kickoff 프롬프트**를 즉시 복사 가능하게 제시.

## 이슈 본문 템플릿

```markdown
## 배경                ← 비trivial 이슈만 (trivial 생략)
<왜 이 작업이 필요한가 — 1~2문장>

## 작업 내용
<무엇을 — 동작 중심, 파일경로 지양>

## 수용 기준
- [ ] [AUTO] <자동 검증 — 테스트/타입체크/특정 동작>
- [ ] [HUMAN] <사람 검증 — 시각확인/운영 apply 등>

## 범위 밖              ← 있을 때만
- <이 이슈에서 안 하는 것>

## 추천
- **권장**: `/<skill>` — <왜 이게 맞는지 1줄>
- 대안: `/<skill>` / `<agent>`
- 그 repo 로컬 스킬/에이전트(`.claude/skills`)도 확인.

## 다음 작업           ← 체인일 때만
다음: <next-id> · 시작 프롬프트:
```
<붙여넣기용 kickoff 프롬프트>
```

> 출처: <genesis — spike/리포트/plan/메모리 경로, 있을 때만>
> AI 가 등록·작성
```

**조건부 섹션 규칙**: `## 배경`(비trivial 만) · `## 범위 밖`(YAGNI 경계가 있을 때만) ·
`## 다음 작업`(체인일 때만) · `> 출처:`(genesis 가 있을 때만 — spike·리포트·plan·메모리).
없으면 그 섹션 통째 생략 — 빈 헤딩 남기지 말 것. `## 작업 내용`·`## 수용 기준`·`## 추천` 은 항상.
분할 모드 확장 헤딩(`## Parent`·`## Blocked by`)은 plan-split.md 규칙.
**수용 기준은 `[AUTO]`/`[HUMAN]` 마커 필수** — linear-goal 이 이 마커로 자율/사람 검증을
가른다(`acceptance-criteria-gate`). AI disclaimer 줄은 **모든** 본문/코멘트에 부착 (REQ-F-011).

## 검증

- 게이트 승인 전 `save_issue`(생성)·`save_project`·`create_issue_label` 호출 0회 · 생성 이슈마다 `## 추천` + disclaimer 존재 · 기본 state=Triage(미활성 팀은 폴백 보고) · dedup 대조 수행(상한 초과 시 "최근 100건 기준" 명시) · 체인이면 Linear 관계 세팅됨 + 각 이슈 전방 포인터 · 종료 응답에 kickoff 프롬프트 1개.
