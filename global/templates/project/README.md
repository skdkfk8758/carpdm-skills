# 프로젝트 템플릿 세트

새 프로젝트(또는 기존 프로젝트)에 리뉴얼된 작업 방식 — **ADR 목표 지향 · 스텝 단위 확인 ·
모델 티어 · council 리뷰/리서치** — 을 3분 안에 까는 최소 세트다.
글로벌 규율(`~/.claude/CLAUDE.md` §모델 티어 · §짧은 호흡)이 SSOT — 이 세트는 그 배선만 둔다.

## 설치

```bash
bash ~/.claude/templates/project/scripts/init-project.sh <target-dir>
```

기존 파일은 덮어쓰지 않고 `SKIP` 으로 넘어간다(재실행 안전, 삭제 동작 없음).
설치 후 `AGENTS.md` 의 `<...>` 를 채우는 것이 첫 작업이다.

## 모노레포 하위 폴더 (`sub/`)

`apps/web`·`apps/api`·`services/x`·`packages/y` 처럼 폴더별로 지침이 갈리는 모노레포는
`--sub` 로 하위 폴더에도 `AGENTS.md`(SSOT)·`CLAUDE.md`(`@AGENTS.md` 포인터) 를 깐다.
반복 가능 — 폴더마다 하나씩 지정한다.

```bash
bash ~/.claude/templates/project/scripts/init-project.sh <target-dir> \
  --sub apps/web --sub apps/api
```

## 파일 역할

| 파일 | 역할 |
|---|---|
| `AGENTS.md` | 프로젝트 지침 SSOT — 목표·스택·검증 3종·브랜치·ADR 규약·사람만 아는 규칙 |
| `CLAUDE.md` | `@AGENTS.md` 한 줄. 진입점을 둘로 갈라 두지 않기 위한 포인터 |
| `.claude/settings.json` | 검증 명령 permission allowlist placeholder |
| `docs/adr/README.md` | ADR 번호·Status·"스텝 계획은 ADR 의 `## Steps` 에" 규약 |
| `docs/adr/0000-template.md` | ADR 본문 형식 (Context/Decision/Consequences/Steps/Verification) |
| `prompts/01-design-session.md` | Fable 설계 세션 킥오프 — 인터뷰 → ADR 초안 → 스텝 계획 → 멈춤 |
| `prompts/02-step-execution.md` | opus 스텝 실행 — 한 스텝만·검증·§A 보고·다음 스텝 질문 |
| `prompts/03-council-review.md` | `/council-review` 호출과 결과를 ADR Verification 으로 |
| `prompts/04-council-research.md` | `/council-research` 호출과 결론을 ADR Context 로 |
| `sub/AGENTS.md` | 모노레포 하위 폴더용 지침 SSOT (`--sub` 로만 설치) |
| `sub/CLAUDE.md` | `@AGENTS.md` 한 줄 (`--sub` 로만 설치) |
| `scripts/init-project.sh` | 위 파일들을 대상 디렉터리에 복사(멱등), `--sub` 로 하위 폴더도 |

## placeholder

전부 `<...>` 꺾쇠 표기다. 남아 있으면 아직 안 채운 것이다 — `grep -rn '<[A-Z-]*>' .` 로 찾는다.

- `<PROJECT-NAME>` `<GOAL>` `<STACK>` `<ENTRYPOINT>` `<KEY-PATHS>` — `AGENTS.md`
- `<VERIFY-CMD-1>` `<VERIFY-CMD-2>` `<VERIFY-CMD-3>` — typecheck / test / build
- `<TRUNK>` `<MERGE-RULE>` — 브랜치 규칙
- `<NNNN>` `<제목>` `<YYYY-MM-DD>` — ADR 머리말
- `<ADR-PATH>` `<STEP-NO>` `<REQUEST>` — 프롬프트 호출 인자
- `<REVIEW-TARGET>` `<QUESTION>` `<CRITERION-1..3>` — council 호출 인자
