---
id: skill-first-workflow
name: skill-first-workflow
description: 비trivial 편집 전 적합 Skill/Agent 호출 의무 — ad-hoc 코딩 대신 파이프라인 경유
category: workflow
priority: high
applies_to: [code]
hooks: []
related: [karpathy-core, subagent-delegation]
overrides: []
---

# Skill-First Workflow — 편집 전 스킬 호출 의무

IMPORTANT: 비trivial 코드 작업은 즉흥 편집(ad-hoc) 대신 **적합한 Skill 또는 Agent 를 먼저 호출**한다. karpathy 원칙 1(Think Before Coding)의 워크플로 진입점 — 파이프라인이 요구사항·플랜·검증을 강제해 silent 한 막코딩을 차단한다.

> 이력: 본 규칙은 2026-04-29 ADMap 시절 `guard-skill-invocation` 훅과 함께 강제로 도입됐다가, lean harness 전환에서 훅·매핑이 정리됐다. 현재는 **advisory(사람·AI 규율)** — 강제 훅 없음. 매핑도 현행 스킬로 갱신됨(구 feature-start/bugfix-start/refactor-start 폐기).

## 1차 호출 매핑 (현행 스킬)

| 작업 | 스킬 |
|---|---|
| 신규 기능 빌드 | `forge` |
| 버그·회귀 수정 | `hunt` |
| 기존 기능 변경·개편 | `renew` |
| 요구사항 명확·순수 TDD만(파이프라인 없이) | `tdd` — 적대 리뷰/보안 페이즈 없는 red-green-refactor escape-hatch. forge/hunt/renew 의 풀 파이프라인 아님(그것들은 자체 TDD 페이즈 보유) |
| 플랜만(구현 X) | `deep-plan` / `deep-interview` |
| Linear 이슈 자동 실행 | `linear-goal` |
| 리팩토링(동작 불변) | 소형·변경분 정리는 `/simplify`(리뷰+적용), 대형 구조 개편은 `renew` — 후보 발굴은 `/ponytail-audit`·`/improve-codebase-architecture`(리포트만). 성공 기준 = 전후 테스트 green |
| 배포 준비 | `preflight`(10차원 종합 판정) → `fortify`(보안 5축 심화) **체인 순서** — 발견(blocker)은 hunt/renew 로 수정 후 재판정. 판정 스킬은 코드 무수정 |
| 그 외 모호 | 메인 판단 — 필요 시 `Plan`/`Explore` 위임 |

## Threshold — 언제 스킬을 경유하나

- **비trivial**: 3+ 파일 · 200+ LOC · 다중 도메인 · 재현/검증 루프 필요 → 스킬 경유.
- **trivial**: 오타·단일 줄·1~2 파일 동일 토픽 이어붙임 → 메인 직접(스킬 불요).
- 스킬 경유 후 그 스킬이 subagent 를 오케스트레이션. 위임 판단은 `subagent-delegation.md` — 2026-08-01 부로 수치 임계가 아닌 성격 기준(캡 기본)이라, 위 스킬 경유 threshold 와는 별개 경계다.

> 2026-08-02 추가 2행(리팩토링·배포 준비) 은퇴 조건: 분기 ablation 에서 오라우팅 재발이 없고 description 트리거 단독으로 충분하면 행 제거.

## 면제 경로 (스킬 불요)

문서·설정·메타 편집은 파이프라인 대상 아님: `docs/`, `.claude/`(rules·hooks·agents·skills), `memory/`·`MEMORY.md`, `settings.json`/`settings.local.json`, `CLAUDE.md`/`AGENTS.md`.

## Anti-patterns

- 비trivial 기능을 스킬 없이 즉흥 Edit/Write 연발 — 요구사항·플랜·검증 통째 생략.
- trivial 오타 수정에 forge 발동 — 과함(원칙 2 위반).
- 스킬 매핑을 구 이름(feature-start 등)으로 기억 — 현행은 forge/hunt/renew.

## Related

- `~/.claude/rules/karpathy-core.md` — 원칙 1(Think Before Coding) 상위. 본 룰이 그 워크플로 진입점.
- `~/.claude/rules/subagent-delegation.md` — 스킬 경유 후 위임 판단(성격 기준·캡 — 본 룰 threshold 와 별개).
