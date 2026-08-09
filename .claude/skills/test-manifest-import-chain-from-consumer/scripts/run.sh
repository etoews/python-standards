#!/usr/bin/env bash
#
# End-to-end test of the python-standards manifest import chain, run FROM a
# consumer project that vendors this repo as a submodule at standards/python/.
#
# It proves a fresh Claude Code session actually loads the standards through the
# chained import:
#
#   <consumer>/CLAUDE.md  ->  @standards/python/standards/manifest.md  ->  @uv.md
#
# A generic model can recite uv best practices from training, so "what are my uv
# rules?" would be a false positive. Instead this plants a random sentinel token
# in the deepest file (uv.md), starts a fresh headless `claude`, and asks it to
# echo the token WITHOUT reading files. Only a chain that truly resolved into the
# session's context can produce it, and num_turns == 1 confirms the answer came
# from loaded memory rather than a file read. The sentinel is reverted on exit.
#
set -euo pipefail

skill_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

submodule=$(git -C "$skill_dir" rev-parse --show-toplevel 2>/dev/null || true)
[ -n "$submodule" ] || { echo "FAIL: not inside a git working tree." >&2; exit 2; }

consumer=$(git -C "$submodule" rev-parse --show-superproject-working-tree 2>/dev/null || true)
if [ -z "$consumer" ]; then
  echo "FAIL: python-standards is not vendored as a submodule here." >&2
  echo "      This test runs from a consumer project that adds it at standards/python/." >&2
  exit 2
fi

claude_md="$consumer/CLAUDE.md"
uv_md="$submodule/standards/uv.md"

command -v claude  >/dev/null 2>&1 || { echo "FAIL: 'claude' CLI not on PATH." >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "FAIL: python3 not on PATH." >&2; exit 2; }
[ -f "$claude_md" ] || { echo "FAIL: no CLAUDE.md at the consumer root ($consumer)." >&2; exit 2; }
grep -qE '@[^[:space:]]*standards/manifest\.md' "$claude_md" || {
  echo "FAIL: $claude_md does not import the standards manifest." >&2
  echo "      Expected a line like: @standards/python/standards/manifest.md" >&2
  exit 2
}
[ -f "$uv_md" ] || {
  echo "FAIL: $uv_md is missing. Check out the submodule at a 1.1.0 or later tag." >&2
  exit 2
}

sentinel="uv-chain-$(openssl rand -hex 6 2>/dev/null || date +%s%N)"
tmp=$(mktemp)

cleanup() {
  git -C "$submodule" checkout -- standards/uv.md >/dev/null 2>&1 || true
  rm -f "$tmp"
}
trap cleanup EXIT

printf '\n- SENTINEL %s\n' "$sentinel" >> "$uv_md"

prompt="Without reading, searching, or opening any files, output only the exact SENTINEL token found in your loaded project instructions (this includes CLAUDE.md and any files it imports). If there is no such token, output NONE."

( cd "$consumer" && claude -p "$prompt" --output-format json ) > "$tmp" 2>/dev/null || true

python3 - "$tmp" "$sentinel" <<'PY'
import json, sys

tmp, sentinel = sys.argv[1], sys.argv[2]
try:
    d = json.load(open(tmp))
except Exception as e:
    print(f"FAIL: could not parse the claude response ({e}).")
    sys.exit(1)

result = d.get("result") or ""
turns = d.get("num_turns")

if sentinel in result and turns == 1:
    print("PASS: a fresh session echoed the planted sentinel from loaded context.")
    print("      CLAUDE.md -> manifest.md -> uv.md resolves end to end (num_turns=1, no file read).")
    sys.exit(0)
if sentinel in result:
    print(f"INCONCLUSIVE: sentinel returned but num_turns={turns} (expected 1).")
    print("      The model may have read the file instead of loading it from context. Re-run.")
    sys.exit(1)
print("FAIL: the fresh session did not surface the sentinel from its loaded instructions.")
print(f"      num_turns={turns}; response={result!r}")
print("      Verify the CLAUDE.md import line, that the submodule is at 1.1.0+, and that")
print("      standards/manifest.md imports @uv.md.")
sys.exit(1)
PY
