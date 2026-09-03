# Requirements: dev 배포 파이프라인 스캐폴딩 스킬

> Crystallized from a deep-interview on 2026-09-03. Final ambiguity: 17% (target ≤ 20%).
> Type: brownfield (기존 스킬 생태계). Rounds: 3. Status: draft.

## 1. Goal & scope

신규 프로젝트에 **dev 배포 파이프라인**을 붙이는 글로벌 스킬. 앱 저장소의 GitLab CI
(`test` → `build` → `promote`)와 `DevOps/infra` 의 GitOps 배선(`gitops/apps/<svc>/` ·
Argo Application · AppProject)을 한 번에 만들고, **MR 두 개를 열고 멈춘다.**

`launch` 는 prod 릴리즈 배선을 담당하며 그 `setup` 모드가 "dev 매니페스트 없으면
**dev 배선부터 — setup 범위 밖, 멈춘다**" 라고 선언한다. 이 스킬은 정확히 그 전제를
채우는 자리다. 두 스킬은 인접하고 중복되지 않는다.

**In scope:** 인터뷰(1) · dev 배선 산출(2) · prod 라우팅(3) · 인프라 요청 문서(4) ·
검증·보고(5) · 스킬 자체 배포(6)
**Out of scope:** prod 릴리즈 배선(→ `launch setup`) · 클러스터·계정 리소스 생성
(→ `DevOps/infra` 트랙) · MR 머지 이후의 모든 것 · GitHub 전용 저장소

## 2. Topology

| Component | Status | One-line role |
|---|---|---|
| 1 인터뷰 | active | 되돌리기 비싼 값만 묻는다 — 3문항 1콜 |
| 2 dev 배선 산출 | active | 앱 repo CI + infra GitOps 경로·Application·AppProject |
| 3 prod 라우팅 | active | 끝에서 `/launch setup` 으로 넘긴다. 직접 만들지 않는다 |
| 4 인프라 요청 문서 | active | dev 준비도 판정 후 **미충족 항목만** 프롬프트로 |
| 5 검증·보고 | active | MR 까지이므로 렌더·dry-run·lint 로만 판정 |
| 6 스킬 자체 배포 | active | `carpdm-skills` 미러 → `/ship` |

## 3. Functional requirements

