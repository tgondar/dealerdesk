# NOTES

Everything below can be checked from a clone: `make test`, `make test-asan`, `make test-rollback`, `make test-speed`, `make test-mutants`. The backlog is the [issue list](https://github.com/tgondar/dealerdesk/issues); the result is [release 2.4](https://github.com/tgondar/dealerdesk/releases/tag/v2.4).

## What I changed, in order, and why

**1. Nothing in the program. First I recorded what it does.** The brief's problem is fear of change, and the ticket demands "unchanged, to the penny". So scripted keystrokes are piped into the real binary and every screen and data file is compared byte for byte. The program needed no change to be tested, so I did not refactor it: the first seven commits add 39 files and modify none.

**2. I treated the documentation as wrong until proven right.** The README contradicted the code in eight places, including the trade discount and the VAT base. The three real invoices recompute exactly with the code, so the code is the truth. That went into `CLAUDE.md` before any agent touched pricing.

**3. CI on Linux and macOS**, with a sanitizer build.

**4. TICKET-142, test first.** Three commits are red on purpose and say `(failing)`; each is followed by the one that turns it green. Fleet is a third customer type letter, so no file format changes.

**5. A defect the feature made worse (#10).** A customer saved without a phone or email reloaded with its fields shifted, so a fleet customer silently lost the discount. Fixed in its own pull request, after recording the broken behaviour.

**6. Release by tag.** `v2.4` builds, runs every check on that exact binary and publishes it with a checksum. Two checks build release 2.3 from history: `make test-rollback` proves 2.3 still reads 2.4's data, since the documented rollback is "copy the old binary back", and `make test-speed`, added after 2.4, fails a build more than twice as slow.

**7. README corrected**, last, once tests pinned every rule it states.

**Left alone on purpose:** 10 open issues that staff would notice or that need a business answer (for example input validation, non-atomic saves and the Help screen's wrong text).

## My agent setup

I used Claude Code. I made the decisions; it did the reading, writing and running.

**In the repository:** `CLAUDE.md`, the test scripts and two workflows. The guards are mechanical, not advisory: `make record` refuses to run with uncommitted source, so an agent cannot re-record a baseline to turn a failure green; `make test-mutants` applies 18 deliberate mistakes and fails if the tests miss one.

**Not in the repository:** my own Claude Code configuration, which I share with unrelated projects. My standing instructions make the agent log every decision it takes without asking me, and separate what it ran from what it only read. From the `agent-skills` plugin I used these commands, in this order:

| Command | Used for |
|---|---|
| `/idea-refine` | the analysis before any change |
| `/test-driven-development` | TICKET-142: failing test first, then the code |
| `code-reviewer` agent | an independent review of the feature diff, without my conclusions |
| `/spec-driven-development` | the spec: requirements with ids and success criteria |
| `/planning-and-task-breakdown` | the plan and the task cards |
| `/code-review-and-quality` | the review of the last pull request; it found five wrong statements in this file |

The spec, the plan and the task cards are in my own notes, not in the repository.

**The prompts that steered the work** (shortened and tidied, not word for word):

| When | What I asked |
|---|---|
| Before anything | "Identify the constraints and what needs solving. I want to understand what works today and what will be added, and to measure the system before and after, with any SLI/SLO I should check. Before any change, let's discuss." |
| Before any code | "Do we have tests? If not, this is mandatory. Then we run the same tests to confirm no behaviour was lost." |
| After the release | "You did nothing about speed, even though I asked. How will I know if the new release is slower?" |

## Where the agent got things wrong

- **A design that broke the ticket.** It added a second prompt, "Fleet customer (Y/N)?", and had edited the keystroke files to fit. The review agent replayed the original keystrokes: one customer saved instead of two. I chose a single prompt that also accepts `F`; the keystroke files are identical to the originals again.
- **Tests that could not fail.** Unit tests accepted anything within half a penny, so an unrounded discount passed. The reviewer found it by deleting the rounding and watching everything stay green.
- **It skipped something I had asked for.** It timed one session once, decided speed did not matter for a terminal program, and moved on. I noticed after the release. Its first speed check then reported 0 ms once: 3 of 350 logged timings were nonsense, most likely the clock being adjusted mid-run under WSL. It now takes the median of seven runs.

## Assumptions

Posted on the ticket (#21) as questions to the requester:

- Retail, trade and fleet are exclusive.
- "Vehicle price" is the list price. The salesman percentage applies after the fleet discount, and its 15% cap is separate.
- The fleet line appears on the quote and the invoice preview, where the trade line appears. Saved invoices keep one combined discount (#20).
- The 10% trade discount and the 15% cap are intended, because invoices were issued with them.
- The source stays C89 for the old Windows compiler, which I could not run. The release is Linux only and says so.

## What I would do next

1. Get answers from the business: trade plus fleet, the trade rate, the one-penny rounding (#14), whether showrooms share a data folder (#15).
2. A separate fleet line on saved invoices (#20), extending the rollback check first.
3. Atomic saves (#12) and input validation (#11), each behind a recorded baseline.
4. Correct the Help screen once signed off, and make the Windows build reproducible.
