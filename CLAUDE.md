# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A **standards/reference repo**, not a source code repository. Actual Python projects live in their own repositories and follow the standards written here. There is nothing to build, test, or lint here, just markdown files maintained by hand.

## Files

- **standards/manifest.md**: the entry point a project imports. It pulls in the topic standards files below, so a project subscribes to all of them through this one import. Add a standard by writing its file and importing it here.
- **standards/uv.md**: the always-on uv and environments rules. Single source of truth for the uv conventions; nothing else in the repo restates them.
- **README.md**: how the standards are used in a project and how a project adopts a new tagged release.
- **PROJECT.md**: the full per-project playbook (src layout, `pyproject.toml`, ruff, pytest, ty, docstrings, logging, error handling) plus copy-paste templates. Read on demand when bootstrapping or configuring a project.
- **MAC.md**: one-time macOS setup playbook for a Python dev machine (uv, VS Code extensions, global config, shell env var, Claude permissions). Steps are numbered and executable top-to-bottom on a fresh Mac.
- **README.local.md**: gitignored, present only on machines that need workarounds the playbook shouldn't carry. Never commit it, and never promote its contents into MAC.md.

manifest.md is the entry point that imports the always-on standards files (uv.md, and more as they are added), PROJECT.md is the full playbook, MAC.md is the machine layer. Each project imports manifest.md and reads PROJECT.md on demand.

## Editing conventions

- **MAC.md documents universal fresh-machine setup only.** Don't add one-off repairs for this specific machine's prior state (e.g., "uninstall extension X we installed years ago"). A reader on a clean Mac wouldn't need them. Perform one-offs in execution but leave them out of the doc.
- **Keep `~/.claude/CLAUDE.md` language-agnostic.** It loads into every Claude session, including non-Python ones, so nothing uv-specific goes there. The uv conventions live in `standards/uv.md`, imported through `standards/manifest.md` into each project's own `CLAUDE.md`. See README.md for how projects consume the standards.
- **For reference/playbook docs, the doc *is* the plan.** When asked to write or update MAC.md / PROJECT.md, write the final content directly to the target file — don't produce a separate meta-plan about what the doc will contain.

## Stack the docs prescribe

uv (deps/envs) · ruff (lint+format) · pytest (tests) · ty (type check, with mypy as documented fallback) · stdlib logging. Python 3.14 is the global default (uv-managed). `src/` layout, `pyproject.toml` as single source of truth, `uv.lock` committed.