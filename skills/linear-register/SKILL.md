---
name: linear-register
model: sonnet
description: >-
  Linear 이슈 등록의 단일 진입점 — 단건~소수 네이티브 등록(Linear MCP)과 plan/spec/PRD
  다중 슬라이스 분할 등록(구 to-issues 흡수)을 모드 분기로 처리한다. 등록 전 기존 백로그와
  dedup·그루핑 대조(유사 이슈 게이트 표시 + project/라벨 배치 제안), 기본 state=Backlog 등록,
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
- **이슈 본문은 사람이 읽는 짧은 요약이다** — 착수 직전의 상세 플래닝은 이슈가 아니라
  별도 단계(빌드 스킬의 Phase 1, `deep-plan`)의 몫이다. 본문에 설계 문서를 담지 않는다.

## 실행 런타임 — codex CLI 위임 (Claude Code 전용)

Claude Code 에서 트리거되면 **등록 실행을 codex CLI 로 위임**한다 — 등록 에이전트만
codex 이고 로직은 동일(`~/.codex/skills/claude-linear-register/` = 본 스킬 verbatim 미러).
codex 세션이 미러로 본 스킬을 읽는 경우 이 섹션은 스킵한다 — 자신이 실행 주체다.

- **전제 감지**: `command -v codex` + `codex mcp get linear`(enabled) 둘 다 성공해야 위임.
  하나라도 실패 → 이 섹션 무시하고 아래 네이티브 워크플로 진행(위임은 증강이지 게이트
  아님) + 폴백 사실 한 줄 보고.
- **게이트는 Claude 쪽 프록시** — `codex exec` 는 비인터랙티브라 확인 게이트를 codex
  안에서 돌릴 수 없다. 2-call 프로토콜:
  1. **초안 call**: `codex exec --skip-git-repo-check "<사용자 요청 + 발견 경위·대상 repo
     경로 등 필요 컨텍스트>. claude-linear-register 스킬로 Step 1~2.5 를 수행하되 확인
     게이트(Step 3) 직전에 멈춰라. 쓰기 도구(save_issue/save_project/create_issue_label)
     호출 금지. 최종 메시지로 미리보기만 출력: 팀/프로젝트/state/이슈별 본문
     전문(fenced)/dedup 후보."`
  2. 미리보기를 Step 3 규격 그대로 사용자에게 게이트 제시(본문 전문 직전 메시지 +
     `AskUserQuestion` 선택지).
  3. 승인 → `codex exec resume --last "게이트 승인됨 — 위 미리보기 본문 그대로 바로
     등록(Step 4 진행). 등록된 이슈 ID·URL·kickoff 프롬프트를 최종 메시지로."`
     거부+피드백 → 같은 resume 로 피드백 전달 후 2 로 재게이트.
  4. **독립 검증**: codex 의 등록 보고를 그대로 믿지 않는다 — `mcp__linear__get_issue` 로
     생성 실존 + 본문 계약(아래 검증 섹션) 확인 후 최종 보고. kickoff 프롬프트 제시는
     Claude 가 마무리.
- **watchdog**: 각 codex exec 는 background 로 띄우고 진행 감시 — 무진행 8분+ 또는 hard
  cap 12분에 kill 후 네이티브 워크플로로 폴백(`delegated-review-watchdog.md` 동형, kill
  사실 보고).

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

각 이슈 본문을 아래 **통합 템플릿**(register 표준 — linear-groom 도 같은 헤딩 화이트리스트로 수렴)으로. 수용 기준은 `[AUTO]`/`[HUMAN]` 마커를 단다(linear-goal 자율/사람 게이팅). `## 범위 밖`·`## 다음 작업`·`> 출처:` 는 조건부(해당될 때만). **`## 추천`** 섹션이 핵심 — 생성 규칙은 [references/recommend-section.md](references/recommend-section.md) §A 를 읽어 따른다(SSOT, linear-groom 과 공유). 요지: 글로벌 스킬/에이전트 우선(모델 판단, 시작 매핑은 anchor 금지) + **붙여넣기용 시작 프롬프트 1개**. **UI/프론트엔드 이슈면** 같은 파일 §C(시안 선행 컨벤션 — 본문에 한 줄, 시안 생성은 착수 시점)도 적용한다. 분할 모드도 같은 화이트리스트를 쓴다 — 부모·의존은 본문 헤딩이 아니라 네이티브 관계로(plan-split.md §5).

### 2.5. Dedup + 그루핑 대조 (등록 전 필수)

