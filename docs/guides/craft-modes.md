# Craft 스킬 + 실행 모드 — 사용 가이드

craft 엔진(forge / hunt / renew)과 그 위의 두 실행 모드(linear /
orchestrated) 사용법. 영속 가이드 — 동작이 바뀌면 본 파일 갱신.

## 1. 작업타입 3스킬

"무슨 작업이냐"로 스킬이 갈린다. 트리거는 자연어 — 슬래시 없이도 발화된다.

| 스킬 | 언제 | 트리거 예 |
|---|---|---|
| **forge** | 없는 걸 **새로 만듦** | "X 추가해줘", "build me Y", "엔드포인트 만들어" |
| **renew** | 있는 걸 **바꿈/재설계** | "X 재설계", "이 플로우 갈아엎어", "modernize Y" |
| **hunt** | **버그 고침** | "X 깨졌어", "500 떠", "왜 null 나와" |

셋 다 같은 엔진 위에서 돈다: Socratic 인터뷰 → codex 적대리뷰 →
동적 워크플로 TDD → 보안검증 → wrap. **셋 모두** TDD와 보안검증 사이에
**Phase 3.5 simplify 검토 패스**(옵션·동작불변 — 변경된 diff에 `/simplify` 필요
여부를 검토하고 재사용/단순화/효율 정리, 테스트 green 유지)가 더 붙는다. 차이는
Phase 1에서 뭘 묻나 + Phase 3 TDD 시작점뿐. 엔진 SSOT:
`craft-core/references/pipeline.md`.

> 순수 리팩터("이 파일 정리", "helper로 추출", "DRY하게")는 더 이상 별도 작업타입
> 스킬이 아니다 — 변경 diff 정리는 빌드 후 Phase 3.5(`/simplify`)가 흡수하고,
> 동작이 바뀌는 재구조화는 `renew` 다.

## 2. 두 실행 모드 — 강도 선택

작업타입과 **직교한 축**. 같은 forge라도 두 강도로 돌 수 있다.

### linear (기본)
단일 세션이 전 페이즈 수행. **거의 모든 작업이 이거.** 평범하게 요청하면
자동 linear. 빌드 모델 opus.

### orchestrated (council) — 무거운 opt-in
멀티에이전트: 이름 붙은 designer + adversary가 설계를 토론 → Workflow TDD →
검증패널. SSOT: `craft-core/references/orchestrated.md`.

발동 방법 3가지:

**1) 키워드 (가장 간단)** — 요청 아무 데나 `[council]` 또는 `--council`:
```
"결제모듈 재설계해줘 [council]"
"refactor this UserService --council"
```

**2) 자연어 문구** (작업동사 + 강도 같이):
```
"결제모듈 재설계해줘 — 팀으로 설계하고 워크플로로 구현하는 방식으로"
"build the rate-limiter with the full council treatment"
"maximum rigor, spare no agents"
```

**3) 엔진이 알아서 제안 (auto-offer)** — 네가 council을 몰라도 됨. 리스크 신호를
흘리거나("이거 중요한데", "리스크 커서", "제대로 하고싶어", "불안해") 작업이
객관적으로 고위험(auth/결제/외부계약 변경/6+ 파일)이면, 엔진이 Phase 1 전에
**한 번** 묻는다 — "council로 갈까?". 무시/무응답이면 기본 linear.

⚠️ 키워드·문구 없이 강도만("council 소집해줘", 작업동사 X)이면 어느 스킬도 안 깰
수 있다 — `[council]`을 작업 요청에 붙이는 게 제일 확실하다.

## 3. orchestrated 페이즈별 동작

| Phase | 무엇 | 모델 |
|---|---|---|
| 0 | designer·adversary spawn (`Agent({name})` — 이름이 SendMessage 주소) | opus |
| 1+2 | **council 루프** — designer 인터뷰(메인 경유)→plan, adversary 공격, 수렴까지. 종료: 유저 승인 AND adversary blocking 없음(≤2R) | opus |
| 3 | **Workflow TDD** — plan을 atomic task 분할, red→green→refactor | **sonnet** |
| 3.5 | **simplify 검토 패스**(forge·renew·hunt, 옵션) — 변경 diff를 `/simplify`로 정리, 테스트 green 유지. designer는 idle-alive 유지 | **sonnet** |
| 4 | **검증패널** — QA/tester/security 병렬 fan-out + designer(이름으로 재개)가 원의도 대조 판정 → accept or Phase 3 재진입 | opus |
| 5 | 요약 (shutdown 없음 — 닫을 팀이 없다) | — |

핵심: Phase 3·3.5만 sonnet(test-pinned + 독립검증이라 충분), 판단 페이즈는 opus.

## 4. 언제 orchestrated 쓰나

- **써라**: 설계 리스크 큰 고위험 작업 — 결제·인증 재설계, 외부 계약 바뀌는
  대규모 변경. 적대적 설계검토 + 구현 후 의도대조가 토큰값을 하는 경우.
- **쓰지 마라**: 일상 작업 99%. 버튼 추가, 단순 버그, 작은 변경 → linear가
  훨씬 싸고 충분. orchestrated는 비싸다(영속 opus 2 + fan-out + loop-back).

## 5. 주의

- **정리 불필요** — designer/adversary는 각자 일이 끝나면 완료되고, 이름만 주소로
  남는다. shutdown 보내지 말 것(SendMessage 계약이 금지). 대신 **같은 이름 재spawn 금지** —
  최신이 이름을 가져가 Phase 1 설계 의도가 끊긴다.
- **재시작** — craft-core 변경은 신규 세션부터 반영된다.
- **codex:rescue 없으면** Phase 2 적대리뷰는 수동 폴백.

## Related
- `craft-core/references/pipeline.md` — 엔진 + Execution mode 분기 (SSOT)
- `craft-core/references/orchestrated.md` — orchestrated 토폴로지 (SSOT)
- `CLAUDE.md` §5 — 모드 아키텍처 노트
