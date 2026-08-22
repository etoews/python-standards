# Docstrings

**Google style.** Concise, well-supported by ruff, ty, IDEs, and Sphinx if you ever add docs.

**What to document:**
- Every public module, class, function, method.
- Private helpers: only when the *why* isn't obvious from the code.

**Document intent, not mechanics.** A docstring that reads "Returns the user's name" for `def get_user_name() -> str` is noise. Document:
- Preconditions the caller must meet
- What "empty" or "missing" means for this function
- Exceptions raised and when
- Non-obvious side effects

**Template:**
```python
def charge_card(amount_cents: int, card: Card) -> ChargeResult:
    """Charge a card, retrying once on transient network errors.

    Idempotency is the caller's responsibility — pass a unique
    idempotency_key on the card if you want this to be safe to retry.

    Args:
        amount_cents: Amount in the card's currency. Must be positive.
        card: Tokenized card object from the payments SDK.

    Returns:
        ChargeResult with status and provider reference.

    Raises:
        ConfigError: If the payments SDK is not configured.
        BackendTimeout: If the provider times out after the single retry.
    """
```

One-line docstrings are fine for obvious functions: `"""Return the config directory path."""`.
