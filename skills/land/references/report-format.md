# Land Report — 수집 · 판정 · 렌더 (Step 6 에서 읽는다)

Step 6 은 이 파일 **하나**를 읽어 report 를 만든다. SKILL.md 는 진입 조건과 고정 순서만
들고 있고 — 무엇을 모으고, 무엇을 판정하고, 어떻게 그리는지는 전부 여기다.
**lazy-read** — Step 6 전에 미리 읽지 않는다.

land 는 보통 새 세션에서 돈다. 유저는 방금 머지한 게 무엇이었고 그 설계 근거가 어디
적혀 있는지 기억이 흐릿하다. 그래서 report 는 "머지함" 통보가 아니라 **나중에 다시 읽어도
무엇이 배에 실렸는지 아는 짧은 변경 기록**이다.

## 0. 고정 순서

**① 한 일 요약 수집 → ② 세션 rename → ③ report 본문 → ④ `▶ 다음 단계` → ⑤ `result:`**

rename 을 건너뛰고 곧장 report/`result:` 로 가지 말 것 — 이 스킵이 "land 후 세션 이름이
안 바뀐다"의 원인이다.

## 1. 세션 이름 설정 (백그라운드 잡 + 1건 이상 머지일 때만)

이 세션이 백그라운드 잡으로 돌고(`$CLAUDE_JOB_DIR` 존재) 실제로 1건 이상 머지됐으면,
report 와 `result:` 를 내기 **전에** 세션 이름을 랜딩 결과로 바꾼다. land 의 마지막 단계이지
선택적 아사이드가 아니다.

- 실행: `~/.claude/skills/craft-core/references/session-rename.md`(공유 SSOT — 포맷 표의
  land 행)의 atomic snippet 그대로(`state.json` `name` 갱신 + `nameSource:"user"` — 하니스
  auto-rename 차단). 포맷: 단일 `landed #451 fix(make)`(연결 이슈 있으면
  `landed [ADT-33] fix(make)`), 다수 `landed 3 PRs`.
- **조용히 생략하는 경우는 둘뿐**: 잡 컨텍스트 아님(`$CLAUDE_JOB_DIR` 없음) 또는 머지 0건.
  그 외엔 반드시 실행한다. 실행이 실패하면(파일·권한) note 1줄 남기고 보고는 계속 —
  단 "실패해도 됨"이 "안 해도 됨"은 아니다.

## 2. 머지된 PR 마다 수집

이 메타데이터는 머지·브랜치 삭제 뒤에도 `gh pr view <n>` 으로 읽힌다(머지 전 Discover 에서
미리 캐싱해 둬도 좋다).

- **한 일 요약(1~2줄)**: `gh pr view <n> --json title,body,commits` 에서 압축한다.
  PR body 의 "변경/Summary" 섹션이나 커밋 메시지 제목들이 근거다. 진단·추측이 아니라
  실제 PR 내용을 근거로 — 없으면 커밋 제목을 그대로 쓴다.
  (land 자신이 Step 0 에서 올린 PR 은 `## 변경`/`## 설계` body 를 갖고 있어야 한다 —
  SKILL.md Step 0 의 body 조립 규칙. `--fill` 로 때운 PR 이면 여기서 품질이 떨어진다.)
- **설계·문서 링크**: PR body·커밋 메시지·변경 파일에서 설계 산출물을 긁는다 —
  - PR body/커밋 텍스트에 박힌 경로·URL: `docs/plans/…`, `docs/specs/…`, `docs/adr/…`,
    `docs/reference/…`, Linear 이슈(`ADT-\d+`, `linear.app/…`), 외부 설계 링크.
  - `gh pr view <n> --json files` 의 변경 파일 중 `docs/**`(특히 `plans/`·`specs/`·`adr/`) —
    그 작업의 설계 문서는 보통 같은 PR 안에 함께 들어온다.
  - 찾은 링크는 클릭 가능하게 — 레포 상대경로(예: `docs/plans/2026-06-29-x.md`)는
    마크다운 링크로, 이슈/PR 은 전체 URL 로. **없으면 생략한다 — 추측해 만들어내지 말 것.**

