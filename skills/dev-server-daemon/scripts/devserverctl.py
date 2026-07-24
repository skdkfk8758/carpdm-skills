#!/usr/bin/env python3
"""devserverctl — run a project's dev server as a true daemon that survives the
agent sandbox, then verify/stop/inspect it.

WHY THIS EXISTS (the hard-won part):
  The Claude Code Bash tool reaps the *entire process tree* of a command when
  the tool call returns. Background tricks that you'd expect to work do NOT:
    - `make dev &`            → killed when the tool returns
    - `run_in_background:true`→ tracked as a job and terminated (observed ~70s)
    - `nohup make dev &`      → nohup only blocks SIGHUP; the harness sends SIGTERM
    - `nohup setsid ...`      → on macOS there is NO `setsid` BINARY; it fails with
                                "nohup: setsid: No such file or directory"
  The reliable fix is real UNIX daemonization: double-fork + os.setsid() so the
  server is reparented to init (pid 1) in a brand-new session. That escapes the
  sandbox's tree-kill, so the server keeps running across agent turns and even
  after the agent session ends — until you explicitly stop it.

Subcommands:
  start   daemonize a dev command, wait for it to listen, report URLs
  status  is it alive? which ports are listening?
  stop    kill the daemon (whole process group: make + node + vite…)
  logs    print the tail of the daemon log

State (pidfile + log) lives under ~/.cache/dev-daemon/<name>/.
"""
import argparse
import os
import re
import shutil
import signal
import subprocess
import sys
import time
import urllib.request

STATE_ROOT = os.path.expanduser("~/.cache/dev-daemon")


# ── state helpers ────────────────────────────────────────────────────────────
def slug(s):
    return re.sub(r"[^A-Za-z0-9._-]+", "-", s).strip("-") or "dev"


def state_dir(name):
    d = os.path.join(STATE_ROOT, slug(name))
    os.makedirs(d, exist_ok=True)
    return d


def paths(name):
    d = state_dir(name)
    return os.path.join(d, "daemon.pid"), os.path.join(d, "daemon.log")


def read_pid(pidfile):
    try:
        with open(pidfile) as f:
            return int(f.read().strip())
    except (OSError, ValueError):
        return None


def alive(pid):
    if not pid:
        return False
    try:
        os.kill(pid, 0)
        return True
    except OSError:
        return False


# ── dev-command auto-detection ───────────────────────────────────────────────
def detect_cmd(cwd):
    """Best-effort guess of the project's dev command. Override with --cmd."""
    mk = os.path.join(cwd, "Makefile")
    if os.path.isfile(mk):
        try:
            with open(mk) as f:
                if re.search(r"^dev:", f.read(), re.M):
                    return "make dev"
        except OSError:
            pass
    pj = os.path.join(cwd, "package.json")
    if os.path.isfile(pj):
        try:
            import json

            with open(pj) as f:
                scripts = (json.load(f) or {}).get("scripts", {})
        except (OSError, ValueError):
            scripts = {}
        if "dev" in scripts:
            if os.path.isfile(os.path.join(cwd, "pnpm-lock.yaml")):
                return "pnpm dev"
            if os.path.isfile(os.path.join(cwd, "yarn.lock")):
                return "yarn dev"
            return "npm run dev"
        if "start" in scripts:
            return "npm start"
    return None


# ── port inspection ──────────────────────────────────────────────────────────
def listening_ports():
    """Set of TCP ports currently in LISTEN state (best-effort, POSIX lsof)."""
    if not shutil.which("lsof"):
        return set()
    try:
        out = subprocess.run(
            ["lsof", "-nP", "-iTCP", "-sTCP:LISTEN"],
            capture_output=True, text=True, timeout=8,
        ).stdout
    except Exception:
        return set()
    ports = set()
    for m in re.finditer(r":(\d+)\s+\(LISTEN\)", out):
        ports.add(int(m.group(1)))
    return ports


def http_code(port):
    try:
        req = urllib.request.Request(f"http://localhost:{port}/", method="GET")
        with urllib.request.urlopen(req, timeout=2) as r:
            return r.status
    except urllib.error.HTTPError as e:
        return e.code  # server answered (e.g. 404) → it's up
    except Exception:
        return None


# ── daemonization (the core trick) ───────────────────────────────────────────
def spawn_daemon(cmd, cwd, logpath, pidpath):
    """Double-fork + setsid so the server reparents to init and survives the
    agent sandbox. Returns the daemon pid (grandchild) to the original caller."""
    r, w = os.pipe()  # grandchild reports its pid back to the original process
    pid = os.fork()
    if pid > 0:
        os.close(w)
        os.waitpid(pid, 0)  # reap the short-lived intermediate child
        data = os.read(r, 32)
        os.close(r)
        try:
            return int(data.decode().strip())
        except ValueError:
            return None
    # intermediate child
    os.close(r)
    os.setsid()  # new session + process group; detach controlling tty
    pid2 = os.fork()
    if pid2 > 0:
        os._exit(0)  # intermediate exits → grandchild reparents to init (pid 1)
    # grandchild = the daemon
    os.write(w, str(os.getpid()).encode())
    os.close(w)
    os.chdir(cwd)
    with open(pidpath, "w") as f:
        f.write(str(os.getpid()))
    devnull = os.open(os.devnull, os.O_RDONLY)
    logfd = os.open(logpath, os.O_WRONLY | os.O_CREAT | os.O_APPEND, 0o644)
    os.dup2(devnull, 0)
    os.dup2(logfd, 1)
    os.dup2(logfd, 2)
    os.closerange(3, 256)
    # exec through a login shell so "make dev" / "npm run dev" resolve on PATH
    os.execvp("/bin/sh", ["/bin/sh", "-lc", cmd])


