---
name: harness-run
description: >-
  루프엔지니어링 하니스 오케스트레이터 — 한 이슈를 워크트리 분기 → 플랜+시안+eval rubric 생성 → G1 freeze → 자율 dev+eval 루프(재시도/단락) → pass면 G3 merge / 단락이면 G2 로 잇는다. 사람은 게이트(G0~G4)에서만 개입하고 나머지는 자동. 한 이슈를 하니스로 끝까지 굴리고 싶을 때 — "이 이슈 하니스로 돌려줘", "harness 돌려", "ADM-140 하니스로", "이슈 자동 개발", "풀 파이프라인으로 돌려줘", "게이트 걸고 진행해", "끝까지 자동으로 개발해줘", "빡세게/제대로 돌려줘" 처럼 'harness-run'·'스킬' 이란 말이 없어도 — 트리거. 세션에 `Linked Linear issue: <ID>` 배너가 붙은 이슈가 harness-class(estimate≥5·cross-cutting·전면개편)인데 사용자가 "이거 진행해줘"만 해도 이 스킬이 정경로다(linear-goal 이 안전판정에서 여기로 에스컬레이션하는 것과 같은 기준). 단일 기능 빌드(forge)·버그(hunt)·플랜만(deep-plan)·경량 티켓 실행(linear-goal) 에는 쓰지 말 것 — harness-run 은 그것들을 게이트로 엮는 상위 오케스트레이터다.
---

# harness-run — 하니스 오케스트레이터 (C1)

메인 루프가 구동하는 오케스트레이터. 자율 dev+eval 코어만 `Workflow`(아키텍처 하이브리드).
요구사항: `docs/specs/loop-engineering-harness/spec.md` REQ-F-001/002/003/007/008/009/010/014.
게이트 계약 SSOT: [`references/gate-contract.md`](references/gate-contract.md).

## 글로벌 SSOT 노트

이 스킬의 **SSOT 는 글로벌 사본**(`~/.claude/skills/`)이며 git 백킹은 `carpdm-skills`
레포(`skills/{harness-run,eval-generate,eval-check,harness-heal}`)다. 로컬 하니스 설치가
없는 프로젝트에서도 `harness-run` 을 바로 쓰게 한다.

- **SSOT = 글로벌(carpdm-skills 추적).** 로직 변경은 라이브 `~/.claude/skills/` 에서 하고 `sync.sh`/`ship` 으로 carpdm-skills 에 미러한다. (과거 SSOT 였던 IA `~/Workspace/Intelligence-Auth/.claude/skills/{harness-run,…}` 사본은 글로벌 단일 SSOT 이관으로 **제거됨** — 더는 거기서 먼저 고치지 않는다.)
- **스크립트 절대경로 + install.sh 재작성.** `dev-eval-loop.js`(Workflow scriptPath)·`validate-rubric.mjs`(eval-generate)·`score-rubric.mjs`(eval-check) 는 cwd 무관 동작을 위해 `/Users/carpdm/.claude/skills/...` 구체 절대경로를 쓴다(Workflow scriptPath 는 상대·`~` 불가). 타 머신 이식성은 `carpdm-skills/install.sh` 가 설치 시 home prefix 를 `$HOME` 으로 재작성해 해결(메인테이너 머신 no-op). 스크립트 자체는 인자 경로만 다루는 pure 로직이라 cwd 무관. `loop-harness-setup` 의 per-project 설치본은 상대경로(`.claude/skills/...`)를 유지한다.
- **우선순위.** 프로젝트에 로컬 하니스 설치가 있으면(loop-harness-setup) 프로젝트 스킬이 글로벌보다 우선 — 이 글로벌 SSOT 는 로컬 미설치 프로젝트에서 발동한다. 충돌 없음.
- **per-project 전제는 그대로.** 오버레이(`rules/harness-overlays/`)·eval 산물·워크트리·플랜 디렉토리는 여전히 작업 대상 프로젝트 기준(없으면 graceful). 글로벌화는 스킬 *로직*만 어디서나 부르게 할 뿐, 프로젝트 상태를 글로벌로 옮기지 않는다.

## 절대 규칙 (분리 무결성)

