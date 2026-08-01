# 팀원 온보딩 & 개발 워크플로우 가이드

> carpdm-skills 환경을 새 머신에 재현하고, 실제 개발에서 스킬을 언제·어떻게 쓰는지의
> 실전 가이드. 시각화 판: [team-workflow-guide.html](team-workflow-guide.html) (Artifact 로도 배포).
> 스킬 인벤토리 SSOT 는 각 `skills/<name>/SKILL.md` — 이 문서는 사용 관점의 안내다.

---

## 1. 셋업 (신규 머신, 3명령 + 후속 4단계)

```bash
git clone https://github.com/skdkfk8758/carpdm-skills.git && cd carpdm-skills
bash install.sh                 # ① 자작 스킬 26종 → ~/.claude/skills/
bash install-global.sh          # ② rules·hooks·settings + 서드파티 스킬 129종 + ~/.codex 형상
bash global/setup/replicate.sh  # ③ MCP(claude/codex)·플러그인 10종·npm 런타임 (멱등)
```

설치 후 수동 4단계:

1. `~/.claude/settings.json` · `~/.codex/config.toml` 의 `<FILL-ME>` 값 채우기.
2. `~/.claude/linear-repo-map.json` 의 repo 경로를 **자기 머신 경로**로 수정 (Linear 팀 라우팅 SSOT).
3. OAuth — Linear MCP 는 Claude Code 와 codex **각각** 첫 사용 시 브라우저 승인.
4. Claude Code 재시작 → 검증:

```bash
ls ~/.claude/skills/ | wc -l    # 130+ 기대
claude mcp list                 # linear, context7
claude plugin list              # ponytail, clean-architecture 등 10종
codex mcp get linear            # enabled: true
```

---

## 2. 핵심 개념 (스킬보다 먼저)

| 개념 | 요지 |
|---|---|
| **skill-first** | 비trivial 코드 작업(3+ 파일 · 200+ LOC · 검증 루프 필요)은 즉흥 편집 대신 스킬 경유. trivial(오타·1-2 파일)은 직접. |
| **승인 게이트** | 외부 write(이슈 생성·PR 머지·브랜치 삭제)는 스킬이 **미리보기 → 승인 대기** 후 실행. 발동 자체는 안전 — 읽기·플랜까지만. |
| **worktree 전략** | 새 브랜치 격리는 예외 없이 worktree(`git worktree add -b`). 메인 체크아웃은 항상 trunk(master). |
| **자동 가드(훅)** | 보호 브랜치 직접 작업 차단 · 파괴 명령 경고 · push/PR 전 CI 3종 로컬 선실행(차단형) · 작업 종료 시 스킬 sync 미완 경고. 훅이 막으면 우회하지 말고 메시지를 따른다. |
| **모드 2종** | `caveman`(산문 압축)·`ponytail`(코드 미니멀리즘 — 매 세션 자동 full, YAGNI 사다리). `/ponytail lite\|ultra` 로 조절. |
| **codex 연동** | 이슈등록 실행(linear-register)·착수 재플래닝(linear-replan)·plan 비평자(deep-plan)가 `codex exec` 로 교차모델 판단을 산다. codex 없으면 graceful 폴백. |

---

## 3. 메인 워크플로우 — 아이디어에서 머지까지

```
모호한 아이디어 ──/deep-interview──▶ REQ spec
                                        │
계획·시안 필요 ──/deep-plan──▶ PLAN + HTML 시안 + Goal Prompt   (codex 비평자 debate)
                                        │
        "이슈로 쪼개줘" ──/linear-register──▶ Linear 이슈 트리   (codex 가 등록 실행)
                                        │
       ┌────────────────────────────────┼───────────────────────────┐
   자율 실행                        직접 빌드                  착수 전 결정 정리
 /linear-goal                 /forge /hunt /renew              /linear-replan
 (worktree+worker+PR)         (인터뷰→TDD→보안검증)            (codex 갈래 인터뷰)
       └────────────────────────────────┼───────────────────────────┘
                                        │
                          /land ──▶ PR 머지 + 로컬 정리
                                        │
                          /wt-sweep ──▶ 워크트리·세션 정리
```

