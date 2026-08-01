---
name: claude-dev-server-daemon
description: Imported Claude skill for starting, checking, logging, and stopping durable local development server daemons.
---

# dev-server-daemon

Keep a project's dev server running in the background so the user can verify a
change in their own browser, without the server dying when your turn ends.

> **Language:** Respond to the user in Korean (한국어) when running this skill —
> the prose you write back (status updates, the reported URLs, the hand-off
> note). The script's own stdout (URLs, pid, ports, log path) stays verbatim.

## The problem this solves

You start `make dev` (or `npm run dev`) so the user can look at the app. It comes
up — then a minute later the API is dead and the user gets `ECONNREFUSED`. Every
"background" trick you'd reach for fails, for non-obvious reasons:

| attempt | why it dies |
|---|---|
| `make dev &` | Bash tool kills its whole process tree when the call returns |
| `run_in_background: true` | tracked as a job and terminated (observed ~70s in) |
| `nohup make dev &` | `nohup` only ignores SIGHUP; the harness sends **SIGTERM** |
| `nohup setsid make dev &` | **macOS has no `setsid` binary** → "setsid: No such file or directory" |

The only thing that reliably survives is real UNIX **daemonization**: fork →
`setsid()` → fork again, so the server is **reparented to init (pid 1)** in a new
session. It's no longer a descendant of the Bash tool's process group, so the
tree-kill can't reach it. `scripts/devserverctl.py` does exactly this (in Python,
since `os.setsid()` is available even though the macOS binary isn't).

## Usage

The script auto-detects the dev command (`make dev` if the Makefile has a `dev:`
target, else `npm/pnpm/yarn dev` from package.json). Pass `--cmd` to override.

**Start** (run from the project dir, or pass `--cwd`):

```bash
python /Users/carpdm/.codex/skills/claude-dev-server-daemon/scripts/devserverctl.py start --cwd /path/to/project
```

It daemonizes the server, waits for it to start listening (dev servers compile
first — it polls up to ~60s), then prints the live URLs with HTTP status, the pid,
the log path, and the stop command. Relay those URLs to the user.

**Override the command** when auto-detect is wrong or the project uses a wrapper:

```bash
... start --cmd "make dev" --cwd /path/to/worktree
... start --cmd "npm run dev -- --port 4000" --cwd .
```

**Check / stop / logs** later:

```bash
python /Users/carpdm/.codex/skills/claude-dev-server-daemon/scripts/devserverctl.py status --cwd /path/to/project
python /Users/carpdm/.codex/skills/claude-dev-server-daemon/scripts/devserverctl.py stop   --cwd /path/to/project
python /Users/carpdm/.codex/skills/claude-dev-server-daemon/scripts/devserverctl.py logs   --cwd /path/to/project --lines 40
```

`stop` kills the whole process group (e.g. `make` + the API + Vite together),
since the daemon is its own session leader.

## How to drive it (workflow)

1. **Start it** with the right `--cwd` (the project or git-worktree the user is
   working in — not necessarily your shell's cwd).
2. **Read the reported ports.** The script diffs listening ports before/after, so
   it shows only the ports *this* server opened. If it reports "no NEW ports", the
   server is probably still compiling or errored — run `logs` and check.
3. **Report the URLs to the user** in plain text (FE URL first; note which port is
   the API if there are two). Tell them how to reach the specific thing they want
   to verify (e.g. a route, after login).
4. **Hand off.** Tell them the server is detached and will keep running, and how to
   stop it (`stop --cwd ...` or `kill <pid>`). Don't re-launch on top of a running
   one — `start` is idempotent and will just report the existing daemon.

## Notes & gotchas

- **Run `start` as a normal Bash call, not `run_in_background`.** The script
  returns once the server is up; the daemon it spawned lives on independently.
  Wrapping it in run_in_background defeats the point and re-introduces the reaping.
- **Worktrees:** pass the worktree path as `--cwd`. Many `make dev` setups
  auto-pick free ports, so two worktrees won't collide — the script reports
  whatever ports actually opened.
- **Two ports (FE + API):** full-stack dev (e.g. Vite + a Node/Nest API) opens
  two. The script lists both; the one answering HTTP on `/` is usually the FE, the
  other is the API the FE proxies to. Verify both came up before declaring success.
- **macOS & Linux:** the Python double-fork works on both. Port detection uses
  `lsof`; if `lsof` is absent the server still starts but port reporting is blank
  (fall back to reading the log for the framework's "Local: http://…" line).
- **Persistence scope:** the daemon survives your turns and even the agent session.
  It does NOT survive a machine reboot. There's no auto-restart — that's
  intentional (a crash-looping server should surface, not silently respawn).
