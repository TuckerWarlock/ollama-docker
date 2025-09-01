#!/bin/bash

# Model Management Script for Ollama
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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

# Available models with descriptions
declare -A MODELS
MODELS[llama3.2:1b]="Fastest, smallest (1B params, ~1GB VRAM)"
MODELS[llama3.2:3b]="Balanced (3B params, ~2GB VRAM)"  
MODELS[llama3.2:11b]="Highest quality (11B params, ~6-7GB VRAM)"
MODELS[codellama:7b]="Code-focused (7B params, ~4GB VRAM)"
MODELS[mistral:7b]="Alternative option (7B params, ~4GB VRAM)"

# Current model from .env
get_current_model() {
    grep "^OLLAMA_MODEL=" .env 2>/dev/null | cut -d'=' -f2 || echo "llama3.2:3b"
}

# Update .env file with new model
set_model() {
    local model=$1
    if [[ -f .env ]]; then
        # Update existing line
        sed -i "s/^OLLAMA_MODEL=.*/OLLAMA_MODEL=${model}/" .env
    else
        # Create .env if it doesn't exist
        echo "OLLAMA_MODEL=${model}" > .env
    fi
    log_success "Set model to: $model"
}

# List available models
list_models() {
    local current=$(get_current_model)
    
    echo "Available models:"
    for model in "${!MODELS[@]}"; do
        if [[ "$model" == "$current" ]]; then
            echo -e "  ${GREEN}* $model${NC} - ${MODELS[$model]} (current)"
        else
            echo -e "    $model - ${MODELS[$model]}"
        fi
    done
}

# Pull a model
pull_model() {
    local model=$1
    log_info "Pulling model: $model"
    docker compose exec ollama ollama pull "$model"
    log_success "Model $model downloaded"
}

# Switch to a model (pull if needed, update .env, restart)
switch_model() {
    local model=$1
    
    # Check if model exists in our list
    if [[ -z "${MODELS[$model]}" ]]; then
        echo "Unknown model: $model"
        echo "Available models: ${!MODELS[*]}"
        exit 1
    fi
    
    log_info "Switching to model: $model"
    
    # Pull model if not already downloaded
    pull_model "$model"
    
    # Update .env file
    set_model "$model"
    
    # Restart python app to pick up new env
    log_info "Restarting Python app with new model..."
    docker compose restart python-app
    
    log_success "Successfully switched to $model"
    echo "Test it with: docker compose exec python-app uv run python main.py"
}

# Show current status
status() {
    local current=$(get_current_model)
    echo "Current model: $current"
    echo "Description: ${MODELS[$current]:-Unknown model}"
    
    # Check if containers are running
    if docker compose ps --services --filter status=running | grep -q ollama; then
        echo "Status: Running"
    else
        echo "Status: Stopped"
    fi
}

# Show help
show_help() {
    echo "Ollama Model Manager"
    echo
    echo "Usage: $0 {list|switch|pull|status|help} [MODEL]"
    echo
    echo "Commands:"
    echo "  list                    - Show available models"
    echo "  switch <model>         - Switch to a model (pulls if needed)"
    echo "  pull <model>           - Download a model"
    echo "  status                 - Show current model and status"  
    echo "  help                   - Show this help"
    echo
    echo "Examples:"
    echo "  $0 list"
    echo "  $0 switch llama3.2:1b"
    echo "  $0 pull codellama:7b"
}

# Main command handling
case "${1:-help}" in
    list)
        list_models
        ;;
    switch)
        if [[ -z "$2" ]]; then
            echo "Usage: $0 switch <model>"
            list_models
            exit 1
        fi
        switch_model "$2"
        ;;
    pull)
        if [[ -z "$2" ]]; then
            echo "Usage: $0 pull <model>"
            list_models
            exit 1
        fi
        pull_model "$2"
        ;;
    status)
        status
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
