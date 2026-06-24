# global/ — `~/.claude/` 글로벌 설정 미러

이 트리는 머신 전역 Claude Code 설정(`~/.claude/` 의 룰·훅·settings)의 **버전관리 미러**다.
`skills/`(sync.sh 가 자동 미러)와 달리, 여기는 **수동 미러** — `~/.claude/` 가 SSOT 이고
변경 시 손으로 이쪽에 반영해 커밋한다.

## 경로 매핑

| repo | 라이브 (SSOT) |
|---|---|
| `global/rules/*.md` | `~/.claude/rules/*.md` |
| `global/hooks/guards/*.sh` | `~/.claude/hooks/guards/*.sh` |
| `global/settings.json` | `~/.claude/settings.json` |

## 규칙

- SSOT 는 `~/.claude/` 라이브. repo 는 백업·이력·리뷰용.
- `settings.json` 은 민감정보(token/secret) 0 인 것만 미러 — 커밋 전 grep 확인.
- sync.sh 범위 밖(skills 전용). 여기 동기화는 수동.
