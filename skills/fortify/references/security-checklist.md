# Fortify 보안 체크리스트 — 5 카테고리 상세

Step 2 에서 lazy load. 각 항목마다 **정적 검사**(소스/설정에서 무엇을 grep/Read),
가능하면 **안전 probe**(읽기전용 명령), **확인필요**(코드로 안 보여 사람이 인프라/운영
에서 확인할 것), **severity 힌트**를 둔다.

판정 원칙: 증거로 충족 → PASS, 증거로 위반 → FAIL, 코드·probe 로 안 보임 → **확인필요**
(추측 PASS/FAIL 금지). 모든 probe 는 사용자 소유 대상 한정·사전확인·비침투(SKILL.md
안전 경계).

## 목차
- [① 애플리케이션·코드 보안](#-애플리케이션코드-보안)
- [② 인증·권한 관리](#-인증권한-관리)
- [③ 데이터·통신 보안](#-데이터통신-보안)
- [④ 인프라·네트워크 보안](#-인프라네트워크-보안)
- [⑤ 로깅·모니터링·백업](#-로깅모니터링백업)
- [안전 probe 명령 카탈로그](#안전-probe-명령-카탈로그)

---

## ① 애플리케이션·코드 보안

> 코드 보안 핵심은 `/security-review` 호출로 합성(DRY). 아래는 그 위에 fortify 가
> 확인하는 배포관점 항목. security-review 미설치면 패턴을 직접 적용.

- **주요 취약점 방어 (OWASP Top 10).** SQL Injection / XSS / CSRF / SSRF.
  - 정적: ORM/쿼리빌더 vs raw 쿼리 문자열 결합(`grep` 으로 문자열 + 변수 concat 쿼리),
    템플릿 출력 이스케이프(React 는 기본 escape — `dangerouslySetInnerHTML` grep),
    CSRF 토큰/SameSite, 외부 URL fetch 시 입력 검증(SSRF). security-review 가 1차.
  - severity: 실증되는 주입/XSS = blocker.
- **입력값 검증·필터링.** 서버 측 검증 + 화이트리스트.
  - 정적: validation 라이브러리(zod/joi/class-validator/pydantic) 사용 여부, 라우트
    핸들러가 req body/query/param 을 검증 없이 신뢰하는지. 클라 검증만 있고 서버
    검증 없으면 FAIL 후보.
- **에러 처리.** 스택 트레이스·DB 쿼리·내부 경로가 사용자 응답에 노출 안 됨.
  - 정적: 전역 에러 핸들러 존재, `NODE_ENV=production` 에서 stack 숨김 설정,
    프레임워크 debug 모드 off(`DEBUG`/`app.debug`). probe: 의도적 404/500 응답 본문에
    스택 노출되는지(읽기전용).
  - severity: 스택/쿼리 노출 = should~blocker(정보량에 따라).
- **오픈소스·종속성 CVE.** 알려진 취약점.
  - probe(안전): `npm audit --omit=dev` / `pnpm audit` / `pip-audit` / `osv-scanner`.
    high/critical 있으면 FAIL~should. lockfile 없으면 확인필요.
- **시크릿 관리.** API 키·DB 비번·암호화 키가 소스에 하드코딩 안 됨.
  - 정적: `grep -rniE "(api[_-]?key|secret|password|token|private[_-]?key)\s*[:=]"`
    소스 트리(테스트 픽스처 제외), `.env` 가 `.gitignore` 에 있는지, `git log`/
    추적파일에 `.env`/키 커밋됐는지. 하드코딩된 실 시크릿 = blocker(FAIL).

## ② 인증·권한 관리

- **비밀번호 정책.** 최소 길이·복잡성·(필요시)변경 주기.
  - 정적: 회원가입/비번변경 핸들러의 길이·정규식 검증. 정책 부재면 should.
- **비밀번호 암호화.** 단방향 해시(bcrypt/argon2/PBKDF2/scrypt) + salt.
  - 정적: `grep` 으로 해시 라이브러리 import. **MD5/SHA1/평문 저장 = blocker(FAIL).**
    bcrypt cost / argon2 파라미터 너무 낮으면 should.
- **세션·토큰 관리.**
  - 정적: 세션 타임아웃 설정값, JWT `expiresIn`(과길면 should), refresh 토큰 저장
    위치(localStorage = XSS 노출 should, httpOnly 쿠키 권장), JWT 서명 알고리즘
    (`alg: none`/약한 키 = blocker), 시크릿 하드코딩 여부.
- **접근 제어 (RBAC/ABAC).** 서버 측 권한 검증.
  - 정적: 관리자/타인 데이터 라우트에 권한 미들웨어가 걸려 있는지(authz 가 클라에만
    있고 서버 없으면 blocker — 수평/수직 권한 상승). IDOR 패턴(`/users/:id` 가 소유자
    검증 없이 조회) 점검.
- **다중 인증 (MFA).** 관리자/주요 시스템.
  - 정적으로 보이면 PASS, 운영 콘솔·인프라 MFA 는 **확인필요**(코드 밖).

## ③ 데이터·통신 보안

- **전구간 암호화 (HTTPS/TLS).** TLS 1.2+ 강제, 취약 프로토콜(SSLv3/TLS1.0/1.1) off.
  - probe(안전): `openssl s_client -connect <host>:443 -tls1_1`(거부돼야 정상),
    `curl -sI https://<host>`(200/리다이렉트), HTTP→HTTPS 리다이렉트 확인. 라이브
    대상 없으면 서버설정(nginx `ssl_protocols`/Caddy 기본)으로 정적, 그것도 없으면
    확인필요.
  - severity: HTTPS 미적용 = blocker.
- **안전한 쿠키.** `Secure` · `HttpOnly` · `SameSite`.
  - 정적: 쿠키 설정 코드(`cookie: { secure, httpOnly, sameSite }`), 세션 미들웨어
    옵션. probe: `curl -sI` 의 `Set-Cookie` 속성. 누락 = should~blocker(세션쿠키면 ↑).
- **보안 헤더.** HSTS / CSP / X-Frame-Options / X-Content-Type-Options 등.
  - probe(안전): `curl -sI https://<host>` 응답 헤더 검사. 정적: helmet/보안헤더
    미들웨어 설정. 핵심 헤더(HSTS·CSP) 누락 = should(CSP 부재로 XSS 노출 크면 ↑).
- **중요 데이터 암호화.** 개인정보·결제정보 저장 시 암호화(AES-256 등).
  - 정적: 민감 컬럼(주민번호/카드/전화)에 암호화 로직/라이브러리 적용 여부, KMS/키
    관리. 평문 저장 실증 = blocker. DB 레벨 암호화(TDE)·디스크 암호화는 **확인필요**.

## ④ 인프라·네트워크 보안

> 대부분 코드 밖 — **정직하게 확인필요로 분류**한다. 코드/IaC 로 보이는 것만 PASS/FAIL.

- **방화벽·포트 개방.** 80/443 만 외부, 백엔드 프라이빗 서브넷, SSH 제한(Bastion).
  - IaC(Terraform/CloudFormation/security group, docker-compose `ports`) 있으면
    정적 검사. 없으면 **확인필요**(운영 네트워크). ⚠ 포트 스캔으로 확인 금지(공격성).
- **불필요한 서비스 제거 / 기본 계정 변경.** 미사용 포트·데몬·기본 비번.
  - 대개 **확인필요**(서버 운영). Dockerfile 에서 불필요 패키지/포트 노출은 정적 가능.
- **WAF / DDoS 방어.** Cloudflare/AWS WAF/Shield 등.
  - 설정 파일·IaC 에 있으면 정적, 아니면 **확인필요**.
- **최신 패치.** OS·웹서버·DBMS 보안 패치.
  - 베이스 이미지 태그(Dockerfile `FROM node:18` 같은 구버전/EOL)·런타임 버전은 정적
    가능. 실제 서버 패치 적용은 **확인필요**.

## ⑤ 로깅·모니터링·백업

- **보안 로그 기록.** 로그인 실패·권한 변경·민감 데이터 접근/변경 이벤트 로깅.
  - 정적: auth 핸들러·권한 변경 지점에 로깅 호출 존재 여부. 부재 = should.
- **로그 내 민감정보 마스킹.** 비번·계좌·주민번호 평문 로깅 금지.
  - 정적: `console.log`/logger 호출에 req body·password·token 통째로 찍는 패턴 grep.
    민감정보 평문 로깅 실증 = blocker~should.
- **로그 보존·격리.** 별도 로그 서버/스토리지 전송, 위변조 방지, 법적 보존기간.
  - 로깅 인프라(전송 설정) 있으면 정적, 대개 **확인필요**.
- **백업 체계 + 복구 테스트.** 정기 백업 + 실제 복구 검증.
  - 거의 항상 **확인필요**(운영). 백업 스크립트/cron 이 repo 에 있으면 그것만 정적.

---

## 안전 probe 명령 카탈로그

모두 **읽기전용·비침투**. 사용자 소유 대상 한정, 실행 전 대상·명령 보여주고 확인.
출력이 길면 `logs/` 로 흘리고 관련 줄만 읽는다.

| 목적 | 명령 (예) | 본다 |
|---|---|---|
| 보안 헤더 | `curl -sI https://<host>` | HSTS / CSP / X-Frame-Options / Set-Cookie 속성 |
| HTTPS 리다이렉트 | `curl -sI http://<host>` | 301/308 → https 인지 |
| TLS 버전/cipher | `openssl s_client -connect <host>:443 </dev/null 2>/dev/null \| openssl x509 -noout -dates` | 인증서 만료일 |
| 약한 TLS 거부 | `openssl s_client -connect <host>:443 -tls1_1 </dev/null` | TLS1.1 거부되는지(거부=정상) |
| 의존성 CVE (node) | `npm audit --omit=dev` 또는 `pnpm audit --prod` | high/critical 권고 |
| 의존성 CVE (python) | `pip-audit` 또는 `safety check` | 알려진 취약 패키지 |
| 의존성 CVE (범용) | `osv-scanner -r .` | lockfile 기반 OSV |
| 시크릿 누출 | `git log --all -p -- '*.env*'` / `grep -rniE '(secret\|api[_-]?key\|password)\s*[:=]' --include=*.{js,ts,py,go,env}` | 하드코딩·커밋된 시크릿 |

**금지**(공격성 — 거부): nmap/masscan 포트 스캔, sqlmap/nikto 류 자동 익스플로잇,
부하·DoS, 무차별 대입, 인증 우회 시도, 미인가/제3자 대상 점검.
