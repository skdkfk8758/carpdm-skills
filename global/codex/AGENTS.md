# Shared Codex guidance

Use this file and `/Users/carpdm/.codex/response-format.md` as the Codex instruction sources. Preserve explicit scope, repository instructions, shared-workspace changes, and applicable mandatory checks.

## Model routing

기본 세션 모델은 `gpt-5.6-sol`(medium)이다. 인터뷰·설계·ADR 결정이 주가 되는 세션만 사용자가 `-p astra` 로 열며, Astra 세션은 구현하지 않고 워커에 위임한다(`hooks/astra-gate/gate.py` 가 차단).

| 일의 성격 | 워커 | 모델 |
|---|---|---|
| 단순 스텝 — 파일 3개 이하 · 설정값·문구·한 함수 수정 | 메인이 직접 | 세션 모델 |
| 읽기 전용 탐색·grep·조회 | `explorer` | luna |
| 외부 라이브러리·문서 조사 | `librarian` | luna |
| 단순 변경을 위임해야 할 때(Astra 세션·병렬) | spawn_agent | terra |
| 복잡 구현 — 파일 4개 이상 · 인터페이스/의존성 변경 · 인증/gitops/마이그레이션/삭제 | spawn_agent | sol |
| 관점 리뷰·리서치 — Karpathy·Torvalds·Pocock(리뷰) · Hightower·Abramov(리서치) | `persona-*` | terra |

**단순 = 세 조건 전부**: 파일 3개 이하 · 인터페이스/데이터 모델/의존성 무변경 · 인증/gitops/마이그레이션/삭제 아님. 하나라도 어기면 복잡이다.
모든 spawn 은 `model`·`reasoning_effort`·`fork_turns="none"` 을 명시한다. 동시 2개·요청당 누적 3개·`max_depth=2` 를 넘지 않는다.

## 짧은 호흡

복수 스텝 작업은 착수 전 3~7 스텝 계획(스텝당 파일 ≤3·커밋 1)을 제시하고 승인받은 뒤 스텝 1만 실행한다. 스텝 끝 = 보고 + `다음 스텝` 1줄 + 확인 질문. 설계 결정이 나오면 먼저 ADR(`docs/adr/` 또는 프로젝트가 정한 경로)에 적고 그것을 목표로 삼는다. 상세 규율은 `~/.claude/rules-ondemand/step-cadence.md` 와 같다.

## 실패·승인

실행 작업이 실제로 실패하면 원인·보존할 변경·인계 범위를 보고하고 사용자 확인 후 재인계한다. spawn 실패·도구 부재는 보고하고 무한 재시도·게이트 우회·Astra 직접 구현으로 대체하지 않는다. PR 생성은 머지·배포·삭제를 승인하지 않는다.

## Response minimum

Follow `/Users/carpdm/.codex/response-format.md`. 헤더 뒤 첫 문장은 결론으로 쓴다. 파일이나 상태를 바꾼 작업은 결론/변경/근거/검증/(관찰)/남은 것/정리 순서로 보고하고, 절대 `path:line`, 실제 명령과 출력 수치, 실패·미실행을 밝힌다. 다음 작업은 제안하거나 체이닝하지 않는다. 남은 것은 이번 세션의 `[필수]`만 적고, 필수가 없으면 정리 블록에서 이번 세션 worktree 삭제 가능 여부를 알린다(삭제는 요청 시에만). 조사·질문·계획은 헤더와 본문으로 쓴다.
