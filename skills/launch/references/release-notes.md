# 버전 · 릴리즈 노트 규칙 (launch Step 1)

> 현재 태그 메시지가 제각각이다 — `v1.23.0 — 키의 기본 브랜드` / `release: v1.2.62 — …` /
> lightweight(메시지 없음). 그리고 `package.json` 버전은 태그와 무관하게 드리프트한다(0.1.0 vs v1.2.62).
> 이 파일은 **태그를 버전의 SSOT** 로 못 박고 메시지 형식을 하나로 고정한다.

## 1. bump 판정 — 커밋 제목으로, 크기가 아니라 종류로

`git log <last-tag>..HEAD --no-merges --format='%s'` 의 각 제목을 conventional prefix 로 분류한다.

| 신호 | bump |
|---|---|
| 제목에 `!:` 또는 본문 `BREAKING CHANGE:` | **major** |
| `feat(` / `feat:` 1건 이상 | **minor** |
| 그 외 (`fix`·`perf`·`refactor`·`chore`·`docs`·`test`·`ci`…) | **patch** |
| 첫 릴리즈(태그 없음) | `v0.1.0` 제안 — 0.x 는 "API 가 아직 흔들린다" 의 정직한 표기 |

prefix 가 없는 제목(`이슈 수정`·`ADT-33 반영`)은 **patch 로 보되 플랜에 "분류 불가 N건" 을 표시**한다.
사용자가 그 중 feat 이 있다고 하면 minor 로 올린다 — 스킬이 diff 를 읽어 추측하지 않는다.
squash 머지 커밋은 MR 제목이 곧 커밋 제목이라 그대로 먹는다. `Merge branch` 커밋은 `--no-merges` 로 이미 제외.

`package.json`·`pyproject.toml` 의 `version` 은 **건드리지 않는다.** 올리려면 릴리즈 라인에 커밋이
필요하고 그건 protected 라 MR 한 바퀴다 — 태그 하나 붙이는 일에 그 비용은 과하다. 드리프트가
보이면 플랜에 한 줄(`package.json 0.1.0 ≠ 태그 — 태그가 SSOT, 파일은 무시`)만 남긴다.

## 2. 태그 메시지 = GitLab Release 본문 — 한 소스

노트 파일을 하나 쓰고 `git tag -a -F` 와 Release `description` 에 **같은 내용**을 넣는다.
두 곳이 다르면 나중에 어느 쪽을 믿을지 모른다.

```
vX.Y.Z — <한 줄 요약: 이 릴리즈의 durable idea, 버전 반복 금지>

## 변경
- feat(scope): <MR 제목 그대로> (!NN, ISSUE-ID)
## 수정
- fix(scope): … (!NN)
## 운영 메모            ← 해당 시만. 없으면 섹션 생략
- 마이그레이션 포함: migrations/0007_… — prod apply 는 별도(머지 ≠ 적용)
- env 추가: FOO_URL (Infisical prod 에 채워야 기동)
```

규칙:

- **첫 줄이 태그 제목**이다(`git tag -l --format='%(contents:subject)'` 가 이걸 보여준다). `vX.Y.Z — ` 로
  시작 — 종전 3가지 스타일 중 이것 하나로 수렴.
- 항목은 **MR 제목을 옮겨 적는다**, 다시 쓰지 않는다. 다시 쓰면 MR 과 노트가 갈리고, 노트 작성이
  릴리즈의 병목이 된다. 다듬을 곳은 첫 줄 요약 하나다.
- `(!NN, ISSUE-ID)` — MR iid 는 커밋 제목의 `(!NN)` 또는 API 매칭에서, 이슈 키는 제목·브랜치명의
  `[A-Z]{2,5}-\d+` 에서. 둘 다 없으면 항목만 남긴다(빈 괄호 금지).
- `## 운영 메모` 는 **변경 파일**로 판정한다 — `migrations/`·`*.sql`·`.env.example`·`compose`·`Dockerfile`
  가 범위에 있으면 넣는다. 사람이 릴리즈 뒤 해야 할 일이 여기 아니면 어디에도 안 남는다.
- `chore`·`ci`·`docs` 만 있는 릴리즈도 노트를 쓴다(짧게). "변경 없음" 릴리즈는 없다 — 있다면 태그할
  이유가 없으니 Step 0 에서 멈췄어야 한다.

## 3. 사용자가 버전을 직접 말했을 때

`v1.4 로 릴리즈` → `v1.4.0`. 규칙 판정과 다르면(예: 규칙은 patch) 플랜에 한 줄로 짚고 사용자 값을
쓴다 — 버전은 소통 도구고 소통의 주인은 사용자다. 단 **뒤로 가는 버전**(마지막 태그보다 낮음)과
**이미 있는 태그**는 거부한다(immutable 태그 + ECR immutable 태그 정책과 충돌).
