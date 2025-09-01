# AMD GPU Support

This document covers AMD GPU support for the Ollama Project using ROCm.

## Current Status

AMD GPU support is **experimental** and less mature than NVIDIA support. While it works, there are important limitations to understand.

### What Works
- ✅ RX 6000 series (RDNA2) - Good support
- ✅ RX 7000 series (RDNA3) - Best support
- ✅ Linux only (Ubuntu, Debian, Arch, CachyOS)
- ✅ All model sizes (1B, 3B, 11B)
- ✅ Automatic fallback to CPU if GPU fails

### Current Limitations
- ❌ **No macOS/Windows support** - ROCm is Linux-only (see explanation below)
- ⚠️ **Performance gap** - 10-30% slower than equivalent NVIDIA GPUs
- ⚠️ **Limited GPU support** - Older AMD GPUs may not work
- ⚠️ **Complex setup** - More involved than NVIDIA
- ⚠️ **Less stable** - May require troubleshooting

## Why Linux-Only?

AMD GPU support is limited to Linux because of **ROCm** (Radeon Open Compute) platform constraints:

### ROCm vs CUDA Platform Support
**AMD ROCm:**
- ✅ **Linux**: Full support (Ubuntu, RHEL, SLES, Arch, etc.)
- ⚠️ **Windows**: Very limited, experimental support only
- ❌ **macOS**: No support at all

**NVIDIA CUDA (for comparison):**
- ✅ **Linux**: Full support
- ✅ **Windows**: Full support 
- ✅ **macOS**: Full support

### Technical Reasons
**Why Windows is problematic:**
- ROCm on Windows is primarily for development/testing
- Missing many production features needed for AI workloads
- Driver integration issues with Windows GPU stack
- Most AI frameworks (including Ollama) don't support ROCm on Windows

**Why macOS isn't supported:**
- ROCm has zero macOS support from AMD
- Apple moved to M-series chips, reducing AMD GPU relevance
- Even Intel Macs with AMD GPUs cannot use ROCm

### When Might This Change?
**Unlikely in the near future** because:
- AMD would need significant investment in Windows ROCm
- Ollama would need to add Windows ROCm support
- Driver ecosystem maturity would take years
- AMD prioritizes Linux for enterprise/HPC markets

**Current reality:** For AI workloads on Windows/macOS with AMD GPUs, you're limited to CPU-only processing.

## Supported GPUs

### Recommended (Best Support)
- **RX 7900 XTX/XT** - Excellent
- **RX 7800 XT** - Excellent  
- **RX 7700 XT** - Excellent
- **RX 6900 XT** - Good
- **RX 6800 XT/6800** - Good
- **RX 6700 XT** - Good

### Limited Support
- **RX 5700 XT** - Basic support, may be slow
- **Vega 64/56** - Basic support, older architecture
- **RX 580/570** - Very limited, not recommended

### Not Supported
- **Integrated graphics** (APUs) - Not supported by ROCm
- **Pre-GCN cards** - Too old for ROCm

## Performance Expectations

### RX 7900 XTX (24GB)
- **llama3.2:1b**: 80-120 tokens/second
- **llama3.2:3b**: 50-80 tokens/second  
- **llama3.2:11b**: 15-25 tokens/second

### RX 6800 XT (16GB)
- **llama3.2:1b**: 60-90 tokens/second
- **llama3.2:3b**: 35-60 tokens/second
- **llama3.2:11b**: 10-18 tokens/second

### RX 6700 XT (12GB)
- **llama3.2:1b**: 50-70 tokens/second
- **llama3.2:3b**: 25-45 tokens/second
- **llama3.2:11b**: 8-15 tokens/second

*Note: Performance varies by system and is typically 10-30% lower than equivalent NVIDIA GPUs.*

## Setup Instructions

### Prerequisites
- **Linux system** (Ubuntu, Debian, Arch, CachyOS)
- **Supported AMD GPU** (see list above)
- **8GB+ system RAM**
- **Updated AMD drivers**

### Quick Setup
```bash
# Configure for AMD GPU
make setup-amd

# Test the configuration  
make test-gpu

# Start using
make setup
make chat
```

### Manual Setup Steps
If the automatic setup fails:

1. **Install ROCm drivers**
2. **Configure Docker device access**
3. **Switch Docker Compose configuration**
4. **Test GPU access**

Detailed steps are in the `scripts/setup-amd.sh` script.

## Troubleshooting

### GPU Not Detected
```bash
# Check if GPU is visible
lspci | grep -i amd

# Check ROCm installation
rocm-smi

# Check Docker access
make test-gpu
```

### Poor Performance
```bash
# Try smaller model
make cpu  # Use 1B model

# Check GPU utilization
watch rocm-smi

# Check memory usage
rocm-smi --showmemuse
```

### Docker Permission Issues
```bash
# Ensure user is in correct groups
groups $USER | grep -E "(render|video)"

# If missing groups:
sudo usermod -aG render,video $USER
# Then log out and back in
```

### Container Startup Issues
```bash
# Check container logs
make logs

# Try CPU-only mode temporarily
cp docker-compose-nvidia.yml.bak docker-compose.yml
make restart
```

## Switching Between GPU Types

### Switch to AMD GPU
```bash
make setup-amd
make restart
```

### Switch to NVIDIA GPU
```bash
make setup-nvidia  
make restart
```

### Switch to CPU-only
```bash
# Use original config without GPU
cp docker-compose-nvidia.yml.bak docker-compose.yml
# Edit to remove GPU sections
make restart
```

## Performance Optimization Tips

### For AMD GPUs
1. **Use latest drivers** - ROCm improves regularly
2. **Adequate cooling** - AMD GPUs can throttle under load
3. **Sufficient PSU** - High-end AMD GPUs use significant power
4. **Close other GPU apps** - Don't run games while using AI
5. **Use fast storage** - Models load from disk

### Model Selection for AMD
- **RX 7900 series**: Any model size works well
- **RX 6800 series**: 11B model may be slow, try 3B
- **RX 6700 series**: Stick with 1B or 3B models
- **Older GPUs**: Use 1B model for best experience

## Known Issues

### Current ROCm Limitations
- **Memory management** - Less efficient than CUDA
- **Driver stability** - May require reboots after updates  
- **Software ecosystem** - Fewer optimized applications
- **Documentation** - Less comprehensive than NVIDIA

### Workarounds
- **Restart if slow** - Reboot can resolve performance issues
- **Monitor temperatures** - Use `sensors` or `rocm-smi`
- **Keep drivers updated** - Check for ROCm updates monthly

## Getting Help

### Check Status
```bash
make status          # Service status
make test-gpu        # GPU test
rocm-smi            # GPU information
```

### Common Commands
```bash
make logs            # Check logs
make restart         # Restart services
make setup-amd       # Reconfigure AMD
```

### If Nothing Works
```bash
# Fall back to CPU
make cpu
# Or switch to NVIDIA if available
make setup-nvidia
```

## Future Improvements

AMD GPU support is actively improving:

- **Better ROCm versions** - Regular updates improve performance
- **More GPU support** - Newer AMD GPUs get better support
- **Ollama optimizations** - Ongoing improvements for AMD
- **Driver stability** - ROCm becomes more stable over time

## Conclusion

AMD GPU support works but requires patience and troubleshooting. NVIDIA GPUs currently provide a smoother experience, but AMD support is steadily improving.

**Recommendation**: If you have both AMD and NVIDIA GPUs, use NVIDIA for AI workloads. If you only have AMD, the setup is worth trying, especially with RX 6000/7000 series cards.
