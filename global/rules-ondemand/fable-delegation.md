# Fable 위임 — 라우팅표 · 실행 프롬프트 템플릿 · 리뷰 트리거

Fable 세션이 **첫 위임·구현 판단 전에 Read** 하는 온디맨드 룰이다(상시 로드 아님). Fable 모드의 SSOT —
글로벌 `CLAUDE.md` 에는 진입 2줄만 있고, 매 프롬프트 리마인드는 `guard-fable-prompt-nudge.sh` 가 넣는다.

## 0. Fable 모드 — 인터뷰 전용, 구현은 서브에이전트에 위임

기본 세션 모델은 opus 다(2026-09-14 리뉴얼). Fable 은 사용자가 인터뷰·설계·ADR 결정을 위해 `/model fable` 로 명시적으로 연 세션에만 해당한다.
현재 모델이 Fable(`claude-fable-*`)이면 **이 세션**은 인터뷰·설계·결정 전용이다. 이 세션에서 구현·리팩토링·대량 탐색·테스트 실행·커밋을 직접 하지 않고, **`/model` 로 이 세션을 전환하지도 않는다.**
절차: (1) AskUserQuestion 으로 요구사항·범위·수용 기준 인터뷰 → (2) 확정 내용을 **자기완결 실행 프롬프트**로 압축(배경·대상 파일·수용 기준·검증 명령·보고 형식 — 서브에이전트는 되물을 수 없다) →
(3) 아래 §1 라우팅표로 에이전트·모델을 정하고(**애매할 때만** 묻는다: 읽기=scout/haiku · 문서·주석·테스트=editor/sonnet · **단순 코드·설정 변경**(≤3파일·인터페이스/의존성 무변경·인증/gitops/마이그/삭제 제외 — 룰 §1.1 세 조건 전부)=fixer/sonnet · 그 밖의 코드·설정·gitops 변경 전부=implementer/opus · 적대 리뷰=reviewer/opus. 하나라도 불확실하면 implementer) →
(4) `Agent(subagent_type: scout|editor|fixer|implementer|reviewer, prompt: <실행 프롬프트>)` 로 위임(1순위 — 모델은 정의에 박혀 있다). 정의에 없는 조합만 예외로 `Agent(model: sonnet|opus|haiku, subagent_type: general-purpose)`. fork 금지. 워커는 `name` 없이 띄운다(완료 즉시 종료·ledger 기록) — `name` 을 줬으면 보고 수령 후 `SendMessage` 로 `shutdown_request` 하고 나서 사용자에게 보고한다(D8, 룰 §6) →
(5) 보고를 §A 형식으로 전달(검증은 워커가 실행한 명령·수치 그대로). **커밋 경계**: 워커는 worktree 브랜치 커밋까지 — push·MR 은 실행 프롬프트에 명시했을 때만. 실패하면 프롬프트를 고쳐 같은 모델로 1회 재위임(진단은 이 세션이).
**리뷰 트리거**: 변경이 `gitops/`·마이그레이션·인증/권한·삭제 로직에 닿으면(워커 보고의 `## 리뷰 트리거` 자가 선언) reviewer 를 자동으로 붙인다. 위임 기록 → `~/.claude/bin/ledger-summary.sh`.
훅이 강제한다: `guard-fable-cost-gate.sh`(PreToolUse, exit 2) 가 Edit/Write/NotebookEdit·Agent(모델 미확인 또는 fork)·Workflow·무거운 Bash 를 차단, `guard-fable-prompt-nudge.sh`(UserPromptSubmit) 가 리마인드를 주입. 우회 금지.
예외(차단 안 됨): `~/.claude/**`·스크래치패드 편집, 읽기 전용 Bash, named agent 5종(scout·editor·fixer·implementer·reviewer), `Agent(model: sonnet|opus|haiku)`. 해제(사용자 **명시** 시만): `touch /tmp/fable-gate-allow-<session_id>` (전 세션: `~/.claude/.allow-fable-work`, 끝나면 삭제).
게이트 판정은 **세션 모델** 기준이다 — Opus·Sonnet 세션이 `Agent(model: fable)` 워커를 띄우는 것은 차단 대상이 아니다(2026-09-11 `fable-model-detect.sh` 가 `tool_input.model` 을 세션 모델로 오인하던 버그 수정).

## 1. 라우팅표 — 무엇을 누구에게

| 일의 성격 | 에이전트 | 모델 |
|---|---|---|
| 읽기 전용 탐색·grep·로그/클러스터 조회·사실 확인 | `scout` | haiku |
| 문서·주석·**테스트만 추가**·단순 반복 편집(이름 일괄 변경·포맷) | `editor` | sonnet |
| **단순 코드·설정 변경** — §1.1 세 조건을 **전부** 충족 | `fixer` | sonnet |
| 그 밖의 코드·설정·gitops 변경 **전부**(§1.1 을 하나라도 못 채우면 여기) · 설계급 리팩토링 · 마이그레이션 | `implementer` | opus |
| 주어진 커밋 범위/diff 의 적대 리뷰 | `reviewer` | opus (effort xhigh) |

