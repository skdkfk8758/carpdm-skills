---
id: yagni-in-design-docs
name: yagni-in-design-docs
description: SPEC/PLAN/Acceptance 산출물의 YAGNI 강제 — "삭제 대상" 섹션 의무
category: editing
priority: high
applies_to: [doc]
hooks: []
related: [yagni-core, karpathy-core]
overrides: []
---

# YAGNI in Design Docs — 설계 문서의 삭제 대상 명문화

IMPORTANT: SPEC/PLAN/Acceptance 등 설계 산출물은 **"삭제 대상"(YAGNI) 섹션을 의무**로 둔다. 무엇을 추가하는지만 적고 무엇을 제거하는지 안 적으면, 기능 전환의 옛 경로가 "다음 PR"로 미뤄져 영영 남는다. `yagni-core.md`(코드 편집 시점 YAGNI)의 **문서 시점 짝** — 삭제를 코드가 아니라 계획 단계에서 먼저 잠근다.

> 이력: 본 규칙의 강제는 과거 Stop 훅으로 구현됐으나 lean harness 전환에서 정리됐다. 현재는 **advisory(사람·AI 규율)** — 강제 훅 없음.

## 규칙

### 삭제 대상 섹션 의무

- SPEC/PLAN/Acceptance 작성 시 `## YAGNI / 삭제 대상` 섹션을 반드시 포함한다.
- 그 섹션에 **이 작업으로 호출처가 사라지는 코드/타입/테스트/문서**를 명시한다. 없으면 "제거할 기존 경로 없음(사유)"이라고 명시적으로 적는다 — 빈칸·누락 금지.
- 기능 전환/개편이면 옛 경로 제거를 **같은 작업 단위(같은 커밋/PR)** task 로 넣는다. 별도 PR 로 미루지 않는다.

### 형식 (예)

```markdown
## YAGNI / 삭제 대상
- `lib/old-sso.ts` + `OLD_*` env — 신 경로로 대체, 같은 PR 에서 제거.
- (제거할 기존 경로 없음: 신규 추가만, 기존과 공존·중복 아님.)
```

## Anti-patterns

- 설계 문서에 추가 task 만 나열, 삭제 task 부재 — 데드코드 누적의 시작점.
- `@deprecated` 만 달고 삭제 task 미정의 — 다음 PR 은 오지 않는다.
- "삭제 대상" 섹션을 빈칸으로 두거나 통째 생략.

## Related

- `~/.claude/rules/yagni-core.md` — 코드 편집 시점 YAGNI(본 룰의 상위·짝).
- `~/.claude/rules/karpathy-core.md` — 원칙 3(Surgical) · 원칙 2(Simplicity).
- `~/.claude/rules/acceptance-criteria-gate.md` — Acceptance 산출물 게이트(동형 완료 규율).
