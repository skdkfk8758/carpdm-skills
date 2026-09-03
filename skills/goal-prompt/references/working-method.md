# Working Method — 3 패밀리 결합 SSOT (ponytail · paperthin · Matt Pocock)

> `goal-prompt` Step 4(조립)·Step 5(렌즈 검토)가 읽는다. §1~§3 은 각 패밀리의
> **압축문**(프롬프트 한 줄로 들어갈 길이), §4 는 **결합표**(시점별로 어느 스킬을
> 어떻게 부르고 없으면 무엇으로 대체하는가), §5 는 렌즈 체크리스트.
> Karpathy 4원칙 본문은 `prompt-template.md` Operating discipline 이 SSOT — 여기
> 복제하지 않는다. 원본이 바뀌면 여기를 고친다.

원본 위치(확인용): ponytail 플러그인
`~/.claude/plugins/cache/ponytail/ponytail/<ver>/skills/ponytail/SKILL.md` · paperthin
`~/.agents/skills/<name>/SKILL.md` · Matt Pocock 플러그인
`~/.claude/plugins/cache/claude-plugins-official/mattpocock-skills/<ver>/skills/{engineering,
productivity}/<name>/SKILL.md`(tdd + `tests.md`/`mocking.md` · code-review · to-tickets ·
implement · handoff · grilling · prototype · research · domain-modeling). `~/.agents/skills/`
에도 구 스냅샷이 남아 있을 수 있다 — 플러그인 쪽이 SSOT.

## §1 ponytail — 사다리 압축

ponytail 은 **플러그인 SessionStart 훅**으로 세션마다 자동 활성된다(`PONYTAIL MODE
ACTIVE` 배너). 프롬프트는 그것을 전제하되 배너가 없을 때의 폴백을 같은 줄에 둔다:

```
- 새 파일·함수·의존성 전 사다리: 필요한가(YAGNI) → 이 레포에 이미 있나 → stdlib → 플랫폼 네이티브 → 설치된 의존성 → 한 줄 → 그제야 최소 코드. 두 칸이 다 되면 위 칸. 버그는 증상이 아니라 모든 호출자가 지나는 지점에서 고친다. 의도적 한계는 `ponytail:` 주석으로 상한과 업그레이드 경로를 남긴다. (ponytail 모드 활성이면 그 규칙이 이 줄을 대체)
```

ponytail 이 **양보하지 않는 것**을 Constraints 가 침범하지 않게 한다: 신뢰 경계 입력
검증·데이터 손실 방지 에러 처리·보안·접근성·명시 요청 항목. 비자명 로직의 "실행
가능한 검사 1개" 는 tdd 슬라이스가 대신한다.

## §2 paperthin — 체크포인트

두 부류다. **자동 16종**은 description 매칭으로 발동한다 — 프롬프트가 할 일은 *발동
조건이 되는 문장*을 두는 것. **유저 전용 12종**(`disable-model-invocation: true`)은
모델이 못 부른다 — 사람이 있으면 타이핑을 요청하고(interactive 부록), 없으면
**출력 형태만** 인라인한다(절차 전체가 아니라 — `hate`/`feynman` 이 유저 전용인
이유가 "상시 반사는 철거·자기의심 편향" 이므로 반사를 상시화하지 않으면서 산출물
이득만 취한다).

| 시점 | 스킬 | 부류 | autonomous 본문 문장 | interactive 부록 |
|---|---|---|---|---|
| 착수 | `readchk` | 자동 | "지시를 내 말로 재진술하고 Context 와 대조한다. 살아남은 갈래만 Persona 우선순위로 고르고 assumption 에 올린다." | 갈래는 사용자에게 |
| 계획 확정 직전 | `hate` | 유저 | "계획 확정 전 3줄: 계획이 서려면 참이어야 하는 가정 1개 → 그것이 틀리는 가장 싼 확인 1개 → 그 확인을 첫 슬라이스에 넣는다. 목록이 아니라 root 하나." | `/hate` 요청 |
| 선택 직후 | `feynman` | 유저 | "선택 직후 그 선택을 회의적 리뷰어에게 설명하는 2문장을 커밋 메시지 본문에 쓴다. 설명이 안 되면 선택을 되돌린다." | `/feynman` 제안 |
| done 직전 | (sip 폴백) | — | "done 전 fresh-eyes 1회: 이 diff 만 본 사람이 Objective 를 복원할 수 있는가. 못 하면 커밋 메시지·주석을 고친다." | 동일 |