| ID | Requirement (the skill SHALL…) | Priority | Acceptance criteria | Origin |
|---|---|---|---|---|
| REQ-F-001 | 인터뷰는 `AskUserQuestion` **1콜 · 최대 3문항**이다 — 노출 등급 · 외부 의존 유무 · 릴리즈 라인 확인 | Must | SKILL.md 에 문항 수 상한이 명시되고, 실행 시 `AskUserQuestion` 호출이 1회 | R2 |
| REQ-F-002 | namespace·AppProject·Service 타입을 **직접 묻지 않는다.** 노출 등급 답에서 파생시킨다 | Must | 사내 전용 → `internal-<svc>` / `apps-internal` / NodePort · 공개 → `<svc>` / `apps-dev` / ClusterIP |  R2 |
| REQ-F-003 | 기본 노출 등급은 **사내 전용**이며 공개는 명시 선택이다 | Must | 옵션 첫 항목이 사내 전용 + `(권장)` | R2 |
| REQ-F-004 | 검증 게이트를 저장소에서 **추정**한다 — `pyproject.toml`·`package.json`·`go.mod` 등 감지 | Must | 감지된 스택과 명령 후보가 산출 요약에 나타난다 | R2 |
| REQ-F-005 | `build`/`promote` 잡의 `changes:` 목록을 **Dockerfile 의 `COPY` 경로 + lockfile 실측**으로 만든다 | Must | 생성된 `changes:` 의 각 항목이 저장소에 실재한다 | R2 |
| REQ-F-006 | 추정한 값은 **전부 산출 요약에 명시**한다. 조용한 추정을 하지 않는다 | Must | 보고에 "추정" 절이 있고 REQ-F-004·005 의 값이 거기 있다 | R2 |
| REQ-F-007 | ECR 경로(`apps/<svc>`)·태그(`<line>-<sha>`)·digest pin·immutable·promote MR 방식은 **묻지 않는다** — ADR 0006 규약이다 | Must | 인터뷰 문항에 이 값들이 없다 | R2 |
| REQ-F-008 | 산출물은 **MR 두 개**다 — 앱 repo(`.gitlab-ci.yml`) · `DevOps/infra`(`gitops/apps/<svc>/` + Application + AppProject). 머지하지 않는다 | Must | 두 MR URL 이 보고에 있고 둘 다 `opened` | R1 |
| REQ-F-009 | 끝에서 `/launch setup` 으로 라우팅한다. prod 배선을 직접 만들지 않는다 | Must | 보고의 다음 단계에 `/launch` 가 있고, 산출물에 태그 규칙 잡이 없다 | R0 |
| REQ-F-010 | **dev 준비도**를 명령으로 판정한다 — 온프렘 Argo · 대상 AppProject · ECR 저장소 · 앱 Secret · 노드 여유 등. 3-상태(PASS/FAIL/확인필요) | Must | 보고에 항목별 상태와 판정 명령이 있다 | R3 |
| REQ-F-011 | 준비도 **미충족 항목이 있을 때만** 인프라 요청 문서를 산출한다. 전부 PASS 면 만들지 않는다 | Must | PASS 100% 실행에서 문서 파일이 생성되지 않는다 | R3 |
| REQ-F-012 | 그 문서는 **infra 세션이 붙여넣는 실행 계약** 형태다 — 판정 가능한 SC(명령 + 기대 출력) · 제약 · 범위 밖 | Must | 각 SC 가 명령과 기대 출력을 갖는다 | R3 |
| REQ-F-013 | 스킬 자체는 `~/Workspace/carpdm-skills/skills/` 에 두고 `/ship` 으로 배포한다 | Should | 파일이 그 경로에 있고 `sync.sh` 미러 대상이다 | R0 |

## 4. Non-functional requirements

| ID | Category | Requirement | Acceptance criteria | Origin |
|---|---|---|---|---|
| REQ-N-001 | 마찰 | 사람에게 묻는 총량이 `AskUserQuestion` 1콜을 넘지 않는다. "폼이 되는 순간 아무도 안 쓴다" | 실행 로그에 `AskUserQuestion` 1회 | R2 |
| REQ-N-002 | 표준화 | 스킬은 조직의 분산을 **복제하지 않고 좁힌다** — ns 관례 둘 중 하나가 기본, 다른 하나는 opt-in | REQ-F-003 과 동일 판정 | R2 |
| REQ-N-003 | 경계 | 클러스터·AWS 계정 리소스를 만들지 않는다. `kubectl apply`·`terraform apply` 를 실행하지 않는다 | 스킬 본문에 그 명령이 없다 | R0·R1 |
| REQ-N-004 | 되돌림 | 산출은 MR 이므로 모든 추정이 머지 전에 한 줄로 교정 가능하다 | REQ-F-008 과 동일 | R1 |
| REQ-N-005 | 안전 | 되돌리기 비싼 값(namespace)만 묻는다. 나머지는 기본값 + 사후 교정 | 인터뷰 문항이 REQ-F-001 의 셋뿐 | R2 |

## 5. Constraints & assumptions

**Constraints**
- GitLab + `DevOps/infra` + ECR + Argo CD 전제의 **조직 전용 스킬**이다. `launch` 가 이미
  같은 전제이므로 일반화하지 않는다.
- `launch` 와 경계를 공유한다 — 이 스킬이 dev, `launch` 가 prod. 한쪽을 고치면 경계
  문장을 같이 본다.
- ADR 0006 이 정한 것(ECR 경로·태그·digest pin)은 선택지로 열지 않는다.

