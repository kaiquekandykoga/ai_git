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
| `AI_GIT_NO_COLOR` | Disable colored terminal output when set | — |

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

`ai_git` generates a commit message from your staged changes, then asks what to
do with it:

```
Commit this message? [A]ccept / [e]dit / [r]egenerate / [q]uit:
```

Accepting commits and pushes to `origin`. The prompt only appears on a
terminal — piped or scripted runs stay unattended, as does `--yes`.

#### Flags

| Flag | Description |
|------|-------------|
| `-n`, `--dry-run` | Print the generated message and change nothing |
| `--no-push` | Commit locally without pushing |
| `-y`, `--yes` | Skip the confirmation prompt (unattended) |
| `-f`, `--force` | Proceed despite secret or remote-server warnings |

```bash
ai_git --dry-run     # see what it would write, commit nothing
ai_git --no-push     # commit locally, publish later yourself
```

#### Privacy

The **full staged diff is sent to `AI_GIT_BASE_URL`** as part of the prompt. The
default is your own machine (`http://127.0.0.1:8080`), and nothing leaves it.
Point `AI_GIT_BASE_URL` at another host and ai_git warns before every run;
plain `http://` to a non-loopback host is refused outright unless you pass
`--force`.

Before generating, ai_git also checks the staged change for credentials —
`.env` files, private keys, AWS/GitHub/Slack-shaped tokens — and refuses to
send them without `--force`. It is a guard, not a guarantee: review what you
stage.

#### Subcommands

| Subcommand | Description |
|------------|-------------|
| `ai_git` | Generate a commit message, commit, and push staged files |
| `ai_git config` | Show the resolved provider configuration |
| `ai_git --help` | Show usage |
| `ai_git --version` | Print version |
