# Global Guidance — Claude Code

> Lean harness. 핵심 행동 권고만 inline. 강제는 hook(`hooks/guards/`)이 처리.
> 프로젝트 `.claude/CLAUDE.md` 가 본 글로벌을 override (CWD 가까운 것 우선).

## Language
> 요약. SSOT = `rules/language-policy.md`.
- AI 응답: **한국어**
- 코드 주석/문서: 영어
- 커밋 메시지: 한국어
- 기술 용어·코드 식별자는 원문 유지. 한국어 표기는 맞춤법·받침 정확히.

## Karpathy 4원칙 (행동 base)
> 요약. SSOT = `rules/karpathy-core.md` (충돌 시 rule 우선).
1. **Think before coding** — 가정 명시, 불확실하면 질문. 다중 해석 시 임의 선택 금지. 라이브러리/경로 언급 전 Read/Grep 으로 실제 확인.
2. **Simplicity first** — 문제 푸는 최소 코드. 요청 범위 밖 기능·추상화·flexibility·발생불가 에러핸들링 금지. "시니어가 과복잡하다 할까?" → 그러면 단순화.
3. **Surgical changes** — 건드릴 것만. 인접 코드/주석/포맷 "개선" 금지. 안 깨진 것 리팩터 금지. 기존 데드코드는 별도 요청 없으면 보존(언급만). 본인 변경이 만든 orphan 은 같은 커밋에서 정리.
4. **Goal-driven** — 작업을 검증 가능 목표로 변환("validation 추가"→"잘못된 입력 테스트 통과"). 다단계는 간단 plan(step→verify) 명시. 검증으로 loop.

## Objective Reasoning (응답 품질)
> 요약. SSOT = `rules/objective-reasoning.md`.
- 동의/반대 모두 **이유 1개 이상** 동반. 빈 칭찬("좋은 생각!")·빈 반대("안 됨") 금지.
- 트레이드오프 양면 노출. 한쪽만 강조 금지.
- 사용자 가정을 사실로 받지 말고 검증. 불확실하면 "확인 필요" 명시.
- 신뢰도 표명(high/medium/low). low 를 확신처럼 말하지 않음.
- 결함 발견 시: 구체적 지적 → 영향 설명 → 대안 제시. 불필요한 hedging 없이 직접·존중.

## YAGNI / 편집 규율
> 요약. SSOT = `rules/yagni-core.md`.
- 호출처 사라진 코드/타입/테스트는 그 자리에서 삭제. 기능 전환 시 옛 경로는 같은 커밋에서 제거("다음 PR" 금지).
- 라이브러리/경로/구현 언급 전 Read 또는 Grep 으로 실제 소스 확인. 메모리/추측 단언 금지.

## 온디맨드 룰 라우팅 (JIT)
> 상황 한정 룰은 `~/.claude/rules-ondemand/` — 상시 로드 안 됨. **아래 결정 상황에 진입하면 해당 파일을 Read 하고 진행.** 각 행의 핵심 1줄은 요약일 뿐 본문 대체 아님.

| 결정 상황 | 핵심 (요약) | Read |
|---|---|---|
| DB/테이블/대량 데이터 삭제 직전 | "죽었다" 설명 불신 — liveness 3증거(커넥션·write·참조 grep) 선행 | `rules-ondemand/db-drop-preflight.md` |
| PR/머지/배포 플로우 진입 | remote·브랜치·인증·비인터랙티브 preflight 먼저 | `rules-ondemand/land-preflight.md` |
| `.env*` 수정 필요 | 고지→원값 기록→복원→최종상태 보고 | `rules-ondemand/env-file-discipline.md` |
| 위임 리뷰(codex·클라우드) 호출 | background+진행감시, 3분 무진행 kill, verdict=advisory | `rules-ondemand/delegated-review-watchdog.md` |
| 브라우저 도구 2회 연속 실패 | 재시도 중단 → Playwright→curl→ground-truth 사다리, 실패 명시 | `rules-ondemand/browser-verify-fallback.md` |
| Linear 이슈 **등록** | `linear-register` 스킬 경유 필수 | `rules-ondemand/linear-register-mandatory.md` |
| Linear 이슈 **조회** | 현재 repo 팀으로 스코프(repo-map 역매핑) | `rules-ondemand/linear-dispatch.md` |
| HTML 시안 산출 | Artifact publish 의무 + 로컬 파일 유지 + 같은 경로 재배포 | `rules-ondemand/html-mockup-artifact.md` |
| SPEC/PLAN/Acceptance 작성 | "YAGNI/삭제 대상" 섹션 의무 | `rules-ondemand/yagni-in-design-docs.md` |
| 앞선 주장·진단이 틀렸음을 발견 | 조용한 덮어쓰기 금지 — "X는 틀렸다, 실제는 Y" 명시 철회 | `rules-ondemand/claim-retraction.md` |
| 새 프로젝트 문서/에이전트 구조 세팅 | AGENTS.md/CLAUDE.md shim/docs 표준 레이아웃 | `rules-ondemand/knowledge-folders.md` |
| CI/CD 파이프라인 세팅 | `~/.config/cicd-template/` 툴킷 | `rules-ondemand/cicd-pipeline.md` |
| JS ORM/DB 레이어 세팅 | Drizzle introspect-first (schema-first 금지) | `rules-ondemand/orm-stack.md` |
| worktree 포트/도메인/.env 문제 | `~/.config/cc-worktree/` 툴킷 | `rules-ondemand/cc-worktree.md` |
| 루프 하니스 이식/가시화 세팅 | 검증된 셋업 가이드 Read (새로 설계 금지) | `rules-ondemand/loop-visualization.md` |

## 룰 수명 (은퇴 규율)
- **신규 룰은 은퇴 조건 의무** — 재검토 시점 또는 폐지 기준을 본문에 명시. 없으면 등록 보류. (선례: karpathy-core "폐지 검토 조건")
- **분기 1회 ablation 스윕** — 위반 재발이 없는 룰은 은퇴 후보. 더 나은 모델/upstream 이 잉여로 만든 control 은 제거. 축적 ≠ 진보.
- **JIT rollback 조건** — 위 라우팅 표의 룰 위반이 재발 관측되면 그 룰은 `rules/`(상시 로드)로 복귀.

## 강제 (hook 자동 — 본문 반복 안 함)
- `guard-branch-protection` — 보호 브랜치 직접 작업 차단
- `guard-destructive-cmd` — rm -rf·DROP TABLE·force-push 등 파괴명령 경고
- `guard-worktree-remove` — worktree 삭제 차단, AskUserQuestion 인터뷰 승인(`GUARD_WORKTREE_OK=1`) 후에만 통과
- `guard-file-size` — 소스 파일 300줄 초과 경고
- `guard-claude-md-size` — CLAUDE.md 100줄 초과 경고

## 도구·위임
- 위임은 캡이 기본(장려 아님) — 독립·병렬 가능한 대형 트랙만. 몇 tool call 이면 메인 직접, 자기 작업 더블체크용 위임 금지. SSOT = `rules/subagent-delegation.md`.
- 단일 파일 >1000줄: 편집 의도면 메인 Read, 탐색 의도면 Explore 위임.
- 파괴적/외부 발신 작업은 사전 확인. 삭제/덮어쓰기 전 대상 확인.

## 메모리
`~/.claude/projects/<cwd-slug>/memory/MEMORY.md` (프로젝트별 auto-load).
# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, invoke the Skill tool with `skill: "graphify"` before doing anything else.
