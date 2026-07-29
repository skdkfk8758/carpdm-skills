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

PORT REPORTING IS OWNERSHIP-BASED (the second hard-won part):
  A machine-wide "what is listening" snapshot is NOT this server's URL. Another
  project (or the main checkout on a different branch) commonly already holds
  :3000, and reporting it hands the user a live link to the wrong code. Ports are
  therefore resolved by process-group ownership: the daemon is a session leader,
  so every port opened by its children shares its pgid. Foreign ports are never
  reported — if this server opened none, that is said out loud instead.

Subcommands:
  start   daemonize a dev command, wait for it to listen, report URLs
  status  is it alive? which ports does IT own?
  stop    kill the daemon (whole process group: make + node + vite…)
  logs    print the tail of the daemon log
  ports   show what is occupying ports (conflict check, no daemon needed)

State (pidfile + log + meta) lives under ~/.cache/dev-daemon/<name>/.
"""
import argparse
import json
import os
import re
import shutil
import signal
import socket
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


def meta_path(name):
    return os.path.join(state_dir(name), "daemon.json")


def write_meta(name, **kv):
    try:
        with open(meta_path(name), "w") as f:
            json.dump(kv, f)
    except OSError:
        pass


def read_meta(name):
    try:
        with open(meta_path(name)) as f:
            return json.load(f) or {}
    except (OSError, ValueError):
        return {}


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
def listening_map():
    """{port: (pid, command)} for TCP LISTEN sockets (best-effort, POSIX lsof)."""
    if not shutil.which("lsof"):
        return {}
    try:
        out = subprocess.run(
            ["lsof", "-nP", "-iTCP", "-sTCP:LISTEN"],
            capture_output=True, text=True, timeout=8,
        ).stdout
    except Exception:
        return {}
    found = {}
    for line in out.splitlines()[1:]:
        m = re.search(r"\s\S*:(\d+)\s+\(LISTEN\)", line)
        f = line.split()
        if not m or len(f) < 2:
            continue
        try:
            found[int(m.group(1))] = (int(f[1]), f[0])
        except ValueError:
            continue
    return found


def pgid_map():
    """{pid: pgid} for every visible process (one `ps` call)."""
    try:
        out = subprocess.run(
            ["ps", "-axo", "pid=,pgid="], capture_output=True, text=True, timeout=8
        ).stdout
    except Exception:
        return {}
    m = {}
    for line in out.splitlines():
        f = line.split()
        if len(f) >= 2:
            try:
                m[int(f[0])] = int(f[1])
            except ValueError:
                pass
    return m


def owned_ports(pid):
    """Ports LISTENed by *this daemon's* process group (make + node + vite…).

    The setsid() happens in the intermediate child, so the daemon's pgid is that
    child's pid — NOT `pid` itself. Every descendant inherits that pgid, so it is
    the exact ownership key, and it is what keeps a foreign :3000 out of the
    report."""
    if not alive(pid):
        return set()
    try:
        pgid = os.getpgid(pid)
    except OSError:
        return set()
    pmap = pgid_map()
    return {
        port for port, (lpid, _cmd) in listening_map().items()
        if pmap.get(lpid) == pgid
    }


def port_owner(port):
    """(pid, command) holding `port`, or None if free."""
    return listening_map().get(port)


def port_free(port):
    """True if nothing can be bound-clashed on `port` (bind test, no lsof needed)."""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        try:
            s.bind(("127.0.0.1", port))
            return True
        except OSError:
            return False


def next_free_port(start, limit=40):
    for p in range(start, start + limit):
        if port_free(p):
            return p
    return None


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
        prev = read_meta(name)
        print(f"already running: name={name} pid={existing} cwd={prev.get('cwd', '?')}")
        if prev.get("cwd") and os.path.abspath(prev["cwd"]) != cwd:
            print(
                "!! CWD MISMATCH — this daemon serves a DIFFERENT directory (likely another\n"
                f"   branch/worktree). Requested: {cwd}\n"
                "   Its URLs show code you did NOT change. Start a separate one:\n"
                f"     ... start --cwd {cwd} --name <distinct-name> --port <free port>"
            )
        _report_ports(existing, logfile, name)
        return

    cmd = args.cmd or detect_cmd(cwd)
    if not cmd:
        sys.exit("could not detect a dev command — pass --cmd \"make dev\" (or your dev command)")

    # ── port conflict pre-check ──────────────────────────────────────────────
    # A busy port is not a hard failure (Next/Vite silently shift to the next
    # one), which is exactly why it must be reported: the URL you'd assume is
    # then someone else's server.
    if args.port:
        owner = port_owner(args.port)
        if owner or not port_free(args.port):
            who = f"pid {owner[0]} ({owner[1]})" if owner else "another process"
            alt = next_free_port(args.port + 1)
            msg = f"port {args.port} is already taken by {who}."
            if alt:
                msg += f"\n  retry with a free one: --port {alt}"
            sys.exit(msg)
        cmd = f"PORT={args.port} {cmd}"  # honored by next/nest/CRA/remix; Vite
        # needs it on the command line instead: --cmd "npm run dev -- --port N"

    open(logfile, "w").close()  # truncate previous log
    pid = spawn_daemon(cmd, cwd, logfile, pidfile)
    if not pid:
        sys.exit("failed to spawn daemon")
    write_meta(name, cwd=cwd, cmd=cmd, pid=pid)
    print(f"daemon started: name={name} pid={pid} cmd={cmd!r} cwd={cwd}")
    print(f"log: {logfile}")

    # poll for the ports THIS daemon opened (dev servers compile first)
    deadline = time.time() + args.timeout
    mine = set()
    while time.time() < deadline:
        time.sleep(2)
        if not alive(pid):
            print("\n!! daemon died during startup — last log lines:")
            _tail(logfile, 15)
            sys.exit(1)
        mine = owned_ports(pid)
        if mine and _all_http_ready(mine):
            break
    _report_ports(pid, logfile, name)


def _all_http_ready(ports):
    # at least one port answers HTTP → server is serving (others may be API)
    return any(http_code(p) is not None for p in ports)


def _log_advertised_ports(logfile):
    """Ports the framework printed in its own banner (Local: http://localhost:N)."""
    try:
        with open(logfile) as f:
            text = f.read()
    except OSError:
        return set()
    return {int(m) for m in re.findall(r"localhost:(\d{2,5})", text)}


def _report_ports(pid, logfile, name):
    mine = owned_ports(pid)
    print("\n=== dev server ===")
    if mine:
        for p in sorted(mine):
            code = http_code(p)
            tag = f"http {code}" if code is not None else "listening"
            print(f"  http://localhost:{p}   ({tag})")
    else:
        print("  (this daemon owns NO listening port — still compiling, or it failed;"
              " run `logs`)")

    # A port the banner advertises but that a FOREIGN pid owns = the trap: the
    # link is alive and shows someone else's code.
    for p in sorted(_log_advertised_ports(logfile) - mine):
        owner = port_owner(p)
        if owner and owner[0] != pid:
            print(f"  !! :{p} appears in this server's log but is owned by pid "
                  f"{owner[0]} ({owner[1]}) — do NOT hand that URL out")

    print(f"\npid {pid}  ·  log: {logfile}")
    print("(only ports owned by this daemon's process group are listed above)")
    print(f"stop:   python {os.path.abspath(__file__)} stop --name {name}")
    print(f"status: python {os.path.abspath(__file__)} status --name {name}")


def cmd_status(args):
    name = args.name or os.path.basename(os.path.abspath(args.cwd).rstrip("/"))
    pidfile, logfile = paths(name)
    pid = read_pid(pidfile)
    if alive(pid):
        meta = read_meta(name)
        print(f"RUNNING  name={name} pid={pid} cwd={meta.get('cwd', '?')}")
        mine = sorted(owned_ports(pid))
        print("ports owned by this daemon:", mine or "(none — compiling or failed)")
    else:
        print(f"STOPPED  name={name} (no live pid)")
    if os.path.isfile(logfile):
        print(f"log: {logfile}")


def cmd_ports(args):
    """Conflict check: who holds what, before you assume a URL."""
    lm = listening_map()
    if not lm:
        print("(no LISTEN sockets seen — is lsof available?)")
        return
    if args.port:
        owner = lm.get(args.port)
        if owner:
            print(f":{args.port} TAKEN by pid {owner[0]} ({owner[1]})"
                  f"  → free alternative: {next_free_port(args.port + 1)}")
        else:
            print(f":{args.port} free")
        return
    for p in sorted(lm):
        pid, cmdname = lm[p]
        print(f"  :{p:<6} pid {pid:<8} {cmdname}")


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
    s.add_argument("--port", type=int, help="pin the port (checked for conflicts first; exported as PORT=)")
    s.add_argument("--timeout", type=int, default=60, help="seconds to wait for ports (default 60)")
    s.set_defaults(func=cmd_start)

    pp = sub.add_parser("ports", help="who is listening on what (conflict check)")
    pp.add_argument("--port", type=int, help="check a single port instead of listing all")
    pp.set_defaults(func=cmd_ports)

    for act, fn, help_ in [
        ("status", cmd_status, "show whether the daemon is alive + the ports IT owns"),
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
