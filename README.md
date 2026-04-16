# AI Git

AI‑powered Git using SLMs

## Usage

#### Requirements

- Ollama running locally

#### Install

```bash
gem install ai_git
```

#### AI Model

Uses `phi4:14b` by default. Override with:

```
export AI_GIT_MODEL_NAME="model_name"
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

## AI Providers

List of supported AI Providers

| Provider | Reference |
|---------|---------|
| Ollama | https://ollama.com


## Development

```bash
gem build ai_git.gemspec
gem install ./ai_git-0.0.0.gem
gem push ai_git-0.0.0.gem  # publish to RubyGems
```
