# Configuration and secrets

**One typed config object, built once at the entry point, passed down explicitly.** Same discipline as logging (`logging.md`): nothing deep in the call stack reaches into `os.environ`. If a function needs a value, it takes it as a parameter.

**Use `pydantic-settings`** — typed, validated, reads environment variables and `.env` from a single class:

```
uv add pydantic-settings
```

`src/myproj/config.py`:
```python
from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Configuration from the environment and .env.

    Built once at the entry point; pass the instance (or its values)
    down explicitly. Never re-read the environment deeper in the stack.
    """

    model_config = SettingsConfigDict(
        env_prefix="MYPROJ_",
        env_file=".env",
        extra="forbid",
    )

    database_url: str                 # required — no default
    api_key: SecretStr                # masked in logs and reprs
    log_level: str = "INFO"
    request_timeout_s: float = 5.0
```

Build it at the entry point, alongside `configure()` from `logging.md`:
```python
# in main(), src/myproj/__main__.py
settings = Settings()   # reads env + .env, validates, fails fast
```

Rules:
- **Required fields have no default.** Missing config fails at startup, not at first use.
- **`extra="forbid"`** so a typo'd `MYPROJ_DATABSE_URL` is an error, not a silently ignored no-op.
- **`SecretStr` for every secret.** Its `repr`/`str`/log output is `**********`; call `.get_secret_value()` only at the point of use. This is what makes "never log tokens" (`logging.md`) hold by default.
- **`env_prefix`** namespaces your variables so they don't collide with unrelated environment.
- **Precedence**, highest first: arguments passed to `Settings(...)` → environment variables → `.env` → field defaults.

**Secrets and `.env`:**
- **`.env` is never committed** — it's in `.gitignore` (`structure.md`).
- **Commit `.env.example`** with every key present and placeholder values. It's the documented contract for what the app needs to run.
- **In production, secrets come from the host's secret store** (env vars the platform injects), not a `.env` file. `.env` is a local-dev convenience only.
