---
name: claude-loop-harness-setup
description: Imported Claude skill for installing or adapting development loop and eval harness infrastructure.
---

# loop-harness-setup — 루프 하니스 + 가시화 한 흐름 셋업

이슈 1건을 **워크트리 → 플랜+rubric → G1 freeze → 자율 dev+eval 루프 → merge** 로 관통하는 eval-게이트 하니스와, 그 구조를 보여주는 `loop/` 가시화·일별 로그를 타깃 프로젝트에 설치한다. 핵심 무결성은 **dev ≠ eval-generator ≠ eval-checker** 3역할 분리(dev 는 rubric 못 봄, checker 만 frozen rubric 채점).

## 트리거 시 먼저

1. **타깃 = 현재 작업 디렉토리**인지 확인. 아니면 어느 프로젝트인지 묻는다.
2. **`$SRC` (포터블 코어 출처)** 확정 — 기본 `/Users/carpdm/Workspace/Intelligence-Auth`(하니스 origin). 다르면 사용자에게 확인. `$SRC` 가 없는 환경이면 멈추고 보고.
3. **부분 셋업 요청 분기** — "가시화만"/"로그만"이면 S1~S4(스킬 이식) 건너뛰고 S5 로. "스킬만"이면 S5 생략.

## 셋업 흐름 (S0~S6 — 각 단계 검증 후 다음)

> **순서 불변식**: S5(가시화)는 S4(단위테스트 green) 의존. 검증 안 된 하니스를 시각화하면 거짓 구조도가 된다. 어겼는데 막히면 순서부터 의심.

### S0 — 사전 의존성
확인: Claude Code `Workflow` 도구 · 글로벌 스킬 `deep-plan`·`land`(`~/.claude/skills/`) · Node.js · git worktree. dev 는 `forge` 안 씀(dev-eval-loop 안 단일 `agent()`) — forge/renew/hunt 불요. 빠진 게 있으면 멈추고 보고.

### S1 — 포터블 코어 복사 (스택 무관, 하드코딩 0)
```bash
SRC=/Users/carpdm/Workspace/Intelligence-Auth   # 또는 확정한 경로
mkdir -p .claude/skills docs/reference rules/harness-overlays
cp -R "$SRC"/.claude/skills/harness-run   .claude/skills/
cp -R "$SRC"/.claude/skills/harness-heal  .claude/skills/
cp -R "$SRC"/.claude/skills/eval-generate .claude/skills/
cp -R "$SRC"/.claude/skills/eval-check    .claude/skills/
cp "$SRC"/docs/reference/eval-rubric-schema.md docs/reference/
touch rules/harness-overlays/.gitkeep
```

### S2 — (DB + raw SQL 타임스탬프 마이그일 때만) db-migrate
```bash
cp -R "$SRC"/.claude/skills/db-migrate .claude/skills/
cp "$SRC"/scripts/migrate.mjs "$SRC"/scripts/new-migration.mjs scripts/ 2>/dev/null
```
**ORM 마이그(Prisma/TypeORM)거나 DB 없으면 생략** — rubric 의 DB 특례(REQ-F-017)도 자동으로 빠진다(taskType≠db).

### S3 — package.json 테스트 배선 (필수)
하니스의 결정론 로직(`decideNext`·`attribution`)은 단위테스트로 잠겨 있다. `test` 스크립트에 잇는다:
```jsonc
"test": "<기존 테스트> && node --test \".claude/skills/**/scripts/*.test.mjs\""
```
기존 `test` 없으면 `"test": "node --test \".claude/skills/**/scripts/*.test.mjs\""`.
DB 면 `db:new`/`db:migrate:status`/`db:migrate:up`/`db:migrate:down` 도 배선(`migrate.mjs` 는 `DATABASE_URL` env). Kysely 면 `db:types`=kysely-codegen, 다른 데이터레이어면 교체.

### S4 — 하니스 검증 (게이트)
```bash
node --test ".claude/skills/**/scripts/*.test.mjs"
```
green = 재시도/단락·진범귀속 "이빨" 정상 이식. **red 면 멈추고 보고** — S5 안 감. (스모크: `validate-rubric.mjs <rubric.json>`, `score-rubric.mjs <rubric.json> <results.json>`.)

### S5 — 가시화·로그 생성 (튜닝이 핵심)
**레퍼런스 HTML 을 베끼지 않는다.** 타깃의 실제 하니스를 실측해 델타를 확정한 뒤 튜닝된 self-contained HTML 을 쓴다. 절차·델타 체크리스트·시각 템플릿·기록 컨벤션은 **`references/visualization.md` 를 Read** 후 따른다.

산출: `loop/harness-visualization.html`(외부 asset 0) · `loop/log/<오늘>.md`(셋업 NOTE 에 델타 한 줄) · `loop/README.md` · `loop/log/README.md` + harness-run/harness-heal SKILL.md 에 "loop 로그 기록"+"가시화 HTML 동기" 컨벤션 섹션.

### S6 — tracer 첫 런 (실 이슈 필요 — 사용자에게 물음)
작고 수직 관통하는 이슈 1건으로 `harness-run` 호출 → G0 slug → 워크트리 → deep-plan/eval-generate → **G1 freeze** → dev-eval-loop → pass면 `land`. **negative test**: 일부러 결함 박은 코드를 checker 가 `<90` 으로 떨구는지 확인 → 떨구면 게이트가 살아 있음.

## 출력 보고
끝에 `result:` 한 줄 — 복사한 스킬 · DB 여부 · 테스트 통과 · 생성한 loop 파일 · 확정한 델타. 그다음 S6 는 어떤 이슈로 돌릴지 사용자에게 묻는다.

## 흔한 함정
- **S5 를 S4 앞에** — 검증 안 된 하니스 시각화 = 거짓 구조도. 순서 고정.
- **레퍼런스 HTML 통째 복사** — 기본형 프로젝트에 확장형(plan-rubric-debate 섹션)을 그리면 없는 기능을 그린 거짓 시각화. 델타 실측 필수(`references/visualization.md`).
- **글로벌 스킬 수정** — 복사·개선은 `.claude/skills/`·`rules/harness-overlays/`(프로젝트 로컬)만. `~/.claude/skills/` 손대면 타 프로젝트 오염(REQ-F-012).
- **dev 에 rubric 주입** — `dev-eval-loop.js` dev `agent()` 에 `rubricPath` 넣지 마라. 분리 무결성(REQ-F-007/008) 붕괴. dev 는 플랜+시안만.
- **`decideNext` 미러 동기** — `dev-eval-loop.js` inline 복제(Workflow import 불가). SSOT=`loop-control.mjs`, 한쪽 고치면 양쪽. 단위테스트가 SSOT 잠금.
- **prod 마이그 자동 적용**(DB) — `migrate.mjs` 는 `--env dev` 강제. prod 는 G4 사람 게이트에서 개별 `psql -f`+`information_schema`.

## Related
- 원본 가이드(SSOT): `$SRC/docs/guides/setup-loop-harness-oneshot.md` · `port-loop-engineering-harness.md` · `setup-loop-visualization.md`.
- 글로벌 룰 포인터: `~/.claude/rules/loop-visualization.md`.
