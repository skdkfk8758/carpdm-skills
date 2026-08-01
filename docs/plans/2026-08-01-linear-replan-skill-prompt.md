# Goal: linear-replan 스킬 저작 — 착수 직전 Linear 이슈를 codex 로 인터뷰형 재플래닝 (ADT-435)

## Objective
carpdm-skills 레포에 `skills/linear-replan/` 스킬을 저작한다 — **Linear 이슈 번호
또는 짧은 자유 요구사항 텍스트**를 받아, plain `codex exec` 로 플랜 초안+체크리스트
(결정 갈래)를 산출하고, 체크리스트 항목을 AskUserQuestion 인터뷰로 전항목 확정해
착수 계획 문서 1개를 만들고(이슈 모드는 승인 게이트 뒤 이슈 코멘트 첨부까지) 하는
동작을 SKILL.md(+필요 시 references/)에 인코딩하고, README 스킬 표에 행을 추가해
CI 검증 3종을 전부 통과시킨다.

## Success Criteria
> 시작 직후 첫 행동으로 `START_SHA=$(git rev-parse HEAD)` 를 기록하고 메시지에
> 표면화하라 — 마지막 criterion 의 기준점이다.

- [ ] `skills/linear-replan/SKILL.md` 존재 + `node scripts/ci/validate-skills.js` exit 0
      (frontmatter `name: linear-replan` = 디렉토리명, `description:` 존재).
- [ ] `node scripts/ci/check-invisible-chars.js` exit 0.
- [ ] `node scripts/ci/catalog.js` exit 0 — README.md 에 `skills/linear-replan` 링크 행
      + "N개 스킬" 카운트 갱신 포함.
- [ ] SKILL.md 에 필수 블록 11개가 지정 범위에서 각각 grep 매치 (패턴·범위는 Verification 4 에 1:1):
      ① `codex exec` 비인터랙티브 직호출(stdin 파이프) — 본문에 `codex exec` ≥1
      ② codex 프리플라이트 — `codex doctor` 또는 `command -v codex` ≥1, 불가 시
        "안내 한 줄 + 깨끗한 정지" + 안내에 deep-plan 라우팅("Claude 단독 재플래닝이
        필요하면 deep-plan") 포함
      ③ 체크리스트 인터뷰 — `AskUserQuestion` ≥1. 절 내용: 체크리스트 = **결정
        갈래만**(검증 항목 아님), **전항목 확정**까지 배칭(1콜 ≤4질문), 사용자가
        "나머지 알아서" 선언 시 잔여는 codex 초안값으로 **봉인** + 산출 문서에
        "봉인 항목" 명시 — 본문에 `봉인` ≥1
      ④ 종료 출력 — `output-contract.md` ≥1 (L1 `result:` + L2 열기 + L3 다음 스킬 제안)
      ⑤ 하류 경계 — **본문(frontmatter 제외)**에 `linear-goal` ≥1 (goal-ready 로
        끌어올리는 앞단 포지션 + L3 라우팅)
      ⑥ 상류 경계 — **본문(frontmatter 제외)**에 `deep-plan` ≥1 (oversized/전면개편이면
        그쪽으로 보내는 기준)
      ⑦ Linear MCP graceful — `craft-core/references/linear.md` 포인터 ≥1 + "MCP
        미설치면 가이드 한 번 + 정지"
      ⑧ 코멘트 첨부 — 본문에 `코멘트` ≥1. 절 내용: 확정 플랜을 이슈 **코멘트**로
        첨부(본문 무수정)하되 외부 write 라 **승인 게이트** 후에만 + AI disclaimer
        줄 부착
      ⑨ codex watchdog — 본문에 `3분` 또는 `timeout` ≥1. 절 내용: `codex exec` 는
        timeout 래핑 또는 background+진행감시, 3분 무진행 kill
      ⑩ 입력 듀얼 모드 — 본문에 `자유 요구사항` ≥1. 절 내용: 입력이 이슈 번호면
        **이슈 모드**(Step 1 fetch + Step 5 코멘트 첨부), 자유 요구사항 텍스트면
        **텍스트 모드**(fetch·코멘트 생략 — 텍스트 자체가 입력, kickoff 문서로 종료,
        L3 에서 `linear-register` 등록을 후보로 제안). 대형·고위험 요구사항은 텍스트
        모드가 아니라 deep-plan 으로 보낸다(블록 ⑥ 경계와 일관)
      ⑪ 은퇴/통합 조건 — 본문에 `은퇴 조건` ≥1. 절 내용 (verbatim 취지): "3개월 내
        ① 텍스트 모드 오발화 실측(deep-plan 과 트리거 혼선) 또는 ② 실사용 저빈도면
        deep-plan 경량 모드로의 흡수를 검토한다. codex CLI 가용성이 사라지면 스킬
        자체를 폐지한다(codex 경유가 존재 이유)." — 글로벌 룰 수명 규율(신규 룰
        은퇴 조건 의무)의 스킬판