[references/dedup-grouping.md](references/dedup-grouping.md) 를 읽어 따른다(SSOT). 요지:
팀 미완 이슈(최근 갱신순 ≤100건, Done·Canceled 제외)를 조회해 ① 이슈별 유사 후보
≤3건 판정(모델 판단, 자동 액션 없음) ② 유사 이슈들의 project·`area:*` 분포 근거로
배치 제안(응집 클러스터 + 기존 적합 없음 → 신설 제안). 결과는 Step 3 게이트에 병합
표시 — 유사 후보 있는 이슈는 이슈별 4택(등록/스킵/기존 보강/relatedTo 연결 등록).

### 3. 확인 게이트 — 쓰기 전 필수 (REQ-F-004, REQ-N-002)

`save_issue`(생성 = `id` 없이) **호출 전** 반드시 제시하고 대기. 게이트는 **2단**이다(포맷 SSOT: dedup-grouping.md §4):

1. **직전 메시지 — 본문 전문 미리보기.** 생성될 각 이슈의 **본문 전체**를 이슈별 fenced 블록으로 출력한다. 제목만 보고 승인하면 분량·문체 위반이 등록된 뒤에야 보인다(실측: 2,300자 이슈가 제목만 보인 게이트를 통과했다). 여기에 dedup 후보·배치 제안·state 도 함께.
2. **`AskUserQuestion` — 선택지만.** 승인 / 거부+피드백(유사 후보 있는 이슈는 §4 의 4택). 선택지 텍스트에는 본문을 넣지 않는다 — 들어가지도 않고, 1단이 이미 보여줬다.

> 등록 예정: **<팀>** / **<프로젝트>** / **state=Backlog** / 이슈 **N건**. 위 본문대로 진행?

사용자가 "바로 등록"이라 명시했으면 게이트 스킵(dedup 후보가 있으면 그 사실만 한 줄 보고). 그 외엔 승인 없이 쓰기 금지. 프로젝트/라벨 **신설** 제안이 승인에 포함될 때만 `save_project`/`create_issue_label` 호출.

### 4. 생성 + 체인 (REQ-F-001/008/009/010)

- `mcp__linear__save_issue`(**`id` 없이 = 생성**, `title`+`team` 필수) 로 생성. **기본 `state: "Backlog"`** — 양 모드 동일. 팀에 Backlog 미활성(`list_issue_statuses` 에 type `backlog` 부재 또는 생성 에러)이면 `state` 생략(팀 기본)으로 폴백하고 그 사실을 보고에 명시. 사용자가 게이트에서 다른 state 를 지정하면 그것이 우선.
  - **왜 Triage 가 아닌가** (2026-07-21 변경): Linear 의 Triage 는 일반 백로그·보드 뷰와 분리된 **인수 대기열**이라, 수락 전까지 백로그 목록·사이클 계획에 안 잡힌다. 이 워크스페이스는 **1인 운영**(전 이슈 createdBy·assignee 동일)이라 수신 팀이 곧 등록자다 — Triage 는 판단을 추가하지 않고 단계만 하나 더 만들고, 실제로 SSO 팀 Triage 에 AI 등록분 4건(SSO-68·69·70·71)이 아무도 비우지 않은 채 쌓였다(실측 2026-07-21). 이 스킬은 등록 게이트에서 팀·프로젝트·라벨·dedup 을 이미 확정하므로 Triage 의 인수 판단은 중복이다. **다인 운영 워크스페이스로 바뀌면 이 결정을 되돌린다** — 그때는 Triage 가 실제 인수 게이트로 기능한다.
- **모든 생성 이슈에 `project` + type 성격 라벨 + (보유 팀이면) `area:*` 라벨 부착** — 단 라벨은 **팀 라벨셋 실측 어휘 내에서만**(dedup-grouping.md §1.5 — 팀마다 어휘가 다르고, 없는 라벨명은 라벨셋을 오염시킨다). 배치는 Step 2.5 제안이 1차 근거, 근거 없고 판별 불가면 추측 말고 사용자에게 질의(`feedback_linear_label_on_create` 실측: 라벨 누락 이슈는 team+area 스코프 조회에서 유실). 우선순위(`priority` 0-4)는 이슈 타입상 명백할 때만 설정.
- **의존 체인이면**: 같은 `save_issue` 호출의 `blocks`/`blockedBy`/`relatedTo`/`parentId`(append-only)로 Linear 네이티브 관계를 세팅하고, 각 이슈(마지막 제외)에 [references/recommend-section.md](references/recommend-section.md) §B 의 `## 다음 작업`(전방 포인터 + kickoff 프롬프트)을 심는다. 분할 모드는 blocker 먼저 의존순 발행(plan-split.md §5).
- Step 2.5 에서 "기존 보강" 선택된 이슈는 신규 생성 대신 `save_issue`(id=기존)로 병합, "연결 등록" 은 생성 + `relatedTo` 세팅.
- 종료 응답에 **첫(또는 다음) 실행 가능 이슈의 kickoff 프롬프트**를 즉시 복사 가능하게 제시.

## 이슈 본문 템플릿

