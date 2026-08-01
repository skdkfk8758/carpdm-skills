# Report Template

Use Korean by default unless the user asks otherwise. When the user requests a browser-viewable, shareable, printable, or HTML result, use `html-report-template.md` instead of this Markdown-only structure.

## Required Sections

```markdown
## 조사 기준

- 모드: customer-condition | area-monitoring
- 대상: ...
- 필수 조건: ...
- 선호 조건: ...
- 제외 조건: ...
- 조사 시각: ...
- 한계: 네이버 부동산 화면에 보이는 정보 기준
- 사용 출처: live listing source | public market-data supplement

## 매물 요약

| 상태 | 출처유형 | 매물/단지 | 거래 | 가격 | 면적 | 층 | 방향 | 관리비 | 입주 | 핵심 근거 | 확인 필요 | 출처 |
|---|---|---|---|---:|---:|---|---|---:|---|---|---|---|
| recommended | live listing | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... |

## 공공/공식 시세 참고

| 출처 | 대상 | 지표 | 값 | 기준일 | 활용 방식 |
|---|---|---|---:|---|---|
| ... | ... | ... | ... | ... | 브리핑 참고 / 확인 질문 생성 |

## 고객 브리핑 초안

### 추천 매물

- **매물명/단지명**: 고객 조건 중 `...`에 잘 맞습니다. visible information 기준으로 `...`가 장점입니다. 다만 `...`는 중개사가 확인한 뒤 안내하는 것이 좋습니다.

### 확인 필요 매물

- **매물명/단지명**: 조건에는 일부 부합하지만 `...`가 확인되지 않았습니다. 확인 후 추천 여부를 정하는 후보입니다.

## 중개사 확인 질문

- 매물/단지명: ...
  - 실제 입주 가능일은 언제인가?
  - 가격 조정 여지가 있는가?
  - 관리비 포함 항목은 무엇인가?
  - 등기/권리/하자 관련 특이사항은 없는가?

## 제외 매물

- **매물명/단지명**: 제외 사유 ...
```

## Field Guidance

- `상태`: `recommended`, `needs confirmation`, or `excluded`.
- `출처유형`: `live listing` for actual listing pages, `public supplement` for official/public market context.
- `핵심 근거`: visible facts that explain the classification.
- `확인 필요`: missing or ambiguous fields.
- `출처`: source URL when available. If not available, write `not visible`.

## Style

- Write briefing text as a draft, not a final customer message.
- Keep claims tied to visible facts.
- Use concise broker-friendly wording.
- End with limitations when data is incomplete or browsing was blocked.
