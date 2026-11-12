# Agent setup, commands and prompts

`NOTES.md` is limited to two pages, so the detail of how the agent was set up and steered is here.

I used Claude Code. I made the decisions; it did the reading, writing and running.

## In the repository

- `CLAUDE.md`: the rules for any agent working here. `AGENTS.md` points other tools to it.
- The test scripts in `tests/` and the two workflows in `.github/workflows/`.
- Two guards that are mechanical, not advisory:
  - `make record` refuses to run with uncommitted source, so an agent cannot re-record a baseline to turn a failure green.
  - `make test-mutants` applies 18 deliberate mistakes and fails if the tests miss one.

## Not in the repository

My own Claude Code configuration, which I share with unrelated projects. My standing instructions make the agent log every decision it takes without asking me, and separate what it ran from what it only read.

The spec, the plan and the task cards are in my own notes.

## Commands used

From the `agent-skills` plugin:

| Command | Used for |
|---|---|
| `/idea-refine` | the analysis before any change |
| `/spec-driven-development` | the spec: requirements with ids and success criteria |
| `/planning-and-task-breakdown` | the plan and the task cards |
| `/test-driven-development` | TICKET-142: failing test first, then the code |
| `/code-review-and-quality` | the review of a late pull request; it found five wrong statements in `NOTES.md` |

An independent review agent also read the feature diff, with the ticket and the house rules but none of my conclusions.

## Prompts that steered the work

Shortened and tidied, not word for word.

| When | What I asked |
|---|---|
| Before anything | "Identify the constraints and what needs solving. I want to understand what works today and what will be added, and to measure the system before and after, with any SLI/SLO I should check. Before any change, let's discuss." |
| On each finding | "For every bug, and every difference between documentation and code, open an issue." |
| On the ticket | "Open it with their exact text, then add what I decided as a comment, so it is clear these are my assumptions." |
| Before any code | "Do we have tests? If not, this is mandatory. Then we run the same tests to confirm no behaviour was lost." |
| For the feature | "/test-driven-development start the fleet discount" |
| On the version | "Why did we update the version now, and not when the tests were added?" |
| After the release | "You did nothing about speed, even though I asked. How will I know if the new release is slower?" |
| On these notes | "NOTES.md is not two pages. Please check and correct that." |

## More times the agent got it wrong

`NOTES.md` has the three that mattered most. These are the others.

- **A status read from the wrong place, twice.** A probe printed `exit=0` under a compiler error, and later under 21 failed checks. Caught because the status contradicted the output above it.
- **An outdated action version written from memory.** The run was green with a deprecation warning. Found by reading the annotations, not only the tick.
- **A speed check that reported 0 ms.** Its first version took the fastest of seven runs, and 3 of 350 logged timings were nonsense, most likely the clock being adjusted mid-run under WSL. It now takes the median.
- **It tried to merge the feature itself** after I asked for less waiting. The permission system refused and it did not look for a way round. I merge.
- **It reported "about two pages" from a word count.** `NOTES.md` printed as three to four pages. I noticed; it then rendered the file to PDF and cut it.
- **It said CI had failed when the run was still queued.** It checked the run's real status and corrected itself.
