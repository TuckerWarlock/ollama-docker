# Ollama Project

A Docker-based setup for running large language models locally with voice conversation capabilities.
Uses the WebUI from this project: https://github.com/open-webui/open-webui

## Features

- **Local AI models** - Complete privacy, no cloud dependencies
- **Voice conversations** - Speech-to-text and text-to-speech
- **Multiple interfaces** - Command-line, web UI, and voice
- **GPU acceleration** - Automatic NVIDIA/AMD GPU detection
- **67+ TTS voices** - Multiple languages via Kokoro TTS
- **Simple commands** - `make` commands instead of complex Docker

## Quick Start

```bash
make setup    # First-time setup (includes voice)
make web      # Open http://localhost:3000
```

Click the microphone icon for voice conversations.

## Available Models

- **llama3.2:1b** - Fastest, CPU-friendly (default)
- **llama3.2:3b** - Balanced performance
- **llama3.2:11b** - Highest quality (GPU recommended)
- **codellama:7b** - Code-focused
- **mistral:7b** - Alternative option

Switch models: `make switch llama3.2:3b`

## Requirements

- **Docker & Docker Compose**
- **8GB+ RAM**
- **Microphone** (for voice features)
- **GPU** (optional): NVIDIA (all platforms) or AMD (Linux only)

## Commands

```bash
make setup              # Initial setup
make web                # Web UI (http://localhost:3000)
make switch MODEL       # Change model
make fast/balanced/quality  # Quick model switches
make status/logs        # Check services
make clean/reset        # Cleanup
```

## Voice Setup

Voice features work automatically on most systems. For configuration:

1. Visit http://localhost:3000
2. Admin Settings → Audio
3. Configure TTS: API Base URL `http://kokoro-tts:8880/v1`, API Key `not-needed`

## Architecture

- **Ollama**: AI model runtime
- **Open WebUI**: Chat interface with Whisper STT
- **Kokoro TTS**: Local text-to-speech (67 voices)

## Documentation

- [INSTALLATION.md](./docs/INSTALLATION.md) - Setup instructions
- [USAGE.md](./docs/USAGE.md) - Usage examples
- [AMD-GPU-SUPPORT.md](./docs/AMD-GPU-SUPPORT.md) - AMD GPU setup

### Other Uses

- Added [continue config](./continue-config.yml) so these local models can be used as coding agents within VSCode. 
- See: https://marketplace.visualstudio.com/items?itemName=Continue.continue for more details.
