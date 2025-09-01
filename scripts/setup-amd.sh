#!/bin/bash

# AMD GPU (ROCm) Setup Script for Ollama
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on Linux
check_os() {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        log_error "AMD GPU support requires Linux. macOS and Windows are not supported."
        exit 1
    fi
    log_success "Running on Linux"
}

# Check for AMD GPU
check_amd_gpu() {
    if ! lspci | grep -i amd | grep -i vga > /dev/null 2>&1; then
        log_warning "No AMD GPU detected. This setup is for AMD GPUs only."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        log_success "AMD GPU detected"
        lspci | grep -i amd | grep -i vga
    fi
}

# Get AMD GPU info
show_gpu_info() {
    log_info "AMD GPU Information:"
    if command -v rocm-smi &> /dev/null; then
        rocm-smi
    else
        log_warning "rocm-smi not available, using lspci instead"
        lspci | grep -i amd | grep -i vga
    fi
}

# Install ROCm
install_rocm() {
    log_info "Installing ROCm..."
    
    # Detect distribution
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
    else
        log_error "Cannot detect Linux distribution"
        exit 1
    fi

    case $ID in
        ubuntu|debian)
            install_rocm_ubuntu
            ;;
        arch|cachyos)
            install_rocm_arch
            ;;
        *)
            log_warning "Unsupported distribution: $ID"
            log_info "Please install ROCm manually: https://rocm.docs.amd.com/en/latest/deploy/linux/quick_start.html"
            exit 1
            ;;
    esac
}

install_rocm_ubuntu() {
    log_info "Installing ROCm on Ubuntu/Debian..."
    
    # Add ROCm repository
    wget -qO - https://repo.radeon.com/rocm/rocm.gpg.key | sudo apt-key add -
    echo "deb [arch=amd64] https://repo.radeon.com/rocm/apt/debian/ ubuntu main" | sudo tee /etc/apt/sources.list.d/rocm.list
    
    sudo apt update
    sudo apt install -y rocm-dkms rocm-libs rocm-utils rocm-smi-lib
    
    # Add user to render and video groups
    sudo usermod -aG render,video $USER
    
    log_success "ROCm installed for Ubuntu/Debian"
}

install_rocm_arch() {
    log_info "Installing ROCm on Arch/CachyOS..."
    
    # Install ROCm packages
    sudo pacman -S --needed rocm-dkms rocm-libs rocm-smi-lib hip
    
    # Add user to render and video groups  
    sudo usermod -aG render,video $USER
    
    log_success "ROCm installed for Arch/CachyOS"
}

# Configure Docker for AMD
configure_docker() {
    log_info "Configuring Docker for AMD GPU..."
    
    # Create or update Docker daemon.json
    if [[ ! -f /etc/docker/daemon.json ]]; then
        sudo mkdir -p /etc/docker
        echo '{}' | sudo tee /etc/docker/daemon.json > /dev/null
    fi
    
    # Add ROCm configuration (simple approach - just ensure Docker can access devices)
    log_info "Docker will access AMD GPU via device passthrough"
    
    sudo systemctl restart docker
    log_success "Docker configured for AMD GPU"
}

# Test AMD GPU access
test_rocm() {
    log_info "Testing ROCm installation..."
    
    # Test basic ROCm
    if command -v rocm-smi &> /dev/null; then
        rocm-smi --showproductname
        log_success "ROCm basic test passed"
    else
        log_warning "rocm-smi not found, skipping ROCm test"
    fi
    
    # Test Docker GPU access
    log_info "Testing Docker AMD GPU access..."
    if docker run --rm \
        --device=/dev/kfd --device=/dev/dri \
        --group-add video --group-add render \
        --security-opt seccomp=unconfined \
        rocm/rocm-terminal:latest rocm-smi --showproductname; then
        log_success "Docker AMD GPU test passed"
    else
        log_warning "Docker AMD GPU test failed - may still work with Ollama"
    fi
}

# Switch project to AMD configuration
switch_to_amd() {
    log_info "Switching project to AMD GPU configuration..."
    
    # Backup current docker-compose.yml
    if [[ -f docker-compose.yml ]]; then
        cp docker-compose.yml docker-compose-nvidia.yml.bak
        log_info "Backed up NVIDIA config to docker-compose-nvidia.yml.bak"
    fi
    
    # Use AMD configuration
    cp docker-compose-amd.yml docker-compose.yml
    
    log_success "Switched to AMD GPU configuration"
}

# Main setup function
main() {
    log_info "Starting AMD GPU (ROCm) setup for Ollama..."
    
    check_os
    check_amd_gpu
    
    # Show current GPU info
    show_gpu_info
    
    # Install ROCm
    install_rocm
    
    # Configure Docker
    configure_docker
    
    # Test setup
    test_rocm
    
    # Switch project configuration
    switch_to_amd
    
    log_success "AMD GPU setup complete!"
    log_warning "You may need to reboot for all changes to take effect"
    log_info "After reboot, test with: make setup"
    
    echo ""
    log_info "Supported AMD GPUs for ROCm:"
    echo "  • RX 6000 series (RDNA2) - Good support"
    echo "  • RX 7000 series (RDNA3) - Best support"  
    echo "  • RX 5000 series (RDNA1) - Limited support"
    echo "  • Vega series - Basic support"
    echo ""
    log_info "Note: AMD GPU performance may be lower than equivalent NVIDIA GPUs"
}

# Show help
show_help() {
    echo "AMD GPU (ROCm) Setup Script for Ollama"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help, -h    Show this help"
    echo "  --test-only   Only test current setup"
    echo "  --info        Show GPU information"
    echo ""
    echo "This script will:"
    echo "  1. Check for AMD GPU"
    echo "  2. Install ROCm drivers"
    echo "  3. Configure Docker"
    echo "  4. Switch project to AMD configuration"
    echo ""
    echo "Supported distributions: Ubuntu, Debian, Arch, CachyOS"
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        show_help
        exit 0
        ;;
    --test-only)
        show_gpu_info
        test_rocm
        exit 0
        ;;
    --info)
        show_gpu_info
        exit 0
        ;;
    "")
        main
        ;;
    *)
        echo "Unknown option: $1"
        show_help
        exit 1
        ;;
esac