**Assumptions resolved**
- "어디서 멈추나": MR 까지 — `launch setup` 과 같은 규율 (R1). 근거는 그 스킬이 적은
  "배선 오류·환경 오류·릴리즈 실패를 분리해서 봐야 원인이 갈린다".
- "무엇을 묻나": 되돌리기 비용 기준. namespace 만 비싸고, 그것도 직접 묻지 않고 노출
  등급으로 파생 (R2).
- "요청 문서 수신자": infra 세션이 붙여넣는 프롬프트 (R3).

**Residual ambiguity**
- **MR 까지 멈추는 대가가 크다.** 2026-09-03 세션에서 admap-mcp 를 클러스터까지 올리며
  잡은 네 가지 — `Too many pods`(파드 상한) · prefix delegation 후에도 `max-pods` 미반영 ·
  온프렘 base 의 k3s 전용 nodeSelector 상속 · 플랫폼만으로 노드 메모리 87% — 는 **전부
  파드가 실제로 뜬 뒤에야 드러났다.** 이 스킬은 구조적으로 그것을 못 본다. 완화책은
  REQ-F-010 의 준비도 판정에 "노드 여유(메모리·`allocatable.pods`)" 를 넣는 것뿐이고,
  그것도 사후가 아니라 사전 추정이다.
- 스킬 이름 미정.
- dev 준비도 항목의 최종 목록 미확정 — `launch` 의 `prod-readiness.md` §1 을 본떠
  작성하되 몇 항목이 될지는 구현 시 정한다.

## 6. Context (brownfield)

| 실측 위치 | 사실 | 제약하는 REQ |
|---|---|---|
| `~/.claude/skills/` 174개 | CI·GitOps 를 만지는 스킬은 **`launch` 하나뿐** | 전체 |
| `launch/references/setup.md` §0 | "dev 매니페스트 없으면 dev 배선부터 — setup 범위 밖, 멈춘다" | REQ-F-009 |
| `launch/SKILL.md` §세 모드 | setup 은 배선을 만들고 **멈춘다**. 이유가 명시돼 있다 | REQ-F-008 |
| `launch/references/prod-readiness.md` §1·§2 | 10항목 3-상태 판정 + "누가 어디서 만드나" 안내. 스킬은 만들지 않고 판정만 한다 | REQ-F-010·011·012 |
| `DevOps/infra` `gitops/bootstrap/applications/` | ns 관례 둘 공존 — `apps-dev`/`survey-radar` vs `apps-internal`/`internal-admap-mcp` | REQ-F-002·003 · REQ-N-002 |
| `apps/admap-mcp` `.gitlab-ci.yml` | dev 잡 3종의 실물(rules·changes·kaniko·promote sed) — 산출 템플릿의 근거 | REQ-F-005 |
| `~/Workspace/carpdm-skills/` | `skills/` 13개 + `docs/{adr,plans,reference,specs}` · `sync.sh` · `/ship` | REQ-F-013 |

## 7. Traceability — clarity trail

| Round | Ambiguity | Targeted dimension | Requirements pinned |
|---|---|---|---|
| 0 | 58% → 47% | topology lock | 컴포넌트 6개 전부 active · REQ-F-009 |
| 1 | 47% → 30% | criteria | REQ-F-008 · REQ-N-003·004 · 잔여 리스크 명명 |
| 2 | 30% → 20% | constraints | REQ-F-001~007 · REQ-N-001·002·005 |
| 3 | 20% → 17% | 컴포넌트 4 | REQ-F-010·011·012 |

## 8. Handoff

Recommended next step: **메인 세션이 직접 구현**한다 — `~/Workspace/carpdm-skills/skills/
<name>/SKILL.md` + `references/` 를 REQ 목록대로 쓰고, 다 되면 `/ship` 으로 배포한다.
`launch/SKILL.md` 의 "이 스킬이 틀린 선택일 때" 절에 새 스킬로 가는 줄을 같은 배포에
추가한다 — 경계는 양쪽에서 같이 적어야 유지된다.

**Treat this spec as the completed requirements step.**
