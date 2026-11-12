#!/usr/bin/env bash
# Rollback check.
#
# RELEASE.txt says: if a release breaks, copy the old binary back. So data
# written by this version must still load in the previous release, and the
# previous release must not damage it.
#
# This builds release 2.3 from git history, lets the new program create fleet
# customers and a fleet invoice, then runs the old program on the same data.
#
#   bash tests/rollback.sh        needs the full git history (not a shallow clone)

set -u
cd "$(dirname "$0")/.." || exit 2
ROOT=$PWD
NEW=${BIN:-./dealerdesk}
case $NEW in /*) ;; *) NEW=$ROOT/$NEW ;; esac
PREVIOUS=a2ba708        # release 2.3, the code as Nextlane delivered it

[ -x "$NEW" ] || { echo "program not found: $NEW (run make first)"; exit 2; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

mkdir "$work/old"
git archive "$PREVIOUS" | tar -x -C "$work/old" ||
    { echo "cannot read commit $PREVIOUS from git history"; exit 2; }
(cd "$work/old" && ${CC:-cc} -o dealerdesk main.c dbfile.c screen.c calc.c -lm) ||
    { echo "release 2.3 does not build"; exit 2; }

cp -r tests/fixtures/data "$work/data"
cd "$work" || exit 2

# New version: Greenway Taxis becomes fleet, a new fleet customer is added,
# Greenway buys vehicle 1002.
printf '%s\n' 2 4 2008 y '' \
              2 'Northside Rentals' '01632 960999' 'hire@northside.example' n y '' 0 \
              4 1002 2008 0 0 y '' 0 | "$NEW" > new.out 2>&1
new_status=$?
cp data/invoices.dat invoices.before

# Old version on the same data: list customers, add one (this rewrites the
# whole customer file), view the fleet invoice, exit.
printf '%s\n' 2 1 '' \
              2 'Rollback Check' 1 2 n '' 0 \
              5 2 50233 '' 0 0 | old/dealerdesk > old.out 2>&1
old_status=$?

failed=0
check() {   # check "what must be true" command...
    label=$1; shift
    if "$@" > /dev/null 2>&1; then echo "ok   $label"; else echo "FAIL $label"; failed=1; fi
}

check "new version ran without error"                    [ "$new_status" -eq 0 ]
check "old version loads the data and exits normally"    [ "$old_status" -eq 0 ]
check "old version shows the fleet customer (as Retail)" grep -q 'Greenway Taxis .*Retail' old.out
check "old version shows the fleet invoice total"        grep -q 'TOTAL  *12901.24' old.out
check "old version saved its own new customer"           grep -q '^2010|Rollback Check|1|2|R$' data/customers.dat
check "Greenway Taxis is still fleet on disk"            grep -q '^2008|Greenway Taxis|.*|F$' data/customers.dat
check "the new fleet customer is still fleet on disk"    grep -q '^2009|Northside Rentals|.*|F$' data/customers.dat
check "invoices are untouched by the old version"        cmp -s data/invoices.dat invoices.before

[ "$failed" -eq 0 ]
