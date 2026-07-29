# Craft 파이프라인 고도화 — 구현 집중 + 사람 확인 최소화

> 2026-07-30. 근거: `craft-timing.jsonl` 40행 실측 + pipeline/security/ui-verify/
> output-contract 전수 리뷰(같은 날 P4/5 정지 진단 — F1~F6 수정 완료 — 의 후속).

## Goal (testable success criteria)

1. 파이프라인 밖 관심사(코드 정리·배포 검토·문서화)는 phase 가 아니라 **§N 라우팅**으로
   이어진다 — 파이프라인 phase 는 "구현 + 그 구현의 검증"만 남는다.
2. 사람 확인(`[사용자 직접 확인 필요]`)은 **agent 가 물리적으로 못 하는 것**만 남는다 —
   폼 제출·버튼 클릭·화면 렌더·API 응답은 agent 가 실구동으로 직접 닫는다.
3. 효과가 측정된다 — 사람 확인 건수가 계측돼 개선 전/후 비교가 가능하다.

## 현재 비용 배분 (median, n=40)

| phase | median | 비고 |
|---|---|---|
| p1 인터뷰+플랜 | 10m (13%) | crisp-스킵 게이트 부재가 유일 지방 |
| p2 플랜 리뷰 | 24m | **레거시 오염** — 핑퐁 은퇴(7/29) 후 표본 3건은 0~13m |
| p3 TDD | 20m (25%) | 코어 — 건드리지 않음 |
| p35 simplify | **0m** | 사실상 항상 스킵 — 존재 가치 의문 |
| p4 verify | 15m (24%) | max 158m = 미분리 사람 대기 (F1 수정으로 해소) |
| p5 wrap | 5m | 기록율 7/40 — 의무 과적 신호 |
| humanWait | 7m (max 3h) | **최적화 대상의 본체** |

사람 확인 *건수*는 현재 미계측 — WS5 가 계측을 넣는다.

## WS1 — Acceptance 태그 3분류: `[AUTO]` / `[AGENT]` / `[HUMAN]` (최우선)

**문제.** 현행 이분법(`[AUTO]`=테스트 / `[HUMAN]`=나머지)이 [HUMAN] 인플레이션의
구조 원인이다. "자동 테스트가 아니다"가 "사람이 봐야 한다"로 태깅되는데, 그 태그의
대부분(로그인 플로우, 폼 제출→저장 확인, 화면 렌더+콘솔 무에러, 엔드포인트 응답)은
agent 가 chrome MCP·curl·CLI 로 실구동해 닫을 수 있다. ui-verify Part B 인프라가
이미 그 능력을 갖고 있는데 — 적용 대상이 *diff 의 인터랙티브 요소*로만 정의돼
Acceptance 장부와 직결되지 않는다.

**변경.**
- `pipeline.md` P1 태그 루브릭(현 206-213행)을 3분류로:
  - `[AUTO]` — 결정론·회귀민감·보안·계약. Phase 3 테스트가 커버(불변).
  - `[AGENT]` — 자동 테스트는 아니지만 **agent 가 실구동으로 검증 가능**: 브라우저
    조작(클릭·입력·네비게이션), 스크린샷+콘솔 판정, curl/CLI 실행, dev 데이터 상태
    확인. Phase 4 에서 ui-verify Part B 기계로 agent 가 직접 닫고 §V
    `[직접 테스트 완료]` 로 배출.
  - `[HUMAN]` — 순수 주관 판단(미감·카피 톤·UX 질감), 실계정/실결제/외부 승인,
    prod 전용 확인. **태깅 시 "agent 가 왜 못 하는가" 1구절 의무** — 정당화 없는
    [HUMAN] 은 [AGENT] 로 강등. 기본값 편향: 애매하면 [AGENT].
- `pipeline.md` P4: `[AGENT]` 항목 처리 절 추가 — ui-verify Part B 절차(인벤토리에
  Acceptance [AGENT] 항목 합류)로 agent 가 구동·판정. fail = confirmed gap(loop-back),
  구동 불가만 [사용자 직접 확인 필요]로 강등+사유.
- `ui-verify.md` Part A: 인벤토리 소스에 "plan Acceptance 의 [AGENT] 항목" 추가
  (diff 추출 요소와 합집합).
