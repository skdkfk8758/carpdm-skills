#!/usr/bin/env python3
"""
Deterministic CI/CD scaffolder for the cicd-scaffold skill.

The model decides the values (by detecting from the project + interviewing the
user for AWS/GitHub gaps), then calls this script with concrete args. The script
does the mechanical, error-prone part: copy templates, prune the optional blocks
that don't apply, substitute every token, and hard-fail if any token survives.

This keeps judgment with the model and removes the divergence + token cost of
hand-substituting YAML on every invocation.

Optional blocks in the templates are fenced with marker comments:
    # @optional:NAME:start ... # @optional:NAME:end
A kept block loses only its marker lines; a dropped block loses marker + body.

Example:
    python scaffold.py --dest /path/to/project \\
      --app-name intel-portal --aws-region ap-northeast-2 \\
      --ecr-repo intel-portal --host-port 80 --container-port 3000 \\
      --dockerfile Dockerfile --build-cmd "npm run build" --test-cmd "npm test" \\
      --npm-scope @team-draftype
    # single package, no audit, generate a Dockerfile:
    python scaffold.py --dest ... --no-api-build --no-audit --gen-dockerfile --start-cmd "node dist/main.js" ...
"""
import argparse
import json
import os
import re
import sys

SKILL_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(SKILL_DIR, "assets")
WF_SRC = os.path.join(ASSETS, "workflows")


def strip_region(text: str, name: str, keep: bool) -> str:
    """Keep a region's body (drop only markers) or drop the whole region."""
    start = re.compile(rf"^[ \t]*#\s*@optional:{re.escape(name)}:start[ \t]*\n", re.M)
    end = re.compile(rf"^[ \t]*#\s*@optional:{re.escape(name)}:end[ \t]*\n", re.M)
    out, i = [], 0
    while True:
        ms = start.search(text, i)
        if not ms:
            out.append(text[i:])
            break
        me = end.search(text, ms.end())
        if not me:
            out.append(text[i:])
            break
        out.append(text[i:ms.start()])
        if keep:
            out.append(text[ms.end():me.start()])
        i = me.end()
    return "".join(out)


def sub_build_args(text: str, build_args: str) -> str:
    """Replace the indented __BUILD_ARGS__ line, preserving the leading whitespace
    on each emitted arg (build-args is a YAML block scalar)."""
    def repl(m):
        indent = m.group(1)
        lines = [ln for ln in build_args.replace("\\n", "\n").split("\n") if ln.strip()]
        return "\n".join(indent + ln.strip() for ln in lines)
    return re.sub(r"^([ \t]*)__BUILD_ARGS__[ \t]*$", repl, text, flags=re.M)


