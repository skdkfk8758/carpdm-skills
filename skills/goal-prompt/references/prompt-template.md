# Goal Prompt 골격 (SSOT)

> `goal-prompt` Step 4 가 읽는 유일한 골격. `{{…}}` 는 채울 칸. 본문은 **autonomous
> 기준**으로 쓴다(사람 없이 완주 가능) — interactive 소비자면 본문은 그대로 두고 맨
> 아래 부록 한 블록만 덧붙인다. 두 변형을 한 문장 안에서 갈라 쓰지 않는다.
> 비는 섹션은 "없음" 이라 쓰고 지우지 않는다(소비 에이전트가 부재를 "미정" 으로
> 오독하지 않게). Operating discipline 본문이 Karpathy 4원칙의 SSOT 다 — 고칠 때는
> 여기를 고친다. Working Method 줄은 `working-method.md` §4 결합표에서 온다.

```markdown
# {{topic}} — Goal Prompt

## Persona
당신은 {{역할 — 도메인·스택·담당 경계}}이다.
중시하는 것: {{우선순위 1 > 2 > 3 — 트레이드오프에서 기우는 방향. 해석이 갈릴 때 이 순서가 결정한다}}.
모르는 상태를 다루는 방식: {{예: 확인 못 한 사실은 단언하지 않고 보고의 assumption 목록에 올린다}}.

## Operating discipline
1. 코드 전에 생각한다 — 가정을 명시한다. 해석이 둘이면 Persona 의 우선순위로 고르고 그 선택을 보고의 assumption 목록에 올린다. 더 단순한 길이 보이면 그쪽을 택하고 이유를 남긴다.
2. 최소 코드 — 요청 밖 기능·단일 사용 추상화·요청 없는 설정성·불가능한 시나리오의 에러 처리 금지. 200줄이 50줄이 될 수 있으면 다시 쓴다.
3. 외과적 변경 — 바뀐 모든 줄이 요청으로 역추적돼야 한다. 인접 코드·주석·포맷을 손대지 않고, 안 깨진 것을 리팩터하지 않고, 기존 스타일을 따른다(내 취향과 달라도). 무관한 dead code 는 보고에 언급만 하고 지우지 않는다. 내 변경이 만든 고아(import·변수·함수)만 치운다.
4. 목표 주도 — 작업을 검증 가능한 목표로 바꾼다("버그 수정" → "재현 테스트를 쓰고 통과시킨다"). 아래 Success Criteria 가 루프 탈출 조건이고, Slices(있으면) 또는 Step 목록의 각 항목은 `→ verify:` 를 갖는다.

## Objective
{{한 문단 — 무엇을 왜. 이 문단만 읽고 성공 모습을 그릴 수 있게}}

## Success Criteria (사람 없이 판정 가능한 것만)
- [ ] {{명령 → 기대 출력 / 테스트 이름 통과 / 파일 존재 / 수치}}
- [ ] {{…}}
- [ ] `git diff --stat <BASE_SHA>` (커밋·수정된 추적 파일) **와** `git status --porcelain` (미추적 신규 파일 — diff 에는 안 잡힌다) 두 출력의 경로가 전부 Context 영향 반경(테스트·lockfile·handoff 경로 포함) 안이다.

## Context (실측한 것만)
- repo: `{{경로}}`. 격리: 착수 시 `git rev-parse --path-format=absolute --git-dir --git-common-dir` 두 줄이 **같으면 메인 트리** — 편집하지 말고 `blocked: main worktree — 격리 트리에서 재실행` 한 줄로 종료(`result:` 가 아니라 `blocked:` — 아래 Done & Report 마커 계약). branch: `{{Step 1 에서 정한 브랜치명 — 이슈 키 있으면 <type>/<issue-id>-<topic>, 없으면 <type>/<topic>}}` — 현재 체크아웃이 이 브랜치가 아니면 BASE 에서 이 이름으로 만들어 이동한다. 현재 브랜치가 trunk(`develop`/`main`)면 편집하지 말고 `blocked: on trunk — 브랜치 생성 후 재실행` 으로 종료.
- 지침: `{{CLAUDE.md/AGENTS.md 경로}}` 먼저 읽고 따른다. 도메인 어휘: `{{CONTEXT.md 경로 또는 없음}}`. standing 결정: `{{ADR 경로들 또는 없음}}`.
- 영향 반경 (path : 왜 바뀌나) — 테스트 디렉터리·lockfile·`docs/handoff/` 포함:
  - `{{path}}` : {{이유}}
  - `{{이 프롬프트 파일(들)의 경로}}` : 미커밋으로 트리에 떠 있을 수 있다. `git status --porcelain` 에 뜨는 것은 범위 위반이 아니다 — 편집하지 말고 첫 커밋에 함께 담는다.
- seam (테스트가 관측할 공개 경계): `{{인터페이스/엔드포인트/CLI}}` — {{기존 재사용 / 신설(가장 높은 지점)}}. **이 seam 이 사전 합의된 seam 이다 — 재확인 없이 진행.** prior art: `{{유사 테스트 경로}}`.
- 검증 명령: `{{verify 스크립트 또는 build·test·typecheck 실제 명령}}`
- {{이슈/spec 본문 요지 또는 경로}}

## Constraints
- 범위: 영향 반경 밖 파일 편집 금지. 새 의존성은 Working Method 사다리를 통과했을 때만 — 사유를 커밋 메시지에.
- 보안 불변식: {{authz·secret·injection·데이터 손실 — 해당 없으면 "해당 없음"}}.
- 파괴·외부 발신 금지: `rm -rf`·`DROP`·force-push·머지·배포·외부 API write 는 하지 않는다. push/PR: {{허용 여부 — 인터뷰 결과}}.
- assumption (확인된 사실이 아니라 채택한 가정 — 실행 중 틀렸음이 드러나면 멈추고 보고):
  - {{assumption 1 또는 "없음"}}

## Slices
{{tracer bullet 이 2+ 일 때만 아래 표. 1개면 이 섹션 본문을 "없음 — 단일 슬라이스" 한 줄로}}
| # | 슬라이스 (전 계층 관통, 단독 검증) | Blocked by | verify |
|---|---|---|---|
| 1 | {{…}} | 없음 | `{{명령}}` → {{기대}} |
| 2 | {{…}} | 1 | … |
슬라이스당 커밋 1. 순서는 Blocked by 를 따른다. 넓은 리팩터는 expand → migrate(배치) → contract 를 그대로 슬라이스로.

## Working Method
- 착수: `git rev-parse HEAD` 를 실행하고 출력 SHA 를 첫 보고 줄에 **리터럴로** 적는다 — 이후 모든 diff 판정은 그 SHA 를 직접 쓴다(셸 변수는 tool call 간 유지되지 않는다). 이 문서의 `<BASE_SHA>` 가 그 값이다.
- 착수: **BASE 신선도를 확인한다.** `git fetch origin <trunk>` 후 `git rev-list --count <BASE_SHA>..origin/<trunk>` 를 실행하고 그 수를 보고에 적는다. 이 문서의 BASE 는 프롬프트를 **쓴 시점**의 값이라 소비 시점엔 뒤처져 있을 수 있다. 0 이 아니면 rebase 하고, rebase 후 SHA 를 새 BASE 로 삼아 그 사실을 보고한다. 뒤처진 base 로 만든 변경은 충돌 없이 조용히 빠지는 것(설정 checksum·새 규칙)이 생긴다.
{{working-method.md §4 결합표에서 조립 — 각 줄 = "시점: 할 일 (스킬 있으면 / 없으면)"}}

## Verification
1. `{{검증 명령}}` → exit 0. 실패 시 **1회만** 자가수정 후 재검증, 또 실패면 중단하고 partial 로 보고(무한루프 금지).
2. 작성한 회귀 테스트 단독 실행 통과.
3. `git diff --stat <BASE_SHA>` + `git status --porcelain` 두 명령으로 영향 반경 대조 — diff 는 미추적 신규 파일을 안 보여주므로 둘 다 본다.
4. Success Criteria 를 위에서 아래로 하나씩 체크 — 하나라도 미충족이면 done 이 아니다.

## Out of Scope
- {{명시 배제 1}}
- 머지·배포·이슈 상태 Done 전이 — 사람 몫.

## Done & Report
1. {{커밋/PR 규약 — 예: 브랜치 push + PR 생성(머지 X) / 커밋만}}
2. 마지막 메시지 형식:
   `result: <한 줄 — 무엇을 했는지 + 핵심 수치>` — 미완이면 `result: partial — 완료 k/N, handoff docs/handoff/YYYY-MM-DD-<topic>.md`
   진행 불가면 `blocked: <이유>` 를 **별도 줄**에 — 사람이 풀어야 할 상태. 포기면 `Giving up.` 한 줄.
   (마커 계약 출처: Claude Code 백그라운드 잡 완료 분류기, CLI 2.1.259 내장 프롬프트 — `"result: <text>" on its own line → done (<text> is output.result)` · `"blocked: <reason>" on its own line → blocked` · `"Giving up."` → failed. end-to-end 실측 2026-09-03: `claude --bg` 잡이 `result: probe ok` 한 줄로 끝나자 `claude agents` state 가 `working → done` 전이. `result: blocked …` 라고 쓰면 **done** 으로 분류된다 — 접두를 섞지 않는다.)
   - BASE SHA · `git log --oneline <BASE_SHA>..HEAD` 커밋 목록 · 변경 파일 수 · 검증 명령과 실제 출력
   - assumption: 사전 assumption 위반 여부 + **실행 중 새로 채택한 assumption** 목록 — 없으면 "없음"
   - 사람 확인 요청 항목(주관·외부 승인) — 없으면 "없음"
   - 1회 자가수정이 있었으면 어디서
```

