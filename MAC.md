# Python Dev Machine Setup with uv

## Context

This is the standards repo that Python projects follow. Machine-wide settings (uv config, shell guardrail, Claude permissions) live at **user-scope**, so they apply wherever `uv init` runs. Language conventions do not: they belong in each project's own `CLAUDE.md`, which imports `standards/manifest.md`, so that non-Python sessions are not made to read Python rules.

Fresh macOS (Apple Silicon) environment with no uv, no pyenv, and no Python tooling beyond whatever `python3` the machine already ships. That might be Apple's Command Line Tools stub at `/usr/bin/python3`, a python.org build at `/usr/local/bin/python3`, or a Homebrew build at `/opt/homebrew/bin/python3`. Which one it is does not matter, because nothing below touches it. Goal: stand up a modern uv-centric Python dev machine where every project is isolated in a virtual environment, with guardrails strong enough that accidentally polluting the system/user site-packages becomes an error.

Decisions:
- Install uv via Homebrew
- Default Python for new projects: 3.14 (uv-managed)
- Strong venv enforcement: `PIP_REQUIRE_VIRTUALENV=1` + uv defaults
- No globally-installed uv tools — add `ruff`/`pytest`/etc. per project via `uv add --dev`

## Setup steps

### 1. Install uv via Homebrew

```
brew install uv
```

Verify: `uv --version`. uv installs to `/opt/homebrew/bin/uv`, already on PATH via the existing `brew shellenv` line in `~/.zprofile`.

### 2. Install uv-managed Python 3.14 and pin globally

```
uv python install 3.14
uv python pin --global 3.14
```

`uv python pin --global` writes `~/.config/uv/.python-version`, making 3.14 the default for any new project without its own `.python-version`. The system `python3` is left untouched for ad-hoc use; uv-managed builds live under `~/.local/share/uv/python/`, with a `~/.local/bin/python3.14` shim, and are only used by uv workflows.

uv downloads these builds from GitHub release assets, not from PyPI. On a TLS-inspecting network this is usually the first step that fails.

### 3. Create global uv config at `~/.config/uv/uv.toml`

```toml
# Prefer uv-managed Pythons; don't silently use a random system Python
python-preference = "only-managed"

# Auto-download a pinned Python version if missing
python-downloads = "automatic"

# Compile .pyc files on install — faster first run, small disk cost
compile-bytecode = true
```

`uv pip` already refuses to install outside a venv by default (requires an explicit `--system` flag to override), so no extra config is needed for that path.

### 4. Add venv guardrail to `~/.zprofile`

Append:

```
export PIP_REQUIRE_VIRTUALENV=1
```

Makes any plain `pip install …` (any non-uv `pip` on PATH) fail with "Could not find an activated virtualenv" unless a venv is active. Paired with step 3, both code paths refuse to install globally.

### 5. Extend user-scope Claude permissions

Edit `~/.claude/settings.json` to merge a `permissions.allow` block, preserving every existing key (`model`, `effortLevel`, `voiceEnabled`, `voice`, `enabledPlugins`, `statusLine`, and so on) and every allow entry already listed:

```json
{
  "permissions": {
    "allow": [
      "Bash(uv --version)",
      "Bash(uv init:*)",
      "Bash(uv add:*)",
      "Bash(uv remove:*)",
      "Bash(uv sync:*)",
      "Bash(uv lock:*)",
      "Bash(uv run:*)",
      "Bash(uv python:*)",
      "Bash(uv tree:*)",
      "Bash(uv venv:*)",
      "Bash(uv tool list)"
    ]
  }
}
```

`uv tool install` / `uv tool uninstall` are deliberately **not** auto-allowed — they mutate global state and deserve a prompt.

### 6. Install VS Code extensions

Opinionated Python-stack extensions. Install from the terminal:

```
code --install-extension ms-python.python
code --install-extension ms-python.vscode-pylance
code --install-extension ms-python.debugpy
code --install-extension ms-python.vscode-python-envs
code --install-extension charliermarsh.ruff
code --install-extension astral-sh.ty
code --install-extension tamasfe.even-better-toml
code --install-extension ms-toolsai.jupyter
```

