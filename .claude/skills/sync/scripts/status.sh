#!/bin/bash
# Read-only audit of python-standards sync state. Prints a report; never
# mutates the repo, the remote, or any machine config (the only network call
# is a git fetch to learn ahead/behind counts).
#
# Expectations are derived from MAC.md itself, not hard-coded here, so the
# audit follows the doc when the doc changes.
#
# Overrides (used when exercising the skill against a sandbox copy):
#   PYSTD_DIR   defaults to $HOME/dev/etoews/python-standards
#   PYSTD_HOME  defaults to $HOME

set -u

DIR="${PYSTD_DIR:-$HOME/dev/etoews/python-standards}"
H="${PYSTD_HOME:-$HOME}"
MAC="$DIR/MAC.md"

if [ ! -d "$DIR/.git" ]; then
  echo "FAIL: no git repo at $DIR"
  exit 1
fi

echo "== GIT =="
branch=$(git -C "$DIR" rev-parse --abbrev-ref HEAD)
echo "branch: $branch"
[ "$branch" != "main" ] && echo "note: on a working branch; sync ff-merges it into main"

if git -C "$DIR" fetch --quiet origin 2>/dev/null; then
  counts=$(git -C "$DIR" rev-list --left-right --count origin/main...HEAD 2>/dev/null)
  behind=$(echo "$counts" | awk '{print $1}')
  ahead=$(echo "$counts" | awk '{print $2}')
  echo "behind origin/main: ${behind:-?}   ahead of origin/main: ${ahead:-?}"
else
  echo "WARN: fetch failed (offline?); ahead/behind unknown"
fi

dirty=$(git -C "$DIR" status --porcelain)
if [ -n "$dirty" ]; then
  echo "uncommitted changes:"
  echo "$dirty" | sed 's/^/  /'
else
  echo "working tree clean"
fi

stashes=$(git -C "$DIR" stash list | wc -l | tr -d ' ')
[ "$stashes" != "0" ] && echo "WARN: $stashes stash(es) present"

echo ""
echo "== MACHINE (does this Mac still match MAC.md?) =="
if [ ! -f "$MAC" ]; then
  echo "FAIL: no MAC.md at $MAC; cannot derive expectations"
else

  # Step 1: uv installed.
  if command -v uv >/dev/null; then
    echo "OK: uv $(uv --version 2>/dev/null | awk '{print $2}')"
  else
    echo "FAIL: uv not installed (MAC.md step 1: brew install uv)"
  fi

  # Step 2: uv-managed Python and the global pin, version read from MAC.md.
  want_py=$(grep -oE 'uv python pin --global [0-9]+\.[0-9]+' "$MAC" | head -1 | awk '{print $NF}')
  if [ -z "$want_py" ]; then
    echo "WARN: could not read the global Python version from MAC.md"
  else
    pinfile="$H/.config/uv/.python-version"
    if [ -f "$pinfile" ]; then
      got=$(tr -d '[:space:]' < "$pinfile")
      if [ "$got" = "$want_py" ]; then
        echo "OK: global Python pin $got"
      else
        echo "DRIFT: global pin is $got, MAC.md says $want_py"
      fi
    else
      echo "MISSING: $pinfile (MAC.md step 2: uv python pin --global $want_py)"
    fi

    if command -v uv >/dev/null; then
      if uv python list --only-installed 2>/dev/null | grep -q "cpython-${want_py}"; then
        echo "OK: uv-managed Python $want_py installed"
      else
        echo "MISSING: no uv-managed $want_py (uv python install $want_py)"
      fi
    fi
  fi

  # Step 3: global uv config. Wanted keys come from the toml fence in MAC.md.
  uvtoml="$H/.config/uv/uv.toml"
  want_keys=$(awk '/^```toml/{f=1;next} /^```/{f=0} f' "$MAC" | grep -oE '^[a-z][a-z-]+' | sort -u)
  if [ ! -f "$uvtoml" ]; then
    echo "MISSING: $uvtoml (MAC.md step 3)"
  else
    missing_keys=""
    for k in $want_keys; do
      grep -qE "^[[:space:]]*$k[[:space:]]*=" "$uvtoml" || missing_keys="$missing_keys $k"
    done
    if [ -z "$missing_keys" ]; then
      echo "OK: uv.toml has every key MAC.md lists"
    else
      echo "DRIFT: uv.toml missing key(s):$missing_keys"
    fi
  fi

  # Step 4: venv guardrail, as a login shell would see it.
  guard=$(zsh -c "source $H/.zprofile >/dev/null 2>&1; echo \${PIP_REQUIRE_VIRTUALENV:-}" 2>/dev/null)
  if [ "$guard" = "1" ]; then
    echo "OK: PIP_REQUIRE_VIRTUALENV=1"
  else
    echo "MISSING: PIP_REQUIRE_VIRTUALENV is '${guard:-unset}' in a login shell (MAC.md step 4)"
  fi

  # Step 5: user-scope Claude permissions listed in MAC.md.
  python3 - "$MAC" "$H/.claude/settings.json" <<'PYEOF'
