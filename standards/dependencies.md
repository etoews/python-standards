# Dependency management

The everyday `uv add` / `uv add --dev` / `uv remove` basics are in `uv.md`. This file is the fuller workflow: optional extras, upgrades, inspection, and ad-hoc scripts.

**Optional extras** (feature flags for users):
```toml
[project.optional-dependencies]
redis = ["redis>=5"]
postgres = ["psycopg[binary]>=3.2"]
```

Users install with `uv add 'myproj[redis]'` or `pip install 'myproj[redis]'`.

**Upgrade:**
```
uv lock --upgrade-package requests   # one dep
uv lock --upgrade                    # everything
uv sync                              # apply to .venv
```

Commit the `uv.lock` change in a single-purpose commit with a subject like `deps: upgrade requests to 2.33`.

**Inspect:** `uv tree`.

**Script with ad-hoc deps** (no project):
```
uv run --with httpx --with rich python script.py
```
