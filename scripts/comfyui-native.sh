#!/usr/bin/env bash

# Native ComfyUI install/run (macOS Apple Silicon or Linux without Docker GPU)
# Docker on macOS cannot use the Metal GPU, so ComfyUI runs on the host and
# the ollama-webui container reaches it at host.docker.internal:8188.
#
# Layout (gitignored):
#   comfyui/app      - ComfyUI checkout
#   comfyui/.venv    - Python environment
#   comfyui/models   - shared with the Docker comfyui service
#   comfyui/custom_nodes, comfyui/output, ...

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

COMFYUI_VERSION=${COMFYUI_VERSION:-v0.39.0}
COMFYUI_DIR="$(cd "$(dirname "$0")/.." && pwd)/comfyui"
APP_DIR="$COMFYUI_DIR/app"
VENV_DIR="$COMFYUI_DIR/.venv"
GGUF_DIR="$COMFYUI_DIR/custom_nodes/ComfyUI-GGUF"

install() {
    echo -e "${BLUE}Installing ComfyUI $COMFYUI_VERSION into $COMFYUI_DIR${NC}"
    mkdir -p "$COMFYUI_DIR/custom_nodes"

    if [ ! -d "$APP_DIR" ]; then
        git clone --depth 1 --branch "$COMFYUI_VERSION" https://github.com/comfyanonymous/ComfyUI.git "$APP_DIR"
    fi
    if [ ! -d "$GGUF_DIR" ]; then
        git clone --depth 1 https://github.com/city96/ComfyUI-GGUF.git "$GGUF_DIR"
    fi

    # PyTorch wheels lag new Python releases, so pin 3.12 when uv is available
    if command -v uv >/dev/null 2>&1; then
        [ -d "$VENV_DIR" ] || uv venv --python 3.12 "$VENV_DIR"
        uv pip install --python "$VENV_DIR/bin/python" -r "$APP_DIR/requirements.txt" -r "$GGUF_DIR/requirements.txt"
    else
        [ -d "$VENV_DIR" ] || python3 -m venv "$VENV_DIR"
        "$VENV_DIR/bin/pip" install -r "$APP_DIR/requirements.txt" -r "$GGUF_DIR/requirements.txt"
    fi

    echo -e "${GREEN}ComfyUI installed${NC}"
    echo -e "Next: ${YELLOW}make pull-image z-image-turbo${NC} then ${YELLOW}make comfyui${NC}"
}

run() {
    if [ ! -x "$VENV_DIR/bin/python" ]; then
        echo -e "${RED}Error: ComfyUI is not installed${NC}"
        echo "Run: make comfyui-install"
        exit 1
    fi
    echo -e "${BLUE}Starting ComfyUI at http://127.0.0.1:8188 (Ctrl+C to stop)${NC}"
    exec "$VENV_DIR/bin/python" "$APP_DIR/main.py" --base-directory "$COMFYUI_DIR" --listen 127.0.0.1 --port 8188
}

case "${1:-}" in
    install) install ;;
    run) run ;;
    *)
        echo "Usage: $0 {install|run}"
        exit 1
        ;;
esac
