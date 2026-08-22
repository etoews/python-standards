# Logging

**stdlib `logging`. Never `print()`** in library or application code (CLIs output to stdout directly; that's not the same thing).

**Module-level logger:**
```python
import logging
logger = logging.getLogger(__name__)
```

Never `logging.getLogger()` (that's the root logger — configuring it affects every library).

**Libraries do not configure logging.** Add `logging.getLogger("myproj").addHandler(logging.NullHandler())` in `src/myproj/__init__.py` and stop there. Let the application configure.

**Applications configure once** at the entry point — see the `_logging.py` template in `templates.md`.

**Use `%` formatting for lazy eval:**
```python
# Yes — %s interpolation only happens if DEBUG is enabled
logger.debug("fetched %s items in %.2fs", len(items), elapsed)

# No — f-string formats even when the message is filtered out
logger.debug(f"fetched {len(items)} items in {elapsed:.2f}s")
```

**`logger.exception` inside `except`** — captures the traceback. `logger.error("...", exc_info=True)` works too.

**Never log:** passwords, tokens, full request/response bodies, PII. Log identifiers (user_id, request_id), not contents.
