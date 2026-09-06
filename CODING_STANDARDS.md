# CODING_STANDARDS — 리뷰 시 강제하는 표준

> **읽는 주체는 리뷰어다.** 구현 에이전트는 탐색·작성·디버깅으로 컨텍스트 압력이 가장 높고,
> 리뷰 에이전트는 diff 만 받아 가장 낮다 — 표준은 압력이 낮은 쪽이 진다.
> `/code-review` 와 스킬 저작 리뷰가 이 파일을 읽고 항목별로 판정한다.
> 저작 중에도 필요하면 `CLAUDE.md` 의 포인터를 따라 여기로 온다.

## 1. 작성 언어 (글로벌 language-policy override)

신규·수정 스킬(`SKILL.md`+`references/*.md`)의 **본문 prose 와 frontmatter `description:` 값은 한국어로 작성**한다. 글로벌 `language-policy`(문서=영어)를 이 레포의 skills 산출물에 한해 override — 사용자가 한국어 운용을 명시했기 때문.

**단, 다음은 항상 원문(영어/식별자) 유지 — 번역·한글화 금지(시스템이 깨짐):**
- frontmatter `name:` 값 (스킬 식별자 — install·sync·invocation·craft-core 절대경로가 참조).
- `model:`/`user-invocable:`/`disallowedTools:`/`tools:` 등 frontmatter 키와 그 값(opus/sonnet/haiku, Write/Edit 등).
- 코드 식별자·도구명(Read/Grep/Bash/Task/Workflow/Edit…)·파일경로·URL·XML 태그·코드블록 내용.
- `description:` 안의 **인용된 트리거 예시 구절**(자연어 발화 매칭용) — 원어 그대로(영어 예시는 영어로) 유지하고 설명 prose 만 한글.

## 2. 스킬 저작 검증 — 하지 말 것 5가지

스킬을 저작/수정한 뒤 검증할 때(carpdm-skills 고유 — 글로벌 rules 가 아니라 여기 둔다):

- **`node --check` 로 스킬 skeleton 을 검증하지 말 것.** skeleton 은 async wrapper 안에서 실행돼 `node --check` 가 false `'Illegal return statement'` 를 뱉는다. 마크다운+frontmatter 구조는 frontmatter 파싱·필수 키(`name`/`description`) 존재·`references/*` 경로 확인으로 검증한다.
- **프론트매터 스키마는 CLI 바이너리가 SSOT — 사용 현황으로 추론하지 말 것.** 설치 스킬이 실제로 쓰는 키를 세어 "그런 키는 없다" 고 결론내면 틀린다(실측 사고 1회). 스키마 원문은 `strings <cli> | grep "Where the skill runs"` 류로 직접 확인한다(CLI = `~/.local/share/claude/versions/<ver>`). 2026-09-03 실측(v2.1.259) 기준 스킬 프론트매터 유효 키: `name` `description` `model` `effort` `allowed-tools` `disallowed-tools` `argument-hint` `disable-model-invocation` `user-invocable` `shell` `when_to_use` `paths` `hooks` `context` `agent` `background` `metadata`. 우리 `validate-skills.js` 는 `name`/`description` 만 보고, 하니스도 미지 키를 telemetry 만 남기고 삼키므로 **프론트매터 오타는 어디서도 안 걸린다**.
- **`model:` 은 실동작 오버라이드다.** 값 = `haiku`/`sonnet`/`opus`/`fable`/full ID/`inherit`. 스킬이 띄우는 `Agent` 는 model 미지정 시 **부모 세션 모델을 상속**하므로(실측: override 없는 subagent 가 `claude-opus-5[1m]` 보고), 저렴한 기계 작업을 위임할 땐 `Agent({model:'sonnet'})` 처럼 **명시**해야 한다. `Agent` 의 model 인자가 상속을 이긴다(실측: `model:'haiku'` → `claude-haiku-4-5-20251001`).
- **`context: fork` 는 사용자 입력이 필요한 스킬에 쓰지 말 것.** 서브에이전트에는 `AskUserQuestion` 이 아예 없다 — 호출하면 `No such tool available: AskUserQuestion. AskUserQuestion is not available inside subagents.` 로 즉시 에러이고 사용자 화면엔 아무것도 안 뜬다(실측). 하니스 가이드도 "Only set `context: fork` for self-contained skills that don't need mid-process user input". 인터뷰·승인 게이트가 있는 스킬(`goal-prompt`·`linear-*`·`land`·`ship`)은 **메인에 남기고, 읽기 무거운 스텝만 `Agent` 로 위임**한다(goal-prompt Step 1 `gp-ground` 가 그 형태). 중첩 subagent spawn 은 깊이 2까지 동작 확인.
- **스킬 트리거(`description`) eval 은 synthetic 단독으로 신뢰하지 말 것.** synthetic 매칭은 name-collision·sibling-skill 경쟁 artifact 로 false 0/100 을 낸다(실측). 실제 `~/.claude/skills/` 에 설치한 뒤 (a) 트리거 매칭 정확도와 (b) sibling-skill 오발화를 보는 **real-env probe** 를 병행한다.

## 3. 리뷰 체크리스트

- `name:` 값 ↔ 디렉토리명 일치, ASCII kebab-case (`scripts/ci/validate-skills.js` 가 강제).
- 프론트매터 키가 §2 의 유효 키 목록 안에 있는가 — 오타는 어떤 게이트도 안 잡는다.
- 본문 prose·`description:` 이 한국어인가, 그러면서 §1 의 원문 유지 항목을 번역하지 않았는가.
- SSOT 를 복제하지 않았는가 — 공유 계약은 포인터로 참조한다(`docs/architecture/decisions.md` §7·§11·§15).
- invisible 문자 0 (`scripts/ci/check-invisible-chars.js`).
