---
name: sweep
description: Clean up accumulated project cruft — 시점 기록 문서(오래된 plan, 랜딩된 handoff, 대체된 report), 휘발성 로그(logs/qa, agent 로그), 고아/중복 문서, build/tmp 잔여물 — 을 scan → classify → propose → confirm → delete 파이프라인으로, git 히스토리를 안전망 삼아 정리한다. 유저가 forge/hunt/renew 를 거치며 쌓인 잔여 문서/로그/아티팩트를 명시적으로 정리/정돈/prune/sweep/비우기 요청할 때 사용 — "레거시 문서 정리해줘", "쌓인 로그/플랜 치워줘", "docs 청소해줘", "오래된 리포트 정리", "clean up old reports", "prune stale handoffs", "이 프로젝트 잡동사니 좀 치워줘" 같은 표현. 영속 knowledge sub-tree (adr / concepts / guides / reference), 모든 rule 과 코드, 아직 참조되는 것은 모두 보존한다. 프로젝트 문서/로그 컨벤션 밖의 일반 파일 삭제, 코드 재구조화/편집(forge/renew/hunt 사용), handoff 작성(handoff 사용) 에는 트리거하지 말 것.
---

# Sweep — 중요한 것은 하나도 잃지 않고 프로젝트 잡동사니 제거

`forge` / `hunt` / `renew` 를 거치는 프로젝트는 *시점 기록
아티팩트*를 쌓는다: 이미 랜딩된 plan, 작업이 출시된 handoff, agent 로그, `.bak`
파일, 대체된 report. 이것들이 쌓여 `grep` 을 흐리고, 레포가 절반쯤 아직 진행
중인 것처럼 읽히게 만든다. Sweep 은 그 레이어를 제거한다 — 그리고 **오직** 그
레이어만.

어려운 부분은 삭제가 아니라, 무엇을 삭제해도 안전한지 아는 것이다.
`knowledge-folders` 컨벤션이 이미 그 선을 그어 두었고, sweep 은 그 위에 지어졌다:
**영속 knowledge 는 남고, 시점 기록 아티팩트는 후보다.** 당신의 일은 그 경계를
신중히 적용하고, 모든 제거를 설명하고, 유저가 승인하지 않은 비가역 액션을 절대
취하지 않는 것이다.

## 안전 경계 — 스캔 전에 읽을 것

컨벤션은 `docs/` 를 두 sub-tree 로 나눈다. Sweep 은 둘을 반대로 다룬다.

| 계층 | 경로 | Sweep 입장 |
|---|---|---|
| **절대 건드리지 않음** | `rules/`, `AGENTS.md`, `CLAUDE.md`, `MEMORY.md`, `memory/`, `.git/`, source code, config, `docs/adr/`, `docs/concepts/`, `docs/guides/`, `docs/reference/`, `docs/_index/` | 영속 knowledge + 결정 + portal. 범위 밖, 완전히. |
| **후보** | `docs/plans/`, `docs/handoff/`, `docs/reports/`, `docs/reviews/`, `docs/runbooks/`, `docs/benchmarks/`, `docs/solutions/`, `docs/_archive/`, `logs/`, `*.bak-*`, `dist/`, `build/`, `tmp/`, `*.tmp`, 빈 디렉토리 | 시점 기록 / 휘발성. 대상 — 단 각각 사라지기 전에 *이유*가 필요하다. |

경로가 후보라는 것은 **필요조건이지 충분조건이 아니다**. 오늘 아침의 plan 도
후보 위치이지만 명백히 살아 있다. 폴더만 보고가 아니라 *staleness 의 증거*에
근거해 삭제한다.

프로젝트가 `knowledge-folders` 를 따르지 않으면(`docs/` 트리 없음) 같은 원칙으로
폴백하라: source, config, README, 그리고 git 추적되고 import 되는 것은 영속;
로그, `.bak`, `tmp`, build 출력은 후보다. 무언가가 knowledge 인지 아티팩트인지
불확실하면 **물어보라 — 추측해서 삭제하지 말 것.**

## 복구 계층 — 이것이 얼마나 신중할지를 좌우한다

후보 파일 둘은 매우 다른 리스크를 질 수 있다:

