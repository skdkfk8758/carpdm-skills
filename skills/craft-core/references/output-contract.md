# Output contract — 전 스킬 공통 종료 출력 규격 (SSOT)

> 이 파일이 carpdm-skills **모든 스킬의 종료 출력** 단일 소스다. 스킬은 이 규격을
> 읽어 emit 한다 — 복제하지 말 것(drift 차단). 한 스킬만 바꾸지 말고 이 파일을 바꿔라.
>
> craft-core 에 두지만 **엔진(4-phase pipeline) 의존이 아니다** — 출력 규격 한 장을
> 읽는 cross-cutting concern 일 뿐이다. handoff·sweep·land 처럼 pipeline 무의존
> 스킬도 이 파일만은 읽는다.

## 왜 이게 필요한가

스킬마다 종료 보고가 제각각이면 두 가지가 깨진다:

1. **완료 신호 누락.** 백그라운드 잡 classifier 는 메시지 **텍스트만** 읽어 완료를
   판정한다(tool 출력·subagent 보고는 안 본다). `result:` 줄이 그 유일한 신호인데
   일부 스킬만 emit 하면 나머지는 "완료"로 분류되지 않는다.
2. **산출물이 막다른 길.** 경로를 손으로 옮기게 하거나, 다음 워크플로로 손을 안
   건네면 산출물이 거기서 끊긴다.

해법은 **출력 전체를 통일하는 게 아니다** — 산출물 성질(commit / `.md` / 삭제목록 /
PR 보고)은 본질적으로 다르고, 본문 구조를 억지 통일하면 의미가 깨진다. 통일하는 것은
**종료 레이어**뿐이다. 본문은 스킬 자유.

## 레이어 × 스킬군 매트릭스

| 레이어 | 적용 | 비적용 |
|---|---|---|
| **R — 결과 보드** (본문 마지막 블록, L1 바로 위) | **코드를 바꾼 스킬** (forge/hunt/renew · harness-run · linear-goal) | 산출물·운영 스킬 (아래 §R 비적용 근거) |
| **L1 — `result:` 1줄** (완료 신호) | **전 스킬 의무** | 없음 |
| **L2 — 산출물 열기 블록** (`open` 경로) | 파일을 산출하는 스킬 | commit/삭제/머지 보고형 |
| **L3 — 다음 스킬 제안** (`AskUserQuestion`) | 산출물을 *전진*시키는 스킬 | 운영/정리 스킬 |

스킬군별 적용:

| 스킬군 | 스킬 | L1 | L2 | L3 |
|---|---|---|---|---|
| 빌드 | forge / hunt / renew | ✓ | — (commit 참조) | ✓ (pipeline Phase 5) |
| 설계·산출 | deep-interview / deep-plan | ✓ | ✓ | ✓ |
| 산출(단발) | deep-prompt / imprint / erd | ✓ | ✓ | — |
| 리뷰·판정 | preflight | ✓ | ✓ (docs/reviews) | ✓ (수정 라우팅) |
| 운영 | handoff / sweep / land | ✓ | handoff 만 ✓ | — |

L3 비적용 근거: `next-skill-routing.md` 가 sweep/land/handoff 를 "다음 후보 아님"으로
명시 배제한다 — 이들은 산출물을 전진시키는 스킬이 아니라 종착 운영이다.

## L1 — `result:` 줄 (전 스킬 의무, 고정)

스킬이 작업을 끝내고 멈추는 지점에서, **마지막 메시지에** 정확히 `result:` 로 시작하는
한 줄을 emit 한다.

```
result: <한 줄 — 무엇을 했는지. 핵심 수치 포함(파일 수, 커밋, 통과 테스트, % 등)>
```

규칙:

- **글자 그대로 `result:` 로 시작.** 백그라운드 잡 완료 신호로 쓰인다.
- **한 줄, self-contained** — 요청을 못 본 사람도 읽힌다("done"·"완료" 같은 말은 신호
  아님).
- 산출물이 아직 안정화 안 됐으면(push 후 CI 대기, 머지 후 settle 등) `result:` 가
  아니라 진행 narration 이다. `result:` 는 **납품 완료**에만.
- 스킬당 종료 시 **한 번**. 중간 단계에 쓰지 말 것.

## L2 — 산출물 열기 블록 (파일 산출 스킬)

