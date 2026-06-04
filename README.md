# carpdm-skills

Claude Code 글로벌 스킬·에이전트 배포 레포. **작업 유형별 엄격 파이프라인 4종 + 심층 인터뷰 1종 + 계획 수립 1종 + Goal Prompt 저작 1종 + 세션 인계 1종 + 정리 유틸 1종 + PR 랜딩 1종 + 에이전트 저작 1종 + 공유 엔진 1종**, 그리고 **재사용 서브에이전트 6종.**

| 스킬 | 용도 | 트리거 (자연어로도 발화) | 의존 |
|---|---|---|---|
| [`forge`](skills/forge) | 새 기능 구현 (0→1) | "X 추가/구현/만들어줘" | craft-core |
| [`hunt`](skills/hunt) | 버그 수정 (재현→회귀잠금) | "X 깨졌어", "왜 null 반환하지" | craft-core |
| [`renew`](skills/renew) | 기존 기능 변경/리뉴얼 | "X 다시 만들어", "동작 바꿔줘" | craft-core |
| [`reshape`](skills/reshape) | 리팩터 (동작 불변) | "정리/추출/분리/DRY 해줘" | craft-core |
| [`deep-interview`](skills/deep-interview) | 모호한 아이디어 → 검증가능 spec (소크라테스 인터뷰, ambiguity 게이트) | "인터뷰해줘", "이거 같이 정리하자", "/deep-interview" | 없음 (독립) |
| [`deep-plan`](skills/deep-plan) | (모호하면 인터뷰 보강 후) 실행 가능 PLAN 문서 + UI면 HTML 시안, 빌드는 안 함 | "계획 세워줘", "어떻게 만들지 설계", "구현 말고 플랜만", "UI 시안 뽑아줘", "/deep-plan" | craft-core |
| [`deep-prompt`](skills/deep-prompt) | 입력 → 자율 goal/백그라운드 잡 실행용 검증가능 Goal Prompt(.md) 저작 (고정 템플릿, 성공기준 측정가능화) | "goal 프롬프트 만들어줘", "백그라운드로 돌릴 목표 정리", "/deep-prompt" | 없음 (독립) |
| [`handoff`](skills/handoff) | 세션 인계 (저장/복원) | "여기까지 하자 이어서", "어디까지 했지" | 없음 (독립) |
| [`sweep`](skills/sweep) | 프로젝트 잡동사니 정리 (문서/로그) | "쌓인 로그/플랜 치워줘", "docs 청소" | 없음 (독립) |
| [`land`](skills/land) | 올린 PR 머지 + 로컬 정리 | "PR 머지하고 브랜치 정리", "land my PRs" | 없음 (독립) |
| [`summon`](skills/summon) | 새 서브에이전트 정의 파일 저작 (model·tool 선택 + 검증된 프롬프트 골격) | "X 하는 에이전트 만들어줘", "서브에이전트 설계해줘", "/summon" | 없음 (독립) |
| [`craft-core`](skills/craft-core) | ⚙️ 공유 엔진 (직접 호출 X) | forge/hunt/renew/reshape 가 내부에서 읽음 | — |

**파이프라인 4종 공통 흐름**: 소크라테스 인터뷰 → codex 적대적 플랜 리뷰 → 동적 워크플로 TDD(sonnet) → 컨벤션 정렬 리팩터(forge·renew 한정, 옵션·동작불변) → 보안 검증.

엔진은 두 실행 모드를 가진다 — **linear**(기본, 단일세션) / **orchestrated**(멀티에이전트 council, 명시 요청 시). 사용법은 [`docs/guides/craft-modes.md`](docs/guides/craft-modes.md).

---

## 에이전트 (재사용 서브에이전트)

[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) 에서 큐레이트해 이 레포 컨벤션에 맞게 적응한 6종. 플랫 `.md` 파일로 `~/.claude/agents/` 에 설치된다 (스킬과 별개 아티팩트). 코드 워크플로 역할군 — orchestrated 모드가 실제 spawn 하는 역할에 정렬.

| 에이전트 | 역할 | model |
|---|---|---|
| [`executor`](agents/executor.md) | 스코프 구현 (최소 diff) | sonnet |
| [`code-reviewer`](agents/code-reviewer.md) | severity 등급 코드 리뷰 | opus |
| [`security-reviewer`](agents/security-reviewer.md) | 취약점 탐지 (OWASP·secrets) | opus |
| [`test-engineer`](agents/test-engineer.md) | 테스트 전략·커버리지·TDD | sonnet |
| [`debugger`](agents/debugger.md) | 근본원인 분석·빌드 에러 해소 | sonnet |
| [`explore`](agents/explore.md) | 코드베이스 탐색·패턴 검색 | haiku |