`sip` 자체는 소비자 프롬프트가 아니라 **goal-prompt Step 5** 에서 발동한다(프롬프트
파일이 artifact). `prism` 은 interactive 부록에만.

## §3 Matt Pocock — 빌드 흐름 압축

Pocock 흐름 `idea → grill → spec → tickets → implement(tdd → code-review)` 에서
**grill 은 goal-prompt Step 3 자신이 맡고**(SKILL.md — design tree·프론티어·권장답),
프롬프트는 spec 을 지난 산출물이므로 **tickets 이후**만 싣는다. 하중을 받는 규칙:

- **seam 사전 합의** — 테스트는 공개 경계에서만. 기존 seam 우선, 신설은 가장 높은
  지점, 이상적 개수 1. `tdd` 스킬은 "seam 을 사용자와 확인" 을 요구하므로 프롬프트
  Context 가 "이 seam 이 사전 합의된 seam" 이라고 **선제 선언**한다(autonomous 에서
  확인 질문으로 죽지 않게).
- **tracer bullet = 실행 단위** — 슬라이스는 전 계층 관통·단독 검증·**fresh 컨텍스트
  하나 크기**, `Blocked by` 선언, 슬라이스당 커밋 1. 2+ 슬라이스면 골격 `## Slices`
  가 그 목록이고 Operating discipline 4 의 Step 목록을 대체한다(수평 슬라이싱 차단).
  한 슬라이스가 컨텍스트 하나에 안 들어가거나 4000자 게이트에 걸리면 프롬프트 N 파일
  분할(`-prompt-01.md`…) + 공통 규율 파일 추출(`-prompt-00-common.md`).
  넓은 리팩터만 예외: expand → migrate(배치) → contract.
- **tdd 루프** — red 먼저, 통과할 만큼만 green, 슬라이스당 seam 1·테스트 1·구현 1.
  리팩터는 루프 밖(review 단계). 타입체크·단일 테스트 파일은 자주, 전체 스위트는 끝에
  1회. 기대값은 독립 출처(spec·알려진 리터럴) — tautological·구현 결합 테스트 금지.
  mock 은 시스템 경계(외부 API·시간·랜덤)만, 자기 모듈·내부 협력자는 mock 하지 않는다.
  테스트당 논리적 assertion 하나.
- **2축 code-review — 항상 인라인** — 커밋 전 `git diff <BASE_SHA>` + `git status --porcelain`(미추적 신규 파일은 diff 에 안 잡힌다 — `...HEAD` 는 미커밋을 빼므로 쓰지 않는다)를 두 축으로
  따로 본다: **Standards**(레포 규약 문서 + Fowler smell 은 판단 라벨, 도구가 강제하는
  건 스킵) / **Spec**(spec = 이 프롬프트의 Objective+Success Criteria — 누락·scope
  creep·오구현). 합쳐 재랭킹하지 않는다. 세션의 `/code-review` 는 **빌트인
  correctness 리뷰**라 2축이 아니다 — 있으면 보조 1회로만.
- **smart zone → 슬라이스 경계가 게이트** — autonomous 소비자는 토큰을 못 재고 새
  세션을 못 연다. 그래서 관측 가능한 조건으로 바꾼다: 다음 슬라이스를 시작할 수
  없거나 1회 자가수정이 실패하면 `docs/handoff/YYYY-MM-DD-<topic>.md`(carpdm `handoff` 스킬의 경로·파일명 규약)
  에 남은 슬라이스·결정·BASE SHA 를 쓰고 `result: partial — 완료 k/N, handoff <경로>` 로
  종료. 재기동은 launcher 몫. interactive 는 `/handoff` 후 사람이 새 세션.
- **어휘·standing 결정** — `CONTEXT.md` 용어로 테스트·인터페이스 이름을 짓고 ADR 을
  따른다. 뒤집어야 하면 코드가 아니라 보고로.

## §4 결합표 — Working Method 조립

각 행이 프롬프트 Working Method 의 한 줄. `있으면` 은 available-skills(자동) 또는
`test -f`(유저 전용) 확인이 참일 때만. **폴백은 항상 같은 줄에.**

