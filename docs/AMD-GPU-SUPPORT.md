# AMD GPU Support

AMD GPU support for Ollama using ROCm. **Linux only** - ROCm has no macOS/Windows support.

## Status

**What Works:**
- RX 6000/7000 series (RDNA2/3)
- Linux distributions: Ubuntu, Debian, Arch, CachyOS
- All model sizes with automatic CPU fallback

**Limitations:**
- **Linux only** (ROCm platform limitation)
- 10-30% slower than equivalent NVIDIA GPUs
- More complex setup than NVIDIA
- Limited older GPU support

## Supported GPUs

### Recommended
- **RX 7900 XTX/XT** - Best performance
- **RX 7800/7700 XT** - Excellent support
- **RX 6900/6800/6700 XT** - Good support

### Limited Support
- **RX 5700 XT, Vega 64/56** - Basic support
- **Integrated/APU graphics** - Not supported

## Performance Expectations

| GPU | llama3.2:1b | llama3.2:3b | llama3.2:11b |
|-----|-------------|-------------|--------------|
| RX 7900 XTX | 80-120 tok/s | 50-80 tok/s | 15-25 tok/s |
| RX 6800 XT | 60-90 tok/s | 35-60 tok/s | 10-18 tok/s |
| RX 6700 XT | 50-70 tok/s | 25-45 tok/s | 8-15 tok/s |

## Setup

### Automated Setup
```bash
make setup-amd    # Handles ROCm installation and configuration
make test-gpu     # Verify setup
make setup        # Start services
```

### Manual Steps (if automated fails)

1. **Install ROCm**
```bash
# Ubuntu/Debian
wget -qO - https://repo.radeon.com/rocm/rocm.gpg.key | sudo apt-key add -
echo "deb [arch=amd64] https://repo.radeon.com/rocm/apt/debian/ ubuntu main" | sudo tee /etc/apt/sources.list.d/rocm.list
sudo apt update && sudo apt install rocm-dkms rocm-libs rocm-smi-lib

# Arch/CachyOS
sudo pacman -S rocm-dkms rocm-libs rocm-smi-lib hip
```

2. **Configure User Groups**
```bash
sudo usermod -aG render,video $USER
# Log out and back in
```

3. **Switch Project Configuration**
```bash
# Backup NVIDIA config
cp docker-compose.yml docker-compose-nvidia.yml.bak

# Use AMD config
cp docker-compose-amd.yml docker-compose.yml
```

## Troubleshooting

### GPU Not Detected
```bash
lspci | grep -i amd     # Check GPU presence
rocm-smi               # Check ROCm installation
make test-gpu          # Test Docker access
```

### Poor Performance
```bash
make fast              # Use smaller model
rocm-smi --showmemuse  # Check GPU memory
```

### Service Issues
```bash
make logs              # Check container logs
make restart           # Restart services
```

### Quick Fixes
- **Reboot** after ROCm installation
- **Check groups**: `groups $USER` should include render,video
- **Try CPU mode**: `make switch llama3.2:1b` if GPU fails

## Model Recommendations

- **RX 7900 series**: Any model size works
- **RX 6800 series**: Use 1B-3B models for best experience  
- **RX 6700 series**: Stick with 1B model for smooth operation
- **Older GPUs**: Use 1B model only

## Switching GPU Types

```bash
# Switch to AMD
make setup-amd && make restart

# Switch back to NVIDIA  
cp docker-compose-nvidia.yml.bak docker-compose.yml && make restart

# CPU-only mode
# Edit docker-compose.yml to remove GPU sections
```

## Voice Features

Voice conversation features (speech-to-text and text-to-speech) work identically on AMD and NVIDIA systems since they run on CPU.
