# Python standards

Single source of truth for how Python projects are built. Vendored into each project as a git
submodule at `standards/python/` and imported by that project's `CLAUDE.md`, so every project
follows the same standards and none of them keeps its own copy.

## Standards

@uv.md

## Opt-in standards

Not imported above, so they are never loaded by default. Follow one only when the
user explicitly asks for it.

- Run a project at login on macOS as a single always-on instance that is also the
  development instance: `mac-launch-on-startup.md`.
