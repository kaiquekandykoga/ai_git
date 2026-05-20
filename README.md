# AI Git

AI‑powered Git using Open Models

## Usage

#### Requirements

- A supported provider reachable from your machine (Jan AI is default — runs locally)

#### Install

```bash
gem install ai_git
```

#### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `AI_GIT_AI_PROVIDER` | AI provider (see table below) | `jan` |
| `AI_GIT_MODEL_NAME` | Model name (overrides provider default) | Provider-specific |
| `AI_GIT_BASE_URL` | Base URL (overrides provider default) | Provider-specific |
| `AI_GIT_API_KEY` | API key for hosted providers (`claude`, `grok`). Falls back to `ANTHROPIC_API_KEY` for `claude`. | — |

##### Provider Defaults

| Provider | Default Model | Base URL | Reference |
|----------|---------------|---------|-----------|
| `jan` (default) | Jan-v3.5-4B-Q4_K_XL | http://127.0.0.1:1337 | https://jan.ai |
| `ollama` | gemma4:e4b | http://localhost:11434 | https://ollama.com |
| `claude` | claude-opus-4-7 | https://api.anthropic.com | https://docs.anthropic.com |
| `grok` | grok-4 | https://api.x.ai | https://docs.x.ai |
| `llama_cpp` | default | http://127.0.0.1:8080 | https://github.com/ggml-org/llama.cpp |
| `unsloth` | unsloth/gemma-3-4b-it | http://127.0.0.1:8000 | https://github.com/unslothai/unsloth |

Local providers (`jan`, `ollama`, `llama_cpp`, `unsloth`) require no API key. Hosted providers (`claude`, `grok`) need `AI_GIT_API_KEY`.

##### Examples

```bash
# Use Jan AI (default)
export AI_GIT_AI_PROVIDER=jan

# Use Ollama with custom model
export AI_GIT_AI_PROVIDER=ollama
export AI_GIT_MODEL_NAME=llama3

# Use Anthropic Claude
export AI_GIT_AI_PROVIDER=claude
export AI_GIT_API_KEY=sk-ant-...

# Use xAI Grok
export AI_GIT_AI_PROVIDER=grok
export AI_GIT_API_KEY=xai-...

# Use a local llama.cpp server (./llama-server --port 8080)
export AI_GIT_AI_PROVIDER=llama_cpp

# Use a local Unsloth/vLLM server on a custom port
export AI_GIT_AI_PROVIDER=unsloth
export AI_GIT_BASE_URL=http://127.0.0.1:8001
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
| `ai_git review` | Review the staged files (experimental) |
| `ai_git --help` | Show usage |
| `ai_git --version` | Print version |

## Development

```bash
bundle exec rake test       # run tests
bundle exec rubocop         # lint

gem build ai_git.gemspec
gem install ./ai_git-$(ruby -r./lib/ai_git/version -e 'print AIGit::VERSION').gem
```
