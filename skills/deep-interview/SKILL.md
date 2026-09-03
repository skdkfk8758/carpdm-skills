---
name: deep-interview
description: 측정 가능한 ambiguity 점수로 게이트되는 Socratic 인터뷰로, 모호한 아이디어를 검증 가능한 요구사항 spec(REQ ID)으로 결정화하고 빌드 스킬로 라우팅한다. 사용자가 흐릿하거나 반쯤 형태만 잡힌 아이디어를 들고 와 코드 전에 인터뷰받거나 "함께 생각을 정리"하고 싶어 할 때 사용 — "인터뷰해줘", "같이 생각 정리하자", "요구사항 못 박아줘", "interview me about X", "help me think this through", "pin down what I actually want", "/deep-interview" 같은 표현. 아이디어가 정말로 모호하거나 클 때는 plan 직행보다 이것을 우선한다. 작고 이미 명확한 작업, 알려진 버그 수정, 이미 요구사항이 확정돼 바로 구현에 들어갈 수 있으면 사용하지 말 것. plan 문서+UI 시안이 목적이면 deep-plan. 이미 형태가 잡힌 plan·결정·설계의 구멍 찾기·압박 테스트("이 계획 맞는지 털어봐", "grill me")는 mattpocock grilling — deep-interview 는 무엇을 만들지부터 흐릿할 때다.
---

# Deep Interview — 빌드 전 Socratic 모호성 해소

흐릿한 아이디어는 *어디가 흐릿한지* 사용자 자신도 모른다. 이 스킬은 모호성을
**측정**하고(ambiguity 점수 = 결승선) **Socratic 질문**으로 사용자의 사고를 끌어내
번호 매긴 요구사항 spec 으로 결정화한 뒤 빌드 스킬로 손을 건넨다. 규율은 grilling 과
같다 — **사실은 내가 캐고, 결정만 사용자에게** — 산출이 다르다(합의가 아니라 REQ spec).

진입 판단(grilling·wayfinder·goal-prompt 내장 인터뷰와의 경계)은
`~/.claude/rules-ondemand/interview-routing.md` 한 장. 지시 자체의 재진술은 `readchk` 가
앞단에서 한다.

## 읽는 것 (lazy — 시점마다 그 파일만)

| 시점 | 파일 |
|---|---|
| 라운드 1 전 | `references/socratic-playbook.md` — 6 유형 · 답 형태 · challenge |
| 매 라운드 점수 | `references/scoring.md` — 차원 · 공식 · sticky · stalled · 라운드 보고 |
| grounding 브리프 · 갭 태그 | `~/.claude/skills/goal-prompt/SKILL.md` Step 1 `gp-ground` 절 + Step 2 갭 태그 4종 — SSOT, 여기 복제 안 함 |
| Phase 4 | `references/spec-template.md` |
| Phase 4 종료 보고 | `~/.claude/references/craft/output-contract.md` |
| Phase 5 | `references/next-skill-routing.md` |

## Phase 0 — 임계값 (한 번, 묻지 않고)

ambiguity ≤ threshold 에서 끝난다. `--quick` 0.35 · 기본 0.20 · `--deep` 0.10. 플래그가
없으면 0.20 으로 시작하고 첫 질문 전에 한 번 고지한다: *"Target ≤ 0.20 (`--quick`/
`--deep` 로 조정). 보통 3~5 라운드, '이 정도면 됐어' 하면 그 자리에서 결정화합니다."*
도중 변경은 그 라운드부터 적용.

## Phase 1 — Orient + grounding

greenfield / brownfield 를 판정한다(scoring 공식이 갈린다). brownfield 면 **묻기 전에**
영향 반경을 실측한다 — `di-ground` 서브에이전트, goal-prompt `gp-ground` 와 같은 계약:

```
Agent({ name: 'di-ground', model: 'sonnet', subagent_type: 'general-purpose' })
```

읽기 전용 · **리터럴만 반환**(경로·심볼·현행 동작 — 산문 요약은 미확인) · 같은 이름
재spawn 금지, 재조회는 `SendMessage({to:'di-ground'})`. 브리프 = 지침·어휘(`CONTEXT.md`·
ADR) · 영향 반경 · 기존 seam · 현행 동작. 반경이 자명해 Read 2~3콜이면 인라인.

**Done when:** 후보 질문의 `[CODE]` 항목마다 `path:line` 리터럴이 붙어 있다.

## Round 0 — 토폴로지 (첫 프론티어)

