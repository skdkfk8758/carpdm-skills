---
name: claude-imprint
description: Imported Claude skill for reproducing an extracted design system faithfully in frontend artifacts.
---

# Imprint — 추출된 디자인 시스템을 한 톨도 벗어나지 않고 새기다

누군가 design-extractor.com 으로 어떤 사이트(Stripe, Apple, Notion…)의 디자인을
추출해 `DESIGN.md` 한 파일을 손에 들고 온다. 그들이 원하는 건 "Claude 가 알아서
멋지게 만든 UI" 가 아니다 — 그건 `frontend-design` 의 일이다. 그들이 원하는 건
*그 추출된 디자인 그대로* 입은 컴포넌트다. 색 하나, 폰트 하나, 간격 하나가
원본 token 을 벗어나면 그건 다른 디자인이고, 실패다.

그래서 이 스킬의 유일한 법칙은 **token-traceability** 다: 생성하는 테마·컴포넌트·
시안의 모든 색/크기/타이포 값이 (a) DESIGN.md 의 token 이거나 (b) 그 token 에서
파생해 테마에 명시 기록한 token 이어야 한다. **인라인 하드코딩된 raw hex/px 는
0개.** 이 한 줄이 imprint 를 frontend-design 과 가른다 — 저쪽은 발명하고, 이쪽은
준수한다.

## 입력 — DESIGN.md 파일

이 스킬은 **`DESIGN.md` 파일 경로**를 입력으로 받는다. design-extractor 는 공개
API 가 없다(UI 전용) — 추출은 *사람이* 웹에서 URL 을 붙여넣어 `DESIGN.md` 를
받아 repo 에 둔다. imprint 는 그 파일을 읽을 뿐, 네트워크 추출을 하지 않는다.

- **파일이 주어지면** → 곧장 파이프라인으로.
- **파일이 없으면** → 추출을 대신 해줄 수 없으니, 사용자를 gallery 로 안내한다:
  > "imprint 는 design-extractor 의 `DESIGN.md` 가 필요합니다.
  > https://www.design-extractor.com/gallery 에서 원하는 사이트(Apple/Figma/
  > Notion/Stripe/Shopify 등 25+)를 고르거나, 직접 URL 을 붙여넣어 `DESIGN.md` 를
  > 받아 repo 에 두고 그 경로를 주세요."
  추측으로 token 을 지어내 진행하지 말 것 — 그건 conformance 위반이다.

DESIGN.md 가 *정확히* 어떤 필드를 담는지는 추출마다 다를 수 있다. 스키마를
가정하지 말고 실제 파일을 읽어 거기 있는 token 을 발견하라 — 파싱 전략은
[`references/tokens-and-theme.md`](references/tokens-and-theme.md).

## 파이프라인

```
1. Parse     DESIGN.md 읽기 → token 발견 (색/타이포/스페이싱/radius/shadow/…)
             → verify: 발견한 token 집합을 사용자에게 보고
2. Theme     token → 단일 token 정의 파일 + Tailwind 매핑
             → verify: DESIGN.md 의 모든 token 이 테마에 1:1, 누락 0
3. Derive    컴포넌트에 필요하나 DESIGN.md 에 없는 값(hover/focus/disabled/
             radius/shadow/transition) → 기존 token 에서 합성 → "derived" 로 명시 기록
             → verify: 모든 파생값이 token 정의 파일에 named derived token 으로 존재
4. Components 테마 token 만 쓰는 React+Tailwind 예시 컴포넌트
             → verify: 인라인 raw 값 0, 에러 없이 렌더
5. Mockup    빌드 없이 브라우저에서 바로 열리는 독립 HTML 시안
             → verify: 단독으로 컴포넌트 미리보기 표시
6. Verify    token-traceability 게이트 (핵심 acceptance)
             → verify: 컴포넌트·시안에서 raw hex/px grep = 0 (token 정의 파일 밖)
```

각 단계는 verify 로 잠근다. verify 실패면 다음 단계로 넘어가지 말고 그 단계를
고친다 — 특히 6번은 이 스킬의 존재 이유다.

