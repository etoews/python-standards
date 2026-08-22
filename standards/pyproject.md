# pyproject.toml

Single source of truth for metadata, build, dependencies, and tool config. See the full template in `templates.md`.

**Sections:**
- `[project]` — name, version, `requires-python`, `dependencies`, authors, description, license
- `[build-system]` — `hatchling` (uv init's default; fine for 99% of projects)
- `[dependency-groups]` — dev deps go here (PEP 735). `uv add --dev foo` writes to `dependency-groups.dev`.
- `[project.optional-dependencies]` — user-facing extras (`pip install myproj[redis]`). Different from dev groups.
- `[tool.ruff]`, `[tool.pytest.ini_options]`, `[tool.ty]` — tool config

**Dependency pinning:**
- **Lower bound only** in `pyproject.toml`: `requests>=2.32`.
- Upper bound is `uv.lock`'s job. Don't write `==` pins in `pyproject.toml` — it breaks downstream consumers.
- Exception: pin exactly when a known incompatibility exists; add a one-line comment with the reason.

**Versioning:** Start at `0.1.0`. Bump per semver when you publish. For unpublished internal tools, `0.0.1` forever is fine.
