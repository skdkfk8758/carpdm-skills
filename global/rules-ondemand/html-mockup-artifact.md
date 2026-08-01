# HTML Mockup → Claude Artifact — 시안은 URL 로 전달한다

IMPORTANT: HTML 시안(목업·companion·ERD·시각화 리포트 등 **사람이 리뷰할 self-contained HTML 산출물**)을 만드는 모든 스킬·지침은, 파일을 쓴 뒤 **반드시 `Artifact` 도구로 publish 하고 사용자에게 artifact URL 을 딜리버러블로 제시**한다. `open <path>` 로컬 열람 안내는 URL 의 보조일 뿐 대체가 아니다.

## 왜

- 로컬 `.html` 은 터미널 밖(모바일·팀 공유·다른 기기)에서 못 본다. artifact 는 링크 하나로 열리고 기본 비공개라 안전.
- 같은 파일 경로 재-publish 시 URL 유지 — 시안 갱신이 살아있는 링크로 전파된다.

## 규칙

1. **publish 의무** — HTML 시안을 Write 한 직후 `Artifact` 도구로 publish. 산출물 보고에서 시안 행의 딜리버러블은 artifact URL 이다.
2. **로컬 파일은 유지** — Artifact 는 파일에서 publish 되고, 빌드 스킬 Phase 3/4 가 로컬 `.html` 을 입력으로 읽는다. 파일 삭제·미생성으로 대체하지 말 것. 로컬 파일 = 기계 입력 SSOT, artifact URL = 사람 열람 뷰.
3. **갱신 = 같은 경로 재-publish** — plan 수정으로 `.html` 이 갱신되면 같은 `file_path` 로 Artifact 를 다시 호출해 URL 을 유지한다. 새 경로 = 새 URL 이므로 의도 없이 경로를 바꾸지 않는다.
4. **Artifact 도구 규약 준수** — publish 전 `artifact-design` 스킬 로드, `<title>`·`favicon`(재배포 간 동일 유지)·`description` 지정. CSP 제약(외부 asset 0)은 시안 규약(self-contained)과 동일하므로 추가 작업 없음.
5. **민감 내용 게이트** — 시안에 실 credential·PII·내부 비공개 데이터가 박혀 있으면 publish 보류하고 파일로만 전달 + 사유 보고 (artifact 는 외부 서비스).

## 적용 대상

- `mockup` 스킬(design-context 기반 충실 시안 — 시안 충실도 SSOT) · `deep-plan` Step 3 (companion + `-erd.html`) · `deep-prompt` §3.5 (`<slug>-mockup.html`) · `craft-core` pipeline Phase 1 HTML companion (forge/hunt/renew 경유 포함) · `erd` · `imprint`/`prototype`/`frontend-design` 이 시안 목적으로 산출한 HTML · 그 밖의 "HTML 로 시안/목업/도식 만들어줘" 류 지침 전부.
- **예외**: repo 에 트래킹되는 파생 산출물 HTML(예: `loop/harness-visualization.html` — `loop-visualization.md` 룰 소관)과 프로덕션 코드의 `.html` 은 대상 아님. 이들은 git 이 SSOT.

## 강제 (hook 자동 — 비차단 nudge)

- `guard-html-mockup-artifact-nudge.sh` (PostToolUse Write|Edit) — 시안 경로 패턴(`docs/plans/**.html`, `.planning/**.html`, `*-mockup.html`, `*-erd.html`) Write 감지 시 "Artifact publish 했나?" stderr 리마인드. 비차단(훅은 publish 여부를 알 수 없음 — 실제 이행은 본 룰을 읽은 AI). 끄기: `GUARD_HTML_ARTIFACT_NUDGE_DISABLE=1`.

## Anti-patterns

- 시안을 쓰고 `open` 경로만 안내하고 종료 — publish 누락, 본 룰의 존재 이유.
- artifact 로 옮긴다며 로컬 `.html` 미생성/삭제 — 하니스 입력 파괴(규칙 2 위반).
- 시안 갱신 때 새 파일 경로로 publish — URL 분열, 이전 링크가 낡은 시안을 가리킴.

## Related

- `~/.claude/skills/craft-core/references/pipeline.md` Phase 1 — HTML companion 규약(짝).
- `~/.claude/rules-ondemand/loop-visualization.md` — repo 트래킹 HTML 의 반대 정책(예외 근거).
