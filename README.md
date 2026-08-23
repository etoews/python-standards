# Python standards

Opinionated, single-path standards for building Python projects: how a project is structured, the
tooling it uses, and the conventions an agent follows while working in it. One set of standards,
shared by every project, kept in one place so nothing drifts.

Stack: uv (deps and envs), ruff (lint and format), pytest (tests), ty (type check, with mypy as the
documented fallback), stdlib logging. Python 3.14, `src/` layout, `pyproject.toml` as the single
source of truth, `uv.lock` committed.

## Contents

- [The Standards](#the-standards)
  - [The manifest](#the-manifest)
  - [Always-on](#always-on)
  - [Read on demand](#read-on-demand)
  - [Opt-in](#opt-in)
  - [MAC](#mac)
- [Use the standards in a project](#use-the-standards-in-a-project)
- [Versioning and updates](#versioning-and-updates)
- [Releases](#releases)
- [Skills](#skills)

## The Standards

### The manifest

- **[standards/manifest.md](standards/manifest.md)**: the entry point a project imports. It pulls in
  the always-on standards files, so a project subscribes to all of them through this one import, and
  names the read-on-demand and opt-in files without importing them.

### Always-on

Imported by the manifest, so they load in every project session — the conventions an agent follows
on every task. uv.md is short and imperative, the single source of truth for the uv conventions.

- [uv](standards/uv.md) — uv and environments
- [structure](standards/structure.md) — the `src/` layout
- [ruff](standards/ruff.md) — lint and format
- [pytest](standards/pytest.md) — tests
- [ty](standards/ty.md) — type check
- [docstrings](standards/docstrings.md) — Google-style docstrings
- [logging](standards/logging.md) — stdlib logging
- [error-handling](standards/error-handling.md) — exception hierarchy and boundaries
- [configuration](standards/configuration.md) — typed config and secrets

### Read on demand

Named by the manifest but not imported. Open the matching file when the task calls for it:

- **Building a project**: [pyproject](standards/pyproject.md),
  [dependencies](standards/dependencies.md), [upgrading-python](standards/upgrading-python.md).
- **Tooling and templates**: [pre-commit](standards/pre-commit.md),
  [templates](standards/templates.md) (ready-to-copy `pyproject.toml`, CI workflow, logging setup,
  CLI entry point), [quick-reference](standards/quick-reference.md).
- **CLI apps**: [cli](standards/cli.md).

### Opt-in

- **[standards/mac-launch-on-startup.md](standards/mac-launch-on-startup.md)**: not imported by the
  manifest. How to run a project at login on macOS as one always-on instance that is also the
  development instance. Followed only when the user explicitly asks for it.

### MAC

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

## Versioning and updates

The standards are released as git tags, and each project pins the submodule to one tag, so a project
adopts changes deliberately rather than having them shift underneath it.

Adopt that version in a project (this example moves it from 1.1.0 to 1.2.0):

    git -C standards/python fetch --tags
    git -C standards/python checkout 1.2.0
    git -C standards/python log --oneline 1.1.0..1.2.0    # review what changed

Then commit the updated submodule pointer. Nothing in the project's `CLAUDE.md` changes, because it
only imports the manifest.

## Releases

Each release is an annotated git tag, versioned with [Semantic Versioning](https://semver.org):
**major** when adopting it needs more than a submodule bump (a moved import, a removed standard),
**minor** when standards are added or changed compatibly, **patch** for fixes and wording. The tag
message summarises what changed.

Cut a release from `main`:

    git tag -a 1.4.0 -m "one-line summary of what changed"
    git push origin 1.4.0

Projects adopt it deliberately — see [Versioning and updates](#versioning-and-updates).

## Skills

The repo ships two [Claude Code skills](https://docs.claude.com/en/docs/claude-code/skills) under
`.claude/skills/`. Each is a folder with a `SKILL.md` and its scripts. Claude loads a skill when the
task matches its description, or you invoke it by name with `/<name>`.

- **[sync](.claude/skills/sync/SKILL.md)**: keep this repo in step across machines and confirm this
  Mac still matches [MAC.md](MAC.md). It pulls, reconciles drift, fast-forward-merges the working
  branch, pushes, and re-audits. A read-only audit script reports git state, this Mac's conformance
  to MAC.md, and doc and manifest integrity, without changing anything. Runs inside this repo.
- **[test-manifest-import-chain-from-consumer](.claude/skills/test-manifest-import-chain-from-consumer/SKILL.md)**:
  prove that a fresh Claude Code session in a project loads the standards through the chained import
  (`CLAUDE.md` → `manifest.md` → `uv.md`). It plants a random sentinel in the deepest file, probes
  with a headless `claude` session, checks the answer came from the loaded import rather than a file
  read, then reverts. Run it from a **consumer** project after adding the submodule or bumping it to
  a new tag.