- **dev ≠ checker ≠ generator** — 셋 다 fresh-context 별 agent(REQ-F-007). dev 는 rubric 미열람, checker 만 frozen rubric(REQ-F-008).
- **dev 는 forge 아님** — 자율 루프 안에서 forge(orchestrated+인터뷰 게이트)를 돌리면 자율성·중첩이 깨진다. dev = 단일 빌드 agent.
- **게이트는 메인루프 pause** — Workflow 는 사람 입력을 못 받는다. G0~G4 는 이 스킬(메인루프)이 멈춰 처리.

## 9단계 ↔ 게이트 흐름

| 단계 | 누가 | 동작 |
|---|---|---|
| **G0** 이슈 intake | 사람 | 이슈 기술 수령(intake 는 수동; C3 Linear 후속). 이슈 slug 확정 + 활성 이슈 있으면 **Linear → In Progress** 자동 전이(graceful) |
| 워크트리 분기 | 자동 | `feat/<slug>` 워크트리 생성(commit-isolation 격리) |
| ② 플랜+시안+rubric | 자동 | `deep-plan`(플랜+HTML시안) → `eval-generate`(rubric, `frozen:false`) |
| **G1** 플랜타임 리뷰 ★ | 사람 | {플랜·시안·rubric} 한 번에 검토·수정 → **승인 시 rubric `frozen:true` 로 잠금** |
| ③④ dev+eval 루프 | 자동(Workflow) | `workflows/dev-eval-loop.js` 호출 — dev(단일 agent)→eval-check→`decideNext` 재시도/단락 |
| **G2** 실패 인터뷰 | 사람 | (단락 시) `harness-heal` 호출 — 진범 귀속 worksheet → 최고레버리지 1건 인터뷰 → 로컬 오버레이(`rules/harness-overlays/`) 개선 |
| **G3** merge | 사람 | (pass 시) `land` — PR→merge 승인→워크트리 정리(REQ-F-014) |
| **G4** prod 마이그 | 사람 | (마이그 포함 시) `db-migrate` prod 절차 — psql 개별 적용 + information_schema 검증(루프 밖) |

## Workflow (메인루프 실행 절차)

1. **G0** — 이슈 기술 받아 slug 확정. slug 확정 직후, 백그라운드 잡으로 돌고 있으면
   (`$CLAUDE_JOB_DIR` 존재) 이 세션 이름을 `[<issue-id>] <작업요약>`(slug 에서 이슈ID 추출,
   예 `[ADT-183] layer mgmt`; 이슈ID 없으면 `[<slug>]`)으로 rename 한다 —
   [`references/session-rename.md`](references/session-rename.md) 의 atomic snippet 그대로
   (`state.json` `name` + `nameSource:"user"`). 잡 컨텍스트 아니면 조용히 생략, 실패해도 hard
   gate 아님 — note 만 남기고 계속.
   - **Linear → In Progress (optional, graceful).** slug 에서 이슈ID 가 잡혔거나 사용자가
     이슈 ID/URL 을 줬으면, `~/.claude/skills/craft-core/references/linear.md` §3(빌드 중 상태
     전이 SSOT)을 lazy-load 해 그 활성 이슈를 **In Progress 로 자동 전이**한다(빌드 시작 시점 =
     G0 bind). 상태 이름은 하드코딩 말고 `list_issue_statuses` 로 조회해 매핑. Linear MCP
     미설치이거나 이슈ID 가 없으면 **묻지 말고** 스킵 — Linear 는 증강일 뿐 게이트하지 않는다.
     전이 실패(권한·네트워크)는 하니스를 막지 않는다(경고만). forge/hunt/renew 가 pipeline
     Phase 0 에서 하는 것과 동일 전이를 harness-run 은 G0 에서 한다.
