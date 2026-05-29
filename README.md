# AI Git

AI-powered Git using LLM

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
| `AI_GIT_API_KEY` | API key for hosted providers (`claude`, `grok`, `azure`, `openrouter`, `mistral`, `gemini`, `hugging_face`, `nvidia_nim`). Falls back to `ANTHROPIC_API_KEY` for `claude`, `AZURE_OPENAI_API_KEY` for `azure`. | — |
| `NO_COLOR` | Disable colored terminal output when set | — |

Run `ai_git config` to see exactly which provider, model, URL and key are resolved from your environment.

##### Provider Defaults

| Provider | Default Model | Base URL | Reference |
|----------|---------------|---------|-----------|
| `jan` (default) | Jan-v3.5-4B-Q4_K_XL | http://127.0.0.1:1337 | https://jan.ai |
| `ollama` | gemma4:e4b | http://localhost:11434 | https://ollama.com |
| `claude` | claude-opus-4-7 | https://api.anthropic.com | https://docs.anthropic.com |
| `grok` | grok-4 | https://api.x.ai | https://docs.x.ai |
| `llama_cpp` | default | http://127.0.0.1:8080 | https://github.com/ggml-org/llama.cpp |
| `unsloth` | unsloth/gemma-3-4b-it | http://127.0.0.1:8000 | https://github.com/unslothai/unsloth |
| `mlx` | mlx-community/Llama-3.2-3B-Instruct-4bit | http://127.0.0.1:8080 | https://github.com/ml-explore/mlx-lm |
| `azure` | gpt-4o-mini | (set via `AI_GIT_BASE_URL`) | https://learn.microsoft.com/azure/ai-services/openai |
| `openrouter` | openai/gpt-4o-mini | https://openrouter.ai/api | https://openrouter.ai/docs |
| `mistral` | mistral-large-latest | https://api.mistral.ai | https://docs.mistral.ai |
| `gemini` | gemini-2.0-flash | https://generativelanguage.googleapis.com | https://ai.google.dev/gemini-api/docs/openai |
| `hugging_face` | meta-llama/Llama-3.3-70B-Instruct | https://router.huggingface.co | https://huggingface.co/docs/inference-providers |
| `nvidia_nim` | meta/llama-3.3-70b-instruct | https://integrate.api.nvidia.com | https://docs.nvidia.com/nim |

Local providers (`jan`, `ollama`, `llama_cpp`, `unsloth`, `mlx`) require no API key. Hosted providers (`claude`, `grok`, `azure`, `openrouter`, `mistral`, `gemini`, `hugging_face`, `nvidia_nim`) need `AI_GIT_API_KEY`.

For `azure`, set `AI_GIT_BASE_URL` to your deployment URL, e.g. `https://my-resource.openai.azure.com/openai/deployments/my-deployment`. Azure uses the `api-key` header rather than `Authorization: Bearer`.

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

# Use a local MLX server (mlx_lm.server --port 8080)
export AI_GIT_AI_PROVIDER=mlx

# Use Azure OpenAI
export AI_GIT_AI_PROVIDER=azure
export AI_GIT_BASE_URL=https://my-resource.openai.azure.com/openai/deployments/my-deployment
export AI_GIT_API_KEY=...

# Use OpenRouter
export AI_GIT_AI_PROVIDER=openrouter
export AI_GIT_API_KEY=sk-or-...

# Use Mistral
export AI_GIT_AI_PROVIDER=mistral
export AI_GIT_API_KEY=...

# Use Google Gemini (via OpenAI-compatible endpoint)
export AI_GIT_AI_PROVIDER=gemini
export AI_GIT_API_KEY=...

# Use Hugging Face Inference Providers
export AI_GIT_AI_PROVIDER=hugging_face
export AI_GIT_API_KEY=hf_...

# Use NVIDIA NIM
export AI_GIT_AI_PROVIDER=nvidia_nim
export AI_GIT_API_KEY=nvapi-...
```

#### Run

```bash
git add <files>
ai_git
```

By default, when run in a terminal, `ai_git` shows the generated message and
asks what to do before touching your history:

```
[a]ccept  [e]dit  [r]egenerate  [s]kip push  [q]uit (a):
```

- **accept** — commit and push
- **edit** — open the message in your `$EDITOR`, then commit
- **regenerate** — ask the model for a different message
- **skip push** — commit but don't push
- **quit** — abort without committing

When stdin is not a terminal (e.g. CI or a pipe), it skips the prompt and
behaves as before (commit and push, unless `--no-push`).

#### Subcommands

| Subcommand | Description |
|------------|-------------|
| `ai_git` | Generate a commit message, commit, and push staged files |
| `ai_git review` | Review the staged files (experimental) |
| `ai_git config` | Show the resolved provider configuration |
| `ai_git --help` | Show usage |
| `ai_git --version` | Print version |

#### Options (default command)

| Flag | Description |
|------|-------------|
| `-y`, `--yes` | Skip the confirmation prompt; commit and push |
| `--no-push` | Commit but do not push |
| `--dry-run` | Print the generated message only; don't commit or push |
| `--amend` | Amend the last commit (disables auto-push) |
| `--conventional` | Use [Conventional Commits](https://www.conventionalcommits.org) format (`feat:`/`fix:`/…) |
| `-a`, `--all` | Stage all changes (`git add -A`) before running |

```bash
ai_git --dry-run                # preview the message, change nothing
ai_git -a --conventional        # stage everything, conventional format
ai_git --yes --no-push          # commit non-interactively, don't push
ai_git --amend                  # rewrite the last commit's message
```

`ai_git review` also accepts `-a`/`--all`. Set `NO_COLOR=1` to disable
colored output.

## Development

```bash
bundle exec rake test       # run tests
bundle exec rubocop         # lint

gem build ai_git.gemspec
gem install ./ai_git-$(ruby -r./lib/ai_git/version -e 'print AIGit::VERSION').gem
```
