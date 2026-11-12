# NOTES

Everything below can be checked from a clone: `make test`, `make test-asan`, `make test-rollback`, `make test-speed`, `make test-mutants`. The backlog is the [issue list](https://github.com/tgondar/dealerdesk/issues); the published result is [release 2.4](https://github.com/tgondar/dealerdesk/releases/tag/v2.4).

## What I changed, in order, and why

**1. Nothing in the program. First I recorded what it does.** The brief's problem is fear of change, and the ticket demands "unchanged, to the penny". Neither can be answered without a baseline. `tests/sessions/*.in` are keystrokes; the runner pipes them into the real binary on a copy of the data and compares every screen and data file byte for byte. The program needed no change to be tested, so I did not refactor it: the first seven commits add 39 files and modify none.

**2. I treated the documentation as wrong until proven right.** The README contradicted the code in eight places (trade discount 5% vs 10%, the VAT base, a build command naming a deleted file). The three real invoices recompute exactly with the code, so the code is the truth. That went into `CLAUDE.md` before any agent touched pricing. Four of the 18 deliberate mistakes in `tests/mutants.sh` are "do what the old README said", and the tests fail for each.

**3. CI on Linux and macOS**, with a sanitizer build. macOS (clang, arm64) reproduces a baseline recorded with gcc on x86-64.

**4. TICKET-142, test first.** Two commits are red on purpose and say `(failing)`. Fleet is a third customer type letter, so no file format changes.

**5. A defect the feature made worse (#10).** A customer saved without a phone or email reloaded with its fields shifted, so a fleet customer silently lost the discount. A vehicle saved without a make reloaded priced 0.00. Fixed in its own pull request, after recording the broken behaviour.

**6. Release by tag.** `v2.4` builds, runs every check on that exact binary, and publishes it with a checksum. `make test-rollback` builds release 2.3 from history and proves it still reads 2.4's data, because the documented rollback is "copy the old binary back". `make test-speed` times each build against 2.3 with the data files nearly full, and fails one that takes more than twice as long.

**7. README corrected**, last, once tests pinned every rule it states.

**Left alone on purpose:** 10 open issues that staff would notice or that need a business answer (input validation, non-atomic saves, the Help screen's wrong text, a one-penny rounding case reproduced on 2.3).

## How I worked with the agent

I used Claude Code. I made the decisions; it did the reading, writing and running. What kept it honest was mechanical, not advisory:

- `make record` refuses to run while source files are uncommitted, so it cannot re-record a baseline to turn a failure green.
- Existing baselines were edited by hand before the code. They passed on the first build, and the diff against `master` is exactly three kinds of line.
- A second agent reviewed the feature diff with the ticket and the house rules but none of my conclusions.
- Every claim is marked as "observed by running" or "read in the code".

**Where it got things wrong, and how that was caught:**

- **A design that broke the ticket.** It added a second prompt, "Fleet customer (Y/N)?", and reasoned that ENTER meaning No kept old habits safe. It had also edited the keystroke files to fit. The review agent replayed the original keystrokes: one customer saved instead of two. I chose a single prompt that also accepts `F`; the keystroke files are identical to `master` again.
- **Tests that could not fail.** Unit tests accepted anything within half a penny, so an unrounded discount passed; three rollback checks were true whatever the program did. The reviewer found both by deleting the rounding and watching everything stay green. That is why `tests/mutants.sh` now exists.
- **It skipped something I had asked for.** At the start I asked to measure the system before and after. It timed one session once, decided speed did not matter for a terminal program, and moved on. I noticed at the end. Its first speed check then took the fastest of seven runs and once reported 0 ms, because WSL adjusts the clock mid-run. It now takes the median.
- **It tried to merge the feature itself** after I said I wanted less waiting. The permission system refused, and it did not look for a way round. I merge.

## Assumptions

Posted on the ticket (#21) as questions to the requester:

- Retail, trade and fleet are exclusive. A trade customer cannot be fleet.
- "Vehicle price" is the list price. The salesman percentage applies after the fleet discount, and its 15% cap is separate.
- The fleet line appears on the quote and the invoice preview, where the trade line appears. Saved invoices keep one combined discount (#20).
- 10% trade discount and the 15% cap are intended, because invoices were issued with them.
- The source stays C89 for the old Windows compiler, which I could not run. The release is Linux only and says so.

## What I would do next

1. Get answers from the business: trade plus fleet, the trade rate, the one-penny rounding (#14), whether showrooms share a data folder (#15).
2. A separate fleet line on saved invoices (#20), extending the rollback check first.
3. Atomic saves (#12) and input validation (#11), each behind a recorded baseline.
4. Correct the Help screen once signed off.
5. A reproducible Windows build.
6. A hook that runs `make test` after every agent edit.

Time: about 3.5 hours of wall-clock time in one day, measured from the session transcript; the agent was working for a little over half of it.
