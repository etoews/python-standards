# Templates

Copy-paste-ready. Rename `myproj` to your project name throughout.

## `pyproject.toml` (full starter)

```toml
[project]
name = "myproj"
version = "0.1.0"
description = "One line."
readme = "README.md"
requires-python = ">=3.14"
authors = [{ name = "Your Name", email = "you@example.com" }]
license = { text = "MIT" }
dependencies = [
    # runtime deps here, e.g.:
    # "httpx>=0.28",
]

[project.scripts]
myproj = "myproj.__main__:main"

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.hatch.build.targets.wheel]
packages = ["src/myproj"]

[dependency-groups]
dev = [
    "pytest>=8",
    "pytest-cov>=5",
    "ruff>=0.8",
    "ty>=0.0.1",
]

[tool.ruff]
line-length = 100
target-version = "py314"

[tool.ruff.lint]
select = ["E", "F", "I", "UP", "B", "SIM", "RUF"]
ignore = []

[tool.ruff.lint.per-file-ignores]
"tests/**" = ["S101", "D"]

[tool.ruff.format]
quote-style = "double"

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-ra --strict-markers --strict-config"
filterwarnings = ["error"]  # treat warnings as errors in tests

[tool.ty.src]
include = ["src"]
```

## Standalone `ruff.toml` (alternative to `[tool.ruff]` in pyproject.toml — pick one, not both)

```toml
line-length = 100
target-version = "py314"

[lint]
select = ["E", "F", "I", "UP", "B", "SIM", "RUF"]
ignore = []

[lint.per-file-ignores]
"tests/**" = ["S101", "D"]

[format]
quote-style = "double"
```

## `.github/workflows/ci.yml`

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install uv
        uses: astral-sh/setup-uv@v5
        with:
          enable-cache: true

      - name: Set up Python
        run: uv python install

      - name: Install dependencies
        run: uv sync --locked

      - name: Ruff — lint
        run: uv run ruff check

      - name: Ruff — format check
        run: uv run ruff format --check

      - name: ty — type check
        run: uv run ty check

      - name: pytest
        run: uv run pytest --cov=myproj --cov-report=term-missing
```

Pin `astral-sh/setup-uv` to the current major tag; bump intentionally.

## `src/myproj/_logging.py`

```python
"""Logging setup. Call configure() once from the app entry point."""
from __future__ import annotations

import json
import logging
import os
import sys
from datetime import datetime, timezone


class _JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        payload = {
            "ts": datetime.fromtimestamp(record.created, tz=timezone.utc).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "msg": record.getMessage(),
        }
        if record.exc_info:
            payload["exc"] = self.formatException(record.exc_info)
        return json.dumps(payload)


def configure() -> None:
    """Configure root logging based on env vars.

    LOG_FORMAT=json      -> machine-readable JSON on stdout
    LOG_FORMAT=<other>   -> human-readable dev format (default)
    LOG_LEVEL=<level>    -> logging level name (default INFO)
    """
    level = os.environ.get("LOG_LEVEL", "INFO").upper()
    fmt = os.environ.get("LOG_FORMAT", "dev").lower()

    handler = logging.StreamHandler(sys.stdout)
    if fmt == "json":
        handler.setFormatter(_JsonFormatter())
    else:
        handler.setFormatter(
            logging.Formatter(
                "%(asctime)s %(levelname)-8s %(name)s: %(message)s",
                datefmt="%Y-%m-%d %H:%M:%S",
            )
        )

    root = logging.getLogger()
    root.handlers.clear()
    root.addHandler(handler)
    root.setLevel(level)
```

Call `configure()` from `src/myproj/__main__.py` (or your CLI entry point) — never from library code.

## `src/myproj/__main__.py` (Typer CLI entry point)

```python
"""CLI entry point. Run with `uv run myproj` or `python -m myproj`."""
from __future__ import annotations

from pathlib import Path
from typing import Annotated

import typer

from myproj._logging import configure as configure_logging

app = typer.Typer(
    help="One-line description of myproj.",
    no_args_is_help=True,
    add_completion=False,  # enable once you publish, if you want shell completion
)


@app.callback()
def _root() -> None:
    """Configure logging before any subcommand runs."""
    configure_logging()


@app.command()
def greet(
    name: Annotated[str, typer.Argument(help="Person to greet.")],
    loud: Annotated[bool, typer.Option(help="SHOUT the greeting.")] = False,
) -> None:
    """Greet someone."""
    msg = f"Hello, {name}!"
    typer.echo(msg.upper() if loud else msg)


@app.command()
def process(
    path: Annotated[Path, typer.Argument(exists=True, dir_okay=False, readable=True)],
) -> None:
    """Process a file."""
    typer.echo(f"Processing {path}")


def main() -> None:
    """Console-script entry point referenced from pyproject.toml."""
    app()


if __name__ == "__main__":
    main()
```

Notes:
- `Annotated[...]` is the modern Typer style (≥0.9). The legacy default-value form (`name: str = typer.Argument(...)`) still works but is on its way out.
- `no_args_is_help=True` shows help instead of failing silently when invoked bare.
- `@app.callback()` runs before any subcommand — the place to wire up logging, load config, etc.
- `typer.echo` over `print` — handles encoding and pager redirection.