아이디어를 1~6개 컴포넌트로 **내가 초안**한다(초기 설명 + grounding 에서). 사용자는
컴포넌트별 **active / deferred** 만 고른다 — `AskUserQuestion` 으로 제안하고 확인받는다.
잘못 쪼갠 토폴로지는 entity-stability(scoring.md)로 뒤에 드러난다.

**Done when:** 모든 컴포넌트에 active/deferred 태그.

## Phase 2 — 루프

ambiguity ≤ threshold 또는 stalled 까지 반복:

1. **Credit.** 직전 답이 조준 밖 차원까지 올렸으면 반영하고 말한다("constraints 도
   0.3→0.6"). 이미 답한 것은 되짚기로만 확인한다.
2. **Score.** 차원별 0~1 → ambiguity. 타깃 = 가장 약한 active 컴포넌트의 가장 약한 차원
   (sticky 규칙 — scoring.md). 무엇을 왜 조준하는지 말한다.
3. **Tag.** 그 차원을 여는 질문 후보를 goal-prompt 4태그로 가른다 — `[CODE]` →
   `di-ground` 재개 또는 Grep · `[DOCS]` → `mattpocock-skills:research` 백그라운드, 없으면
   context7 인라인 · `[THIRD]` → 권장답으로 assumption 승격 + 소유자 기록(기다리지 않는다)
   · **`[HUMAN]` 만 사용자에게.** 사실 갭이 도는 동안 그것에 의존하지 않는 `[HUMAN]` 을
   먼저 묻는다.
4. **Ask — 답 형태로 갈린다** (playbook §답 형태):
   - **결정형**(옵션 출처 = 코드 현행 또는 사용자 발화): 독립 항목끼리 **프론티어**로
     `AskUserQuestion` 1콜 ≤4문항, 첫 옵션 `(권장)` + 근거 한 줄. 출처 없으면 결정형이 아니다.
   - **생성형**(구체 예시·근거·워크플로): 산문 **1문항**, 권장답 없음. 6 Socratic 유형 중
     하나를 스스로 명명하고 던진다 — 사용자가 생각하고 나는 압력만. 여기가 grilling 과
     갈리는 지점이다.
5. **Report.** scoring.md 라운드 테이블 — 점수 · ambiguity % · 컴포넌트 · `locked:` ·
   다음 타깃 · stalled 여부. 테이블 연속이 곧 상태다(별도 파일 없음).

**Challenge — stalled 일 때만, 순서대로 각 1회:** contrarian → simplifier → ontologist.
repo 에 `CONTEXT.md` 가 있으면 ontologist 는 `mattpocock-skills:domain-modeling` 호출로
대체한다. 오프너는 playbook.

**멈춤:** threshold 도달 → Phase 4 · soft cap 라운드 8 → 계속/결정화 제안 + 남은 모호
명명 · hard cap 라운드 15 → 결정화 + 잔여 명시 · "됐어"(라운드 2+) → 따른다, 잔여 명시.

## Phase 4 — spec 결정화

> 세션 모델이 최상위 티어(fable/opus)가 아니면 `Agent(model:'fable', 실패 시 'opus' —
> 폴백 보고)` 로 위임한다: 압축 digest(토폴로지 · `locked:` 누적 · 잔여 · template 경로 ·
> 저장 경로)만 넘기고 메인이 Read 로 검증.

`spec-template.md` 로 작성 — `REQ-F/REQ-N` 안정 ID · MoSCoW · acceptance · Origin 라운드.
저장은 repo 관례(`docs/specs/`), 없으면 경로 제안 후 확정.

**Done when — 콜드리드 통과:** `shower` 로 spec **내용만**(의도 없이) 컨텍스트 없는
서브세션에 넘겨 "stands on its own" 판정을 받는다. 미달 항목은 spec §5 Residual
ambiguity 에 기록. `--quick` 은 생략하고 보고에 명시. 그 뒤 `output-contract.md` 고정
블록(`result:` + `SPEC` 행)을 내고 Phase 5 로.

## Phase 5 — 다음 스킬 (제안만)

`next-skill-routing.md` 를 **Read 한 뒤** available-skills 목록에서 valid-next 를 재선정하고
`AskUserQuestion` 으로 추천한다 — 자동 시작 없음. spec 은 다음 스킬에게 **확정 입력**이다
(재인터뷰 없음).

**넛지 1개만**(paperthin §4 — 사용자 타이핑 전용, 해당 없으면 붙이지 않는다):
- 결정형 라운드에서 권장답을 전부 그대로 골랐다 → `/feynman` (빌린 이해 검증).
- Residual ambiguity ≠ None → `/hate` (첫 못).
