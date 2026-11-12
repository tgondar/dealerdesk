# Instructions for AI agents

The rules for working in this repository are in [CLAUDE.md](CLAUDE.md). They apply to every agent and tool, not only Claude Code. Read that file before changing anything.

This file exists so tools that look for `AGENTS.md` find those rules. `CLAUDE.md` is the full list and the one to trust if the two ever differ.

The three that matter most, repeated here in case your tool does not follow the link:

1. The program and the real invoices are right. Never change behaviour to match a document.
2. Run `make test` before and after a change. Never run `make record` to make a failure pass.
3. Plain C89.
