/*
 * dbfile.c - flat file storage
 *
 * Files live in ./data, relative to where the program is started
 * One record per line, fields separated by |
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "globals.h"
#include "dbfile.h"

#define DATA_DIR "data/"

static void cpy(char *d, const char *s, int n)
{
    strncpy(d, s ? s : "", n - 1);
    d[n - 1] = 0;
}

/*
 * Returns the next |-separated field of a line and moves *rest past it;
 * NULL when the line has no more fields. Unlike strtok, an empty field is
 * returned as "" and not skipped. Skipping it moved every later field one
 * place to the left (issue #10).
 */
static char *next_field(char **rest)
{
    char *field = *rest;
    char *bar;

    if (field == NULL)
        return NULL;
    bar = strchr(field, '|');
    if (bar) {
        *bar = 0;
        *rest = bar + 1;
    } else {
        *rest = NULL;
    }
    return field;
}

static void load_stock(void)
{
    FILE *f;
    char line[512];
    char *t;
    char *rest;
    VEHICLE *v;

    nveh = 0;
    f = fopen(DATA_DIR "stock.dat", "r");
    if (!f)
        return;
    while (fgets(line, sizeof line, f) && nveh < MAX_VEH) {
        line[strcspn(line, "\r\n")] = 0;
        if (line[0] == 0 || line[0] == '#')
            continue;
        v = &veh[nveh];
        rest = line;
        t = next_field(&rest);
        if (!t)
            continue;
        v->id = atoi(t);
        t = next_field(&rest);
        cpy(v->plate, t, sizeof v->plate);
        t = next_field(&rest);
        cpy(v->make, t, sizeof v->make);
        t = next_field(&rest);
        cpy(v->model, t, sizeof v->model);
        t = next_field(&rest);
        v->year = t ? atoi(t) : 0;
        t = next_field(&rest);
        v->mileage = t ? atol(t) : 0;
        t = next_field(&rest);
        v->cost = t ? atof(t) : 0;
        t = next_field(&rest);
        v->price = t ? atof(t) : 0;
        t = next_field(&rest);
        v->status = t ? atoi(t) : 0;
        nveh++;
    }
    fclose(f);
}

static void load_customers(void)
{
    FILE *f;
    char line[512];
    char *t;
    char *rest;
    CUSTOMER *c;

    ncust = 0;
    f = fopen(DATA_DIR "customers.dat", "r");
    if (!f)
        return;
    while (fgets(line, sizeof line, f) && ncust < MAX_CUST) {
        line[strcspn(line, "\r\n")] = 0;
        if (line[0] == 0 || line[0] == '#')
            continue;
        c = &cust[ncust];
        rest = line;
        t = next_field(&rest);
        if (!t)
            continue;
        c->id = atoi(t);
        t = next_field(&rest);
        cpy(c->name, t, sizeof c->name);
        t = next_field(&rest);
        cpy(c->phone, t, sizeof c->phone);
        t = next_field(&rest);
        cpy(c->email, t, sizeof c->email);
        t = next_field(&rest);
        c->type = (t && t[0]) ? t[0] : 'R';
        ncust++;
    }
    fclose(f);
}

static void load_invoices(void)
{
    FILE *f;
    char line[512];
    char *t;
    char *rest;
    INVOICE *i;

    ninv = 0;
    f = fopen(DATA_DIR "invoices.dat", "r");
    if (!f)
        return;
    while (fgets(line, sizeof line, f) && ninv < MAX_INV) {
        line[strcspn(line, "\r\n")] = 0;
        if (line[0] == 0 || line[0] == '#')
            continue;
        i = &inv[ninv];
        rest = line;
        t = next_field(&rest);
        if (!t)
            continue;
        i->no = atoi(t);
        t = next_field(&rest);
        cpy(i->date, t, sizeof i->date);
        t = next_field(&rest);
        i->veh_id = t ? atoi(t) : 0;
        t = next_field(&rest);
        i->cust_id = t ? atoi(t) : 0;
        t = next_field(&rest);
        i->list = t ? atof(t) : 0;
        t = next_field(&rest);
        i->disc = t ? atof(t) : 0;
        t = next_field(&rest);
        i->net = t ? atof(t) : 0;
        t = next_field(&rest);
        i->vat = t ? atof(t) : 0;
        t = next_field(&rest);
        i->fees = t ? atof(t) : 0;
        t = next_field(&rest);
        i->tradein = t ? atof(t) : 0;
        t = next_field(&rest);
        i->total = t ? atof(t) : 0;
        ninv++;
    }
    fclose(f);
}

static void load_ids(void)
{
    FILE *f;
    char line[128];

    f = fopen(DATA_DIR "next_ids.dat", "r");
    if (!f)
        return;
    while (fgets(line, sizeof line, f)) {
        sscanf(line, "vehicle=%d", &next_veh_id);
        sscanf(line, "customer=%d", &next_cust_id);
        sscanf(line, "invoice=%d", &next_inv_no);
    }
    fclose(f);
}

void load_all(void)
{
    load_stock();
    load_customers();
    load_invoices();
    load_ids();
}

void save_stock(void)
{
    FILE *f;
    int i;

    f = fopen(DATA_DIR "stock.dat", "w");
    if (!f) {
        printf("  ERROR: cannot write stock.dat\n");
        return;
    }
    for (i = 0; i < nveh; i++)
        fprintf(f, "%d|%s|%s|%s|%d|%ld|%.2f|%.2f|%d\n",
                veh[i].id, veh[i].plate, veh[i].make, veh[i].model,
                veh[i].year, veh[i].mileage, veh[i].cost, veh[i].price,
                veh[i].status);
    fclose(f);
}

void save_customers(void)
{
    FILE *f;
    int i;

    f = fopen(DATA_DIR "customers.dat", "w");
    if (!f) {
        printf("  ERROR: cannot write customers.dat\n");
        return;
    }
    for (i = 0; i < ncust; i++)
        fprintf(f, "%d|%s|%s|%s|%c\n",
                cust[i].id, cust[i].name, cust[i].phone, cust[i].email,
                cust[i].type);
    fclose(f);
}

void save_invoices(void)
{
    FILE *f;
    int i;

    f = fopen(DATA_DIR "invoices.dat", "w");
    if (!f) {
        printf("  ERROR: cannot write invoices.dat\n");
        return;
    }
    for (i = 0; i < ninv; i++)
        fprintf(f, "%d|%s|%d|%d|%.2f|%.2f|%.2f|%.2f|%.2f|%.2f|%.2f\n",
                inv[i].no, inv[i].date, inv[i].veh_id, inv[i].cust_id,
                inv[i].list, inv[i].disc, inv[i].net, inv[i].vat,
                inv[i].fees, inv[i].tradein, inv[i].total);
    fclose(f);
}

void save_ids(void)
{
    FILE *f;

    f = fopen(DATA_DIR "next_ids.dat", "w");
    if (!f) {
        printf("  ERROR: cannot write next_ids.dat\n");
        return;
    }
    fprintf(f, "vehicle=%d\ncustomer=%d\ninvoice=%d\n",
            next_veh_id, next_cust_id, next_inv_no);
    fclose(f);
}
