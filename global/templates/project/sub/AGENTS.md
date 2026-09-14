# <폴더명> — <한 줄 역할>

## 스택·진입점
- 런타임/프레임워크: <RUNTIME-FRAMEWORK>
- 진입점: <ENTRYPOINT-FILE>

## 검증
<!-- 루트에서 `pnpm --filter <name> ...` 형식으로 돈다면 그 형식을 그대로 쓴다 -->
| 종류 | 명령 |
|---|---|
| typecheck | `<VERIFY-CMD-1>` |
| test | `<VERIFY-CMD-2>` |
| build | `<VERIFY-CMD-3>` |

## 테스트 위치·패턴
- 위치: <TEST-DIR>
- 패턴: <TEST-NAMING-PATTERN>

## 경계
- 이 폴더 밖 파일을 고치지 않는다.
- 공유 패키지(`packages/*`)의 인터페이스 변경은 ADR 후 진행한다.
- 환경변수는 `.env.example` 에 키만 남긴다.

## 사람만 아는 규칙
- <코드·문서를 읽어도 알 수 없는 것만 여기 적는다. 없으면 이 줄을 지운다>

레포 규칙은 루트 `AGENTS.md`, 모델 티어·스텝 규율은 글로벌 `~/.claude/CLAUDE.md` 를 따른다.