2. **워크트리 — 자동 아님, 메인루프가 직접 수행·검증한다.** `git worktree add -b feat/<slug> ../<repo>--<slug>` 로 분기. **직후 `git worktree list | grep feat/<slug>` 로 생성 확인 — 안 보이면 STOP**(이 단계를 빠뜨리면 dev 가 메인트리서 돌아 분리무결성이 붕괴한다). 이후 모든 작업·Workflow `args.worktree` 는 이 워크트리 기준 — Workflow agent 의 cwd 는 launch 시점 메인세션 cwd 로 pin 되므로, 메인세션이 이 워크트리에 있어야 dev 가 거기서 돈다. `EnterWorktree` 는 deferred 도구(먼저 `ToolSearch` 로 로드)이고 이미 워크트리 세션이면 거부되니 — `git worktree add` 를 1순위로 쓴다.
3. **생성** — `deep-plan` 으로 플랜+시안, `eval-generate` 로 rubric+스텁(G1 검토용으로 `<worktree>/.eval/` 에 생성, frozen:false).
4. **G1 ★** — {플랜·시안·rubric} 을 `AskUserQuestion` 으로 제시. 승인 시 rubric 의 `"frozen": true` 로 수정(잠금). dev 가 보기 전에 freeze.
5. **eval 산물 격리(분리무결성 — REQ-F-008/N-001) ★** — freeze 후 dev-loop 전에 `.eval/`(rubric+tests)를 **워크트리 밖** `evalDir`(예: `<worktree>/../.eval-<slug>/`)로 이동하고 워크트리에서 제거한다. dev 워크트리엔 eval 산물이 0이어야 한다(dev 가 oracle 을 읽어 게이밍하는 채널 차단 — M2 dogfood 실측). `.eval/`·`.eval-run/` 는 gitignore — 브랜치에 커밋 금지.
6. **오버레이 주입(C4 소비경로)** — `rules/harness-overlays/{dev,deep-plan,eval-generate}.md` 존재 시 읽어둔다(메인루프는 fs 가능). deep-plan/eval-generate 호출 시 본문 주입, dev 는 `args.devOverlay` 로 전달.
7. **dev+eval** — `Workflow({ scriptPath: '/Users/carpdm/.claude/skills/harness-run/workflows/dev-eval-loop.js', args: { worktree, planPath, mockupPath, evalDir, maxRetries: 2, devOverlay } })`. checker 만 `evalDir` 받음. 반환 `{outcome, history, attempts}`. (글로벌 변형 — scriptPath 는 cwd 무관 절대경로. §글로벌 변형 노트.)
7. **분기** —
   - `outcome === 'pass'` → **G3**: `land` 로 PR→merge(사람 승인)→워크트리 정리.
   - `outcome === 'short-circuit'` → **G2**: `harness-heal` 호출(최종 verdict + 플랜 + frozen rubric 경로 전달) → 진범 귀속 → 1건 인터뷰 → 로컬 오버레이 개선 → 재진입. 같은 signature 2 heal-round 생존 시 에스컬레이트.
7. **G4** — 변경에 마이그가 포함됐으면, merge 후 별도로 `db-migrate` prod 절차(사람 게이트).

## 재시도/단락 규칙 (REQ-F-009/010)

`scripts/loop-control.mjs` 가 SSOT(단위테스트). `decideNext(history)`:
- 최신 pass → `pass` · 동일 signature 2연속 → `short-circuit`(조기) · 시도 ≥ 1+maxRetries(2) → `short-circuit`(cap) · 그 외 `retry`.
- dev-eval-loop Workflow 는 이 로직을 inline 미러(Workflow 는 import 불가 — 동기 유지).

## Task 진행 체크리스트 (컨벤션)

G0 에서 slug 확정 직후, 네이티브 Task 도구(`TaskCreate`)로 게이트 흐름을 페이즈
체크리스트로 시드한다 — 사용자가 대화턴에서 진행을 따라가는 표시다. 항목은 위
9단계 표의 행과 동형, **게이트 라벨 유지**:

`G0 — 이슈 intake` · `워크트리 분기 + 검증` · `② deep-plan + eval-generate` ·
`G1 — 플랜·시안·rubric 승인 + freeze + eval 격리` · `③④ dev+eval Workflow 루프` ·
`분기 — G3 land / G2 heal` · (마이그 포함 시) `G4 — prod 마이그`.

- 각 단계 진입 시 `TaskUpdate` `in_progress`, 완료 시 `completed` — 경계마다 빠짐없이.
  종료 시(pass/short-circuit) 전 항목이 닫혀 있어야 한다.
- ③④ Workflow 구간은 단일 항목을 in_progress 로 유지한다 — 내부 진행은
  `dev-eval-loop.js` 의 `phase()`/`log()` 진행트리가 담당(메인 루프 잠듦, Task 세분 금지).
