# Dedup + 그루핑 — 등록 전 기존 백로그 대조 (SSOT)

> 확인 게이트 **전에** 신규 이슈 초안을 기존 백로그와 대조해 ① 중복 후보를 찾고
> ② 프로젝트/라벨 배치를 근거 있게 제안한다. 결과는 게이트에 병합 표시 — **자동
> 액션 없음**, 판단은 항상 사용자.

## 1. 조회 (읽기 전용)

- 팀 = SKILL.md Step 1 에서 해소한 teamId (repo-map 역매핑).
- `mcp__linear__list_issues` 로 그 팀의 **미완 이슈만** 조회 — 상태 type
  `triage`/`backlog`/`unstarted`/`started` (Done·Canceled 제외 — 완료와 유사한
  신규는 dup 이 아니라 재발/후속일 가능성이 높다).
- **상한 100건, 최근 갱신순.** 초과 백로그는 최근 100건만 대조하고, 게이트에
  "최근 100건 기준" 을 명시한다 (조회 폭주 방지 — 침묵 truncation 금지).
- **대형 응답은 파일로 오프로드된다**(실측: 66건 ≈ 89KB → 토큰 한도 초과). 전체를
  Read 하지 말고 추출한다. 응답은 **null 필드의 키를 통째 생략**하므로(`project`
  없는 이슈엔 키 자체가 없음) 기본값 처리 필수:

```bash
python3 -c '
import json,sys
d = json.load(open(sys.argv[1])); 
for i in d["issues"]:
    if i.get("statusType") not in {"triage","backlog","unstarted","started"}: continue
    labels = [l.get("name",l) if isinstance(l,dict) else l for l in i.get("labels",[])]
    print(i["id"], "|", i.get("statusType"), "|", i.get("project","-"), "|", labels, "|", i["title"])
    print("  ", (i.get("description") or "").replace("\n"," ")[:200])
' "$FILE"
```

## 1.5. 라벨 어휘 실측 (부착 전 필수)

**팀마다 라벨셋이 다르다** — 실측: SSO 팀은 `Improvement`/`Bug`/`Feature` 3종만이고
`area:*` 9종·`type:bug` 류는 존재하지 않는다(그건 타 팀 어휘). `save_issue` 의
`labels` 는 이름을 받으므로 없는 라벨명을 넘기면 팀 라벨셋 오염 또는 에러다.

- 부착 전 `mcp__linear__list_issue_labels {team}` 로 그 팀의 실제 라벨셋을 확보한다
  (1.의 조회와 같은 턴에 병렬 호출 가능).
- **존재하는 어휘 내에서만** 부착: type 성격 라벨은 그 팀의 실제 이름으로
  (예: SSO 는 `Bug`/`Feature`/`Improvement`), `area:*` 는 **보유 팀에만** 적용 —
  없는 팀은 생략하고 게이트에 "이 팀은 area 라벨 미사용" 한 줄 명시.
- 새 라벨이 정말 필요하면 §3 신설 제안과 동일하게 **게이트 승인 후에만**
  `create_issue_label`. 부착 편의로 조용히 라벨을 만들지 않는다.

## 2. Dedup 판정

- 신규 이슈 초안(제목+본문 요지)과 조회 결과를 **모델 판단**으로 대조 — 수치
  임계값 없음. 기준: "같은 작업을 다시 등록하는 것인가?" 수준의 유사성. 표면
  키워드 겹침만으로 후보 올리지 않는다 (오탐 비용 = 게이트 노이즈).
- 이슈당 후보 **최대 3건**. 각 후보에 identifier·제목·상태·한 줄 근거.

## 3. 그루핑 제안

같은 조회 결과에서 유사/인접 이슈들의 `project`·`labels` 분포를 보고 신규 이슈의
배치를 제안한다:

- **project**: 유사 이슈 다수가 속한 프로젝트 → 제안 + 근거 이슈 ID 병기.
  분포가 갈리거나 유사 이슈가 없으면 기존 방식(list_projects / 사용자 확인)으로.
- **`area:*` 라벨**: 유사 이슈들의 area 분포 근거로 제안. 근거 없으면 기존 규칙
  (판별 불가 시 사용자 질의) 유지 — 분포는 질의를 대체하는 근거이지 추측 면허가
  아니다.
- **신설 제안**: 신규 이슈들이 **상호 유사 ≥3건으로 응집**하는데 기존 적합
  프로젝트/라벨이 없으면, 새 프로젝트(또는 라벨) 신설을 게이트에서 제안한다.
  `save_project`/`create_issue_label` 은 **승인 후에만** 호출 (외부 write 게이트
  원칙 동일).

## 4. 게이트 병합 표시

Step 3 확인 게이트에 이슈별로 병합 표시:

```
등록 예정: <팀> / state=Triage / N건 (최근 100건 대조)
1. <제목>
   ⚠ 유사: SSO-42 "..." (Backlog) — <한 줄 근거>
   배치 제안: project=<X> · area:<y>  (근거: SSO-40, SSO-42)
2. <제목>  — 유사 없음 · 배치 제안: 프로젝트 없음 · area:<z>
[신설 제안: 프로젝트 "<이름>" — 이슈 1,3,4 응집, 기존 적합 없음]
```

유사 후보가 있는 이슈는 `AskUserQuestion` 으로 이슈별 4택:

| 선택 | 동작 |
|---|---|
| 그대로 등록 | 신규 생성 (제안된 배치로) |
| 스킵 | 이 이슈 등록 안 함 |
| 기존 보강 | 신규 생성 대신 `save_issue`(id=기존)로 기존 이슈 본문에 내용 병합 |
| 연결 등록 | 신규 생성 + `relatedTo: [기존 id]` 세팅 |

유사 후보가 없으면 4택 없이 일반 게이트(승인/거부)로 족하다.

## Anti-patterns

- 유사 후보를 자동 스킵/자동 연결 — 판정은 휴리스틱, 액션은 사용자.
- 상한 초과 백로그를 조용히 truncate — "최근 100건 기준" 명시 의무.
- 키워드 겹침만으로 후보 남발 — 게이트가 노이즈로 죽는다.
- 분포 근거 없이 area 라벨 추측 부착 — 기존 질의 규칙 우회 금지.
- 승인 전 `save_project`/`create_issue_label` 호출.