## 3. 잔여 작업 판정 — 3 소스

랜딩이 끝났다고 작업이 다 끝난 건 아니다. "모두 끝났는가"에 명시적으로 답한다:

- **이번 실행 잔여 (git, 항상)**: Skipped/미완 PR(대기 상한 초과 포함), conflict 로 멈춘
  rebase, 워크트리 점유로 삭제 보류된 브랜치, `-d` 가 거부하고 PR 도 미머지인 브랜치
  (SKILL.md Step 5.2 의 survivor), 기본 브랜치보다 ahead 인데 머지 안 된 로컬 브랜치
  (`git rev-list --count <default>..<branch>` > 0), dirty 워크트리.
- **Linear 연결 이슈 잔여 (graceful — Step 5.5 Done 전이와 같은 조건)**: 이번 land 의
  연결 이슈 중 Done 못 간 것(AC 미체크로 In Review 잔류 포함), 그 parent 이슈의
  다른 미완 sub-issue. Linear MCP 가 없거나 연결 이슈가 없으면 조용히 생략.
- **세션 히스토리 잔여 (graceful)**: `docs/handoff/` 에 이번 랜딩 작업과 같은 스레드의
  handoff 문서가 있으면 그 "남은 작업" 섹션을 대조한다 — 랜딩으로 소진됐으면 잔여
  아님(소진 사실만 언급, 삭제는 handoff/sweep 의 일), 미완 항목이 남았으면 잔여다.
  디렉터리가 없으면 생략.

## 4. `▶ 다음 단계` 블록 행 매핑

스캔 결과는 **다음 단계 블록**(`~/.claude/references/craft/output-contract.md`
§N — 고정 3행 `잔여/필수/권장`, 블록 생략 금지, 규칙은 거기가 SSOT — 복제 금지)으로 emit
한다. 위치: report 본문 아래, `result:` 바로 위. land 의 행 매핑:

- **잔여** = 3-소스 스캔 결과 그대로 — 항목마다 출처(git/Linear/handoff) + 라우팅
  1줄(미머지 브랜치 → 이어서 작업 후 다시 land, 미완 이슈 → `linear-goal <ID>`,
  handoff 잔여 → handoff 로 재개). 잔여 0건일 때만 `없음 — ✅ 모든 작업 완료`.
- **필수** = 이번 land 가 만든, 안 하면 미완/위험으로 남는 후속만 — conflict 로 멈춘
  rebase 해소, `## ⚠ 마이그레이션` prod apply, deps 변경 시 `npm install`. 없으면 "없음".
- **권장** = **잔여 0건(완료 선언)일 때만** 두 가지 — ① 잔여 워크트리 `wt-sweep` 안내
  (모두 랜딩됐으니 지금이 치워도 안전한 시점) ② 다음 티켓 선정이 필요해 보이면
  `linear-prioritize` 한 줄 ③ **repo 가 GitLab 호스팅이고 `.gitlab-ci.yml` 에 태그 릴리즈 잡이 있으면**
  `git describe --tags --abbrev=0 --match 'v*'` 이후 릴리즈 라인 커밋 수를 세어 `미릴리즈 N 커밋 → /launch`
  한 줄(0 이면 생략, GitHub repo 면 생략 — launch 는 GitLab 전용). **잔여가 있으면 셋 다 권하지 않는다**
  (미머지 작업이 남은 워크트리 정리 유도 금지 — 워크트리는 Local sync 에 목록만).
  land 는 다음 작업 후보를 **직접 조회하지 않는다** — 스프린트 플래닝은 `linear-prioritize`
  의 일이고, 여기서 축약 재구현하지 않는다.

**"다 끝났나"에 답하는 것은 잔여 행 하나다.** 유저가 "이거 다 끝난 거야?" 라고 물어도
블록 아래에 `**완료 여부: 아니오 — …**` 같은 요약 문단을 따로 쓰지 말 것 — 잔여 행이 이미
그 답이고, 문단을 덧붙이면 같은 판정이 두 번 나오면서 **블록이 마지막이라는 순서 규칙이
깨진다**(블록 다음은 `result:` 뿐이다). 판정 근거를 더 보여야 하면 잔여 행의 항목 자체를
구체적으로 쓰고, 문단을 새로 만들지 않는다.

