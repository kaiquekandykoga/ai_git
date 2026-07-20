# AI Git

AI-powered Git commit messages using a local LLM

## Usage

#### Requirements

- [llama.cpp](https://github.com/ggml-org/llama.cpp) running locally (e.g. `./llama-server --port 8080`)

#### Install

```bash
gem install ai_git
```

#### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `AI_GIT_MODEL_NAME` | Model name | `ggml-org/gemma-4-E4B-it-GGUF:Q8_0` |
| `AI_GIT_BASE_URL` | Base URL of the llama.cpp server | `http://127.0.0.1:8080` |
| `NO_COLOR` | Disable colored terminal output when set | — |

Run `ai_git config` to see exactly which model, URL and endpoint are resolved from your environment.

ai_git talks to a local [llama.cpp](https://github.com/ggml-org/llama.cpp) server over its OpenAI-compatible
`/v1/chat/completions` endpoint. No API key is needed.

##### Example

```bash
# Start llama.cpp's server, then run ai_git with defaults
./llama-server --port 8080
ai_git

# Or point at a custom model/port
export AI_GIT_MODEL_NAME=my-model
export AI_GIT_BASE_URL=http://127.0.0.1:8081
```

#### Run

```bash
git add <files>
ai_git
```

`ai_git` generates a commit message from your staged changes, commits, and
pushes to the current branch's upstream — no prompts, no flags.

#### Subcommands

| Subcommand | Description |
|------------|-------------|
| `ai_git` | Generate a commit message, commit, and push staged files |
| `ai_git config` | Show the resolved provider configuration |
| `ai_git --help` | Show usage |
| `ai_git --version` | Print version |

## Development

```bash
bundle exec rake test       # run tests
bundle exec rubocop         # lint

gem build ai_git.gemspec
gem install ./ai_git-$(ruby -r./lib/ai_git/version -e 'print AIGit::VERSION').gem
```