- **git 추적됨** → `git rm` 은 히스토리에서 복구 가능. 삭제 제안해도 안전.
- **추적 안 됨** (대부분의 로그, `tmp`, 갓 만든 `.bak`) → 한 번 `rm` 하면
  **사라진다**, git 안전망 없음. 각별히 다룰 것: `gitignore`-하고-남기기를
  선호하거나, 항목별 명시적 확인을 요구하고, "이건 복구할 수 없습니다"라고
  분명히 말할 것.

스캔 동안 항상 `git status` / `git ls-files` 를 실행해 각 후보의 계층을 알아둘 것.
그것 없이 삭제 제안을 절대 제시하지 말 것.

## 파이프라인

### 1. Scan
네 카테고리 전반에서 후보를 감지한다. 카테고리별 휴리스틱과 정확한 명령은
`references/detection.md` 참조. 각 히트마다 기록할 것: 경로, 카테고리, **왜
stale 해 보이는지**(증거), 복구 계층 (tracked / untracked).

### 2. Classify
히트를 카테고리별로 묶는다. 이미 보이는 false positive 는 떨군다(실은 살아 있는
spec 인 "plan", 몇 분 전 쓰인 로그, 유저가 방금 일부러 만든 `.bak`). staleness
증거가 약하면 삭제 제안 대신 "flagged, not proposed" 로 강등하라.

### 3. Propose — 항상 이 report 형태를 사용할 것
유저는 이 report 만 보고 결정하므로, 제거와 이유가 읽기 쉽게:

```
# Sweep proposal — <repo name>

## Summary
<N> candidates, <X> tracked (recoverable) / <Y> untracked (NOT recoverable).
Permanent knowledge & code untouched.

## Stale docs (point-in-time)
- docs/plans/2026-04-01-old-thing.md  [tracked]  — superseded by 2026-05 plan; work merged in <commit>
- docs/handoff/foo.md                 [tracked]  — referenced task shipped; handoff is stale per YAGNI

## Logs (volatile)
- logs/qa/                            [untracked, NOT recoverable] — 14 files, all > 7d (GC window)
- logs/agents/executor-*.log          [untracked, NOT recoverable] — 6 files

## Orphan / duplicate
- docs/_archive/empty/                [tracked]  — empty dir
- docs/reports/dup-of-X.md            [tracked]  — duplicate SSOT of docs/reports/X.md

## Build / tmp
- *.bak-1748* (3 files)               [untracked, NOT recoverable]
- tmp/                                [untracked, NOT recoverable]

## Excluded on purpose
<anything you flagged but did NOT propose, with the reason — so the user sees you considered it>
```

### 4. Confirm
세분성을 제공하라: **전체**, **카테고리별**, **파일별** 승인. untracked /
복구 불가 그룹은 *별도로 명시적으로* 확인하라 — 포괄적 "yes" 에 묻어가게 하지
말 것. 이것이 비가역 부분이다; 그렇게 취급하라.

### 5. Execute
- Tracked → `git rm <path>` (디렉토리는 `git rm -r`). 요청 없으면 commit 말고
  stage 만 — 유저가 staged 삭제를 리뷰하게 두라.
- Untracked → 4 단계에서 확인된 항목만 `rm`. 유저가 계속 쓰고 싶어 하는 휘발성
  디렉토리(예: `logs/`)는 디렉토리 자체를 삭제하기보다 `.gitignore` 추가를
  선호하라.
- 스캔이 명시적으로 나열하지 않은 경로를 절대 `rm -rf` 하지 말 것. proposal 에
  보인 것 너머의 globbing 금지.

### 6. Verify
`git status` 를 실행하고 최종 상태를 보고하라: 무엇이 제거됐고, 무엇이 staged 됐고,
무엇이 건너뛰어졌는지. `.gitignore` 항목을 추가했으면 보여줄 것. 유저가 직접
리뷰하고 commit 할 수 있는 상태로 레포를 남길 것 — commit 은 유저의
몫(외부/비가역)이지 sweep 의 것이 아니다.

## Sweep 이 아닌 것

- `git clean -fdx` 가 아니다 — 그건 무딘 도구이고 knowledge/아티팩트 경계를 무시한다.
- refactor 가 아니다 — 파일 *내용*을 절대 편집하지 않는다 (`forge`/`renew`/`hunt` 사용).
- memory 나 handoff 위생 로직이 아니다 — stale handoff 는 삭제하지만 작성하지는
  않는다 (`handoff` 사용).
- 자동이 아니다 — 스캔하고 제안할 뿐, 삭제는 항상 확인을 기다린다.
