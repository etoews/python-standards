# Error handling

**Raise specific exceptions.** `raise Exception(...)` is unfilterable — every caller has to either catch everything or nothing.

**Define a project exception hierarchy** in `src/myproj/exceptions.py`:
```python
class MyProjError(Exception):
    """Base class for all myproj exceptions."""

class ConfigError(MyProjError):
    """Raised when required configuration is missing or invalid."""

class BackendTimeout(MyProjError):
    """Raised when an external backend doesn't respond in time."""
```

Callers catch `MyProjError` for "anything from us" or specific subclasses for targeted handling.

**Catch at boundaries, not in the middle.** Translate third-party exceptions at the seam where your code meets the external lib:
```python
def fetch_user(user_id: str) -> User:
    try:
        resp = httpx.get(f"{BASE}/users/{user_id}", timeout=5)
        resp.raise_for_status()
    except httpx.TimeoutException as e:
        raise BackendTimeout(f"users endpoint timed out for {user_id}") from e
    except httpx.HTTPStatusError as e:
        raise BackendError(f"users endpoint: {e.response.status_code}") from e
    return User.model_validate(resp.json())
```

Downstream code catches `MyProjError` subclasses, not `httpx.*`. The `from e` preserves the original traceback chain for debugging.

**`except ... pass` is a bug.** If you truly mean to swallow, leave a one-line comment with the reason:
```python
try:
    shutil.rmtree(tmpdir)
except FileNotFoundError:
    pass  # already cleaned up by caller; safe to ignore
```

Never bare `except:` — always `except Exception:` at minimum (so KeyboardInterrupt can still kill the process).
