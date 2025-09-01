# Ollama Project

A Docker-based setup for running large language models locally using Ollama, with both command-line and web interfaces.

## What This Project Does

- **Run AI models locally** - No cloud dependencies, complete privacy
- **Multiple interfaces** - Command-line chat and web UI
- **Easy model switching** - Switch between different AI models instantly  
- **GPU acceleration** - Automatic NVIDIA GPU detection and usage
- **Cross-platform** - Works identically on Linux, macOS, and Windows
- **Simple commands** - Use `make` commands instead of complex Docker commands

## Quick Start

```bash
# First time setup
make first-time

# Start chatting
make chat

# Or use the web interface
make web
```

## Available Models

- **llama3.2:1b** - Fastest responses, CPU-friendly (default)
- **llama3.2:3b** - Balanced performance, better with GPU
- **llama3.2:11b** - Highest quality, requires GPU for good speed
- **codellama:7b** - Specialized for code generation, needs GPU  
- **mistral:7b** - Alternative general-purpose model, needs GPU

**CPU-Only Users:** The default 1B model works well on CPU. For better performance with larger models, GPU acceleration is recommended.

## Common Commands

```bash
make                    # Show all available commands
make setup              # Initial setup
make chat               # Start command-line chat
make web                # Show web UI URL (http://localhost:3000)
make switch llama3.2:1b # Switch to different model
make status             # Check service status
make clean              # Clean up containers
```

## Quick Model Switching

```bash
make fast      # Switch to fastest model (llama3.2:1b)
make balanced  # Switch to balanced model (llama3.2:3b)
make quality   # Switch to best quality (llama3.2:11b)
make code      # Switch to code-focused model
```

## Requirements

- **Docker** - Container runtime
- **Docker Compose** - Multi-container orchestration
- **Make** - Command runner (usually pre-installed on Linux/macOS)
- **8GB+ RAM** - For running models
- **GPU** (optional) - For acceleration:
  - **NVIDIA GPU** - Best support, automatic setup
  - **AMD GPU** - Experimental support, requires ROCm (Linux only)

## GPU Support

### NVIDIA GPU (Recommended)
- Automatic detection and setup
- Works on Linux, Windows, and macOS
- Best performance and stability
- Simply run `make setup` - GPU acceleration works out of the box

### AMD GPU (Experimental)
- Linux only (Ubuntu, Debian, Arch, CachyOS)
- Requires ROCm setup
- RX 6000/7000 series recommended
- Performance typically 10-30% lower than equivalent NVIDIA

**Why Linux-only?** AMD's ROCm platform (equivalent to NVIDIA's CUDA) has very limited Windows support and no macOS support. This is a limitation of AMD's GPU compute ecosystem, not this project.

```bash
# Setup AMD GPU support
make setup-amd

# Test configuration
make test-gpu
```

**For detailed AMD GPU setup and troubleshooting:** See [docs/AMD-GPU-SUPPORT.md](./docs/AMD-GPU-SUPPORT.md)

### CPU-Only
- Works on all systems without GPU
- Default 1B model is optimized for CPU performance
- No additional setup required

## Project Structure

```
ollama-docker/
├── README.md              # This file
├── Makefile               # Simple command interface
├── docker-compose.yml     # Docker services (NVIDIA/CPU)
├── docker-compose-amd.yml # Docker services (AMD GPU)
├── Dockerfile             # app container
├── main.py                # chat application
├── .env                   # Configuration file
├── pyproject.toml         # dependencies
├── uv.lock                # Dependency lock file
├── docs/
│   ├── INSTALLATION.md    # Detailed setup instructions
│   ├── USAGE.md           # Usage guide and examples
│   └── AMD-GPU-SUPPORT.md # AMD GPU setup guide
└── scripts/
    ├── setup.sh           # Setup automation
    ├── setup-amd.sh       # AMD GPU setup
    ├── model-manager.sh   # Model management
    └── cleanup.sh         # Cleanup utilities
```

## Interfaces

### Command Line Interface
- Interactive chat in terminal
- Direct API access
- Scriptable and automatable

### Web Interface
- Visual chat interface at http://localhost:3000
- Easy model switching
- Chat history
- File uploads and downloads

## Features

- **Privacy First** - All processing happens locally
- **No Internet Required** - Once models are downloaded
- **GPU Accelerated** - Automatic NVIDIA GPU detection
- **Multiple Models** - Easy switching between different AI models
- **Persistent Storage** - Models and conversations are saved
- **Easy Cleanup** - Simple commands to reset everything
- **Cross Platform** - Docker ensures identical behavior everywhere

## Getting Help

- Run `make` to see all available commands
- Check `docs/INSTALLATION.md` for setup issues
- Check `docs/USAGE.md` for examples and advanced usage
- View logs with `make logs`

## License

This project is open source. Ollama and the AI models have their own licenses.

## Contributing

1. Fork the repository
2. Make your changes
3. Test with `make setup` and `make chat`
4. Submit a pull request

---

**Next Steps:** See [INSTALLATION.md](./docs/INSTALLATION.md) for detailed setup instructions.
