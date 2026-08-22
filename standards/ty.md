# ty (type check)

```
uv add --dev ty
uv run ty check
```

**All projects are typed.** Every function and method gets a full signature — parameters and return type — in both `src/` and `tests/`. No exceptions for "private" helpers, no "add them later". `ty check` runs clean on every commit; CI fails on type errors.

- Return `-> None` is explicit, not optional.
- Class attributes get annotations (`name: str`), not just `__init__` parameters.
- Tests count: `def test_foo() -> None:`.

**Modern syntax only** (Python 3.14+):
```python
# Yes
def fetch(ids: list[int]) -> dict[str, Item] | None: ...

# No — legacy
from typing import List, Dict, Optional
def fetch(ids: List[int]) -> Optional[Dict[str, Item]]: ...
```

`list[int]`, `dict[str, X]`, `X | None` work without imports on 3.9+ for annotations and 3.10+ for runtime. On 3.14 everything works everywhere.

**ty fallback:** if `ty check` can't handle something your project legitimately needs (rare but happens with complex Protocols, PEP 695 generics edge cases, or plugin-heavy frameworks), swap ty for mypy on *that* project: `uv remove ty && uv add --dev mypy`, replace `[tool.ty]` with `[tool.mypy]`, and note the swap in the README. Not a defeat; a documented escape hatch.

**Don't use `# type: ignore` without a specific rule:** `# type: ignore[arg-type]`, not bare `# type: ignore`. Bare ignores hide new errors forever.
