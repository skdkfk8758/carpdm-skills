# global/ — `~/.claude/` 글로벌 설정 미러 (전수)

이 트리는 머신 전역 Claude Code 설정(`~/.claude/` 의 룰·훅·settings·CLAUDE.md)의
**버전관리 미러**다. `~/.claude/` 라이브가 SSOT — 이 트리는 백업·이력·리뷰·**팀원
동일 셋업 재현**용이다. 2026-08-01 부로 부분("손댄 것만") 미러에서 **전수 미러**로
전환 — 팀원이 clone 후 스킬(`install.sh`)만 설치하면 행동 규율(rules·guards)이
통째로 빠진 환경이 되는 갭이 근거.

## 설치 (팀원 셋업)

```bash
bash install.sh                 # 자작 배포 스킬 → ~/.claude/skills/
bash install-global.sh          # 이 트리 → ~/.claude/ + ~/.codex/ (rules·hooks·settings·skills-extra·codex)
bash global/setup/replicate.sh  # 파일 밖 환경 — MCP 등록·플러그인 설치·codex 런타임(npm)
```

`install-global.sh` 는 관리 목록만 복사한다(다른 `~/.claude/` 파일 무접촉).
내용이 다른 기존 파일은 `~/.claude/backups/global-install-<ts>/` 백업 후 덮어쓰고,
`settings.json` 의 `<FILL-ME>` placeholder 는 로컬 실값이 있으면 보존한다(재실행 안전).
`~/.codex/config.toml` 은 기존 파일이 있으면 보존(신규 머신에만 설치).

설치 후: ① `settings.json`·`~/.codex/config.toml` 의 `<FILL-ME>` 채우기,
② `~/.claude/linear-repo-map.json` 의 repo 경로를 자기 머신 경로로 수정,
③ MCP OAuth(Linear — 첫 사용 시 브라우저 승인, Claude·codex 각각), ④ Claude Code 재시작.

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
| `global/skills-extra/*/` | `~/.claude/skills/*/` | repo `skills/` 미추적 스킬 전수(서드파티 포함 — 환경 재현용, 자작 배포는 `skills/`+`sync.sh`) |
| `global/linear-repo-map.json` | `~/.claude/linear-repo-map.json` | Linear 팀 라우팅 SSOT(경로는 머신별 수정) |
| `global/codex/{skills,agents,prompts}/` | `~/.codex/{skills,agents,prompts}/` | codex 형상 전수 |
| `global/codex/config.toml` | `~/.codex/config.toml` | secret 마스킹 후 · 설치는 신규 머신만 |
| `global/setup/replicate.sh` | (파일 아님 — 실행) | MCP·플러그인·npm 재현 명령(멱등) |

## 제외 (의도적 — 머신·개인 종속)

- `memory/`·`projects/` — 세션·프로젝트별 개인 기록.
- 플러그인 **본체**·캐시·로그류 — 파일 미러 대신 `setup/replicate.sh` 의 설치 명령으로 재현.
- `~/.claude.json` — MCP OAuth 토큰·세션 상태가 섞인 파일이라 통미러 금지. MCP 는
  `setup/replicate.sh` 의 `claude mcp add` 명령으로 재현(각자 OAuth).

## 규칙

- SSOT 는 `~/.claude/` 라이브. repo 에서 직접 고쳤으면 `install-global.sh` 로 라이브
  반영(스킬의 install/sync 양방향과 동형 — 마지막 동기화 방향 주의).
- secret 은 커밋 금지 — `sync-global.sh` 의 마스킹+스캔이 게이트. env 값 외의 새
  secret 형태가 생기면 스캔 패턴도 같이 확장할 것.
