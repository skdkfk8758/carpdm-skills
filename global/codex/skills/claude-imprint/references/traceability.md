# Token-Traceability — 이 스킬의 법칙과 검증

imprint 의 존재 이유. 생성물의 모든 색/크기/타이포 값이 token 으로 역추적되고,
인라인 하드코딩 raw 값이 0이어야 한다. 이 파일은 (1) 없는 값을 *파생*하는 규칙,
(2) traceability 를 *검증*하는 grep 을 정의한다.

## 법칙 (다시)

raw 값이 사는 곳은 `theme/tokens.css` 의 `:root` 단 하나. 그 밖의 모든 파일은
named token(`var(--…)` 또는 Tailwind 클래스)만 참조한다. 위반 = 어딘가 token 을
안 거치고 값을 박은 것 = conformance 실패.

## 파생(derive) 규칙 — 없는 값을 충실하게 만들기

진짜 컴포넌트는 DESIGN.md 가 거의 안 주는 값들이 필요하다: hover/focus/active/
disabled state 색, border-radius, shadow, transition, focus ring. 이걸 인라인으로
박으면 traceability 가 깨진다. 대신 **기존 token 에서 합성해 tokens.css 의
`derived` 섹션에 named token 으로 기록**한다(REQ-F-005).

derive 는 *발명이 아니라 도출*이어야 한다 — 기존 token 에서 결정론적으로 끌어낸다.
권장 도출:

| 필요한 값 | 도출 방법 (기존 token 기반) |
|---|---|
| `*-hover` 색 | 해당 색의 명도(L) ±6~10% (어두운 배경이면 밝게, 밝으면 어둡게) |
| `*-active` 색 | hover 보다 한 단계 더 (L ±12~16%) |
| `*-disabled` 색 | 해당 색의 opacity 0.4~0.5, 또는 surface 쪽으로 mix |
| `focus ring` | primary(또는 accent)의 opacity 0.4 |
| `border` 색 (없으면) | text 와 surface 사이 mix, 혹은 가장 옅은 gray scale |
| `radius` (없으면) | spacing scale 기반 (예: space-2 = sm, space-4÷2 = md) |
| `shadow` (없으면) | text 색 기반 저-opacity 다단 그림자 (sm/md/lg 단계) |
| `transition` | 공통값 (예: 150ms ease) — 색이 아니므로 utility token 으로 |

각 derived token 은 **무엇에서 어떻게** 파생했는지 주석 필수:

```css
/* --- derived (DESIGN.md 에 없음) --- */
--color-primary-hover:    #5249e0;            /* derived: primary L-8% */
--color-primary-disabled: rgba(99,91,255,.45);/* derived: primary @45% */
--ring-focus:             rgba(99,91,255,.4); /* derived: primary @40% */
--radius-md:              8px;                /* derived: space-4 ÷ 2 */
--shadow-md:              0 4px 12px rgba(26,31,54,.10); /* derived: text-primary @10% */
```

원칙:
- **가능하면 적게 파생하라.** DESIGN.md 가 준 게 있으면 그걸 쓴다. 파생은 빈칸 메우기지 취향이 아니다.
- **derived 를 사용자에게 알린다.** 파이프라인 보고에 "DESIGN.md 에 radius/shadow 가 없어 N개 token 을 파생함 — 검토 바람" 을 남긴다. 사용자가 원본에 없던 값을 인지하고 조정할 수 있어야 한다.
- **그래도 token 이다.** 파생값도 tokens.css 에 있으므로 grep 검증을 통과한다.

## 검증 — traceability 게이트 (핵심 acceptance, REQ-N-001)

components/ 와 preview.html 에서 **raw 값이 0건**임을 기계적으로 확인한다.
tokens.css 는 검증 대상에서 제외(거기가 raw 값의 합법적 거처).

```bash
OUT=imprint-out   # 실제 출력 경로로

# 1) raw hex 색 (#abc / #aabbcc / #aabbccdd) — tokens.css 제외
grep -rEn '#[0-9a-fA-F]{3,8}\b' "$OUT" \
  --include='*.tsx' --include='*.jsx' --include='*.html' --include='*.css' \
  | grep -v '/tokens\.css:'

# 2) raw px/rem 리터럴 — tokens.css 제외
#    (Tailwind 클래스 p-4 등은 숫자만이라 안 걸림; style="...16px" / 인라인 css 가 표적)
grep -rEn '[0-9]+(px|rem)\b' "$OUT" \
  --include='*.tsx' --include='*.jsx' --include='*.html' --include='*.css' \
  | grep -v '/tokens\.css:'

# 3) rgb()/hsl() 인라인 색 — tokens.css 제외
grep -rEn '\b(rgb|rgba|hsl|hsla)\(' "$OUT" \
  --include='*.tsx' --include='*.jsx' --include='*.html' --include='*.css' \
  | grep -v '/tokens\.css:'
```

**통과 기준: 세 grep 모두 출력 0줄.** 한 줄이라도 나오면:

1. 그 값이 DESIGN.md token 으로 표현 가능하면 → 해당 Tailwind 클래스/`var()` 로 교체.
2. DESIGN.md 에 없는 값이면 → tokens.css 의 derived 섹션에 token 추가 후 참조로 교체.

0이 될 때까지 반복한다. 이 게이트가 imprint 와 frontend-design 을 가르는 선이다 —
통과 못 하면 "충실 재현" 이라 부를 수 없다.

## 예외·주의

- **preview.html 의 `:root`**: 독립 시안은 tokens.css 의 `:root` 블록을 인라인으로
  포함할 수 있다(빌드 불요 목적). 그 인라인 `:root` 블록은 "token 정의" 이므로 raw
  값 허용 — grep 시 그 블록도 제외하거나, preview.html 의 `:root{…}` 안쪽만 면제한다.
  단 `:root` *밖*의 마크업/스타일에는 raw 값 0.
- **SVG/이미지 안의 색**: 외부 에셋이면 token 화 대상이 아니다. 하지만 컴포넌트가
  그리는 인라인 SVG 의 `fill`/`stroke` 는 token 을 써야 한다(`fill="var(--color-…)"`).
- **Tailwind 임의값(`bg-[#fff]`)**: 금지. 이건 클래스처럼 보이지만 raw 값 박기다 —
  grep 1번에 걸리며 실패다. 반드시 테마 키(`bg-primary`)를 쓴다.
