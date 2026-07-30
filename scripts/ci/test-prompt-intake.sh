#!/usr/bin/env bash
# Acceptance tests for the prompt-intake hook + base-rate aggregator.
#
# Targets the repo mirror by default so CI can run it without a live
# ~/.claude install. Pass an explicit hook path to test the live copy.
#
#   bash scripts/ci/test-prompt-intake.sh [hook.py] [baserate.py]
#
# Every case maps to a numbered Acceptance item in
# docs/plans/2026-07-30-prompt-intake-classifier.md.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOOK="${1:-$REPO_ROOT/global/hooks/prompt-intake.py}"
AGG="${2:-$REPO_ROOT/global/scripts/prompt-intake-baserate.py}"

PASS=0
FAIL=0
FAILED_CASES=()

ok() { PASS=$((PASS + 1)); printf '  ok   %s\n' "$1"; }
no() {
  FAIL=$((FAIL + 1))
  FAILED_CASES+=("$1")
  printf '  FAIL %s\n' "$1"
  [ -n "${2:-}" ] && printf '       %s\n' "$2"
}
assert_eq() { # name expected actual
  if [ "$2" = "$3" ]; then ok "$1"; else no "$1" "expected [$2] got [$3]"; fi
}

TMP="$(mktemp -d)"
trap 'chmod -R u+rwX "$TMP" 2>/dev/null; rm -rf "$TMP"' EXIT

# Each case gets a fresh log dir so line counts are unambiguous.
new_logdir() {
  local d="$TMP/log-$1"
  mkdir -p "$d"
  printf '%s' "$d"
}

# run_hook <logdir> <payload-json> [extra env assignments...]
run_hook() {
  local dir="$1" payload="$2"
  shift 2
  env PROMPT_INTAKE_LOG_DIR="$dir" "$@" python3 "$HOOK" <<<"$payload"
}

records() { cat "$1/records.jsonl" 2>/dev/null; }
count() { records "$1" | wc -l | tr -d ' '; }
field() { # logdir key
  records "$1" | tail -1 | python3 -c "
import json,sys
raw = sys.stdin.read().strip()
try:
    r = json.loads(raw) if raw else {}
except Exception:
    print('<PARSE-FAIL>'); raise SystemExit(0)
print(r.get('$2', '<MISSING>'))
" 2>/dev/null
}

payload() { # prompt [session_id]
  python3 -c "
import json,sys
print(json.dumps({
  'session_id': sys.argv[2] if len(sys.argv) > 2 else 'sess-test',
  'cwd': '/tmp/proj',
  'prompt': sys.argv[1],
}))
" "$1" "${2:-sess-test}"
}

echo "hook: $HOOK"
echo "agg:  $AGG"
echo

# ── Acceptance 1 · 5 — one record, silent stdout, exit 0 ────────────────────
d="$(new_logdir a1)"
out="$(run_hook "$d" "$(payload '로그인 기능 추가해줘')")"
rc=$?
assert_eq "A1  payload 1건 → JSONL +1" "1" "$(count "$d")"
assert_eq "A5  stdout 빈 문자열" "" "$out"
assert_eq "A5b exit 0" "0" "$rc"

# ── Acceptance 2 — exact schema key set ─────────────────────────────────────
EXPECTED_KEYS='agent_id,agent_type,banner_stripped,cwd,has_backtick,has_error_text,has_number,has_path,is_question,is_slash_command,prompt_head,prompt_len,scope_word_hits,session_id,specifics_count,ts,vague_word_hits,verb_class'
actual_keys="$(records "$d" | tail -1 | python3 -c "
import json,sys
try: print(','.join(sorted(json.loads(sys.stdin.read()).keys())))
except Exception: print('<PARSE-FAIL>')
" 2>/dev/null)"
assert_eq "A2  스키마 키 집합 정확 일치" "$EXPECTED_KEYS" "$actual_keys"

# ── Acceptance 3 — verb_class ───────────────────────────────────────────────
for pair in '로그인 기능 추가해줘|build' '500 에러 나|fix' '이 룰 설명해줘|explain' '안녕|none'; do
  prompt="${pair%|*}"; expected="${pair#*|}"
  d="$(new_logdir "verb-$expected")"
  run_hook "$d" "$(payload "$prompt")" >/dev/null
  assert_eq "A3  verb_class '$prompt' → $expected" "$expected" "$(field "$d" verb_class)"
