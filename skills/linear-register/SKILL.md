---
name: linear-register
description: Register one to a few Linear issues natively (via Linear MCP), and on each issue append an adaptive "## 추천" section that points to the right global skill/agent/workflow for that work, plus — for dependency chains — set Linear relations and embed a forward pointer + ready-to-paste kickoff prompt for the next issue. Use when the user wants to file/create/register a Linear issue or a small set of linked Linear issues — "리니어에 이슈 등록", "이 작업 Linear 티켓 만들어줘", "이거 이슈로 올려줘", "연결된 이슈 몇 개 등록", "file this as a Linear issue". Do NOT use for: breaking a whole plan/spec/PRD into many vertical-slice issues (use to-issues), synthesizing a PRD from the conversation (use to-prd), running a ticket as an autonomous build (use linear-goal), or reorganizing/enriching an existing backlog (use linear-groom). When the input is a large plan or PRD, recommend those skills instead of decomposing it here.
---

# linear-register

Linear 이슈를 네이티브로 등록하고, 각 이슈에 **다음 행동 가이드**(적합한 스킬/에이전트 추천 + 체인 전방 포인터)를 등록 시점에 함께 박는다. 등록과 "그래서 뭘로 이어가나" 사이의 끊김을 없앤다. 전체 요구사항: [SPEC.md](SPEC.md).

## 경계 (먼저 확인)

- 대형 plan/spec 을 다중 슬라이스로 **분할** → 직접 안 함, `to-issues` 추천.
- 대화 → **PRD 합성** → `to-prd`. 티켓 **자율빌드** → `linear-goal`. 기존 백로그 **재배치/보강** → `linear-groom`.
- 이 스킬은 **단건~소수**의 Linear 이슈 등록 + 추천 + 체인 전담.

## 워크플로

### 1. 타깃 팀/프로젝트 해소 (REQ-F-002/003)

- 현재 repo (`git rev-parse --show-toplevel`, worktree 면 메인 repo) → `~/.claude/linear-repo-map.json` **역매핑**. `projectExceptions[].repo` 우선, 없으면 `teamRoutes[].repo` prefix 매칭 → `teamId`. (`linear-dispatch.md` 룰과 동형.)
- repo 가 맵에 없음 → **"어느 팀?" 사용자에게 질의**. 추측 등록 금지.
- 프로젝트는 그 팀의 `mcp__linear__list_projects` 에서 고르거나 사용자 확인 (없으면 "프로젝트 없음" 명시).

### 2. 이슈 초안 작성 (REQ-F-005/006/011)

각 이슈 본문을 아래 **통합 템플릿**(register 표준 — linear-groom 도 같은 코어 헤딩 `## 작업 내용`/`## 수용 기준` 으로 수렴)으로. 수용 기준은 `[AUTO]`/`[HUMAN]` 마커를 단다(linear-goal 자율/사람 게이팅). `## 배경`·`## 범위 밖`·`> 출처:` 는 조건부(해당될 때만). **`## 추천`** 섹션이 핵심 — 생성 규칙은 [references/recommend-section.md](references/recommend-section.md) §A 를 읽어 따른다(SSOT, linear-groom 과 공유). 요지: 글로벌 스킬/에이전트 우선(모델 판단, 시작 매핑은 anchor 금지) → 프로젝트 로컬 포인터 부차(타repo 안 읽음, REQ-N-003). 큰 plan/PRD 입력이면 `to-issues`/`to-prd` 위임을 적는다(REQ-F-007). **UI/프론트엔드 이슈면** 같은 파일 §C(시안 선행 컨벤션 — 본문에 한 줄, 시안 생성은 착수 시점)도 적용한다.

### 3. 확인 게이트 — 쓰기 전 필수 (REQ-F-004, REQ-N-002)

`save_issue`(생성 = `id` 없이) **호출 전** 반드시 제시하고 대기:

> 등록 예정: **<팀>** / **<프로젝트>** / 이슈 **N건** — [제목 목록]. 진행?

사용자가 "바로 등록"이라 명시했으면 게이트 스킵. 그 외엔 승인 없이 쓰기 금지.

### 4. 생성 + 체인 (REQ-F-001/008/009/010)

- `mcp__linear__save_issue`(**`id` 없이 = 생성**, `title`+`team` 필수) 로 생성. 라벨/우선순위(`priority` 0-4)는 이슈 타입상 **명백할 때만** 설정.
- **의존 체인이면**: 같은 `save_issue` 호출의 `blocks`/`blockedBy`/`relatedTo`/`parentId`(append-only)로 Linear 네이티브 관계를 세팅하고, 각 이슈(마지막 제외)에 [references/recommend-section.md](references/recommend-section.md) §B 의 `## 다음 작업`(전방 포인터 + kickoff 프롬프트)을 심는다.
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
**수용 기준은 `[AUTO]`/`[HUMAN]` 마커 필수** — linear-goal 이 이 마커로 자율/사람 검증을
가른다(`acceptance-criteria-gate`). AI disclaimer 줄은 **모든** 본문/코멘트에 부착 (REQ-F-011).

## 검증

- 게이트 승인 전 `save_issue`(생성) 호출 0회 · 생성 이슈마다 `## 추천` + disclaimer 존재 · 체인이면 Linear 관계 세팅됨 + 각 이슈 전방 포인터 · 종료 응답에 kickoff 프롬프트 1개.
