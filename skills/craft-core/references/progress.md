# Progress Template — 턴 내 진행 표시 공유 SSOT

구현 스킬(forge/hunt/renew · linear-goal)이 서브에이전트·팀에이전트로
작업할 때 그 진행을 **작업 턴 안에서** 보여주는 방법의 단일 SSOT. `output-contract.md`
와 동렬 — craft-core 에 있지만 엔진(pipeline) 의존이 아닌 공유 한 장이다. 소비처는
이 파일을 읽어 emit 하고 포맷을 복제하지 않는다(drift 차단).

## 채널 원칙 — 라이브 2 + 스냅샷, 흉내 금지

턴 내 라이브 갱신이 되는 채널은 **둘뿐**이다:

1. **native Task 체크리스트** (`TaskCreate`/`TaskUpdate`) — 단 Workflow 실행 중엔
   메인 루프가 잠들어 갱신 불가. 긴 Workflow 페이즈는 항목 1개를 `in_progress` 로
   고정하고 내부는 채널 2에 위임한다.
2. **Workflow 진행 트리** (`phase()` / agent `label` / `log()`) — Workflow 구간 한정.
   서브에이전트 **내부** 스텝은 안 보이므로 label·log() 가 요약의 전부다.

나머지는 시점 스냅샷: 서브에이전트(Agent) 완료 알림 · STATUS_LOG 파일(R8) ·
메인 마크다운 배너(append-only — 페이즈 **경계**에서만 찍는다).

**금지(흉내):** 서브에이전트 내부 실시간 스트리밍 시도, 이미 출력된 배너의 반복
재출력으로 라이브 위장, 폴링 wakeup 남발. 하니스가 불가한 것을 흉내내면 토큰만
태우고 라이브처럼 보이지도 않는다.

## P1 — council 라운드 배너 (소비: orchestrated.md §1)

council 은 Workflow 가 아니라 팀 메시지 교환이라 자동 트리가 없다. 메인 루프가
**라운드 경계마다** 아래 스코어보드 1블록을 배너로 찍는다 — 메시지 본문 중계 금지,
건수 + 대표 1구절만:

```
── council r<N> ──
 designer   v<N> (수용 X건 · 반박 Y건: <대표 근거 1구절>)
 adversary  공격 Z건 — <대표 이의 1구절>
```

수렴 시 `공격 0건 — 수렴` + `plan freeze → 사용자 승인 대기` 1줄. 공격 카운트의
감소가 곧 수렴 게이지다.

## P3 — worker STATUS_LOG 기본 주입 (소비: linear-goal SKILL.md)

백그라운드 worker 는 도는 동안 턴이 조용한 게 정상이다. 대신:

- **spawn 시** worker 프롬프트 헤더에 `STATUS_LOG=<worktree>/logs/agents/goal-<issue-id>-<ts>.status.log`
  를 기본 주입한다(subagent-invocation R8 을 opt-in 이 아니라 기본으로). append 규율은
  R8 그대로 — ≤20 스텝 줄 + 종료 시 `[DONE]`/`[FAIL]` 마커 정확히 1회.
- **kickoff 보고**에 관전 명령을 명시한다: `tail -f <status.log 경로>`.
- 사용자가 진행을 물으면 메인이 status log 꼬리(최근 ~5줄)를 읽어와 요약한다.
- 판정은 R9 그대로 — idle 알림만으론 완료 불인정, `[DONE]` + git diff·verify 재실행으로
  메인이 직접 판정.

> **§P4 (ETA 스냅샷) 는 은퇴했다 (2026-07-30).** 매 phase 경계마다 jsonl median
> 조회 + Task 텍스트 `est ~Xm` 부기 + 배너는 가치(예측 눈요기) 대비 비용(매 경계
> 조회·갱신)이 안 맞았고, 표본 오염(P2 핑퐁 레거시)으로 예측이 틀렸다. **타이밍
> 기록 자체는 유지**(pipeline.md 타이밍 섹션 — 튜닝의 유일 근거) — 은퇴한 것은
> *표시*뿐이다. 소요 보고는 Phase 5 §R 보드의 타이밍 행 1회로 충분. 복원은 git
> history.

## 실패 시

전부 hard gate 아님 — 표시·기록 실패는 note 만 남기고 파이프라인을 막지 않는다.