**사람이 30초에 읽는 문서로 쓴다.** 이슈는 설계 문서가 아니라 "무엇을 왜 하고, 끝난 걸
어떻게 아나"의 요약이다.

```markdown
## 작업 내용
<무엇을 하는지 — 쉬운 말로 3줄 이내. 동작 중심.>

## 수용 기준
- [ ] [AUTO] <자동 검증 — 테스트/타입체크/특정 동작>
- [ ] [HUMAN] <사람 검증 — 시각확인/운영 apply 등>

## 범위 밖              ← YAGNI 경계가 있을 때만
- <이 이슈에서 안 하는 것>

## 추천
`/<skill>` — <왜 이게 맞는지 1줄>

시작 프롬프트:
```
<붙여넣기용 kickoff 프롬프트>
```

## 다음 작업           ← 체인일 때만
다음: <next-id> <제목> · 시작 프롬프트:
```
<다음 이슈용 kickoff 프롬프트>
```

> 출처: <genesis — spike/리포트/plan/메모리, 있을 때만>
> AI 가 등록·작성
```

### 헤딩 화이트리스트 (그 밖의 헤딩 신설 금지)

| 헤딩 | 언제 |
|---|---|
| `## 작업 내용` · `## 수용 기준` · `## 추천` | **항상** |
| `## 범위 밖` | YAGNI 경계가 있을 때만 |
| `## 다음 작업` | 체인일 때만 |

위 5개 밖의 헤딩을 만들지 않는다 — `## 배경`·`## 현황`·`## 원본` 류 신설 금지(배경은
`## 작업 내용` 첫 줄에 한 구절로 녹인다). 조건부 섹션은 해당 없으면 **통째 생략**(빈
헤딩 금지). 분할 모드도 이 화이트리스트를 따른다 — 부모·의존은 헤딩이 아니라 Linear
네이티브 관계(`parentId`/`blockedBy`)로 표현한다(plan-split.md §5).

### 분량 상한 (넘으면 등록 전 축약)

- `## 작업 내용` **≤ 3줄**
- `## 수용 기준` **≤ 5개**
- 본문 전체 **≤ 600자** (아래 carve-out 제외)

### 문체 — 비전문 독자 기준

- **산문에 파일경로·라인번호·심볼명을 쓰지 않는다** (`src/x.ts:42`, `getPlan` 류).
  착수 시점의 grounding 이 찾을 일이지 이슈가 들고 있을 정보가 아니다.
  단 **산출 경로 지정**(예: 시안을 `docs/preview/<name>.html` 로 만들라 — §C 컨벤션)은
  *참조*가 아니라 *계약*이라 예외다. 기존 코드를 가리키는 경로만 금지 대상.
- 한 문장은 두 절 이내. 도메인 약어가 불가피하면 처음 한 번 괄호로 쉬운 말 병기.

### carve-out — 규칙 대상 밖

`>` **인용줄**(`> 출처:` · `> Plan-reviewed:` · disclaimer)과 **fenced 코드블록**
(kickoff 프롬프트·에러 로그·스키마 스니펫)은 헤딩 화이트리스트·자수 상한·경로 금지의
**대상이 아니다**. 재현 로그와 스택트레이스는 코드블록 안에 그대로 넣어도 된다 — 금지
대상은 산문 속 경로 나열이다.

### 항상 지키는 것

- **수용 기준의 `[AUTO]`/`[HUMAN]` 마커 필수** — linear-goal 이 이 마커로 자율/사람
  검증을 가른다(`acceptance-criteria-gate`).
- **AI disclaimer 줄은 모든 본문/코멘트에 부착** (REQ-F-011).
- **`## 범위 밖` 은 값이 크다** — `linear-goal` 의 goal-ready 판정과 라우팅 가드가 이
  헤딩(또는 동등한 scope 경계)을 읽는다. 경계가 있으면 생략하지 말 것.

## 검증

- 게이트 승인 전 `save_issue`(생성)·`save_project`·`create_issue_label` 호출 0회 · 생성 이슈마다 `## 추천` + disclaimer 존재 · 기본 state=Backlog(미활성 팀은 폴백 보고) · dedup 대조 수행(상한 초과 시 "최근 100건 기준" 명시) · 체인이면 Linear 관계 세팅됨 + 각 이슈 전방 포인터 · 종료 응답에 kickoff 프롬프트 1개.
- **본문 계약 (이슈마다 센다):** ① 화이트리스트 밖 헤딩 **0개** ② 분량 **상한 준수**
  (작업 내용 ≤3줄 · 수용 기준 ≤5개 · 본문 ≤600자, carve-out 제외) ③ **disclaimer** 줄
  존재 ④ **추천 코드블록** 1개(시작 프롬프트). 하나라도 미달이면 등록 전에 고친다.
