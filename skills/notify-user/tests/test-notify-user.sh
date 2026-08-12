#!/usr/bin/env bash
# Portable test suite for the notify-user skill helper.
# No external test framework: plain bash + PATH mocks + NOTIFY_USER_* test hooks.
# Leaves no artifacts (all scratch lives under a mktemp dir removed on EXIT).
set -uo pipefail

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)/notify-user"

PASS=0
FAIL=0
CURRENT=""
RUN_RC=0

TMPBASE="$(mktemp -d "${TMPDIR:-/tmp}/notify-user-tests.XXXXXX")"
MOCKDIR="$TMPBASE/mocks"
PYBIN="$TMPBASE/pybin"        # python3 only (for no-notifier tests)
WSLTMP="$TMPBASE/wsl-tmp"     # fake "Windows TEMP" dir as seen from WSL
WIN_TEMP="C:/Temp/notify-user-tests"
FAKEHOME="$TMPBASE/fakehome"
LOG="$TMPBASE/mock.log"
mkdir -p "$MOCKDIR" "$PYBIN" "$WSLTMP" "$FAKEHOME" "$TMPBASE/proj"
ln -s "$(command -v python3)" "$PYBIN/python3"

trap 'rm -rf "$TMPBASE"' EXIT

note() { printf '%s\n' "$*"; }
pass() { PASS=$((PASS+1)); printf '  ok   - %s\n' "$CURRENT"; }
fail() { FAIL=$((FAIL+1)); printf '  FAIL - %s: %s\n' "$CURRENT" "$*"; }

# run <stdout-file> <stderr-file> <cmd...>  -> sets RUN_RC
run() {
  local out="$1" err="$2"; shift 2
  "$@" >"$out" 2>"$err"
  RUN_RC=$?
}

check() { # check <desc> <cmd...>
  CURRENT="$1"; shift
  if "$@" >/dev/null 2>&1; then pass; else fail "assertion failed"; fi
}

expect_rc() { # expect_rc <desc> <expected-rc> <cmd...>
  CURRENT="$1"; local want="$2"; shift 2
  run "$TMPBASE/out" "$TMPBASE/err" "$@"
  if [ "$RUN_RC" -eq "$want" ]; then pass; else fail "expected exit $want, got $RUN_RC"; fi
}

expect_grep_file() { # expect_grep_file <desc> <file> <pattern>
  CURRENT="$1"; local f="$2" p="$3"
  if grep -q "$p" "$f"; then pass; else fail "no match for '$p' in $(basename "$f"): [$(cat "$f")]"; fi
}

# ---------------------------------------------------------------------------
# Mock transport binaries
# ---------------------------------------------------------------------------
cat > "$MOCKDIR/notify-send" <<'SH'
#!/usr/bin/env bash
printf 'NOTIFY-SEND\n' >> "${NOTIFY_MOCK_LOG:-/dev/null}"
printf '%s\n' "$@" >> "${NOTIFY_MOCK_LOG:-/dev/null}"
echo "mock stdout noise"
exit "${NOTIFY_MOCK_EXIT:-0}"
SH
cat > "$MOCKDIR/osascript" <<'SH'
#!/usr/bin/env bash
printf 'OSASCRIPT TITLE=%s\nOSASCRIPT BODY=%s\n' "$3" "$4" >> "${NOTIFY_MOCK_LOG:-/dev/null}"
exit "${NOTIFY_MOCK_EXIT:-0}"
SH
cat > "$MOCKDIR/wslpath" <<'SH'
#!/usr/bin/env bash
case "$1" in
  -u) printf '%s\n' "${NOTIFY_WSL_TMP:?}"; exit "${NOTIFY_WSLPATH_U_RC:-0}" ;;
  -w) printf '%s\n' "$WIN_TEMP/$(basename "$2")"; exit "${NOTIFY_WSLPATH_W_RC:-0}" ;;
  *) exit 1 ;;
esac
SH
cat > "$MOCKDIR/powershell.exe" <<'SH'
#!/usr/bin/env bash
if [[ "$*" == *GetTempPath* ]]; then
  printf '%s\n' "${WIN_TEMP:?}"
  exit "${NOTIFY_PREFLIGHT_RC:-0}"
