# carpdm-skills

Claude Code 글로벌 스킬 배포 레포. **작업 유형별 엄격 파이프라인 4종 + 세션 인계 1종 + 공유 엔진 1종.**

| 스킬 | 용도 | 트리거 (자연어로도 발화) | 의존 |
|---|---|---|---|
| [`forge`](skills/forge) | 새 기능 구현 (0→1) | "X 추가/구현/만들어줘" | craft-core |
| [`hunt`](skills/hunt) | 버그 수정 (재현→회귀잠금) | "X 깨졌어", "왜 null 반환하지" | craft-core |
| [`renew`](skills/renew) | 기존 기능 변경/리뉴얼 | "X 다시 만들어", "동작 바꿔줘" | craft-core |
| [`reshape`](skills/reshape) | 리팩터 (동작 불변) | "정리/추출/분리/DRY 해줘" | craft-core |
| [`handoff`](skills/handoff) | 세션 인계 (저장/복원) | "여기까지 하자 이어서", "어디까지 했지" | 없음 (독립) |
| [`craft-core`](skills/craft-core) | ⚙️ 공유 엔진 (직접 호출 X) | forge/hunt/renew/reshape 가 내부에서 읽음 | — |

**파이프라인 4종 공통 흐름**: 소크라테스 인터뷰 → codex 적대적 플랜 리뷰 → 동적 워크플로 TDD(sonnet) → 보안 검증.

---

## 설치

### 전체 설치

```bash
git clone https://github.com/skdkfk8758/carpdm-skills.git
cd carpdm-skills
bash install.sh
```

6개 스킬을 `~/.claude/skills/` 로 복사한다. 기존 동일 이름은 `.bak-<timestamp>` 백업 후 덮어씀 (멱등). 설치 후 Claude Code **재시작**.

### 개별 설치 (하나씩)

```bash
# 예: handoff 만
cp -R skills/handoff ~/.claude/skills/

# 예: forge 만 — craft-core 도 같이 (의존)
cp -R skills/forge skills/craft-core ~/.claude/skills/
```

> ⚠️ **forge / hunt / renew / reshape 는 craft-core 가 반드시 함께 있어야 한다.** 내부에서 `~/.claude/skills/craft-core/references/...` 를 절대경로로 참조하기 때문. handoff 는 단독 설치 가능.

---

## 전제 / 의존성

| 항목 | 필수? | 설명 |
|---|---|---|
| Claude Code | ✅ | 스킬은 Claude Code Skill 기능 위에서 동작 |
| 설치 경로 `~/.claude/skills/` | ✅ 고정 | 다른 위치면 craft-core 엔진을 못 찾아 깨짐 |
| **craft-core** | ✅ | 파이프라인 4종 공유 엔진. 빼면 4개 전부 동작 불가 |
| **`codex:rescue` 플러그인** | ⚠️ 권장 | Phase 2(적대 플랜 리뷰)가 호출. 없으면 그 단계는 수동 대체/생략. handoff 는 무관 |

`~` 절대경로는 사용자별 전개되므로 어느 머신이든 `~/.claude/skills/` 설치면 동작.

---

## 사용법

```
# 자연어 — 의도 감지 자동 발화
"ai ask 엔드포인트에 streaming 추가해줘"        → forge
"벤치가 500 던져, 고쳐줘"                        → hunt
"이 컨트롤러 핸들러 추출해서 정리해줘"           → reshape
"여기까지 하자, 내일 이어서 정리해줘"            → handoff (저장)
"어제 하던 거 어디까지 했지"                      → handoff (복원)

# 슬래시 명시 호출
/forge   /hunt   /renew   /reshape
```

handoff 는 **양방향 자동 감지** (작업 끝/중단 = 저장, 세션 시작/재개 = 복원). 파이프라인 4종은 **언더트리거 설계**(과발화 방지) — 확실히 원하면 슬래시 명시 호출 권장.

---

## 검증 / 트러블슈팅

```bash
ls ~/.claude/skills/   # forge hunt renew reshape handoff craft-core
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
bash sync.sh --push    # 미러링 + 커밋 + push 까지 한 번에
```

`sync.sh` 는 **레포 `skills/` 가 추적 중인 스킬만** 갱신한다 (true mirror, 삭제 파일 반영). 새 스킬 배포 시작은 `skills/<name>/` 디렉토리를 먼저 만든 뒤 sync.
