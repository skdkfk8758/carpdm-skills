---
name: probe
description: 스킬의 트리거 description 이 실제 설치 환경(`~/.claude/skills/` 에 형제 스킬들이 함께 깔린 상태)에서 제대로 발화하는지 측정한다 — (a) 트리거 정확도와 (b) 어느 형제 스킬이 가로채는지(sibling 경쟁)를 함께 잡는다. skill-creator 의 격리-주입 eval 이 놓치는, 실제 경쟁 상황에서의 트리거 동작을 본다. 사용자가 스킬 트리거를 TEST/EVAL/측정하거나, 스킬이 제대로 발화하는지, 다른 스킬이 오발화(가로채기)하는지 확인하려 할 때 사용 — "이 스킬 트리거 제대로 되는지 측정해줘", "스킬 트리거 정확도 eval", "어느 스킬이 가로채는지 확인", "real-env 로 트리거 테스트", "sibling 스킬 경쟁 측정", "트리거 false 0/100 나오는데 실제로 확인", "/probe" 같은 표현. 새 스킬을 저작/생성(use summon)하거나, skill-creator 의 description 자동개선·합성 eval 을 돌리려 할 때는 트리거하지 말 것 — probe 는 *측정*만 하지 스킬을 만들거나 description 을 고치지 않는다.
---

# Probe — real-env 스킬 트리거 측정

스킬이 트리거되지 않는 진짜 이유는 description 이 나빠서가 아니라, **다른 형제 스킬이
먼저 가로채서**일 때가 많다. 합성(synthetic) eval 은 스킬 하나만 격리해 테스트하므로
이 경쟁을 못 본다 — 그래서 실제로는 멀쩡한데 false 0/100 이 나온다.

probe 는 스킬을 **이미 설치된 그대로** 두고, query 에 반응해 *실제로 발화한 모든
스킬*을 캡처한다. 두 가지를 동시에 측정한다:

- **(a) 트리거 정확도** — 대상 스킬이 should-trigger query 에서 발화한 비율.
- **(b) sibling 경쟁** — 어느 형제가 query 를 가로챘는가.

## 이것이 올바른 도구일 때

스킬의 트리거를 **측정/검증**하려 할 때. 특히 합성 eval 이 의심스러운 결과
(예: false 0/100)를 낼 때, 실제 설치 환경에서 무엇이 발화하는지 확인하는 용도.

형제 도구와의 경계:
- **vs `summon`** — summon 은 새 스킬/에이전트를 *저작*한다. probe 는 만들지 않고 *측정*만 한다.
- **vs skill-creator** — skill-creator 는 격리-주입 합성 eval + description 자동개선을 한다. probe 는 그게 못 보는 *real-env 경쟁*을 측정한다. 개선은 skill-creator 에, 측정은 probe 에.

## 작동 원리 (요약 — 자세히는 `references/methodology.md`)

각 query 를 `claude -p --output-format stream-json` 으로 실제 실행하고, `assistant`
이벤트의 tool_use 에서 발화 스킬을 추출한다(`Skill.input.skill`, `Read` 의 file_path
에서 `/skills/<name>/` 정규화). 발화한 *모든* 스킬을 모아 대상/형제로 분류한다.

핵심 안전장치:
- **outcome 분류** — `target_only` / `target_plus_sibling` / `sibling_only` / `none`
  / `error` / `timeout` / `parse_error`. 인프라 실패(error/timeout/parse)는 invalid 로
  정확도에서 제외 — "미발화"로 뭉개지 않는다.
- **artifact 진단** — recognizable 이벤트 0(스키마 드리프트), 전부 미발화 의심,
  설치 스킬 snapshot 드리프트를 정상 0점이 아니라 *경고*로 emit.
- **파서 계약 고정** — `scripts/test_parser.py` 가 저장된 raw stream fixture 로
  파서를 검증한다. CLI 출력 스키마가 바뀌면 silent false 가 아니라 테스트 실패로 드러난다.

## 사용법

1. eval set 작성(JSON). should-trigger 와 should-not-trigger 를 섞는다 — 후자가
   형제 경쟁 측정의 핵심이다:
   ```json
   [
     {"query": "사용자가 실제로 칠 발화", "should_trigger": true, "target": "<스킬명>"},
     {"query": "트리거되면 안 되는 발화", "should_trigger": false, "target": "<스킬명>"}
   ]
   ```
2. 먼저 dry-run 으로 비용(세션 수) 확인:
   ```bash
   python3 scripts/real_env_probe.py --eval-set evals.json --dry-run
   ```
3. 실행(`--runs` 다회로 변동 관찰, `--workers` 는 작게):
   ```bash
   python3 scripts/real_env_probe.py --eval-set evals.json --runs 3
   ```
4. 결과 JSON 의 `summary.trigger_accuracy`, `summary.sibling_competition`,
   `artifacts`, `env_drift` 를 읽는다. `artifacts` 가 비어있지 않으면 점수를 믿지 말고
   원인부터 본다.

검증: `python3 scripts/test_parser.py` (파서 단위 테스트 — claude 호출 없이 빠름).

## Anti-patterns

- **합성 eval 의 0/100 을 그대로 믿기** — probe 의 존재 이유가 그 artifact 를 잡는 것.
- **should-not-trigger query 생략** — 그러면 (b) sibling 경쟁을 측정할 수 없다.
- **`artifacts`/`env_drift` 무시하고 점수만 읽기** — invalid run 을 정상 점수로 오인한다.
- **probe 로 스킬을 고치려 하기** — probe 는 측정 도구다. 개선은 skill-creator/summon.
- **거대한 eval set 을 무계획 실행** — query×runs 만큼 실제 claude 세션이 돈다. dry-run 으로 비용 먼저.
