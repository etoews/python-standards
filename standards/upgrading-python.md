# Upgrading Python

Bump a project to a newer Python version when the global default moves up, when you need new syntax or stdlib features, or when the current pin nears end-of-life. One project at a time, one commit.

**Steps:**

1. **Pick the target version.** See what's already on disk: `uv python list --only-installed`. If you need a newer interpreter: `uv python install 3.X` (uv downloads and caches it; nothing global is touched).

2. **Pin the project:** `uv python pin 3.X`. Rewrites `.python-version`.

3. **Update `pyproject.toml`:**
   - `requires-python = ">=3.X"` under `[project]`.
   - `target-version = "py3X"` under `[tool.ruff]` — without this, ruff keeps applying the *old* version's rules and the `UP` fixes in step 5 won't fire.
   - `[tool.ty]` needs no change; ty reads `requires-python`.

4. **Rebuild the venv:** `rm -rf .venv && uv sync`. Recreating from scratch is faster than debugging a half-migrated environment, and the lockfile is what's authoritative anyway.

5. **Modernize syntax:** `uv run ruff check --select UP --fix`. Rewrites `Optional[X]` → `X | None`, `List[X]` → `list[X]`, `typing.Dict` → `dict`, `Union[A, B]` → `A | B`, and similar. Review the diff before staging — `UP` is mechanical but occasionally touches code you'd want to look at.

6. **Run every check.** Anything that broke at the language level surfaces here:
   ```
   uv run ruff check
   uv run ruff format --check
   uv run ty check
   uv run pytest
   ```

7. **Update CI** if your workflow pins a Python version explicitly. The CI template (`templates.md`) uses `uv python install` (no explicit version), which honours `.python-version` automatically — nothing to edit there.

8. **Commit as a single-purpose change.** Subject like `python: upgrade to 3.X`. Bundle `.python-version`, `pyproject.toml`, `uv.lock`, and any source/test edits ruff made. Keep unrelated work out — a Python bump should be reviewable in isolation and revertable in one click.

**Library projects:** raising `requires-python` drops support for users on older versions. Be deliberate; mention the bump in the changelog. Apps can move freely.

**Skipping multiple versions** (e.g. 3.11 → 3.14) is fine, but expect more cleanup in step 5 and more deprecations in step 6. Don't try to land it alongside a feature branch — give it its own PR.
