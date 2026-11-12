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

dealerdesk: $(SRC) $(HDR)
	$(CC) $(CFLAGS) -o $@ $(SRC) -lm

clean:
	rm -rf dealerdesk build

.PHONY: all clean
