# `## 추천` + 체인 전방 가이드 — 생성 규칙 (SSOT)

> 이 파일이 Linear 이슈에 붙는 **적응형 추천 섹션**과 **연결 이슈 전방 가이드**의 단일
> 소스다. `linear-register`(등록 시점)와 `linear-groom`(보강 시점) 양쪽이 읽어 동일하게
> 적용한다 — 복제하지 말 것(drift 차단). 규칙을 바꾸려면 이 파일을 바꾼다.

## A. `## 추천` 블록 — 적응형 도구 추천

이슈 본문 하단(원본/disclaimer 위)에 그 작업에 **적합한 스킬/에이전트/워크플로우**를
모델 판단으로 러프하게 추천한다. 고정 lookup 아님 — 이슈 타입·크기를 보고 그 순간 고른다.

**우선순위 (필수):**
1. **글로벌 스킬/에이전트 우선** — available-skills 목록(컨텍스트에 이미 주입)을 실제로
   훑어 이 이슈에 맞는 것을 고른다. 시작 매핑(고정 아님, anchor 금지):
   - 버그/고장 → `/hunt`
   - 새 기능(greenfield) → `/forge`
   - 기존 변경/개편 → `/renew`
   - 큰 교차·전면개편·research → `harness-run` 또는 `/deep-plan`
   - 자율 적합 단일 티켓 → `linear-goal`
   - 코드 이해·위치 파악 → `Explore` 에이전트 / `/deep-research`
   - 대형 plan/spec/PRD 분할 → `to-issues`
2. **프로젝트 로컬 포인터 부차** — 1줄: 해당 repo 의 `.claude/skills`·`.agents` 도 확인.
   **타repo 파일을 읽지 않는다**(경량 — repo/팀명 수준 포인터만).

**블록 포맷:**

```markdown
## 추천
- **권장**: `/<skill>` — <왜 이게 맞는지 1줄>
- 대안: `/<skill>` / `<agent>`
- 해당 repo(`<repo 또는 팀명>`)의 `.claude/skills`·`.agents` 로컬 툴도 확인.
```

## B. 체인 전방 가이드 — 연결 이슈에만

이슈가 **Linear 네이티브 관계**(`blocks`/`blockedBy`/`parent`/`relatedTo`)로 다른 이슈와
연결돼 있으면, 다음 작업으로의 전방 포인터 + 붙여넣기용 kickoff 프롬프트를 본문에 심는다.
연결이 없으면(단건) 이 섹션을 **생략**한다.

- **방향**: 이 이슈가 `blocks` 하는(= 이게 끝나야 풀리는) 다음 이슈를 가리킨다.
- **kickoff 프롬프트**: 다음 이슈를 곧장 착수할 수 있는 한 단락. A절 추천과 일관되게
  (예: 다음이 버그면 "`/hunt` 로 <다음 이슈 id> 착수: …").

**블록 포맷:**

```markdown
## 다음 작업
다음: <next-id> <next-title> · 시작 프롬프트:
```
<붙여넣기용 kickoff 프롬프트 — 다음 이슈 id + 무엇을 할지>
```
```

## C. UI/프론트엔드 이슈 — 시안 선행 컨벤션 (UI 작업에만)

이슈가 사용자 대면 UI(화면·컴포넌트·페이지·패널·인터랙션·visible UX 변경)를 만들거나
바꾸면, 본문에 **시안 선행** 한 줄을 박는다. **시안 자체를 등록 시점에 생성하지는 않는다** —
경량 유지(linear-register 는 시안·메타프롬프트 없음). 등록은 "시안을 먼저 만들고 거기에
충실히 구현하라"는 **계약만** 명시하고, 시안 실제 생성은 착수 시점에 forge/renew(craft
Phase 1-2 가 `.html` companion 생성)·deep-plan 이 맡는다.

- **판별**: UI/프론트엔드 작업인가? (화면·컴포넌트·페이지·패널·인터랙션·visible UX).
  순수 백엔드·리팩터·CLI·DB·API 계약이면 **이 절 생략**.
- **본문에 추가** (`## 작업 내용`/`## 작업` 안 한 줄): "시안을 `docs/preview/<name>.html`
  standalone 으로 **선행**(프로젝트 `DESIGN.md`/디자인 토큰 충실, 하드코딩 hex/px 금지),
  거기에 충실 구현." DESIGN.md/토큰 시스템이 있으면 그 경로를 가리키고, 없는 net-new 면
  "시안은 `frontend-design` 으로" 로 적는다.
- **추천(§A) 정합**: §A 는 보통 `/forge`·`/renew` 를 가리키면 충분하다 — 빌드가 craft
  Phase 3 에서 시안→충실구현 / `DESIGN.md`→`imprint` / net-new→`frontend-design` 로 **자동
  라우팅**한다. 추천에 `frontend-design`/`imprint` 를 직접 넣지 않아도 된다(넣어도 무방).

> 왜 등록 시 시안을 안 만드나: 미착수 백로그 이슈의 시안은 낭비(YAGNI), Linear 는 HTML
> 시안을 렌더하지 못한다(첨부 제약). "시안+이슈를 같이" 가 꼭 필요한 큰 UI 작업은
> `deep-plan`(HTML 시안 산출) → `to-issues`(분할) 경로를 쓴다.

## 적용처별 차이

- **linear-register** (등록 시점) — 배치로 이슈를 만들며 관계를 직접 세팅하고, 그 자리에서
  A+B(+UI 면 C)를 본문에 박는다. 종료 응답에 첫 실행 가능 이슈의 kickoff 프롬프트도 사용자에게 제시.
- **linear-groom** (보강 시점) — **보강 대상 이슈에만** A(+UI 면 C)를 추가한다(healthy 이슈는
  surgical 불변식상 손대지 않음). B 는 배치에서 읽은 기존 관계로 연결된 이슈에 추가. 둘 다
  승인 게이트 뒤에만 write.
