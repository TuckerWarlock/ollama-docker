#!/usr/bin/env python3
"""Model-agnostic image generation through ComfyUI.

Each model is a JSON file in image-models/ that names a workflow template
(image-models/workflows/<name>.json), the files to download, and default
parameters. Workflow inputs written as "$name" are filled from those
defaults, overridden by command-line flags.

Usage:
    python3 scripts/image-gen.py list
    python3 scripts/image-gen.py pull z-image-turbo [--dry-run]
    python3 scripts/image-gen.py gen z-image-turbo "a red fox in snow" [--steps 9] [--size 1024x1024] [--seed 42]
    python3 scripts/image-gen.py webui-env z-image-turbo
    python3 scripts/image-gen.py webui-install
"""

import argparse
import json
import os
import random
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any

REPO_DIR = Path(__file__).resolve().parent.parent
REGISTRY_DIR = REPO_DIR / "image-models"
COMFYUI_DIR = Path(os.environ.get("COMFYUI_DIR", REPO_DIR / "comfyui")).expanduser()
COMFYUI_URL = os.environ.get("COMFYUI_URL", "http://127.0.0.1:8188")
OUTPUT_DIR = REPO_DIR / "outputs"
WEBUI_URL = os.environ.get("WEBUI_URL", "http://localhost:3000")
IMAGE_STUDIO = REPO_DIR / "openwebui" / "image_studio.py"

# Workflow placeholders Open WebUI can fill per request, mapped to its node types.
# Image Studio always sends a negative prompt (possibly ""), so mapping it is safe.
WEBUI_NODE_TYPES = {
    "model": "model",
    "prompt": "prompt",
    "negative": "negative_prompt",
    "width": "width",
    "height": "height",
    "steps": "steps",
    "seed": "seed",
}


def load_model(name: str) -> dict[str, Any]:
    path = REGISTRY_DIR / f"{name}.json"
    if not path.is_file():
        available = ", ".join(sorted(p.stem for p in REGISTRY_DIR.glob("*.json")))
        sys.exit(f"Unknown image model '{name}'. Available: {available}")
    return json.loads(path.read_text())


def load_workflow(model: dict[str, Any]) -> dict[str, Any]:
    return json.loads((REGISTRY_DIR / "workflows" / f"{model['workflow']}.json").read_text())


def fill_workflow(workflow: dict[str, Any], params: dict[str, Any]) -> dict[str, Any]:
    """Replace every "$name" input value with params[name]."""
    for node_id, node in workflow.items():
        for key, value in node["inputs"].items():
            if isinstance(value, str) and value.startswith("$"):
                name = value[1:]
                if name not in params:
                    sys.exit(f"Workflow node {node_id}.{key} needs '{name}' but no value was given")
                node["inputs"][key] = params[name]
    return workflow


def file_name(entry: dict[str, str]) -> str:
    return Path(urllib.parse.urlparse(entry["url"]).path).name


def cmd_list(_: argparse.Namespace) -> None:
    for path in sorted(REGISTRY_DIR.glob("*.json")):
        print(f"{path.stem:20} {json.loads(path.read_text()).get('description', '')}")


def cmd_pull(args: argparse.Namespace) -> None:
    model = load_model(args.model)
    for entry in model["files"]:
        dest = COMFYUI_DIR / "models" / entry["dir"] / file_name(entry)
        if dest.exists():
            print(f"exists   {dest}")
            continue
        if args.dry_run:
            request = urllib.request.Request(entry["url"], method="HEAD")
            with urllib.request.urlopen(request) as resp:
                size = int(resp.headers.get("Content-Length", 0))
            print(f"would download {size / 1e9:.2f}GB -> {dest}")
            continue
        dest.parent.mkdir(parents=True, exist_ok=True)
        partial = dest.with_name(dest.name + ".part")
        print(f"download {entry['url']}")
        with urllib.request.urlopen(entry["url"]) as resp, partial.open("wb") as out:
            total = int(resp.headers.get("Content-Length", 0))
            done = 0
            while chunk := resp.read(1 << 20):
                out.write(chunk)
                done += len(chunk)
                if total:
                    print(f"\r  {done / 1e9:.2f}/{total / 1e9:.2f}GB", end="", flush=True)
        print()
        partial.rename(dest)
        print(f"saved    {dest}")


def comfy_request(path: str, payload: dict[str, Any] | None = None) -> Any:
    data = json.dumps(payload).encode() if payload is not None else None
    request = urllib.request.Request(
        COMFYUI_URL + path, data=data, headers={"Content-Type": "application/json"}
    )
    try:
        with urllib.request.urlopen(request) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        sys.exit(f"ComfyUI error {e.code}: {e.read().decode()}")
    except urllib.error.URLError as e:
        sys.exit(f"Cannot reach ComfyUI at {COMFYUI_URL} ({e.reason}). Is it running? (make comfyui)")


