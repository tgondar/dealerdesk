# DealerDesk: rules for AI agents

DealerDesk is a menu-driven terminal program in C. Car dealerships use it every day for stock, customers, quotes and invoices, and it has been in production for years. Staff must not notice any change except a feature that a ticket asks for.

## The program is right, the documentation is wrong

`README.md`, `RELEASE.txt`, the Help screen and several code comments describe an older program. When they disagree with the code, the code and the invoices in `data/invoices.dat` are right. Never change behaviour to match the documentation.

| Topic | Documentation says | The program does | Issue |
|---|---|---|---|
| Trade discount | 5% | 10% | #5 |
| Salesman discount | 10% maximum, manager PIN above | capped at 15% without a message, no PIN | #6 |
| VAT | on list price; delivery exempt | 20% of (net price + delivery) | #7 |
| Plates | upper-cased when added | stored as typed | #8 |
| Build | `main.c dbfile.c screen.c report.c` | `report.c` does not exist | #2 |
| Data folder | `C:\DEALERDESK\DATA` | `./data`, relative to where it is started | #3 |
| Menu | has "6. Reports" | removed | #4 |
| Version | README says 2.1 | `DD_VERSION` in `screen.h`, printed on every screen | #1 |

Pricing, as `calc_quote()` implements it:

    list price
    - trade discount        10% for type T customers
    - fleet discount        4% for type F customers (TICKET-142)
    - salesman discount     % of what remains, capped at 15
    = net price
    + delivery              150.00
    + VAT                   20% of (net price + delivery)
    + registration fee      55.00
    - trade-in
    = total

A customer has one type letter in `data/customers.dat`: `R` retail, `T` trade, `F` fleet. A customer is never two types at once. Saved invoices store one combined discount amount, with no breakdown (#20).

## Commands

Run these on Linux, macOS or WSL, from the repository root.

| Command | What it does |
|---|---|
| `make` | builds `./dealerdesk` with `-std=c89 -pedantic -Wall -Wextra` |
| `make test` | pricing unit tests, then every recorded session against the baseline |
| `make test-asan` | the same sessions on a build that stops on memory errors |
| `make test-rollback` | builds release 2.3 from git history and checks it still reads, and does not damage, data written by the current code |
| `make record` | rewrites the baseline (see the rules below) |
| `make clean` | removes build output |

The README Quick Start command, `gcc -o dealerdesk *.c -lm`, must keep working. Do not add `.c` files to the repository root unless they belong to the program; tests live in `tests/`.

## Releases

`RELEASE.txt` is the procedure and it is accurate. In short: the version lives in `DD_VERSION` in `screen.h`; a pushed tag `vX.Y` that matches it makes the Release workflow build, run every check on that binary and publish it. Never move or reuse a tag. `CHANGES.txt` is written for showroom staff, not for developers: no file names, no issue numbers.

## How the tests work

- `tests/sessions/NAME.in` is what a user types, one line per ENTER. A line with only `@restart` closes the program and starts it again on the same data.
- `tests/expected/NAME.out` is what the program printed and the data files it left behind, recorded from the code as Nextlane delivered it.
- `tests/fixtures/data` is the frozen sample data every session starts from. Do not edit it. A session that needs other data brings its own files in `tests/sessions/NAME.data/`.
- `tests/test_calc.c` checks `calc_quote()` directly. Its first three cases are the real invoices.

A failing comparison means behaviour changed. That is the test doing its job.

## Rules

1. **Tests first.** Before changing behaviour, add or edit the session and the expected output that describe the new behaviour, see them fail, then change the code.
2. **Never record to make a failure go away.** Use `make record` only to add a session for behaviour that already exists, or when the change in behaviour is the purpose of the work. Commit re-recorded files separately from the code, so a reviewer can read the difference. The script refuses to record while source files differ from the last commit.
3. **Plain C89.** Declarations at the top of a block, `/* */` comments, no `snprintf`, no `stdint.h`, no `stdbool.h`. Windows releases are built with an old compiler that nobody here can run.
4. **Do not run `./dealerdesk` in the repository root from a script.** It writes to `data/` at once. The test runner uses a throwaway copy. `git checkout -- data` restores the sample data.
5. **Data files stay compatible in both directions.** Existing `data/*.dat` files must load without conversion, and a file written by a new version must still load in the previous one, because the rollback procedure is to put the old binary back. Do not insert, reorder or remove fields. A change to what is stored extends `tests/rollback.sh`.
6. **Known defects stay until someone decides.** The baseline records them on purpose, for example the negative totals in `quote-retail` (#11). If you find a new defect or another place where documentation and code disagree, open an issue. Do not fix it as part of other work.
7. **Hostile input gets a test.** A change that reads or stores user input extends `tests/sessions/input-hostile.in` or adds a `*-input-hostile.in` session (separator characters, over-long input, format specifiers) and must pass `make test-asan`.
8. **Money is exact to the penny.** Round with `rnd2()` at the same points the existing code does.
9. **Say what you ran.** In commit messages and reports, separate what was observed by running from what was only read in the code.
10. **One purpose per commit.** Prefix `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf` or `ci`, and reference the issue number.