def process(text: str, regions: dict, tokens: dict, build_args: str | None) -> str:
    for name, keep in regions.items():
        text = strip_region(text, name, keep)
    if build_args is not None and "__BUILD_ARGS__" in text:
        text = sub_build_args(text, build_args)
    for tok, val in tokens.items():
        text = text.replace(tok, val)
    return text


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--dest", required=True, help="project root (writes .github/workflows/)")
    p.add_argument("--app-name", required=True)
    p.add_argument("--aws-region", required=True)
    p.add_argument("--ecr-repo", required=True)
    p.add_argument("--host-port", required=True)
    p.add_argument("--container-port", required=True)
    p.add_argument("--dockerfile", default="Dockerfile", help="Dockerfile path used by the build step")
    p.add_argument("--build-cmd", required=True)
    p.add_argument("--test-cmd", required=True)
    p.add_argument("--npm-scope", default="", help="private GitHub Packages @scope; omit to drop private-scope steps")
    p.add_argument("--api-build-cmd", default="", help="monorepo api typecheck cmd; omit/--no-api-build for single package")
    p.add_argument("--no-api-build", action="store_true")
    p.add_argument("--build-args", default="", help="docker build-args, newline/\\n separated; omit to drop the block")
    p.add_argument("--no-audit", action="store_true")
    p.add_argument("--ci-runner", choices=["self-hosted", "github"], default="self-hosted",
                   help="CI/release runner. self-hosted (default) = node:20 container on the "
                        "dev/prod runner, zero GitHub-hosted minutes (matches the zero-billing "
                        "topology + adds the workspace-wipe guard). github = ubuntu-latest "
                        "(simpler/isolated, but billed and dies on a billing stop). See pitfalls.md #4/#5.")
    p.add_argument("--gen-dockerfile", action="store_true", help="also generate a Dockerfile from the template")
    p.add_argument("--start-cmd", default="npm start", help="container CMD when generating a Dockerfile")
    a = p.parse_args()

    private = bool(a.npm_scope)
    api_build = bool(a.api_build_cmd) and not a.no_api_build
    build_args_on = bool(a.build_args)
    ci_self_hosted = a.ci_runner == "self-hosted"

    regions = {
        "private-scope": private,
        "no-private-scope": not private,
        "api-build": api_build,
        "build-args": build_args_on,
        "ci-self-hosted": ci_self_hosted,
        "ci-github": not ci_self_hosted,
    }
    tokens = {
        "__PRIVATE_NPM_SCOPE__": a.npm_scope,
        "__BUILD_CMD__": a.build_cmd,
        "__API_BUILD_CMD__": a.api_build_cmd,
        "__TEST_CMD__": a.test_cmd,
        "__AWS_REGION__": a.aws_region,
        "__ECR_REPO__": a.ecr_repo,
        "__DOCKERFILE__": a.dockerfile,
        "__APP_NAME__": a.app_name,
        "__HOST_PORT__": a.host_port,
        "__CONTAINER_PORT__": a.container_port,
        # Dockerfile CMD exec-form: split into a JSON array so multi-word starts
        # (e.g. "node apps/api/dist/main.js") don't become one bogus binary name.
        "__START_CMD_JSON__": json.dumps(a.start_cmd.split()),
    }

    wf_dest = os.path.join(a.dest, ".github", "workflows")
    os.makedirs(wf_dest, exist_ok=True)

    written = []
    for fn in sorted(os.listdir(WF_SRC)):
        if not fn.endswith(".yml"):
            continue
        if fn == "audit.yml" and a.no_audit:
            continue
        src = os.path.join(WF_SRC, fn)
        text = open(src, encoding="utf-8").read()
        text = process(text, regions, tokens, a.build_args if build_args_on else None)
        outp = os.path.join(wf_dest, fn)
        open(outp, "w", encoding="utf-8").write(text)
        written.append(outp)

    if a.gen_dockerfile:
        dt = open(os.path.join(ASSETS, "Dockerfile.template"), encoding="utf-8").read()
        dt = process(dt, regions, tokens, None)
        dpath = os.path.join(a.dest, a.dockerfile)
        os.makedirs(os.path.dirname(dpath) or ".", exist_ok=True)
        open(dpath, "w", encoding="utf-8").write(dt)
        written.append(dpath)

    # Hard guard: no token may survive in the workflows.
    leftover = {}
    for outp in written:
        if "/.github/workflows/" in outp.replace("\\", "/"):
            found = re.findall(r"__[A-Z_]+__", open(outp, encoding="utf-8").read())
            if found:
                leftover[outp] = sorted(set(found))
    if leftover:
        print("ERROR: unsubstituted tokens remain:", file=sys.stderr)
        for f, t in leftover.items():
            print(f"  {f}: {t}", file=sys.stderr)
        sys.exit(1)

    print(f"Scaffolded {len(written)} files into {a.dest}:")
    for w in written:
        print("  " + os.path.relpath(w, a.dest))
    print("\nGuard: no __TOKEN__ survives in workflows. ✓")
    print("Next: GitHub + AWS setup (references/github-setup.md, references/aws-oidc-setup.md), then DEPLOY_ENABLED cutover.")


if __name__ == "__main__":
    main()
