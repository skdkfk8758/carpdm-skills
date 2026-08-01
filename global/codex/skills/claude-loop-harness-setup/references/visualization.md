# S5 — loop/ 가시화·로그 생성 (상세)

HTML 은 하니스 구조의 **파생 산출물**이다 — `gate-contract.md`·`loop-control.mjs`·`attribution.mjs` 가 SSOT. 레퍼런스를 베끼면 drift 한 거짓 시각화가 되니, 타깃의 실제 하니스를 실측해 델타를 확정한 뒤 튜닝한다.

## 1. 시각 템플릿 레퍼런스 (구조만 참고, 베끼지 말 것)

- `$SRC/loop/harness-visualization.html` — **기본형**(② deep-plan+eval-generate 1-shot, plain decideNext). 새 프로젝트가 보통 이쪽.
- `~/Workspace/ADMap/loop/harness-visualization.html` — **확장형**(② plan-rubric-debate 섹션 추가, normalizeSignature). 그 기능을 *실제로 이식한* 프로젝트만 이 섹션을 그린다.

해당 레퍼런스를 Read 해 CSS·레이아웃·인터랙션(노드 클릭 상세)을 가져오되, 본문 내용은 아래 델타로 교체한다.

## 2. 델타 체크리스트 — HTML 쓰기 전 소스로 실측 (추측 금지)

| 확인 항목 | 어디서 | 갈리는 예 |
|---|---|---|
| 스킬 개수·구성 | `ls .claude/skills` | db-migrate 유무 → 4 vs 5 skills |
| ② 생성 방식 | `find .claude/skills -name '*debate*'` | plan-rubric-debate(Author↔Critic) vs deep-plan+eval-generate 1-shot |
| decideNext 로직 | `scripts/loop-control.mjs` | `normalizeSignature` 유무 / 코드박스 본문 일치 |
| 단위테스트 카운트 | `grep -c 'test(' *.test.mjs` | "N cases" 숫자(loop-control / attribution) |
| 게이트 계약 | `references/gate-contract.md` | G4 = TypeORM vs `psql -f`+information_schema |
| 브랜치 전략 | `branch-worktree-strategy.md`/메모리 | trunk 이름(develop vs feat/X.Y.Z), G3 land(advisory repo 면 `--auto` 금지·수동 CI 확인) |
| attribution grain·진범 | `scripts/attribution.mjs` | item/category/total · deep-plan/eval-generate/forge-dev |
| 경로 base | — | 컴포넌트 맵 절대경로를 타깃으로 |
| 표기 | SKILL.md | "하니스" vs "하네스" 등 프로젝트 용어 통일 |

확정한 델타는 `loop/log/<오늘>.md` 셋업 NOTE 에 한 줄로 남긴다(다음 사람이 무엇이 다른지 즉시 봄).

## 3. 산출 파일

1. **`loop/harness-visualization.html`** — self-contained(외부 asset 0). 섹션: ① 게이트 흐름(G0~G4, 사람/자동 레인) · ② 역할 분리(dev/gen/chk) · ③ decideNext(코드박스+판정) · ④ C4 heal worksheet · ⑤ 컴포넌트 맵(스킬별 파일). 확장형이면 ②와 ③ 사이에 토론 섹션 추가. 노드 클릭 → 하단 상세 패널(레퍼런스의 `DETAIL` 스크립트 패턴).
2. **`loop/README.md`** — 파일 역할표 + 기록 메커니즘(스킬 컨벤션) + SSOT 경계(HTML=파생).
3. **`loop/log/README.md`** — 파일 규칙(`YYYY-MM-DD.md`) + 엔트리 포맷(`## HH:MM · slug · ISSUE|HEAL|NOTE`) + 분류.
4. **`loop/log/<오늘>.md`** — H1=날짜 + 셋업 NOTE 1건(무엇=역이식·튜닝, 조치=확정 델타 한 줄).

> 1~4 의 본문 구조는 `$SRC/loop/` 의 같은 파일들을 Read 해 가져오되, 델타로 내용 교체.

## 4. SKILL 컨벤션 섹션 추가 (동기 메커니즘 — 자동 hook 아님)

**`harness-run/SKILL.md`** — `## 출력 보고` 앞에 추가:

```markdown
## loop 로그 기록 (컨벤션)

종료 시(pass/short-circuit) **오늘 날짜 파일** `loop/log/YYYY-MM-DD.md` 에 한 엔트리 append(없으면 H1=날짜로 생성) — 포맷은 `loop/log/README.md`.
- `pass` → 분류 `NOTE`("무엇"=outcome·attempts, 게이트 G3). `short-circuit` → 분류 `ISSUE`("무엇"=최종 signature, 게이트 G2; heal 결과는 harness-heal 이 별도 HEAL).
메인루프는 fs 가능 — 종료 직전 Write/Edit append. 자동 hook 아님.

## 가시화 HTML 동기 (컨벤션)

하니스 **구조**(게이트·스킬 구성·decideNext/역할 분리·컴포넌트 맵)를 바꾸면 같은 변경에서 `loop/harness-visualization.html` 도 갱신한다 — HTML 은 gate-contract·loop-control 의 파생 산출물이라 안 고치면 drift. SSOT 경계는 `loop/README.md`.
```

**`harness-heal/SKILL.md`** — Workflow 마지막 스텝으로 추가:

```markdown
N. **loop 로그 기록** — 라운드 완료 시 `loop/log/YYYY-MM-DD.md` 에 `HEAL` 엔트리 append(포맷 `loop/log/README.md`): "무엇"=signature, "진범"=라벨, "조치"=수정한 오버레이 경로 또는 에스컬레이트. 자동 hook 아님 — 스킬 컨벤션.
```

두 SKILL 의 `## 출력 보고` 한 줄에도 `loop/log/YYYY-MM-DD.md 기록 여부`를 덧붙인다.

## 5. (옵션) Stop 훅 강제

컨벤션 누락이 잦으면 `guard-stop-heal-log` 류 Stop 훅(오버레이를 고쳤는데 오늘 HEAL 로그 없으면 stop 차단)을 별도로 붙인다. 기본은 컨벤션만 — 안 깨진 것 미리 빌드하지 않는다. 사용자가 명시 요청할 때만.

## 6. 검수
`loop/harness-visualization.html` 을 열어 게이트 흐름·스킬 개수·decideNext 본문이 **실제 프로젝트와 일치**하는지 눈으로 확인. 불일치 = 델타 튜닝 누락.
