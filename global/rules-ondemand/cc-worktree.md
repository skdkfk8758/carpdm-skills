# cc-worktree — 워크트리 웹개발 환경 (포트/도메인/.env)

IMPORTANT: 사용자(macOS + Homebrew)는 git worktree 로 웹페이지를 병렬 작업한다. 포트 충돌·다중 URL·워크트리별 `.env` 부재 문제를 **`~/.config/cc-worktree/` 툴킷**으로 해결해 두었다. 관련 질문이 오면 새로 설계하지 말고 이 툴킷으로 안내한다. 상세는 on-demand 로 `~/.config/cc-worktree/README.md` 를 Read.

## 무엇을 하나

- **결정론적 포트** — 워크트리 디렉토리명 해시 → 3000-3999 고정. 같은 워크트리 = 늘 같은 포트.
- **이름 도메인** — `https://<워크트리명>.test` (Caddy reverse_proxy + 로컬 CA trust + dnsmasq `*.test`). host 분리라 워크트리끼리 **쿠키/세션 독립**.
- **로컬 설정 자동 복사** — `git worktree add` 시 git `post-checkout` 훅이 메인 워크트리의 `.env*` **와 `.infisical.auth`** 를 새 워크트리로 복사(없는 것만). Claude Code 의 git 워크트리는 `WorktreeCreate` 훅을 안 타므로 post-checkout 을 쓴다. 대상 목록은 훅의 `names=()` 한 줄 — gitignored 라 checkout 이 절대 가져다주지 않는 것만 넣는다(`.infisical.json` 은 tracked 라 불필요).
  - **형제 워크트리 prune 은 등록 경로 기반**(`git worktree list --porcelain`). 경로 패턴 하드코딩 금지 — repo 마다 워크트리 배치가 다르다(`.claude/worktrees/` vs repo 루트 직하). 2026-07-20 이전 훅은 `.claude/worktrees/*` 만 제외해, 루트 직하 배치 repo 에서 형제 워크트리의 `.env*` 를 긁어 디렉터리 스켈레톤을 만들었고 이게 세대마다 증식했다(실측: 한 워크트리에 25,991 파일·174M, `worktree add` 2분+ → 수정 후 1.2초). ADType-Intelligence ADT-359.

## 명령 (이대로 안내)

| 상황 | 명령 |
|---|---|
| 새 맥 1회 세팅 | `bash ~/.config/cc-worktree/bootstrap.sh` + 출력된 sudo 4줄 |
| 새 프로젝트 온보딩 | `cd <프로젝트> && bash ~/.config/cc-worktree/setup-project.sh` |
| 기존 repo 들에 .env 훅 일괄 | `bash ~/.config/cc-worktree/install-worktree-hook.sh ~/Workspace/*` |
| 워크트리에서 dev 기동 | `cd <워크트리> && dev` → `https://<워크트리명>.test` |

## 스택 계약 (포트)

dev 서버가 **`PORT` env 를 따라야** 결정론적 포트가 적용된다.
- **Next / CRA / Remix / Nuxt** — 기본으로 PORT 먹음. 그대로 `dev`.
- **Vite / SvelteKit** — `vite.config` `server.port: Number(process.env.PORT) || <기본>` 필요. `setup-project.sh` 가 자동 패치(애매하면 수동 안내).
- 안 따르면 caddy(→해시포트)와 서버 포트 불일치로 **502**.

## 한계 (고지)

- **husky repo — git 훅으로는 못 고친다(체인도 무효).** husky 가 `core.hooksPath=.husky/_` 를 소유하고 그 디렉토리는 install 때 생성되므로, 갓 추가한 워크트리엔 shim 이 없어 `worktree add` 시점에 git 이 **훅을 하나도 실행하지 않는다**. `.husky/post-checkout` 체인을 넣어도 그걸 호출할 `_/` 가 없어 안 돈다(2026-07-30 실측, ADMap). **해법은 install 시점 연결** — 새 워크트리는 node_modules 비공유라 반드시 install 을 거치므로, root `prepare` 에서 `post-checkout --now`(훅 프로토콜 밖 직접 실행)를 호출한다. tracked 스크립트 + 툴킷 미설치 시 `exit 0` 가드. 선례: ADMap `scripts/worktree-local-config.sh`(PR #577).
- **lefthook / 자체 post-checkout 보유 repo** — installer `SKIP-own`. hooksPath 가 tracked 디렉토리면(예: `.githooks/`) 심볼릭이 붙어 동작하나 `git status` untracked 노이즈 → `.git/info/exclude` 로 로컬 제외.
- macOS/Homebrew 전용. caddy·dnsmasq 는 root brew service, 로컬 CA 는 키체인 trust 필요(bootstrap 가 sudo 단계 출력).

## SSOT

훅 로직은 `~/.config/cc-worktree/post-checkout` 단일 파일(모든 repo 가 이걸 심볼릭). 동작 변경은 이 파일만 수정.
