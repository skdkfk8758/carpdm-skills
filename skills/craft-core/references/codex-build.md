# Cross-model build lane (②′) — codex owns green, Claude owns red+verify

Phase 3 의 **opt-in** 확장. codex 를 cross-model *구현자* 로 참여시킨다 — red→green→
refactor 의 **green 스텝만** codex 가 맡고, red 작성·독립 verify·refactor 는 Claude 가
쥔다. Orca 가 워크트리/터미널 lifecycle 을 소유한다. Phase 2 가 cross-model *리뷰* 로
독립성을 사듯, 이 레인은 cross-model *구현* 으로 대칭이다.

이 파일은 델타다. red-green-refactor 정의·모델 규칙 SSOT 는 `dynamic-tdd.md` / `tdd`
스킬. 여기 복제하지 않는다.

## 발동 게이트 (기본 off)

- **linear 기본 = 무변경.** codex 구현 참여 안 함 (세션이 최상위 티어면 불필요).
- **opt-in**: `--codex-build` 플래그, 또는 orchestrated 모드에서 명시 요청 시.
- codex 가 품질 업그레이드라는 보장 없음 — 세션이 최상위 티어(fable/opus 급)면
  codex 의 값은 *품질* 이 아니라 *독립성*(다른 모델의 diff). 그 독립성이 비용을
  정당화할 때(고위험·설계 다양성)만 켠다.

## 불변식 (설계 토대)

**Claude Workflow 구현이 floor. codex 는 opt-in 증강.** codex 가 어떤 이유로든
(limit·hang·red diff) 못 내면 → 현행 검증된 Claude Workflow 경로로 degrade.
**최악의 경우 = 지금 동작.** red 테스트가 진짜 oracle — codex 출력은 권고, 통과 못
하면 자동 폐기.

## Stage 1 분기 (dynamic-tdd Stage 1 대체 — `--codex-build` 발동 시만)

현행 Stage 1 은 Claude subagent 가 red+green+refactor 를 통째로 한다. 발동 시 green
스텝만 codex 로:

```javascript
async function greenViaCodex(t) {
  // 1) RED — Claude 가 실패 테스트 작성 + 올바른 이유로 fail 확인 (oracle 소유)
  const red = await agent(
    `Write ONLY the failing test for: ${t.spec}. Confirm it fails for the right ` +
    `reason (not typo/import). Report the test file path + the exact test command.`,
    { label: `red:${t.id}`, phase: 'Implement', schema: RED });
  if (!red.failsForRightReason) return claudeFallback(t, red);

  // 2) GREEN — codex 가 격리 워크트리에서 최소 구현 (아래 드라이버)
  const green = await driveCodexGreen(t, red);      // {status, worktreePath, jsonl}
  if (green.status !== 'ok') return claudeFallback(t, red, green);

  // 3) VERIFY — Claude(haiku) 가 격리 워크트리에서 독립 재실행 (구현자 불신)
  const v = await agent(
    `In worktree ${green.worktreePath}, run "${red.testCommand}". Report testsGreen ` +
    `honestly — do not trust codex.`,
    { label: `verify:${t.id}`, phase: 'Verify', model: 'haiku', effort: 'low', schema: RESULT });
  if (!v.testsGreen) return claudeFallback(t, red, green);  // codex diff red → 워크트리 폐기

  await mergeBack(green.worktreePath);              // green 확인된 diff 만 메인 트리로
  return { ...v, builtBy: 'codex', task: t.id };
}
```

- **refactor** 는 codex 에 안 맡긴다 — green 확정 후 Phase 3.5 simplify pass 가
  Claude 로 정리한다.
- **claudeFallback** = 현행 Stage 1 그대로 (Claude subagent red+green+refactor). floor.
- `red` 테스트 파일은 codex green 워크트리에도 있어야 verify 가 같은 트리에서 돈다 —
  워크트리 분기 후 red 커밋/스테이지, 그 위에서 codex green.

## codex green 드라이버 (Orca + `codex exec`) — 실측 확정