done

# ── Acceptance 4 — specifics_count ──────────────────────────────────────────
d="$(new_logdir a4)"
run_hook "$d" "$(payload 'guard-file-size.sh 의 300 을 500 으로')" >/dev/null
sc="$(field "$d" specifics_count)"
if [ "${sc:-0}" -ge 3 ] 2>/dev/null; then ok "A4  specifics_count ≥ 3 (got $sc)"; else no "A4  specifics_count ≥ 3" "got [$sc]"; fi

# ── Acceptance 6 — no classification logic in source ────────────────────────
# Strip comments and docstrings first — prose that *denies* classifying
# ("no verdict, no label") must not read as classifying.
code_only="$(python3 - "$HOOK" <<'PYEOF'
import ast, sys
src = open(sys.argv[1]).read()
tree = ast.parse(src)
for node in ast.walk(tree):
    if isinstance(node, (ast.Module, ast.FunctionDef, ast.ClassDef)):
        doc = ast.get_docstring(node, clean=False)
        if doc:
            src = src.replace(doc, "")
print("\n".join(l.split("#")[0] for l in src.splitlines()))
PYEOF
)"
# Match labels as *emitted values* (quoted literals), not as identifiers —
# VAGUE_RE is the vague-word dictionary backing the vague_word_hits signal,
# which is raw data, not a verdict.
if printf '%s' "$code_only" | grep -Eq '"(VAGUE|CLEAR|interview|proceed|needs_interview)"|verdict|classification'; then
  no "A6  훅 소스에 라벨 판정 없음" "a label literal appears in executable code"
else
  ok "A6  훅 소스에 라벨 판정 없음"
fi

# ── Acceptance 7 · 8 — Orca banner stripping ────────────────────────────────
BANNER='Linked Linear issue: ADT-431
https://linear.app/adtype-intelligence/issue/ADT-431/map-credentials-route-adm-179

'
d="$(new_logdir a7)"
run_hook "$d" "$(payload "$BANNER")" >/dev/null
assert_eq "A7  배너만 → specifics_count 0" "0" "$(field "$d" specifics_count)"
assert_eq "A7b 배너만 → banner_stripped true" "True" "$(field "$d" banner_stripped)"

d="$(new_logdir a8)"
run_hook "$d" "$(payload "${BANNER}/renew")" >/dev/null
assert_eq "A8  배너 뒤 /renew → is_slash_command" "True" "$(field "$d" is_slash_command)"