- [ ] **frontmatter 블록**(첫 `---` ~ 둘째 `---`) 안에 `linear-goal` ≥1 그리고
      `deep-plan` ≥1 (디스앰비규에이션 — ⑤⑥의 본문 매치와 별도로 이중 만족 불가.
      frontmatter 는 `name: linear-replan`+`description:` 뿐이므로 매치는 description
      에서만 나온다. **단일행 전제 금지** — 형제 스킬 9개가 `description: >-` folded
      다중행 스타일이고 그쪽이 관례다).
- [ ] SKILL.md 에 불변식 문장 리터럴 `이슈 본문·상태를 수정하지 않는다` ≥1.
- [ ] `git status --porcelain` 출력 0줄(전부 커밋) 이고 `git diff --name-only
      $START_SHA..HEAD` 가 `skills/linear-replan/` 하위와 `README.md` 외 0건.

## Context
(전부 이번 세션 실측 — 추측 아님)
- 레포 = Claude Code 스킬 배포 레포. 마크다운만, 빌드/런타임 없음. 새 스킬 =
  `skills/<name>/SKILL.md`(+`references/*.md`). 본문 prose 한국어, frontmatter
  `name:`/키/도구명은 원문 유지 (`rules/project.md` 작성 언어 정책).
- CI 검증: `scripts/ci/validate-skills.js` · `check-invisible-chars.js` · `catalog.js`
  (node 단독, 의존성 0). README 행 누락 시 `guard-readme-fresh` 훅이 PR 차단.
- codex 호출면: `/opt/homebrew/bin/codex` v0.145.0. `codex exec [PROMPT]` 비인터랙티브
  (stdin 파이프 지원), `codex doctor` 진단, `~/.codex/auth.json` 인증됨. **플러그인
  경로(codex-companion.mjs)는 2026-07-30 은퇴 — 참조 금지**, plain `codex exec` 만.
