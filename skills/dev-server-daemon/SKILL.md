---
name: dev-server-daemon
description: >-
  Start a project's dev server in the BACKGROUND as a true daemon that survives
  the agent sandbox, so the user can open it in their browser and verify a change
  themselves. Use this WHENEVER the user wants a dev/local server left running —
  "개발서버 백그라운드로 띄워줘", "dev 서버 올려둬 내가 확인할게", "start the app so I
  can check it", "keep the server running", "run it in the background", "올려놔",
  "leave it up" — and ESPECIALLY when a dev server you started keeps dying after a
  minute or two, or when `make dev &` / `nohup` / run-in-background got reaped.
  The naive ways (`&`, nohup, run_in_background) all die because the Claude Code
  Bash tool kills its process tree on return; on macOS `setsid` doesn't even
  exist. This skill daemonizes correctly (double-fork) so the server persists.
  Also handles status / stop / logs for a server it launched.
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

And a second failure that looks like success: the port you assume is **someone
else's server**. `:3000` is usually already held by another project (or by the
main checkout on a different branch). Frameworks silently shift to the next free
port when that happens, so the server you started is on `:3001` while the URL you
hand out — `:3000` — is alive, renders fine, and shows code you did not change.
That is why this script never reports a machine-wide port snapshot: see
[Port conflicts](#port-conflicts-the-3000-trap).

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
python ~/.claude/skills/dev-server-daemon/scripts/devserverctl.py start --cwd /path/to/project
```

It daemonizes the server, waits for it to start listening (dev servers compile
first — it polls up to ~60s), then prints the live URLs with HTTP status, the pid,
the log path, and the stop command. Relay those URLs to the user.

**Override the command** when auto-detect is wrong or the project uses a wrapper:

```bash
... start --cmd "make dev" --cwd /path/to/worktree
... start --cmd "npm run dev -- --port 4000" --cwd .
```

**Check / stop / logs / port conflicts** later:

```bash
python ~/.claude/skills/dev-server-daemon/scripts/devserverctl.py status --cwd /path/to/project
python ~/.claude/skills/dev-server-daemon/scripts/devserverctl.py stop   --cwd /path/to/project
python ~/.claude/skills/dev-server-daemon/scripts/devserverctl.py logs   --cwd /path/to/project --lines 40
python ~/.claude/skills/dev-server-daemon/scripts/devserverctl.py ports              # who holds what
python ~/.claude/skills/dev-server-daemon/scripts/devserverctl.py ports --port 3000  # is one port free?
```

`stop` kills the whole process group (e.g. `make` + the API + Vite together),
since the daemon is its own session leader.

## Port conflicts (the `:3000` trap)

**Check before you start, and only trust ports this daemon owns.**

```bash
... ports --port 3000        # ":3000 TAKEN by pid 21264 (node)  → free alternative: 3001"
... start --cwd <worktree> --port 3001
```

- `--port N` **pre-checks** N (bind test + owner lookup) and refuses to start with
  a suggested free port if it's taken. It then exports `PORT=N` to the dev command
  — honored by Next / Nest / CRA / Remix. **Vite ignores `PORT`**: use
  `--cmd "npm run dev -- --port 3001"` instead.
- The report lists **only ports whose process group is this daemon's** (setsid
  gives it a private pgid). A foreign `:3000` can never leak into the report; if
  the server opened nothing, it says so instead of substituting someone else's.
- If the framework's own banner advertises a port that a **different** pid owns,
  the report flags it (`!! :3000 appears in this server's log but is owned by pid
  … — do NOT hand that URL out`). That's the collision case where the framework
  shifted ports but printed the original.
- Re-running `start` for a daemon **name** already alive prints its recorded
  `cwd` and warns on mismatch — same repo, different worktree/branch is the other
  way you end up showing unchanged code. Use a distinct `--name` per worktree.

## How to drive it (workflow)

1. **Check the port** you expect (`ports --port N`) if the project pins one; pick a
   free port up front rather than discovering the collision from a wrong URL.
2. **Start it** with the right `--cwd` (the project or git-worktree the user is
   working in — not necessarily your shell's cwd) and a per-worktree `--name`.
3. **Read the reported ports.** They are ownership-filtered — whatever is listed
   belongs to this server. If it reports it owns none, the server is probably still
   compiling or errored — run `logs` and check. Never fill the gap with `:3000`.
4. **Report the URLs to the user** in plain text (FE URL first; note which port is
   the API if there are two). Tell them how to reach the specific thing they want
   to verify (e.g. a route, after login).
5. **Hand off.** Tell them the server is detached and will keep running, and how to
   stop it (`stop --cwd ...` or `kill <pid>`). Don't re-launch on top of a running
   one — `start` is idempotent and will just report the existing daemon.

## Notes & gotchas

- **Run `start` as a normal Bash call, not `run_in_background`.** The script
  returns once the server is up; the daemon it spawned lives on independently.
  Wrapping it in run_in_background defeats the point and re-introduces the reaping.
- **Worktrees:** pass the worktree path as `--cwd` **and a distinct `--name`**
  (the default name is the cwd basename, which collides when two worktrees share
  it). Frameworks that auto-shift ports won't fail to boot, but the URL they
  print may not be the one they got — the report is ownership-filtered for
  exactly this reason.
- **Two ports (FE + API):** full-stack dev (e.g. Vite + a Node/Nest API) opens
  two. The script lists both; the one answering HTTP on `/` is usually the FE, the
  other is the API the FE proxies to. Verify both came up before declaring success.
- **Invoke it as `python3`.** Recent macOS ships no bare `python` on PATH — the
  examples above are written `python` for brevity, but `python: command not found`
  is the expected failure on a clean machine. Use `python3` and it just works.
- **macOS & Linux:** the Python double-fork works on both. Port detection uses
  `lsof`; if `lsof` is absent the server still starts but port reporting is blank
  (fall back to reading the log for the framework's "Local: http://…" line).
- **Persistence scope:** the daemon survives your turns and even the agent session.
  It does NOT survive a machine reboot. There's no auto-restart — that's
  intentional (a crash-looping server should surface, not silently respawn).
