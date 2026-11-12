#!/usr/bin/env bash
# Behaviour baseline for DealerDesk.
#
# Each tests/sessions/NAME.in holds the keys a user would type, one line per
# ENTER. A line containing only @restart closes the program and starts it
# again on the same data, to check that what was saved is read back.
#
# For every session the program runs on a throwaway copy of
# tests/fixtures/data. The screens it prints and the data files it leaves
# behind are compared byte for byte with tests/expected/NAME.out.
#
#   bash tests/run.sh            compare with the baseline (default)
#   bash tests/run.sh record     write the baseline; refused while source
#                                files differ from the last commit
#
# Two substitutions keep the baseline readable and stable:
#   - the ESC byte of the clear-screen code is shown as ^
#   - today's date, stamped on new invoices, is shown as <TODAY>

set -u
cd "$(dirname "$0")/.." || exit 2
ROOT=$PWD
BIN=${BIN:-./dealerdesk}
case $BIN in /*) ;; *) BIN=$ROOT/$BIN ;; esac
MODE=${1:-check}
TODAY=$(date +%Y-%m-%d)

[ -x "$BIN" ] || { echo "program not found: $BIN (run make first)"; exit 2; }

if [ "$MODE" = record ]; then
    if ! git diff --quiet HEAD -- '*.c' '*.h'; then
        echo "Refusing to record: source files differ from the last commit."
        echo "A baseline must describe committed code. Commit or revert first."
        exit 2
    fi
    mkdir -p tests/expected
fi

# Every saved invoice must add up, whatever discounts went into it.
invoice_arithmetic() {
    awk -F'|' '
        function off(x) { return x < -0.005 || x > 0.005 }
        NF {
            if (off($5 - $6 - $7))             { print "invoice " $1 ": list - discounts is not net"; bad = 1 }
            if (off($7 + $9 + $8 - $10 - $11)) { print "invoice " $1 ": lines do not add up to total"; bad = 1 }
        }
        END { if (!bad) print "ok" }' "$1"
}

run_session() {
    work=$(mktemp -d)
    cp -r tests/fixtures/data "$work/data"
    # A session may replace data files with its own: tests/sessions/NAME.data/
    if [ -d "${1%.in}.data" ]; then cp -r "${1%.in}.data/." "$work/data/"; fi
    awk -v d="$work" '
        BEGIN { n = 1 }
        $0 == "@restart" { n++; next }
        { print > (d "/in." n) }' "$1"

    n=1
    while [ -f "$work/in.$n" ]; do
        echo "### run $n"
        (cd "$work" && "$BIN" < "in.$n" 2>&1)
        status=$?
        printf '\n### exit status: %s\n' "$status"
        n=$((n + 1))
    done

    for f in customers.dat invoices.dat next_ids.dat stock.dat; do
        echo "### data/$f"
        cat "$work/data/$f"
    done
    echo "### files in data/: $(ls "$work/data" | tr '\n' ' ')"
    echo "### invoice arithmetic: $(invoice_arithmetic "$work/data/invoices.dat")"
    rm -rf "$work"
}

normalise() {
    tr '\033' '^' | sed "s/$TODAY/<TODAY>/g"
}

count=0
failed=0
for session in tests/sessions/*.in; do
    name=$(basename "$session" .in)
    expected=tests/expected/$name.out
    count=$((count + 1))

    if [ "$MODE" = record ]; then
        run_session "$session" | normalise > "$expected"
        echo "recorded $name"
    elif [ ! -f "$expected" ]; then
        echo "FAIL $name (no baseline: tests/expected/$name.out is missing)"
        failed=$((failed + 1))
    elif difference=$(run_session "$session" | normalise | diff -u "$expected" -); then
        echo "ok   $name"
    else
        echo "FAIL $name"
        echo "$difference"
        failed=$((failed + 1))
    fi
done

echo "$count sessions, $failed failed"
[ "$failed" -eq 0 ]