파일을 산출하는 스킬은 `result:` 바로 아래에 산출물을 바로 열 수 있는 블록을 붙인다.

```
result: <L1 한 줄>

산출물 — 열기:
- <라벨> `<상대경로>`  →  `open <상대경로>`
- <라벨> `<상대경로>`  →  `open <상대경로>`

(`open` = macOS. Linux `xdg-open <path>`, Windows `start <path>`.)
```

규칙:

- **존재하는 산출물만** 행으로. 안 만든 산출물 행 금지(예: UI 가 아니라 HTML 시안을
  안 만들었으면 그 행 생략).
- **경로는 프로젝트 루트 기준 상대경로.** 절대경로 금지(환경마다 다름).
- **라벨은 한국어 한 단어급** — `PLAN` / `시안` / `SPEC` / `프롬프트` 처럼 즉시 식별.
- cross-platform 주석은 블록 맨 아래 **한 번만**. 매 행 반복 금지.

비적용(commit/삭제/머지 보고형): 산출물이 파일이 아니라 git 상태 변화다. 열기 블록
대신 각자 보고한다 — forge/hunt/renew 는 커밋, sweep 은 삭제 목록, land 는 머지/정리
요약. 이때도 L1 `result:` 줄은 **의무**.

### 스킬별 L2 매핑

| 스킬 | 열기 블록 행 |
|---|---|
| `deep-plan` | `PLAN` (`docs/plans/…md`) + (UI plan 이면) `시안` (`…html`) + (DB/BE plan 이면) `ERD` (`…-erd.html`) |
| `erd` | `ERD` (`docs/preview/…-erd.html` 또는 plan 동일 디렉토리 `…-erd.html`) |
| `deep-interview` | `SPEC` (`docs/specs/…md` 또는 프로젝트 spec 위치) |
| `deep-prompt` | `프롬프트` (`…md`) |
| `imprint` | 산출 디렉토리(테마/컴포넌트/preview) — 대표 `시안` (`…html`) |
| `preflight` | `리포트` (`docs/reviews/…-preflight.md`) |
| `handoff` (WRITE) | `핸드오프` (`…md`) |

## L3 — 다음 스킬 제안 (전진형 스킬)

산출물을 다음 워크플로로 전진시킬 수 있는 스킬은, `result:` 블록 **다음에**
`AskUserQuestion` 으로 다음 스킬을 한 번 추천한다(추천만 — 자동 시작 금지).

규칙·후보군·강도 추천·이중 인터뷰 회피 프레이밍은 모두
`~/.claude/skills/deep-interview/references/next-skill-routing.md` 에 산다(SSOT — 복제
금지). 이 contract 는 포인터일 뿐 규칙을 재기술하지 않는다.

- **deep-interview / deep-plan** — next-skill-routing.md 그대로.
- **forge / hunt / renew** — `pipeline.md` Phase 5 가 이미 next-skill-routing 메커니즘과
  동일하게 빌드 후 제안을 emit 한다. 별도 적용 불필요.
- **preflight** — L3 는 *산출물 전진*이 아니라 **발견→수정 라우팅**이다(blocker/시급
  should → forge/renew/hunt/simplify). next-skill-routing 의 *메커니즘 원칙*(설치 스킬
  Bash 스캔 금지·available-skills 에서 읽기·자동 시작 금지)만 공유하고 후보군 규칙은
  다르다 — preflight `SKILL.md` Step 5 가 SSOT. 고칠 게 없으면(GO) 생략.

## R — 결과 보드 (코드를 바꾼 스킬 전용)

작업을 끝낸 시점(빌드 wrap · 하니스 종료 · worker 완료 턴)에 결과를 **고정 행 셋**으로
정리하는 반고정 블록. **본문 마지막 = L1 바로 위**에 선다 — L1~L3 은 불변이고 보드가
그 위에 얹힌다(`result:` 는 여전히 보드 아래 마지막 줄 — classifier 파싱 순서 불변식).

**적용**: forge/hunt/renew(pipeline Phase 5 가 주입) · harness-run · linear-goal.
**비적용**: 산출물 스킬(deep-* 등 — L2 열기 블록이 그 역할) · 운영 스킬(land 등 —
자체 머지 보고). 범위를 넓히면 이 contract 가 경계한 "본문 억지 통일"로 되돌아간다.