- 이슈 본문 신계약(PR #153): 헤딩 화이트리스트 + ≤600자 + 산문 내 파일경로 0 —
  이슈에 실행 상세가 의도적으로 없다. 이 스킬이 착수 시점에 그 갭을 메꾼다
  (이슈 fetch → 레포 Read/Grep grounding → codex 재플래닝).
- 경계 대상 SKILL 실물: `skills/linear-goal/SKILL.md`(routing rubric·goal-ready
  4기준·oversized-class), `skills/deep-plan/SKILL.md`. 경계 절 작성 전 반드시 Read.
- 공유 SSOT (복제 금지, 포인터 참조): Linear MCP graceful 감지 =
  `skills/craft-core/references/linear.md`, 종료 출력 =
  `skills/craft-core/references/output-contract.md`.
- **저작 잡 권한 vs 런타임 동작 구분** — 이 goal 은 스킬 *문서*를 쓰는 잡이다.
  SKILL.md 가 인코딩하는 런타임 동작(이슈 코멘트 첨부·승인 게이트)은 스킬이
  나중에 실행될 때의 일이고, 이 저작 잡 자체는 어떤 Linear write 도 호출하지
  않는다(Constraints 참조). 이 구분을 헷갈려 저작 중 코멘트를 달지 말 것.
- 인코딩할 동작 골격 (SKILL.md 가 지시할 워크플로):
  Step 0 codex 프리플라이트(불가 시 안내 한 줄 — deep-plan 라우팅 포함 — 후 정지)
  + **입력 모드 판정**: 이슈 번호/URL = 이슈 모드, 그 외 짧은 자유 요구사항 텍스트 =
  텍스트 모드(대형·고위험이면 deep-plan 라우팅 제안 후 정지)
  → Step 1 [이슈 모드만] Linear MCP 로 이슈 fetch(미설치면 linear.md 규약대로
  가이드 한 번 + 정지); [텍스트 모드] fetch 생략 — 요구사항 텍스트가 곧 입력.
  양 모드 공통 레포 grounding → Step 2 codex exec 에 입력+grounding 파이프(timeout
  래핑 또는 background+진행감시, 3분 무진행 kill) → 플랜 초안 + 결정 갈래
  체크리스트 수신 → Step 3 AskUserQuestion 배칭(1콜 ≤4질문)으로 전항목 확정 —
  답 반영은 Claude 직접, **구조를 바꾸는 큰 갈래만 codex 재호출 1회 한정**;
  "나머지 알아서" 선언 시 잔여는 codex 초안값 봉인 + 문서에 봉인 항목 명시
  → Step 4 확정 플랜 문서 1개 저장(이슈 모드 `docs/plans/<issue-id>-kickoff.md` /
  텍스트 모드 `docs/plans/<slug>-kickoff.md` 기본) → Step 5 [이슈 모드만] 승인
  게이트 후 이슈 코멘트로 첨부(AI disclaimer 부착, 본문 무수정) → output-contract
  종료 + L3 제안(이슈 모드 = linear-goal / 텍스트 모드 = linear-register 등록 또는
  빌드 스킬).

## Constraints
- 수정 허용 경로: `skills/linear-replan/**` 와 `README.md` **만**. 그 외 전부 읽기 전용
  — 특히 linear-goal/deep-plan/craft-core 참조 파일 수정 금지(포인터로만 참조).
- 커밋은 현재 워크트리 브랜치에 허용. **push·PR 생성·머지 금지** — 변경만 두고 보고.
- **이 저작 잡은 Linear write 도구(save_issue·save_comment 등) 호출 금지** — 코멘트
  첨부는 SKILL.md 에 *문서로 인코딩*할 런타임 동작이지, 지금 실행할 일이 아니다.
- codex 플러그인 설치·companion 스크립트 부활 금지. live `~/.claude/skills/` 직접
  편집·설치 금지(repo 만 — install 과 real-env probe 는 사람 몫).
- SSOT 문서 내용을 SKILL.md 로 복제하지 말 것 — 경로 포인터만 (레포 drift 차단 규율).

## Verification
Success Criteria 와 1:1, 이 순서로 (파일 = `skills/linear-replan/SKILL.md`, 본문 추출 =
`awk '/^---$/{c++;next} c>=2' skills/linear-replan/SKILL.md`):
1. `node scripts/ci/validate-skills.js` → exit 0
2. `node scripts/ci/check-invisible-chars.js` → exit 0
3. `node scripts/ci/catalog.js` → exit 0
4. 필수 블록 11개:
   ① `grep -c "codex exec"` ≥1
   ② `grep -cE "codex doctor|command -v codex"` ≥1
   ③ `grep -c "AskUserQuestion"` ≥1 그리고 `grep -c "봉인"` ≥1
   ④ `grep -c "output-contract.md"` ≥1
   ⑤ 본문 추출 | `grep -c "linear-goal"` ≥1
   ⑥ 본문 추출 | `grep -c "deep-plan"` ≥1
   ⑦ `grep -c "craft-core/references/linear.md"` ≥1
   ⑧ 본문 추출 | `grep -c "코멘트"` ≥1
   ⑨ `grep -cE "3분|timeout"` ≥1
   ⑩ `grep -c "자유 요구사항"` ≥1
   ⑪ `grep -c "은퇴 조건"` ≥1
5. frontmatter 추출 = `awk '/^---$/{c++;next} c<2' skills/linear-replan/SKILL.md` —
   그 출력에 `grep -c "linear-goal"` ≥1 · `grep -c "deep-plan"` ≥1
   (단일행 `^description:` grep 금지 — folded `>-` 다중행이 레포 관례라 거짓 FAIL 난다)
6. `grep -cF "이슈 본문·상태를 수정하지 않는다" skills/linear-replan/SKILL.md` ≥1
7. `git status --porcelain` → 0줄 그리고 `git diff --name-only <START_SHA>..HEAD` →
   `skills/linear-replan/`·`README.md` 외 0건.
   **주의**: `$START_SHA` env 변수는 Bash 호출 간 유지되지 않는다 — 시작 때 메시지에
   표면화해 둔 **리터럴 SHA 를 치환**해 실행하라.

## Out of Scope
- 스킬을 실제로 *실행*해 이슈를 재플래닝하는 것 (그건 스킬 사용 시점의 일).
- linear-goal·deep-plan·craft-core 등 기존 스킬 수정 — **linear-goal 의 진입 라우팅
  (replan 경유 갱신)은 후속 이슈로** (Done & Report 의 등록 권고 참조).
- Linear 이슈 등록·본문 수정·상태 전이·코멘트 작성 (저작 잡 기준 — 런타임 인코딩과 별개).
- codex 형상 복구(플러그인 재설치)·install.sh/sync.sh 변경.
- 계획대로 코드를 짜는 실행 경로 구현 (기존 실행 스킬 몫 — ADT-435 범위 밖 그대로).

## Done & Report
이 goal 은 사람이 지켜보지 않는 자율 잡으로 실행되고, 완료는 별도 평가기가
대화에 표면화된 내용으로 판정한다. 평가기는 명령을 돌리거나 파일을 읽지 못한다 —
그러니 매 턴 Verification 실행 결과와 변경 요약을 **메시지 텍스트로 다시
진술**하라(START_SHA 포함). 상태는 마지막 메시지를 아래 한 줄로 맺어 명확히 하라:
- 완료 — 위 Success Criteria 가 **전부 참**이면 `result:` 한 줄(달성 내용 +
  각 criterion 의 검증 결과 수치).
- 막힘 — 사람의 한 가지 행동(권한·결정·접근)이 있어야만 진행 가능하고 합리적
  추측이 불가능하면, `needs input:` 한 줄에 정확히 무엇이 필요한지.
- 불가 — 전제가 틀렸거나 구조적으로 불가능하면(잘못된 레포·CI 스크립트 부재 등),
  `failed:` 한 줄에 이유.
- 종료 보고에 **후속 이슈 등록 권고**를 명시하라: "linear-goal 진입 라우팅을
  replan 경유로 갱신하는 건은 후속 이슈 — linear-register 경유로 등록 필요(이 잡은
  Linear write 금지라 등록은 사람 몫)".
- 사람이 직접 확인할 항목(`[HUMAN]`·`blocked`)이 **2건 이상** 남으면, 종료 보고에
  텍스트로만 남기지 말고 `~/.claude/skills/craft-core/references/ui-verify.md` §5·§5.1 대로
  **인터랙티브 체크리스트를 Artifact 로 publish** 한다(표면 무관 — 비UI 면 항목이 실행할
  명령과 기대 출력이 된다). **1건이어도** 작업 워크트리의 dev 서버를 `dev-server-daemon`
  으로 **띄운 채** 넘겨 링크가 바로 열리게 하고, 보고 마지막에 artifact URL(냈으면) +
  실측 dev origin + 정지 명령을 적는다. 띄울 dev 명령이 없는 프로젝트면 기동을 생략하고
  서버 없이 실행 가능한 확인 방법을 적는다. 체크는 사람이 채운다 — 대신 켜지 않는다.
  (이 레포는 dev 서버 없음 — 기동 생략, 확인 방법 = 아래 probe 절차 명기.)
  잔여 [HUMAN] 최소 2건 확정: ① ADT-435 수용 기준 3 — 산출 계획이 실제 착수에
  충분한지 이슈 1건으로 확인, ② real-env probe — 사람이 `bash install.sh` 로 live
  설치 후 트리거 정확 발화 + linear-goal/deep-plan sibling 오발화 없음 확인
  (`rules/project.md` Skill authoring 검증 — live 설치는 이 잡이 하지 않는다).
그 외에는 계속 진행한다 — Verification 을 돌려 Success Criteria 를 자가 판정하고
전부 참이 될 때까지 루프한다.
