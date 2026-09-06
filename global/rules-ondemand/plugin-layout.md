# 플러그인 레이아웃 · 업데이트 — 온디맨드 룰

플러그인(마켓플레이스 배포 스킬)의 **설치 실체가 어디 있고, 무엇이 진실인가**. 스킬 저작
레포(`carpdm-skills`)와 달리 이쪽은 `install.sh` 가 아니라 `claude plugin` CLI 가 관리한다.

## 1. 어디를 보는가 (navigation)

| 알고 싶은 것 | 파일 |
|---|---|
| 무엇이 설치돼 있고 **어느 커밋인가** (ground truth) | `~/.claude/plugins/installed_plugins.json` → `gitCommitSha` |
| 마켓플레이스가 가리키는 **최신 pin** | `~/.claude/plugins/marketplaces/<mp>/.claude-plugin/marketplace.json` → 해당 plugin 의 `source.sha` |
| 설치된 스킬 **본문** | `~/.claude/plugins/cache/<mp>/<plugin>/<version>/skills/**/SKILL.md` |
| 어떤 마켓플레이스가 어느 GitHub repo 인가 | `~/.claude/plugins/known_marketplaces.json` |
| 스킬 on/off | `~/.claude/settings.json` → `skillOverrides` (`"off"`), `enabledPlugins` |

**버전 문자열(`1.2.3`)은 진실이 아니다.** 같은 버전으로 내용이 바뀐다 — 비교는 항상
`gitCommitSha` ↔ marketplace `source.sha`.

## 2. 업데이트 — `plugin update` 는 거짓 "최신" 을 낸다

`claude plugin update <p>@<mp>` 는 **version 문자열만** 보고 `already at the latest
version` 을 반환한다. 마켓플레이스 pin(sha)이 앞서 있어도 그렇다 — 실측(2026-09-05):
`mattpocock-skills` 가 pin `5b15a47` → `6654f6b` 로 이동했는데 버전은 양쪽 다 `1.2.3`
이라 update 가 거절했다.

강제 갱신:
```bash
claude plugin marketplace update <mp>          # 먼저 pin 을 당겨온다
claude plugin uninstall <plugin>@<mp>
claude plugin install   <plugin>@<mp>
```
갱신 확인은 `installed_plugins.json` 의 `gitCommitSha` 가 marketplace `source.sha` 와
같아졌는지로 한다 — CLI 의 성공 메시지는 sha 를 말하지 않는다.

**새로 설치된 스킬은 그 세션에서 못 쓴다** — Claude Code 재시작 후에 로드된다.

## 3. 스킬이 목록에 안 보이는 이유 3가지

1. `disable-model-invocation: true` — 모델 목록에 안 뜨고 **사용자 슬래시 호출 전용**
   (맷포콕 풀은 절반 이상이 이렇다: `retro`·`to-tickets`·`triage`·`wayfinder`…).
2. `settings.json` `skillOverrides` 에서 `"off"`.
3. 설치 직후 재시작 전.