fi
win_path="${@: -1}"
name="$(basename "$win_path")"
printf 'XML_PATH=%s\n' "$win_path" >> "${NOTIFY_MOCK_LOG:-/dev/null}"
cat "${NOTIFY_WSL_TMP:?}/$name" >> "${NOTIFY_MOCK_LOG:-/dev/null}" 2>/dev/null || true
printf '\n' >> "${NOTIFY_MOCK_LOG:-/dev/null}"
exit "${NOTIFY_TOAST_RC:-0}"
SH
chmod +x "$MOCKDIR"/*

# Environment template for transport tests
mock_env() { # mock_env <platform>
  local plat="$1"
  export NOTIFY_USER_PLATFORM="$plat"
  export NOTIFY_MOCK_LOG="$LOG"
  export NOTIFY_WSL_TMP="$WSLTMP"
  export WIN_TEMP="$WIN_TEMP"
  export NOTIFY_PREFLIGHT_RC=0 NOTIFY_WSLPATH_U_RC=0 NOTIFY_WSLPATH_W_RC=0 NOTIFY_TOAST_RC=0
  export NOTIFY_MOCK_EXIT=0
  export PATH="$MOCKDIR:$PATH"
  export HOME="$FAKEHOME"
}

# ---------------------------------------------------------------------------
note "1. Argument validation"
# ---------------------------------------------------------------------------
cd "$TMPBASE/proj"
expect_rc "bad category -> exit 2" 2 "$SCRIPT" bogus title
expect_grep_file "bad category on stderr" "$TMPBASE/err" "invalid category"
check "bad category -> stdout empty" test ! -s "$TMPBASE/out"
expect_rc "missing title -> exit 2" 2 "$SCRIPT" complete
expect_rc "too many args -> exit 2" 2 "$SCRIPT" complete title body extra
expect_rc "invalid workspace mode -> exit 2" 2 env NOTIFY_USER_WORKSPACE=bogus "$SCRIPT" complete title
expect_grep_file "invalid workspace mode on stderr" "$TMPBASE/err" "invalid NOTIFY_USER_WORKSPACE"

# ---------------------------------------------------------------------------
note "2. Missing python3 -> failed (exit 1), diagnostic on stderr"
# ---------------------------------------------------------------------------
expect_rc "python3 missing -> exit 1" 1 env PATH=/nonexistent "$(command -v bash)" "$SCRIPT" complete title
expect_grep_file "python3 message on stderr" "$TMPBASE/err" "python3 is required"

# ---------------------------------------------------------------------------
note "3. sent/failed/skipped protocol and streams (linux mock)"
# ---------------------------------------------------------------------------
mock_env linux
export NOTIFY_MOCK_EXIT=0
rm -f "$LOG"; : > "$LOG"
run "$TMPBASE/out" "$TMPBASE/err" "$SCRIPT" complete 'Sent title' 'ctx'
check "sent -> exit 0" test "$RUN_RC" -eq 0
check "sent -> stdout exactly one line" test "$(wc -l < "$TMPBASE/out")" -eq 1
expect_grep_file "sent -> stdout line content" "$TMPBASE/out" '^notify-user: sent - Sent title$'
check "sent -> mock stdout noise suppressed" grep -vq 'mock stdout noise' "$TMPBASE/out"

export NOTIFY_MOCK_EXIT=1
rm -f "$LOG"; : > "$LOG"
run "$TMPBASE/out" "$TMPBASE/err" "$SCRIPT" error 'Fail title' 'ctx'
check "failed -> exit 1" test "$RUN_RC" -eq 1
check "failed -> stdout empty" test ! -s "$TMPBASE/out"
expect_grep_file "failed line on stderr" "$TMPBASE/err" '^notify-user: failed - notify-send error (exit 1)$'

rm -f "$LOG"; : > "$LOG"
run "$TMPBASE/out" "$TMPBASE/err" env NOTIFY_USER_PLATFORM=warp "$SCRIPT" complete 'X'
check "skipped (unsupported) -> exit 0" test "$RUN_RC" -eq 0
check "skipped -> stdout one line" test "$(wc -l < "$TMPBASE/out")" -eq 1
expect_grep_file "skipped -> stdout line content" "$TMPBASE/out" '^notify-user: skipped - unsupported platform (warp)$'

# ---------------------------------------------------------------------------
note "4. Only the first nonempty body line is delivered (linux + macOS mocks)"
# ---------------------------------------------------------------------------
mock_env linux
rm -f "$LOG"; : > "$LOG"
"$SCRIPT" complete 'Multi-line' $'line-one\ngarbage-line-two\ngarbage-line-three' >/dev/null 2>&1
expect_grep_file "first body line delivered" "$LOG" '^line-one$'
check "later body lines discarded" grep -vq 'garbage-line' "$LOG"
mock_env macos
rm -f "$LOG"; : > "$LOG"
"$SCRIPT" complete 'Mac multi' $'mac-line-one\nmac-garbage' >/dev/null 2>&1
expect_grep_file "first mac body line delivered" "$LOG" '^OSASCRIPT BODY=mac-line-one$'
check "later mac body line discarded" grep -vq 'mac-garbage' "$LOG"

# ---------------------------------------------------------------------------
note "5. Workspace privacy modes (linux mock, controlled CWD)"
# ---------------------------------------------------------------------------
cd "$TMPBASE/proj"   # basename: proj ; full with HOME=$FAKEHOME -> ~/proj
mkdir -p "$FAKEHOME/proj2"
mock_env linux
body_lines() { # body_lines -> print log lines after the NOTIFY-SEND marker
  sed -n '/^NOTIFY-SEND$/,${/^NOTIFY-SEND$/d;p}' "$LOG"
}
# default (unset) = basename
CURRENT="default mode shows basename"
rm -f "$LOG"; : > "$LOG"
env -u NOTIFY_USER_WORKSPACE "$SCRIPT" complete 'W' 'b' >/dev/null 2>&1
body_lines | grep -q '^Workspace: proj$' && pass || fail "default mode does not show basename 'proj'"
# explicit basename
CURRENT="basename mode shows basename"
rm -f "$LOG"; : > "$LOG"
env NOTIFY_USER_WORKSPACE=basename "$SCRIPT" complete 'W' 'b' >/dev/null 2>&1
body_lines | grep -q '^Workspace: proj$' && pass || fail "basename mode missing 'Workspace: proj'"
# full mode with HOME=fakehome -> home abbreviation (CWD under fakehome)
CURRENT="full mode home abbreviation"
rm -f "$LOG"; : > "$LOG"
( cd "$FAKEHOME/proj2" && env NOTIFY_USER_WORKSPACE=full "$SCRIPT" complete 'W' 'b' ) >/dev/null 2>&1
body_lines | grep -q '^Workspace: ~/proj2$' && pass || fail "full mode missing 'Workspace: ~/proj2'"
# off mode -> no workspace line at all
CURRENT="off mode hides workspace"
rm -f "$LOG"; : > "$LOG"
env NOTIFY_USER_WORKSPACE=off "$SCRIPT" complete 'W' 'b' >/dev/null 2>&1
body_lines | grep -q 'Workspace:' && fail "off mode still discloses workspace" || pass

# ---------------------------------------------------------------------------
note "6. WSL preflight/toast failures are failed (exit 1), not skipped or sent"
# ---------------------------------------------------------------------------
mock_env wsl
export NOTIFY_PREFLIGHT_RC=1
run "$TMPBASE/out" "$TMPBASE/err" "$SCRIPT" complete 'Preflight' 'b'
check "preflight failure -> exit 1" test "$RUN_RC" -eq 1
check "preflight failure -> stdout empty" test ! -s "$TMPBASE/out"
expect_grep_file "preflight failure on stderr" "$TMPBASE/err" '^notify-user: failed - powershell.exe preflight exited 1$'
export NOTIFY_PREFLIGHT_RC=0

export NOTIFY_WSLPATH_U_RC=1
run "$TMPBASE/out" "$TMPBASE/err" "$SCRIPT" complete 'P' 'b'
check "wslpath -u failure -> exit 1" test "$RUN_RC" -eq 1
expect_grep_file "wslpath -u failure on stderr" "$TMPBASE/err" '^notify-user: failed - wslpath -u conversion exited 1$'
export NOTIFY_WSLPATH_U_RC=0

export NOTIFY_WSLPATH_W_RC=1
run "$TMPBASE/out" "$TMPBASE/err" "$SCRIPT" complete 'P' 'b'
check "wslpath -w failure -> exit 1" test "$RUN_RC" -eq 1
expect_grep_file "wslpath -w failure on stderr" "$TMPBASE/err" '^notify-user: failed - wslpath -w conversion exited 1$'
export NOTIFY_WSLPATH_W_RC=0

export NOTIFY_TOAST_RC=1
run "$TMPBASE/out" "$TMPBASE/err" "$SCRIPT" complete 'P' 'b'
check "toast invocation failure -> exit 1" test "$RUN_RC" -eq 1
expect_grep_file "toast failure on stderr" "$TMPBASE/err" '^notify-user: failed - Windows toast invocation error (exit 1)$'
export NOTIFY_TOAST_RC=0

# ---------------------------------------------------------------------------
note "7. WSL success: XML escaping, single body line, workspace modes, silence"
# ---------------------------------------------------------------------------
rm -f "$LOG"; : > "$LOG"
"$SCRIPT" complete 'A&B<C>"D' $'ctx&<line>\nsecond-discarded' >/dev/null 2>&1
expect_grep_file "unique XML path recorded" "$LOG" '^XML_PATH=C:/Temp/notify-user-'
expect_grep_file "title metacharacters XML-escaped" "$LOG" '<text>A&amp;B&lt;C&gt;&quot;D</text>'
expect_grep_file "body metacharacters XML-escaped" "$LOG" '<text>ctx&amp;&lt;line&gt;</text>'
check "second body line absent from WSL toast" grep -vq 'second-discarded' "$LOG"
expect_grep_file "toast is silent" "$LOG" '<audio silent="true" />'
expect_grep_file "default basename workspace in WSL toast" "$LOG" '<text>Workspace: proj</text>'

rm -f "$LOG"; : > "$LOG"
env NOTIFY_USER_WORKSPACE=off "$SCRIPT" complete 'NoWS' 'b' >/dev/null 2>&1
check "off mode: no Workspace in WSL toast" grep -vq 'Workspace' "$LOG"
rm -f "$LOG"; : > "$LOG"
( cd "$FAKEHOME/proj2" && env NOTIFY_USER_WORKSPACE=full "$SCRIPT" complete 'FullWS' 'b' ) >/dev/null 2>&1
expect_grep_file "full mode home abbreviation in WSL toast" "$LOG" '<text>Workspace: ~/proj2</text>'

# ---------------------------------------------------------------------------
note "8. Concurrent WSL invocations: distinct unique paths, no leftover files"
# ---------------------------------------------------------------------------
rm -f "$LOG"; : > "$LOG"
( env NOTIFY_USER_WORKSPACE=basename "$SCRIPT" complete 'Conc A' 'a' >/dev/null 2>&1 ) &
PID1=$!
( env NOTIFY_USER_WORKSPACE=basename "$SCRIPT" complete 'Conc B' 'b' >/dev/null 2>&1 ) &
PID2=$!
wait "$PID1"; R1=$?
wait "$PID2"; R2=$?
check "concurrent run A exit 0" test "$R1" -eq 0
check "concurrent run B exit 0" test "$R2" -eq 0
PATHS=$(grep '^XML_PATH=' "$LOG" | sort -u | wc -l)
check "two distinct unique XML paths" test "$PATHS" -eq 2
LEFTOVER=$(find "$WSLTMP" -name 'notify-user-*' 2>/dev/null | wc -l)
check "no leftover unique temp files" test "$LEFTOVER" -eq 0

# ---------------------------------------------------------------------------
note "9. No transport present -> skipped (exit 0), stdout one line"
# ---------------------------------------------------------------------------
rm -f "$LOG"; : > "$LOG"
run "$TMPBASE/out" "$TMPBASE/err" env NOTIFY_USER_PLATFORM=linux PATH="$PYBIN" "$(command -v bash)" "$SCRIPT" complete 'No ns'
check "notify-send absent -> exit 0" test "$RUN_RC" -eq 0
expect_grep_file "linux skipped line on stdout" "$TMPBASE/out" '^notify-user: skipped - notify-send not found$'
run "$TMPBASE/out" "$TMPBASE/err" env NOTIFY_USER_PLATFORM=wsl PATH="$PYBIN" "$(command -v bash)" "$SCRIPT" complete 'No wsl'
check "wsl transport absent -> exit 0" test "$RUN_RC" -eq 0
expect_grep_file "wsl skipped line on stdout" "$TMPBASE/out" '^notify-user: skipped - WSL toast needs powershell.exe and wslpath (not found)$'

# ---------------------------------------------------------------------------
note "Summary: $PASS passed, $FAIL failed"
# ---------------------------------------------------------------------------
[ "$FAIL" -eq 0 ] || { printf 'TEST SUITE FAILED\n' >&2; exit 1; }
printf 'TEST SUITE PASSED\n'
