# probe 방법론 — real-env 트리거 측정

## 왜 real-env 인가 (skill-creator eval 과의 차이)

skill-creator 의 `run_eval.py` 는 대상 스킬 하나를 `.claude/commands/` 에 uuid 접미사로 **격리 주입**한 뒤 `claude -p` 로 트리거 여부를 본다. 격리라서:

- 실제 `~/.claude/skills/` 에 깔린 **형제 스킬들과의 경쟁**을 재현하지 못한다.
- 대상의 발화 여부만 보고, *어느 형제가 가로챘는지*는 모른다.
- name-collision 등 측정 artifact 로 **false 0/100** 이 난다(실측).

probe 는 정반대다 — 스킬을 **이미 설치된 그대로** 두고, query 에 반응해 *실제로 발화한 모든 스킬*을 캡처한다. 격리 주입도, 임시 command 파일도 없다(name-collision 원천 제거).

## 두 측정축

- **(a) 트리거 정확도** — should-trigger query 에서 대상 스킬이 발화한 비율. invalid run(아래) 제외.
- **(b) sibling 경쟁** — query 별 발화한 형제(대상 아님) 분포. 가로채기/오발화를 드러낸다.

## 발화 스킬 추출 규칙 (fixture 로 고정 — `test_parser.py`)

`claude -p --output-format stream-json` 의 `assistant` 이벤트(input 이 완성된 full 이벤트)에서 tool_use 를 읽는다:

- `Skill` tool → `input.skill` 이 곧 스킬명.
- `Read` tool → `input.file_path` 에서 `/skills/<name>/` 를 정규화해 스킬명. (스킬 경로가 아니면 트리거로 치지 않음)
- `Skill` 인데 skill 값이 없으면 `unknown_skill_events` 로 분리.

CLI 출력 스키마가 바뀌면 `test_parser.py` 가 **fixture 대비 실패**하므로, silent false score 가 아니라 테스트 실패로 드러난다.

## outcome 분류 (단일 "발화 스킬명"으로 뭉개지 않음)

| state | 의미 |
|---|---|
| `target_only` | 대상만 발화 |
| `target_plus_sibling` | 대상 + 형제 동시 발화 |
| `sibling_only` | 대상 미발화, 형제가 가로챔 |
| `none` | 아무 스킬도 발화 안 함 |
| `error` | claude -p 비정상 종료(인증/rate-limit 등) |
| `timeout` | 시간 초과 |
| `parse_error` | recognizable stream 이벤트 0 (스키마 드리프트 의심) |

`error`/`timeout`/`parse_error` 는 **invalid** — 정확도·sibling 집계에서 제외하고 별도 보고한다. 인프라 실패를 "미발화"로 세면 측정이 오염된다.

## artifact 진단 (정상 0점이 아니라 경고)

- 전 run 이 invalid → 인프라 실패, 점수 없음.
- parse_error 존재 → CLI 스키마 드리프트 의심.
- 유효한 should-trigger 가 전부 미발화 → description/collision 의심.
- 실행 시작·끝 설치 스킬 snapshot(이름+SKILL.md 해시)이 다르면 → 결과 INVALID.

## eval set 포맷

```json
[
  {"query": "사용자가 실제로 칠 법한 발화", "should_trigger": true, "target": "deep-interview"},
  {"query": "트리거되면 안 되는 발화", "should_trigger": false, "target": "deep-interview"}
]
```

`target` 은 item 별 지정, 없으면 `--target` 기본값. should-not-trigger query 는 형제 경쟁 측정의 핵심이다.

## 실행

```bash
python3 scripts/real_env_probe.py --eval-set evals.json --runs 3
python3 scripts/real_env_probe.py --eval-set evals.json --dry-run   # 예상 세션 수만
```

- `--runs` 다회로 변동(nondeterminism) 관찰. `--workers` 는 작게(비용·rate-limit).
- query 는 **untrusted prompt** 로 취급된다(도구·파일 접근 유발 가능) — harmless 임시 cwd 에서 실행, timeout 강제.

## 범위 밖 (재구현 금지)

description 자동개선, HTML 벤치마크 뷰어, train/test split 은 skill-creator 가 제공한다. probe 는 *real-env 측정*만 한다 — 개선은 그 도구나 수동으로.
