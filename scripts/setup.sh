#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
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

# Check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        log_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    log_success "Docker is running"
}

# Check if NVIDIA runtime is available
check_nvidia() {
    if ! docker run --rm --gpus all nvidia/cuda:11.0.3-base-ubuntu20.04 nvidia-smi > /dev/null 2>&1; then
        log_warning "NVIDIA GPU support not detected. Running CPU-only mode."
        return 1
    fi
    log_success "NVIDIA GPU support detected"
    return 0
}

# Setup function
setup() {
    log_info "Setting up Ollama Project..."
    
    check_docker
    
    # Build and start services
    log_info "Building and starting services..."
    docker compose up -d --build
    
    # Wait for Ollama to be ready
    log_info "Waiting for Ollama to be ready..."
    sleep 10
    
    # Pull the model
    log_info "Pulling Llama 3.2 3B model..."
    docker compose exec ollama ollama pull llama3.2:3b
    
    log_success "Setup complete!"
    log_info "Services running:"
    log_info "  - Ollama API: http://localhost:11434"
    log_info "  - Web UI: http://localhost:3000"
    log_info ""
    log_info "To interact with your app:"
    log_info "  docker-compose exec python-app main.py"
}

# Start function
start() {
    log_info "Starting services..."
    docker compose up -d
    log_success "Services started"
}

# Stop function
stop() {
    log_info "Stopping services..."
    docker compose down
    log_success "Services stopped"
}

# Logs function
logs() {
    docker compose logs -f
}

# Status function
status() {
    docker compose ps
}

# Interactive app
interactive() {
    log_info "Starting interactive app..."
    docker compose exec python-app uv run main.py
}

# Help function
help() {
    echo "Usage: $0 {setup|start|stop|logs|status|interactive|help}"
    echo ""
    echo "Commands:"
    echo "  setup       - Initial setup (build, start, pull model)"
    echo "  start       - Start all services"
    echo "  stop        - Stop all services"
    echo "  logs        - Show logs from all services"
    echo "  status      - Show service status"
    echo "  interactive - Run interactive app"
    echo "  help        - Show this help message"
}

# Main script
case "${1:-}" in
    setup)
        setup
        ;;
    start)
        start
        ;;
    stop)
        stop
        ;;
    logs)
        logs
        ;;
    status)
        status
        ;;
    interactive)
        interactive
        ;;
    help|--help|-h)
        help
        ;;
    *)
        log_error "Unknown command: ${1:-}"
        help
        exit 1
        ;;
esac
