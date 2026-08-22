# Python standards

Single source of truth for how Python projects are built. Vendored into each project as a git
submodule at `standards/python/` and imported by that project's `CLAUDE.md`, so every project
follows the same standards and none of them keeps its own copy.

## Standards

The always-on standards, imported here so every project subscribes to all of them through this one
import. Short and imperative; the conventions an agent follows on every task.

@uv.md
@structure.md
@ruff.md
@pytest.md
@ty.md
@docstrings.md
@logging.md
@error-handling.md
@configuration.md

## Read on demand

Named but not imported, so they do not load by default. Open the matching file when the task calls
for it — bootstrapping or configuring a project, wiring CI, or reaching for a template.

- `pyproject.md` — `pyproject.toml` layout, sections, dependency pinning, versioning.
- `dependencies.md` — the fuller dependency workflow: extras, upgrades, inspection, ad-hoc scripts.
- `upgrading-python.md` — bump a project to a newer Python version, one commit at a time.
- `pre-commit.md` — the local pre-commit hook gate that runs ruff and ty before each commit.
- `cli.md` — CLI apps with Typer (apps only).
- `templates.md` — copy-paste `pyproject.toml`, `ruff.toml`, CI workflow, `_logging.py`, CLI entry point.
- `quick-reference.md` — the command cheat-sheet.

## Opt-in standards

Not imported above, so they are never loaded by default. Follow one only when the
user explicitly asks for it.

- Run a project at login on macOS as a single always-on instance that is also the
  development instance: `mac-launch-on-startup.md`.
