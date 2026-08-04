# ADR 003 — 하네스 최소화 (룰 코퍼스·스킬·벤더 진입점)

- Status: Accepted
- Date: 2026-08-04
- Context source: 실측 감사 (80세션 / 13,692턴 / 2026-07-29~08-04)

## Context

개인 하네스의 상시 로딩 지침이 **12편 54,352 bytes** 였다. 실사용을 재 보니 어시스턴트
출력에서 룰 슬러그가 언급된 것은 **61건 / 13,692턴** 이었고, 그중 상당수는 하네스 자체를
논한 메타 언급이었다.

더 중요한 건 **지침이 자기 자신에 대해 거짓을 적고 있었다**는 것이다. 파일 시스템과 대조해
확인된 것만 16건 — 없는 훅을 "강제한다"고 적고, 없는 스킬을 "반드시 호출하라"고 지시하고,
은퇴한 룰의 사본 90,308 bytes 가 저장소 생성물 안에서 계속 지시하고 있었다.

## Decision

### 1. 상시 로딩은 `CLAUDE.md` 한 장 + import 1편

- `~/.claude/rules/` 12편 폐지. 상시 = `CLAUDE.md`(5,384B) + `@rules/response-format.md`(3,953B).
- 살아 있던 4편(`branch-worktree-strategy`·`verification-safety`·`acceptance-criteria-gate`·
  `turn-result-board`)은 삭제가 아니라 **`rules-ondemand/` 로 이동** — 상시 비용만 0으로.
- 판정 기준: **기본 시스템 프롬프트 · `settings.json` · 등록된 훅 · ponytail** 넷 중 하나라도
  커버하면 상시에 두지 않는다.

### 2. 구현 파이프라인 스킬 은퇴 — 구현은 메인이 직접

`forge`·`renew`·`hunt`·`linear-goal` 제거. 구현·수정·버그픽스는
**plan mode → 구현 → `/code-review`(보안 민감 시 `/security-review`)** 로 한다.
스킬 26 → 11종.

### 3. 벤더별 진입점 없음 — `CLAUDE.md` 단일

저장소 9곳에서 `AGENTS.md`·`SHARED-RULES.md`·`PROJECT-RULES.md` 제거.
포인터로 축약해도 "포인터가 비었다고 판단되면 본문이 복사된다"가 남는다 —
**진입점을 하나로 두는 것만이 구조적 해소**다. 인스턴스: ADType `docs/adr/066`.

### 4. 참조 자료는 `skills/` 밖으로

`craft-core` 는 `user-invocable: false` 인데 `skills/` 에 있어 목록 비용만 냈다.
실제 참조되는 6편을 `~/.claude/references/craft/` 로 옮기고 껍데기 제거 —
**`skills/` 는 호출되는 것, `references/` 는 읽히는 것**.

## Consequences

| | before | after |
|---|---:|---:|
| 상시 로딩 | 60,703 B | **9,337 B** |
| on-demand | 19편 | 10편 (상시 0) |
| 배포 스킬 | 26종 | 11종 |
| 활성 스킬 | 35 | 23 |
| 벤더별 진입점 | 9저장소 | 0 |

**감수한 것**: Codex 는 실사용 중이다(80세션 `codex` bash 290회). 이제 그 도구로 작업할 때는
`CLAUDE.md` 를 명시적으로 읽혀야 한다. 갈라진 지침이 만드는 거짓이 한 홉 더 가는 비용보다
비싸다는 판단이다.

## 되살릴 조건 (재설치 금지 근거)

**이 절이 이 ADR 의 본체다.** 근거 없이 되돌리지 않기 위해 조건을 못 박는다.

| 대상 | 되살릴 조건 |
|---|---|
| `karpathy-core`·`yagni-core` | **ponytail 플러그인을 끄면** 근거가 사라진다 — 그때 상시로 복귀 |
| `commit-isolation` | 기본 프롬프트가 *"Commit or push only when the user asks"* 를 더 이상 말하지 않게 되면 |
| `objective-reasoning` | 확신도 미표명이 실제 오판으로 이어진 사례가 관측되면 (실측 기준선: 6턴/13,692) |
| `language-policy` | `settings.json` 의 `"language"` 키가 사라지면 |
| `forge`·`renew`·`hunt` | plan mode + `/code-review` 로 3회 이상 돌린 뒤 **놓친 결함**이 나오면 |
| `linear-goal` | 이슈 자율 실행을 다시 원하고, 그 실패 모드(무한 대기·거짓 완료)를 감수할 때 |
| `AGENTS.md` | Codex 작업 빈도가 높아져 "매번 `CLAUDE.md` 를 읽히는" 비용이 실제 마찰이 되면 — **본문 없는 포인터**로만. 전문 inline 복귀는 금지 |
| 은퇴 on-demand 5편 | 각 룰의 트리거 상황이 실제로 재발하고, 대체재(스킬·기본 프롬프트)가 못 잡을 때 |

## 재검토

**2026-09-04**(1개월 후) — `/context` 실측을 다시 찍어 상시 비용을 확인하고,
위 "되살릴 조건" 중 발동한 것이 있는지 점검한다.

## 방법론 (다음 정리 때 그대로 쓸 것)

1. **추정하지 말고 측정.** 한국어는 `chars/4` 가 최대 2배 어긋난다 — `/context` 만 정확하다.
2. **2차 오탐 제거.** 룰 인용 1차 grep 은 룰 본문 주입에 오염된다. 어시스턴트 **출력**만 센다.
3. **세 곳과 대조.** 기본 시스템 프롬프트 / 등록된 훅(분기별 exit 코드) / `settings.json`.
4. **삭제는 생성기·설치기·카탈로그까지.** 파일만 지우면 다음 실행에 되살아난다
   (실측: `install.sh` 가 `references/craft` 를 안 옮겨 새 설치가 깨질 뻔했고,
   `global/rules/` 는 은퇴 12편을 계속 배포하고 있었다).
5. **Read 0 ≠ 불필요.** 안전장치(`db-drop-preflight`)와 기본값이 함정인 것(`orm-stack`)은
   발화 빈도로 자르지 않는다.
