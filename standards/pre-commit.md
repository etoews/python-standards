# Pre-commit hooks

A local gate that runs ruff and ty before each commit, so CI (`templates.md`) rarely fails on something a hook would have caught. `pre-commit` is installed as a global tool (see MAC.md), not a project dependency.

**Wire it up** (once per clone):
```
pre-commit install            # install the git hook
pre-commit run --all-files    # run against the whole repo the first time
```

`.pre-commit-config.yaml`:
```yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.8.0          # keep in sync with the ruff version in pyproject.toml
    hooks:
      - id: ruff-check
        args: [--fix]
      - id: ruff-format

  - repo: local
    hooks:
      - id: ty
        name: ty
        entry: uv run ty check
        language: system
        types: [python]
        pass_filenames: false

  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v5.0.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-toml
      - id: check-added-large-files
      - id: check-merge-conflict
```

Rules:
- **Pin every `rev:` and bump deliberately** — same stance as deps (`pyproject.md`) and the pinned `setup-uv` in CI (`templates.md`). `pre-commit autoupdate` bumps them all at once; review the diff.
- **Keep the `ruff-pre-commit` rev in sync with the `ruff` dev dependency** so the hook and CI apply identical rules. A mismatch means "passes locally, fails in CI."
- **ty runs as a `local` system hook** (`uv run ty check`), not a mirrored repo, because it must execute in your project venv where your deps and their type information live. `pass_filenames: false` because ty checks the whole project, not just the staged files.
- **The hook is a fast gate, not the enforcer.** It can be skipped (`git commit -n`), so CI (`templates.md`) stays the source of truth. Run the same tools in both and don't let them drift.