> 원본의 oh-my-claudecode 플러그인 결합(네임스페이스 Task 호출·`.omc/` 경로·consensus 모드·미import 에이전트 핸드오프)은 제거/일반화했다. 결정 배경은 [`docs/adr/001-agents-as-second-artifact-type.md`](docs/adr/001-agents-as-second-artifact-type.md).

---

## 설치

### 전체 설치

```bash
git clone https://github.com/skdkfk8758/carpdm-skills.git
cd carpdm-skills
bash install.sh
```

12개 스킬을 `~/.claude/skills/`, 6개 에이전트를 `~/.claude/agents/` 로 복사한다. 기존 동일 이름은 `.bak-<timestamp>` 백업 후 덮어씀 (멱등). 설치 후 Claude Code **재시작**.

### 개별 설치 (하나씩)

```bash
# 예: handoff 만
cp -R skills/handoff ~/.claude/skills/

# 예: forge 만 — craft-core 도 같이 (의존)
cp -R skills/forge skills/craft-core ~/.claude/skills/
```

> ⚠️ **forge / hunt / renew / reshape / deep-plan 은 craft-core 가 반드시 함께 있어야 한다.** 내부에서 `~/.claude/skills/craft-core/references/...` 를 절대경로로 참조하기 때문 (deep-plan 은 deep-interview 의 references 도 차용). handoff / sweep / land / summon / deep-prompt 은 단독 설치 가능.

---

## 전제 / 의존성

| 항목 | 필수? | 설명 |
|---|---|---|
| Claude Code | ✅ | 스킬은 Claude Code Skill 기능 위에서 동작 |
| 설치 경로 `~/.claude/skills/` | ✅ 고정 | 다른 위치면 craft-core 엔진을 못 찾아 깨짐 |
| **craft-core** | ✅ | 파이프라인 4종 + deep-plan 공유 엔진. 빼면 5개 전부 동작 불가 |
| **`codex:rescue` 플러그인** | ⚠️ 권장 | Phase 2(적대 플랜 리뷰)가 호출. 없으면 그 단계는 수동 대체/생략. handoff 는 무관 |

`~` 절대경로는 사용자별 전개되므로 어느 머신이든 `~/.claude/skills/` 설치면 동작.

---

## 사용법

```
# 자연어 — 의도 감지 자동 발화
"ai ask 엔드포인트에 streaming 추가해줘"        → forge
"벤치가 500 던져, 고쳐줘"                        → hunt
"이 컨트롤러 핸들러 추출해서 정리해줘"           → reshape
"대시보드 어떻게 만들지 플랜이랑 UI 시안 줘"     → deep-plan (빌드 X)
"여기까지 하자, 내일 이어서 정리해줘"            → handoff (저장)
"어제 하던 거 어디까지 했지"                      → handoff (복원)

# 슬래시 명시 호출
/forge   /hunt   /renew   /reshape
```

handoff 는 **양방향 자동 감지** (작업 끝/중단 = 저장, 세션 시작/재개 = 복원). 파이프라인 4종은 **언더트리거 설계**(과발화 방지) — 확실히 원하면 슬래시 명시 호출 권장.

---

## 검증 / 트러블슈팅

```bash
ls ~/.claude/skills/   # forge hunt renew reshape deep-interview deep-plan deep-prompt handoff sweep land summon craft-core
ls ~/.claude/agents/   # executor code-reviewer security-reviewer test-engineer debugger explore (*.md)
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

`sync.sh` 는 **레포가 추적 중인 것만** 갱신한다 (true mirror, 삭제 파일 반영) — 스킬은 `skills/` 의 디렉토리별, 에이전트는 `agents/` 의 플랫 `.md` 집합. 새 스킬 배포 시작은 `skills/<name>/` 디렉토리를, 에이전트는 `agents/` 디렉토리를 먼저 만든 뒤 sync.

`--push` 는 `chore/sync-<timestamp>` 브랜치를 만들어 PR 생성·머지까지 한다 (`gh` CLI 필요). master 직접 push 를 막는 브랜치 보호 환경에서도 동작.
