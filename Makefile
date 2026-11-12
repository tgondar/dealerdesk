# DealerDesk build entry point for gcc or clang on Linux, macOS and WSL.
#
# The README Quick Start command keeps working and builds the same program:
#     gcc -o dealerdesk *.c -lm
#
# -std=c89 -pedantic: Windows releases are built with an old compiler, so the
# source has to stay plain C89. No optimisation flags are set, to match the
# Quick Start build.

CFLAGS = -std=c89 -pedantic -Wall -Wextra
SRC    = main.c dbfile.c screen.c calc.c
HDR    = globals.h dbfile.h screen.h calc.h

all: dealerdesk

# LDFLAGS is empty by default. The release build sets it to -static so the
# binary does not depend on the C library of the machine it is copied to.
dealerdesk: $(SRC) $(HDR)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(SRC) -lm

# The same sessions run against a build that stops on memory errors and
# undefined behaviour.
build/dealerdesk-asan: $(SRC) $(HDR)
	mkdir -p build
	$(CC) $(CFLAGS) -g -fsanitize=address,undefined -fno-sanitize-recover=all -o $@ $(SRC) -lm

build/test_calc: tests/test_calc.c calc.c calc.h
	mkdir -p build
	$(CC) $(CFLAGS) -I. -o $@ tests/test_calc.c calc.c -lm

test: dealerdesk build/test_calc
	build/test_calc
	BIN=./dealerdesk bash tests/run.sh

test-asan: build/dealerdesk-asan
	BIN=build/dealerdesk-asan bash tests/run.sh

# Data written by this version must survive putting release 2.3 back.
test-rollback: dealerdesk
	BIN=./dealerdesk bash tests/rollback.sh

# Applies deliberate mistakes one at a time; the tests must catch each one.
test-mutants:
	bash tests/mutants.sh

# Rewrites tests/expected. Read CLAUDE.md before using it.
record: dealerdesk
	BIN=./dealerdesk bash tests/run.sh record

clean:
	rm -rf dealerdesk build

.PHONY: all test test-asan test-rollback test-mutants record clean
