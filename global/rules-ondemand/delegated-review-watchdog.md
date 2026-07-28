# Delegated Review Watchdog — 위임 리뷰에 시간 가드

IMPORTANT: codex·클라우드 팀모드 등 **위임(delegated) 리뷰**는 hang 하거나 false verdict 를 낸다(실측: codex 적대 리뷰가 최종 포맷 단계에서 ~39분 hang → 수동 취소). 위임 리뷰 결과는 **권고(advisory)** 로 다루고, 시간 가드와 독립 재검증을 항상 건다.

## 규칙

위임 리뷰를 호출할 때 4요소를 모두 적용한다:

1. **Background + 감시.** 위임 호출을 background 로 돌리고 `Monitor` 로 진행을 본다 — 포그라운드로 무한 대기하지 않는다.
2. **진행 기반 cap.** 진행 신호(로그 스트림 새 줄 등)가 살아 있으면 hard cap **12분**까지 연장, 마지막 진행 후 **8분+** 무소식이면 hang 으로 간주하고 **kill** 한다(부분 결과가 있으면 회수 — codex companion 은 stderr 스트림에 부분 발견이 남는다). 진행 신호를 관측할 수 없는 위임 작업은 종전대로 10분 고정 cap.
   - **임계를 조이면 정상 실행이 죽는다 (실측 2026-07-28).** 종전 3분/20분 조합에서 hang 판정 2건(474s·311s 무진행)이 났는데, 같은 조건의 *정상* codex 리뷰 1회가 473s(툴콜 6회 — 툴콜 사이 추론 무음이 수 분)였다. 즉 그 kill 들은 hang 이 아니라 오판이었을 가능성이 높고, kill 후 로컬 fallback 재실행까지 물려 해당 phase 가 33·45분으로 불었다. **오판 비용 > hang 방치 비용**이므로 무진행 임계는 넉넉히, hard cap 은 짧게 잡는다.
   - 위임 대상의 실측 소요를 아는 경우 그 값이 우선한다 — craft Phase 2 는 `codex-review.md` 의 임계가 SSOT.
3. **Local fallback.** kill 후 로컬 multi-agent 리뷰로 대체해 리뷰 자체를 빠뜨리지 않는다.
4. **독립 재검증.** 위임이든 fallback 이든 verdict 를 그대로 신뢰하지 않는다 — 핵심 발견은 직접 grep/build/재현으로 확인한 뒤 반영한다.

## 적용 시점

- craft Phase 2(codex 적대 plan 리뷰) — `craft-core/references/codex-review.md` 가 이 규칙을 구현한다.
- 임의의 장시간 위임 작업(외부 모델·클라우드 에이전트)에 일반 적용.

## Anti-patterns

- 위임 리뷰를 포그라운드로 띄우고 무한 대기 — 39분을 통째로 날린다.
- 위임 verdict 를 재검증 없이 그대로 플랜/코드에 반영(false verdict 전파).
- hang 인데 cap 없이 "곧 끝나겠지" 로 계속 기다림.
- 반대 방향 — 무진행 임계를 몇 분으로 조여 정상 추론 구간을 hang 으로 오판 kill. 재실행 비용이 기다린 시간보다 크다.

## Related

- `~/.claude/skills/craft-core/references/codex-review.md` — craft Phase 2 구현부.
- `~/.claude/rules-ondemand/browser-verify-fallback.md` — 동형 규칙(브라우저 도구 2회 캡). 같은 fallback 원리(cap→fallback→독립재검증)의 브라우저 인스턴스.
