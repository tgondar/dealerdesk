This standard disclaimer states that the work is entirely fictional and any resemblance to real people, places, or events is coincidental.

DEALERDESK
==========

Dealer management for the showroom: stock, customers, quotes and invoices.

The version is shown at the top of every screen.


QUICK START (Linux, macOS, or WSL on Windows)
---------------------------------------------

You need a C compiler (gcc or clang). From the repository root:

    gcc -o dealerdesk *.c -lm
    ./dealerdesk

* Always run it from the repository root. It reads and writes the files in ./data
* Pick a menu option by typing its number and pressing ENTER. 0 goes back, and
  0 on the main menu exits.
* Every change (new vehicle, sale, ...) is saved to data/*.dat immediately.
  To put the sample data back:

      git checkout -- data


BUILD AND TEST
--------------

    make                 builds ./dealerdesk with strict warnings
    make test            pricing tests, then every recorded session
    make test-asan       the same sessions, stopping on memory errors
    make test-rollback   checks that release 2.3 still reads the data
    make test-speed      checks it is not slower than release 2.3

"make" and the Quick Start command build the same program from main.c,
dbfile.c, screen.c and calc.c.

Run "make test" before and after any change. A failure means the program
no longer does what it did. See CLAUDE.md for how the tests work.

(Windows releases are built with the Borland compiler on the old build PC.)


RUN
---

    ./dealerdesk

Data files are read from the "data" folder in the directory the program is
started from:

    stock.dat       vehicles
    customers.dat   customers
    invoices.dat    invoices
    next_ids.dat    id counters

Do NOT edit the .dat files by hand while the program is running!


MENU
----

    1. Stock
    2. Customers
    3. Quote
    4. Sell vehicle
    5. Invoices
    9. Help
    0. Exit


PRICING RULES
-------------

* Trade customers get a 10% trade discount off the list price.
* Fleet customers get a 4% fleet discount off the list price.
  A customer is retail, trade or fleet, never two at once.
* Salesman discount is a percentage of what is left after the trade or
  fleet discount. Anything above 15% is reduced to 15%. There is no
  manager PIN.
* Delivery (150.00) and first registration (55.00) are added to every sale.
  They are never discounted.
* VAT (20%) is calculated on the discounted price plus delivery.
  First registration is VAT exempt.
* Trade-in value is taken off the final total.

Plates are stored exactly as typed. "Find by plate" needs the same capital
letters and spaces.

The Help screen inside the program still shows older rules for the trade
discount, the salesman discount and plates. The rules above are what the
program does.


RELEASE
-------

See RELEASE.txt


Problems: ask Phil (ext. 214).
