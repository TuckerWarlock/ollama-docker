# GitHub Actions Workflows

This directory contains CI/CD workflows for the Ollama Docker project.

## docker-ci.yml

Automated testing workflow that validates Docker Compose configurations and service functionality.

### When It Runs

- **Pull requests** to main/develop branches
- **Pushes** to main branch
- **Manual dispatch** via GitHub UI
- **File changes** to: `docker-compose*.yml`, `scripts/`, `Makefile`, `.env`, `Dockerfile`

### What It Tests

**Service Integration:**
- Both NVIDIA and AMD Docker Compose configurations
- All services start correctly (Ollama, Web UI, TTS)
- API endpoints respond (ports 11434, 3000, 8880)
- Basic model pulling functionality

**Configuration Validation:**
- Docker Compose YAML syntax
- Makefile syntax and commands
- Script permissions and shell syntax
- Required documentation files exist

**Quality Checks:**
- Container logs for errors
- Service health endpoints
- Make commands execute without syntax errors

### Test Matrix

- **NVIDIA Config**: `docker-compose.yml` (CPU mode in CI)
- **AMD Config**: `docker-compose-amd.yml` (CPU mode in CI)

### CI Adaptations

- **GPU configs stripped** - CI runners don't have GPUs
- **Small model used** - `llama3.2:1b` for faster testing
- **Partial downloads** - Tests API without waiting for full model downloads
- **20-minute timeout** - Prevents hanging builds

### What It Doesn't Test

- GPU functionality (requires actual hardware)
- Audio/voice features (no microphone in CI)
- Browser interactions (headless environment)
- Full model performance (network/time constraints)

### Adding New Tests

To add tests for new components:

1. **Service health check**: Add API endpoint test to `test-docker-compose` job
2. **Configuration validation**: Add file validation to `validate-documentation` job  
3. **Script testing**: Add syntax check to `test-makefile` job

### Local Testing

Run similar tests locally:

```bash
# Validate compose files
docker compose config

# Test service startup
make setup
make status

# Test scripts
bash -n scripts/*.sh
```

### Debugging Failed Builds

Check the workflow logs for:
- Container startup errors in service logs
- API connectivity timeouts
- Missing files or permissions issues
- Docker Compose validation errors