Orca 가 워크트리 lifecycle·card status 를 소유하고, 그 안에서 `codex exec --json`
비대화 실행으로 구조화 이벤트를 회수한다. 대화 TUI(`--agent codex`)는 JSONL 회수가
거칠어 green 스텝엔 **exec 모드** 를 쓴다.

```bash
# a) 격리 워크트리 (Orca lifecycle 소유, merge-back 가시성)
orca worktree create --name green-<taskId> --parent-worktree active --json   # → wtId, wtPath

# b) codex 비대화 — workspace-write 샌드박스(워크트리 밖 못 나감, 승인 프롬프트 없음=hang 없음)
orca terminal create --worktree id:<wtId> --title green-<taskId> --command \
  'codex exec --json -s workspace-write -C <wtPath> -o .codex-last.txt \
     "<green brief: red 테스트 X 를 최소 구현으로 통과. YAGNI. 테스트 자체는 수정 금지." \
     > .codex-green.jsonl 2> .codex-green.err' --json     # → termHandle

# c) 완료 대기 + 회수 (watchdog: 아래)
orca terminal wait --terminal <termHandle> --for exit --timeout-ms <T> --json
orca terminal read  --terminal <termHandle> --json        # + 워크트리 .codex-green.jsonl 파싱
```

**실측 이벤트 스키마 (codex-cli 0.144.4 `exec --json`):**

| 이벤트 | 의미 |
|---|---|
| `{"type":"thread.started","thread_id":…}` | 세션 시작 |
| `{"type":"turn.started"}` | 턴 시작 |
| `{"type":"item.started"/"item.completed","item":{"type":"error","message":…}}` | 아이템 에러 — **치명 아님**(config 경고도 여기로) |
| `… "item":{"type":"command_execution",…}}` | codex 가 shell 명령 실행 |
| `… "item":{"type":"file_change",…}}` | **파일 write 발생** (green 활동 신호) |
| `… "item":{"type":"agent_message","text":…}}` | 에이전트 산출 |
| `{"type":"turn.completed","usage":{input_tokens,cached_input_tokens,output_tokens,reasoning_output_tokens}}` | 턴 정상 종료 + 사용량 |

- **성공 판정 = `turn.completed` 존재 AND exit 0** (진짜 oracle 은 위 verify 스텝).
- **함정(실측 2회 재확인): `error` 아이템 ≠ 실패.** 한 런에 config-경고 `error`
  아이템 24~25개가 떠도 turn 정상 완료. 치명 판정을 error 아이템 매칭으로 하면 오탐 —
  치명은 **turn 종결성**(turn.completed 부재)과 **exit code** 로만 판정한다.
- **그린 스텝 write 검증(실측):** `codex exec -s workspace-write` 로 hello.txt 생성 →
  exit 0 · turn.completed 1 · file_change 이벤트 · 파일 실제 write 확인. green 스텝
  드라이버 end-to-end 동작.

## codex limit 처리 래더

`delegated-review-watchdog` · `browser-verify-fallback` 동형. driveCodexGreen 안:

### 분류 (구조화 이벤트 우선, 문자열 보조)

```
codex 종료 후:
  exit==0 && turn.completed 있음                 → OK (verify 로)
  exit!=0 || turn.completed 없음 || turn.failed  → FATAL → 분류:
      ├─ transient : 429 · "rate limit" · "try again in Ns"
      ├─ hard-cap  : "usage limit" · "quota" · "weekly/daily limit reached"
      ├─ auth      : "not logged in" · "invalid api key"
      └─ unknown   : 그 외 전부 → hard-cap 과 동일 취급(안전 폴백)
  wait timeout(진행 정지)                         → HANG → kill → 폴백
```

> **limit 정확 문자열 = 미확정(medium).** 트리거 관측을 못 해(quota 정상), unknown
> fatal 을 hard-cap 으로 격하 → 무조건 Claude 폴백. floor 불변식이 정확 문자열 없이도
> 성립하는 안전판. 실제 limit 1회 관측 시 transient/hard 구분 문자열만 추가하면
> 백오프 최적화가 켜진다(그 전엔 전부 폴백).

### 처리