import json, re, sys

mac_path, settings_path = sys.argv[1], sys.argv[2]
want = sorted(set(re.findall(r'"(Bash\(uv [^"]*\))"', open(mac_path).read())))
if not want:
    print("WARN: no Bash(uv ...) permissions found in MAC.md")
    raise SystemExit(0)
try:
    allow = set(json.load(open(settings_path)).get("permissions", {}).get("allow", []))
except FileNotFoundError:
    print(f"MISSING: {settings_path} (MAC.md step 5)")
    raise SystemExit(0)
except Exception:
    print(f"FAIL: {settings_path} is not valid JSON")
    raise SystemExit(0)
missing = [w for w in want if w not in allow]
if missing:
    print(f"DRIFT: user-scope Claude permissions missing {len(missing)}/{len(want)}: {', '.join(missing)}")
else:
    print(f"OK: all {len(want)} uv permissions present in ~/.claude/settings.json")
PYEOF

  # Step 6: VS Code extensions listed in MAC.md.
  want_ext=$(grep -oE 'code --install-extension [A-Za-z0-9._-]+' "$MAC" | awk '{print $3}' | sort -u)
  n_want=$(echo "$want_ext" | grep -c .)
  if ! command -v code >/dev/null; then
    echo "WARN: 'code' not on PATH; cannot check the $n_want VS Code extensions"
  else
    have=$(code --list-extensions 2>/dev/null)
    missing_ext=""
    for e in $want_ext; do
      echo "$have" | grep -qix "$e" || missing_ext="$missing_ext $e"
    done
    if [ -z "$missing_ext" ]; then
      echo "OK: all $n_want VS Code extensions installed"
    else
      echo "MISSING: VS Code extension(s):$missing_ext"
    fi
  fi
fi

echo ""
echo "== DOCS =="
python3 - "$DIR" <<'PYEOF'
import os, re, sys

root = sys.argv[1]
docs = [f for f in ("README.md", "MAC.md", "PROJECT.md", "CLAUDE.md")
        if os.path.isfile(os.path.join(root, f))]

def anchor(heading):
    # GitHub's rule: lowercase, drop punctuation, then map each remaining
    # space to its own hyphen ("lint + format" -> "lint--format").
    s = re.sub(r'[^\w\s-]', '', heading.strip().lower())
    return re.sub(r'\s', '-', s.strip())

problems = 0
for name in docs:
    text = open(os.path.join(root, name)).read()
    anchors = {anchor(m) for m in re.findall(r'^#{1,6}\s+(.*)$', text, re.M)}
    for target in re.findall(r'\]\((#[^)]+)\)', text):
        if target[1:] not in anchors:
            print(f"BROKEN: {name} links to {target}, no such heading")
            problems += 1
    for target in re.findall(r'\]\(([^)#][^)]*)\)', text):
        if re.match(r'^[a-z]+://|^mailto:', target):
            continue
        if not os.path.exists(os.path.join(root, target.split('#')[0])):
            print(f"BROKEN: {name} links to {target}, no such file")
            problems += 1
if not problems:
    print(f"OK: internal links and TOC anchors resolve in {len(docs)} docs")
PYEOF

echo ""
echo "== NOTES =="
localnotes="$DIR/README.local.md"
if [ -f "$localnotes" ]; then
  if git -C "$DIR" ls-files --error-unmatch README.local.md >/dev/null 2>&1; then
    echo "FAIL: README.local.md is TRACKED; it is machine-local and must stay gitignored"
  else
    echo "machine-local file present: README.local.md (never commit)"
  fi
fi
echo "repo is public: keep employer, network, and vendor names out of files and commit messages"
exit 0
