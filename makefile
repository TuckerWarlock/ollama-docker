# Ollama Python Project Makefile
# Usage: make <command> [arguments]

.PHONY: help setup start stop restart status logs chat clean reset
.PHONY: list-models pull switch
.DEFAULT_GOAL := help

# Colors for output
BLUE := \033[36m
GREEN := \033[32m  
YELLOW := \033[33m
RED := \033[31m
RESET := \033[0m

# Get additional arguments (for model names, etc.)
ARGS := $(filter-out $@,$(MAKECMDGOALS))

# Prevent make from treating arguments as targets
%:
	@:

help: ## Show this help message
	@echo -e "$(BLUE)Ollama Python Project$(RESET)"
	@echo "======================"
	@echo -e "$(GREEN)GPU Configuration:$(RESET)"
	@echo -e "  $(YELLOW)make setup-nvidia$(RESET)   - Configure for NVIDIA GPU (default)"
	@echo -e "  $(YELLOW)make setup-amd$(RESET)      - Configure for AMD GPU (ROCm)"
	@echo -e "  $(YELLOW)make test-gpu$(RESET)       - Test current GPU configuration"
	@echo ""
	@echo -e "$(GREEN)Setup & Control:$(RESET)"
	@echo -e "  $(YELLOW)make setup$(RESET)          - Initial setup (build, start, pull model)"
	@echo -e "  $(YELLOW)make start$(RESET)          - Start all services"
	@echo -e "  $(YELLOW)make stop$(RESET)           - Stop all services"  
	@echo -e "  $(YELLOW)make restart$(RESET)        - Restart all services"
	@echo -e "  $(YELLOW)make status$(RESET)         - Show service status"
	@echo -e "  $(YELLOW)make logs$(RESET)           - Show service logs"
	@echo ""
	@echo -e "$(GREEN)Model Management:$(RESET)"
	@echo -e "  $(YELLOW)make list-models$(RESET)    - List available models"
	@echo -e "  $(YELLOW)make switch MODEL$(RESET)   - Switch to a model (e.g., make switch llama3.2:1b)"
	@echo -e "  $(YELLOW)make pull MODEL$(RESET)     - Download a model"
	@echo ""
	@echo -e "$(GREEN)Usage:$(RESET)"
	@echo -e "$(GREEN)Usage:$(RESET)"
	@echo -e "  $(YELLOW)make chat$(RESET)           - Start interactive chat"
	@echo -e "  $(YELLOW)make web$(RESET)            - Open web UI (shows URL)"
	@echo ""
	@echo -e "$(GREEN)Model Shortcuts:$(RESET)"
	@echo -e "  $(YELLOW)make cpu$(RESET)            - CPU-optimized model (llama3.2:1b - default)"
	@echo -e "  $(YELLOW)make gpu$(RESET)            - GPU-optimized model (llama3.2:3b)"
	@echo -e "  $(YELLOW)make quality$(RESET)        - Best quality (llama3.2:11b - requires GPU)" 
	@echo -e "  $(YELLOW)make code$(RESET)           - Code-focused (codellama:7b - requires GPU)"
	@echo ""
	@echo -e "$(GREEN)Cleanup:$(RESET)"
	@echo -e "  $(YELLOW)make clean$(RESET)          - Clean up project containers/volumes"
	@echo -e "  $(YELLOW)make reset$(RESET)          - Full reset (with confirmation)"
	@echo ""
	@echo -e "$(GREEN)Examples:$(RESET)"
	@echo "  make setup"
	@echo "  make switch llama3.2:11b"
	@echo "  make chat"

# Setup & Control Commands
setup: ## Initial setup and start
	@echo -e "$(BLUE)Setting up Ollama Python Project...$(RESET)"
	@bash scripts/setup.sh setup

start: ## Start all services
	@echo -e "$(BLUE)Starting services...$(RESET)"
	@bash scripts/setup.sh start

stop: ## Stop all services
	@echo -e "$(BLUE)Stopping services...$(RESET)"
	@bash scripts/setup.sh stop

restart: ## Restart all services
	@echo -e "$(BLUE)Restarting services...$(RESET)"
	@docker compose restart

status: ## Show service status
	@echo -e "$(BLUE)Service Status:$(RESET)"
	@bash scripts/setup.sh status
	@echo ""
	@echo -e "$(BLUE)Current Model:$(RESET)"
	@bash scripts/model-manager.sh status

logs: ## Show service logs
	@bash scripts/setup.sh logs

# Model Management Commands  
list-models: ## List available models
	@bash scripts/model-manager.sh list

pull: ## Download a model (usage: make pull llama3.2:1b)
	@if [ -z "$(ARGS)" ]; then \
		echo -e "$(RED)Error: Please specify a model$(RESET)"; \
		echo "Usage: make pull <model>"; \
		echo "Example: make pull llama3.2:1b"; \
		bash scripts/model-manager.sh list; \
	else \
		bash scripts/model-manager.sh pull $(ARGS); \
	fi

switch: ## Switch to a model (usage: make switch llama3.2:11b) 
	@if [ -z "$(ARGS)" ]; then \
		echo -e "$(RED)Error: Please specify a model$(RESET)"; \
		echo "Usage: make switch <model>"; \
		echo "Example: make switch llama3.2:11b"; \
		bash scripts/model-manager.sh list; \
	else \
		bash scripts/model-manager.sh switch $(ARGS); \
	fi

# Usage Commands
chat: ## Start interactive chat
	@echo -e "$(BLUE)Starting interactive chat...$(RESET)"
	@echo -e "$(YELLOW)Tip: Type 'quit' to exit$(RESET)"
	@bash scripts/setup.sh interactive

web: ## Show web UI URL  
	@echo -e "$(BLUE)Web UI available at:$(RESET)"
	@echo -e "$(GREEN)http://localhost:3000$(RESET)"
	@echo ""
	@echo -e "$(YELLOW)Make sure services are running first (make start)$(RESET)"

# Cleanup Commands
clean: ## Clean up project containers and volumes
	@echo -e "$(BLUE)Cleaning up project...$(RESET)"
	@bash scripts/cleanup.sh quick

reset: ## Full reset with confirmation  
	@echo -e "$(YELLOW)This will completely reset your project!$(RESET)"
	@bash scripts/cleanup.sh reset

# Development shortcuts
dev: start chat ## Start services and immediately open chat

quick-switch: ## Quick switch to llama3.2:1b (fastest model)
	@bash scripts/model-manager.sh switch llama3.2:3b

# Check if required files exist
check-setup:
	@if [ ! -f "scripts/setup.sh" ] || [ ! -f "scripts/model-manager.sh" ] || [ ! -f "scripts/cleanup.sh" ]; then \
		echo "$(RED)Error: Required script files not found in scripts/ directory$(RESET)"; \
		exit 1; \
	fi

# Make scripts executable
fix-permissions: ## Make all scripts executable
	@echo "$(BLUE)Making scripts executable...$(RESET)"
	@chmod +x scripts/*.sh
	@echo "$(GREEN)Done!$(RESET)"

# Popular model shortcuts (for convenience)
default: ## Switch to default model (llama3.2:1b - CPU friendly)
	@bash scripts/model-manager.sh switch llama3.2:1b

cpu: ## Switch to CPU-optimized model (llama3.2:1b)
	@bash scripts/model-manager.sh switch llama3.2:1b

gpu: ## Switch to GPU-optimized model (llama3.2:3b)  
	@bash scripts/model-manager.sh switch llama3.2:3b

quality: ## Switch to highest quality model (llama3.2:11b - requires GPU)
	@bash scripts/model-manager.sh switch llama3.2:11b

code: ## Switch to code-focused model (codellama:7b - requires GPU)
	@bash scripts/model-manager.sh switch codellama:7b

# Legacy shortcuts (for backward compatibility)
fast: cpu ## Alias for cpu (backward compatibility)

balanced: gpu ## Alias for gpu (backward compatibility)

# GPU Configuration Commands
setup-nvidia: ## Configure for NVIDIA GPU (default)
	@echo -e "$(BLUE)Configuring for NVIDIA GPU...$(RESET)"
	@if [ -f docker-compose-amd.yml.bak ]; then \
		cp docker-compose-amd.yml.bak docker-compose.yml; \
		echo -e "$(GREEN)Switched to NVIDIA GPU configuration$(RESET)"; \
	else \
		echo -e "$(GREEN)Already using NVIDIA GPU configuration$(RESET)"; \
	fi

setup-amd: ## Configure for AMD GPU (ROCm)
	@echo -e "$(BLUE)Setting up AMD GPU support...$(RESET)"
	@chmod +x scripts/setup-amd.sh
	@bash scripts/setup-amd.sh
	@echo -e "$(GREEN)AMD GPU setup complete$(RESET)"

test-gpu: ## Test current GPU configuration
	@echo -e "$(BLUE)Testing GPU configuration...$(RESET)"
	@if grep -q "nvidia" docker-compose.yml 2>/dev/null; then \
		echo "Current config: NVIDIA GPU"; \
		docker run --rm --gpus all nvidia/cuda:11.0.3-base-ubuntu20.04 nvidia-smi 2>/dev/null || echo "NVIDIA GPU test failed"; \
	elif grep -q "rocm\|/dev/kfd" docker-compose.yml 2>/dev/null; then \
		echo "Current config: AMD GPU"; \
		bash scripts/setup-amd.sh --test-only; \
	else \
		echo "Current config: CPU-only"; \
	fi

demo: start web ## Start services and show web UI link
	@echo -e "$(GREEN)Demo ready! Services starting...$(RESET)"

# Show current configuration
config: ## Show current configuration
	@echo -e "$(BLUE)Current Configuration:$(RESET)"
	@echo "Model: $(grep OLLAMA_MODEL .env 2>/dev/null | cut -d'=' -f2 || echo 'Not set')"
	@echo "Host: $(grep OLLAMA_HOST .env 2>/dev/null | cut -d'=' -f2 || echo 'Not set')"
	@echo ""
	@bash scripts/setup.sh status 2>/dev/null || echo "Services not running"
