# Codex 1-pass 리뷰 — 호출 계약 + verdict + triage 원장 (공유 SSOT)

codex 를 **적대적 리뷰어로 1회 호출**하고, 발견을 **증거 원장으로 triage** 해서
닫는 공통 계약이다. 소비처: pipeline Phase 2 폴백(플랜 리뷰), security.md §2
(diff correctness 리뷰), deep-plan Step 2/④(호출 규약만 차용 — debate 루프는
그 스킬 소유). 리뷰 *대상* 과 공격 목록은 각 소비처가 정의하고, 여기는 **호출·
마스킹·effort·verdict 파싱·watchdog·원장 규칙**만 산다.

> **수렴 핑퐁 은퇴 (2026-07-29).** 종전 이 파일은 converge-gated 핑퐁(최대
> 3라운드, `--resume-last` 스레드 관리, 분쟁 에스컬레이션)이었다. 은퇴 근거:
> Phase 2 핑퐁이 직렬 24.8분(중앙, 총 벽시계의 21%)인데 상류 리뷰(deep-plan
> debate)와 중복이었고, 배관(라운드 인덱싱·스레드 오염·verdict 라운드 계약)이
> 유지비의 주범이었다(자기결함 수정 3건 실측). 발견의 가치는 적대 구조 + 증거
> 원장에서 나온다 — 루프가 아니라(로컬 폴백 22건이 동급 발견 산출 실측).
> 복원은 git history.

## 어떻게 호출하는가

**codex-companion 을 Bash background 로 직접 호출한다** — `codex:rescue` 스킬
경유가 아니라. 이유: rescue 서브에이전트 계약은 "stdout 만 그대로 반환, 실패
시 아무것도 반환하지 마라"인데, companion 은 최종 결과만 stdout 에 쓰고 진행·
중간 발견(`[codex] Assistant message captured: BLOCKING - ...`)은 전부 stderr
로 스트림한다. 그래서 rescue 경유는 timeout kill 시 부분 결과를 통째로 버린다
(실측 2026-07-20). 직접 호출 + stderr 파일 캡처가 그 회수 경로를 연다.

```bash
# 0) 출력 디렉토리 — 세션 scratchpad 우선. /tmp 고정 파일명 금지
#    (동시 세션·다른 repo 실행이 서로 덮어쓴다). 없으면 mktemp -d 로 만든다.
OUT="${SCRATCHPAD:-$(mktemp -d -t codex-review)}"
# 1) plugin root 해소 (버전 하드코딩 금지)
ROOT=$(ls -d ~/.claude/plugins/cache/openai-codex/codex/*/ | sort -V | tail -1)
# 2) 1-pass 실행. TAG 는 소비처별 식별자(plan / diff 등) — 동시 리뷰 파일 충돌 방지.
#    --effort 는 아래 effort 게이트 참조 (기본 medium, 고위험 표면만 high)
#    프롬프트는 인자 대신 파일로 — 셸 확장·injection 회피(<<'EOF' 는 확장 안 함)
TAG=plan
cat > "$OUT/$TAG-prompt.txt" <<'EOF'
<소비처가 정의한 리뷰 프롬프트>
EOF
date +%s > "$OUT/$TAG-start.txt"
CLAUDE_PLUGIN_ROOT="$ROOT" node "$ROOT/scripts/codex-companion.mjs" task --effort medium \
  --prompt-file "$OUT/$TAG-prompt.txt" > "$OUT/$TAG-out.txt" 2> "$OUT/$TAG-err.txt" \
  && date +%s > "$OUT/$TAG-done.txt" || date +%s > "$OUT/$TAG-failed.txt"
#    ^ 마커는 성공/실패를 갈라 남긴다. 무조건 done 을 찍으면 node 가 죽어도
#      워처가 "정상 완료"로 읽는다.
```

(companion 이 없으면 — plugin 미설치 — **`codex:rescue` 폴백도 불가능하다**:
rescue 서브에이전트는 같은 플러그인(`codex/<ver>/agents/codex-rescue.md`)에
들어 있어 companion 이 없으면 그것도 없다. 이 경우 유일한 경로는 아래
watchdog 4항의 **로컬 적대 리뷰**다.)

네 가지가 중요하다:

1. **read-only 로 유지.** `--write` 를 붙이지 않고, 프롬프트에도 평이한 말로
   *"Review and critique only. Do not edit, create, or delete any files."* 라고
   말한다. 그래야 codex 가 당신 작업 트리 밖에 머문다.
1-a. **마스킹 (송신 전 필수) — codex 는 외부 모델이다.** 프롬프트에 실리는 플랜·
   diff·repo-context 에 secret·credential·내부 호스트·PII·고객 데이터를 넣지
   않는다 — 경로·계약 형태·standing 결정 요약만 싣는다. 민감 레포면 승인된
   요약만 전달하거나 로컬 리뷰어로 전환한다. (`acceptance-criteria-gate` G3 의
   증거 첨부 마스킹과 같은 원리: 외부로 나간 것은 캐시·인덱싱돼 남는다.)
