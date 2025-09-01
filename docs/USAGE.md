# Usage Guide

This guide covers everything you need to know about using the Ollama Python Project effectively.

## Quick Reference

```bash
make                    # Show all commands
make setup              # First-time setup
make chat               # Start command-line chat
make web                # Show web UI URL
make switch MODEL       # Change AI model
make status             # Check services
make clean              # Clean up
```

## Getting Started

### 1. Start the System

```bash
# If this is your first time:
make first-time

# If already set up:
make start
```

### 2. Choose Your Interface

You have two main ways to interact with the AI:

#### Command-Line Interface
```bash
make chat
```
- Direct terminal interaction
- Perfect for quick questions
- Scriptable and automatable
- No browser needed

#### Web Interface
```bash
make web
# Then open http://localhost:3000 in your browser
```
- Visual chat interface
- Chat history
- Easy model switching
- File uploads/downloads
- Better for longer conversations

## Model Management

### Understanding Models

Different models have different strengths:

| Model | Size | Speed | Quality | Best For | VRAM Usage |
|-------|------|--------|---------|----------|------------|
| llama3.2:1b | Small | Fastest | Good | Quick questions, fast responses | ~1GB |
| llama3.2:3b | Medium | Fast | Better | General use, balanced performance | ~2-3GB |
| llama3.2:11b | Large | Slower | Best | Complex tasks, detailed responses | ~6-7GB |
| codellama:7b | Medium | Fast | Code-focused | Programming, debugging | ~4GB |
| mistral:7b | Medium | Fast | Alternative | General use, different style | ~4GB |

### Switching Models

```bash
# Quick shortcuts
make fast      # Switch to llama3.2:1b (fastest)
make balanced  # Switch to llama3.2:3b (default)
make quality   # Switch to llama3.2:11b (best quality)
make code      # Switch to codellama:7b (for coding)

# Or specify any model
make switch llama3.2:1b
make switch mistral:7b

# See all available models
make list-models

# Download a model without switching
make pull llama3.2:11b
```

### Model Selection Guidelines

**For Quick Questions/Chat:**
```bash
make fast
make chat
```

**For Programming Help:**
```bash
make code
make chat
# Ask: "Write a Python function to sort a list"
```

**For Complex Analysis:**
```bash
make quality
make chat
# Ask: "Analyze this business proposal and suggest improvements"
```

## Command-Line Usage Examples

### Basic Conversations

```bash
make chat
# You: Hello, what can you help me with?
# Ollama: I can help with questions, writing, coding, analysis...

# You: Write a Python function to calculate fibonacci numbers
# Ollama: [Provides code example]

# You: quit
```

### Quick One-Off Questions

Instead of interactive mode, you can also use the API directly:

```bash
# Test a quick prompt
docker compose exec python-app uv run python -c "
from main import chat_with_ollama
print(chat_with_ollama('What is the capital of France?'))
"
```

## Web Interface Usage

### Accessing the Web UI

1. Make sure services are running: `make start`
2. Open browser to http://localhost:3000
3. You'll see a chat interface with your current model

### Web UI Features

- **Chat History**: All conversations are saved
- **Model Selection**: Click model name dropdown to switch
- **File Uploads**: Drag and drop documents to analyze
- **Export Chats**: Download conversation history
- **Multiple Conversations**: Create separate chat threads

### Web UI Tips

- Use **Ctrl+Enter** to send messages (instead of just Enter)
- **Clear Chat** button removes current conversation
- **Regenerate** button gets a new response to your last question
- **Stop Generation** if response is taking too long

## Advanced Usage

### Using Different Models for Different Tasks

```bash
# Start with coding model for development work
make code
make chat
# Ask programming questions...

# Switch to high-quality model for writing
make quality
make chat  
# Ask for writing help...

# Switch to fast model for quick lookups
make fast
make chat
# Ask simple questions...
```

### Automation and Scripting

You can integrate the AI into scripts:

```bash
#!/bin/bash
# Script to get AI help with error messages

ERROR_LOG=$1
if [ -z "$ERROR_LOG" ]; then
    echo "Usage: $0 <error_log_file>"
    exit 1
fi

# Make sure services are running
make start

# Get AI analysis of the error
docker compose exec python-app uv run python -c "
from main import chat_with_ollama
import sys
with open('$ERROR_LOG', 'r') as f:
    error_text = f.read()
response = chat_with_ollama(f'Analyze this error and suggest a fix: {error_text}')
print(response)
"
```

### Configuration Customization