- **어디서 시작하나**: 요구가 crisp 하면 빌드 스킬 직행. 모호하면 deep-interview/deep-plan 부터.
- **세션 경계**: 끊을 때 `/handoff`(저장), 재개할 때 "어디까지 했지"(복원).
- **배포 직전**: `/preflight`(10차원 종합 GO/NO-GO) · `/fortify`(보안 5카테고리만 깊게).

---

## 4. 스킬 사용 가이드 (그룹별 — 언제 · 어떻게)

### 🔨 빌드 파이프라인 (코드를 짓는다)

| 스킬 | 언제 | 이렇게 말하면 발동 |
|---|---|---|
| `forge` | **없던 기능**을 새로 | "X 추가해줘", "만들어줘", `/forge` |
| `hunt` | **깨진 것**을 고침 (재현→회귀 잠금) | "왜 안 돼", "500 떠", `/hunt` |
| `renew` | **있는 기능**을 의도적으로 변경 | "이 화면 개편", "동작 바꿔줘", `/renew` |
| `tdd` | 요구 명확 + 순수 red-green 만 (파이프라인 없이) | "test-first 로", `/tdd` |

셋 다 같은 엔진(craft-core): 소크라테스 인터뷰 → plan 게이트 → TDD → 보안 검증.
**언더트리거 설계**라 확실히 원하면 슬래시 명시가 빠르다.

### 🧭 생각·계획 (코드 전에)

| 스킬 | 언제 | 산출 |
|---|---|---|
| `deep-interview` | 아이디어가 흐릿할 때 | 번호 매긴 REQ spec |
| `deep-plan` | 플랜/설계/UI 시안 필요, 구현은 아직 | PLAN.md + 시안 HTML + Goal Prompt |
| `deep-prompt` | 백그라운드 자율 잡에 넣을 목표문 | Goal Prompt .md |

### 🔗 Linear 라이프사이클

| 스킬 | 언제 | 비고 |
|---|---|---|
| `linear-register` | 이슈 등록 **유일 진입점** (단건·plan 분할 모두) | 등록 전 dedup 대조 + 본문 미리보기 게이트. 직접 `save_issue` 금지(룰) |
| `linear-replan` | 티켓 **착수 직전** 결정 갈래 정리 | codex 초안 → 인터뷰 확정 → 착수 계획 코멘트 |
| `linear-goal` | 티켓 1건 자율 실행 | worktree 분기 → goal worker → PR(In Review 까지) |
| `linear-groom` | 백로그 정리·보강 | 고아 이슈 그룹핑, 빈약 이슈 spec 화 |
| `linear-prioritize` | "뭐부터 하지" 스프린트 플래닝 | 의존·병렬 분석 + 우선순위 |

### 🧹 운영 (세션·정리·머지)

| 스킬 | 언제 |
|---|---|
| `handoff` | 세션 끊기 전 저장 / 재개 시 복원 (양방향 자동) |
| `land` | 올린 PR 머지 + master pull + 브랜치 정리 |
| `wt-sweep` | 잔여 워크트리·세션 기록 정리 (land 후) |
| `sweep` | 오래된 문서·로그·plan 정리 |
| `dev-server-daemon` | dev 서버를 세션 종료 후에도 살려둘 때 |
| `ship` | (이 레포 유지보수자 전용) 스킬 변경 배포 — sync→PR→CI→머지 |

### 🔍 검토·판정 (코드 안 고침)

| 스킬/명령 | 축 |
|---|---|
| `preflight` | 배포 전 10차원 종합 → GO/조건부GO/NO-GO |
| `fortify` | 보안 5카테고리만 깊게 → PASS/조건부/FAIL |
| `/code-review` (빌트인) | diff correctness 리뷰 |
| `/security-review` (빌트인) | diff 보안 리뷰 |
| `/simplify` (빌트인) | 단순화 리뷰 + **수정 적용** |
| `/ponytail-review` · `/ponytail-audit` | 과잉설계 삭제 후보 (diff / repo 전체) |
| `/clean-architecture` (플러그인) | 의존성 규칙·SOLID·레이어 경계 |

