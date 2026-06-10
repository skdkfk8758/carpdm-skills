# carpdm-skills

Claude Code 글로벌 스킬 배포 레포. **작업 유형별 엄격 파이프라인 3종 + 심층 인터뷰 1종 + 계획 수립 1종 + Goal Prompt 저작 1종 + 세션 인계 1종 + 정리 유틸 1종 + PR 랜딩 1종 + 스킬 배포 1종 + 배포 전 최종 검토 1종 + UI 디자인 충실 재현 1종 + ERD 도식 1종 + 코드베이스 컨텍스트 셋업 1종 + 공유 엔진 1종**, 총 **스킬 15종.**

스킬은 역할에 따라 **5개 그룹**으로 나뉜다. (물리 폴더는 플랫 — `skills/` 한 레벨. craft-core 절대경로 결합 때문에 카테고리 폴더는 두지 않으며, 분류는 개념적이다.)

### 🔨 build-pipeline — 코드를 짓는 엄격 파이프라인

craft-core 공유 엔진(소크라테스 인터뷰 → codex 적대 리뷰 → TDD → 보안 검증) 위에서 도는 작업유형 3종 + 엔진.

| 스킬 | 용도 | 트리거 (자연어로도 발화) | 의존 |
|---|---|---|---|
| [`forge`](skills/forge) | 새 기능 구현 (0→1) | "X 추가/구현/만들어줘" | craft-core |
| [`hunt`](skills/hunt) | 버그 수정 (재현→회귀잠금) | "X 깨졌어", "왜 null 반환하지" | craft-core |
| [`renew`](skills/renew) | 기존 기능 변경/리뉴얼 | "X 다시 만들어", "동작 바꿔줘" | craft-core |
| [`craft-core`](skills/craft-core) | ⚙️ 공유 엔진 (직접 호출 X) | forge/hunt/renew/deep-plan 이 내부에서 읽음 | — |

### 🧭 think & plan — 코드 전에 요구사항·계획·목표를 정리

| 스킬 | 용도 | 트리거 (자연어로도 발화) | 의존 |
|---|---|---|---|
| [`deep-interview`](skills/deep-interview) | 모호한 아이디어 → 검증가능 spec (소크라테스 인터뷰, ambiguity 게이트) | "인터뷰해줘", "이거 같이 정리하자", "/deep-interview" | 없음 (독립) |
| [`deep-plan`](skills/deep-plan) | (모호하면 인터뷰 보강 후) 실행 가능 PLAN 문서 + UI면 HTML 시안, 빌드는 안 함 | "계획 세워줘", "어떻게 만들지 설계", "구현 말고 플랜만", "UI 시안 뽑아줘", "/deep-plan" | craft-core |
| [`deep-prompt`](skills/deep-prompt) | 입력 → 자율 goal/백그라운드 잡 실행용 검증가능 Goal Prompt(.md) 저작 (고정 템플릿, 성공기준 측정가능화) | "goal 프롬프트 만들어줘", "백그라운드로 돌릴 목표 정리", "/deep-prompt" | 없음 (독립) |

### 🎨 design & ui — 추출된 디자인 시스템 충실 재현

| 스킬 | 용도 | 트리거 (자연어로도 발화) | 의존 |
|---|---|---|---|
| [`imprint`](skills/imprint) | DESIGN.md(design-extractor 추출) → React+Tailwind 테마·컴포넌트·HTML 시안 충실 재현 (token-traceability) | "이 DESIGN.md 로 컴포넌트 만들어줘", "추출한 디자인대로 Tailwind 테마", "/imprint" | 없음 (독립) |
| [`erd`](skills/erd) | DB 스키마(마이그/ORM/repo) → self-contained HTML ERD (테이블 카드 + SVG 관계선 4종 색) | "이 마이그레이션으로 ERD 그려줘", "DB 관계도 HTML 로", "스키마 다이어그램", "/erd" | 없음 (독립) |

### 🏗 codebase context — 코드 옆에 도메인 지식 두기 + 노후화 게이트

