# Launch at login on macOS, still developable

How to run a Python app at login on macOS as a single always-on instance that is
also the development instance. A code change to the running app is picked up
without a manual restart.

## When to apply

Apply this standard only when the user explicitly asks to run a project at login,
or as an always-on local service, on macOS. It is opt-in. It is not part of the
always-on standards and nothing here applies by default. Linux is out of scope,
see "Not covered".

## The pattern

Run one instance through a macOS launchd LaunchAgent, and run it in reload mode.
Because the reloader watches the package source, the single login-launched
instance is also the development instance. Edit the source and that instance
restarts and serves the new code. Static assets are live on a browser refresh.

One instance meets both goals, so no second development server is needed. The
alternative, a plain always-on instance plus a separate reload instance on
another port, is rejected because a code change then shows only in the second
instance, not in the login-launched one.

Accept and document one trade-off: a save with a syntax error or a bad import
takes the app down until it is fixed, because the reloader will not serve broken
code. This is intended behaviour on a single-user development machine, where the
always-on instance is deliberately the development instance. Do not use this
pattern for a shared or production host.

## The app must provide

Reload mode needs three things from the app. Build them once, they are useful on
their own.

- A zero-argument application factory reachable by import string, for example
  `myproj.app:create_app_from_env`, that reads its configuration from the
  environment. The reloader re-imports this factory in a subprocess on each
  change, so it must build the app with no arguments.
- A run mode that starts the framework reloader watching the package source. With
  uvicorn this is `uvicorn.run(factory_import_string, factory=True, reload=True,
  reload_dirs=[package_dir])`. Expose it behind a `--reload` option on the run
  command, documented as development only.
- Logging configured inside the factory. The reloader runs the app in a fresh
  subprocess, so configure logging there too, otherwise the worker logs through
  `logging.lastResort` instead of the project format.

Configuration is re-read on each restart, because the factory rebuilds the
settings object. A dependency change or a bare environment change with no watched
source touched is not picked up, and needs a restart of the agent.

## Package it machine-neutral

The LaunchAgent plist holds absolute, machine-specific paths (the interpreter,
the working directory, the log file). Treat it exactly as `.env` is treated in
the project playbook: never commit the filled-in file to a machine-neutral repo.

- Commit a plist template with placeholder tokens, and an installer that fills it
  in on the target machine.
- The installer writes the rendered plist to `~/Library/LaunchAgents`, outside the
  repository, and loads it.
- The rendered plist is never committed. The template and the installer are the
  committed contract, the same way `.env.example` is committed and `.env` is not.

## The installer

Write the installer as a standard project script, following the project playbook.

- Stdlib only, under `scripts/`, run with `uv run scripts/install_launch_on_startup.py`.
- Resolve each value from the command line, then an environment variable, then a
  computed default (port, label, login shell, log path, and the `uv` path from
  `shutil.which`).
- Render with `string.Template` and `${NAME}` tokens. `substitute` raises on a
  placeholder the caller does not supply, so a typo fails loudly instead of
  writing a broken plist. Do not hand-roll token replacement.
- Offer `--dry-run` to print the rendered plist without writing or loading it.
- Make the load idempotent. `launchctl bootout` is asynchronous, so wait for the
  old service to unload before `launchctl bootstrap` loads the same label again,
  otherwise bootstrap races the teardown and fails with error 5. Retry bootstrap
  a few times.
- Validate the rendered plist with `plutil -lint`, then poll the app's health
  endpoint so the installer confirms the app answered.
- Keep the render step a pure function and cover it with a focused test, including
  the failure on an unfilled placeholder.

## The LaunchAgent

- Run the agent through a login shell, `/bin/zsh -lc`, so the app sees the real
  PATH. Collectors and tools that shell out to git, gh, brew, docker, uv, or node
  need it, and the launchd default agent PATH is minimal.
- Keep PATH set-up in `~/.zprofile`. A login, non-interactive shell reads
  `~/.zprofile` but not `~/.zshrc`, so PATH that lives only in `~/.zshrc` is
  absent when the agent starts and tools look missing. Homebrew's `shellenv` is
  already in `~/.zprofile` on a machine set up per MAC.md.
