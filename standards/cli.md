# CLI (apps only)

For apps that expose a CLI, **use Typer.** It turns the type hints you already write under `ty.md` into args, options, help text, and validation — no decorator soup, no string-typed arguments.

```
uv add typer
```

**Why Typer:**
- **vs Click** — Typer *is* Click underneath, but type-hint-driven. Same maturity, less boilerplate. Drop to raw Click only when you need dynamic command construction the type system can't express.
- **vs argparse** — fine for a 30-line one-shot script. Past two subcommands and a few flags you're rebuilding what Typer gives you for free.
- **vs Fire** — too magic for shipped tools; reflection-based CLIs drift silently as the code drifts.

**Pair with `rich`** (`uv add rich`) for tables, progress bars, and styled output to *stdout*. Keep `logging` (`logging.md`) for diagnostics to *stderr*. Different channels — don't conflate them.

**Entry point** is already declared in the `pyproject.toml` template (`templates.md`):
```toml
[project.scripts]
myproj = "myproj.__main__:main"
```

Then `uv run myproj --help` works, and `uv tool install .` installs it system-wide.

See `templates.md` for the `__main__.py` template.
