# Adversarial Plan Review via Codex — cross-model debate

Phase 2 는 완성된 Phase-1 플랜을 codex 에게 적대적 리뷰어로서 넘긴다. codex 는
당신 플랜에 이해관계가 없는 두 번째 모델이다 — 그 독립성이 가치 전부다.
그 일은 코드가 존재하기 전에, 수정이 싼 곳에서 무엇이 잘못됐는지 찾는 것이다.

구조는 **converge-gated 핑퐁**이다: codex 가 지적하고(R1), 당신(Claude)이
수정 + 응답 원장으로 답하고, codex 가 같은 스레드(`--resume-last`)에서 해소
여부를 검증한다(Rn). 수렴하면 멈춘다 — 라운드 수는 게이트가 결정하지 고정
횟수가 아니다.

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
# 2) R1 — fresh 실행. stdout=최종 verdict, stderr=진행+부분 발견
#    --effort 는 아래 effort 게이트 참조 (기본 medium, 고위험 표면만 high)
#    끝에 완료 마커를 남긴다 — watchdog 의 hang 워처가 이 파일을 본다.
date +%s > /tmp/codex-review-start.txt
CLAUDE_PLUGIN_ROOT="$ROOT" node "$ROOT/scripts/codex-companion.mjs" task --effort medium \
  "<R1 프롬프트>" > /tmp/codex-review-r1-out.txt 2> /tmp/codex-review-r1-err.txt
date +%s > /tmp/codex-review-r1-done.txt
# 3) R2+ — 같은 스레드 재개 (codex 가 이전 라운드 컨텍스트 유지, 델타만 검증)
CLAUDE_PLUGIN_ROOT="$ROOT" node "$ROOT/scripts/codex-companion.mjs" task --resume-last --effort medium \
  "<Rn 프롬프트>" > /tmp/codex-review-r2-out.txt 2> /tmp/codex-review-r2-err.txt
date +%s > /tmp/codex-review-r2-done.txt
```

(경로는 세션 scratchpad 가 있으면 그쪽을 쓴다. companion 이 없으면 —
plugin 미설치 — `codex:rescue` 스킬 경유로 폴백하되, 그 경로는 부분 결과
회수도 스레드 재개도 안 됨을 안다: 매 라운드 fresh 리뷰로 강등.)

두 가지가 중요하다:

1. **read-only 로 유지.** `--write` 를 붙이지 않고, 프롬프트에도 평이한 말로
   *"Review and critique only. Do not edit, create, or delete any files."* 라고
   말한다. 그래야 planning 중 codex 가 당신 작업 트리 밖에 머문다.
2. **codex 를 플랜 파일로 경로로 가리켜라** — 당신의 요약이 아니라 실제 문서를
   읽도록. cwd 는 repo 루트로 두면 codex 가 repo 의 `.codex/config.toml`
   (effort 등)을 로드하고 레포 실측 대조까지 한다 — 느려지지만 품질이 오른다.
3. **effort 게이트 (비용) — 프롬프트 산문이 아니라 `--effort` CLI 플래그로 건다.**
   프롬프트에 "medium reasoning effort" 라고 쓰는 것은 추론 예산을 바꾸지
   **않는다** — 플래그 미지정이면 `~/.codex/config.toml` 의
   `model_reasoning_effort` (이 머신 기준 `high`) 가 그대로 적용된다.
   - **기본 `--effort medium`** — 소·중형 플랜 전부.
   - **`--effort high`** — 보안 surface·외부 호출자 계약 변경·마이그 포함 플랜만.
   실측(동일 프롬프트·동일 repo·동시 실행, 2026-07-28): high 473s vs medium 206s
   = **2.3×**. 툴콜은 high 6회 / medium 22회 — 시간차는 repo 대조가 아니라 추론
   토큰이다. 즉 cwd=repo(위 2항)는 비용 주범이 아니므로 유지한다.

## R1 프롬프트 형태

codex 는 compact 한 XML-태그 operator 프롬프트에 가장 잘 응답한다. 적응하라:

```
<task>
Adversarially review the implementation plan at <plan-path>. Your job is to find
what is WRONG with it before any code is written. Be hostile but specific.
Review and critique only — do NOT edit, create, or delete any files.
Do not route through skills or spawn subagents — review the plan directly.
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
Bias toward approval: surface only findings that would materially change the
implementation outcome. Style preferences and scope expansions beyond the
stated goal are not findings.
</grounding_rules>

<structured_output_contract>
End your response with exactly one fenced json block:
{"converged": bool, "issues": [{"id": "B1", "severity": "high|med|low",
  "section": "<plan section>", "problem": "...", "suggested_fix": "..."}]}
