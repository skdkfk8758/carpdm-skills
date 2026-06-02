# Craft 스킬 + 실행 모드 — 사용 가이드

craft 엔진(forge / hunt / renew / reshape)과 그 위의 두 실행 모드(linear /
orchestrated) 사용법. 영속 가이드 — 동작이 바뀌면 본 파일 갱신.

## 1. 작업타입 4스킬

"무슨 작업이냐"로 스킬이 갈린다. 트리거는 자연어 — 슬래시 없이도 발화된다.

| 스킬 | 언제 | 트리거 예 |
|---|---|---|
| **forge** | 없는 걸 **새로 만듦** | "X 추가해줘", "build me Y", "엔드포인트 만들어" |
| **renew** | 있는 걸 **바꿈/재설계** | "X 재설계", "이 플로우 갈아엎어", "modernize Y" |
| **hunt** | **버그 고침** | "X 깨졌어", "500 떠", "왜 null 나와" |
| **reshape** | **행동변경 없이 리팩터** | "이 파일 정리", "helper로 추출", "DRY하게" |

넷 다 같은 5단계 엔진 위에서 돈다: Socratic 인터뷰 → codex 적대리뷰 →
동적 워크플로 TDD → 보안검증 → wrap. 차이는 Phase 1에서 뭘 묻나 + Phase 3
TDD가 어디서 시작하나뿐. 엔진 SSOT: `craft-core/references/pipeline.md`.

## 2. 두 실행 모드 — 강도 선택

작업타입과 **직교한 축**. 같은 forge라도 두 강도로 돌 수 있다.

### linear (기본)
단일 세션이 전 페이즈 수행. **거의 모든 작업이 이거.** 평범하게 요청하면
자동 linear. 빌드 모델 opus.

### orchestrated (council) — 무거운 opt-in
멀티에이전트: 영속 designer + adversary가 설계를 토론 → Workflow TDD →
검증패널 → 팀 정리. **명시적으로 요청해야만** 발동.
SSOT: `craft-core/references/orchestrated.md`.

발동 문구 (작업동사 + 강도를 같이):

```
"결제모듈 재설계해줘 — 팀으로 설계하고 워크플로로 구현하는 방식으로"
"build the rate-limiter with the full council treatment"
"이 리팩터 council 소집해서 / maximum rigor, spare no agents"
```

⚠️ 작업동사 없이 강도만("council 소집해줘") 말하면 어느 스킬도 안 깰 수 있다 —
항상 "재설계/build/fix + council" 형태로.

## 3. orchestrated 페이즈별 동작

| Phase | 무엇 | 모델 |
|---|---|---|
| 0 | 팀 생성(TeamCreate) + designer·adversary spawn | opus |
| 1+2 | **council 루프** — designer 인터뷰(메인 경유)→plan, adversary 공격, 수렴까지. 종료: 유저 승인 AND adversary blocking 없음(≤2R) | opus |
| 3 | **Workflow TDD** — plan을 atomic task 분할, red→green→refactor | **sonnet** |
| 4 | **검증패널** — QA/tester/security 병렬 fan-out + 살아있는 designer가 원의도 대조 판정 → accept or Phase 3 재진입 | opus |
| 5 | 요약 + **팀 shutdown**(영속 agent 정리) | — |

핵심: Phase 3만 sonnet(test-pinned + 독립검증이라 충분), 판단 페이즈는 opus.

## 4. 언제 orchestrated 쓰나

- **써라**: 설계 리스크 큰 고위험 작업 — 결제·인증 재설계, 외부 계약 바뀌는
  대규모 변경. 적대적 설계검토 + 구현 후 의도대조가 토큰값을 하는 경우.
- **쓰지 마라**: 일상 작업 99%. 버튼 추가, 단순 버그, 작은 리팩터 → linear가
  훨씬 싸고 충분. orchestrated는 비싸다(영속 opus 2 + fan-out + loop-back).

## 5. 주의

- **팀 정리** — orchestrated 끝나면 designer/adversary가 idle로 살아있다.
  Phase 5 shutdown 필수(엔진이 처리하지만 중단 시 수동 확인).
- **재시작** — craft-core 변경은 신규 세션부터 반영된다.
- **codex:rescue 없으면** Phase 2 적대리뷰는 수동 폴백.

## Related
- `craft-core/references/pipeline.md` — 엔진 + Execution mode 분기 (SSOT)
- `craft-core/references/orchestrated.md` — orchestrated 토폴로지 (SSOT)
- `rules/project.md` §5 — 모드 아키텍처 노트
