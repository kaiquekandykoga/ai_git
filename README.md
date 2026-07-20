# AI Git

AI-powered Git using LLM

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
| `AI_GIT_MODEL_NAME` | Model name | `ggml-org/gemma-4-E4B-it-GGUF` |
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