| # | 시점 | 있으면 (스킬 이름 발동) | 없으면 (인라인) |
|---|---|---|---|
| 1 | 착수 | `readchk` 원리로 재진술 (§2 행) | 같은 문장 |
| 2 | 착수 | ponytail 배너 확인 | §1 사다리 한 줄 |
| 3 | 계획 확정 직전 | §2 hate 인라인 3줄 (유저 전용이라 항상 인라인) | 동일 |
| 4 | 슬라이스 시작 | `/tdd` — seam 은 Context 의 것(사전 합의됨), red→green | §3 tdd 항 요지 3줄 |
| 5 | 선택 직후 | §2 feynman 인라인 2문장 (항상 인라인) | 동일 |
| 6 | 커밋 직전 | §3 2축 인라인 (항상) + 빌트인 `/code-review` 있으면 보조 1회 | 2축 인라인만 |
| 7 | 슬라이스 못 넘김 / 자가수정 실패 | `handoff` 스킬로 `docs/handoff/` 증류 후 partial 종료 | "남은 슬라이스·결정·BASE SHA 를 `docs/handoff/YYYY-MM-DD-<topic>.md` 에 쓰고 partial 종료" |
| 8 | done 직전 | §2 sip 폴백 문장 | 동일 |

BASE SHA 리터럴 기록, Success Criteria, Verification 은 스킬 유무와 무관하게 항상 —
프롬프트의 척추다.

## §5 2-렌즈 체크리스트 (Step 5)

### Karpathy 렌즈 — "받은 에이전트가 추측 없이 done 까지 가나"
- [ ] Context 의 모든 경로·명령이 Step 1 실측인가 (하나라도 추측이면 BLOCKING)
- [ ] 소비자가 **할 수 없는 일**을 지시하지 않나 — 파일 자기편집·새 세션 열기·사람에게
      질문(autonomous 본문) — 있으면 BLOCKING
- [ ] 진술되지 않은 가정이 남았나 — Constraints assumption 으로 승격
- [ ] Objective 에 요청 밖 기능이 섞였나
- [ ] Success Criteria 각 항목이 명령/테스트/파일/수치로 판정되나 — "잘/깔끔/정상" 0건
- [ ] 마지막 SC 가 BASE SHA 리터럴 기준의 `git diff --stat <SHA>` **+ `git status --porcelain`** 쌍(`...HEAD` 아님, diff 단독 아님)이고 영향 반경에 테스트·lockfile·handoff 가 포함돼 있나
- [ ] Verification 에 실패 상한(1회 자가수정 → partial)이 있나
- [ ] 페르소나에 "중시 순서"와 "불확실성 처리"가 있나 — 직함만이면 BLOCKING
- [ ] 파일당 `LC_ALL=en_US.UTF-8 wc -m` 이 **4000 이하**인가 — 초과는 BLOCKING(Step 6 게이트를 통과할 때까지 산출하지 않는다. 1,000자 이상 초과면 산문 압축 말고 슬라이스 분할 + 공통 파일 추출로 간다)
- [ ] 공통 파일을 뺐다면 각 슬라이스 파일 첫머리에 `## 공통 규율`(경로 + "읽지 않고 시작하지 않는다")이 있나 — 없으면 BLOCKING(소비자가 규율 없이 시작한다)
- [ ] Context 에 `{{…}}` placeholder 가 남아 있나 — 하나라도 있으면 BLOCKING(branch 포함, launcher 는 채워주지 않는다)

### Pocock 렌즈 — "빌드가 수직으로, 검증 가능하게 굴러가나"
- [ ] seam 이 Context 에 확정·선언돼 있나 (미정이면 `[HUMAN]` 갭으로 되돌림)
- [ ] 2+ 슬라이스면 `## Slices` 가 있고 각 행이 Blocked by·verify·fresh 컨텍스트 크기인가
- [ ] tdd 진입점(행 4)·2축 리뷰(행 6)·partial 경로(행 7)가 Working Method 에 있나
- [ ] `CONTEXT.md`/ADR 이 있는 레포면 Context 가 그것을 가리키나
- [ ] Working Method 의 모든 줄에 "없으면" 절이 있나
- [ ] interactive 부록이 autonomous 본문에 섞이지 않았나

BLOCKING = "BLOCKING" 표기 항목 + SC 판정 불가. 그 외는 SUGGESTION — 반영 재량,
기각 시 사유 한 줄.