## 5. 조건부 섹션

- **`## Skipped` / `## ⚠ 미완`** — conflict 로 멈춘 rebase, 막혀서 제외된 PR, 대기 상한
  초과 PR. 아무것도 조용히 빠져나가지 않게 명시.
- **`## ⚠ 마이그레이션` (해당 시 필수)** — 머지된 PR 의 변경 파일(`gh pr view <n> --json files`)에
  DB 마이그레이션(`migrations/` 경로, `*.up.sql`/`*.down.sql`)이 있으면 넣는다.
  **머지 ≠ DB 적용**이다(운영 apply 는 slow-lane 수동, `orm-stack.md` §slow-lane /
  `branch-worktree-strategy.md` §6b). 마이그 파일 목록 + "prod 미적용 — apply 후
  `information_schema` 실객체 조회로 applied 검증 필요(exit 0 은 증거 아님,
  verification-safety V3)". land 가 apply 를 대신 실행하지는 않는다(온프레미스 배포는
  사용자 직접 관리). 마이그 PR 을 이 섹션 없이 조용히 landed 로만 보고하지 말 것.
- **`## ⚠ deps 변경`** — Step 5.1 의 lockfile 감지 결과(worktree 별 `node_modules` 분리 탓에
  main repo 부팅 실패 위험). lockfile 목록 + `npm install` 제안.
- **`## ⚠ 문서 drift`** — Step 5.6 스캔 결과. rename·삭제된 심볼/파일/엔드포인트를 참조하는
  STALE 히트를 `path:line` 으로 나열하고 잔여 행에 후속 수정을 남긴다. 히트 0건이면 섹션 생략.
- **Orca 감지 시 워크트리 표기·카드 갱신** — `references/orca.md`. 워크트리 줄을
  displayName + workspaceStatus + 라이브 attach 로 쓰고, 머지된 PR 의 head 워크트리 카드를
  `--workspace-status completed --comment "landed #<n>"` 로 갱신. 저위험 write, 실패해도 무시.
  **워크트리 *제거* 는 하지 않는다**(wt-sweep 소관).

## 6. 렌더 — 카드형

맨 위 한눈 요약, 그 아래 PR 카드, 마지막에 휘발성 sync. 영속 changelog(Landed)를 시각적으로
1순위에, 운영 정리(Local sync)를 부차로 둔다. 머지 건수에 따라 두 형태로 graceful 하게 줄인다.

### 다수 PR (2건+)

```
🚢 Landed N · ⏭ Skipped M · 🔧 Synced
────────────────────────

## Landed

▸ [#451](PR 전체 URL) · fix(make)
  NestJS+Vite 잔재 제거 · make dev→npm run dev(next :3000) · find-free-port.sh 삭제
  ↳ [plan](docs/plans/2026-06-29-makefile-next.md) · ADT-33

▸ [#450](PR 전체 URL) · feat(api)
  …한 일 1~2줄, `·` 구분…
  ↳ [spec](docs/specs/…md) · ADT-31

## Skipped
⏭ [#46](PR 전체 URL) refactor auth — CI 실패 (재시도 후 다시 land)

## Local sync
develop `→ <sha>` · [refactor-auth] rebase · 잔여 워크트리 [stoic-wu]

▶ 다음 단계
 잔여   refactor-auth — 미머지 커밋 3건 (git) → 이어서 작업 후 다시 land
        ADT-33 — AC 미체크 2건, In Review 잔류 (Linear) → 체크 후 Done
 필수   없음
```

### 단일 PR — 요약 헤더·구분선·섹션 헤딩 생략, 카드 1개 + sync 1줄로 압축