- severity=high — must be resolved before implementation (BLOCKING).
- converged=true only when no high-severity issues remain.
- Keep ids stable across rounds (B1 stays B1 in every later round).
Free-form analysis above the block is welcome; the block is the verdict.
</structured_output_contract>
```

## 수렴 판정 (isConverged)

verdict JSON 으로 기계 판정한다 — 산문 해석 금지:

- `converged === true` **또는** `issues` 에 `severity:"high"` 가 0건 → **수렴, 루프 종료.**
- 그 외 → 응답 라운드 진행.

(ADMap harness `debate-control.mjs` 의 `isConverged` 와 같은 시맨틱. 그 스크립트는
프로젝트 로컬이라 import 하지 않는다 — 규칙 자체를 여기 인라인해 전 프로젝트에서
동작시킨다.)

## 응답 라운드 (Rn) — 원장으로 답하고, 스레드에서 검증받는다

수렴 전이면 라운드마다:

1. **플랜 수정** — 수용하는 high/med 항목을 해당 섹션에 접어 넣는다.
2. **응답 원장(response ledger) 작성** — scratchpad 에, codex 의 모든 issue id 에
   대해 한 줄씩:

   ```
   | id | 판정 | 근거 |
   | B1 | FIXED | plan §3 재작성 — <무엇을 어떻게> |
   | B2 | REJECTED | <grep/build/재현 증거로 반박> |
   | B3 | DEFERRED | <정당 사유 + 행선지 — 후속 이슈 URL/plan 후속 섹션> |
   ```

   **REJECTED 는 반드시 직접 검증 증거(grep/build/재현)를 동반한다** — 증거
   없는 reject 금지. codex verdict 를 그대로 믿지 않는 독립 재검증이 이
   원장 작성 행위 자체다.
   **DEFERRED 는 med/low 전용** — high 는 defer 불가(FIXED 또는 증거 있는
   REJECTED 만). defer 는 사유와 행선지(후속 이슈·plan 섹션)를 반드시 명명 —
   행선지 없는 defer 는 조용한 무시와 같다. 이 3선택지(fix/defer/push-back)가
   리뷰어의 범위 확장 압박에 대한 author 의 수렴 장치다.
3. **codex 에 `--resume-last` 로 원장 검증 요청:**

   ```
   <task>
   Round N of the adversarial review you started. The plan at <plan-path> was
   revised. The response ledger below answers each of your issues by id.
   Verify: for each FIXED — is it actually resolved in the revised plan?
   For each REJECTED — does the evidence hold? Re-raise an issue only if the
   rebuttal fails. New issues only if material.
   Review and critique only — do NOT edit, create, or delete any files.
   Do not route through skills or spawn subagents — verify the ledger directly.
   </task>

   <response_ledger>
   <원장 본문>
   </response_ledger>

   <structured_output_contract>
   (R1 과 동일 JSON 블록 — id 유지, 해소된 항목은 목록에서 제거)
   </structured_output_contract>
   ```

resume 이라 codex 는 플랜 전체를 재독하는 대신 델타를 검증한다 — "지적이
해소됐는가"를 지적한 본인이 판정하는 것이 이 루프가 닫히는 지점이다.

## 종료 규칙 3개

- **수렴** — high 0건. NON-BLOCKING(med/low)은 항목별 채택 여부를 결정하고
  기록한다.
- **분쟁 에스컬레이션** — 같은 id 를 당신이 2회 REJECTED 했는데 codex 가 2회
  재제기하면, 그 항목은 루프에서 제외하고 양쪽 논거와 함께 사용자에게
  surface 한다. 적대자를 조용히 무시하지도, 맹목적으로 따르지도 말 것 —
  단, 논쟁을 무한히 돌리지도 말 것.
- **캡 3라운드** — 도달 시 미해소 high 목록 + 원장을 사용자에게 제시하고
  멈춘다. (실측 codex 1회 = medium 3~4분 · high 8분, 라운드 사이 원장·플랜
  수정 오버헤드가 그보다 크다 — 그 이상은 효용 대비 비용 초과. 수렴 라운드
  실측 분포 n=5: 2R·2R·3R·3R·4R — 4R 1건은 도구오류 재기동 케이스라
  3 을 캡으로 잡아도 정상 수렴을 자르지 않는다.)

종료 후 결과를 플랜에 기록: `## Codex review — round N: <verdict + what changed>`
(라운드별 1줄 + 최종 수렴/에스컬레이션 상태).

## 시간 가드 — watchdog (필수, 라운드마다)

codex 호출은 hang 할 수 있고(실측 ~39분, 최종 포맷 단계 — companion 에는 턴
타임아웃이 없다), 동시에 **정당하게 느릴 수도 있다**(실측 2026-07-20: 20줄
미니 플랜이 repo cwd·effort=high 에서 165초 — 실전 플랜은 10분 초과가 정상
소요일 수 있다). **임계가 빡빡하면 정상 실행을 hang 으로 오판해 죽인다** —
실측 2건(`hang(474s, verdict 미회수)` → p2 45분, `hang(311s 무진행)` → p2 33분)의
474s 는 정상 high 런 1회 소요(473s)와 같은 길이였다. kill 하면 부분 결과만 건지고
로컬 폴백을 처음부터 다시 돌리므로 오판 비용이 hang 방치 비용보다 크다.
고정 cap 은 정상 실행을 죽이므로, **진행 기반 hang 판정**으로
글로벌 `delegated-review-watchdog` 규칙을 구현한다 — 단 **임계값은 아래 실측치가
우선**(글로벌 룰의 20분/3분은 codex 이전 계측 기반의 일반값). **모든 라운드(R1·Rn)에
동일 적용한다:**

