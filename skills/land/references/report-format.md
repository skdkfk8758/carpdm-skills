# Land Report 포맷 — 카드형 (Step 6 에서 읽는다)

포맷은 **카드형** — 맨 위 한눈 요약, 그 아래 PR 카드, 마지막에 휘발성 sync. 영속
changelog(Landed)를 시각적으로 1순위에, 운영 정리(Local sync)를 부차로 둔다. 머지 건수에
따라 두 형태로 graceful 하게 줄인다.

## 다수 PR (2건+)

```
🚢 Landed N · ⏭ Skipped M · 🔧 Synced
────────────────────────

## Landed

▸ [#451](PR 전체 URL) · fix(make)
  NestJS+Vite 잔재 제거 · make dev→npm run dev(next :3000) · find-free-port.sh 삭제
  ↳ [plan](docs/plans/2026-06-29-makefile-next.md) · ADT-33

▸ [#450](PR 전체 URL) · feat(api)
  …한 일 1~2줄, `·` 구분…
  ↳ [spec](docs/specs/…md) · ADT-31

## Skipped
⏭ [#46](PR 전체 URL) refactor auth — CI 실패 (재시도 후 다시 land)

## Local sync
develop `→ <sha>` · [refactor-auth] rebase · 잔여 워크트리 [stoic-wu]

## 다음 작업
→ [ADT-35](이슈 전체 URL) P1 · rate-limit 대시보드 — ADT-33 Done 으로 unblock. `linear-goal ADT-35`
→ [ADT-38](이슈 전체 URL) P2 · 감사 로그 뷰어 — 추천: forge (이슈 `## 추천` 인용)

▶ 다음 단계
 잔여   refactor-auth — 미머지 커밋 3건 (git) → 이어서 작업 후 다시 land
        ADT-33 — AC 미체크 2건, In Review 잔류 (Linear) → 체크 후 Done
 필수   없음
```

## 단일 PR — 요약 헤더·구분선·섹션 헤딩 생략, 카드 1개 + sync 1줄로 압축

```
🚢 Landed [#451](PR 전체 URL) · fix(make)
NestJS+Vite 잔재 제거 · make dev→npm run dev(next :3000) · find-free-port.sh 삭제
↳ [plan](docs/plans/2026-06-29-makefile-next.md) · ADT-33

🔧 develop `→ <sha>` · 브랜치 정리
→ 다음: [AUT-31](이슈 전체 URL) P1 refresh token rotation — `linear-goal AUT-31`

▶ 다음 단계
 잔여   없음 — ✅ 모든 작업 완료
 필수   없음
 권장   wt-sweep — 잔여 워크트리 [stoic-wu] 정리 (모두 랜딩됨, 지금이 안전 시점)
```

## 포맷 규칙

- **요약 헤더**(`🚢 Landed N · ⏭ Skipped M · 🔧 Synced`)는 **2건+ 일 때만**. 스크롤 없이
  카운트 한눈에. 단일 PR 은 생략.
- **구분선** = box-drawing `─` 반복. markdown `---` **금지** — 바로 위 요약줄을 setext
  H2 헤딩으로 오인 렌더한다. 단일 PR 은 구분선 자체를 생략.
- **카드 헤더** = `▸ [#N](url) · <type(scope)>` — PR 은 전체 URL 링크, type/scope 는 커밋
  제목에서. **한 일**은 헤더 아래 2칸 들여쓰기 `·` 구분 1~2줄. **설계·이슈 링크**는 `↳`
  줄로 분리(없으면 `↳` 줄 통째 생략 — 추측 금지, SKILL.md 의 수집 규칙 그대로).
- **글리프 고정**: 🚢 Landed · ⏭ Skipped · 🔧 Local/Synced · 다음 작업 줄은 plain `→`.
  그 외 이모지 남발 금지(노이즈).
- **`▶ 다음 단계` 블록 = 항상 마지막**(`result:` 직전) — 고정 3행 잔여/필수/권장,
  규칙·행 매핑은 output-contract §N + SKILL.md Step 6 잔여 작업 판정이 SSOT(여기서
  재기술 안 함). 잔여 항목 = `<대상> — <상태> (<출처 git/Linear/handoff>) → <라우팅>`,
  잔여 0건일 때만 `없음 — ✅ 모든 작업 완료` + 권장 행 wt-sweep. 잔여 있으면 완료
  선언·wt-sweep 안내 금지. Local sync 의 워크트리 목록은 두 경우 모두 유지(목록만).
- **다음 작업 줄** = `→ [ID](url) P<n> · <제목> — <kickoff 가이드>`. unblock 근거가 있으면
  가이드 앞에 붙인다. 섹션 자체는 수집 조건 미충족 시 통째 생략(SKILL.md 의 graceful 규칙).
