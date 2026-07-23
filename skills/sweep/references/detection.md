# Detection 휴리스틱

정리 후보를 찾는 카테고리별 규칙. 각 히트는 일치하는 경로만이 아니라 **staleness
의 증거**를 지녀야 한다. 모든 히트가 복구 계층(tracked / untracked)을 갖도록
`git ls-files` 와 `git status` 를 처음에 한 번 실행하라.

목차:
- [1. Stale point-in-time docs](#1-stale-point-in-time-docs)
- [2. Volatile logs](#2-volatile-logs)
- [3. Orphan / duplicate docs](#3-orphan--duplicate-docs)
- [4. Build / tmp leftovers](#4-build--tmp-leftovers)
- [Cross-cutting: never-touch guard](#cross-cutting-never-touch-guard)

## 1. Stale point-in-time docs

위치: `docs/plans/`, `docs/handoff/`, `docs/reports/`, `docs/reviews/`,
`docs/runbooks/`, `docs/benchmarks/`, `docs/solutions/`, `docs/_archive/`.

Staleness 증거(최소 하나 필요; 많을수록 확신 높음):

- **과거의 날짜 파일명** — `docs/plans/YYYY-MM-DD-*.md` 에서 날짜가 오늘보다 한참
  뒤처진 것. 같은 주제의 가장 최근 plan 보다 오래된 plan 은 대체되었을 가능성이
  높다.
- **랜딩된 작업** — 기술된 작업이 끝난 `handoff/` 또는 `plans/` 문서. 비가역
  삭제(특히 untracked handoff = 복구 불가)이므로 인상이 아니라 **관찰 가능한
  3증거**를 요구한다(db-drop-preflight 동형): (1) 대상 산출물 존재 — 언급된
  파일/심볼을 `git grep -F` 로 확인, (2) 머지 커밋 존재 —
  `git log --oneline -- <target>` 히트 또는 연결 이슈 Done, (3) 열린 체크박스
  0 — 문서에 미완 항목이 남아 있지 않음. 3증거를 못 채우면 *제안 말고*
  "flagged, not proposed" 로 강등한다. YAGNI 규칙에 따라 출시된 handoff 는 삭제
  대상이지만, 증거가 문턱이다.
- **대체됨** — 같은 주제의 문서 둘; 오래된 게 후보, 새 게 남는다. 날짜만이
  아니라 둘 다 읽어 확인하라.
- **이미 archive 됨** — `docs/_archive/` 아래 무엇이든 정의상 은퇴한 것이다;
  제안하라(tracked → 복구 가능) — 단 유저가 `_archive` 를 장기 cold storage 로
  쓰는 경우는 예외(불확실하면 물어보라).

유용한 명령(증거를 읽되 행동하지 말 것):
```bash
git -C <repo> log --oneline -5 -- docs/plans/<file>      # was its work merged?
git ls-files docs/plans docs/handoff docs/reports        # tracked candidates
ls -lt docs/handoff                                       # oldest-last by mtime
```

stale 로 취급하지 말 것: 활성 SPEC (`docs/specs/`), 미래 날짜나 열린 체크박스를
가진 plan, `docs/_index/index.md` 에서 참조되는 report.

## 2. Volatile logs

위치: `logs/` (특히 `logs/qa/`, `logs/agents/`), `*.status.log`.

- `logs/qa/` 는 컨벤션상 **7일 GC 윈도우**를 가진다 — 7일보다 오래된 파일이 1순위
  후보.
- `logs/agents/*.log`, `*.status.log` — agent 실행 scratch, 거의 항상 휘발성.
- 이것들은 보통 **untracked → 복구 불가**다. 그 계층을 큰소리로 flag 하라.
- `logs/` 가 계속 출력돼야 한다면, 디렉토리 자체를 삭제하기보다 `.gitignore` 되어
  있는지 확인하는 쪽을 선호하라 — 삭제해 봐야 다음 실행이 다시 만든다.

```bash
find logs -type f -mtime +7 2>/dev/null     # older than 7 days
git check-ignore logs/qa/ || echo "logs/qa NOT gitignored"
```

## 3. Orphan / duplicate docs

- **고아(Orphan)** — 레포 어디에서도 참조되지 않는 시점 기록 문서. 판정은
  portal 단독이 아니라 **레포 전체 cross-reference** 로 한다:
  `git grep -l -F "<basename>" -- ':!<self>'` 로 docs 전체·코드·rules 주석에서
  참조를 찾고, 히트가 있으면(살아 있음) *제안 말고* "flagged, not proposed" 로
  강등한다. portal 부재는 그 자체로 고아 신호가 아니라 *고칠 portal gap* 신호일
  뿐 — knowledge sub-tree 든 시점 기록 문서든 portal 에 없다고 삭제 후보로 올리지
  말 것.
- **중복(Duplicate)** — 거의 동일한 내용 / 같은 SSOT 의 파일 둘. 컨벤션은 중복
  SSOT 를 금지한다; 정본을 남기고 사본을 제안하라.
- **빈 디렉토리** — 파일 없는 디렉토리(이전 이동 후 남은 경우가 많다).

판정용 grep 은 항상 **fixed-string**(`-F`)이다 — 파일명의 `.`·`_` 가 정규식으로
해석되면 유사명이 우연 히트해 고아/중복 판정이 뒤집힌다(verification-safety V2
동형: 리터럴을 패턴 자리에 escape 없이 넣지 말 것).

```bash
git grep -l -F "<basename>" -- ':!<self>' || echo "orphan: no repo-wide reference"  # -F = 리터럴
find docs -type d -empty
```

## 4. Build / tmp leftovers

- `*.bak-*` (`install.sh` 등이 만드는 타임스탬프 백업), `*.tmp`, `*.orig`, `*~`.
- Build 출력: `dist/`, `build/`, `out/`, `.next/`, `coverage/` — 단 프로젝트가
  이를 분명히 재생성할 때만(build 단계가 존재). 문서 전용이나 markdown 레포라면
  `build/` 디렉토리가 의미 있을 수 있다 — 가정하기 전에 확인하라.
- `tmp/`, `.cache/` scratch.
- 이것들은 보통 **untracked → 복구 불가**다.

**최근 백업 주의.** *최근* mtime 을 가진 `.bak` / `.orig`(또는 epoch 타임스탬프
도구 백업이 아닌 이름, 예: `config.json.bak-recent` vs
`config.json.bak-1748000000`)은 유저가 방금 일부러 만든 것일 수 있다. 누군가
몇 분 전에 만든 untracked, 복구 불가 파일을 삭제하는 것은 피해야 할 바로 그
비가역 실수다. 자동 제안 배치에 묶지 말 것 — "Excluded on purpose" 로 옮기고
의도적으로 보인다고 적으며 명시적 opt-in 으로 제공하라. stale 도구 백업(오래된
mtime + epoch 타임스탬프 이름)은 평범한 후보로 남는다.

```bash
find . -name '*.bak-*' -o -name '*.tmp' -o -name '*.orig' 2>/dev/null
find . -name '*.bak*' -mtime -1 2>/dev/null      # made in last day → caution, likely intentional
git status --porcelain --ignored | grep '^!!'    # ignored build/tmp output
```

## Cross-cutting: never-touch guard

어떤 경로든 제안하기 전에, 영속 집합에 없는지 재확인하라:

`rules/`, `AGENTS.md`, `CLAUDE.md`, `MEMORY.md`, `memory/`, `.git/`, `docs/adr/`,
`docs/concepts/`, `docs/guides/`, `docs/reference/`, `docs/_index/`, `docs/specs/`
(활성 계약), source code, `package.json`, lockfile, CI config, `.claude/`.

잘못 제안된 영속 파일 하나가 도구에 대한 모든 신뢰를 무너뜨린다. 경로가 경계에
있을 때(이 `report` 가 실은 영속 reference 인가?) "Excluded on purpose" 목록으로
당신의 추론과 함께 옮기고 유저가 다시 끌어오게 두라 — 남기는 쪽으로 기울 것.

## Related

- `~/.claude/rules-ondemand/db-drop-preflight.md` — 비가역 삭제 전 liveness 3증거 halt
  (§1 landed 판정 3증거의 동형 근거).
- `~/.claude/rules/verification-safety.md` V2 — 판정 grep 의 fixed-string 이스케이프
  근거(§3 orphan/dup grep).
