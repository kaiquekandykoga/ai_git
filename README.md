# AI Git

AI‑powered Git using Open Models

## Usage

#### Requirements

- Jan AI or Ollama running locally (Jan AI is default)

#### Install

```bash
gem install ai_git
```

#### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `AI_GIT_AI_PROVIDER` | AI provider: `jan` or `ollama` | `jan` |
| `AI_GIT_MODEL_NAME` | Model name (overrides provider default) | Provider-specific |
| `AI_GIT_BASE_URL` | Base URL (overrides provider default) | Provider-specific |

##### Provider Defaults

| Provider | Default Model | Base URL | Reference |
|----------|---------------|---------|-----------|
| `jan` (default) | Jan-v3.5-4B-Q4_K_XL | http://127.0.0.1:1337 | https://jan.ai |
| `ollama` | gemma4:e4b | http://localhost:11434 | https://ollama.com |

##### Examples

```bash
# Use Jan AI (default)
export AI_GIT_AI_PROVIDER=jan

# Use Ollama with custom model
export AI_GIT_AI_PROVIDER=ollama
export AI_GIT_MODEL_NAME=llama3
```

#### Run

```bash
git add <files>
ai_git
```

#### Subcommands

| Subcommand | Description |
|------------|-------------|
| `ai_git` | Default - generates commit message, commits, and pushes staged files |
| `ai_git review` | Review the stagged files (experimental) |

## Development

```bash
gem build ai_git.gemspec
gem install ./ai_git-0.0.0.gem
gem push ai_git-0.0.0.gem  # publish to RubyGems
```
