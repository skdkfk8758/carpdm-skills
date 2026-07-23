# API key 설정 가이드

이 스킬은 `ADMAP_API_KEY` **환경변수 하나**만 읽는다. 스킬 파일 어디에도 키를 저장하지
않는다 — 그래서 키를 바꿀 때 고칠 코드가 없다. 심는 자리 한 곳만 바꾸면 된다.

## 왜 환경변수인가

산출물(`index.html`·`style.json`)은 광고주에게 URL 로 공개된다. 키가 산출물에 들어가면
devtools 로 누구나 볼 수 있다. 그래서 키는 **빌드 시점에만** 쓰이고, 스캐폴드가 끝나면
산출물에는 남지 않는다(`build.mjs` 가 매번 grep 으로 확인한다 — REQ-N-001).

## 심는 자리 — 3가지

| 위치 | 언제 잡히나 | 장점 | 단점 |
| --- | --- | --- | --- |
| **`~/.claude/settings.json` 의 `env`** ← 권장 | Claude Code 세션 전부 | 기획자가 셸 설정을 몰라도 됨. git 밖이라 커밋 사고 없음 | 터미널에서 직접 `node` 를 돌릴 땐 안 잡힘. 값 변경은 세션 재시작 필요 |
| `~/.zshrc` (또는 `~/.bashrc`) | 터미널 + Claude Code 양쪽 | 어디서든 잡힘 | 기획자에게 셸 편집을 시켜야 함 |
| 실행 시 인라인 | 그 명령 한 번 | 아무 데도 안 남음 | 매번 붙여야 하고 셸 히스토리에 남음 |

### 절대 넣지 말 것

- **프로젝트 `.claude/settings.json`** — ADMap repo 에 커밋돼 GitHub 로 올라간다.
- **`.env` / `.env.dev`** — repo 안이고, `NEXT_PUBLIC_*` 규칙과 섞여 사고가 난다.
- **산출 폴더 안 어디든** — 공개 배포 대상이다.
- **스킬 파일(`SKILL.md`·`scripts/*.mjs`)** — 스킬은 코드고 키는 데이터다.

## 권장 형태 (`~/.claude/settings.json`)

`env` 블록에 한 줄 추가한다. 다른 키는 건드리지 않는다.

```jsonc
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1",
    "ENABLE_LSP_TOOL": "1",
    "ADMAP_API_KEY": "admap_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" // ← 이 한 줄
  }
}
```

> `settings.json` 은 주석을 허용하지 않는 엄격한 JSON 이다. 위 `//` 는 설명용이니 실제
> 파일에는 넣지 말 것.

## 스크립트로 세팅 (권장)

손편집보다 안전하다 — 형식 검증 + 라이브 검증 + 백업 + 마스킹 출력을 한다.

```bash
# 값 직접 전달
node scripts/set-key.mjs --key admap_xxxxxxxx

# 셸 히스토리에 안 남기려면 (권장)
echo -n admap_xxxxxxxx | node scripts/set-key.mjs --stdin

# 오프라인이라 라이브 검증을 못 할 때
node scripts/set-key.mjs --key admap_xxxxxxxx --no-verify

# 현재 저장 상태만 확인 (마스킹 출력)
node scripts/set-key.mjs --show
```

스크립트가 하는 일:

1. `admap_` 접두 + 영숫자 형식 검사 — 오타면 저장 전에 막는다.
2. `GET /v1/maps` 로 라이브 검증 — 401 이면 **저장하지 않는다**. 죽은 키가 박히는 걸 막는다.
3. `~/.claude/settings.json` 을 `settings.json.bak-<타임스탬프>` 로 백업.
4. `env.ADMAP_API_KEY` 만 갱신하고 나머지 설정은 보존.
5. 결과를 마스킹해서 출력 — 전체 키를 화면에 다시 찍지 않는다.

`settings.json` 이 깨진 JSON 이면 덮어쓰지 않고 중단한다.

## 반영 시점

`settings.json` 에 저장한 값은 **Claude Code 세션을 다시 시작해야** 잡힌다. 지금 세션에서
바로 쓰려면 셸에도 넣는다:

```bash
export ADMAP_API_KEY=admap_xxxxxxxx
```

## 키 교체(rotation)

1. 새 키를 발급받는다 — SSO 로그인 후 `POST /api/v1/keys/bootstrap` (브라우저 `Origin`
   헤더가 필요해 CLI 로는 안 된다).
2. `node scripts/set-key.mjs --stdin` 으로 갈아끼운다.
3. 세션 재시작.

**스킬 파일도, 이미 만든 산출 폴더도 고칠 필요가 없다.** 산출물에는 키가 없기 때문이다.

## 키가 노출됐다면

- 채팅·이슈·PR·스크린샷에 평문이 들어갔으면 그 키는 폐기하고 재발급한다. 외부 서비스는
  캐시·인덱싱이 남아 삭제해도 회수되지 않는다.
- 공용 키를 여러 기획자가 공유하는 구조라 **누가 유출했는지 audit 으로 분해되지 않는다.**
  교체하면 전원이 새 키로 갈아타야 한다. 이건 알려진 트레이드오프다(spec R11).

## 문제 해결

| 증상 | 원인 | 조치 |
| --- | --- | --- |
| `ADMAP_API_KEY 가 설정되지 않았습니다` | 환경변수 미주입 | 위 3가지 중 하나로 심고 세션 재시작 |
| `HTTP 401 (ADMAP_API_KEY 가 무효하거나 만료됐습니다)` | 키 폐기·오타 | `--show` 로 확인 후 재발급·재설정 |
| `HTTP 403` | 이 키에 허용되지 않은 브랜드/스코프 | 키 발급 범위 확인 |
| settings 에 넣었는데 안 잡힘 | 세션 재시작 안 함 / 터미널에서 직접 실행 | 세션 재시작 또는 `export` 병행 |