# ── Acceptance 11 — hook work < 100ms ───────────────────────────────────────
# Measured end-to-end, this assertion is dominated by interpreter startup
# (~50ms here), so it goes red on a loaded runner for reasons unrelated to the
# hook. Subtract a bare-interpreter baseline and assert on the remainder.
baseline_ms=$(python3 -c '
import subprocess, time
runs = []
for _ in range(5):
    t = time.time(); subprocess.run(["python3", "-c", "pass"]); runs.append((time.time()-t)*1000)
print(int(min(runs)))
')
d="$(new_logdir a11)"
max_ms=0
for _ in $(seq 10); do
  s=$(python3 -c 'import time;print(int(time.time()*1000))')
  run_hook "$d" "$(payload '성능 측정용 프롬프트')" >/dev/null
  e=$(python3 -c 'import time;print(int(time.time()*1000))')
  ms=$((e - s))
  [ "$ms" -gt "$max_ms" ] && max_ms=$ms
done
work_ms=$((max_ms - baseline_ms))
[ "$work_ms" -lt 0 ] && work_ms=0
if [ "$work_ms" -lt 100 ]; then
  ok "A11 훅 작업 ${work_ms}ms < 100ms (실측 ${max_ms}ms − 인터프리터 기동 ${baseline_ms}ms)"
else
  no "A11 훅 작업 < 100ms" "work ${work_ms}ms (raw ${max_ms}ms − baseline ${baseline_ms}ms)"
fi

# ── Acceptance 12 — three failure paths all exit 0, no log growth ───────────
d="$(new_logdir a12a)"
run_hook "$d" "$(payload 'seed')" >/dev/null
before="$(count "$d")"
chmod 000 "$d/records.jsonl"
run_hook "$d" "$(payload '쓰기 불가 파일')" >/dev/null 2>&1
assert_eq "A12a chmod 000 로그 → exit 0" "0" "$?"
chmod 600 "$d/records.jsonl"
assert_eq "A12a 로그 증가 0" "$before" "$(count "$d")"

# A missing intermediate directory is NOT a failure path — makedirs(exist_ok)
# just creates it. Only an unwritable parent actually exercises REQ-N-002.
mkdir -p "$TMP/ro-parent" && chmod 500 "$TMP/ro-parent"
run_hook "$TMP/ro-parent/child" "$(payload '읽기전용 부모')" >/dev/null 2>&1
assert_eq "A12b 생성 불가 부모 → exit 0" "0" "$?"
assert_eq "A12b 로그 증가 0" "0" "$(count "$TMP/ro-parent/child")"
chmod 700 "$TMP/ro-parent"

d="$(new_logdir a12c)"
env PROMPT_INTAKE_LOG_DIR="$d" python3 "$HOOK" <<<'{"prompt": broken json' >/dev/null 2>&1
assert_eq "A12c 깨진 JSON → exit 0" "0" "$?"
assert_eq "A12c 로그 증가 0" "0" "$(count "$d")"

# ── Acceptance 13 — 1.5MB payload survives (no E2BIG) ───────────────────────
d="$(new_logdir a13)"
python3 -c "
import json
print(json.dumps({'session_id':'big','cwd':'/tmp','prompt':'x'*1500000}))
" >"$TMP/big.json"
env PROMPT_INTAKE_LOG_DIR="$d" python3 "$HOOK" <"$TMP/big.json" >/dev/null 2>&1
assert_eq "A13 1.5MB payload → exit 0" "0" "$?"
assert_eq "A13 레코드 정확히 1건" "1" "$(count "$d")"

# ── Acceptance 14 — file 0600, dir 0700 ─────────────────────────────────────
d="$(new_logdir a14)"
run_hook "$d" "$(payload '권한 확인')" >/dev/null
# Not `stat`: macOS -f means "format", Linux -f means "filesystem info", so the
# usual `stat -f … || stat -c …` fallback never fires on Linux — it succeeds
# with the wrong output instead.
mode_of() { python3 -c "import os,sys;print(format(os.stat(sys.argv[1]).st_mode & 0o777, 'o'))" "$1"; }
assert_eq "A14 로그 파일 0600" "600" "$(mode_of "$d/records.jsonl")"
assert_eq "A14 로그 디렉토리 0700" "700" "$(mode_of "$d")"

# ── Acceptance 15 — truncation, no sha, secret redaction ────────────────────
d="$(new_logdir a15)"
run_hook "$d" "$(payload "$(python3 -c 'print("가"*200)')")" >/dev/null
# Guard against a false pass: the record must exist before its fields mean anything.
assert_eq "A15 레코드 존재(전제)" "1" "$(count "$d")"
# Character count, not bytes — Korean is 3 bytes/char in UTF-8 and awk length
# would report 360 for a correct 120-character head.
head_len="$(records "$d" | tail -1 | python3 -c "
import json,sys
try: print(len(json.loads(sys.stdin.read()).get('prompt_head','')))
except Exception: print(999)
" 2>/dev/null)"
if [ "${head_len:-999}" -le 120 ]; then ok "A15 prompt_head ≤ 120 (got $head_len)"; else no "A15 prompt_head ≤ 120" "got $head_len"; fi
assert_eq "A15 prompt_sha 부재" "<MISSING>" "$(field "$d" prompt_sha)"

d="$(new_logdir a15b)"
run_hook "$d" "$(payload 'sk-ant-api03-SECRETVALUE1234567890 이거 확인해줘')" >/dev/null
assert_eq "A15 레코드 존재(전제, redaction)" "1" "$(count "$d")"
if [ "$(count "$d")" = "1" ] && records "$d" | grep -q 'SECRETVALUE1234567890'; then
  no "A15 시크릿 redaction" "raw secret present in record"
elif [ "$(count "$d")" = "1" ]; then
  ok "A15 시크릿 redaction"
else
  no "A15 시크릿 redaction" "no record written — cannot judge"
fi

# ── Acceptance 16 — disable switch ──────────────────────────────────────────
# Control first: without the switch the same payload MUST be recorded, else
# "no growth" proves nothing.
d="$(new_logdir a16)"
run_hook "$d" "$(payload '비활성 확인')" >/dev/null
assert_eq "A16 대조군 — 스위치 없으면 1건 기록" "1" "$(count "$d")"
run_hook "$d" "$(payload '비활성 확인')" PROMPT_INTAKE_DISABLE=1 >/dev/null
assert_eq "A16 DISABLE=1 → 증가 0 (여전히 1건)" "1" "$(count "$d")"

# ── Acceptance 9 · 10 · 17 — aggregator ─────────────────────────────────────
if [ -f "$AGG" ]; then
  d="$(new_logdir agg)"
  python3 - "$d/records.jsonl" <<'PYEOF'
import json, os, sys
path = sys.argv[1]
rows = []
# 3 rows meet the base-rate condition (build/change + specifics 0)
for i, verb in enumerate(["build", "build", "change"]):
    rows.append({"ts": 1000 + i, "session_id": "s1", "verb_class": verb,
                 "specifics_count": 0, "prompt_len": 30, "prompt_head": "x"})
# 7 rows do not
for i in range(7):
    rows.append({"ts": 2000 + i, "session_id": "s2", "verb_class": "explain",
                 "specifics_count": i, "prompt_len": 30, "prompt_head": "x"})
os.makedirs(os.path.dirname(path), exist_ok=True)
with open(path, "w") as f:
    for r in rows:
        f.write(json.dumps(r) + "\n")
PYEOF
  agg_out="$(PROMPT_INTAKE_LOG_DIR="$d" python3 "$AGG" 2>&1)"
  if printf '%s' "$agg_out" | grep -q '3건 / 전체 10건 = 30.0%'; then
    ok "A9  집계 정확값 3건 / 전체 10건 = 30.0%"
  else
    no "A9  집계 정확값" "got: $(printf '%s' "$agg_out" | head -3 | tr '\n' ' ')"
  fi

  d="$(new_logdir agg-empty)"
  : >"$d/records.jsonl"
  empty_out="$(PROMPT_INTAKE_LOG_DIR="$d" python3 "$AGG" 2>&1)"
  rc=$?
  if printf '%s' "$empty_out" | grep -q '샘플 없음'; then ok "A10 빈 로그 → 샘플 없음"; else no "A10 빈 로그 → 샘플 없음" "got: $empty_out"; fi
  assert_eq "A10 빈 로그 → exit 0" "0" "$rc"

  # correction_flag is computed by the aggregator, scoped per session.
  d="$(new_logdir agg-corr)"
  python3 - "$d/records.jsonl" <<'PYEOF'
import json, os, sys
path = sys.argv[1]
rows = [
    # same session, 10s apart, short corrective follow-up → 1 correction
    {"ts": 1000, "session_id": "s1", "verb_class": "build", "specifics_count": 0,
     "prompt_len": 40, "prompt_head": "로그인 기능 추가해줘"},
    {"ts": 1010, "session_id": "s1", "verb_class": "none", "specifics_count": 0,
     "prompt_len": 12, "prompt_head": "아니 그게 아니라"},
    # different session, adjacent in file, must NOT count
    {"ts": 1015, "session_id": "s2", "verb_class": "none", "specifics_count": 0,
     "prompt_len": 8, "prompt_head": "다시"},
]
os.makedirs(os.path.dirname(path), exist_ok=True)
with open(path, "w") as f:
    for r in rows:
        f.write(json.dumps(r) + "\n")
PYEOF
  corr_out="$(PROMPT_INTAKE_LOG_DIR="$d" python3 "$AGG" 2>&1)"
  if printf '%s' "$corr_out" | grep -q '정정 발화: 1건'; then
    ok "A17 correction 사후 계산 — 교차 세션 제외"
  else
    no "A17 correction 사후 계산" "got: $(printf '%s' "$corr_out" | grep -i 정정 || echo '<no 정정 line>')"
  fi
else
  no "A9/A10/A17 집계 스크립트" "not found: $AGG"
fi

# ── Signal VALUES, not just keys — mutation testing showed a key-set check
#    lets every has_*/hits/is_* field be hardcoded without a test noticing. ───
d="$(new_logdir values)"
run_hook "$d" "$(payload 'src/app/main.py 에서 500 Error 가 `render()` 전부 터져요 ADT-431 왜죠?')" >/dev/null
check_field() { assert_eq "AV  $1 == $2" "$2" "$(field "$d" "$1")"; }
check_field has_path True
check_field has_number True
check_field has_error_text True
check_field has_backtick True
check_field is_question True
check_field scope_word_hits 1
check_field banner_stripped False
vh="$(field "$d" vague_word_hits)"
if [ "${vh:-0}" -ge 0 ] 2>/dev/null; then ok "AV  vague_word_hits 정수 ($vh)"; else no "AV  vague_word_hits 정수" "got [$vh]"; fi

# Negative control: without these features every flag must be False/0. Without
# it, "always True" implementations pass the block above.
d="$(new_logdir values-neg)"
run_hook "$d" "$(payload '이거 좀 해주세요')" >/dev/null
for f in has_path has_number has_error_text has_backtick is_question banner_stripped is_slash_command; do
  assert_eq "AVN $f == False" "False" "$(field "$d" "$f")"
done
assert_eq "AVN scope_word_hits == 0" "0" "$(field "$d" scope_word_hits)"

# REQ-F-002 also pins types, which a key-set check cannot see.
type_report="$(records "$d" | tail -1 | python3 -c "
import json,sys
r = json.loads(sys.stdin.read())
want = {'ts': int, 'prompt_len': int, 'specifics_count': int, 'scope_word_hits': int,
        'vague_word_hits': int, 'prompt_head': str, 'verb_class': str,
        'banner_stripped': bool, 'has_path': bool, 'has_number': bool,
        'has_error_text': bool, 'has_backtick': bool, 'is_question': bool,
        'is_slash_command': bool}
bad = [k for k, t in want.items() if not isinstance(r.get(k), t)]
print(','.join(bad) if bad else 'OK')
" 2>/dev/null)"
assert_eq "AT  스키마 타입 일치" "OK" "$type_report"

# REQ-F-003 '복수 매칭 시 첫 매칭 우선' — needs a prompt matching two classes.
d="$(new_logdir verb-prec)"
run_hook "$d" "$(payload '에러 핸들링 추가해줘')" >/dev/null
assert_eq "AP  build+fix 동시매칭 → build 우선" "build" "$(field "$d" verb_class)"
d="$(new_logdir verb-prec2)"
run_hook "$d" "$(payload '에러 로그 포맷 바꿔줘')" >/dev/null
assert_eq "AP  change+fix 동시매칭 → change 우선" "change" "$(field "$d" verb_class)"
d="$(new_logdir verb-prec3)"
run_hook "$d" "$(payload '500 에러 나')" >/dev/null
assert_eq "AP  fix 단독 유지" "fix" "$(field "$d" verb_class)"

# ── Redaction, per enumerated rule (REQ-N-005) ──────────────────────────────
redaction_case() { # label secret prompt-prefix
  local dd; dd="$(new_logdir "redact-$1")"
  run_hook "$dd" "$(payload "${3}$2 확인해줘")" >/dev/null
  if [ "$(count "$dd")" != "1" ]; then
    no "AR  $1 redaction" "no record written"
  elif records "$dd" | grep -qF "$2"; then
    no "AR  $1 redaction" "raw secret survives in record"
  else
    ok "AR  $1 redaction"
  fi
}
redaction_case ghp    'ghp_A1b2C3d4E5f6G7h8I9j0K1l2M3n4O5p6Q7' ''
redaction_case AKIA   'AKIAIOSFODNN7EXAMPLE' ''
redaction_case bearer 'Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0' ''
redaction_case admap  'admap_2azPuQXKmy5FYLPEEkWqarExarKQgvQA' ''
redaction_case base64 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY' ''
# Straddling the 120-char head boundary. The leak here is a FRAGMENT, so
# grepping for the whole secret would pass while raw key material is stored.
d="$(new_logdir redact-straddle)"
run_hook "$d" "$(payload "$(python3 -c 'print("가"*111, end="")')AKIAIOSFODNN7EXAMPLE 확인해줘")" >/dev/null
if [ "$(count "$d")" != "1" ]; then
  no "AR  straddle redaction" "no record written"
elif field "$d" prompt_head | grep -q 'AKIAIOSF'; then
  no "AR  straddle redaction" "raw key fragment stored at the head boundary"
else
  ok "AR  straddle redaction"
fi

# False-positive guard: ordinary long developer tokens must survive, or the
# 5-15% manual-labelling material is destroyed (spec §5 residual #1).
d="$(new_logdir redact-fp)"
run_hook "$d" "$(payload 'commit 5540195aa1b2c3d4e5f60718293a4b5c6d7e8f90 확인')" >/dev/null
if records "$d" | grep -q '5540195aa1b2c3d4e5f60718293a4b5c6d7e8f90'; then
  ok "ARF git SHA 는 redaction 되지 않음"
else
  no "ARF git SHA 는 redaction 되지 않음" "40-hex SHA was redacted — labelling material lost"
fi

# ── verdict() range table — the project's actual decision output ────────────
if [ -f "$AGG" ]; then
  vt="$(python3 - "$AGG" <<'PYEOF'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("agg", sys.argv[1])
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
cases = [(1.9, "폐기"), (2.0, "경계"), (4.9, "경계"), (5.0, "라벨"),
         (15.0, "라벨"), (15.1, "경계"), (30.0, "경계"), (30.1, "재설계")]
bad = []
for pct, want in cases:
    got = m.verdict(pct)
    key = ("폐기" if "폐기" in got else "재설계" if "재설계" in got
           else "라벨" if "라벨" in got else "경계")
    if key != want:
        bad.append(f"{pct}→{key}(want {want})")
print(",".join(bad) if bad else "OK")
PYEOF
)"
  assert_eq "AVD verdict 구간표 (2/5/15/30 경계)" "OK" "$vt"

  # Displayed percentage and the branch must agree — a reader acts on the
  # printed figure. Run the real script: 1 hit in 51 rows is 1.9607%, which
  # prints as "2.0%" but reaches the "<2%" branch when compared unrounded.
  d="$(new_logdir agg-round)"
  python3 - "$d/records.jsonl" <<'PYEOF'