2. **codex 를 대상 파일 경로로 가리켜라** — 당신의 요약이 아니라 실제 문서/diff 를
   읽도록. cwd 는 repo 루트로 두면 codex 가 repo 의 `.codex/config.toml`
   (effort 등)을 로드하고 레포 실측 대조까지 한다 — 느려지지만 품질이 오른다.
3. **effort 게이트 (비용) — 프롬프트 산문이 아니라 `--effort` CLI 플래그로 건다.**
   프롬프트에 "medium reasoning effort" 라고 쓰는 것은 추론 예산을 바꾸지
   **않는다** — 플래그 미지정이면 `~/.codex/config.toml` 의
   `model_reasoning_effort` (이 머신 기준 `high`) 가 그대로 적용된다.
   - **기본 `--effort medium`** — 소·중형 대상 전부.
   - **`--effort high`** — 보안 surface·외부 호출자 계약 변경·마이그 포함·6+ 파일만.
   실측(동일 프롬프트·동일 repo·동시 실행, 2026-07-28): high 473s vs medium 206s
   = **2.3×**. 툴콜은 high 6회 / medium 22회 — 시간차는 repo 대조가 아니라 추론
   토큰이다. 즉 cwd=repo(위 2항)는 비용 주범이 아니므로 유지한다.

## 프롬프트 골격 — verdict 계약은 공통, 공격 목록은 소비처가

codex 는 compact 한 XML-태그 operator 프롬프트에 가장 잘 응답한다. `<task>`(대상
경로 + read-only + "Do not route through skills or spawn subagents") ·
`<look_for>`(소비처 정의 — 플랜 공격 목록은 pipeline Phase 2, diff correctness
목록은 security.md §2) · `<grounding_rules>` · `<structured_output_contract>` 로
구성한다. 뒤의 둘은 공통:

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

## verdict 파싱 — fail-closed

계약은 fenced json 블록 **정확히 1개**다. 0개·2개 이상·파싱 실패·`issues` 배열
부재는 전부 **계약 위반 → 발견 미확보**: 같은 프롬프트로 verdict 만 재요청하고
(1회), 재요청도 실패하면 로컬 폴백으로 넘어간다. **복수 블록에서 "마지막 것을
취하는" 추측 복구를 하지 않는다** — 어느 블록이 최종인지 모르는 채 고르면 조용히
틀린 verdict 를 채택한다. 파싱 실패를 "이슈 0건"으로 읽는 것이 가장 위험한
오독이다(실측: 추출 정규식 결함으로 정상 verdict 를 "미검출"로 오판한 사례).

## triage 원장 — 발견은 재리뷰가 아니라 증거로 닫는다

verdict 의 **모든 issue id** 에 대해 원장 한 줄씩 작성한다(scratchpad 또는 리뷰
기록 섹션). 닫힘 판정자는 codex 재호출이 아니라 **당신의 직접 검증**이다:

```
| id | 판정 | 근거 |
| B1 | FIXED | plan §3 재작성 / <test-file> red→green — <무엇을 어떻게> |
| B2 | REJECTED | <grep/build/재현 증거로 반박> |
| B3 | DEFERRED | <정당 사유 + 행선지 — 후속 이슈 URL/plan 후속 섹션> |
```

- **high 는 FIXED 또는 증거 있는 REJECTED 만** — defer 불가. 미해소 high 를 들고
  다음 단계로 진행하지 않는다.
- **REJECTED 는 반드시 직접 검증 증거(grep/build/재현)를 동반한다** — 증거 없는
  reject 금지. codex verdict 를 그대로 믿지 않는 독립 재검증이 이 원장 작성 행위
  자체다(codex/폴백의 verdict 는 **권고**다).
- **DEFERRED 는 med/low 전용** — 사유와 행선지(후속 이슈·plan 섹션)를 반드시
  명명. 행선지 없는 defer 는 조용한 무시와 같다.

종료 후 결과를 대상 문서에 기록(플랜이면 `## Codex review — 1-pass: <발견 수 +
원장 요약>`, diff 리뷰면 Phase 4 리포트에).

## 시간 가드 — watchdog (필수)

codex 호출은 hang 할 수 있고(실측 ~39분 — companion 에는 턴 타임아웃이 없다),
동시에 **정당하게 느릴 수도 있다**(실측: 정상 high 런 473s — 툴콜 사이 추론
무음이 수 분간 이어진다). 고정 cap 은 정상 실행을 죽이므로 **진행 기반 hang
판정**으로 글로벌 `delegated-review-watchdog` 규칙을 구현한다 — 단 임계값은
아래 실측치가 우선:

