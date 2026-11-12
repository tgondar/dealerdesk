# NOTES

Any claim here can be checked from a clone: `make test`, `make test-asan`, `make test-rollback`, `make test-speed`, `make test-mutants`. Backlog: the [issues](https://github.com/tgondar/dealerdesk/issues). Result: [release 2.4](https://github.com/tgondar/dealerdesk/releases/tag/v2.4).

## What I changed, in order, and why

1. **Recorded what the program does, before changing it.** The ticket demands "unchanged, to the penny", so scripted keystrokes go into the real binary and every screen and data file is compared byte for byte. The first seven commits add 39 files and modify none.
2. **Treated the documentation as wrong.** The README contradicted the code in eight places. The three real invoices recompute exactly with the code, so the code is the truth.
3. **CI on Linux and macOS**, with a sanitizer build.
4. **TICKET-142, test first.** Three commits are red on purpose and say `(failing)`. Fleet is a third customer type letter, so no file format changes.
5. **Fixed a defect the feature made worse (#10).** A customer saved without a phone reloaded with shifted fields, so a fleet customer silently lost the discount.
6. **Release by tag.** `v2.4` is built, checked and published with a checksum. `make test-rollback` proves release 2.3 still reads 2.4's data; `make test-speed`, added after 2.4, fails a build twice as slow as 2.3.
7. **Corrected the README**, once tests pinned every rule it states.

Left alone on purpose: 10 open issues that staff would notice or that need a business answer.

## How I worked with the agent

I used Claude Code. I decided; it read, wrote and ran. The guards are mechanical: `make record` refuses to run with uncommitted source, so an agent cannot re-record a baseline to hide a failure, and `make test-mutants` fails if the tests miss any of 18 deliberate mistakes. Setup, commands and prompts: [PROMPTS.md](PROMPTS.md).

Where it got things wrong:

- **A design that broke the ticket.** It added a second prompt and edited the keystroke files to fit. An independent review agent replayed the original keystrokes: one customer saved instead of two. I chose one prompt that also accepts `F`.
- **Tests that could not fail.** Unit tests accepted anything within half a penny, so an unrounded discount passed. The reviewer found it by deleting the rounding and watching everything stay green.
- **It skipped something I had asked for.** It timed one session once and decided speed did not matter. I noticed after the release; `make test-speed` is the result.

## Assumptions

Posted on the ticket (#21) as questions to the requester:

- Retail, trade and fleet are exclusive.
- "Vehicle price" is the list price; the salesman percentage applies after the fleet discount.
- The fleet line appears on the quote and the invoice preview; saved invoices keep one combined discount (#20).
- The 10% trade discount and the 15% cap are intended: invoices were issued with them.
- The source stays C89 for the old Windows compiler, which I could not run.

## What I would do next

1. Get business answers: trade plus fleet, the trade rate, a one-penny rounding case (#14).
2. A fleet line on saved invoices (#20), extending the rollback check first.
3. Atomic saves (#12) and input validation (#11), each behind a recorded baseline.
4. Correct the Help screen once signed off, and make the Windows build reproducible.
