# Knowledge Folders — 저장소 문서 표준 레이아웃

IMPORTANT: 에이전트가 읽을 위치를 단일화한다. **지침 진입점은 `CLAUDE.md` 하나다.**

## Standard Layout

| 경로 | 역할 | SSOT? |
|---|---|---|
| `CLAUDE.md` | **지침 본문 SSOT.** 규칙은 여기만 고친다 | **YES** |
| `rules/` | 생성 파이프라인을 쓰는 프로젝트의 fragment SSOT (선택) | YES (쓸 때) |
| `docs/` | 문서 단일 트리 — knowledge(`adr/concepts/guides/reference`) + artifact(`specs/plans/...`) | YES |
| `~/.claude/projects/<slug>/memory/` | 세션 간 메모리 (글로벌, 저장소 밖) | YES |

**지침 파일은 저장소당 하나다.** 벤더별 진입점을 따로 두면 갈라지고, 갈라진 쪽을 읽은 에이전트가
틀린 경로·틀린 포트를 사실로 받는다(2026-08-03 실측: 한 저장소는 바이트 동일 사본 2벌, 다른 저장소는
한쪽이 마이그레이션 이전 형상에 머문 채 5주 방치, 또 한 곳은 두 파일이 **서로 다른 절반**을 담아
어느 걸 읽었느냐로 규칙의 절반만 보였다).

`CLAUDE.md` 가 그 하나다 — Claude Code 가 native 로 읽고 `@import` 로 분할까지 된다.
**2026-08-04 부로 `AGENTS.md`(Codex/OpenAI 진입점)는 전 저장소에서 제거했다.**

## docs/ Sub-tree

| Sub-tree | 용도 |
|---|---|
| `docs/adr/` | Architecture Decision Records — **영속**(왜·버린 대안·외부 제약) |
| `docs/concepts/` · `guides/` · `reference/` | 영속 지식·절차·참조 |
| `docs/_index/index.md` | knowledge portal — 전체 navigator, 1 프로젝트 1 진입점 |
| `docs/specs/` · `plans/` | 시점 기록 — **수명은 머지까지**. 결정은 ADR 로 승격 후 정리 |
| `docs/{runbooks,reports,reviews,handoff,_archive}/` | 운영 산출물 |

**knowledge** = 2+ 페이지에서 재참조될 영속 지식. **artifact** = 시점 기록.
판별 질문 하나: *"이걸 실행 가능한 검사로 바꿀 수 있는가?"* — 예면 테스트로 만들고 문서는 지운다.
아니면 왜·제약·미검증이므로 ADR 한 줄로 남긴다.

## Rules

### R1: 지침 파일은 하나

- 벤더별 진입점(`AGENTS.md`·`.cursorrules` 등)을 추가하지 않는다. 새 도구를 들이면 그 도구가 `CLAUDE.md` 를 읽게 만든다.
- 부득이 추가하면 **본문 없는 포인터**여야 하고, *왜 포인터인지* 한 줄을 남긴다 — 안 적으면 다음 사람이 "비어 있으니 채워야지" 하고 되돌린다.

### R2: 디렉터리별 룰은 중첩 `CLAUDE.md` 로

Claude Code 는 `<dir>/CLAUDE.md` 를 그 디렉터리에서 작업할 때만 자동 로드한다 — 상시 로딩을 안 늘리고
FE/BE 룰을 분리하는 정공법이다(예: `apps/next/src/CLAUDE.md` → `rules/11-frontend.md`).
중첩 로딩이 없는 도구를 쓰게 되면 그 도구 쪽에서 경로를 명시 Read 해야 한다.

### R3: 생성 파이프라인은 선택 — 쓰면 in-repo SSOT 만

`rules/*.md` → 생성물 구조를 쓰는 프로젝트라면:

- **생성 입력은 저장소 안에만 둔다.** 개인 하네스(`~/.claude/`)의 룰을 생성물에 inline 하면
  환경마다 결과가 달라지고, 그러면 drift 검사가 그 파일을 **SKIP 하도록** 만들어진다.
  그 사각에서 은퇴한 룰의 사본이 계속 지시된다(실측 90,308 bytes — ADType `ADR-066`).
- **drift 검사가 모든 생성물을 덮어야 한다.** 검사에서 빠진 생성물은 반드시 썩는다.
- 생성물 손편집 금지. 고치는 곳은 언제나 `rules/`.

### R4: 부재 허용

| 대상 | 부재 OK? |
|---|---|
| `CLAUDE.md` | NO — 에이전트가 작업할 저장소면 필수 |
| `rules/` | YES — 본문이 `CLAUDE.md` 한 장이면 생략 |
| `docs/` | YES — knowledge 가 2+ 페이지 누적되면 도입 |

**선제 생성 금지.** 아무도 안 읽는 지침을 늘리는 것이 이 규약이 막으려는 실패다.

### R5: 설계 문서는 "삭제 대상"을 명문화한다

SPEC/PLAN/Acceptance 에 `## YAGNI / 삭제 대상` 섹션을 **의무**로 둔다. 무엇을 추가하는지만 적고
무엇을 제거하는지 안 적으면, 기능 전환의 옛 경로가 "다음 PR"로 미뤄져 영영 남는다.

- 이 작업으로 **호출처가 사라지는** 코드·타입·테스트·문서를 명시한다.
  없으면 `(제거할 기존 경로 없음: 신규 추가만)` 이라고 **명시적으로** 적는다 — 빈칸·누락 금지.
- 기능 전환/개편이면 옛 경로 제거를 **같은 커밋/PR** task 로 넣는다. 별도 PR 로 미루지 않는다.
- `@deprecated` 만 달고 삭제 task 를 안 만드는 것이 가장 흔한 실패다 — 다음 PR 은 오지 않는다.

### R6: portal 단일 진입

`docs/` 를 쓰면 `docs/_index/index.md` 가 단일 진입점. 신규 문서는 portal 의 knowledge/artifact
라우팅을 따르고, **추가 시 portal 갱신**한다 — 안 하면 발견성이 없어 문서가 중복 생성된다.

## Anti-patterns

- 벤더별 진입점을 따로 만들어 규칙 본문을 복사 — 갈라진다. 시간 문제가 아니라 **관측된 사실**이다.
- 생성물에 개인 하네스를 inline — 환경 의존 → drift 검사 SKIP → 은퇴 룰이 살아남는다.
- `docs/` 내용을 지침 본문에 inline — 상시 로딩 폭증.
- knowledge 와 artifact sub-tree 혼재 — 경계가 흐려져 grep 노이즈.
- 저장소를 만들자마자 지침 파일부터 생성 — 읽을 사람도 내용도 없다.

## Related

- `branch-worktree-strategy.md` — 브랜치·머지 규율 (지침이 서술하는 워크플로의 짝)
- 인스턴스 예: ADType `docs/adr/066-claude-md-single-ssot.md` (ADR-011 supersede — 왜 inline 이 아니라 포인터인가)
