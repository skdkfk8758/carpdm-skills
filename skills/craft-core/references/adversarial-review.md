# 적대 리뷰 1-pass — 프롬프트 골격 + verdict + triage 원장 (공유 SSOT)

적대 리뷰를 **1회** 돌리고, 발견을 **증거 원장으로 triage** 해서 닫는 공통 계약이다.
소비처: pipeline Phase 2(잔여 플랜 리뷰), `security.md` §2(diff correctness 리뷰),
`deep-plan` Step 2(debate 라운드 — 루프는 그 스킬 소유). 리뷰 *대상* 과 공격 목록은
각 소비처가 정의하고, 여기는 **호출 형태·verdict 파싱·원장 규칙**만 산다.

> **cross-model(codex) 은퇴 (2026-07-30).** 종전 이 계약은 codex 플러그인
> (`codex@openai-codex`)의 `codex-companion.mjs` 를 Bash background 로 직접 호출해
> *다른 모델* 의 독립 판단을 샀다. 사용자 요청으로 플러그인을 제거(uninstall)하면서
> 호출 경로가 소멸했다 — 남은 리뷰어는 전부 같은 모델이다.
>
> **잃은 것을 명시한다: 모델 독립성.** 같은 모델의 자기 리뷰는 같은 맹점을 공유하므로,
> 발견의 신뢰는 이제 *다른 모델* 이 아니라 **역할 분리(adversary 프롬프트) + 원장의
> 직접 검증 증거**에서만 나온다. 이 계약을 "cross-model 검증단" 이라고 부르지 말 것 —
> 더는 아니다. 복원 경로: `claude plugin install codex@openai-codex` 후 git history 의
> `codex-review.md`·`codex-build.md` revert(그 두 파일이 호출·watchdog·limit 래더 SSOT
> 였다).
>
> (선행 은퇴: **수렴 핑퐁** — 직렬 24.8분(중앙, 총 벽시계 21%, `craft-timing.jsonl`
> n=27)에 상류 deep-plan 리뷰와 중복이었다. 발견의 가치는 루프가 아니라 적대 구조 +
> 증거 원장에서 나온다.)

## 어떻게 돌리는가

**리뷰어 역할 subagent 를 `Agent` 로 1개 띄운다** — 구현자와 컨텍스트를 공유하지 않게.
프롬프트가 곧 계약이다:

1. **read-only 로 유지.** 프롬프트에 평이한 말로 *"Review and critique only. Do not
   edit, create, or delete any files."* 라고 말한다.
2. **대상을 파일 경로로 가리켜라** — 당신의 요약이 아니라 실제 문서/diff 를 읽도록.
   요약을 넘기면 리뷰어가 당신의 프레이밍을 물려받아 독립성이 더 깎인다.
3. **역할을 명시하라** — *"You are an adversarial reviewer. Find what breaks."*
   같은 모델이므로 **역할 분리가 유일한 독립성 장치**다. 이걸 빼면 자기 확인이 된다.
4. **1회다.** 재리뷰 요청으로 발견을 닫지 않는다 — 원장의 직접 검증으로 닫는다.

## 프롬프트 골격 — verdict 계약은 공통, 공격 목록은 소비처가

`<task>`(대상 경로 + read-only + 역할) · `<look_for>`(소비처 정의 — 플랜 공격 목록은
pipeline Phase 2, diff correctness 목록은 `security.md` §2) · `<grounding_rules>` ·
`<structured_output_contract>` 로 구성한다. 뒤의 둘은 공통:

```
<grounding_rules>
Cite the specific section/file:line for every finding. If something is a
hypothesis, say so. Do not invent problems to seem thorough.
Bias toward approval: surface only findings that would materially change the
outcome. Style preferences and scope expansions beyond the stated goal are
not findings.
</grounding_rules>

<structured_output_contract>
End your response with exactly one fenced json block:
{"issues": [{"id": "B1", "severity": "high|med|low",
  "section": "<section or file:line>", "problem": "...", "suggested_fix": "..."}]}
- severity=high — must be resolved before proceeding (BLOCKING).
Free-form analysis above the block is welcome; the block is the verdict.
</structured_output_contract>
```