> 축약판(스킬 미경유 코드 턴용 3+2행)이 글로벌 `~/.claude/rules/turn-result-board.md`
> 에 인라인으로 산다 — 여기 행 셋을 바꾸면 그 축약 5행과의 정합을 확인할 것(풀 보드
> SSOT 는 본 파일, 축약판은 의도적 인라인 — drift 표면 최소화 트레이드오프).

### 행 셋 (존재하는 행만 — 순서 고정)

```
┌ 결과 — <skill> · <topic/issue> ─────────────
 변경        N files (+A/−D) · <브랜치/워크트리>
   <경로>            <±Δ>  <무엇을 왜>     ← 파일별 1행, 10개 초과 시 상위 8 + "외 N files"
 커밋        N — <hash 단계 체인>
 <정체성 행>  스킬별 1행 (아래 표)
 테스트      +N 신규 (핵심 경계 케이스 명시) · <러너 X/X> · <타입체크>
 검증 커맨드  <실행한 명령> → <실제 출력 수치>   ← 재현 가능 증거, 1~3행
 결정        <주요 결정 + 트레이드오프> · ADR 여부
 평결        보안 <verdict> (근거 1구절) · intent <verdict>
 Acceptance  N/N [AUTO x · HUMAN y — 처리 방식]
 타이밍      phase 별 elapsed (est 대비) · total · 사람대기 분리   ← progress.md P4 와 같은 소스
 잔여        [HUMAN] 남은 수동 확인 · 코드 밖 후속
└─────────────────────────────────────────────
```

| 스킬 | 정체성 행 |
|---|---|
| forge | `신규 표면` — 추가된 엔드포인트/컴포넌트/contract |
| hunt | `재현` — 재현 커맨드 red 확인 → 회귀테스트 green 잠금 |
| renew | `보존 계약` — characterization N항 green · 마이그 경로 검증 |
| harness-run | `outcome` — pass/short-circuit · attempts 점수 궤적(예 `FAIL 76 → PASS 93`) + `게이트` — G0~G4 체크 현황 + `a<N> 감점` — 실패 attempt 의 카테고리·사유·verdict 경로 |
| linear-goal | `worker` — [DONE]/[FAIL] 자가보고 + `메인 재검증` — git diff·verify 재실행 결과 (R9: 자가보고만으론 완료 불인정) |

### 보드 6규칙

1. **존재하는 행만.** 안 한 것의 행 금지(L2 와 동일 원리) — 해당 없으면 행을 뺀다.
2. **모든 green 은 증거 동반.** 수치·경로·명령 재실행 결과 — "됐음" 금지
   (verification-safety V1: 이 명령이 실패했다면 지금 출력이 달랐을 것인가).
3. **타이밍은 est 대비 실측.** progress.md P4 와 같은 jsonl 소스 — 보드가 매 런의
   병목 보고를 겸한다(사람 대기 분리 표기).
4. **사람 몫은 명시적으로 남긴다.** [HUMAN] 잔여·머지 승인·수동 확인 — 보드가 "전부
   끝남"으로 위장하지 않는다. fail/미충족(short-circuit·needs input)도 같은 보드로
   정리한다(성공 전용 포맷 아님).
5. **L1 은 보드 아래 마지막 줄.** 순서 불변식 — 보드 도입이 `result:` 파싱을 깨면 안 된다.
6. **한 번 쓰고 재사용.** 턴 출력과 Linear 이슈 코멘트(`linear.md` §3b)가 **같은 본문** —
   채널별 재작성 금지(이중 SSOT 는 반드시 drift 난다).

## 적용 체크 (스킬 저작 시)

스킬 종료부를 쓸 때 자문:

1. 마지막 메시지가 `result:` 로 시작하는 한 줄을 내는가? (L1 — 전부 의무)
2. 파일을 산출했다면 열기 블록을 붙였는가? (L2 — 파일 산출 스킬)
3. 산출물이 전진형이면 next-skill-routing 으로 제안하는가? (L3 — 전진형만)
4. 코드를 바꿨다면 L1 바로 위에 결과 보드를 붙였는가? (R — 빌드/하니스/worker 스킬만.
   활성 Linear 이슈가 있으면 같은 보드를 코멘트로도 — `linear.md` §3b)

비적용 레이어는 명시적으로 비운다 — 억지로 채우지 말 것(운영 스킬에 다음 제안 강제
금지).
