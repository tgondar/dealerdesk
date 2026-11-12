#!/usr/bin/env bash
# Rollback check.
#
# RELEASE.txt says: if a release breaks, copy the old binary back. So data
# written by this version must still load in the previous release, the
# previous release must not damage it, and it must still be right when the
# new version is put back again.
#
# Three steps on one copy of the sample data:
#   1. new version   Greenway Taxis becomes fleet, a fleet customer is added,
#                    Greenway buys vehicle 1002
#   2. release 2.3   built from git history; lists, quotes, adds a customer and
#                    sells a vehicle, so it rewrites every data file
#   3. new version   again, on what 2.3 left behind
#
#   bash tests/rollback.sh        needs the full git history (not a shallow clone)

set -u -o pipefail
cd "$(dirname "$0")/.." || exit 2
ROOT=$PWD
NEW=${BIN:-./dealerdesk}
case $NEW in /*) ;; *) NEW=$ROOT/$NEW ;; esac
PREVIOUS=a2ba708        # release 2.3, the code as Nextlane delivered it

[ -x "$NEW" ] || { echo "program not found: $NEW (run make first)"; exit 2; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

mkdir "$work/old"
git archive "$PREVIOUS" | tar -xf - -C "$work/old" ||
    { echo "cannot read commit $PREVIOUS from git history (shallow clone?)"; exit 2; }
(cd "$work/old" && ${CC:-cc} -o dealerdesk main.c dbfile.c screen.c calc.c -lm) ||
    { echo "release 2.3 does not build"; exit 2; }

cp -r tests/fixtures/data "$work/data"
cd "$work" || exit 2

keys() { printf '%s\n' "$@"; }

# 1. new version
keys 2 4 2008 y '' \
     2 'Northside Rentals' '01632 960999' 'hire@northside.example' F '' 0 \
     4 1002 2008 0 0 y '' 0 | "$NEW" > step1.out 2>&1
fleet_invoice=$(grep '^50233|' data/invoices.dat)

# 2. release 2.3: list customers, quote Greenway on vehicle 1003, add a
#    customer, sell vehicle 1004 to customer 2001, view the fleet invoice
keys 2 1 '' 0 \
     3 1003 2008 0 0 '' \
     2 2 'Rollback Check' 1 2 n '' 0 \
     4 1004 2001 0 0 y '' \
     5 2 50233 '' 0 0 | old/dealerdesk > step2.out 2>&1
old_status=$?

# 3. new version again: list customers, quote Greenway on vehicle 1003, view
#    the fleet invoice
keys 2 1 '' 0 \
     3 1003 2008 0 0 '' \
     5 2 50233 '' 0 0 | "$NEW" > step3.out 2>&1

failed=0
check() {   # check "what must be true" command...
    label=$1; shift
    if "$@" > /dev/null 2>&1; then echo "ok   $label"; else echo "FAIL $label"; failed=1; fi
}
has()  { grep -q -- "$1" "$2"; }      # has PATTERN FILE
line() { grep -q -x -F -- "$1" "$2"; } # line EXACT-LINE FILE
lacks() { ! grep -q -- "$1" "$2"; }       # lacks PATTERN FILE

echo "-- the new version wrote what this check relies on"
check "Greenway Taxis was saved as fleet"                line "2008|Greenway Taxis|01632 960702|fleet@greenwaytaxis.example|F" data/customers.dat
check "the fleet invoice was saved"                      [ -n "$fleet_invoice" ]

echo "-- release 2.3 on that data"
check "it did not crash"                                 [ "$old_status" -eq 0 ]
check "its screens say v2.3"                             has 'DEALERDESK v2.3' step2.out
check "it lists all 9 customers"                         has '9 customer(s)' step2.out
check "it quotes Greenway at full price (no fleet line)" has 'TOTAL  *19429.00' step2.out
check "it shows the fleet invoice with the right total"  has 'TOTAL  *12901.24' step2.out
check "it saved its own customer"                        line "2010|Rollback Check|1|2|R" data/customers.dat
check "it saved its own invoice"                         has '^50234|' data/invoices.dat

echo "-- what release 2.3 left on disk"
check "Greenway Taxis is still fleet"                    line "2008|Greenway Taxis|01632 960702|fleet@greenwaytaxis.example|F" data/customers.dat
check "the added fleet customer is still fleet"          line "2009|Northside Rentals|01632 960999|hire@northside.example|F" data/customers.dat
check "an original customer is unchanged"                line "2002|Marlow Motors Ltd|01632 960118|buying@marlowmotors.example|T" data/customers.dat
check "the fleet invoice line is unchanged"              line "$fleet_invoice" data/invoices.dat
check "an original invoice line is unchanged"            line "50232|2021-03-29|1001|2008|10495.00|839.60|9655.40|1961.08|205.00|0.00|11821.48" data/invoices.dat
check "both sold vehicles are marked sold"               [ "$(grep -c -E '^100[24]\|.*\|2$' data/stock.dat)" -eq 2 ]
check "the id counters moved on"                         line "invoice=50235" data/next_ids.dat

echo "-- the new version put back"
check "its screens no longer say v2.3"                   lacks 'DEALERDESK v2.3' step3.out
check "it lists all 10 customers"                        has '10 customer(s)' step3.out
check "Greenway Taxis is fleet again"                    has 'Greenway Taxis .*Fleet' step3.out
check "Greenway gets the fleet discount again"           has 'TOTAL  *18661.24' step3.out
check "the fleet invoice still shows the right total"    has 'TOTAL  *12901.24' step3.out

[ "$failed" -eq 0 ]
