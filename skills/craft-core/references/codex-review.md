# Adversarial Plan Review via Codex

Phase 2 는 완성된 Phase-1 플랜을 codex 에게 적대적 리뷰어로서 넘긴다. codex 는
당신 플랜에 이해관계가 없는 두 번째 모델이다 — 그 독립성이 가치 전부다.
그 일은 코드가 존재하기 전에, 수정이 싼 곳에서 무엇이 잘못됐는지 찾는 것이다.

## 어떻게 호출하는가

**codex-companion 을 Bash background 로 직접 호출한다** — `codex:rescue` 스킬
경유가 아니라. 이유: rescue 서브에이전트 계약은 "stdout 만 그대로 반환, 실패
시 아무것도 반환하지 마라"인데, companion 은 최종 결과만 stdout 에 쓰고 진행·
중간 발견(`[codex] Assistant message captured: BLOCKING - ...`)은 전부 stderr
로 스트림한다. 그래서 rescue 경유는 timeout kill 시 부분 결과를 통째로 버린다
(실측 2026-07-20). 직접 호출 + stderr 파일 캡처가 그 회수 경로를 연다.

```bash
# 1) plugin root 해소 (버전 하드코딩 금지)
ROOT=$(ls -d ~/.claude/plugins/cache/openai-codex/codex/*/ | sort -V | tail -1)
# 2) background 실행 — stdout=최종 verdict, stderr=진행+부분 발견
date +%s > /tmp/codex-review-start.txt
CLAUDE_PLUGIN_ROOT="$ROOT" node "$ROOT/scripts/codex-companion.mjs" task \
  "<프롬프트>" > /tmp/codex-review-out.txt 2> /tmp/codex-review-err.txt
```

(경로는 세션 scratchpad 가 있으면 그쪽을 쓴다. companion 이 없으면 —
plugin 미설치 — `codex:rescue` 스킬 경유로 폴백하되, 그 경로는 부분 결과
회수가 안 됨을 안다.)

두 가지가 중요하다:

1. **read-only 로 유지.** `--write` 를 붙이지 않고, 프롬프트에도 평이한 말로
   *"Review and critique only. Do not edit, create, or delete any files."* 라고
   말한다. 그래야 planning 중 codex 가 당신 작업 트리 밖에 머문다.
2. **codex 를 플랜 파일로 경로로 가리켜라** — 당신의 요약이 아니라 실제 문서를
   읽도록. cwd 는 repo 루트로 두면 codex 가 repo 의 `.codex/config.toml`
   (effort 등)을 로드하고 레포 실측 대조까지 한다 — 느려지지만 품질이 오른다.

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

## 시간 가드 — watchdog (필수)

codex 호출은 hang 할 수 있고(실측 ~39분, 최종 포맷 단계 — companion 에는 턴
타임아웃이 없다), 동시에 **정당하게 느릴 수도 있다**(실측 2026-07-20: 20줄
미니 플랜이 repo cwd·effort=high 에서 165초 — 실전 플랜은 10분 초과가 정상
소요일 수 있다). 고정 cap 은 정상 실행을 죽이므로, **진행 기반 hang 판정**으로
글로벌 `delegated-review-watchdog` 규칙을 구현한다:

1. 위 direct 호출을 background 로 돌리고 폴링마다 stderr 파일을 본다 —
   포그라운드 무한 대기 금지.
2. **진행 기반 판정 (경과시간 감각 금지 — 파일과 `date +%s` 로만).**
   - stderr 에 새 진행 줄(`[codex] Running command` / `Assistant message
     captured` / `Turn started`)이 계속 붙고 있으면 → hang 아님. **hard cap
     20분**까지 연장 허용.
   - 마지막 진행 줄 이후 **3분+ 새 줄 없음** → hang 판정, 즉시 kill.
   - hard cap 20분 도달 → 진행 여부 무관 kill (효용 체감 + Phase 지연 상한).
3. **kill 후 부분 결과 회수 — 건너뛰지 마라.** stderr 의
   `[codex] Assistant message captured:` 줄들이 부분 발견이다(truncate 되어
   있지만 BLOCKING 항목의 존재와 방향은 읽힌다). 이것을 fallback 리뷰의 입력
   힌트로 넘긴다.
4. kill 후 **로컬 multi-agent 리뷰**(adversarial reviewer 역할 subagent)로 fallback — Phase 2 를 통째로 건너뛰지 않는다.
5. codex/fallback 의 verdict 는 **권고**다 — BLOCKING 발견은 플랜에 접기 전 직접 확인(grep/build/재현)으로 독립 재검증한다.

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