Edit the `.env` file to change defaults:

```bash
# Current configuration
make config

# Edit configuration
nano .env

# Example customizations:
OLLAMA_MODEL=llama3.2:11b          # Change default model
OLLAMA_HOST=http://ollama:11434    # API endpoint
PYTHON_ENV=production              # Environment mode
```

## Common Use Cases

### 1. Code Review and Debugging

```bash
make code
make chat
```
Then ask:
- "Review this Python function for bugs: [paste code]"
- "Explain what this SQL query does: [paste SQL]"
- "How can I optimize this algorithm?"

### 2. Writing and Editing

```bash
make quality
make chat
```
Then ask:
- "Help me write a professional email about [topic]"
- "Improve this paragraph: [paste text]"
- "Create an outline for a presentation on [topic]"

### 3. Learning and Research

```bash
make balanced
make chat
```
Then ask:
- "Explain quantum computing in simple terms"
- "What are the pros and cons of different database types?"
- "Help me understand this concept: [topic]"

### 4. Quick Factual Questions

```bash
make fast
make chat
```
Then ask:
- "What's the syntax for a Python list comprehension?"
- "Convert 100 fahrenheit to celsius"
- "What's the population of Tokyo?"

## Performance Optimization

### Choosing the Right Model

**For Speed** (quick responses):
```bash
make fast    # llama3.2:1b - fastest responses
```

**For Balance** (good speed + quality):
```bash
make balanced    # llama3.2:3b - default choice
```

**For Quality** (best responses):
```bash
make quality    # llama3.2:11b - highest quality
```

### Managing Resources

**Monitor GPU usage:**
```bash
# In another terminal
watch nvidia-smi
```

**Check system resources:**
```bash
make logs    # Check for memory issues
make status  # Check service health
```

**If running low on memory:**
```bash
make switch llama3.2:1b    # Use smaller model
make restart               # Restart services
```

## Troubleshooting Usage Issues

### Model Not Responding

```bash
# Check if model is loaded
make status
make logs

# Try restarting
make restart

# Switch to a different model
make switch llama3.2:3b
```

### Slow Responses

```bash
# Switch to faster model
make fast

# Check GPU usage
nvidia-smi

# Restart services to free memory
make restart
```

### Web Interface Not Loading

```bash
# Check if services are running
make status

# Check the URL
make web

# Restart web service
docker compose restart ollama-webui
```

### Connection Errors

```bash
# Check service logs
make logs

# Restart everything
make restart

# Check if ports are available
sudo lsof -i :11434
sudo lsof -i :3000
```

## Best Practices

### 1. Model Selection Strategy

- **Start with balanced** (`make balanced`) for most tasks
- **Switch to fast** (`make fast`) for quick questions
- **Use quality** (`make quality`) for important/complex work
- **Use code** (`make code`) specifically for programming tasks

### 2. Resource Management

- Monitor GPU memory usage with `nvidia-smi`
- Use `make status` to check service health
- Restart services if they become unresponsive
- Use smaller models if running low on resources

### 3. Conversation Tips

**Good prompts:**
- Be specific: "Write a Python function that takes a list and returns unique items"
- Provide context: "I'm building a web app and need to..."
- Ask for explanations: "Explain how this code works step by step"

**Less effective prompts:**
- Too vague: "Help me code"
- No context: "Fix this" (without showing what's broken)
- Overly complex: Multiple unrelated questions in one prompt

### 4. Workflow Optimization

```bash
# Morning setup
make start

# For development work
make code

# For writing/research
make quality

# Quick questions throughout day
make fast

# End of day cleanup (optional)
make stop
```

## Integration Examples

### With IDEs and Editors

You can create custom commands in your IDE:

**VS Code Task:**
```json
{
    "label": "Ask AI",
    "type": "shell", 
    "command": "make chat",
    "group": "build"
}
```

**Vim/Neovim:**
```vim
command! AskAI !make chat
```

### With Shell Scripts

```bash
# ~/.bashrc or ~/.zshrc
alias ask="make -C /path/to/ollama-project chat"
alias ai-code="make -C /path/to/ollama-project code && make -C /path/to/ollama-project chat"
```

## Getting Help

If you need assistance:

1. **Check status:** `make status`
2. **View logs:** `make logs` 
3. **Restart services:** `make restart`
4. **Check configuration:** `make config`
5. **Clean restart:** `make clean && make setup`
6. **Full reset:** `make reset`

For more help, see the troubleshooting section in [INSTALLATION.md](./INSTALLATION.md).
