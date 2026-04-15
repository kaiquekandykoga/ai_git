# AI Git

AI‑powered git commit + push tool using SLMs (Small Language Models)

## Usage

#### Requirements

- Ruby 4.0+
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

Generates a commit message via Ollama, commits, and pushes

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
