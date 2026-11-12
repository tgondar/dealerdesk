#!/usr/bin/env bash
# Is this version slower than the last release?
#
# The program keeps everything in memory, reads all its files at start-up and
# rewrites a whole file on every save. Its tables have fixed sizes (500
# vehicles, 500 customers, 2000 invoices), so the slowest it can ever be is
# with the files nearly full. This check builds that data, builds release 2.3
# from git history, and times both versions on the same machine, in the same
# run, with the same keystrokes.
#
# Only the ratio between the two is judged. Absolute times depend on the
# machine and mean nothing on a shared CI runner.
#
#   bash tests/speed.sh        needs the full git history (not a shallow clone)

set -u -o pipefail
cd "$(dirname "$0")/.." || exit 2
ROOT=$PWD
NEW=${BIN:-./dealerdesk}
case $NEW in /*) ;; *) NEW=$ROOT/$NEW ;; esac
PREVIOUS=a2ba708        # release 2.3
RUNS=7                  # each measurement is the median of this many runs
LIMIT=2                 # fail when a workload takes more than LIMIT times ...
SLACK=20                # ... plus SLACK milliseconds (timer noise on tiny values)

[ -x "$NEW" ] || { echo "program not found: $NEW (run make first)"; exit 2; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

mkdir "$work/old"
git archive "$PREVIOUS" | tar -xf - -C "$work/old" ||
    { echo "cannot read commit $PREVIOUS from git history (shallow clone?)"; exit 2; }
(cd "$work/old" && ${CC:-cc} -o dealerdesk main.c dbfile.c screen.c calc.c -lm) ||
    { echo "release 2.3 does not build"; exit 2; }
cp "$NEW" "$work/new-dealerdesk"

# --- data close to the limits: 490 vehicles, 490 customers, 1980 invoices
mkdir "$work/full"
awk 'BEGIN {
    for (i = 0; i < 490; i++)
        printf "%d|PL%04d X|Make %d|Model number %d|2020|%d|5000.00|%d.00|0\n", 1000 + i, i, i % 20, i, 10000 + i, 10000 + i
}' > "$work/full/stock.dat"
awk 'BEGIN {
    for (i = 0; i < 490; i++)
        printf "%d|Customer number %d|07700 9%05d|customer%d@example.com|%s\n", 2000 + i, i, i, i, (i % 3 == 0 ? "T" : "R")
}' > "$work/full/customers.dat"
awk 'BEGIN {
    for (i = 0; i < 1980; i++)
        printf "%d|2021-01-01|1000|%d|10000.00|0.00|10000.00|2030.00|205.00|0.00|12235.00\n", 50000 + i, 2000 + i % 490
}' > "$work/full/invoices.dat"
printf 'vehicle=1490\ncustomer=2490\ninvoice=51980\n' > "$work/full/next_ids.dat"

# --- workloads: the same keys for both versions
keys() { printf '%s\n' "$@"; }
repeat() { n=$1; shift; i=0; while [ "$i" -lt "$n" ]; do keys "$@"; i=$((i + 1)); done; }

keys 0 > "$work/start.keys"
{ repeat 40 1 2 '' 0  2 1 '' 3 'number 4' '' 0  5 1 '' 2 51000 '' 0  3 1200 2100 5 0 ''; keys 0; } > "$work/browse.keys"
{ keys 1; repeat 400 6 1005 ''; keys 0 0; } > "$work/save-stock.keys"
{ i=0; while [ "$i" -lt 20 ]; do keys 4 $((1000 + i)) 2001 0 0 y ''; i=$((i + 1)); done; keys 0; } > "$work/sell.keys"
{ keys 2; repeat 8 2 'New customer' '07700 900000' 'new@example.com' n ''; keys 0 0; } > "$work/add-customer.keys"

# milliseconds for one run of a workload, with fresh data, timing the program only
one_run() {   # one_run BINARY WORKLOAD STARTS
    rm -rf "$work/run" && mkdir "$work/run" && cp -r "$work/full" "$work/run/data"
    TIMEFORMAT=%3R
    t=$( { time ( cd "$work/run" && n=0 && while [ "$n" -lt "$3" ]; do "$1" < "$work/$2.keys" > /dev/null 2>&1; n=$((n + 1)); done ); } 2>&1 )
    case $t in
        *[!0-9.,]*|'') echo "ignoring one sample of $2, unexpected timing output: [$t]" >&2; return ;;
    esac
    echo "$t" | tr -d '.,' | sed 's/^0*//; s/^$/0/'
}

# The median, not the fastest run: a single sample can be wrong. When the
# machine's clock is adjusted during a run (WSL does this when it resyncs with
# Windows) the shell reports a time that is too short, zero, or not a number.
# Seen in 3 of 350 samples. One bad sample cannot move a median of seven.
typical() {   # typical BINARY WORKLOAD STARTS
    samples=
    r=0
    while [ "$r" -lt "$RUNS" ]; do
        samples="$samples$(one_run "$1" "$2" "$3")
"
        r=$((r + 1))
    done
    count=$(printf '%s' "$samples" | grep -c .)
    [ "$count" -ge 3 ] || { echo "fewer than 3 usable timings for $2" >&2; exit 2; }
    printf '%s' "$samples" | grep . | sort -n | sed -n "$(( (count + 1) / 2 ))p"
}

failed=0
printf '%-34s %10s %10s   %s\n' "workload (data files nearly full)" "2.3 ms" "now ms" "verdict"
measure() {   # measure "label" WORKLOAD STARTS
    old=$(typical "$work/old/dealerdesk" "$2" "$3") || exit 2
    new=$(typical "$work/new-dealerdesk" "$2" "$3") || exit 2
    if [ "$new" -gt $((old * LIMIT + SLACK)) ]; then verdict="SLOWER"; failed=1; else verdict="ok"; fi
    printf '%-34s %10s %10s   %s\n' "$1" "$old" "$new" "$verdict"
}

measure "start and exit, 50 times"       start        50
measure "40 rounds of lists and quotes"  browse        1
measure "400 saves of the stock file"    save-stock    1
measure "20 sales"                       sell          1
measure "8 new customers"                add-customer  1

[ "$failed" -eq 0 ] || echo "A workload takes more than $LIMIT times release 2.3 plus $SLACK ms."
[ "$failed" -eq 0 ]
