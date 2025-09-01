# Installation Guide

This guide will help you set up the Ollama Project on your system.

## System Requirements

### Minimum Requirements
- **RAM:** 8GB (16GB recommended)
- **Storage:** 10GB free space (for models)
- **OS:** Linux, macOS, or Windows with WSL2

### GPU Requirements (Optional but Recommended)
- **NVIDIA GPU** with 4GB+ VRAM
- **NVIDIA drivers** installed and working
- **Docker with GPU support**

## Step-by-Step Installation

### 1. Install Docker

#### Linux (Ubuntu/Debian)
```bash
# Update package index
sudo apt update

# Install Docker
sudo apt install docker.io docker-compose-v2

# Add your user to docker group
sudo usermod -aG docker $USER

# Log out and back in, then test
docker --version
```

#### Linux (Arch/CachyOS)
```bash
# Install Docker
sudo pacman -S docker docker-compose

# Enable and start Docker
sudo systemctl enable docker
sudo systemctl start docker

# Add your user to docker group
sudo usermod -aG docker $USER

# Log out and back in
```

#### macOS
```bash
# Install Docker Desktop from:
# https://docs.docker.com/desktop/mac/install/

# Or with Homebrew:
brew install --cask docker
```

#### Windows
1. Install WSL2 first
2. Download Docker Desktop from https://docs.docker.com/desktop/windows/install/
3. Enable WSL2 integration in Docker Desktop settings

### 2. Install NVIDIA GPU Support (Optional)

If you have an NVIDIA GPU and want GPU acceleration:

#### Linux
```bash
# Install NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt update
sudo apt install nvidia-container-toolkit

# Configure Docker
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# Test GPU access
docker run --rm --gpus all nvidia/cuda:11.0.3-base-ubuntu20.04 nvidia-smi
```

#### macOS/Windows
GPU support is automatically handled by Docker Desktop if you have compatible hardware.

### 3. Clone or Download the Project

#### Option A: Download ZIP
1. Download the project as a ZIP file
2. Extract to your desired location
3. Open terminal in the project directory

#### Option B: Git Clone (if you have Git)
```bash
git clone <your-repo-url>
cd ollama-python-project
```

### 4. Verify Installation

Check that you have all required tools:

```bash
# Check Docker
docker --version
docker compose version

# Check Make (usually pre-installed)
make --version

# Check project files
ls -la
```

You should see these files:
- `Makefile`
- `docker-compose.yml`
- `Dockerfile`
- `main.py`
- `scripts/` directory

### 5. First Time Setup

Run the complete setup:

```bash
# Make scripts executable and run setup
make first-time
```

This will:
- Make all scripts executable
- Build the container
- Start all services
- Download the default model (llama3.2:3b)

**Note:** The first run will take several minutes as it downloads:
- Base Docker images (~3GB)
- The AI model (~2GB)

### 6. Verify Everything Works

```bash
# Check if services are running
make status

# Test the command-line interface
make chat

# Test the web interface (in a browser, go to http://localhost:3000)
make web
```

## Troubleshooting

### Docker Permission Issues
```bash
# If you get permission denied errors:
sudo usermod -aG docker $USER
# Then log out and back in

# Or temporarily use sudo:
sudo make setup
```

### GPU Not Detected
```bash
# Check if NVIDIA drivers are installed
nvidia-smi

# Check if Docker can access GPU
docker run --rm --gpus all nvidia/cuda:11.0.3-base-ubuntu20.04 nvidia-smi

# If GPU isn't working, the project will run on CPU (slower but still works)
```

### Port Already in Use
```bash
# If port 11434 or 3000 are in use:
docker compose down
sudo lsof -i :11434
sudo lsof -i :3000

# Kill the processes using those ports, then:
make start
```

### Not Enough Memory
```bash
# If you get out of memory errors:
# 1. Try a smaller model:
make switch llama3.2:1b

# 2. Or increase Docker memory limit in Docker Desktop settings
```

### Script Permission Issues
```bash
# If you get "permission denied" on scripts:
chmod +x scripts/*.sh

# Or use the make command:
make fix-permissions
```

### Models Not Loading
```bash
# Check available models
make list-models

# Manually pull a model
make pull llama3.2:3b

# Check Ollama logs
make logs
```

## Advanced Setup Options

### Custom Configuration

Edit the `.env` file to customize settings:

```bash
# Example .env file
OLLAMA_HOST=http://ollama:11434
OLLAMA_MODEL=llama3.2:3b
NVIDIA_VISIBLE_DEVICES=all
```

### Using Different Models

```bash
# See all available models at: https://ollama.com/library

# Popular options:
make switch llama3.2:1b      # Fastest
make switch llama3.2:11b     # Highest quality
make switch codellama:7b     # Code-focused
make switch mistral:7b       # Alternative model
```

### CPU-Only Setup

If you don't have an NVIDIA GPU or want to use CPU only:

1. The setup will automatically fall back to CPU
2. **Default model (llama3.2:1b) is optimized for CPU use** - expect 3-10 tokens/second
3. Performance expectations on CPU:
   - **llama3.2:1b**: Fast, responsive (recommended for CPU)
   - **llama3.2:3b**: Slower, but usable (1-3 tokens/second)  
   - **llama3.2:11b**: Very slow on CPU (not recommended)

```bash
# For CPU-only users, these models work well:
make switch llama3.2:1b    # Best for CPU (default)
make switch llama3.2:3b    # Acceptable on powerful CPUs
```

**CPU Performance Tip:** Close other resource-intensive applications while using larger models.

## Uninstallation

To completely remove the project:

```bash
# Stop and remove all containers, volumes, and images
make reset

# Remove project directory
cd ..
rm -rf ollama-python-project
```

## Getting Help

If you encounter issues:

1. Check the logs: `make logs`
2. Check service status: `make status`
3. Try restarting: `make restart`
4. For a clean start: `make clean && make setup`
5. For complete reset: `make reset`

## Next Steps

Once installation is complete, see [USAGE.md](./USAGE.md) for examples and detailed usage instructions.