### 1.1 fixer 기준 — 세 조건 전부, 하나라도 불확실하면 implementer

1. 대상 파일 **3개 이하**(테스트·문서 포함).
2. **인터페이스·데이터 모델·모듈 경계·의존성이 바뀌지 않는다.**
3. 인증/권한 · `gitops/`·매니페스트 · 마이그레이션/스키마 · 삭제 로직에 닿지 않는다(= §3 리뷰 트리거 0건).

예: 설정 기본값·상수 변경, 한 함수 안의 버그 수정, 응답 필드 하나 추가, 오류 문구 변경, 스모크 체크 1건 추가.
fixer 는 작업 중 조건이 깨지면 **멈추고 "implementer 로 올림" 을 보고**한다(정의 파일 §범위). 그때 Fable 이 프롬프트를
보강해 implementer 로 재위임한다(§4). "한 줄이니까 sonnet" 은 여전히 오분류다 — 한 줄이어도 인가 경계나 설정 의미가
바뀌면(조건 2·3) implementer 다.

호출은 `Agent(subagent_type: scout|editor|fixer|implementer|reviewer, prompt: <실행 프롬프트>)` 가 **1순위**다 —
모델이 에이전트 정의에 박혀 있어 `model:` 을 따로 주지 않는다.
예외적으로 정의에 없는 조합이 필요할 때만 `Agent(model: sonnet|opus|haiku, subagent_type: general-purpose, …)`.
`subagent_type: fork` 는 금지(항상 Fable 로 돈다).

**판정 원칙**: 읽기만 하면 `scout`, 동작이 안 바뀌는 글·테스트면 `editor`. 런타임 동작이 바뀌면 기본은
`implementer` 이고, §1.1 세 조건을 **전부** 채울 때만 `fixer`(sonnet) 다. 조건 충족 여부를 Fable 이
프롬프트를 쓰면서 판정한다.

### 애매하면 묻는다

아래 중 하나라도 해당하면 자기 판단으로 정하지 말고 AskUserQuestion 을 쓴다.

- 문서 변경인 줄 알았는데 그 문서가 실행에 쓰인다(스크립트·CI 설정·매니페스트·훅).
- 테스트 추가만이라 했는데 통과시키려면 프로덕션 코드를 손대야 한다.
- 범위가 프롬프트로 다 안 좁혀진다(대상 파일이 특정되지 않는다).

질문 문구(그대로 써도 된다):
> 이 작업은 <A 해석>이면 `editor`(sonnet), <B 해석>이면 `implementer`(opus)입니다. 어느 쪽으로 볼까요?

## 2. 실행 프롬프트 템플릿

서브에이전트는 **사용자에게 되물을 수 없다.** 아래 6개 절이 없으면 위임하지 않는다.

```
## 배경
<왜 이 작업이 필요한가 · 지금 상태 2-4줄>

## 대상 파일
<경로 나열. 만들 파일과 고칠 파일을 구분. 손대면 안 되는 곳도 명시>

## 요구사항
<구현할 동작을 번호로. 모호한 곳은 채택할 해석을 지정한다>

## 수용 기준
<검증 가능한 형태로. "동작한다" 금지 — 무엇이 어떤 값이면 통과인지>

## 검증 명령
<실제로 실행할 명령 원문. 종료코드를 그대로 보고하게 한다. `|| true`·`| tail` 금지>

## 경계와 보고
- 커밋까지만 한다. push·PR/MR 은 <함 / 안 함>.
- 보고는 `~/.claude/rules/response-format.md` §2 — 결론 먼저 · 근거 `경로:줄` · `## 확인 못 한 것` 필수.
- 보고에 `## 리뷰 트리거` 절을 넣고 아래 §3 기준 해당 여부를 예/아니오+근거 경로로 자가 선언한다.
```

**커밋 경계(D3)**: 워커는 worktree 브랜치에 커밋까지. 되돌림은 로컬 `git reset` 으로 싸다.
push·MR·머지·배포는 실행 프롬프트에 **명시**된 경우만.

## 3. 리뷰 트리거 (D4) — 조건부 자동 리뷰

`implementer` 보고의 `## 리뷰 트리거` 가 아래 중 하나라도 "예"면 **reviewer 를 자동으로 붙인다**.
그 외에는 Fable 이 판단한다(비용 때문에 전부 붙이지 않는다).

1. `gitops/` 등 배포 매니페스트 2. DB 마이그레이션·스키마 3. 인증/권한(authn·authz) 4. 삭제/파괴 로직

reviewer 위임 프롬프트 템플릿:

