# Quick reference

| Command | Purpose |
|---|---|
| `uv init --app myproj` | New application project |
| `uv init myproj` | New library project |
| `uv add <pkg>` | Add runtime dep |
| `uv add --dev <pkg>` | Add dev dep |
| `uv remove <pkg>` | Remove dep |
| `uv sync` | Install locked deps into `.venv` |
| `uv sync --locked` | Same, but fail if lockfile is stale (CI) |
| `uv lock --upgrade` | Bump all deps |
| `uv lock --upgrade-package <pkg>` | Bump one |
| `uv run <cmd>` | Run command inside project venv |
| `uv run python -m myproj` | Run the app module |
| `uv run pytest` | Tests |
| `uv run ruff check --fix` | Lint + autofix |
| `uv run ruff format` | Format |
| `uv run ty check` | Type check |
| `uv tree` | Show dep graph |
| `uv python pin 3.X` | Pin project Python version |

See MAC.md for one-time machine setup.
