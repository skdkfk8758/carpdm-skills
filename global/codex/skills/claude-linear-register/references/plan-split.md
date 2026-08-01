# Plan 분할 모드 — plan/spec/PRD → tracer-bullet vertical slice 이슈들 (SSOT)

> 입력이 **다단계 plan/spec/PRD 문서**(deep-plan 산출, 설계 문서, PRD)일 때
> linear-register 가 이 모드로 진입한다. 구 분할 전용 스킬(2026-07-21 흡수)의 이관본 —
> 단건 경로와 같은 코어 헤딩 계약·팀 라우팅·확인 게이트·Backlog 기본을 공유하고, 분할
> 규칙만 다르다.

## 1. 입력 수집

대화 컨텍스트에 있는 것부터 쓴다. 사용자가 이슈 참조(번호·URL·경로)를 넘기면
Linear 에서 본문+코멘트를 fetch 해 읽는다. plan 문서 경로면 Read.

## 2. 코드베이스 탐색 (선택)

아직 탐색 전이면 현재 상태를 파악한다. 이슈 제목·본문은 프로젝트 도메인 용어집
어휘를 쓰고, 건드리는 영역의 ADR 을 존중한다.

## 3. Vertical slice 초안

plan 을 **tracer bullet** 이슈들로 쪼갠다. 각 이슈는 한 레이어의 수평 슬라이스가
아니라 **모든 통합 레이어를 end-to-end 로 관통하는 얇은 수직 슬라이스**다.

슬라이스는 'HITL' 또는 'AFK':
- **HITL** — 사람 개입 필요 (아키텍처 결정, 디자인 리뷰).
- **AFK** — 사람 개입 없이 구현·머지 가능. 가능하면 AFK 를 우선.

<vertical-slice-rules>
- 각 슬라이스는 좁지만 모든 레이어(schema, API, UI, tests)를 관통하는 COMPLETE 경로
- 완료된 슬라이스는 단독으로 demo 또는 검증 가능
- 두꺼운 소수보다 얇은 다수를 선호
</vertical-slice-rules>

## 4. 분해 프리뷰 quiz

제안 분해를 번호 목록으로 제시. 슬라이스마다:

- **Title**: 짧은 서술명
- **Type**: HITL / AFK
- **Blocked by**: 선행 슬라이스 (있으면)
- **User stories covered**: 커버하는 user story (원문에 있으면)

사용자에게 확인: granularity 적절한가(너무 굵음/가늚)? 의존 관계 맞나? 병합/추가
분할할 슬라이스는? HITL/AFK 마킹 맞나? — 승인까지 반복.

이 quiz 가 곧 이 모드의 **확인 게이트 1부**다. 승인 후 SKILL.md Step 2.5(dedup/
그루핑) → Step 3(등록 게이트: 팀/프로젝트/state 확정)로 이어진다.

## 5. 의존순 발행

승인된 슬라이스마다 이슈를 발행한다. **blocker 먼저**(의존순) — "Blocked by" 에
실제 issue identifier 를 참조할 수 있게. 관계는 `save_issue` 의
`blocks`/`blockedBy`/`parentId` 로 네이티브 세팅. **전건 기본 `state: "Backlog"`**
(SKILL.md Step 4 와 동일 — 미활성 팀 폴백 + 변경 사유 포함).

본문 템플릿 = **SKILL.md 통합 템플릿 그대로**. 이 모드 전용 확장 헤딩은 없다 —
부모·의존은 본문 헤딩이 아니라 **Linear 네이티브 관계**(`parentId`/`blockedBy`)로만
표현한다(구 `## Parent`/`## Blocked by` 는 같은 정보의 본문 중복이었다):

```markdown
## 작업 내용
<이 vertical slice 의 end-to-end 동작 — 3줄 이내, 레이어별 구현 서술 금지.>

## 수용 기준
- [ ] [AUTO] <기계 검증 — 테스트/타입체크/관찰 가능 동작>
- [ ] [HUMAN] <사람 검증 — 시각 확인/운영 apply>

## 범위 밖              ← 이 슬라이스가 안 하는 것 (다음 슬라이스 몫)
- <경계>

## 추천
<recommend-section.md §A 로 생성 — 권장 스킬 1줄 + 시작 프롬프트 코드블록>

## 다음 작업           ← 이 슬라이스가 blocks 하는 다음 슬라이스가 있을 때
<recommend-section.md §B>

> Plan-reviewed: <조건부 — 아래 마커 규칙>
> AI 가 등록·작성
```

슬라이스는 서로 의존하므로 `## 범위 밖` 이 특히 값을 한다 — "이건 다음 슬라이스 몫"을
적어두면 worker 가 범위를 넘지 않는다. 결정 인코딩 스니펫(state machine·schema·type
shape)이 꼭 필요하면 **fenced 코드블록**에 넣는다 — 코드블록은 자수 상한 carve-out 이다.

**`Plan-reviewed:` 마커 (조건부 의무).** 원본 plan `.md` 에 `## Plan review`
섹션(레거시 헤딩 `## Codex review` 도 인식)이 실존하면 각 이슈에 마커 한 줄을
넣는다 — 규격·소비처는
`~/.claude/skills/craft-core/references/linear.md` §2a 가 SSOT(복제 금지).
빌드 파이프라인 Phase 2 가 이 마커로 플랜 재리뷰를 스킵한다. verdict 섹션이
없는 plan 이면 마커 줄 자체를 생략(거짓 마커 금지).

부모/원본 이슈를 close 하거나 수정하지 않는다.

## Anti-patterns

- 레이어별 수평 분할 ("DB 이슈, API 이슈, UI 이슈") — tracer bullet 위반.
- quiz 생략하고 바로 발행 — 확인 게이트 위반.
- blocker 보다 피blocker 를 먼저 발행 — Blocked by 에 실 ID 참조 불가.