- Use an absolute `uv` path in the command, because PATH set-up runs inside the
  login shell and the command should not depend on its own resolution order.
- Set `RunAtLoad` and `KeepAlive` so the agent starts at login and restarts if it
  exits.

Manage the agent (replace the label with the one the installer used):

    # status
    launchctl print gui/$(id -u)/dev.$(id -un).myproj
    # restart, for example after a dependency change
    launchctl kickstart -k gui/$(id -u)/dev.$(id -un).myproj
    # stop and remove
    launchctl bootout gui/$(id -u)/dev.$(id -un).myproj

## Templates

Copy-paste ready. Rename `myproj` throughout, and set the reload command to your
app's run command.

### `scripts/myproj.plist.template`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!--
  LaunchAgent template. The placeholder tokens are filled in on the machine that
  runs scripts/install_launch_on_startup.py. The rendered plist holds real,
  machine-specific paths, so the script writes it to ~/Library/LaunchAgents and
  it is never committed.
-->
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${LABEL}</string>
    <key>ProgramArguments</key>
    <array>
        <string>${SHELL}</string>
        <string>-lc</string>
        <string>exec ${UV_BIN} run myproj serve --reload --port ${PORT}</string>
    </array>
    <key>WorkingDirectory</key>
    <string>${WORKING_DIR}</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>${LOG_PATH}</string>
    <key>StandardErrorPath</key>
    <string>${LOG_PATH}</string>
</dict>
</plist>
```

### `scripts/install_launch_on_startup.py`

```python
#!/usr/bin/env python3
"""Install a macOS launchd LaunchAgent that runs the app at login with reload.

The one always-on instance is also the development instance: a change to the
package source restarts it and the new code is served. The installer fills the
committed plist template with values found on this machine, writes the result to
~/Library/LaunchAgents (outside the repository), validates it, and loads it.

Run it with: uv run scripts/install_launch_on_startup.py
Each option falls back to an environment variable, then to a computed default.
"""

from __future__ import annotations

import argparse
import contextlib
import getpass
import os
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path
from string import Template

REPO_ROOT = Path(__file__).resolve().parent.parent
TEMPLATE = REPO_ROOT / "scripts" / "myproj.plist.template"


def render_plist(template: str, values: dict[str, str]) -> str:
    """Return the template with every ``${TOKEN}`` replaced from ``values``.

    Raise ``ValueError`` if the template names a placeholder that ``values`` does
    not supply, so a missing or misspelled key fails loudly.
    """
    try:
        return Template(template).substitute(values)
    except KeyError as missing:
        raise ValueError(f"template placeholder {missing} has no value") from missing


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    """Parse the command line. Each option documents its env fallback."""
    parser = argparse.ArgumentParser(
        description="Install the launchd LaunchAgent that runs the app at login.",
    )
    parser.add_argument("--port", help="Loopback port to bind (env PORT; default 8000).")
    parser.add_argument("--label", help="LaunchAgent label (env LABEL).")
    parser.add_argument("--shell", help="Login shell (env SHELL_BIN; default /bin/zsh).")
    parser.add_argument("--uv", help="Path to uv (env UV_BIN; default: found on PATH).")
    parser.add_argument("--log", help="Combined stdout/stderr log path (env LOG_PATH).")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the rendered plist and exit; do not write or load it.",
    )
    return parser.parse_args(argv)


def _pick(cli_value: str | None, env_name: str, default: str) -> str:
    """Resolve a value from the CLI, then the environment, then a default."""
    if cli_value is not None:
        return cli_value
    return os.environ.get(env_name) or default


def _launchctl(*args: str) -> subprocess.CompletedProcess[str]:
    """Run a launchctl subcommand, capturing output and never raising."""
    return subprocess.run(["launchctl", *args], capture_output=True, text=True, check=False)


def _loaded(service: str) -> bool:
    """Return whether launchd currently knows the service."""
    return _launchctl("print", service).returncode == 0


