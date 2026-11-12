#!/usr/bin/env bash
# Do the tests notice when the program is wrong?
#
# Each line below is one deliberate mistake. It is applied to a throwaway copy
# of the source, and `make test` must then fail. A mistake that leaves the
# tests green is a hole in the tests. A mistake that no longer applies means
# the code moved and this list has to follow.
#
# Several are the rules the old README described: the change a reader of that
# README, human or agent, would have made.
#
#   bash tests/mutants.sh        about a minute

set -u
cd "$(dirname "$0")/.." || exit 2
ROOT=$PWD
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

caught=0
missed=0

mutant() {   # mutant "what is broken" FILE 'sed expression'
    rm -rf "$work/src" && mkdir "$work/src"
    cp "$ROOT"/*.c "$ROOT"/*.h "$ROOT"/Makefile "$work/src"/ && cp -r "$ROOT/tests" "$work/src/tests"
    sed "$3" "$work/src/$2" > "$work/changed"
    if cmp -s "$work/changed" "$work/src/$2"; then
        echo "NOT APPLIED  $1"; missed=$((missed + 1)); return
    fi
    cp "$work/changed" "$work/src/$2"
    # A mistake that does not compile proves nothing about the tests.
    if ! (cd "$work/src" && make dealerdesk build/test_calc) > /dev/null 2>&1; then
        echo "DOES NOT BUILD  $1"; missed=$((missed + 1)); return
    fi
    if (cd "$work/src" && make test) > /dev/null 2>&1; then
        echo "MISSED       $1"; missed=$((missed + 1))
    else
        echo "caught       $1"; caught=$((caught + 1))
    fi
}

# pricing rules, as the old README had them
mutant "trade discount 5% instead of 10%"               calc.c 's/list \* 0\.10/list * 0.05/'
mutant "salesman discount capped at 10 instead of 15"   calc.c 's/disc_pct > 15/disc_pct > 10/; s/disc_pct = 15/disc_pct = 10/'
mutant "VAT on the list price"                          calc.c 's/(q->net + q->delivery) \* 0\.20/(list + q->delivery) * 0.20/'
mutant "delivery not subject to VAT"                    calc.c 's/(q->net + q->delivery) \* 0\.20/q->net * 0.20/'

# fleet discount (TICKET-142)
mutant "fleet discount 5% instead of 4%"                calc.c 's/list \* 0\.04/list * 0.05/'
mutant "fleet discount not rounded to the penny"        calc.c 's/q->fleet_disc = rnd2(list \* 0\.04);/q->fleet_disc = list * 0.04;/'
mutant "salesman % taken before the fleet discount"     calc.c 's/(list - q->trade_disc - q->fleet_disc) \* disc_pct/(list - q->trade_disc) * disc_pct/'
mutant "retail customers get the fleet discount"        calc.c "s/if (cust_type == 'F')/if (cust_type != 'T')/"
mutant "saved invoice forgets the fleet amount"         main.c 's/i->disc = q.trade_disc + q.fleet_disc + q.disc;/i->disc = q.trade_disc + q.disc;/'
mutant "fleet line missing from the quote"              main.c 's/if (q->fleet_disc > 0)/if (q->fleet_disc > 99999999)/'
mutant "a trade customer can be marked fleet"           main.c "s/    if (c->type == 'T') {/    if (c->type == 'Z') {/"
mutant "marking a fleet customer changes nothing"       main.c 's/        c->type = to;/        ;/'
mutant "F is ignored when adding a customer"            main.c "s/if (b\[0\] == 'F' || b\[0\] == 'f')/if (0)/"

# screens, input and data files
mutant "plates upper-cased on add (the Help screen)"    main.c 's/    read_line("  Make       : ", v.make, sizeof v.make);/    { char *p; for (p = v.plate; *p; p++) *p = (char)toupper((unsigned char)*p); } read_line("  Make       : ", v.make, sizeof v.make);/'
mutant "one word changed on a screen"                   main.c 's/Registration fee/Registration Fee/'
mutant "separator typed by a user reaches the file"     screen.c "s/\*p = '\/';/;/"
mutant "loader skips empty fields again (issue 10)"     dbfile.c 's/        \*rest = bar + 1;/        *rest = bar + 1 + strspn(bar + 1, "|");/'
mutant "empty customer type stored as a zero byte"      dbfile.c 's/(t .. t\[0\]) ? t\[0\] : /t ? t[0] : /'

echo "$caught caught, $missed missed or not applied"
[ "$missed" -eq 0 ]
