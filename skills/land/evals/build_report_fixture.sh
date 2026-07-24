#!/usr/bin/env bash
# Build an OFFLINE fixture for testing `land`'s STEP 6 (Report) judgment.
#
# build_fixture.sh covers Steps 1-3 (classify → order → PLAN, stops at the gate).
# Everything after the gate — collection, residual verdict, conditional sections,
# card render — was untested. This fixture starts from a POST-merge state so the
# subagent's only job is to produce the REPORT.
#
# Mocked external state (offline, no gh / no Linear):
#   merged-prs.json   what `gh pr view <n> --json title,body,commits,files` would return
#   pr-state.json     PRs still open after the run (the skipped one)
#   worktree-list.txt `git worktree list`
#   linear-state.json linked issue + acceptance checkboxes
#   docs/handoff/…    a handoff doc whose "남은 작업" must be reconciled
#
# Two variants:
#   bash build_report_fixture.sh <dir>          # residual work remains  (default)
#   bash build_report_fixture.sh <dir> clean    # everything landed → completion path
#
# The subagent MUST NOT run gh/git-destructive commands — it reads the mocked
# state and emits the report text. Grade the REPORT, not the merges.
set -euo pipefail

DIR="${1:?usage: build_report_fixture.sh <target-dir> [clean]}"
VARIANT="${2:-residual}"
rm -rf "$DIR"
mkdir -p "$DIR"
cd "$DIR"

git init -q -b master
git config user.email "fixture@example.com"
git config user.name "Fixture"
echo "# app" > README.md
git add -A && git commit -qm "init"

# --- master already carries the squashed commits of #41, #43, #44 ---
echo login > login.txt
echo '{"lockfileVersion":3}' > package-lock.json          # #41 touched the lockfile
git add -A && git commit -qm "fix(auth): fix login redirect (#41)"

mkdir -p migrations docs/plans
echo "CREATE TABLE rate_limit (id serial);" > migrations/20260710120000_rate_limit.up.sql
echo "DROP TABLE rate_limit;" > migrations/20260710120000_rate_limit.down.sql
echo "# rate-limit plan" > docs/plans/2026-07-10-rate-limit.md
git add -A && git commit -qm "feat(api): add rate-limit middleware (#43)"

echo ui > ratelimit-ui.txt
git add -A && git commit -qm "feat(web): rate-limit config UI (#44)"

if [ "$VARIANT" != "clean" ]; then
  # rate-limit-ui survives ONLY because a worktree holds it → deletion deferred.
  git branch rate-limit-ui HEAD~1
  # refactor-auth: PR #46 skipped (CI failing) → ahead of master, not landed.
  git checkout -q -b refactor-auth
  echo auth > auth.txt && git add -A && git commit -qm "refactor auth pass 1"
  # experiment-x: survivor with no PR at all.
  git checkout -q master
  git checkout -q -b experiment-x
  echo exp > exp.txt && git add -A && git commit -qm "experiment"
  git checkout -q master
fi

# --- mocked: gh pr view <n> --json title,body,commits,files (merged PRs) ---
# #43 has a rich body (design link found). #44 was raised with `--fill` (body is
# just the commit subject) → the report must fall back to the commit title, and
# must NOT invent a design link.
cat > merged-prs.json <<'JSON'
[
  {
    "number": 41,
    "title": "fix(auth): fix login redirect",
    "body": "## 변경\n- 로그인 후 redirect 대상이 항상 `/` 로 가던 것 수정\n- 의존성 bump (package-lock.json)\n\n## 설계\ndocs/plans/2026-07-02-auth-redirect.md · ADT-31",
    "commits": [{"messageHeadline": "fix(auth): fix login redirect"}],
    "files": [{"path": "login.txt"}, {"path": "package-lock.json"}]
  },
  {
    "number": 43,
    "title": "feat(api): add rate-limit middleware",
    "body": "## 변경\n- 토큰 버킷 미들웨어 추가, 기본 60rpm\n- rate_limit 테이블 마이그레이션 동반\n\n## 설계\ndocs/plans/2026-07-10-rate-limit.md · ADT-33",
    "commits": [{"messageHeadline": "feat(api): add rate-limit middleware"}],
    "files": [
      {"path": "migrations/20260710120000_rate_limit.up.sql"},
      {"path": "migrations/20260710120000_rate_limit.down.sql"},
      {"path": "docs/plans/2026-07-10-rate-limit.md"}
    ]
  },
  {
    "number": 44,
    "title": "feat(web): rate-limit config UI",
    "body": "feat(web): rate-limit config UI",
    "commits": [{"messageHeadline": "feat(web): rate-limit config UI"}],
    "files": [{"path": "ratelimit-ui.txt"}]
  }
]
JSON

