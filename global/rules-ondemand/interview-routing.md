# Interview Routing — 어떤 인터뷰로 들어가는가

> 인터뷰 스킬이 5계열이다 — 자체(deep-interview · deep-plan/goal-prompt 내장 갭 인터뷰 ·
> linear-replan) · mattpocock grilling 계열 · paperthin(`/hate`) · readchk · AskUserQuestion 단발.
> **진입** 결정을 이 한 장으로. 인터뷰 **종료 후** "다음 스킬" 은 별개 SSOT —
> `~/.claude/skills/deep-interview/references/next-skill-routing.md`.
>
> 플러그인 스킬 파일은 업데이트 시 덮어써진다 — 경계문은 우리 쪽(이 파일 · deep-interview
> description)에만 둔다. mattpocock 쪽 원문 라우터는 `/ask-matt`(사용자 타이핑).

## 0. 먼저 — 인터뷰가 필요한가

1. 코드·문서·메모리로 해소되면 **묻지 않는다**.
2. 갈래 1~2개, 서로 독립 → `AskUserQuestion` 1콜(권장안 첫 옵션 + 왜). 스킬 아님.
3. 갈래 3개 이상 **또는 서로 의존**(A 의 답이 B 의 옵션을 바꾼다) → 아래 표.

## 1. 라우팅 표

| 상황 (입력이 무엇인가) | 스킬 | 호출 형태 | 산출 |
|---|---|---|---|
| 아이디어 자체가 흐릿 — **무엇을 만들지**부터 | `deep-interview` | 모델 발동 | REQ spec (ambiguity 게이트) |
| plan·결정·설계가 **이미 있고** 구멍 찾기·압박 | `mattpocock-skills:grilling` | 모델 발동 | 합의 (문서 없음) |
| 위 + repo 안, **CONTEXT.md·ADR 흔적** 남기고 싶음 | `/grill-with-docs` | 사용자 타이핑 | grilling + domain-modeling |
| repo 밖 (글·발표·개인 결정) | `/grill-me` | 사용자 타이핑 | grilling stateless |
| **자율 에이전트 프롬프트**가 목적 | `goal-prompt` | 모델 발동 | grilling 규율 갭 인터뷰 내장(design tree·프론티어·권장답, 7갭 상한 — 초과 시 grilling/wayfinder 로 라우팅 아웃) |
| **plan 문서+시안**, 저자×비평자 debate | `deep-plan` | 모델 발동 | 갭 인터뷰 내장 |
| Linear 이슈 1건 **착수 직전** 결정 갈래 | `linear-replan` | 모델 발동 | 체크리스트 전항목 AskUserQuestion |
| 한 세션에 안 담기는 **대형 안개** | `/wayfinder` | 사용자 타이핑 · 트래커 setup 선행 | decision tickets 맵 |
| 답이 사용자가 아니라 **제3자**에게 있음 | `/to-questionnaire` | 사용자 타이핑 | 질문지 `.md` |
| 계획에 공수 들이기 **직전 철거 반사** | `/hate` | 사용자 타이핑 | paperthin 비평 |
| **지시 자체**가 헷갈림 (this/that/저거) | `readchk` | 모델 발동 | 재진술 + 생존 갈래 1개 |

## 2. deep-interview vs grilling — 둘 다 "interview me" 에 반응한다

- **기준 = 입력.** 흐릿한 아이디어(무엇을 만들지 모름) → deep-interview.
  이미 형태 있는 plan/decision(맞는지 모름) → grilling.
- **형식이 다르다.** deep-interview = 라운드당 1문항 · ambiguity 수치 게이트 · REQ spec 산출.
  grilling = 프론티어 질문 전부 한 라운드 · 문항마다 권장답 첨부 · 산출물 없이 합의로 종료.
- **이어 쓸 수 있다.** deep-interview → spec → grilling 으로 Residual ambiguity 만 압박.
  반대(grilling 뒤 deep-interview)는 하지 않는다 — 이미 형태가 있다.
- 사용자가 "grill" 이라 말하면 grilling. "인터뷰해줘" 만으로는 입력 형태로 판정.

## 3. 이중 인터뷰 금지

- 인터뷰 산출물(spec · PLAN · `-prompt.md` · grilling 합의)이 컨텍스트에 있으면 다음
  스킬은 **재인터뷰하지 않는다** — 확정 입력으로 삼는다. goal-prompt Step 0 · deep-plan
  crisp 판정이 그 스킵 지점.
- `/to-spec`(mattpocock)은 "인터뷰 없음, 합성만" — grilling **뒤에만** 의미. deep-interview
  뒤에는 중복(이미 spec).

## 4. 설치 형상 (2026-09-03 실측 — 바뀌면 이 절만 고친다)

- 플러그인 `mattpocock-skills@claude-plugins-official` 1.2.3 — 25종, 네임스페이스
  `mattpocock-skills:<name>`. **모델 발동 11종**: grilling · prototype · research ·
  domain-modeling · codebase-design · tdd · code-review · diagnosing-bugs ·
  resolving-merge-conflicts · wizard · writing-for-agents. 나머지 14종은
  `disable-model-invocation: true` — 사용자가 `/이름` 타이핑해야만 뜬다(grill-me ·
  grill-with-docs · to-spec · to-tickets · implement · wayfinder · triage · to-questionnaire
  · loop-me · teach · handoff · wait-what · ask-matt · setup-matt-pocock-skills).
- 트래커 의존 5종(`/to-spec` `/to-tickets` `/wayfinder` `/implement` `/triage`)은 repo 당
  `/setup-matt-pocock-skills` 1회 선행 — 없으면 스킬이 그걸 먼저 요구한다.
- **중복 설치 주의:** `~/.agents/skills/`(npx skills, 8-27 스냅샷)에도 같은 이름이 있고
  일부가 `~/.claude/skills/` 심링크로 노출된다 → `tdd` · `diagnosing-bugs` · `research` ·
  `resolving-merge-conflicts` 가 bare 와 `mattpocock-skills:` 두 벌로 뜬다(`tdd` 는 내용도
  다름). 모델 발동 시 어느 쪽이 잡힐지 비결정 — 정리 전까지 **플러그인 네임스페이스를
  명시**해 부른다. 정리는 `/re0-upgrade` 또는 심링크 제거.
- 이름 충돌 1건 더: 우리 `handoff`(모델 발동) vs 플러그인 `handoff`(사용자 타이핑).
  `/handoff` 타이핑 시 어느 쪽인지 확인 — 세션 저장·복원은 우리 것.

## Related

- 글로벌 `CLAUDE.md` §온디맨드 룰 라우팅 — 이 파일로 들어오는 입구
- `hooks/prompt-intake.py` 인터뷰 게이트 — 모호한 개발 요청에 이 파일을 가리킨다
- `paperthin-routing.md` — `/hate` 등 사용자 전용 12종의 SSOT
- `~/.claude/skills/deep-interview/references/next-skill-routing.md` — 인터뷰 **종료 후** 라우팅