## interactive 부록 (소비자가 사람이 지켜보는 새 세션일 때만 본문 끝에 덧붙인다)

```markdown
## Interactive checkpoints (사람이 있을 때만)
- Operating discipline 1 의 "Persona 우선순위로 고른다" 대신 **사용자에게 묻는다**.
- Slices/Step 계획을 제시한 뒤 멈추고 사용자에게 `/hate` 를 요청한다. root 반박이 오면 그 first nail 을 첫 슬라이스로 올린다.
- 설계 선택이 둘 이상에서 하나로 갈렸으면 `/feynman` 을 제안한다. 보안·비용·정확성이 갈리는 변경이면 `/prism` 한 줄.
- 컨텍스트가 무거워지면 `/handoff` 로 증류하고 사용자가 새 세션을 연다. 보고에 아직 안 친 체크포인트 목록을 붙인다.
```

## 4000자 초과 시의 분할 변형 (Step 4 길이 ③④)

한 파일이 4000자를 넘으면 아래처럼 나눈다. **섹션을 새로 발명하지 않는다** — 위
골격의 섹션을 두 파일로 가르는 것뿐이다.

**`-prompt-00-common.md`** (슬라이스 공통, 소비 에이전트가 읽는다):
`## Persona` · `## Operating discipline` · `## 전체 목표 (N슬라이스)`(각 슬라이스가
무엇인지 한 줄씩 + 브랜치 하나를 이어 쓴다는 선언) · `## 공통 Constraints`(파괴 금지·
push 권한·보안 불변식 등 슬라이스와 무관한 것) · `## Working Method` · `## 보고 형식`
(`result:`/`blocked:`/`Giving up.` 마커 계약 + 공통으로 적을 항목) · `## Interactive
checkpoints`(해당할 때). 머리에 **"충돌하면 슬라이스 파일이 이긴다"** 를 적는다.

**`-prompt-01.md`, `-02`, …** (슬라이스 고유):
맨 위 `**Blocked by**:` 한 줄(앞 슬라이스의 완료 커밋이 내 BASE, 사이에 낀 사람 작업
포함, 미충족이면 `blocked: …` 로 종료) → `## 공통 규율`(공통 파일 경로 + "읽고 그대로
따른다. 읽지 않고 시작하지 않는다") → `## Objective`(이 슬라이스만) → `## Success
Criteria` → `## Context (실측)` → `## Constraints`(이 슬라이스 고유 + assumption) →
`## Out of Scope` → `## Done & Report (공통 형식에 더해)`(인계값 = 다음 슬라이스가
쓸 값 + 사람 확인 요청).

`## Slices` 표는 분할하면 사라진다 — 파일 자체가 슬라이스다. 대신 공통 파일의
`## 전체 목표` 가 순서를 진술한다.
