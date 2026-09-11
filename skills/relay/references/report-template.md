# relay 보고 형식

첫 문장은 결론이다: `<N>개 WU 가 새로 끝났고 판정은 <통과 a / 실패 b / 미실행 c>, 다음 물결은 <k>세션` 형태.

## 1. 판정 — 새로 완료된 WU

| WU | 기준 | 명령 | 관측 | 판정 |
|---|---|---|---|---|
| S0 | `AC-` ≥ 25 | `git show origin/develop:.moai/specs/SPEC-X/spec.md \| grep -c 'AC-'` | 41 · 고유 25 | 통과 |
| BE-C1 | `make api-check` exit 0 | `make api-check` (relay-verify @ 7ea364c) | exit 0 · 612 passed | 통과 |
| BE-C1 | 운영 3초 이내 | — | — | 미실행 — 운영 검증 WU 담당 |

이전에 끝난 WU 는 한 줄로 묶는다: `이전 완료 N개 — 재판정 안 함`.
관찰(성공 기준 밖 변경, FROZEN 문서 수정, 상태 표기 불일치)은 표 아래 최대 3줄.

## 2. 동기화

`로컬 <trunk>: <책갈피 SHA> → <새 SHA> (fast-forward)` 또는 `건너뜀 — <이유>`.

## 3. 다음 물결

**1차 물결 — 동시에 <k>세션** (소스 경로가 겹치지 않음)

| 순서 | WU | 호스트 | 붙여넣기 | 만지는 경로 |
|---|---|---|---|---|
| ★1 | BE-C1 검색량 정렬 | Codex | `다음 프롬프트대로 진행해줘: /abs/path/…-be-prompt-01.md` | `services/api/app/services/market_service.py` |

★ 에는 우선 근거 한 줄(운영에서 깨져 있음 · 뒤 WU 를 N개 품).

**미룬 WU** — `<WU>: <겹친 경로> 때문에 <WU> 뒤로` · **막힌 WU** — `<WU>: <선행 WU> 대기`.

**[HUMAN]** — 머지 승인 · 배포 · 운영 데이터 적용 · 실수집 승인처럼 사람만 할 수 있는 것.

## 4. 정리 안내 (해당할 때만)

- 열린 PR → `land` · 머지된 WU 의 워크트리 → `wt-sweep` · 릴리즈 대상 누적 → `launch`.