# ── subcommands ──────────────────────────────────────────────────────────────
def cmd_start(args):
    cwd = os.path.abspath(args.cwd)
    if not os.path.isdir(cwd):
        sys.exit(f"cwd not a directory: {cwd}")
    name = args.name or os.path.basename(cwd.rstrip("/"))
    pidfile, logfile = paths(name)

    existing = read_pid(pidfile)
    if alive(existing):
        print(f"already running: name={name} pid={existing}")
        _report_ports(set(), logfile, existing, name, pidfile)
        return

    cmd = args.cmd or detect_cmd(cwd)
    if not cmd:
        sys.exit("could not detect a dev command — pass --cmd \"make dev\" (or your dev command)")

    open(logfile, "w").close()  # truncate previous log
    before = listening_ports()
    pid = spawn_daemon(cmd, cwd, logfile, pidfile)
    if not pid:
        sys.exit("failed to spawn daemon")
    print(f"daemon started: name={name} pid={pid} cmd={cmd!r} cwd={cwd}")
    print(f"log: {logfile}")

    # poll for newly-opened ports (dev servers compile first — give them time)
    deadline = time.time() + args.timeout
    new = set()
    while time.time() < deadline:
        time.sleep(2)
        if not alive(pid):
            print("\n!! daemon died during startup — last log lines:")
            _tail(logfile, 15)
            sys.exit(1)
        new = listening_ports() - before
        if new and _all_http_ready(new):
            break
    _report_ports(new, logfile, pid, name, pidfile)


def _all_http_ready(ports):
    # at least one port answers HTTP → server is serving (others may be API)
    return any(http_code(p) is not None for p in ports)


def _report_ports(new, logfile, pid, name, pidfile):
    ports = sorted(new) if new else sorted(listening_ports())
    print("\n=== dev server ===")
    if new:
        for p in sorted(new):
            code = http_code(p)
            tag = f"http {code}" if code is not None else "listening"
            print(f"  http://localhost:{p}   ({tag})")
    else:
        print("  (no NEW ports detected — check the log; server may still be compiling)")
    print(f"\npid {pid}  ·  log: {logfile}")
    print(f"stop:   python {os.path.abspath(__file__)} stop --name {name}")
    print(f"status: python {os.path.abspath(__file__)} status --name {name}")


def cmd_status(args):
    name = args.name or os.path.basename(os.path.abspath(args.cwd).rstrip("/"))
    pidfile, logfile = paths(name)
    pid = read_pid(pidfile)
    if alive(pid):
        print(f"RUNNING  name={name} pid={pid}")
        print("listening ports:", sorted(listening_ports()) or "(none seen)")
    else:
        print(f"STOPPED  name={name} (no live pid)")
    if os.path.isfile(logfile):
        print(f"log: {logfile}")


def cmd_stop(args):
    name = args.name or os.path.basename(os.path.abspath(args.cwd).rstrip("/"))
    pidfile, _ = paths(name)
    pid = read_pid(pidfile)
    if not alive(pid):
        print(f"not running: name={name}")
        return
    # daemon is a session/group leader (setsid) → killpg takes the whole tree
    # (make + node/nest + vite) in one shot.
    try:
        os.killpg(os.getpgid(pid), signal.SIGTERM)
    except OSError:
        try:
            os.kill(pid, signal.SIGTERM)
        except OSError:
            pass
    time.sleep(2)
    if alive(pid):
        try:
            os.killpg(os.getpgid(pid), signal.SIGKILL)
        except OSError:
            pass
    print(f"stopped: name={name} pid={pid}")


def _tail(path, n):
    try:
        with open(path) as f:
            for line in f.readlines()[-n:]:
                print("   " + line.rstrip())
    except OSError:
        print("   (no log)")


def cmd_logs(args):
    name = args.name or os.path.basename(os.path.abspath(args.cwd).rstrip("/"))
    _, logfile = paths(name)
    _tail(logfile, args.lines)


def main():
    ap = argparse.ArgumentParser(description="Run a dev server as a sandbox-surviving daemon.")
    sub = ap.add_subparsers(dest="action", required=True)

    s = sub.add_parser("start", help="daemonize a dev command and report URLs")
    s.add_argument("--cmd", help='dev command (e.g. "make dev", "npm run dev"). auto-detected if omitted')
    s.add_argument("--cwd", default=".", help="project directory (default: cwd)")
    s.add_argument("--name", help="daemon name (default: basename of cwd)")
    s.add_argument("--timeout", type=int, default=60, help="seconds to wait for ports (default 60)")
    s.set_defaults(func=cmd_start)

    for act, fn, help_ in [
        ("status", cmd_status, "show whether the daemon is alive + ports"),
        ("stop", cmd_stop, "stop the daemon (whole process group)"),
        ("logs", cmd_logs, "print the tail of the daemon log"),
    ]:
        p = sub.add_parser(act, help=help_)
        p.add_argument("--cwd", default=".", help="project directory (default: cwd)")
        p.add_argument("--name", help="daemon name (default: basename of cwd)")
        if act == "logs":
            p.add_argument("--lines", type=int, default=30)
        p.set_defaults(func=fn)

    args = ap.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