- `output-contract.md` §V 규칙 1: [AGENT] green → `[직접 테스트 완료]` 매핑 명시.
- 하위호환: 구버전 태그 재분류 규칙(pipeline:161 — deep-plan 구산출 태그 보정)에
  [AGENT] 분류 추가. `deep-plan` 의 Acceptance 생성 루브릭도 같은 3분류로 동기
  (한 소스 참조 — 복제 금지).

**트레이드오프.** agent 실구동 시간만큼 P4 벽시계 ↑ — 대신 humanWait ↓. 기계 시간이
사람 시간보다 싸다: 올바른 교환. 단 [AGENT] 판정 오류(실은 주관 판단인 것)는 agent 가
green 을 위조하는 게 아니라 "구동했으나 판단 불가" 로 [HUMAN] 강등하면 안전.

## WS2 — "파괴적 컨트롤" 재정의 + confirm 오버라이드 (WS1 커버리지 확장)

**문제.** ui-verify 안전 규칙이 삭제/결제/외부발신을 일괄 금지 → blocked → 사람 이관.
그런데 **dev 환경 + 시드 데이터의 "삭제 버튼"은 파괴적이지 않다** — 실데이터가 아니고
재시드로 복원된다. blanket ban 이 [사용자 직접 확인 필요]를 불필요하게 부풀린다.

**변경.** `ui-verify.md` §2 안전 절 재정의:
- **절대 금지 유지** — 경계 밖 발신(메일·SMS·웹훅·실결제·외부 API 쓰기), prod 데이터,
  복구 경로 없는 조작. 이건 dev 여도 금지(메일은 dev 에서도 진짜 나간다).
- **허용 신설** — dev/로컬 환경 AND 대상이 시드/테스트 데이터 AND 복원 경로 확인
  (재시드 스크립트·트랜잭션 롤백·재생성 가능)일 때 삭제·상태변경 컨트롤 실구동 허용.
  판정 증거(왜 dev 데이터인지) 1구절 기록.
- **JS dialog 함정 우회** — `confirm`/`alert` 를 띄우는 컨트롤은 클릭 전
  `javascript_tool` 로 `window.confirm = () => true`(필요 시 `alert` no-op) 주입 후
  클릭 — 도구 블록 없이 실구동. 주입 사실을 판정 기록에 남긴다(네이티브 dialog 는
  회피 불가 — 그 경우만 이관 유지).

**트레이드오프.** dev 오판(실은 공유 DB) 리스크 — 복원 경로 *확인 후에만* 허용이라
보수적. 확인 못 하면 현행대로 이관: 기본 동작 불변, 허용은 증거 있는 경우만.

## WS3 — 구현 외 관심사 → §N 라우팅 (덜어내기)

**3a. P3.5 simplify pass 은퇴.** p35 median 0m — 사실상 항상 스킵되거나 무비용
통과. 블로킹 질문 1개(AskUserQuestion 제안)만 남기고 가치가 없다. phase 를 제거하고
`/simplify` 를 §N **권장** 행의 상시 후보로 이동("green diff 정리 — behavior-preserving").
`simplify-pass.md` 삭제, pipeline 의 P3.5 절·타이밍 스키마 `p35` 제거(과거 행 호환:
ETA 계산이 없는 키 무시). 은퇴 근거·복원 경로(git history)를 커밋 메시지에.

**3b. ETA 스냅샷 축소.** 매 phase 진입마다 jsonl median 조회 + Task 텍스트 `est ~Xm`
부기 + 경계 배너 — 가치(눈요기) 대비 비용(매 경계 조회·갱신)이 안 맞고, 표본 오염
(p2 레거시)으로 예측이 틀린다. **타이밍 기록은 유지**(튜닝 유일 근거) — *예측 표시*만
은퇴: progress.md §P4 를 wrap 1회 보고(보드 타이밍 행)로 대체.

**3c. §N 후보 확충.** post-build 라우팅 예시에 `preflight`(배포 전 종합 판정)·
`fortify`(보안 심화)·`/simplify`(3a) 를 명시 — "구현 끝 = land/sweep" 만이 아니라
검토·정리 스킬로의 전진을 §N 이 안내한다. 파이프라인 안으로 끌어오는 게 아니라
**밖으로 잇는다** — 이 플랜의 방향 그 자체.

**유지(컷 안 함) + 근거.** §R/§V/§N/L1(텍스트 1회 — 검증 실체), Linear 전이+코멘트
(graceful·비차단), ADR 기록(조건부 — 결정 컨텍스트는 세션이 가장 잘 아는 시점에),
UI companion 목업(P4 Part C 의 visual 계약 — 구현 품질 직결), P2 게이트(이미 7/29
재설계 완료 — 기본 스킵).

