# Ruff (lint + format)

One tool. Replaces black, isort, flake8, pyupgrade, and most of pylint.

**Daily commands:**
```
uv run ruff check --fix      # lint with autofix
uv run ruff format           # format (black-compatible)
```

**Recommended rule selection** (goes in `[tool.ruff.lint]`):
- `E`, `F` — pycodestyle errors, pyflakes (catch real bugs)
- `I` — import sorting (replaces isort)
- `UP` — pyupgrade (modernize syntax as you bump Python version)
- `B` — flake8-bugbear (common pitfalls)
- `SIM` — flake8-simplify (redundant patterns)
- `RUF` — ruff-specific rules

**Per-file ignores** for tests:
- `S101` (assert-used): pytest uses asserts; this is correct.
- `D100`-series (missing docstrings): tests don't need them.

Config can live in `[tool.ruff]` inside `pyproject.toml` (the default) or a standalone `ruff.toml` — both starters are in `templates.md`. Pick one. Do not duplicate.

**In CI: `ruff format --check`** (fails if unformatted) and `ruff check` (no `--fix`).
