/*
 * Unit tests for calc_quote(): the pricing rules as the program applies them
 * today. The first three cases are the invoices in data/invoices.dat, so the
 * expected figures come from real documents and not from this code.
 *
 * Several of these rules contradict README.md and the Help screen (trade
 * discount 10%, cap 15%, VAT on the discounted price plus delivery). The
 * program is right; see CLAUDE.md.
 */
#include <stdio.h>
#include <math.h>
#include "calc.h"

typedef struct {
    const char *name;
    double list;            /* inputs */
    char   type;
    double pct;
    double tradein;
    double trade_disc;      /* expected */
    double disc_pct;
    double disc;
    double net;
    double vat;
    double total;
} CASE;

static const CASE cases[] = {
    /* name                                 list      type pct  trade-in  trade    pct   disc     net       vat      total */
    {"invoice 50230: retail, 5%, trade-in",  9295.00, 'R',  5.0, 1500.00,    0.00,  5.0,  464.75,  8830.25, 1796.05,  9331.30},
    {"invoice 50231: trade",                13495.00, 'T',  0.0,    0.00, 1349.50,  0.0,    0.00, 12145.50, 2459.10, 14809.60},
    {"invoice 50232: retail, 8%",           10495.00, 'R',  8.0,    0.00,    0.00,  8.0,  839.60,  9655.40, 1961.08, 11821.48},
    {"retail, no discount",                 10995.00, 'R',  0.0,    0.00,    0.00,  0.0,    0.00, 10995.00, 2229.00, 13429.00},
    {"trade discount is 10%",               10995.00, 'T',  0.0,    0.00, 1099.50,  0.0,    0.00,  9895.50, 2009.10, 12109.60},
    {"salesman % applies after trade",      10000.00, 'T', 10.0,    0.00, 1000.00, 10.0,  900.00,  8100.00, 1650.00,  9955.00},
    {"salesman % is capped at 15",          10995.00, 'R', 20.0,    0.00,    0.00, 15.0, 1649.25,  9345.75, 1899.15, 11449.90},
    {"negative % becomes 0",                10995.00, 'R', -3.0,    0.00,    0.00,  0.0,    0.00, 10995.00, 2229.00, 13429.00},
    {"half a penny rounds up",              10995.00, 'R',  7.5,    0.00,    0.00,  7.5,  824.63, 10170.37, 2064.07, 12439.44},
    {"fees are never discounted",            1000.00, 'T', 15.0,    0.00,  100.00, 15.0,  135.00,   765.00,  183.00,  1153.00},
    {"unknown type gets no trade discount", 10995.00, 'X',  0.0,    0.00,    0.00,  0.0,    0.00, 10995.00, 2229.00, 13429.00},
    {"type is case sensitive",              10995.00, 't',  0.0,    0.00,    0.00,  0.0,    0.00, 10995.00, 2229.00, 13429.00},

    /* TICKET-142: fleet customers (type F) get 4% off the list price. The
     * salesman % then applies to what remains, as it does after the trade
     * discount, and its 15% cap is not used up by the fleet discount.
     * Figures worked out by hand before the code was written. */
    {"fleet: 4% off the list price",        10995.00, 'F',  0.0,    0.00,    0.00,  0.0,    0.00, 10555.20, 2141.04, 12901.24},
    {"fleet: salesman % applies after",     10995.00, 'F',  5.0,    0.00,    0.00,  5.0,  527.76, 10027.44, 2035.49, 12267.93},
    {"fleet: salesman cap stays at 15",     10995.00, 'F', 20.0,    0.00,    0.00, 15.0, 1583.28,  8971.92, 1824.38, 11001.30},
    {"fleet: with % and trade-in",          10995.00, 'F',  7.5, 1500.00,    0.00,  7.5,  791.64,  9763.56, 1982.71, 10451.27},
    {"fleet: fees are not discounted",       1000.00, 'F',  0.0,    0.00,    0.00,  0.0,    0.00,   960.00,  222.00,  1387.00},
    {"fleet: discount rounds to the penny", 12345.67, 'F',  0.0,    0.00,    0.00,  0.0,    0.00, 11851.84, 2400.37, 14457.21},
    {"fleet: type is case sensitive",       10995.00, 'f',  0.0,    0.00,    0.00,  0.0,    0.00, 10995.00, 2229.00, 13429.00}
};

static int failures = 0;

static void check(const char *name, const char *field, double got, double want)
{
    if (fabs(got - want) >= 0.005) {
        printf("FAIL %s: %s is %.4f, expected %.2f\n", name, field, got, want);
        failures++;
    }
}

int main(void)
{
    int i, n = (int)(sizeof cases / sizeof cases[0]);
    QUOTE q;

    for (i = 0; i < n; i++) {
        const CASE *c = &cases[i];

        calc_quote(&q, c->list, c->type, c->pct, c->tradein);
        check(c->name, "list", q.list, c->list);
        check(c->name, "trade discount", q.trade_disc, c->trade_disc);
        check(c->name, "discount %", q.disc_pct, c->disc_pct);
        check(c->name, "discount", q.disc, c->disc);
        check(c->name, "net", q.net, c->net);
        check(c->name, "delivery", q.delivery, 150.00);
        check(c->name, "VAT", q.vat, c->vat);
        check(c->name, "registration fee", q.reg_fee, 55.00);
        check(c->name, "trade-in", q.tradein, c->tradein);
        check(c->name, "total", q.total, c->total);
    }
    printf("calc: %d cases, %d failed checks\n", n, failures);
    return failures != 0;
}
