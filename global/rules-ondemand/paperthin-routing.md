# paperthin Routing — 언제 어떤 스킬로 가는가

> paperthin 28종은 `~/.agents/skills/` 관리 설치 + `~/.claude/skills/<name>` 심링크.
> 목록·설치 상태 확인은 `/re0-upgrade` (변경 전 승인 게이트 있음).
>
> **핵심 구분 하나**: 16종은 description 을 달고 있어 모델이 알아서 발동한다.
> 나머지 12종은 `disable-model-invocation: true` — **사용자가 `/이름` 을 직접 쳐야만 뜬다.**
> 모델이 할 수 있는 최선은 "지금 이걸 치세요"라고 제안하는 것뿐이다. 그 제안을
> 놓치지 않게 하는 장치가 `hooks/guards/guard-paperthin-nudge.sh`.

## 1. 사용자가 직접 쳐야 하는 12종 (모델 자동 발동 불가)

| 명령 | 언제 | 왜 유저 전용인가 |
|---|---|---|
| `/hate` | 계획·설계·논증을 실제 공수 들이기 **직전** | 파괴 반사가 상시면 모델이 철거 쪽으로 편향된다 |
| `/prism` | 실패 모드가 이질적이라 리뷰어 하나로 부족할 때 | 렌즈 2~5개 수렴/불일치 + 그걸 가를 질문 1개 |
| `/feynman` | 선택지를 **막 고른 직후** | 이해는 결정 직후가 가장 위조하기 쉽다 |
| `/macrothink` | 세션이 한 방향으로 굳었다고 의심될 때 | 세션 미끼 제거 후 fresh read 팬아웃, 수렴을 증거로 안 침 |
| `/debloat` | 내용은 맞는데 문서가 부풀었을 때 | 재작성 아님 — 의미 보존 압축 |
| `/reorder` | 목록·표·enum·섹션 순서가 임의로 흐트러졌을 때 | 항목 이동만, 문구·추가·삭제 없음 |
| `/dedash` | em-dash 를 걷어낼 때 | **주의: 이 환경의 한국어 지침·문서는 `—` 를 의도적으로 쓴다. 유저가 명시 요청할 때만.** |
| `/re0-git` | 커밋 직후 메시지를 핸드오프 가능한 형태로 | `git log` 만으로 이야기가 되게 |
| `/re0-release` | 출시하기로 결정했을 때 | 레포 shipping 체크리스트 → 태그·퍼블리시 |
| `/re0-merge` | 외부 기여 PR 을 리뷰·랜딩할 때 | 저자 크레딧 보존 + thesis 게이트 |
| `/re0-plan` · `/re0-upgrade` | paperthin 레포 자체 사이클 / 스킬 카탈로그 동기화 | 이 인프라 레포들에는 `/re0-upgrade` 만 해당 |

## 2. 모델이 알아서 발동하는 16종 — 별도 조치 불필요

`readchk`(지시 이해 확인) · `aim`(얇은 요청+데이터) · `modelchk`(모델/effort 사이징) ·
`autobahn`(가드레일 인접 작업 분리) · `factchk`(현실 주장 검증) · `mandela`(eval 누수 감사) ·
`sip`(산출물 자가 시식) · `shower`(무맥락 콜드리드) · `ssotize`(SSOT 통합) ·
`catchup`(복귀 브리핑) · `nba`(다음 최선 행동) · `detool`(벤더 명사 제거) ·
`re0` · `re0-loop` · `re0-memo` · `re0-work`

발동이 **안 뜨는데 필요하다** 싶으면 그건 이 파일 문제가 아니라 그 스킬 description 문제다.

## 3. 훅이 거는 넛지

`guard-paperthin-nudge.sh` (PostToolUse: Write|Edit, stderr, 비차단):

- **판단 산출물** — `docs/{specs,plans,reviews}/*.md` · `.planning/*.md` · `wiki/adr/*.md` ·
  `SPEC|PLAN|DESIGN|ADR|RFC*.md` · `*-{plan,spec,design,proposal}.md`
  → `/hate` `/prism` `/feynman` `/macrothink` 중 **하나를 골라** 제안.
- **문서 비대** — `docs/` · `wiki/` · `README.md` 중 200줄 초과 → `/debloat` `/reorder`.
- (session_id, kind, path) 당 1회만. 같은 계획 문서를 반복 수정해도 재발화 안 함.
- 끄기: `GUARD_PAPERTHIN_NUDGE_DISABLE=1`.

## 4. 제안 규율 — 넛지를 받았을 때 모델이 하는 것

1. **하나만 고른다.** 4개를 나열해 사용자에게 고르라고 미루는 건 넛지를 소음으로 만든다.
2. **왜 이것인지 한 줄** 을 붙인다 — "실패 모드가 보안·비용으로 갈려서 `/prism`" 처럼.
3. **작업을 멈추지 않는다.** 제안은 턴 마지막 한 줄이다. 승인 게이트가 아니다.
4. 사용자가 무시하면 **같은 턴 흐름에서 다시 꺼내지 않는다.**

## Related

- 글로벌 `CLAUDE.md` §온디맨드 룰 라우팅 — 이 파일로 들어오는 입구
- `knowledge-folders.md` — 넛지가 감지하는 `docs/` · `wiki/` 경로 규약의 SSOT