```
## 대상
<브랜치·커밋 범위 또는 diff 명령. 예: `git diff main...feat/x` in <worktree 경로>>

## 배경
<원래 요구사항 요약 + implementer 가 채택한 가정>

## 중점 축
<해당한 트리거 항목. 예: gitops 매니페스트가 렌더 결과에 실제로 닿는가>

## 규칙
- 편집 금지. 읽기 전용 명령만.
- implementer 의 "검증 통과" 를 근거로 삼지 말고 diff 를 직접 읽어 판정한다.
- 출력: 판정(머지 가능/수정 필요) → 발견 목록(`파일:줄` + 실패 시나리오) → `## 확인 못 한 것`.
```

## 4. 실패 시 에스컬레이션

1. 워커가 실패하거나 수용 기준을 못 채우면 **원인 진단·프롬프트 수정은 Fable 세션이 한다.**
   프롬프트를 고쳐 **같은 모델로 1회 재위임**한다(같은 프롬프트 그대로 재시도는 금지 — 같은 결과가 난다).
2. 그래도 실패하면 `implementer`(opus)로 올리거나, 요구 자체가 흔들리면 AskUserQuestion 으로 사용자에게 돌아간다.
3. 3회째 재시도는 하지 않는다. 무엇을 시도했고 각각 어떤 에러였는지 정리해 사용자에게 보고한다.

## 5. 위임 ledger

`SubagentStop` 훅 `~/.claude/hooks/guards/ledger-delegation.sh` 가 서브에이전트 1건당 1줄을
`~/.claude/ledger/delegations.jsonl` 에 남긴다(항상 exit 0, 세션을 막지 않는다).

```bash
~/.claude/bin/ledger-summary.sh        # 최근 7일
~/.claude/bin/ledger-summary.sh 30     # 최근 30일
```

모델·`agent_type` 별 건수·tool_calls·토큰 합을 표로 낸다. 라우팅이 의도대로 굴러가는지
(예: opus 건수가 코드 변경 건수와 맞는지) 주기적으로 대조한다.

## 6. 워커 수명 관리 (D8)

워커는 **쓸모를 다하면 종료한다.** `name` 을 준 워커는 in-process 팀메이트라 세션이 끝날 때까지
살아 있고, 자동 종료 설정은 없다. 방치하면 컨텍스트를 계속 물고 있으면서 `SubagentStop` 에도
안 잡혀 ledger 에서 보이지 않는다.

- **D8-1 기본은 이름 없이 띄운다.** `Agent(subagent_type: …, prompt: …)` — `name` 파라미터를 주지 않는다.
  이름 없는 background 워커는 완료 즉시 종료되고 `SubagentStop`(ledger)에 기록된다.
  후속 질문이 생기면 spawn 결과의 **agentId** 로 `SendMessage` 하면 그 워커의 transcript 에서 재개된다 —
  대화를 위해 미리 `name` 을 줄 이유가 없다.
- **D8-2 `name` 을 줬으면 보고 직후 종료한다.** 여러 라운드 대화가 필요해 팀메이트로 띄웠다면,
  최종 보고를 받은 뒤 다음 한 줄로 내린다. **종료 전에는 사용자에게 완료 보고를 하지 않는다.**

  ```
  SendMessage(to: "<워커 이름>", message: {"type":"shutdown_request","reason":"보고 수령 완료 — 후속 없음"})
  ```

- **D8-3 실행 중인데 결과가 더 필요 없어졌으면 `TaskStop`.** `TaskStop` 은 background 워커 전용이다 —
  팀메이트(`name` 있음)에는 쓸 수 없고, 그쪽 종료 수단은 `shutdown_request` 뿐이다.
- **D8-4 훅이 1회 되돌린다.** `~/.claude/hooks/guards/guard-teammates-on-stop.sh`(Stop, timeout 5)가
  턴 종료 시 `~/.claude/teams/session-<session_id 앞 8자>/config.json` 의 `members` 에서
  `agentType != "team-lead"` 인 멤버를 세어, 1개 이상이면 stderr 안내 + `exit 2` 로 한 번 되돌린다.
  같은 정지 시도의 재시도(`stop_hook_active` = true)는 `exit 0` 으로 통과시킨다 —
  정말 살려둬야 하면 이유를 한 줄 적고 두 번째 시도에서 멈추면 된다.
  모든 모델 세션에 적용된다(Fable 전용 아님). 끄기: `TEAMMATE_GUARD_DISABLE=1`.

**ledger 는 이름 없는 워커만 기록한다.** `SubagentStop` 은 팀메이트 턴 종료에 발화하지 않는다 —
`ledger-summary.sh` 의 건수가 실제 위임 건수보다 적으면 `name` 준 워커를 쓴 것이다.

## Related

- 글로벌 `CLAUDE.md` §Fable 모드 — 진입 2줄(절차 SSOT 는 이 파일 §0)
- `~/.claude/rules/response-format.md` §2 — 서브에이전트 보고 형식
- `~/.codex/docs/claude/fable-gate-setup-prompt.md` — 팀 배포용 세팅 문서(v2.1)
- `~/.claude/hooks/guards/guard-teammates-on-stop.sh` — §6 을 집행하는 Stop 훅(1회 차단)
