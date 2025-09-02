# Usage Guide

This guide covers everything you need to know about using the Ollama Project effectively.
## Quick Commands

```bash
make                    # Show all commands
make web                    # Open web interface
make switch MODEL           # Change AI model  
make fast/balanced/quality  # Quick model switches
make status                 # Check services
```

## Interfaces

### Voice Conversations
1. Visit http://localhost:3000
2. Click microphone icon
3. Speak naturally
4. AI responds with voice

### Web Chat
- Text-based chat at http://localhost:3000
- File uploads and chat history
- Model switching via dropdown

### Command Line
```bash
make chat  # Terminal-based interaction
```

## Model Selection

| Model | Best For | Speed | Resource Use |
|-------|----------|--------|--------------|
| llama3.2:1b | Quick questions, real-time voice | Fastest | Low (CPU-friendly) |
| llama3.2:3b | General conversation | Balanced | Medium |
| llama3.2:11b | Complex topics | Slower | High (GPU needed) |
| codellama:7b | Programming help | Medium | Medium (GPU preferred) |

```bash
make fast      # llama3.2:1b
make balanced  # llama3.2:3b (default)
make quality   # llama3.2:11b
make code      # codellama:7b
```

## Voice Features

### TTS Voices
Choose from 67+ voices in Admin Settings → Audio:

**Popular English:**
- `af_bella` - Warm, natural
- `af_alloy` - Professional
- `af_heart` - Expressive

**Other Languages:**
- `ja_*` - Japanese voices
- `zh_*` - Chinese voices
- `ko_*` - Korean voices

### Voice Tips
- Speak clearly and pause between thoughts
- Enable "Auto-playback" for automatic responses
- Use natural, conversational language
- Grant browser microphone permissions when prompted

## Common Workflows

### Learning Session
```bash
make quality  # Best explanations
# Voice: "Explain machine learning basics"
# Follow up with related questions
```

### Coding Help
```bash
make code     # Programming-focused model  
# Voice: "Help debug this Python function"
# Paste code, ask voice questions about it
```

### Quick Q&A
```bash
make fast     # Fastest responses
# Voice: "What's the weather like today?"
# Good for rapid back-and-forth
```

## Configuration

### Web Interface Settings
- **Model selection**: Dropdown in web UI
- **Voice settings**: Admin Settings → Audio
- **Chat history**: Automatically saved

### Environment Variables
Edit `.env` file for defaults:
```bash
OLLAMA_MODEL=llama3.2:3b
OLLAMA_HOST=http://ollama:11434
```

## Maintenance

```bash
make status    # Check all services
make logs      # View service logs
make restart   # Restart everything
make clean     # Remove containers, volumes, networks
```

For installation issues, see [INSTALLATION.md](./INSTALLATION.md).
