# Python standards

Opinionated, single-path standards for building Python projects: how a project is structured, the
tooling it uses, and the conventions an agent follows while working in it. One set of standards,
shared by every project, kept in one place so nothing drifts.

Stack: uv (deps and envs), ruff (lint and format), pytest (tests), ty (type check, with mypy as the
documented fallback), stdlib logging. Python 3.14, `src/` layout, `pyproject.toml` as the single
source of truth, `uv.lock` committed.

## What's in here

- **[standards/manifest.md](standards/manifest.md)**: the entry point a project imports. It pulls in
  the always-on standards files below, so a project subscribes to all of them through this one
  import.
- **[standards/uv.md](standards/uv.md)**: the always-on uv and environments rules. Short and
  imperative, the single source of truth for the uv conventions.
- **[standards/mac-launch-on-startup.md](standards/mac-launch-on-startup.md)**: opt-in, not imported
  by the manifest. How to run a project at login on macOS as one always-on instance that is also the
  development instance. Followed only when the user explicitly asks for it.
- **[PROJECT.md](PROJECT.md)**: the full playbook: project structure, `pyproject.toml`, ruff,
  pytest, ty, docstrings, logging, CLI, error handling, config and secrets, pre-commit, upgrading
  Python, and copy-paste templates. Read the relevant section when the task calls for it.
- **[MAC.md](MAC.md)**: one-time setup for a Python dev machine: installing uv, global config, the
  virtual-env guardrail, and VS Code extensions. Run once per machine, independent of any project.

## Use the standards in a project

Vendor this repo once as a git submodule at `standards/python/`:

    git submodule add https://github.com/etoews/python-standards.git standards/python

Then the project's own `CLAUDE.md` imports the manifest and adds nothing but project-specific notes:

    # Python standards

    @standards/python/standards/manifest.md

    # project-specific guidance below

The import means the standards are never pasted into the project, so there is one source of truth
and no copy to drift. The manifest pulls in the always-on standards files (uv and environments
today), and PROJECT.md holds everything read on demand. Commit the submodule and the `CLAUDE.md`
change together.

## The full playbook

The always-on standards are only the essentials. For anything past day-to-day work, open the
matching part of PROJECT.md before acting:

- **Building a project**: structure, `pyproject.toml`, dependency management, upgrading Python.
- **Quality tooling**: ruff, pytest, ty, pre-commit, docstrings.
- **Writing the code**: logging, error handling, configuration and secrets, CLI apps.
- **Templates**: ready-to-copy `pyproject.toml`, CI workflow, logging setup, and CLI entry point.

One-time machine setup is separate, in MAC.md.

## Versioning and updates

The standards are released as git tags, and each project pins the submodule to one tag, so a project
adopts changes deliberately rather than having them shift underneath it.

Release a new version from this repo:

    git tag 1.2.0 && git push origin main --tags

Adopt that version in a project (this example moves it from 1.1.0 to 1.2.0):

    git -C standards/python fetch --tags
    git -C standards/python checkout 1.2.0
    git -C standards/python log --oneline 1.1.0..1.2.0    # review what changed

Then commit the updated submodule pointer. Nothing in the project's `CLAUDE.md` changes, because it
only imports the manifest.