- **게이트 레일 스냅샷 (progress.md P2).** 게이트 통과 시점마다 레일 1줄을 턴에
  재출력해 "지금 어느 게이트 앞인가"를 항상 답한다
  (`rail: G0─wt─②─G1★─③④─G3─G4` + 현 위치 표시). attempt 결과 log 는 점수 포함
  (`PASS 93` / `FAIL 76 <signature>`) — 포맷은
  `~/.claude/skills/craft-core/references/progress.md` §P2 를 읽어 따른다(복제 금지).

## loop 로그 기록 (컨벤션)

종료 시(pass/short-circuit) **오늘 날짜 파일** `loop/log/YYYY-MM-DD.md` 에 한 엔트리 append(없으면 H1=날짜로 생성) — 포맷은 `loop/log/README.md` 참조.

- `pass` → 분류 `NOTE`, "무엇"에 outcome·attempts, "게이트" G3.
- `short-circuit` → 분류 `ISSUE`, "무엇"에 최종 signature, "게이트" G2. (heal 라운드 결과는 `harness-heal` 이 별도 `HEAL` 엔트리로 append.)
- **타이밍 (병목 실측 — 항상 포함).** 각 단계 진입 시 `date +%s` 를 기록해 두고
  (G0 · 워크트리 · ② 생성 · G1 · ③④ Workflow · 종료), 엔트리에 한 줄 붙인다:
  `타이밍: ②plan+rubric Xs · G1대기 Ys(사람) · loop Zs/attempts N · total Ts`.
  **G1 대기(사람 승인)는 자동 구간과 반드시 분리 표기** — 사람 대기를 하니스
  병목으로 오인하지 않기 위함. Workflow 내부는 시계가 없으므로(`Date.now()` 금지)
  loop 구간은 메인루프의 호출 전/후 시각 차로 잰다. 기록 실패는 hard gate 아님.

메인루프는 fs 가능 — 종료 직전 Write/Edit 로 append. 자동 hook 아님(스킬 컨벤션).

## 가시화 HTML 동기 (컨벤션)

하니스 **구조**(게이트 G0~G4 · 스킬 구성 · `decideNext`/역할 분리 · 컴포넌트 맵)를 바꾸면 같은 변경에서 `loop/harness-visualization.html` 도 갱신한다 — HTML 은 본 SKILL.md·gate-contract·loop-control 의 **파생 산출물**이라 안 고치면 drift 난다. SSOT 경계는 `loop/README.md` 참조.

## 출력 보고

종료 시(pass/short-circuit 공통) **결과 보드**(`~/.claude/skills/craft-core/references/output-contract.md`
§R — 복제 금지)를 emit 한다. harness 정체성 행: `outcome`(pass/short-circuit + attempts
점수 궤적, 예 `FAIL 76 → PASS 93`) · `게이트`(G0~G4 체크 현황 + 다음 사람 게이트) ·
`a<N> 감점`(실패 attempt 의 카테고리·사유·verdict 경로). 공통 행: 변경(워크트리·files) ·
증거(verdict 경로·rubric frozen 유지·eval 산물 격리 확인) · 기록(loop 로그 append 여부) ·
타이밍(② · G1대기(사람) · loop/attempts · total).

보드 아래에 **검증 체크리스트**(output-contract §V — 복제 금지)를 붙인다 — eval
rubric 채점 항목을 자동 검증/직접 테스트/사용자 직접 확인 셋으로 가른다. 자율 루프라
`[HUMAN]` walk 이 없었으므로 미검증 `[HUMAN]` 항목은 전부 `[사용자 직접 확인 필요]`
체크박스로. 그 아래 **다음 단계 블록**(output-contract §N — 고정 3행 잔여/필수/권장,
항상 emit, 복제 금지)을 붙인다 — 잔여 = 미통과 게이트·short-circuit 사유(없으면 "없음 —
✅ 모든 작업 완료"), 필수 = pass 면 `/land`(G3), short-circuit 이면 `harness-heal`(G2).
그 아래 L1 `result:` 한 줄(이슈 slug · outcome · attempts · 다음 게이트). **활성
Linear 이슈가 있으면 같은 보드+체크리스트를 이슈 코멘트로 남긴다**(`linear.md` §3b —
자동·마스킹·실패 보드도 동일).
