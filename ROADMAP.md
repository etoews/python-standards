# Python standards roadmap

Planned changes to the standards. Each item names the standards it changes and
the project that adopts it first, so a change is proven in one project before
it becomes the rule for all of them.

## Contents

| Item | Status |
|------|--------|
| [Configuration in TOML, secrets in `.env`](#configuration-in-toml-secrets-in-env) | ⬜ Planned |

---

## Configuration in TOML, secrets in `.env`

`configuration.md` puts every setting in `.env`. That mixes two kinds of value
with different rules: configuration, which is safe to show and to discuss, and
secrets, which are not. Split them by file.

- `.env` holds secrets and sensitive values only, each typed `SecretStr`. It
  stays gitignored, and `.env.example` documents each secret with a placeholder.
- A TOML file holds configuration: paths, ports, lists, and nested settings.
  Name it `<project>.toml` and gitignore it. Commit `<project>.example.toml`
  with every key present, commented out, and documented.
- `pydantic-settings` reads both through one `Settings` class with
  `TomlConfigSettingsSource`. The precedence, highest first, is arguments passed
  to `Settings(...)` → environment variables → `.env` → TOML → field defaults.
- Paths in configuration accept `~`, expanded by a validator, so the committed
  example holds no machine-specific path.
- `extra="forbid"` rejects an unknown key in the TOML and in `.env`. A startup
  check also rejects an unknown prefixed variable in the environment, which
  `pydantic-settings` ignores on its own.

**Standards to revise:** `configuration.md`, `templates.md` (add the example
TOML and the two-source `Settings`), `structure.md` (gitignore the TOML),
`quick-reference.md`.

**First adopter:** `wkx-ecosystem-localhost`, milestone M10 "Configurable
board". Its README documents the split until this standard changes.
