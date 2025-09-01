#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project name patterns to clean up
PROJECT_PATTERNS=("ollama_py" "ollama-py" "ollama_py_simple")

# Base images to preserve (large downloads)
PRESERVE_IMAGES=(
    "ollama/ollama:latest"
    "ghcr.io/open-webui/open-webui:main" 
    "nvidia/cuda:11.0.3-base-ubuntu20.04"
)

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

# Stop all containers matching project patterns
stop_project_containers() {
    log_info "Stopping project containers..."
    
    for pattern in "${PROJECT_PATTERNS[@]}"; do
        containers=$(docker ps -a --format "table {{.Names}}" | grep -E "(${pattern}|ollama|python-app|webui)" 2>/dev/null || true)
        if [[ -n "$containers" ]]; then
            echo "$containers" | while read container; do
                if [[ "$container" != "NAMES" ]]; then
                    log_info "Stopping container: $container"
                    docker stop "$container" 2>/dev/null || true
                    docker rm "$container" 2>/dev/null || true
                fi
            done
        fi
    done
    
    log_success "Project containers stopped and removed"
}

# Remove project-specific volumes
cleanup_volumes() {
    log_info "Cleaning up project volumes..."
    
    for pattern in "${PROJECT_PATTERNS[@]}"; do
        volumes=$(docker volume ls --format "table {{.Name}}" | grep "$pattern" 2>/dev/null || true)
        if [[ -n "$volumes" ]]; then
            echo "$volumes" | while read volume; do
                if [[ "$volume" != "NAME" ]]; then
                    log_info "Removing volume: $volume"
                    docker volume rm "$volume" 2>/dev/null || true
                fi
            done
        fi
    done
    
    log_success "Project volumes cleaned up"
}

# Remove project-specific networks
cleanup_networks() {
    log_info "Cleaning up project networks..."
    
    for pattern in "${PROJECT_PATTERNS[@]}"; do
        networks=$(docker network ls --format "table {{.Name}}" | grep "$pattern" 2>/dev/null || true)
        if [[ -n "$networks" ]]; then
            echo "$networks" | while read network; do
                if [[ "$network" != "NAME" ]]; then
                    log_info "Removing network: $network"
                    docker network rm "$network" 2>/dev/null || true
                fi
            done
        fi
    done
    
    log_success "Project networks cleaned up"
}

# Remove project-specific images (preserve base images)
cleanup_images() {
    log_info "Cleaning up project images (preserving base images)..."
    
    # Get all images
    all_images=$(docker images --format "table {{.Repository}}:{{.Tag}}" | tail -n +2)
    
    # Remove project-built images
    for pattern in "${PROJECT_PATTERNS[@]}"; do
        project_images=$(echo "$all_images" | grep "$pattern" 2>/dev/null || true)
        if [[ -n "$project_images" ]]; then
            echo "$project_images" | while read image; do
                log_info "Removing project image: $image"
                docker rmi "$image" 2>/dev/null || true
            done
        fi
    done
    
    log_success "Project images cleaned up (base images preserved)"
}

# Remove ALL images including base images (for complete reset)
cleanup_all_images() {
    log_info "Removing ALL images (including base images)..."
    
    # Get all images
    all_images=$(docker images --format "table {{.Repository}}:{{.Tag}}" | tail -n +2)
    
    # Remove project-built images first
    for pattern in "${PROJECT_PATTERNS[@]}"; do
        project_images=$(echo "$all_images" | grep "$pattern" 2>/dev/null || true)
        if [[ -n "$project_images" ]]; then
            echo "$project_images" | while read image; do
                log_info "Removing project image: $image"
                docker rmi "$image" 2>/dev/null || true
            done
        fi
    done
    
    # Remove base images
    for image in "${PRESERVE_IMAGES[@]}"; do
        if docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "$image" 2>/dev/null; then
            log_info "Removing base image: $image"
            docker rmi "$image" 2>/dev/null || true
        fi
    done
    
    # Remove any remaining project-related images
    docker image prune -a -f 2>/dev/null || true
    
    log_success "ALL images removed (system completely clean)"
}

# General Docker cleanup (safe)
general_cleanup() {
    log_info "Performing general Docker cleanup..."
    
    # Remove stopped containers
    docker container prune -f
    
    # Remove dangling images only (not tagged images)
    docker image prune -f
    
    # Remove unused networks
    docker network prune -f
    
    log_success "General cleanup completed"
}

# Show what will be preserved
show_preserved() {
    log_info "These base images will be preserved:"
    for image in "${PRESERVE_IMAGES[@]}"; do
        echo -e "  ${GREEN}✓${NC} $image"
    done
}

# Main cleanup function
full_cleanup() {
    log_info "Starting full project cleanup..."
    
    show_preserved
    
    # Stop any running docker compose
    log_info "Stopping docker compose services..."
    docker compose down --volumes 2>/dev/null || true
    
    stop_project_containers
    cleanup_volumes
    cleanup_networks
    cleanup_images
    general_cleanup
    
    log_success "Full cleanup completed!"
    
    # Show final state
    echo
    log_info "Final Docker state:"
    echo "Containers:"
    docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
    echo
    echo "Images:"
    docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}"
    echo
    echo "Volumes:"
    docker volume ls
    echo
    echo "Networks:"
    docker network ls
}

# Quick cleanup (containers and volumes only)
quick_cleanup() {
    log_info "Starting quick cleanup..."
    
    docker compose down --volumes 2>/dev/null || true
    stop_project_containers
    cleanup_volumes
    docker container prune -f
    
    log_success "Quick cleanup completed!"
}

# Reset for fresh start
reset_project() {
    log_warning "This will completely reset your project and remove ALL Docker images!"
    log_warning "Base images (ollama, web-ui, nvidia/cuda) will need to be re-downloaded (~8GB)"
    read -p "Are you sure? This will leave your system completely clean (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Stop any running docker compose
        log_info "Stopping docker compose services..."
        docker compose down --volumes 2>/dev/null || true
        
        stop_project_containers
        cleanup_volumes
        cleanup_networks
        cleanup_all_images  # Use the new function that removes everything
        general_cleanup
        
        log_success "Complete system reset finished!"
        log_info "All project containers, volumes, networks, and images removed"
        log_info "Next setup will re-download all base images (~8GB)"
        log_info "Run 'make first-time' to start fresh"
    else
        log_info "Reset cancelled"
    fi
}

# Show help
show_help() {
    echo "Docker Cleanup Script for Ollama Project"
    echo
    echo "Usage: $0 {full|quick|reset|help}"
    echo
    echo "Commands:"
    echo "  full    - Complete cleanup (containers, volumes, networks, project images)"
    echo "  quick   - Quick cleanup (containers and volumes only)"  
    echo "  reset   - Nuclear option: remove EVERYTHING including base images (~8GB)"
    echo "  help    - Show this help message"
    echo
    echo "Base images preserved by 'full' cleanup:"
    for image in "${PRESERVE_IMAGES[@]}"; do
        echo "  - $image"
    done
    echo
    echo "WARNING: 'reset' removes ALL images and leaves system completely clean!"
}

# Main script
case "${1:-full}" in
    full)
        full_cleanup
        ;;
    quick)
        quick_cleanup
        ;;
    reset)
        reset_project
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