| 스킬 | 용도 | 트리거 (자연어로도 발화) | 의존 |
|---|---|---|---|
| [`colocate-domain-context`](skills/colocate-domain-context) | 도메인별 CLAUDE.md 를 코드 옆에 배치(경로 근접 auto-load) + 코드만 바뀌고 문서 미갱신 시 경고하는 co-update 게이트 셋업. 프로젝트 구조·verify host(verify.sh/husky/pre-commit/CI/Makefile/none)에 적응 | "폴더별 CLAUDE.md", "도메인 지식 코드 옆에", "co-update 게이트 만들어줘", "문서 노후화 막는 게이트" | 없음 (독립) |

### 🧹 session & ops — 작업 사이클 운영 (저장·정리·랜딩·배포검토)

| 스킬 | 용도 | 트리거 (자연어로도 발화) | 의존 |
|---|---|---|---|
| [`handoff`](skills/handoff) | 세션 인계 (저장/복원) | "여기까지 하자 이어서", "어디까지 했지" | 없음 (독립) |
| [`sweep`](skills/sweep) | 프로젝트 잡동사니 정리 (문서/로그) | "쌓인 로그/플랜 치워줘", "docs 청소" | 없음 (독립) |
| [`land`](skills/land) | 올린 PR 머지 + 로컬 정리 | "PR 머지하고 브랜치 정리", "land my PRs" | 없음 (독립) |
| [`ship`](skills/ship) | (레포 전용) 스킬 변경 PR→CI→머지→로컬정리 한 흐름 | "PR 올리고 land 까지", "ship 해줘", "CI 통과하면 머지" | 없음 (독립, carpdm-skills 전용) |
| [`preflight`](skills/preflight) | 배포 직전 앱 전체 최종 검토 → 10차원 + 기술부채 점검, 고정 포맷 리포트 + GO/조건부GO/NO-GO 판정 | "배포 전에 검토해줘", "최종 점검", "출시 전 전체 봐줘", "배포 가능한지", "/preflight" | 없음 (독립) |

**파이프라인 3종 공통 흐름**: 소크라테스 인터뷰 → codex 적대적 플랜 리뷰 → 동적 워크플로 TDD(sonnet) → simplify 검토 패스(forge·renew·hunt, 옵션·동작불변, `/simplify` 위임) → 보안 검증 → 빌드 후 다음 스킬 제안(push 했으면 `/land`, 잔여 정리면 `/sweep` — 추천만, 자동 시작 X).

엔진은 두 실행 모드를 가진다 — **linear**(기본, 단일세션) / **orchestrated**(멀티에이전트 council, 명시 요청 시). 사용법은 [`docs/guides/craft-modes.md`](docs/guides/craft-modes.md).

문서를 산출하는 스킬(plan·spec·goal·adr)의 출력 형태 카탈로그는 [`docs/reference/output-templates.md`](docs/reference/output-templates.md).

> 과거 재사용 서브에이전트 6종(`agents/*.md`)과 에이전트 저작 스킬 `summon` 을 함께 배포했으나 [ADR 002](docs/adr/002-revert-agents-artifact-type.md) 로 철회했다 — 이 레포는 다시 스킬 단일 아티팩트다.

---

## 설치

### 전체 설치

```bash
git clone https://github.com/skdkfk8758/carpdm-skills.git
cd carpdm-skills
bash install.sh
```

15개 스킬을 `~/.claude/skills/` 로 복사한다. 기존 동일 이름은 in-place 덮어씀 (멱등 — git history 가 안전망). 설치 후 Claude Code **재시작**.

### 개별 설치 (하나씩)

```bash
# 예: handoff 만
cp -R skills/handoff ~/.claude/skills/

# 예: forge 만 — craft-core 도 같이 (의존)
cp -R skills/forge skills/craft-core ~/.claude/skills/
```

