# Project structure

**Use the `src/` layout.** It forces tests to import the *installed* package, which catches packaging mistakes early (missing files, wrong `package_data`, import-path bugs) — you will not discover these at `pip install` time on a user's machine if you skip this.

```
myproj/
├── pyproject.toml
├── uv.lock
├── .python-version
├── README.md
├── .gitignore
├── src/
│   └── myproj/
│       ├── __init__.py
│       ├── __main__.py        # for `python -m myproj`
│       ├── exceptions.py
│       └── _logging.py
└── tests/
    ├── conftest.py
    └── test_something.py
```

Rules:
- No top-level `__init__.py`. Nothing importable lives outside `src/`.
- `tests/` is **not** a package — no `__init__.py`. pytest discovers by path.
- Mirror package structure under `tests/` once you have >1 module.
- One package per repo. Monorepos with multiple packages are a separate pattern not covered here.

**`.gitignore`** (minimum):
```
.venv/
__pycache__/
*.pyc
.pytest_cache/
.ruff_cache/
.coverage
dist/
build/
*.egg-info/
.env
```

Which of these files to commit and which to ignore (`pyproject.toml`, `uv.lock`, `.python-version`, `.venv/`) is covered in `uv.md`.
