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
  import, and names the read-on-demand and opt-in files without importing them.
- **[standards/uv.md](standards/uv.md)** and the other always-on topic files
  ([structure](standards/structure.md), [ruff](standards/ruff.md), [pytest](standards/pytest.md),
  [ty](standards/ty.md), [docstrings](standards/docstrings.md), [logging](standards/logging.md),
  [error-handling](standards/error-handling.md), [configuration](standards/configuration.md)): the
  day-to-day conventions the manifest imports. uv.md is short and imperative, the single source of
  truth for the uv conventions.
- **standards/ read-on-demand files** ([pyproject](standards/pyproject.md),
  [dependencies](standards/dependencies.md), [upgrading-python](standards/upgrading-python.md),
  [pre-commit](standards/pre-commit.md), [cli](standards/cli.md), [templates](standards/templates.md),
  [quick-reference](standards/quick-reference.md)): named by the manifest but not imported. Open the
  matching file when the task calls for it.
- **[standards/mac-launch-on-startup.md](standards/mac-launch-on-startup.md)**: opt-in, not imported
  by the manifest. How to run a project at login on macOS as one always-on instance that is also the
  development instance. Followed only when the user explicitly asks for it.
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
and no copy to drift. The manifest pulls in the always-on standards files, and names the
read-on-demand files that a task opens when it needs them. Commit the submodule and the `CLAUDE.md`
change together.

## Read on demand

The always-on standards cover day-to-day coding. A few topics are named by the manifest but not
imported; open the matching file in `standards/` before acting:

- **Building a project**: `pyproject.md`, `dependencies.md`, `upgrading-python.md`.
- **Tooling and templates**: `pre-commit.md`, `templates.md` (ready-to-copy `pyproject.toml`, CI
  workflow, logging setup, CLI entry point), `quick-reference.md`.
- **CLI apps**: `cli.md`.

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