1. **호출 자체를 Bash `run_in_background` 로 띄운다 — 그러면 대기 로직이
   필요 없다.** 잡이 끝나면 하니스가 알아서 완료 알림을 보낸다. 포그라운드
   무한 대기 금지, 그리고 짧은 sleep 폴링 반복도 금지 — 폴 1회가 메인루프 턴
   1회이고, 이 폴링이 p2 오버헤드의 실질 부분이다.
   hang 감시는 **별도의 background until-loop 하나**로 붙인다 — stderr 가
   8분간 커지지 않으면 exit 해서 알림을 띄우는 워처:

   ```bash
   # codex 잡과 함께 띄운다. 정상 종료면 done 마커가 생겨 워처도 같이 빠진다.
   until [ -f /tmp/codex-review-r1-done.txt ] || \
         [ $(( $(date +%s) - $(stat -f %m /tmp/codex-review-r1-err.txt) )) -ge 480 ]; do
     sleep 20
   done
   [ -f /tmp/codex-review-r1-done.txt ] && echo OK || echo STALL
   ```

   (`Monitor` 는 쓰지 않는다 — 알림이 **1회**뿐인 대기에는 background Bash 가
   맞는 도구다. Monitor 는 발생마다 반복 알림이 필요할 때용이고, 무한 명령을
   걸면 조건 충족 후에도 타임아웃까지 armed 로 남는다.)
2. **진행 기반 판정 (경과시간 감각 금지 — 파일과 `date +%s` 로만).**
   - stderr 에 새 진행 줄(`[codex] Running command` / `Assistant message
     captured` / `Turn started`)이 계속 붙고 있으면 → hang 아님. **hard cap
     12분/라운드**까지 연장 허용.
   - 마지막 진행 줄 이후 **8분+ 새 줄 없음** → hang 판정, 즉시 kill.
     (임계 근거: 정상 high 런이 툴콜 6회/473s — 툴콜 사이 추론 무음이 수 분간
     이어진다. 종전 3분 임계는 이 정상 구간을 잘라 죽였다.)
   - hard cap 12분 도달 → 진행 여부 무관 kill (기본 effort=medium 실측 206s ·
     3라운드 캡 기준 상한. 효용 체감 + Phase 지연 상한).
3. **kill 후 부분 결과 회수 — 건너뛰지 마라.** stderr 의
   `[codex] Assistant message captured:` 줄들이 부분 발견이다(truncate 되어
   있지만 BLOCKING 항목의 존재와 방향은 읽힌다). 이것을 fallback 리뷰의 입력
   힌트로 넘긴다.
4. kill 후 **로컬 multi-agent 리뷰**(adversarial reviewer 역할 subagent)로
   fallback — Phase 2 를 통째로 건너뛰지 않는다. fallback 리뷰에도 같은
   verdict JSON 계약과 수렴 게이트를 적용한다.
5. codex/fallback 의 verdict 는 **권고**다 — high 발견을 플랜에 접기 전
   직접 확인(grep/build/재현)으로 재검증하고, 그 증거를 원장에 남긴다.

## Anti-patterns

- *플랜* 리뷰 중 codex 가 파일을 편집하게 두기 (read-only 줄을 잊음).
- 각 항목을 해소하는 대신 codex 출력을 그대로 플랜에 붙여넣기.
- R2+ 를 fresh 호출로 돌리기 — 스레드가 끊겨 codex 가 해소 여부를 검증 못
  하고 플랜 전체를 재독한다 (`--resume-last` 를 쓸 것).
- 증거 없는 REJECTED — codex 지적을 "판단상 아님"으로 기각. 원장의 근거
  칸이 비면 그 reject 는 무효다.
- effort 를 프롬프트 산문으로 "지정" — `--effort` 플래그 없으면 config 의
  `high` 가 그대로 적용된다(라운드당 2.3× 비용). 게이트는 플래그다.
- verdict JSON 없이 산문만 보고 수렴을 "느낌으로" 판정.
- 수렴 전에 캡·에스컬레이션 사유 없이 루프 중단 — 미해소 high 를 들고
  구현에 진입하는 것.
- 짧은 간격 sleep 폴링으로 라운드를 지킴 — 폴 1회 = 메인루프 턴 1회라
  codex 를 기다리는 시간보다 폴링이 더 비싸진다. 잡을
  `run_in_background` 로 띄우고 완료 알림을 받을 것.
- 알림 1회짜리 대기에 `Monitor` 를 씀 — 무한 명령이면 조건 충족 후에도
  타임아웃까지 armed 로 남는다. Monitor 는 발생마다 반복 알림용.
- 모든 NON-BLOCKING nit 을 필수로 취급 → 플랜이 요청하지 않은 scope
  creep.
