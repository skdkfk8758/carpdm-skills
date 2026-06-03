# Adversarial Plan Review via Codex

Phase 2 는 완성된 Phase-1 플랜을 codex 에게 적대적 리뷰어로서 넘긴다. codex 는
당신 플랜에 이해관계가 없는 두 번째 모델이다 — 그 독립성이 가치 전부다.
그 일은 코드가 존재하기 전에, 수정이 싼 곳에서 무엇이 잘못됐는지 찾는 것이다.

## 어떻게 호출하는가

**`codex:rescue`** 스킬을 (`Skill` 도구로) 쓴다. 당신의 프롬프트를 단일
codex `task` 실행으로 전달한다. 두 가지가 중요하다:

1. **read-only 로 유지.** rescue 런타임은 프롬프트가 명확히 review-only 를
   요청하지 않으면 write-capable codex 로 기본값을 둔다. 그러니 프롬프트는,
   평이한 말로, *"Review and critique only. Do not edit, create, or delete any
   files."* 라고 말해야 한다. 그래야 planning 중 codex 가 당신 작업 트리 밖에 머문다.
2. **codex 를 플랜 파일로 경로로 가리켜라** — 당신의 요약이 아니라 실제 문서를
   읽도록.

## 프롬프트 형태

codex 는 compact 한 XML-태그 operator 프롬프트에 가장 잘 응답한다. 적응하라:

```
<task>
Adversarially review the implementation plan at <plan-path>. Your job is to find
what is WRONG with it before any code is written. Be hostile but specific.
Review and critique only — do NOT edit, create, or delete any files.
</task>

<look_for>
- Hidden or unstated assumptions that, if false, break the plan
- Missing edge cases / failure modes
- Security holes (injection, authz gaps, secret/host exposure, unsafe input)
- A materially simpler approach that reaches the same goal
- Scope creep — steps not justified by the stated goal
- Steps whose "verify" check does not actually prove the step
- Architecture decisions: does the plan make a hard-to-reverse decision that
  should be recorded as an ADR? Does it conflict with a standing ADR?
</look_for>

<grounding_rules>
Cite the specific plan section for every finding. If something is a hypothesis,
say so. Do not invent problems to seem thorough.
</grounding_rules>

<structured_output_contract>
Return two lists:
1. BLOCKING — must be resolved before implementation, each with the section it
   refers to and a concrete suggested fix.
2. NON-BLOCKING — worth considering, same format.
If the plan is sound, say so plainly and return empty lists.
</structured_output_contract>
```

## codex 가 응답한 후

- Triage: 모든 **BLOCKING** 발견을 플랜에 접어 넣는다 (관련 섹션 수정).
  NON-BLOCKING 항목별로 채택할지 결정한다; 결정을 기록한다.
- 결과를 플랜에 기록: `## Codex review — round N: <verdict + what changed>`.
- 비trivial 한 변경을 했다면 수정된 플랜을 **재리뷰**한다. blocking 이의가
  남지 않거나, 2 라운드 후 멈춘다 (그 이후는 효용 체감).
- codex 와 당신이 의견이 다르면, 양쪽 논거와 함께 사용자에게 surface 한다 —
  적대자를 조용히 무시하지도, 맹목적으로 따르지도 말 것.

## Anti-patterns

- *플랜* 리뷰 중 codex 가 파일을 편집하게 두기 (read-only 줄을 잊음).
- 각 항목을 해소하는 대신 codex 출력을 그대로 플랜에 붙여넣기.
- 라운드 1 이 진짜 구조적 문제를 surface 했는데 한 라운드로 끝내기.
- 모든 NON-BLOCKING nit 을 필수로 취급 → 플랜이 요청하지 않은 scope
  creep.