# --- mocked: Linear + handoff. These are the NON-git residual sources, so the
# `clean` variant must clear them too — otherwise the "all landed" fixture still
# has real residual work and the completion path can never be reached.
mkdir -p docs/handoff

if [ "$VARIANT" = "clean" ]; then
  # Every source drained: AC all checked, no open sibling, handoff fully consumed.
  cat > linear-state.json <<'JSON'
{
  "ADT-31": {"linkedPR": 41, "state": "Done", "body": "## 수용 기준\n- [x] redirect 대상이 원래 경로로 복귀\n- [x] 회귀 테스트 추가"},
  "ADT-33": {"linkedPR": 43, "state": "Done", "parent": "ADT-30",
             "body": "## 수용 기준\n- [x] 60rpm 초과 시 429\n- [x] 마이그레이션 파일 작성\n- [x] 대시보드 지표 노출"},
  "ADT-34": {"linkedPR": 44, "state": "Done", "parent": "ADT-30", "body": "rate-limit 설정 UI"}
}
JSON
  cat > docs/handoff/2026-07-10-rate-limit.md <<'MD'
# handoff — rate-limit

## 남은 작업
- rate-limit 미들웨어 구현 + PR (→ #43 으로 랜딩됨)
- config UI (→ #44 로 랜딩됨)
- 로그인 redirect 수정 (→ #41 로 랜딩됨)
MD
  cat > pr-state.json <<'JSON'
[]
JSON
  cat > worktree-list.txt <<TXT
$DIR              $(git rev-parse --short HEAD) [master]
$DIR/../wt-ratelimit-mw  def5678 [rate-limit-mw]   (merged, branch already deleted)
TXT
else
  # ADT-33 blocked on unchecked acceptance items; ADT-34 an open sibling under the
  # same parent; the handoff still lists prod migration as open.
  cat > linear-state.json <<'JSON'
{
  "ADT-31": {"linkedPR": 41, "state": "Done", "body": "## 수용 기준\n- [x] redirect 대상이 원래 경로로 복귀\n- [x] 회귀 테스트 추가"},
  "ADT-33": {"linkedPR": 43, "state": "In Review", "parent": "ADT-30",
             "body": "## 수용 기준\n- [x] 60rpm 초과 시 429\n- [ ] 마이그레이션 prod 적용\n- [ ] 대시보드 지표 노출"},
  "ADT-34": {"parent": "ADT-30", "state": "Todo", "body": "rate-limit 지표 대시보드"}
}
JSON
  cat > docs/handoff/2026-07-10-rate-limit.md <<'MD'
# handoff — rate-limit

## 남은 작업
- rate-limit 미들웨어 구현 + PR (→ #43 으로 랜딩됨)
- config UI (→ #44 로 랜딩됨)
- prod 마이그레이션 적용 — 아직
MD
  cat > pr-state.json <<'JSON'
[
  {"number":46,"title":"refactor auth","headRefName":"refactor-auth","baseRefName":"master","isDraft":false,"mergeable":"MERGEABLE","mergeStateStatus":"UNSTABLE","statusCheckRollup":[{"name":"ci","status":"COMPLETED","conclusion":"FAILURE"}]}
]
JSON
  cat > worktree-list.txt <<TXT
$DIR              $(git rev-parse --short HEAD) [master]
$DIR/../wt-ratelimit-ui  9abcdef [rate-limit-ui]
$DIR/../wt-experiment    0fedcba [experiment-x]
TXT
fi

cat > defaultBranch.txt <<'TXT'
master
TXT

echo "report fixture built at $DIR  (variant: $VARIANT)"
echo "  merged: #41 (deps/lockfile) #43 (migration + plan link) #44 (--fill body → title fallback)"
if [ "$VARIANT" = "clean" ]; then
  echo "  residual: NONE → report must declare 완료 + 권장 행(wt-sweep / linear-prioritize)"
else
  echo "  residual: #46 CI-fail skipped · refactor-auth ahead · experiment-x no-PR ·"
  echo "            rate-limit-ui deletion deferred (worktree) · ADT-33 AC 2건 미체크 · handoff prod 마이그 미완"
fi
