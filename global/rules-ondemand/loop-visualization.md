# loop-visualization — 루프 하니스 + 가시화 셋업 포인터

> **부분 은퇴 (2026-07-29)**: 하니스 실행 스킬 5종(harness-run·eval-generate·eval-check·harness-heal·loop-harness-setup)이 은퇴해 **"하니스 스킬 이식" 진입점은 더 이상 유효하지 않다**. 남은 유효 범위는 이미 하니스가 있는 프로젝트(현재 Intelligence-Auth `loop/`)의 **가시화·로그 레이어**뿐이다.

IMPORTANT: 루프엔지니어링 하니스를 타 프로젝트에 올리거나(스킬 이식 — 은퇴) 그 위 `loop/`(시각화 HTML + 일별 운영 로그) 레이어를 세팅하는 작업은 매번 새로 설계하지 말고 **검증된 셋업 가이드**를 따른다. 상세·복사용 프롬프트는 on-demand 로 가이드를 Read.

## 진입점 선택

- **하니스 + 가시화 한 번에** (새 프로젝트 처음) → `setup-loop-harness-oneshot.md`(S0~S6 통합 + one-shot 프롬프트).
- **하니스 스킬만 이식** → `port-loop-engineering-harness.md`.
- **가시화·로그만** (하니스 이미 있음) → `setup-loop-visualization.md`.

## 무엇을 만드나

- `loop/harness-visualization.html` — 하니스 구조 self-contained 시각화(게이트 G0~G4 · 3역할 분리 · decideNext · C4 heal · 컴포넌트 맵). 외부 asset 0.
- `loop/log/YYYY-MM-DD.md` — 루프 돌며 나온 ISSUE/HEAL/NOTE 일별 누적.
- (은퇴) 하니스 스킬 SKILL.md 의 "loop 로그 기록"·"가시화 HTML 동기" 컨벤션 섹션 — 스킬 은퇴로 무효.

## 불변식 (바꾸지 말 것)

- **HTML 은 파생 산출물** — `gate-contract.md`·`loop-control.mjs`·`attribution.mjs` 가 SSOT. 하니스 구조가 바뀌면 같은 변경에서 HTML 갱신(안 하면 drift 한 거짓 시각화).
- **레퍼런스 베끼기 금지** — HTML 쓰기 전 본 프로젝트의 `.claude/skills/harness-*` 를 실측해 델타(스킬 개수 · ② 1-shot vs debate · decideNext normalizeSignature 유무 · G4 DB 방식 · trunk/land 규칙 · 테스트 카운트 · 표기)를 확정한 뒤 튜닝. 메모리/추측 금지.
- **자동 hook 아님** — 로그 append 는 사람/AI 가 수행한다(종전엔 하니스 스킬 컨벤션이었으나 은퇴).

## 적용 (이대로 안내)

진입점 가이드의 §"재사용 프롬프트"를 복사해 `$SRC`(레퍼런스 Intelligence-Auth 경로)만 바꿔 실행. S4(단위테스트 green) 전엔 S5(가시화) 안 감 — 검증 안 된 하니스 시각화는 거짓 구조도.

## SSOT

- 통합 진입: `~/Workspace/Intelligence-Auth/docs/guides/setup-loop-harness-oneshot.md` (S0~S6 + one-shot 프롬프트).
- 상세 본체: `setup-loop-visualization.md`(가시화) · `port-loop-engineering-harness.md`(스킬 이식).
- 시각 템플릿·원형 인스턴스: Intelligence-Auth `loop/`(기본형·하니스 origin) · ADMap `loop/`(확장형·debate 이식본).

## Related

- `~/.claude/rules/branch-worktree-strategy.md` — trunk/land 규칙(G3 튜닝 입력).
