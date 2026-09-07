#!/usr/bin/env bash
# Verification suite for lab 001. Every test asserts behavior — messages and repository
# state — never just exit codes. An exit-code-only suite is exactly how the bug this lab
# studies survived (episode 001, §4c).
# shellcheck disable=SC2034  # out/rc/ALL_BRANCHES/etc. are read inside eval'd check() conditions
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1
LAB="$PWD"
FIXTURE="$LAB/fixture"
LOG="$LAB/state/reaped.log"
TMP="$LAB/.testtmp"   # all test artifacts stay inside the lab dir; teardown wipes them
mkdir -p "$TMP"

PASS=0; FAIL=0
ok(){   PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad(){  FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1"; fi }  # $1 = label, $2 = condition

fresh(){ ./scripts/make-fixture.sh "$FIXTURE" >/dev/null; rm -rf "$LAB/state"; }
branches(){ git -C "$FIXTURE" branch --format='%(refname:short)' | sort | paste -sd' ' -; }
log_lines(){ [ -f "$LOG" ] && wc -l < "$LOG" || echo 0; }

ALL_BRANCHES="feature/one feature/two main wip/unmerged"
KEPT_BRANCHES="main wip/unmerged"

echo "T1 dry-run is the default"
fresh
out="$(./reaper "$FIXTURE" 2>&1)"
check "announces what it would delete"  '[[ "$out" == *"[dry-run] would delete branch feature/one"* ]]'
check "says how to actually delete"     '[[ "$out" == *"pass --apply to delete."* ]]'
check "deletes nothing"                 '[ "$(branches)" = "$ALL_BRANCHES" ]'
check "logs nothing"                    '[ "$(log_lines)" = 0 ]'

echo "T2 --apply --yes deletes merged branches only, and logs each one"
fresh
out="$(./reaper "$FIXTURE" --apply --yes 2>&1)"
check "reports both deletions"          '[[ "$out" == *"deleted branch feature/one"* && "$out" == *"deleted branch feature/two"* ]]'
check "merged branches gone, rest kept" '[ "$(branches)" = "$KEPT_BRANCHES" ]'
check "audit log has two entries"       '[ "$(log_lines)" = 2 ]'

echo "T3 keyboard: answering n skips (default-No either way)"
fresh
out="$(printf 'n\n\n' | script -qec "./reaper '$FIXTURE' --apply" /dev/null)"
check "reports skips"                   '[[ "$out" == *"skipped branch feature/one"* && "$out" == *"skipped branch feature/two"* ]]'
check "deletes nothing"                 '[ "$(branches)" = "$ALL_BRANCHES" ]'
check "logs nothing"                    '[ "$(log_lines)" = 0 ]'

echo "T4 keyboard: answering y deletes"
fresh
out="$(printf 'y\ny\n' | script -qec "./reaper '$FIXTURE' --apply" /dev/null)"
check "reports both deletions"          '[[ "$out" == *"deleted branch feature/one"* && "$out" == *"deleted branch feature/two"* ]]'
check "merged branches gone, rest kept" '[ "$(branches)" = "$KEPT_BRANCHES" ]'
check "audit log has two entries"       '[ "$(log_lines)" = 2 ]'

echo "T5 headless, fixed probe: fails closed with the documented refusal (the regression test)"
fresh
rc=0; setsid --wait ./reaper "$FIXTURE" --apply </dev/null >"$TMP"/t5.out 2>"$TMP"/t5.err || rc=$?
# The refusal text arriving on stderr also proves the probe's save/restore dance worked —
# if the fix had silenced stderr on the exec, this message would vanish into /dev/null.
check "prints the documented refusal"   'grep -q "no tty for confirmation — pass --yes" "$TMP"/t5.err'
check "refuses every branch"            'grep -c "skipped branch" "$TMP"/t5.out | grep -qx 2'
check "deletes nothing"                 '[ "$(branches)" = "$ALL_BRANCHES" ]'
check "logs nothing"                    '[ "$(log_lines)" = 0 ]'

echo "T6 headless, buggy probe: the crash the episode studies"
fresh
rc=0; REAPER_BUGGY_TTY_PROBE=1 setsid --wait ./reaper "$FIXTURE" --apply </dev/null >"$TMP"/t6.out 2>"$TMP"/t6.err || rc=$?
check "exits nonzero"                   '[ "$rc" != 0 ]'
check "raw unbound-variable error"      'grep -q "unbound variable" "$TMP"/t6.err'
check "no documented refusal appears"   '! grep -q "no tty for confirmation" "$TMP"/t6.err'
check "still deletes nothing (luck #1: set -u)" '[ "$(branches)" = "$ALL_BRANCHES" ]'
check "logs nothing"                    '[ "$(log_lines)" = 0 ]'

echo "T7 headless, buggy probe, strict mode off: default-No refuses by accident (luck #2)"
fresh
rc=0; REAPER_BUGGY_TTY_PROBE=1 REAPER_NO_STRICT=1 setsid --wait ./reaper "$FIXTURE" --apply </dev/null >"$TMP"/t7.out 2>"$TMP"/t7.err || rc=$?
check "sweep completes"                 '[ "$rc" = 0 ]'
check "every branch skipped"            'grep -c "skipped branch" "$TMP"/t7.out | grep -qx 2'
check "deletes nothing"                 '[ "$(branches)" = "$ALL_BRANCHES" ]'

echo "T8 blast-radius guard: refuses a repo without the fixture marker"
fresh
rm -rf "$TMP"/not-the-fixture; git init -q -b main "$TMP"/not-the-fixture
git -C "$TMP"/not-the-fixture -c user.name=x -c user.email=x@invalid.example -c commit.gpgsign=false commit -q --allow-empty -m init
rc=0; ./reaper "$TMP"/not-the-fixture --apply --yes >"$TMP"/t8.out 2>"$TMP"/t8.err || rc=$?
check "refuses with the marker message" 'grep -q "not the lab fixture" "$TMP"/t8.err'
check "exits nonzero"                   '[ "$rc" = 3 ]'
rm -rf "$TMP"/not-the-fixture

echo
printf '%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" = 0 ]
