# Usage

## Requirements

- [llama.cpp](https://github.com/ggml-org/llama.cpp) running locally (e.g. `./llama-server --port 8080`)

## Install

```bash
gem install ai_git
```

## Configuration

Settings live in a YAML file at `~/.ai_git/config.yml` (`config.yaml` is read
too). The file is optional — without it every setting falls back to its
default.

```yaml
# ~/.ai_git/config.yml
model_name: ggml-org/gemma-4-E4B-it-GGUF:Q8_0
base_url: http://127.0.0.1:8080
no_color: false
```

| Setting | Description | Default |
|---------|-------------|---------|
| `model_name` | Model name | `ggml-org/gemma-4-E4B-it-GGUF:Q8_0` |
| `base_url` | Base URL of the llama.cpp server | `http://127.0.0.1:8080` |
| `no_color` | Disable colored terminal output | `false` |

An unknown key or a malformed value fails the run with an error naming the
file, so a typo never silently leaves the default in place.

Run `ai_git config` to see exactly which model, URL and endpoint are resolved,
and which file they came from.

ai_git talks to a local [llama.cpp](https://github.com/ggml-org/llama.cpp) server over its OpenAI-compatible
`/v1/chat/completions` endpoint. No API key is needed.

### Example

```bash
# Start llama.cpp's server, then run ai_git with defaults
./llama-server --port 8080
ai_git commit

# Or point at a custom model/port
mkdir -p ~/.ai_git
cat > ~/.ai_git/config.yml <<'YAML'
model_name: my-model
base_url: http://127.0.0.1:8081
YAML
```

## Run

Every action is named by a subcommand. A bare `ai_git` does nothing and changes
nothing; it only points you at `ai_git help`.

```bash
git add <files>
ai_git commit
```

`ai_git commit` generates a commit message from your staged changes, then asks
what to do with it:

```
Commit this message? [A]ccept / [e]dit / [r]egenerate / [q]uit:
```

Accepting commits and pushes to `origin`. The prompt only appears on a
terminal — piped or scripted runs stay unattended, as does `--yes`.

## Flags

These belong to `ai_git commit`:

| Flag | Description |
|------|-------------|
| `-n`, `--dry-run` | Print the generated message and change nothing |
| `--no-push` | Commit locally without pushing |
| `-y`, `--yes` | Skip the confirmation prompt (unattended) |
| `-f`, `--force` | Proceed despite secret or remote-server warnings |
| `-h`, `--help` | Describe the subcommand and its flags |

```bash
ai_git commit --dry-run     # see what it would write, commit nothing
ai_git commit --no-push     # commit locally, publish later yourself
```

## Privacy

The **full staged diff is sent to the configured `base_url`** as part of the
prompt. The default is your own machine (`http://127.0.0.1:8080`), and nothing
leaves it. Point `base_url` at another host and ai_git warns before every run;
plain `http://` to a non-loopback host is refused outright unless you pass
`--force`.

Before generating, ai_git also checks the staged change for credentials —
`.env` files, private keys, AWS/GitHub/Slack-shaped tokens — and refuses to
send them without `--force`. It is a guard, not a guarantee: review what you
stage.

## Subcommands

| Subcommand | Description |
|------------|-------------|
| `ai_git commit` | Generate a commit message, commit, and push staged files |
| `ai_git config` | Show the resolved provider configuration |
| `ai_git help` | List every subcommand and the top-level options |
| `ai_git help <subcommand>` | Describe one subcommand and the flags it takes |
| `ai_git --help` | Same overview as `ai_git help` |
| `ai_git --version` | Print version |

`ai_git` on its own is not one of them: with no subcommand it prints where to
look and exits without touching the repository. Naming an unknown subcommand,
or a flag where a subcommand belongs, prints the usage and exits `1`.

Each subcommand also answers `--help` for itself:

```bash
ai_git help commit     # or: ai_git commit --help
ai_git help config     # or: ai_git config --help
```
