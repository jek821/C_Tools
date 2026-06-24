#!/usr/bin/env bash
# Run from inside jek_wc/: bash test.sh
#
# Strategy: the system `wc` is the oracle. For each test file we ask the real
# `wc` for its line/word/byte counts, then run our tool and pull the matching
# number out of its labeled output. If the numbers agree, we match GNU wc.

TOOL=./jekwc
PASS=0
FAIL=0

# --- helpers ----------------------------------------------------------------

# check "description" "actual output" "expected output"
check() {
    local desc="$1" actual="$2" expected="$3"
    if [ "$actual" = "$expected" ]; then
        echo "PASS: $desc"
        ((PASS++))
    else
        echo "FAIL: $desc"
        echo "  expected: $expected"
        echo "  actual:   $actual"
        ((FAIL++))
    fi
}

# field "Label" "$output"  ->  prints the number after "Label:"
# e.g. field "Lines" "Lines: 5" -> 5
field() {
    awk -F': ' -v key="$1" '$1 == key { print $2 }' <<<"$2"
}

# compare_all "description" "file"
# Runs our tool with default (all) flags and checks lines/words/bytes against
# the real wc, which we read with -l / -w / -c to get clean integers.
compare_all() {
    local desc="$1" file="$2" out
    out="$($TOOL "$file" 2>/dev/null)"
    check "$desc: lines" "$(field Lines "$out")" "$(wc -l < "$file" | tr -d ' ')"
    check "$desc: words" "$(field Words "$out")" "$(wc -w < "$file" | tr -d ' ')"
    check "$desc: bytes" "$(field Bytes "$out")" "$(wc -c < "$file" | tr -d ' ')"
}

# --- setup ------------------------------------------------------------------

# mktemp creates a temp file with a unique name so tests never collide
BASIC=$(mktemp)
EMPTY=$(mktemp)
LARGE=$(mktemp)
NO_NEWLINE=$(mktemp)
WHITESPACE=$(mktemp)
MULTILINE=$(mktemp)

printf "hello world\n"            > "$BASIC"
printf ""                         > "$EMPTY"
printf 'a%.0s' {1..9000}          > "$LARGE"        # 9000 a's — crosses the 4096-byte buffer
printf "no newline"               > "$NO_NEWLINE"
printf "  spaced \t out\twords \n" > "$WHITESPACE"  # mixed tabs/spaces
printf "one\ntwo two\nthree x y\n" > "$MULTILINE"

# --- count tests (extrapolated from real wc) --------------------------------

compare_all "basic file"      "$BASIC"
compare_all "empty file"      "$EMPTY"
compare_all "large file"      "$LARGE"
compare_all "no trailing nl"  "$NO_NEWLINE"
compare_all "mixed whitespace" "$WHITESPACE"
compare_all "multiline"       "$MULTILINE"

# --- individual flag tests --------------------------------------------------

check "-l only prints lines only" \
    "$($TOOL -l "$BASIC" 2>/dev/null)" "Lines: $(wc -l < "$BASIC" | tr -d ' ')"
check "-w only prints words only" \
    "$($TOOL -w "$BASIC" 2>/dev/null)" "Words: $(wc -w < "$BASIC" | tr -d ' ')"
check "-b only prints bytes only" \
    "$($TOOL -b "$BASIC" 2>/dev/null)" "Bytes: $(wc -c < "$BASIC" | tr -d ' ')"

# stdout must stay clean (no stray debug output) when a flag is used
check "-b stdout has no debug lines" \
    "$($TOOL -b "$BASIC" 2>/dev/null | wc -l | tr -d ' ')" "1"

# --- exit-code / error tests ------------------------------------------------

$TOOL "$BASIC" > /dev/null 2>&1
check "valid file exits 0" "$?" "0"

timeout 5 $TOOL /tmp/does_not_exist_jekwc > /dev/null 2>&1
check "missing file exits 1" "$?" "1"

timeout 5 $TOOL > /dev/null 2>&1
check "no args exits 1" "$?" "1"

timeout 5 $TOOL -z "$BASIC" > /dev/null 2>&1
check "unknown flag exits 1" "$?" "1"

# --- teardown ---------------------------------------------------------------

rm -f "$BASIC" "$EMPTY" "$LARGE" "$NO_NEWLINE" "$WHITESPACE" "$MULTILINE"

# --- results ----------------------------------------------------------------

echo ""
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