```
transient : 백오프 [30s→60s→120s], codex 가 "try again in Ns" 주면 그 값 존중,
            max 2회. 초과 → hard-cap 취급.
hard-cap  : 서킷 브레이커 flip: session.codexAvailable=false → 현재 태스크 즉시
            claudeFallback.
auth      : fail-fast, 사용자 고지, claudeFallback + 서킷 오픈.
hang      : orca terminal stop → claudeFallback.
```

### 서킷 브레이커 (효율 핵심)

hard-cap 은 태스크 하나가 아니라 **윈도 전체 소진** — t4 에서 걸리면 t5·t6 도 같이
걸린다. 첫 hard-cap(또는 auth, 또는 transient 재시도 소진)에서
`session.codexAvailable=false` flip → 남은 태스크 전부 codex 스킵하고 Claude 직행.
N번 헛 라운드트립 방지.

### 부분 diff 안전

codex 가 limit 전 파일 일부만 write 했을 수 있음 → **격리 워크트리가 방어**: codex
diff 는 verify green 확인 전엔 메인 트리에 안 들어온다. red/limit 이면 워크트리 폐기
(`orca worktree rm --worktree id:<wtId> --force`) → 부분 diff 소멸. red 테스트가 안전망.

### preflight (선택)

무거운 codex 빌드 전 값싼 probe 1회로 이미 limit 인지 확인 → limit 이면 이번 런
codex 통째 스킵 + 고지. codex 가 quota 를 쉽게 안 노출하면 lazy 탐지(첫 태스크) +
서킷 브레이커로 충분 — preflight 는 optional.

## 보고 (침묵 스왑 금지)

Phase 5 wrap 에 builtBy 를 태스크별로 명시 (claim-retraction 정신):

```
codex 구현: t1,t3 (2 tasks)
codex usage limit @ t4 → 서킷 오픈, 폴백
Claude 폴백 구현: t4,t5,t6 (3 tasks)
전 태스크 green, Phase 4 secure verify pass
```

codex→Claude 조용한 교체 금지.

## 불변 (codex 무엇을 짜든)

Phase 3 형제 회귀 최종 게이트 + Phase 4 secure verify + intent conformance 는 Claude
가 그대로 돈다. codex 출력은 권고 — 핵심 발견은 직접 재검증(Phase 2 원장 규율 동형).
보안 불변식은 항상 `[AUTO]` — codex diff 도 예외 없음.

## TO-CONFIRM (실측 1회로 확정 — 그 전엔 안전 폴백으로 동작)

- codex limit(429/usage-cap) 실제 message/event 문자열 — quota 소진 시점 캡처.
- `turn.failed`/`turn.aborted` 이벤트 정확 명칭 (성공만 관측됨).
- codex 사용자 config 위생: 실측 중 duplicate agent role(24건) + GitHub Copilot MCP
  auth 실패(stderr) 발견 — 본 레인 무관하나 codex 환경 노이즈원.

## Anti-patterns

- codex 에 red 테스트 작성을 맡기기 — 자기 채점. red 는 Claude 가 쥔다.
- codex "green" 을 verify 없이 신뢰 — 독립 haiku verify 가 oracle.
- `error` 아이템으로 치명 판정 — 오탐(config 경고도 error). turn 종결성으로 판정.
- codex diff 를 verify 전 메인 트리 merge — 부분 diff 오염. 격리 워크트리 경유.
- hard-cap 후 남은 태스크도 codex 재시도 — 서킷 브레이커로 차단.
- codex→Claude 폴백을 조용히 — builtBy 보고 누락.

## Related

- `dynamic-tdd.md` — Phase 3 모델 규칙·Stage 골격 SSOT (이 파일이 그 위 opt-in 델타).
- `codex-review.md` — Phase 2 cross-model *리뷰*(read-only). 이 파일은 cross-model *구현*.
- `~/.claude/rules/delegated-review-watchdog.md` — limit/hang 래더의 상위 규칙.
- `~/.claude/skills/orca-cli/SKILL.md` — Orca 워크트리/터미널 드라이버 SSOT.