## WS4 — 스모크 가능성 조기 판정 (P0 로 전진 배치)

**문제.** env/credential/DB 부재를 **P4 에서 처음 발견** → 스모크 skip → 이관 폭탄.
늦은 발견이 사람 확인을 낳는다.

**변경.** `pipeline.md` P0 Frame 에 1줄 추가: dev 실행면 사전 판정 —
`devserverctl.py` auto-detect(Makefile `dev:`/package.json `dev`) + `.env`/시드 존재
확인(실행은 안 함, 존재만). 불가 판정이면 **P1 인터뷰에서 사용자에게 조기 고지**
("스모크 불가 — [AGENT] 항목이 [HUMAN] 으로 강등될 것") — P4 이관 폭탄 대신 플랜
시점에 알고 시작한다.

## WS5 — 계측: 사람 확인 건수 (효과 측정 없이는 최적화도 없다)

`craft-timing.jsonl` 행에 필드 추가:

```json
"human":{"acceptance":<[HUMAN]+[AGENT] 총>,"agentClosed":<agent 실구동으로 닫은 수>,"handed":<사람 이관 수>}
```

- WS1/WS2 의 성공 판정 근거: `handed / acceptance` 비율이 내려가야 한다.
- **은퇴 조건**(글로벌 룰 수명 규율): 2개월 표본에서 `handed` median 이 1 이하로
  안정되면 이 계측 필드를 제거(목적 달성 — 유지비만 남음). 반대로 [AGENT] 도입에도
  `handed` 가 안 내려가면 WS1 루브릭을 재검토.
- p2 레거시 오염 대응: ETA/튜닝 판정 시 2026-07-29 이전 행 제외(핑퐁 은퇴 마커).

## 우선순위 · 파일 변경 맵

| 순위 | WS | 파일 | 예상 효과 |
|---|---|---|---|
| 1 | WS1 태그 3분류 | pipeline.md · ui-verify.md · output-contract.md · deep-plan 루브릭 | 사람 확인 건수 구조적 감소(본체) |
| 2 | WS2 파괴적 재정의 | ui-verify.md | blocked→이관 감소 |
| 3 | WS3 라우팅 | pipeline.md · progress.md · simplify-pass.md(삭제) | phase 수 -1 · 블로킹 질문 -1 · 경계 오버헤드 제거 |
| 4 | WS4 조기 판정 | pipeline.md (P0 1줄) | 이관 폭탄 예방 |
| 5 | WS5 계측 | pipeline.md (스키마) | 효과 측정 가능 |

## YAGNI (이 변경이 만드는 삭제 대상)

- `simplify-pass.md` 파일 (3a — pipeline P3.5 절과 함께).
- `progress.md` §P4 ETA 절 (3b — 파일 자체는 다른 절이 남으면 유지).
- 타이밍 스키마 `p35` 키.

## Acceptance

1. [AUTO] pipeline.md 에 `[AGENT]` 태그 정의 + P4 처리 절 존재, grep 으로 확인.
2. [AGENT] ui-verify Part A 인벤토리 소스에 Acceptance [AGENT] 합류 명시.
3. [AUTO] P3.5 절·simplify-pass.md·`p35` 스키마 부재 (grep 0건).
4. [AGENT] §N 후보에 preflight/fortify/simplify 명시.
5. [AUTO] 타이밍 스키마에 `human` 필드 + 은퇴 조건 명시.
6. [HUMAN] 다음 실빌드 1회에서 `handed` 건수가 체감 감소 — 루브릭 체화는 실행으로만
   확인 가능(agent 가 자기 태깅 습관을 사전 검증할 수 없음).

## Risks

- [AGENT] 오태깅(주관 판단을 agent 가 구동만 하고 green 처리) — "판단 불가 시 [HUMAN]
  강등" 규칙이 방어. 미감·톤은 lubric 에 명시적 [HUMAN] 예시로 남긴다.
- WS2 dev 오판 — 복원 경로 증거 없으면 현행 이관 유지(기본 불변).
- P3.5 은퇴 후 diff 품질 저하 우려 — §N 권장 라우팅 + Phase 3 refactor 스텝(TDD 내장)이
  커버. 재발 관측 시(리뷰에서 정리 발견 급증) phase 복원은 git revert 1회.

## Pipeline state

- phase: plan (승인 대기) · mode: —
- updated: 2026-07-30