### 🎨 UI·도식

| 스킬 | 언제 |
|---|---|
| `mockup` | 기존 프로젝트 룩에 충실한 화면 시안 |
| `imprint` | design-extractor DESIGN.md 를 그대로 재현 |
| `erd` | DB 스키마 → 인터랙티브 ERD (Artifact) |
| `frontend-design` (플러그인) | 자유 창작 UI |

### 🏗 스캐폴딩

`cicd-scaffold`(GitHub Actions 배포) · `admap-scaffold`(ADMap 지도 페이지) ·
`colocate-domain-context`(도메인 CLAUDE.md 배치) · `api-docs-guide-scaffold`(개발자 포털 3종).

---

## 5. 시나리오 퀵레퍼런스

| 상황 | 이렇게 말한다 | 발동 |
|---|---|---|
| 새 기능 만들고 싶다 | "결제 취소 기능 추가해줘" | `forge` |
| 뭔가 깨졌다 | "업로드가 500 떠" | `hunt` |
| 기존 화면을 바꾸고 싶다 | "대시보드 개편해줘" | `renew` |
| 아이디어가 아직 흐릿하다 | "이거 같이 정리하자" | `deep-interview` |
| 설계/시안만 먼저 보고 싶다 | "구현 말고 플랜만" | `deep-plan` |
| 할 일을 잊지 않게 적어두고 싶다 | "이거 이슈로 남겨놔" | `linear-register` |
| 플랜을 티켓으로 나누고 싶다 | "이 플랜 이슈로 쪼개줘" | `linear-register` (분할) |
| 티켓을 맡기고 싶다 | "ADT-123 이거 진행해줘" | `linear-goal` |
| 뭐부터 할지 모르겠다 | "남은 이슈 정리해줘, 뭐부터?" | `linear-prioritize` |
| 오늘은 여기까지 | "여기까지 하자, 내일 이어서" | `handoff` |
| 어제 뭐 하다 말았지 | "어디까지 했었지?" | `handoff` (복원) |
| PR 다 올렸다, 마무리 | "다 됐어, 머지하고 정리해줘" | `land` |
| 워크트리가 쌓였다 | "안 쓰는 워크트리 치워줘" | `wt-sweep` |
| 배포해도 되나 | "배포 전에 전체 검토해줘" | `preflight` |
| 보안 괜찮나 | "보안 점검해줘" | `fortify` |
| DB 구조가 궁금하다 | "이 스키마 ERD 그려줘" | `erd` |
| 화면 시안이 필요하다 | "이 화면 목업 떠줘" | `mockup` |

---

## 6. 이 레포를 유지보수할 때 (스킬을 고치는 사람)

정식 루프: **live `~/.claude/skills/<name>/` 편집 → `bash sync.sh` → 리뷰 → `/ship`**.

- `sync.sh` 는 스킬 미러 + 글로벌 덤프(`sync-global.sh` 내장 — secret 마스킹·스캔 게이트)를 한 커밋에 싣는다.
- `--push`/`--pr-only`/push/PR 시점에 CI 3종(frontmatter·invisible-chars·README 카탈로그)이 로컬 선실행된다 — 로컬 green = CI green.
- 루트 메타(README·scripts·sync.sh 자체)는 ship 범위 밖 — 수동 커밋 후 `land`.
- 환경(MCP·플러그인)을 바꿨으면 `global/setup/replicate.sh` 목록도 같이 갱신 — 안 하면 다음 팀원 온보딩에서 빠진다.

> 상세 아키텍처·설계 결정은 [`rules/project.md`](../../rules/project.md), 글로벌 덤프 구조는 [`global/README.md`](../../global/README.md).
