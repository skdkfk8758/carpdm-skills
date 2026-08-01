# global/ — `~/.claude/` 글로벌 설정 미러 (전수)

이 트리는 머신 전역 Claude Code 설정(`~/.claude/` 의 룰·훅·settings·CLAUDE.md)의
**버전관리 미러**다. `~/.claude/` 라이브가 SSOT — 이 트리는 백업·이력·리뷰·**팀원
동일 셋업 재현**용이다. 2026-08-01 부로 부분("손댄 것만") 미러에서 **전수 미러**로
전환 — 팀원이 clone 후 스킬(`install.sh`)만 설치하면 행동 규율(rules·guards)이
통째로 빠진 환경이 되는 갭이 근거.

## 설치 (팀원 셋업)

```bash
bash install.sh          # 스킬 25종 → ~/.claude/skills/
bash install-global.sh   # 이 트리 → ~/.claude/ (rules·hooks·settings·CLAUDE.md)
```

`install-global.sh` 는 관리 목록만 복사한다(다른 `~/.claude/` 파일 무접촉).
내용이 다른 기존 파일은 `~/.claude/backups/global-install-<ts>/` 백업 후 덮어쓰고,
`settings.json` 의 `<FILL-ME>` placeholder 는 로컬 실값이 있으면 보존한다(재실행 안전).

설치 후: ① `settings.json` 의 `<FILL-ME>` 채우기(또는 해당 env 제거), ② Linear 쓰면
`~/.claude/linear-repo-map.json` 직접 작성(아래 제외 목록), ③ Claude Code 재시작.

## 동기화 (라이브 → repo)

```bash
bash sync-global.sh      # 전수 미러 + settings secret 마스킹 + 커밋 전 secret 스캔
```

rules·rules-ondemand·hooks/guards 는 `--delete` strict 미러(라이브에서 지운 룰은
repo 에서도 빠짐 — git history 가 안전망). 새 스크립트 편입은 수동 결정(NOTE 안내).
스캔이 secret 의심 패턴을 잡으면 exit 1 — 마스킹 없이 커밋되지 않게.

## 경로 매핑

| repo | 라이브 (SSOT) | 범위 |
|---|---|---|
| `global/CLAUDE.md` | `~/.claude/CLAUDE.md` | 글로벌 지침 본체 |
| `global/rules/*.md` | `~/.claude/rules/*.md` | 전수 (상시 로드 룰) |
| `global/rules-ondemand/*.md` | `~/.claude/rules-ondemand/*.md` | 전수 (JIT 룰) |
| `global/hooks/guards/*.sh` | `~/.claude/hooks/guards/*.sh` | 전수 (가드 훅) |
| `global/hooks/*.{sh,py}` | `~/.claude/hooks/*.{sh,py}` | settings 가 참조하는 것 |
| `global/scripts/*` | `~/.claude/scripts/*` | 훅·automation 이 참조하는 것 |
| `global/statusline.sh` | `~/.claude/statusline.sh` | settings 참조 |
| `global/linear-issue-goal-template.md` | 동명 | linear-goal 스킬 참조 |
| `global/settings.json` | `~/.claude/settings.json` | secret 마스킹(`<FILL-ME>`) 후 |

## 제외 (의도적 — 머신·개인 종속)

- `linear-repo-map.json` — Linear 팀 ↔ **로컬 절대경로** 매핑이라 머신 종속.
  각자 자기 워크스페이스 경로로 작성(구조는 파일 상단 `_doc` 주석이 자기기술 —
  뼈대는 `teamRoutes[]`: `{teamKey, teamId, repo}` 배열).
- `memory/`·`projects/` — 세션·프로젝트별 개인 기록.
- `plugins/`·`commands/`·캐시·로그류 — 각자 설치/생성.

## 규칙

- SSOT 는 `~/.claude/` 라이브. repo 에서 직접 고쳤으면 `install-global.sh` 로 라이브
  반영(스킬의 install/sync 양방향과 동형 — 마지막 동기화 방향 주의).
- secret 은 커밋 금지 — `sync-global.sh` 의 마스킹+스캔이 게이트. env 값 외의 새
  secret 형태가 생기면 스캔 패턴도 같이 확장할 것.
