# Pytest

**Directory:** `tests/` at project root, no `__init__.py`. Mirror package structure.

**Config** goes in `[tool.pytest.ini_options]`:
```toml
testpaths = ["tests"]
addopts = "-ra --strict-markers --strict-config"
```

- `-ra` — summary of all non-passing outcomes at the end
- `--strict-markers` — typos in `@pytest.mark.xxx` are errors, not silent no-ops
- `--strict-config` — same for config keys

**Naming:** `test_*.py`, `Test*` classes, `test_*` functions. Don't deviate.

**Fixtures** go in `conftest.py` at the nearest common ancestor of the tests that use them. Don't put app-wide fixtures in a single root `conftest.py` when only one subdirectory uses them.

**Parametrize, don't loop:**
```python
# Yes
@pytest.mark.parametrize("n,expected", [(1, 1), (2, 4), (3, 9)])
def test_square(n, expected):
    assert square(n) == expected

# No
def test_square():
    for n, expected in [(1, 1), (2, 4), (3, 9)]:
        assert square(n) == expected   # first failure hides the rest
```

**Structure each test as Arrange-Act-Assert**, separated by blank lines. If a test has more than one "Act," split it.

**Coverage:** `uv run pytest --cov=myproj --cov-report=term-missing`. No coverage gating in CI until the suite is mature — gating too early creates test-for-the-metric-not-for-the-bug habits.
