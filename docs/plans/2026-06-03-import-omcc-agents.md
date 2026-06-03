# Import oh-my-claudecode agents (10 curated)

> Phase-1 spec: `docs/specs/import-oh-my-claudecode-agents.md` (pinned, ambiguity 0.15).
> Mode: forge linear. This doc = implementation plan for Phase 2 codex review.

## Goal (testable success criteria)

oh-my-claudecode 의 agent 10개를 repo `agents/` 로 import, 최소 변형(level 제거 + dangling 참조 prune), install/sync 배포배선, 문서 갱신. 성공 = Acceptance 7항목 전부 pass.

## Scope (IN / OUT)

**IN:** agents/ 디렉토리 신설 + 10개 .md / install.sh·sync.sh agents 블록 / README·rules/project.md 갱신.
**OUT:** 기존 스킬 재배선(C4 deferred) / 비코드 agent 9종 / summon 연동(컨벤션 호환만) / AGENTS.md 손편집(@rules/project.md shim 이라 rules 편집으로 충분).

## Files (verified — path : why)

| path | 변경 | 근거 |
|---|---|---|
| `agents/{executor,code-reviewer,test-engineer,qa-tester,security-reviewer,critic,planner,architect,explore,debugger}.md` | 신규 (10) | REQ-F-001. 원본 다운로드 완료 ($CLAUDE_JOB_DIR/tmp/omcc) |
| `install.sh` | edit | skills 루프 뒤 agents 루프 블록 추가. 현재 17-32행 패턴 복제 → DEST `~/.claude/agents` |
| `sync.sh` | edit | skills 미러 루프 뒤 agents 미러 블록. DST `agents/` (rsync --delete) |
| `README.md` | edit | agents 표 + 카운트 |
| `rules/project.md` | edit | "What this repo is"·Commands·Architecture 에 agents 아티팩트 반영 |

## Steps (each → verify)

1. `agents/` 생성 + 10개 복사 (원본 그대로) → verify: `ls agents/*.md | wc -l` == 10
2. 각 파일 `^level:` 줄 삭제 → verify: `grep -l '^level:' agents/*.md` 빈 출력
3. dangling 참조 prune (analyst×3, document-specialist×2, verifier×debugger): 비-import agent 이름을 일반 능력 표현으로 reword, 의미 보존. `code-reviewer` 의 "reviewer/verifier lane"·"writers"(동시쓰기)는 일반명사 → 유지 → verify: handoff 문장에서 비-import agent 이름 0건
4. install.sh agents 블록 추가 (멱등·.bak 백업 동일 로직) → verify: `bash install.sh && ls ~/.claude/agents/*.md | wc -l` == 10, 재실행 시 .bak 생성
5. sync.sh agents 미러 블록 추가 → verify: live 편집→`bash sync.sh`→repo 반영 무손실
6. README + rules/project.md 표·카운트 갱신 → verify: 10개 agent 모두 README 에 링크
7. model pin 보존 확인 → verify: opus 5 / sonnet 4 / haiku 1

## Risks

- **R1 analyst 허브 의존:** planner 본문이 analyst 에 구조 의존("consult analyst first"). 단순 삭제 시 워크플로 깨짐 → 일반 능력으로 reword (제거 아닌 추상화). codex 검토 핵심.
- **R2 install/sync 순회 일반화:** 두 스크립트가 skills/ 전용. agents 블록 추가 시 중복 코드 — 함수 추출 vs 블록 복제 트레이드. 단순성 위해 블록 복제(YAGNI, 2회뿐).
- **R3 guard-readme-fresh 훅:** README 신선도 훅이 agents 도 강제하는지 확인 — 현재 `skills/<name>`만 체크면 무영향.
- **R4 disallowedTools 정식 필드:** 검증 완료(정식). 변형 불필요.

## Security surface

agent .md 는 시스템프롬프트 텍스트 — 실행 코드 아님. install.sh/sync.sh 는 로컬 cp/rsync, 외부발신 없음. 신규 입력·인증경계·시크릿 없음. 표면 최소.

## YAGNI (deletions in this change)

- 각 agent frontmatter `level:` 줄 (비정식·미사용).
- dangling 핸드오프 참조 (가져오지 않은 agent 로의 죽은 링크).
- 신규 데드코드 없음 — orphan 생성 안 함.

## Acceptance

1. `ls agents/*.md | wc -l` 출력 == `10`
2. `grep -l '^level:' agents/*.md` 출력 비어있음
3. agents 본문 핸드오프 문장에 비-import agent 이름(analyst/document-specialist/verifier as agent) 0건
4. `bash install.sh` 후 `ls ~/.claude/agents/*.md | wc -l` == `10`; 재실행 시 `.bak-*` 백업 생성(멱등)
5. live agent 편집 후 `bash sync.sh` → repo `agents/` 에 반영, 삭제도 미러됨
6. README.md 가 10개 agent 디렉/파일 모두 링크; rules/project.md 카운트·검증 ls 라인 갱신
7. model pin: opus / sonnet / haiku 원본 보존

## Codex/workflow review — round 1 (BLOCKING 반영)

codex 런타임이 멈춰(task 미추적) 유저 지시로 **워크플로 4차원 적대 리뷰**로 대체. BLOCKING 7건 발견, 전부 반영:

- **스크립트 구조 불일치** → install/sync 를 dir-루프 복제가 아닌 **별개 flat-file 블록**으로 작성. R2("블록 복제") 폐기.
- **first-run 부트스트랩** → repo `agents/` 존재 가드 + sync 는 agents/ populated 후. install `mkdir -p`.
- **check-skill-sync Stop 훅 누락** → agents drift(플랫 미러) + 미커밋(`-- skills agents`) 감지 추가.
- **dangling 열거 불완전** → 실제는 omc 생태계 결합(네임스페이스·`.omc/`·consensus·explore-high·start-work). **유저 결정: light 7개로 축소**(planner/critic/architect 제외 — 결합 집중 + craft-core 중복). 남은 7개의 결합 전부 제거/일반화.
- **Step3 verify 비검증가능** → grep + allowlist(`reviewer/verifier lane`, `writers`)로 결정화. 실제 검증은 잔여 grep 0 확인으로 수행.
- **planner→analyst 데이터계약** → planner 제외로 회피(동작변경 리스크 제거).
- **dangling 오열거** → 7개 기준 재grep 후 정확 처리.

NON-BLOCKING: install echo 갱신(반영), rsync --delete footgun(문서화), README 비대칭(ADR 명시), **ADR 신설**(`docs/adr/001`). all-19 대안은 ADR 에서 기각 근거 기록.

## 최종 결과 (10→7)

import: executor, code-reviewer, security-reviewer, test-engineer, qa-tester, debugger, explore. model: opus 2 / sonnet 4 / haiku 1.