## 핵심 법칙 — token-traceability

raw 값(색 hex, px/rem 크기)이 살 수 있는 곳은 **token 정의 파일 단 하나**다
(`theme/tokens.css` 의 `:root`). 그 밖의 모든 곳 — Tailwind config, React
컴포넌트, HTML 시안 — 은 *named token* 만 참조한다. 이렇게 하면:

- 디자인이 한 곳에 모여 원본 충실성을 검증·수정하기 쉽다.
- 검증이 기계적이다: token 정의 파일을 뺀 나머지에서 raw hex/px 를 grep → **0이어야
  통과**. 1건이라도 있으면 그건 어딘가 token 을 안 거치고 값을 박았다는 뜻 = 실패.

DESIGN.md 에 없어서 *만들어낸* 값(hover 색, 그림자 등)도 예외가 아니다 — 인라인하지
말고 token 정의 파일에 `derived` 섹션의 named token 으로 넣고, 무엇에서 어떻게
파생했는지 주석을 단다(예: `--color-primary-hover: /* derived: primary L-10% */`).
파생도 token 이므로 traceability 가 유지되고, 사용자가 "이건 원본에 없던 내 추정"
임을 한눈에 본다.

법칙·파생 규칙·검증 grep 상세: [`references/traceability.md`](references/traceability.md).

## 출력

기본 출력 레이아웃(저장 위치는 생성 시 사용자와 확정 — 기본 제안 `imprint-out/`):

```
<out>/
├── theme/
│   ├── tokens.css         # 유일하게 raw 값이 사는 곳 (DESIGN.md token + derived)
│   └── tailwind.config.js # named token → CSS var 매핑 (raw 값 없음)
├── components/            # React+Tailwind 예시 (token 클래스만 사용)
│   ├── Button.tsx
│   ├── Card.tsx
│   └── …                  # 대표 세트 (기본: Button/Card/Input/Nav — 사용자 요청 시 조정)
└── preview.html           # 독립 HTML 시안 (빌드 불요, 같은 token 사용)
```

컴포넌트 세트는 고정이 아니다 — 사용자가 특정 컴포넌트/화면을 지정하면 그것을,
지정 안 하면 대표 세트를 생성한다. 출력 shape(Tailwind config 모양, 컴포넌트
컨벤션, 독립 HTML 구성)은 [`references/output.md`](references/output.md).

생성을 마치면 `/Users/carpdm/.codex/skills/claude-craft-core/references/output-contract.md` 의 종료
블록으로 보고한다 — `result:` 한 줄(무엇을 어느 DESIGN.md 로 재현했는지 + raw hex/px
grep = 0 확인) + 산출물 열기 블록(L1+L2). 대표 열기 행은 독립 시안 `preview.html`.
imprint 는 종착 산출이라 다음 스킬 제안(L3)은 하지 않는다. 예:

```
result: <brand> DESIGN.md 재현 — 컴포넌트 N개 + theme + 시안, raw hex/px = 0

산출물 — 열기:
- 시안 `imprint-out/preview.html`  →  `open imprint-out/preview.html`
- 테마 `imprint-out/theme/tokens.css`  →  `open imprint-out/theme/tokens.css`

(`open` = macOS. Linux `xdg-open`, Windows `start`.)
```

## 이 스킬이 아닌 것 (frontend-design 과의 경계)

- **새 미감을 발명하지 않는다.** DESIGN.md(또는 그 파생)로 도출 불가능한 디자인
  값을 도입하면 conformance 위반이다. "더 예쁘게" 하려고 원본 token 을 바꾸지 말 것.
- **추출하지 않는다.** URL/스크린샷에서 token 을 뽑는 건 imprint 의 일이 아니다 —
  그건 design-extractor 가 (사람 손으로) 한다.
- **빌드 파이프라인이 아니다.** craft-core(forge/hunt/renew/reshape) 와 무관한
  단독 스킬이다. 테스트 스위트를 세우지 않으며, 검증은 위 grep 기반 traceability 다.

자유 창작 UI 가 필요하면 `frontend-design` 으로, 기능 구현은 `forge` 로 보내라.
