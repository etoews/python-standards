---
name: sync
description: Sync this python-standards repo between machines and verify this Mac still matches what MAC.md prescribes. Use whenever the user says "sync", asks to push or pull the standards, says they edited the docs on the other machine, reports that a documented setup step no longer holds (uv missing, wrong default Python, the pip guardrail not firing, a VS Code extension gone), or has just changed MAC.md or PROJECT.md in a way the other machine should pick up, even if they never say the word "sync".
---

# Sync

This repo lives at `$HOME/dev/etoews/python-standards` and holds only markdown:
MAC.md (machine layer), PROJECT.md (per-project layer), README.md, CLAUDE.md.
Git carries it between machines. "Sync" means: pull, reconcile drift, ff-merge
the working branch, push, verify. Always do all five, in that order, even if
the user only asked for one direction. Half a sync is how the machines quietly
diverge.

## Step 0: Audit

Run the read-only audit first and again at the end:

```sh
.claude/skills/sync/scripts/status.sh
```

It reports git state, this Mac's conformance to MAC.md, doc integrity (internal
links and TOC anchors), and warnings. It never mutates anything. Its
expectations are parsed out of MAC.md, so the doc stays the source of truth and
the audit follows it automatically. When exercising the skill against a sandbox
copy, set `PYSTD_DIR` and `PYSTD_HOME`; note that `PYSTD_HOME` only redirects
file-path checks, since `uv` and `code` always answer for the real machine.

## Nothing here symlinks

Unlike the dotfiles repo, no file in this repo is linked into the live system.
Nothing to install, build, test, or lint. The analogue of "symlink health" is
different and it is the reason the audit exists: **MAC.md describes real machine
state**, so this Mac can drift from the doc even when git is perfectly in sync.
The audit checks what MAC.md claims is true here:

| MAC.md step | What can drift |
|---|---|
| 1 | uv missing from PATH |
| 2 | no uv-managed Python at the pinned version; `~/.config/uv/.python-version` gone or stale |
| 3 | `~/.config/uv/uv.toml` missing keys |
| 4 | `PIP_REQUIRE_VIRTUALENV` not 1 in a login shell |
| 5 | `~/.claude/settings.json` missing the uv permissions |
| 6 | VS Code extensions uninstalled |

## Two directions of drift, and they are fixed differently

- **Machine drifted from the doc** (audit says MISSING or DRIFT, doc is still
  right): re-run that MAC.md step on this machine. No commit results.
- **The world moved past the doc** (uv changed a flag, a new default Python, an
  extension renamed): the doc is what needs changing. Propose the edit on a
  `feat/*` branch and say so in the report. Never silently reshape MAC.md to
  match whatever this machine happens to have; that ratifies drift as standard.

When you cannot confidently tell which of the two you are looking at, show the
user and ask. Guessing wrong either breaks the other machine or bakes a local
accident into the standard.

## Never commit

- `README.local.md` — machine-local workarounds, gitignored on purpose. It must
  never become tracked and never be promoted into MAC.md. The audit FAILs if it
  is tracked.
- `.obsidian/workspace.json`, `.DS_Store` — noise, already gitignored.

## This repo is public

Keep employer, corporate network, and vendor names out of every file **and out
of commit messages**. If a machine-specific problem needs recording (a
TLS-inspecting network breaking `uv python install`, say), write it neutrally or
put it in `README.local.md`.

## The procedure

1. **Classify what the audit found** into three buckets:
   - *Share*: intentional doc edits meant for both machines.
   - *Machine*: conformance gaps to repair on this Mac (no commit).
   - *Noise*: gitignored churn. Leave it.

2. **Pull with rebase.** `git pull --rebase` on `main`. Never a merge commit; if
   both machines committed, rebase keeps history linear.

3. **Repair machine drift** the audit flagged, running the actual MAC.md step
   rather than an improvised equivalent. Re-running a step must not clobber
   unrelated config: step 5 merges into `~/.claude/settings.json`, preserving
   every existing key, and `~/.zprofile` may be a symlink into the dotfiles repo,
   so check with `ls -la` and edit the target on a branch there.

4. **Commit the Share bucket, ff-merge the working branch, and push.** Work
   happens on a `feat/<slug>` branch, not on `main` (the global git rules require
   this). Commit still-uncommitted Share changes there using this repo's style
   from `git log`: a conventional-commit prefix, lower case, e.g.
   `docs: pin default Python to 3.15`. Then ship it: invoking `/sync` is the go
   signal, so it satisfies the "review before ff-merge" gate in the global rules.
   Rebase the `feat/*` branch onto the freshly pulled `main` so it fast-forwards,
   check out `main`, `git merge --ff-only` the branch, delete the merged branch,
   and push `main`. If `/sync` was invoked from `main`, there is nothing to
   merge; just commit Share changes there. Only the branch you are on is
   integrated; other `feat/*` branches are left alone.

5. **Verify.** Re-run the audit, confirm it is clean, then report.

## After syncing, tell the user what still needs a human

- A changed `~/.zprofile` does not affect open shells: `exec zsh`.
- Pulled PROJECT.md changes do not reach existing projects. Their per-project
  `CLAUDE.md` was copied from the template at `uv init` time and is now a fork;
  say which projects likely want the update rather than editing them here.
- The other machine only gets doc changes on its own next sync.

## Report format

End with exactly this shape, dropping lines that do not apply:

```
## Sync report
- Pulled: <n> commits: <one-line summary> | already up to date
- Merged: <branch> -> main (ff) | nothing to merge
- Pushed: <n> commits: <one-line summary> | nothing to push
- Machine repaired: <what, which MAC.md step> | already conformant
- Doc changes proposed: <what and why> | none
- Left alone (machine-local): <list>
- Action needed: exec zsh | sync the other machine | none
```

## Scope

This skill touches only this repo, its remote, and the machine config MAC.md
prescribes. Nothing else on the machine is in scope. Never force-push; if a push
is rejected, fetch and rebase again.