import json, os, sys
path = sys.argv[1]
os.makedirs(os.path.dirname(path), exist_ok=True)
rows = [{"ts": 1000, "session_id": "s1", "verb_class": "build",
         "specifics_count": 0, "prompt_len": 30, "prompt_head": "x"}]
rows += [{"ts": 1000 + i, "session_id": "s2", "verb_class": "explain",
          "specifics_count": 1, "prompt_len": 30, "prompt_head": "x"}
         for i in range(50)]
with open(path, "w") as f:
    for r in rows:
        f.write(json.dumps(r) + "\n")
PYEOF
  round_out="$(PROMPT_INTAKE_LOG_DIR="$d" python3 "$AGG" 2>&1)"
  if printf '%s' "$round_out" | grep -q '= 2.0%' && printf '%s' "$round_out" | grep -q '폐기'; then
    no "AVR 표시값과 판정 일치" "prints 2.0% but returns the <2% retire verdict"
  elif printf '%s' "$round_out" | grep -q '= 2.0%'; then
    ok "AVR 표시값과 판정 일치"
  else
    no "AVR 표시값과 판정 일치" "unexpected output: $(printf '%s' "$round_out" | head -2 | tr '\n' ' ')"
  fi

  # correction window/length filters — both were deletable without failing.
  corr_case() { # label ts_gap prompt_len expected_count
    local dd; dd="$(new_logdir "corr-$1")"
    python3 - "$dd/records.jsonl" "$2" "$3" <<'PYEOF'
import json, os, sys
path, gap, plen = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
os.makedirs(os.path.dirname(path), exist_ok=True)
rows = [
    {"ts": 1000, "session_id": "s1", "verb_class": "build", "specifics_count": 0,
     "prompt_len": 40, "prompt_head": "로그인 기능 추가해줘"},
    {"ts": 1000 + gap, "session_id": "s1", "verb_class": "none", "specifics_count": 0,
     "prompt_len": plen, "prompt_head": "아니 그게 아니라"},
]
with open(path, "w") as f:
    for r in rows:
        f.write(json.dumps(r) + "\n")
PYEOF
    local out; out="$(PROMPT_INTAKE_LOG_DIR="$dd" python3 "$AGG" 2>&1)"
    if printf '%s' "$out" | grep -q "정정 발화: $4건"; then
      ok "AC  $1 → $4건"
    else
      no "AC  $1 → $4건" "got: $(printf '%s' "$out" | grep 정정 || echo '<none>')"
    fi
  }
  corr_case "gap=120(경계 포함)" 120 12 1
  corr_case "gap=121(창 밖)"     121 12 0
  corr_case "len=59(포함)"        10 59 1
  corr_case "len=60(제외)"        10 60 0
fi

echo
echo "── ${PASS} passed, ${FAIL} failed ──"
if [ "$FAIL" -gt 0 ]; then
  printf 'failed: %s\n' "${FAILED_CASES[@]}"
  exit 1
fi
exit 0
