# uv and environments

- All Python work uses uv. Never run bare `pip install`, it will fail anyway (`PIP_REQUIRE_VIRTUALENV=1`).
- Start projects with `uv init <name>` (library) or `uv init --app <name>` (app).
- Add deps with `uv add <pkg>` / `uv add --dev <pkg>`. Remove with `uv remove <pkg>`.
- Run code with `uv run <cmd>` (auto-activates `.venv`). Scripts: `uv run python script.py`.
- After pulling: `uv sync`.
- Per-project Python version: `uv python pin 3.X` (writes `.python-version`). Global default is 3.14.
- Commit: `pyproject.toml`, `uv.lock`, `.python-version`. Gitignore: `.venv/`.
- For global CLI tools (ruff, pre-commit, etc.), use `uv tool install <pkg>`, not `pip install --user`.
