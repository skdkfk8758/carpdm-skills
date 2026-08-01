---
id: yagni-core
name: yagni-core
description: 편집 핵심 원칙 — YAGNI(데드코드 즉시 삭제) + 진단 규율(코드 확인 전 단언 금지)
category: editing
priority: critical
applies_to: [code, doc]
tracks: [T1, T2, T3]
hooks: [Stop]
related: [yagni-in-design-docs, skill-first-workflow, karpathy-core]
overrides: []
---

# Editing Core — YAGNI + Diagnostic Discipline

본 룰은 글로벌 `~/.claude/CLAUDE.md` 의 "Editing rules" 섹션 두 단락(YAGNI + 진단)을 별도 파일로 분리한 것. 본문 동일.

## YAGNI — 데드코드 즉시 삭제

IMPORTANT: 호출처가 사라진 코드/타입/테스트는 **그 자리에서 삭제**. 기능 전환/리팩터 시 옛 경로는 **같은 커밋**에서 제거. SPEC/PLAN/Acceptance 산출물은 YAGNI 섹션 의무.

문서 단계 강제(SPEC/PLAN "삭제 대상" 섹션 의무): [`~/.claude/rules-ondemand/yagni-in-design-docs.md`](../rules-ondemand/yagni-in-design-docs.md).

### 적용 시점

- 코드 편집 중 — 호출되지 않는 함수/타입 발견 시 즉시 삭제 후보
- 기능 전환·리팩터링 시 — 옛 경로는 같은 커밋에서 제거 (별도 PR 금지)
- SPEC/PLAN 작성 시 — "삭제 대상" 섹션 필수 (`yagni-in-design-docs.md` 참조)

### Anti-patterns

- "이번엔 추가만 하고 다음 PR 에서 정리하겠다" — 다음 PR 은 오지 않는다
- `@deprecated` 만 달고 본 SPEC 에서 삭제 task 미정의

## 진단 — 코드 확인 전 단언 금지

IMPORTANT: 라이브러리/경로/구현을 언급하기 전에 **반드시 Read 또는 Grep**으로 실제 소스를 확인한다. 이름이나 메모리 snapshot만으로 추론 금지. 에러 메시지는 해당 라이브러리 고유 어휘로 식별한다. 불확실하면 "추측" 또는 "확인 필요"라고 명시하고, 단언하지 않는다.

### 적용 시점

- 사용자 질문에 답하기 전 — 파일/함수/경로 언급 시 Read/Grep 선행
- 에러 진단 시 — 메모리/추측 금지, 실제 메시지·스택 확인
- 라이브러리·도구 동작 설명 시 — 공식 문서 또는 코드 확인

### 예외

- 일반 프로그래밍 개념 — 검색 불필요
- 사용자가 명시적으로 "추측해도 됨" 한 경우

## Related

- `~/.claude/rules-ondemand/yagni-in-design-docs.md` — SPEC/PLAN 단계 강제 (문서 시점 짝)
- `~/.claude/rules/skill-first-workflow.md` — 편집 전 스킬 호출 의무
- `~/.claude/rules/karpathy-core.md` — 4행동 원칙 (본 룰의 상위, 원칙 2·3 적용)
