# Commit Isolation — uncommitted 노출 최소화

IMPORTANT: 동시 세션·백그라운드 잡이 uncommitted 작업 트리를 `git reset`/`checkout` 으로 밀어버려 진행 중 편집을 통째로 날릴 수 있다. 진짜 위험은 변경 자체가 아니라 **uncommitted 상태로 오래·크게 노출되는 것**이다.

## 1차 방어 — early-commit

- 장시간 작업 또는 멀티파일 변경은 **첫 의미 단위에서 즉시 커밋**한다. 거대한 uncommitted change set 을 노출한 채 끌지 않는다.
- 보호 브랜치면 작업 시작 시 feature 브랜치부터 만든다(`guard-branch-protection` 와 동일 방향).
- WIP 라도 작은 커밋을 쌓는다 — 나중에 squash/rebase 로 정리하면 된다. 커밋된 것은 reset 사고에서 살아남는다.

## 2차 방어(위험할 때만) — 수동 worktree

> 스코프: 본 항목은 *이미 체크아웃된 트리*의 진행 중 작업 보호용 *추가* worktree 를 말한다. 새 브랜치 격리 자체는 `branch-worktree-strategy.md §5`(예외없이 worktree)가 SSOT — 충돌 아님.

- 동시 세션/백그라운드 잡이 같은 트리를 건드릴 게 **예상될 때만** worktree 로 격리한다.
- worktree 자동격리를 전역 기본으로 켜지 않는다 — 대부분 작업에 과하고, in-place 가 단순하다. 위험 신호가 있을 때 수동으로 켠다.

## 적용 시점

- 멀티파일 리팩터/기능 작업 진입 → 첫 커밋 지점을 일찍 잡는다.
- 백그라운드 잡을 띄우기 전 → 현재 트리가 커밋됐는지 확인.
- 병렬 세션을 의도적으로 돌릴 때 → 각 작업을 worktree 또는 분리 브랜치로.

## Anti-patterns

- "다 끝나면 한 번에 커밋" — 그 사이 reset 한 번이면 전부 손실.
- 안전 근거 없이 모든 작업을 worktree 로 격리 — 과한 오버헤드.
- uncommitted 대량 편집 위에서 백그라운드 잡 실행.
