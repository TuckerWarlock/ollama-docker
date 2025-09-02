# Installation Guide

## Prerequisites

- **Docker & Docker Compose**
- **8GB+ RAM, 15GB disk space**
- **Microphone** (for voice features)

## 1. Install Docker

### Linux
```bash
# Ubuntu/Debian
sudo apt install docker.io docker-compose-v2
sudo usermod -aG docker $USER

# Arch/CachyOS  
sudo pacman -S docker docker-compose
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

### macOS/Windows
Install Docker Desktop from docker.com

**Important**: Log out and back in after adding yourself to docker group.

## 2. GPU Support (Optional)

### NVIDIA
```bash
# Install NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | sudo apt-key add -
echo "deb [arch=amd64] https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list" | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt update && sudo apt install nvidia-container-toolkit
sudo systemctl restart docker
```

### AMD (Linux only)
```bash
make setup-amd  # Automated AMD setup
```

## 3. Project Setup

```bash
# Clone or download project
git clone https://github.com/TuckerWarlock/ollama-docker
cd ollama-docker

# First-time setup (downloads ~11GB)
make setup
```

## 4. Voice Configuration

1. Open http://localhost:3000
2. Grant microphone permissions when prompted
3. Go to **Admin Settings → Audio**
4. Configure TTS:
   - **Text-to-Speech Engine**: OpenAI
   - **API Base URL**: `http://kokoro-tts:8880/v1`
   - **API Key**: `not-needed`
   - **TTS Model**: `kokoro`
   - **TTS Voice**: `af_bella` (or preferred voice)
5. Save settings

## 5. Verification

```bash
make status    # All services should be running
make web       # Opens http://localhost:3000
```

Test voice by clicking microphone icon and speaking.

## Troubleshooting

### Common Issues
- **Permission denied**: `sudo usermod -aG docker $USER` then logout/login
- **Port conflicts**: `docker compose down` then check ports with `lsof`
- **GPU not detected**: System falls back to CPU automatically
- **Voice not working**: Check browser permissions and microphone access

### Quick Fixes
```bash
make restart   # Restart all services
make clean     # Clean rebuild
make reset     # Nuclear option (re-downloads everything)
```

For detailed troubleshooting, check logs with `make logs`.
