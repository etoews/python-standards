---
name: test-manifest-import-chain-from-consumer
description: End-to-end test, run from a project that vendors python-standards as a submodule, that a fresh Claude Code session really loads the standards through the chained import (the project's CLAUDE.md imports standards/python/standards/manifest.md, which imports uv.md). Use after adding the submodule, after bumping it to a new tag, or whenever you need to confirm the manifest import chain still resolves into a real session and has not silently broken. It plants a random sentinel, probes with a headless `claude -p`, checks the answer came from loaded context, and reverts.
---

# Test the manifest import chain from a consumer

This skill lives in python-standards but runs from a **consumer**: a project that
vendors python-standards as a git submodule at `standards/python/` and imports
the manifest from its own `CLAUDE.md`.

## What it proves, and why the obvious test fails

The chain is:

    <consumer>/CLAUDE.md  ->  @standards/python/standards/manifest.md  ->  @uv.md

Asking a fresh session "what are my uv rules?" is not a valid test: a model can
recite uv and pip best practices from training whether or not the import loaded,
a false positive. The only trustworthy probe is content the model could not know
unless the file genuinely reached its context. So the test plants a random
**sentinel** token in the deepest file in the chain (`uv.md`), starts a fresh
headless `claude`, and asks it to echo the token without reading any files. A
correct answer with `num_turns == 1` proves the sentinel arrived through the
loaded import chain rather than a file read.

## Run it

From the consumer repo, run the script. It locates the submodule and the
consumer root itself, so the working directory does not matter:

    standards/python/.claude/skills/test-manifest-import-chain-from-consumer/scripts/run.sh

It is self-contained and cleans up after itself: the planted sentinel is
reverted on exit, pass or fail.

## Reading the result

- **PASS** (exit 0): a fresh session echoed the sentinel from loaded context. The
  full chain resolves end to end.
- **FAIL** (exit 1): the sentinel did not surface, the chain is not loading.
  Check, in the consumer, that `CLAUDE.md` has the
  `@standards/python/standards/manifest.md` import line, that the submodule is
  checked out at a `1.1.0` or later tag, and that `standards/manifest.md`
  imports `@uv.md`.
- **INCONCLUSIVE** (exit 1): the sentinel came back but the model used more than
  one turn, so it may have read the file instead of loading it from context.
  Re-run.
- **Precondition failure** (exit 2): no submodule, no `claude` CLI, missing
  `uv.md`, or a `CLAUDE.md` that does not import the manifest. The message names
  what to fix.

## When to run

- Right after `git submodule add` wiring, to confirm the import took.
- After bumping the submodule to a new tag, the case where a chain can silently
  break.

This is the consumer half of a two-layer check. The `sync` audit inside
python-standards statically validates the bundle's `@import` graph before a tag
is cut; this skill proves a real consumer session actually loads it.