> ⚠️ **forge / hunt / renew / deep-plan 은 craft-core 가 반드시 함께 있어야 한다.** 내부에서 `~/.claude/skills/craft-core/references/...` 를 절대경로로 참조하기 때문 (deep-plan 은 deep-interview 의 references 도 차용). handoff / sweep / land / ship / deep-prompt / imprint / erd 은 단독 설치 가능. 단 **deep-plan 의 DB/BE plan ERD 시안** 기능은 `erd` 가 설치돼 있어야 동작한다(없으면 ERD 만 생략, plan/시안은 정상). 둘을 함께 쓰려면 `erd` 도 같이 설치.

---

## 전제 / 의존성

| 항목 | 필수? | 설명 |
|---|---|---|
| Claude Code | ✅ | 스킬은 Claude Code Skill 기능 위에서 동작 |
| 설치 경로 `~/.claude/skills/` | ✅ 고정 | 다른 위치면 craft-core 엔진을 못 찾아 깨짐 |
| **craft-core** | ✅ | 파이프라인 3종 + deep-plan 공유 엔진. 빼면 4개 전부 동작 불가 |
| **`codex:rescue` 플러그인** | ⚠️ 권장 | Phase 2(적대 플랜 리뷰)가 호출. 없으면 그 단계는 수동 대체/생략. handoff 는 무관 |

`~` 절대경로는 사용자별 전개되므로 어느 머신이든 `~/.claude/skills/` 설치면 동작.

---

## 사용법

```
# 자연어 — 의도 감지 자동 발화
"ai ask 엔드포인트에 streaming 추가해줘"        → forge
"벤치가 500 던져, 고쳐줘"                        → hunt
"이 플로우 동작을 이렇게 바꿔줘"                 → renew
"대시보드 어떻게 만들지 플랜이랑 UI 시안 줘"     → deep-plan (빌드 X)
"여기까지 하자, 내일 이어서 정리해줘"            → handoff (저장)
"어제 하던 거 어디까지 했지"                      → handoff (복원)

# 슬래시 명시 호출
/forge   /hunt   /renew
```

handoff 는 **양방향 자동 감지** (작업 끝/중단 = 저장, 세션 시작/재개 = 복원). 파이프라인 3종은 **언더트리거 설계**(과발화 방지) — 확실히 원하면 슬래시 명시 호출 권장.

---

## 검증 / 트러블슈팅

```bash
ls ~/.claude/skills/   # forge hunt renew deep-interview deep-plan deep-prompt handoff sweep land ship preflight imprint erd craft-core
```

- **forge 류가 craft-core 못 찾음** → 설치 경로 확인. `~/.claude/skills/craft-core/` 필수.
- **Phase 2 codex 에러/스킵** → `codex:rescue` 미설치. 수동 리뷰 또는 codex 플러그인 설치.
- **스킬 안 보임** → Claude Code 재시작 (세션 시작 시 로드).
- **handoff 저장 위치** → git repo 의 `docs/handoff/`. repo 밖/non-git 이면 `~/.claude/projects/<slug>/handoff/`.

## 업데이트 / 제거 (사용자)

```bash
git pull && bash install.sh      # 업데이트 (기존본 .bak 백업)
rm -rf ~/.claude/skills/<name>   # 개별 제거
```

## 배포 (유지보수자)

작업본(`~/.claude/skills/`)에서 스킬을 고친 뒤 레포로 반영:

```bash
bash sync.sh           # ~/.claude/skills/ → repo skills/ 미러링 후 변경 표시
bash sync.sh --push    # 미러링 + 브랜치·PR·머지 자동 (master 직접 push 안 함)
```

`sync.sh` 는 **레포가 추적 중인 것만** 갱신한다 (true mirror, 삭제 파일 반영) — `skills/` 의 디렉토리별. 새 스킬 배포 시작은 `skills/<name>/` 디렉토리를 먼저 만든 뒤 sync.

`--push` 는 `chore/sync-<timestamp>` 브랜치를 만들어 PR 생성·머지까지 한다 (`gh` CLI 필요). master 직접 push 를 막는 브랜치 보호 환경에서도 동작.