1. **호출 자체를 Bash `run_in_background` 로 띄운다 — 그러면 대기 로직이
   필요 없다.** 잡이 끝나면 하니스가 완료 알림을 보낸다. 포그라운드 무한 대기
   금지, 짧은 sleep 폴링 반복도 금지 — 폴 1회가 메인루프 턴 1회다.
   hang 감시는 **별도의 background until-loop 하나**로 붙인다 — stderr 가
   8분간 커지지 않으면 exit 해서 알림을 띄우는 워처:

   ```bash
   # codex 잡과 함께, 같은 TAG 로 띄운다.
   # 정상/실패 종료면 마커가 생겨 워처도 같이 빠진다 — 남는 건 STALL 뿐.
   until [ -f "$OUT/$TAG-done.txt" ] || [ -f "$OUT/$TAG-failed.txt" ] || \
         [ $(( $(date +%s) - $(stat -f %m "$OUT/$TAG-err.txt") )) -ge 480 ]; do
     sleep 20
   done
   if   [ -f "$OUT/$TAG-done.txt"   ]; then echo OK
   elif [ -f "$OUT/$TAG-failed.txt" ]; then echo FAILED   # node 자체 실패 — 폴백
   else echo STALL; fi                                    # 무진행 8분 — kill 대상
   ```

   워처가 `STALL` 을 내면 **거기서 끝이 아니다** — 잡을 실제로 kill 하고
   (`TaskStop` 또는 잡 PID), 아래 3항으로 부분 결과를 회수한 뒤 4항 폴백으로
   넘어간다. `FAILED` 는 kill 없이 곧장 3~4항.

   (`Monitor` 는 쓰지 않는다 — 알림이 **1회**뿐인 대기에는 background Bash 가
   맞는 도구다. Monitor 는 발생마다 반복 알림이 필요할 때용이고, 무한 명령을
   걸면 조건 충족 후에도 타임아웃까지 armed 로 남는다.)
2. **진행 기반 판정 (경과시간 감각 금지 — 파일과 `date +%s` 로만).**
   - stderr 에 새 진행 줄(`[codex] Running command` / `Assistant message
     captured` / `Turn started`)이 계속 붙고 있으면 → hang 아님. **hard cap
     12분**까지 연장 허용.
   - 마지막 진행 줄 이후 **8분+ 새 줄 없음** → hang 판정, 즉시 kill.
   - hard cap 12분 도달 → 진행 여부 무관 kill (기본 effort=medium 실측 206s
     기준 상한. 효용 체감 + 지연 상한).
3. **kill 후 부분 결과 회수 — 건너뛰지 마라.** stderr 의
   `[codex] Assistant message captured:` 줄들이 부분 발견이다(truncate 되어
   있지만 BLOCKING 항목의 존재와 방향은 읽힌다). 이것을 fallback 리뷰의 입력
   힌트로 넘긴다.
4. kill/실패/미설치 후 **로컬 적대 리뷰**(adversarial reviewer 역할 subagent)로
   fallback — 리뷰 단계를 통째로 건너뛰지 않는다. fallback 리뷰에도 같은
   verdict JSON 계약과 원장 규칙을 적용하고, 폴백 사실을 보고에 명시한다.

## Anti-patterns

- 리뷰 중 codex 가 파일을 편집하게 두기 (read-only 줄을 잊음).
- 각 항목을 원장으로 닫는 대신 codex 출력을 그대로 문서에 붙여넣기.
- 증거 없는 REJECTED — codex 지적을 "판단상 아님"으로 기각. 원장의 근거
  칸이 비면 그 reject 는 무효다.
- 미해소 high 를 DEFERRED 로 밀거나 들고 다음 단계 진입.
- effort 를 프롬프트 산문으로 "지정" — `--effort` 플래그 없으면 config 의
  `high` 가 그대로 적용된다(2.3× 비용). 게이트는 플래그다.
- verdict JSON 없이 산문만 보고 발견 유무를 "느낌으로" 판정.
- 수렴 핑퐁 재도입(`--resume-last` 라운드 관리·재리뷰 요청) — 은퇴된 구조다.
  발견은 원장의 직접 검증 증거로 닫지, codex 의 재승인으로 닫지 않는다.
- 짧은 간격 sleep 폴링으로 대기 — 폴 1회 = 메인루프 턴 1회라 codex 를
  기다리는 시간보다 폴링이 더 비싸진다. 잡을 `run_in_background` 로 띄우고
  완료 알림을 받을 것.
- 알림 1회짜리 대기에 `Monitor` 를 씀 — 무한 명령이면 조건 충족 후에도
  타임아웃까지 armed 로 남는다.
- 모든 med/low nit 을 필수로 취급 → 요청하지 않은 scope creep.