`astral-sh.ty` is Astral's preview type-checker extension — runs as a language server alongside Pylance.

### 7. Configure VS Code user settings

Merge into `~/Library/Application Support/Code/User/settings.json`. VS Code does not create this file until you change a setting through the UI, so on a fresh machine it will be missing; create it with these blocks wrapped in a top-level `{ … }`. A running VS Code picks the change up live, no restart needed.

```json
"[python]": {
  "editor.defaultFormatter": "charliermarsh.ruff",
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.ruff": "explicit",
    "source.organizeImports.ruff": "explicit"
  }
},
"[toml]": {
  "editor.defaultFormatter": "tamasfe.even-better-toml"
}
```

- `source.fixAll.ruff` applies ruff autofixes on save.
- `source.organizeImports.ruff` sorts and prunes imports on save (replaces isort).

## Daily recipes (reference)

### Start a new project

```
cd ~/dev/somewhere
uv init myproj          # library-style layout; use `uv init --app myproj` for a CLI/app
cd myproj
uv add requests         # runtime dep
uv add --dev ruff pytest  # dev deps
uv run pytest           # run tests
uv run python -m myproj # run the app
```

### Clone an existing uv project

```
git clone <repo> && cd <repo>
uv sync                 # materializes .venv from uv.lock
uv run <cmd>            # no manual `source .venv/bin/activate` needed
```

### Switch Python version for one project

```
uv python pin 3.13
uv sync   # rebuilds .venv against the new interpreter
```

### One-off script with inline deps (no project)

```
uv run --with httpx python - <<'PY'
import httpx
print(httpx.get("https://example.com").status_code)
PY
```

### Upgrade a dependency

```
uv lock --upgrade-package requests
uv sync
```

### Upgrade everything

```
uv lock --upgrade
uv sync
```

### Global CLI tool

```
uv tool install ruff        # puts `ruff` on PATH at ~/.local/bin/ruff
uv tool list
uv tool upgrade ruff
uv tool uninstall ruff
```

## Files created / modified

- **New**: `~/.config/uv/uv.toml`
- **New**: `/Users/etoews/dev/etoews/python-standards/MAC.md` (this file)
- **Edit**: `~/.zprofile` (append one export)
- **Edit**: `~/.claude/settings.json` (add `permissions.allow`)
- **Edit**: `~/Library/Application Support/Code/User/settings.json` (add `[python]` and `[toml]` format-on-save blocks; create the file if absent)
- **Install**: VS Code extensions listed in step 6
- **Unchanged**: the pre-existing system `python3`, `~/.claude/CLAUDE.md`, `/Users/etoews/dev/etoews/python-standards/.claude/settings.local.json`

`~/.zprofile` and `~/.claude/settings.json` may each be a symlink into a dotfiles repo. Edit the symlink target, on a branch, so the machine setup stays version-controlled. Check with `ls -la` before writing.

## Verification

Run from a fresh login shell so `~/.zprofile` is re-sourced:

1. `uv --version` — prints a version.
2. `uv python list --only-installed` — shows a uv-managed 3.14.x.
3. Venv guardrail: `pip3 install --dry-run requests`, using whichever non-uv `pip3` is on PATH, should fail with "Could not find an activated virtualenv".
4. End-to-end smoke test in a throwaway dir outside this one:
   ```
   cd /tmp && uv init demo && cd demo
   uv add requests
   uv run python -c "import requests; print(requests.__version__)"
   rm -rf /tmp/demo
   ```
   should create `demo/.venv/`, write `pyproject.toml` + `uv.lock`, print a version.
5. `uv pip install --dry-run requests` run outside any project dir, with no venv active. Should fail with "No virtual environment found; run `uv venv` …". That is uv's built-in default, not something `uv.toml` configures, which is why step 3 needs no extra setting for this path.
6. `uv init demo && cd demo`, then confirm a fresh Claude session picks up the conventions once you drop in the `CLAUDE.md` template from README.md. Nothing loads them automatically outside a project.