def _reload(domain: str, service: str, plist_path: Path) -> None:
    """Boot the old instance out, wait for it, then bootstrap the new plist.

    bootout is asynchronous, so bootstrapping the same label straight away races
    the teardown and fails with error 5. Wait for the unload, then retry.
    """
    _launchctl("bootout", service)
    for _ in range(20):
        if not _loaded(service):
            break
        time.sleep(0.5)

    for attempt in range(1, 4):
        result = _launchctl("bootstrap", domain, str(plist_path))
        if result.returncode == 0:
            return
        if attempt == 3:
            sys.exit(f"error: launchctl bootstrap failed for {service}: {result.stderr.strip()}")
        time.sleep(1)


def _wait_for_health(url: str, timeout: int = 30) -> bool:
    """Poll the health endpoint until it answers 200 or the timeout passes."""
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        with (
            contextlib.suppress(urllib.error.URLError, OSError),
            urllib.request.urlopen(url, timeout=2) as response,
        ):
            if response.status == 200:
                return True
        time.sleep(1)
    return False


def main(argv: list[str] | None = None) -> None:
    """Render, validate, and load the LaunchAgent, then report how to manage it."""
    args = parse_args(argv)

    if not TEMPLATE.is_file():
        sys.exit(f"error: template not found at {TEMPLATE}")

    port = _pick(args.port, "PORT", "8000")
    if not port.isdigit():
        sys.exit(f"error: --port must be an integer, got {port!r}")
    label = _pick(args.label, "LABEL", f"dev.{getpass.getuser()}.myproj")
    shell = _pick(args.shell, "SHELL_BIN", "/bin/zsh")
    default_log = str(Path.home() / "Library" / "Logs" / "myproj.log")
    log_path = _pick(args.log, "LOG_PATH", default_log)
    uv_bin = args.uv or os.environ.get("UV_BIN") or shutil.which("uv")
    if not uv_bin:
        sys.exit("error: uv not found on PATH; install uv or pass --uv /abs/path/to/uv")

    values = {
        "LABEL": label,
        "SHELL": shell,
        "UV_BIN": uv_bin,
        "PORT": port,
        "WORKING_DIR": str(REPO_ROOT),
        "LOG_PATH": log_path,
    }
    plist_text = render_plist(TEMPLATE.read_text(), values)

    if args.dry_run:
        print(plist_text)
        return

    if sys.platform != "darwin":
        sys.exit("error: this installer targets macOS launchd; use --dry-run elsewhere")
    if not (Path(shell).exists() and os.access(shell, os.X_OK)):
        sys.exit(f"error: login shell {shell} is not executable; pass --shell /bin/zsh")

    launch_agents = Path.home() / "Library" / "LaunchAgents"
    launch_agents.mkdir(parents=True, exist_ok=True)
    Path(log_path).parent.mkdir(parents=True, exist_ok=True)

    plist_path = launch_agents / f"{label}.plist"
    plist_path.write_text(plist_text)

    lint = subprocess.run(
        ["plutil", "-lint", str(plist_path)], capture_output=True, text=True, check=False
    )
    print(lint.stdout.strip() or f"{plist_path}: OK")
    if lint.returncode != 0:
        sys.exit(lint.stderr.strip() or "error: plutil -lint failed")

    domain = f"gui/{os.getuid()}"
    service = f"{domain}/{label}"
    _reload(domain, service, plist_path)

    url = f"http://127.0.0.1:{port}/"
    print(f"waiting for the app on 127.0.0.1:{port} ...", end=" ", flush=True)
    healthy = _wait_for_health(f"{url}api/health")
    print("ok" if healthy else f"no answer yet; check the log at {log_path}")

    print(
        f"\ninstalled and loaded: {label}\n"
        f"  plist:  {plist_path}\n"
        f"  log:    {log_path}\n"
        f"  url:    {url}\n\n"
        "manage:\n"
        f"  status:  launchctl print {service}\n"
        f"  restart: launchctl kickstart -k {service}   # after a dependency change\n"
        f"  stop:    launchctl bootout {service}"
    )


if __name__ == "__main__":
    main()
```

## Not covered

Linux is out of scope for this standard. The same pattern maps to a systemd user
service (`systemctl --user`, `WantedBy=default.target`, `loginctl enable-linger`),
but the plist, launchctl, and login-shell PATH details here are macOS only. Write
a separate standard for systemd if a project needs it.