```
🚢 Landed [#451](PR 전체 URL) · fix(make)
NestJS+Vite 잔재 제거 · make dev→npm run dev(next :3000) · find-free-port.sh 삭제
↳ [plan](docs/plans/2026-06-29-makefile-next.md) · ADT-33

🔧 develop `→ <sha>` · 브랜치 정리

▶ 다음 단계
 잔여   없음 — ✅ 모든 작업 완료
 필수   없음
 권장   wt-sweep — 잔여 워크트리 [stoic-wu] 정리 (모두 랜딩됨, 지금이 안전 시점)
```

### 포맷 규칙

- **요약 헤더**(`🚢 Landed N · ⏭ Skipped M · 🔧 Synced`)는 **2건+ 일 때만**. 스크롤 없이
  카운트 한눈에. 단일 PR 은 생략.
- **구분선** = box-drawing `─` 반복. markdown `---` **금지** — 바로 위 요약줄을 setext
  H2 헤딩으로 오인 렌더한다. 단일 PR 은 구분선 자체를 생략.
- **카드 헤더** = `▸ [#N](url) · <type(scope)>` — PR 은 전체 URL 링크, type/scope 는 커밋
  제목에서. **URL 을 얻을 수 없으면**(오프라인·`gh` 불가) 링크 없이 `▸ #N · <type(scope)>`
  로 쓰고 그 사실을 Local sync 에 1줄 남긴다 — URL 을 조립해 지어내지 말 것(설계 링크와
  같은 원칙). **한 일**은 헤더 아래 2칸 들여쓰기 `·` 구분 1~2줄. **설계·이슈 링크**는 `↳`
  줄로 분리(없으면 `↳` 줄 통째 생략 — 추측 금지, §2 수집 규칙 그대로).
- **카드 순서 = 머지한 순서**(Confirm 플랜의 순서 그대로). PR 번호 오름/내림차순이 아니라
  실제 랜딩 순서다 — stack 의 부모→자식 순서가 보존돼야 변경 기록으로 읽힌다.
- **글리프 고정**: 🚢 Landed · ⏭ Skipped · 🔧 Local/Synced. 그 외 이모지 남발 금지(노이즈).
- **잔여 워크트리 표기** = 기본은 경로/이름 나열(`잔여 워크트리 [stoic-wu]`). Orca 가 감지되면
  `land 리뉴얼 (in-progress · 에이전트 1 attach · #451 merged)` 처럼 displayName +
  workspaceStatus + 라이브 attach 로 쓴다(§5 / `references/orca.md`).
- **`▶ 다음 단계` 블록 = 항상 마지막**(`result:` 직전) — 고정 3행 잔여/필수/권장. 항목 형식
  `<대상> — <상태> (<출처 git/Linear/handoff>) → <라우팅>`. 잔여 0건일 때만
  `없음 — ✅ 모든 작업 완료` + 권장 행. 잔여 있으면 완료 선언·wt-sweep 안내 금지.
  Local sync 의 워크트리 목록은 두 경우 모두 유지(목록만). **블록과 `result:` 사이에는
  아무것도 넣지 않는다** — 완료 판정 요약 문단도 포함(§4).
- **AC 미체크 고정 표기** — Linear 이슈가 미체크 수용 기준 때문에 Done 못 가고 In Review 로
  남았으면 잔여 행에 `⚠ AC 미체크 <n>건 (<ISSUE-ID>)` 를 **이 문자열 형태 그대로** 넣는다.
  자연어로 풀어 쓰면(“수용 기준 2건이 미체크라…”) 뜻은 같아도 스캔·grep 이 안 된다.

## 7. `result:` — 마지막 한 줄

`~/.claude/references/craft/output-contract.md` L1(전 스킬 공통, 백그라운드 잡
완료 신호). 머지/정리 수치를 담되 self-contained 로:

```
result: N개 PR 머지 — 로컬 <default> 동기화, M개 브랜치 정리, K개 rebase
```

- 산출물이 git 상태 변화라 **열기 블록(L2)은 비적용**.
- **다음 스킬 제안(L3)도 비적용** — 운영 스킬이라 `next-skill-routing.md` 가 배제한다.
  후속 안내는 `▶ 다음 단계`의 권장 행이 담당한다.
- conflict 로 멈춘 rebase 가 있으면 `result:` 가 아니라 진행 상태로 보고한다(미납품).
