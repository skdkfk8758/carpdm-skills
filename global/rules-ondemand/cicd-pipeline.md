# cicd-pipeline — Node monorepo CI/CD 템플릿 포인터

IMPORTANT: 사용자는 동질 스택(Node 20 monorepo · npm · GitHub Packages private registry · Docker→AWS ECR · SSH 배포 · OIDC)의 프로젝트들에 **동일한 CI/CD 파이프라인**을 반복 적용한다. 새 프로젝트의 CI/CD·GitHub Actions·배포 파이프라인을 세팅하는 질문이 오면 새로 설계하지 말고 **`~/.config/cicd-template/` 툴킷**으로 안내한다. 상세는 on-demand 로 `~/.config/cicd-template/README.md` 를 Read.

## 무엇을 제공하나

- **재사용 워크플로 SSOT** (`deploy.yml`) — `test→build(ECR push)→deploy(SSH)`. dev/prod 가 `environment` 키만 바꿔 호출.
- **5 워크플로 템플릿** — `ci.yml`(PR 게이트) / `deploy.yml` / `deploy-dev.yml`(develop→dev 자동) / `release.yml`(v*→prod 승인) / `audit.yml`.
- **`__NAME__` 플레이스홀더** + 치환 체크리스트 + GitHub Environment/secret/OIDC 셋업 가이드.

## 적용 (이대로 안내)

```bash
cp ~/.config/cicd-template/workflows/*.yml <project>/.github/workflows/
# README §치환 체크리스트대로 sed 치환 → 안 쓰는 선택 step 삭제 → GitHub secret/env 설정
```

## 설계 불변식 (바꾸지 말 것)

- 태그: prod 만 `latest`(롤백 대상), dev 는 `dev` rolling — 침범 금지.
- OIDC push(정적키 0) / 서버 pull 만 IAM key.
- `DEPLOY_ENABLED` 게이트는 **step-level**(environment var 는 job-level if 미해결).
- 전 workspace 타입체크(root build + api:build) — 사각 차단.

## 한계

PRIVATE repo + GitHub Pro 미보유 → branch protection 403 → CI red 여도 머지차단 불가(advisory). `~/.claude/rules/branch-worktree-strategy.md` §8.

## Related

- `~/.claude/rules/branch-worktree-strategy.md` — 브랜치/워크트리 컨벤션 (본 파이프라인의 전략 짝).
- `~/.config/cicd-template/README.md` — 치환·GitHub 설정 상세 (SSOT).
- 원형 인스턴스: ADMap-Intelligence `.github/workflows/` + `docs/adr/041`.
