# Python standards roadmap

Planned changes to the standards. Each item names the standards it changes and
the project that adopts it first, so a change is proven in one project before
it becomes the rule for all of them.

## Contents

| Item | Status |
|------|--------|
| [Configuration in TOML, secrets in `.env`](#configuration-in-toml-secrets-in-env) | ⬜ Planned |
| [Lint, format, and type-check in a Claude Code hook](#lint-format-and-type-check-in-a-claude-code-hook) | ⬜ Planned |

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

---

## Lint, format, and type-check in a Claude Code hook

`ruff.md` and `ty.md` give the agent commands to run by hand after it edits
code. A step the agent must remember is a step it sometimes skips, and
`pre-commit.md` catches the miss only at commit time. Move the checks into
Claude Code hooks, so the harness runs them after every edit and the agent does
not have to remember.

- A `PostToolUse` hook on `Edit` and `Write` runs `uv run ruff check --fix` and
  `uv run ruff format` on each edited `.py` file. Findings that autofix cannot
  clear go back to the agent, so it corrects them in the same turn.
- A `Stop` hook runs `uv run ty check` and `uv run pytest` over the project. A
  failure blocks the end of the turn and returns the output to the agent, so no
  turn ends with a type error or a failed test.
- A check belongs in a hook when it is deterministic, idempotent, and fast
  enough to run every time. Ruff, ty, and pytest qualify. A step that needs
  judgement, such as a review, a doc revision, or a commit, stays with the
  agent.
- The hook scripts live in this repo, under `hooks/`. A project's
  `.claude/settings.json` points at `standards/python/hooks/`, so every project
  runs the same script and a tag bump updates them all at once.
- The hook, `pre-commit`, and CI run the same tools with the same settings. The
  hook serves the agent in the session, `pre-commit` serves a human commit, and
  CI stays the source of truth. Keep the three in step.

**Standards to revise:** `ruff.md` and `ty.md` (the hook runs the commands; the
agent runs them by hand only outside a session), `pre-commit.md` (the
three-layer model), `templates.md` (add the `.claude/settings.json` hook block),
`structure.md` (add `.claude/settings.json` to the tree), `quick-reference.md`.
Also `README.md` (an adoption step that wires the hook) and this repo's
`CLAUDE.md` (the new `hooks/` directory).

**First adopter:** `wkx-ecosystem-localhost`.