`Agent` 의 구조화 출력(schema)을 쓸 수 있으면 그쪽이 낫다 — 검증이 도구 층에서 돌아
계약 위반 시 리뷰어가 재시도한다. 산문 반환이면 아래 파싱 규칙을 적용한다.

## verdict 파싱 — fail-closed

계약은 fenced json 블록 **정확히 1개**다. 0개·2개 이상·파싱 실패·`issues` 배열 부재는
전부 **계약 위반 → 발견 미확보**: 같은 프롬프트로 verdict 만 재요청하고(1회), 재요청도
실패하면 그 사실을 보고에 명시한다. **복수 블록에서 "마지막 것을 취하는" 추측 복구를
하지 않는다** — 어느 블록이 최종인지 모르는 채 고르면 조용히 틀린 verdict 를 채택한다.
파싱 실패를 "이슈 0건"으로 읽는 것이 가장 위험한 오독이다(실측: 추출 정규식 결함으로
정상 verdict 를 "미검출"로 오판한 사례).

## triage 원장 — 발견은 재리뷰가 아니라 증거로 닫는다

verdict 의 **모든 issue id** 에 대해 원장 한 줄씩 작성한다(scratchpad 또는 리뷰 기록
섹션). 닫힘 판정자는 리뷰어 재호출이 아니라 **당신의 직접 검증**이다:

```
| id | 판정 | 근거 |
| B1 | FIXED | plan §3 재작성 / <test-file> red→green — <무엇을 어떻게> |
| B2 | REJECTED | <grep/build/재현 증거로 반박> |
| B3 | DEFERRED | <정당 사유 + 행선지 — 후속 이슈 URL/plan 후속 섹션> |
```

- **high 는 FIXED 또는 증거 있는 REJECTED 만** — defer 불가. 미해소 high 를 들고
  다음 단계로 진행하지 않는다.
- **REJECTED 는 반드시 직접 검증 증거(grep/build/재현)를 동반한다** — 증거 없는 reject
  금지. 리뷰어 verdict 를 그대로 믿지 않는 독립 재검증이 이 원장 작성 행위 자체다
  (리뷰어의 verdict 는 **권고**다). 같은 모델 리뷰어에서는 이 규율이 종전보다 **더**
  중요하다 — 동조(리뷰어가 구현 판단을 그대로 승인)와 환각을 걸러낼 유일한 층이다.
- **DEFERRED 는 med/low 전용** — 사유와 행선지(후속 이슈·plan 섹션)를 반드시 명명.
  행선지 없는 defer 는 조용한 무시와 같다.

종료 후 결과를 대상 문서에 기록한다(플랜이면 `## Plan review — 1-pass: <발견 수 +
원장 요약>`, diff 리뷰면 Phase 4 리포트에). 기존 플랜의 레거시 헤딩 `## Codex review`
는 상류 리뷰 흔적으로 **그대로 인식**한다(Phase 2 게이트 2항).

## Anti-patterns

- 리뷰어에게 파일 편집을 허용 (read-only 줄을 잊음).
- 각 항목을 원장으로 닫는 대신 리뷰어 출력을 그대로 문서에 붙여넣기.
- 증거 없는 REJECTED — 지적을 "판단상 아님"으로 기각. 원장의 근거 칸이 비면 그 reject
  는 무효다.
- 미해소 high 를 DEFERRED 로 밀거나 들고 다음 단계 진입.
- verdict JSON 없이 산문만 보고 발견 유무를 "느낌으로" 판정.
- 수렴 핑퐁 재도입(라운드 관리·재리뷰 요청) — 은퇴된 구조다.
- 역할 분리 없이 "리뷰해줘" 만 던짐 — 같은 모델이므로 adversary 역할이 없으면
  자기 확인이 되고, 이 계약의 유일한 독립성 장치가 사라진다.
- 이 리뷰를 cross-model 검증으로 보고 — 모델 독립성은 은퇴했다(위 기록).
- 모든 med/low nit 을 필수로 취급 → 요청하지 않은 scope creep.
