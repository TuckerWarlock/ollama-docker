# ComfyUI + ComfyUI-GGUF for NVIDIA GPUs (used by docker-compose.comfyui-gpu.yml)
# RTX 50xx (Blackwell) needs CUDA 12.8+: build with
#   --build-arg BASE_IMAGE=pytorch/pytorch:2.14.0-cuda13.0-cudnn9-runtime
ARG BASE_IMAGE=pytorch/pytorch:2.14.0-cuda12.6-cudnn9-runtime
FROM ${BASE_IMAGE}

ARG COMFYUI_VERSION=v0.39.0

RUN apt-get update && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch ${COMFYUI_VERSION} https://github.com/comfyanonymous/ComfyUI.git /opt/ComfyUI \
    && git clone --depth 1 https://github.com/city96/ComfyUI-GGUF.git /data/custom_nodes/ComfyUI-GGUF \
    && pip install --no-cache-dir -r /opt/ComfyUI/requirements.txt -r /data/custom_nodes/ComfyUI-GGUF/requirements.txt

# Models and output are bind-mounted from ./comfyui (shared with the native install)
WORKDIR /opt/ComfyUI
EXPOSE 8188
CMD ["python", "main.py", "--base-directory", "/data", "--listen", "0.0.0.0", "--port", "8188"]
