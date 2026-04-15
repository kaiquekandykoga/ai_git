# AI Git

AI-powered git commit and push tool using Ollama

## Requirements

- Ruby 4.0+
- Ollama

## Setup

```bash
ollama pull phi4:14b  # or: ollama serve
gem install ai_git
```

## Run

```bash
git add <files>
ai_git
```

Generates a commit message via Ollama, commits, and pushes

## Development

```bash
gem build ai_git.gemspec
gem install ./ai_git-0.0.0.gem
gem push ai_git-0.0.0.gem  # publish to RubyGems
```
