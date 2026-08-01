---
id: subagent-delegation
name: subagent-delegation
description: subagent 위임 시점 결정 — 언제 위임할 것인가 (호출 방법은 subagent-invocation)
category: workflow
priority: high
applies_to: [agent-call]
tracks: [T2, T3]
hooks: []
related: [subagent-invocation, agent-pipeline-tracks]
overrides: []
---

# Subagent Delegation

IMPORTANT: 위임은 **캡(cap)이 기본**이다 — 장려가 아니다. Claude 5 계열(Opus 5 포함)은
위임 성향이 이미 강하고, complete-spec 을 주고 단일 실행으로 맡길 때 최고 성능을
낸다(플랫폼 프롬프팅 문서, 2026-08-01 개정). 이 룰의 역할은 "언제 위임하라"가 아니라
"언제 위임하지 마라"다. 종전 "3+ 파일이면 위임" 수치 의무는 폐기 — Claude 5 이전
캘리브레이션이다.

## When to Delegate

위임은 **독립적이고 병렬 가능한 대형 트랙**에만:

- 광범위 multi-file 조사처럼 진짜 분리 가능한 작업
- 전문 컨텍스트 격리가 목적인 작업 (보안 감사, 적대 리뷰의 역할 분리 등)
- 파일 수·LOC 는 보조 신호일 뿐 임계가 아니다

## When NOT to Delegate (캡)

- 몇 번의 tool call 로 직접 끝낼 수 있는 작업
- 자기 작업 검증/더블체크용 subagent — 모델이 자가검증을 기본 수행하므로 이중 비용.
  **예외**: *독립 컨텍스트가 목적*인 검증(구현자 주장을 신뢰하지 않는 verify 스테이지,
  adversarial 리뷰의 역할 분리)은 더블체크가 아니라 역할 분리 — 유지.
- 1개로 되면 1개 — spawn 수 최소 유지

## How to Delegate

1. Define a clear, scoped task with expected output
2. Include all necessary context in the prompt
3. Review subagent output before integrating
4. Use parallel delegation for independent subtasks

## Anti-Patterns

- Do NOT delegate trivial tasks (typo fixes, single-line changes)
- Do NOT chain more than 3 subagents sequentially
- Do NOT delegate without sufficient context
- 수치 임계("3+ 파일")를 위임 *의무*로 복원 — Claude 5 이전 캘리브레이션

## 재검토 조건 (룰 수명)

- 분기 ablation 스윕에서 과잉위임(불필요 spawn 누적) 또는 과소위임(단일 세션
  truncation/품질 저하) 재발 관측 시 기준 재조정.
- 세션 주력 모델이 Claude 5 미만으로 내려가면 종전 수치 임계 복원 검토(git history).

## Large File Read

IMPORTANT: 단일 파일 > 1000 lines Read 시 의도별 분기.

| Intent | 행동 |
|---|---|
| 편집 (수정/리팩터/추가/삭제) | 메인 직접 Read — exact lines 필요 (karpathy 원칙 3) |
| 탐색 (이해/요약/구조 파악) | `Explore` 또는 `caveman:cavecrew-investigator` 위임 |
| 모호 | 메인 Read + 첫 N lines 만, 필요 시 subagent 후속 |

### Threshold

- 기본: `GUARD_LARGE_FILE_LINES=1000`
- 면제 경로: `docs/`, `CLAUDE.md`, `AGENTS.md`, `MEMORY.md`, `.claude/`, `~/.claude/`, `package-lock.json`, `pnpm-lock.yaml`, `*.lock`, `*.snap`, `*.min.js`, `dist/`, `build/`

### 작성 제약과 구분

`guard-file-size` 훅 (300줄) = **작성** 경고. 본 룰 (1000줄) = **읽기** 분기. 별개 정책.

### Anti-patterns (large file read)

- 큰 파일 전체 Read 후 일부만 사용 (컨텍스트 낭비)
- 편집 의도인데 subagent 요약만 보고 Edit — exact line 없으면 lossy
- 임계값 직전 파일 (999 lines) 반복 Read — 분할 또는 subagent 고려

### Enforcement (Phase 1)

- `~/.claude/hooks/guards/guard-large-file-read.sh` — PreToolUse:Read stderr nudge (비차단)
- 로그: `~/.claude/logs/large-file-read.jsonl`
- 분석: `~/.claude/scripts/analyze-large-file-read.sh`
- Override: `GUARD_LARGE_FILE_DISABLE=1` / `GUARD_LARGE_FILE_LINES=N` / `GUARD_LARGE_FILE_NUDGE_CAP=N`
- Phase 2 결정 (≈ 2026-06-26): 발화율·intent 분포·subagent 후속 호출률 기반 tune/폐기. **차단 훅 영구 금지**.
