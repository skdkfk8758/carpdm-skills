# Land Preflight — PR/머지 플로우 전 last-mile 사전 점검

IMPORTANT: 자율 파이프라인이 실작업은 끝내고 **마지막 land/deploy 단계에서 멈추는** 사고가 반복된다(실측: git remote 부재로 /land 가 PR 플로우 미완 → 로컬 머지만 남음, 비인터랙티브 마이그레이션이 확인 프롬프트에서 정지). PR 생성·머지·배포로 향하는 플로우는 시작 전에 아래 preflight 를 통과시킨다.

## Preflight 체크 (PR/land/deploy 진입 전)

1. **remote 존재** — `git remote -v` 로 origin 확인. 없으면 즉시 사용자에게 보고하고 로컬 머지 fallback 여부를 묻는다 — 작업 다 끝내고 나서 발견하지 않는다.
2. **브랜치 상태** — 메인 워크트리가 기대 브랜치(trunk)에 있는지, 타겟 base 브랜치가 존재하는지 확인. 예상 밖 브랜치면 진행 전 보고.
3. **인증** — `gh auth status` (PR 플로우), 배포 자격증명 (deploy 플로우) 가용 확인.
4. **비인터랙티브 보장** — 파이프라인 안에서 실행할 명령이 확인 프롬프트를 띄울 수 있으면 pre-answer flag(`--yes`, `-f`, `--no-input` 류)를 명시하거나, flag 가 없으면 그 명령을 파이프라인에 넣지 않고 사용자 단계로 분리한다. 백그라운드 잡이 인터랙티브 프롬프트에서 hang 하는 것이 최악의 실패 모드다.

## 규칙

- preflight 실패 = **작업 시작 전 보고**. "구현 끝났는데 remote 가 없어서 못 올림" 은 preflight 생략의 결과다.
- 파괴 명령(`gh pr merge`, `git push`)의 pre-answer flag 는 비인터랙티브 보장용이지 승인 게이트 우회용이 아니다 — 사용자 승인 게이트는 그대로 유지.

## Anti-patterns

- 구현·검증 전부 끝낸 뒤 PR 생성 시점에 remote 부재 발견 — preflight 생략.
- 백그라운드 마이그레이션/배포 잡이 y/n 프롬프트에서 무한 대기 — 비인터랙티브 보장 누락.
- preflight 실패를 침묵하고 로컬 머지로 조용히 대체 — 사용자는 PR 이 올라간 줄 안다.

## Related

- `~/.claude/rules/branch-worktree-strategy.md` — 브랜치/워크트리 전략(본 룰의 상위 컨벤션).
- `land` 스킬 — 본 preflight 의 주 적용 대상.