def cmd_gen(args: argparse.Namespace) -> None:
    model = load_model(args.model)
    params: dict[str, Any] = {**model["defaults"], "prompt": args.prompt}
    for item in args.set:
        key, _, value = item.partition("=")
        try:
            params[key] = json.loads(value)  # numbers and booleans keep their type
        except json.JSONDecodeError:
            params[key] = value
    if args.size:
        width, _, height = args.size.partition("x")
        params["width"], params["height"] = int(width), int(height)
    for key in ("steps", "cfg", "negative"):
        if getattr(args, key) is not None:
            params[key] = getattr(args, key)
    params["seed"] = args.seed if args.seed is not None else random.randint(0, 2**32 - 1)

    workflow = fill_workflow(load_workflow(model), params)
    if args.dry_run:
        print(json.dumps(workflow, indent=2))
        return

    prompt_id = comfy_request("/prompt", {"prompt": workflow})["prompt_id"]
    print(f"queued {prompt_id} (seed {params['seed']}, {params['steps']} steps)")
    started = time.monotonic()
    while True:
        history = comfy_request(f"/history/{prompt_id}").get(prompt_id)
        if history and history.get("status", {}).get("completed"):
            break
        if history and history.get("status", {}).get("status_str") == "error":
            sys.exit(f"Generation failed: {json.dumps(history['status'].get('messages', []))}")
        if time.monotonic() - started > args.timeout:
            sys.exit(f"Timed out after {args.timeout}s waiting for {prompt_id}")
        time.sleep(1)

    OUTPUT_DIR.mkdir(exist_ok=True)
    for output in history["outputs"].values():
        for image in output.get("images", []):
            query = urllib.parse.urlencode(
                {"filename": image["filename"], "subfolder": image["subfolder"], "type": image["type"]}
            )
            dest = OUTPUT_DIR / image["filename"]
            with urllib.request.urlopen(f"{COMFYUI_URL}/view?{query}") as resp:
                dest.write_bytes(resp.read())
            print(f"saved {dest} ({time.monotonic() - started:.0f}s)")


def cmd_webui_env(args: argparse.Namespace) -> None:
    """Write comfyui/webui.env so Open WebUI's image button uses this model's workflow."""
    model = load_model(args.model)
    template = load_workflow(model)
    nodes = []
    for node_id, node in template.items():
        for key, value in node["inputs"].items():
            if isinstance(value, str) and value[1:] in WEBUI_NODE_TYPES:
                nodes.append({"type": WEBUI_NODE_TYPES[value[1:]], "key": key, "node_ids": [node_id]})
    defaults = model["defaults"]
    workflow = fill_workflow(template, {**defaults, "prompt": "", "seed": 0})
    env = {
        "IMAGE_GENERATION_MODEL": defaults["model"],
        "IMAGE_SIZE": f"{defaults['width']}x{defaults['height']}",
        "IMAGE_STEPS": str(defaults["steps"]),
        "COMFYUI_WORKFLOW": json.dumps(workflow, separators=(",", ":")),
        "COMFYUI_WORKFLOW_NODES": json.dumps(nodes, separators=(",", ":")),
    }
    dest = COMFYUI_DIR / "webui.env"
    dest.parent.mkdir(parents=True, exist_ok=True)
    # Single quotes keep Compose from interpolating anything inside the JSON.
    dest.write_text("".join(f"{key}='{value}'\n" for key, value in env.items()))
    print(f"wrote {dest} for {args.model}")


def webui_request(path: str, payload: dict[str, Any], token: str | None = None) -> Any:
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    request = urllib.request.Request(WEBUI_URL + path, data=json.dumps(payload).encode(), headers=headers)
    with urllib.request.urlopen(request) as resp:
        return json.loads(resp.read())


def cmd_webui_install(_: argparse.Namespace) -> None:
    """Create or update the Image Studio pipe in Open WebUI and make sure it's enabled."""
    # With WEBUI_AUTH=false, Open WebUI signs everyone in as this built-in admin
    token = webui_request("/api/v1/auths/signin", {"email": "admin@localhost", "password": "admin"})["token"]
    form = {
        "id": "image_studio",
        "name": "Image Studio",
        "content": IMAGE_STUDIO.read_text(),
        "meta": {"description": "Rewrite a request into a ComfyUI prompt, then generate the image"},
    }
    try:
        function = webui_request("/api/v1/functions/id/image_studio/update", form, token)
    except urllib.error.HTTPError as e:
        if e.code not in (400, 401, 404):
            sys.exit(f"Open WebUI error {e.code}: {e.read().decode()}")
        function = webui_request("/api/v1/functions/create", form, token)
    if not function.get("is_active"):
        webui_request("/api/v1/functions/id/image_studio/toggle", {}, token)
    print("Image Studio installed - pick it in the Web UI model dropdown")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("list", help="List image models").set_defaults(func=cmd_list)

    pull = sub.add_parser("pull", help="Download a model's files into comfyui/models")
    pull.add_argument("model")
    pull.add_argument("--dry-run", action="store_true", help="Show what would be downloaded (HEAD requests only)")
    pull.set_defaults(func=cmd_pull)

    gen = sub.add_parser("gen", help="Generate an image")
    gen.add_argument("model")
    gen.add_argument("prompt")
    gen.add_argument("--steps", type=int)
    gen.add_argument("--size", help="WIDTHxHEIGHT, e.g. 1024x768")
    gen.add_argument("--seed", type=int)
    gen.add_argument("--cfg", type=float)
    gen.add_argument("--negative")
    gen.add_argument("--set", action="append", default=[], metavar="KEY=VALUE", help="Override any workflow parameter")
    gen.add_argument("--timeout", type=int, default=1800, help="Seconds to wait for the image (default 1800)")
    gen.add_argument("--dry-run", action="store_true", help="Print the filled workflow instead of queueing it")
    gen.set_defaults(func=cmd_gen)

    webui = sub.add_parser("webui-env", help="Point Open WebUI's image generation at a model")
    webui.add_argument("model")
    webui.set_defaults(func=cmd_webui_env)

    sub.add_parser("webui-install", help="Install the Image Studio pipe into Open WebUI").set_defaults(
        func=cmd_webui_install
    )

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
