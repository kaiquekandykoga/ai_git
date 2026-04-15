# AGENTS.md

## Requirements

- Ruby 4.0+ (required by gemspec)
- Ollama running with `llama3.2:3b` model

## Run

```bash
# 1. Stage files first
git add <files>

# 2. Run the app
./bin/ai_git
```

The app connects to `http://localhost:11434/api/generate`, generates a commit message, commits, and pushes.

## Development

```bash
# Build gem
gem build ai_git.gemspec

# Install locally
gem install ./ai_git-0.1.0.gem

# Publish
gem push ai_git-0.1.0.gem
```

## Architecture

- Entry: `bin/ai_git`
- Main module: `lib/ai_git.rb`
- Git operations: `lib/ai_git/git.rb`
- Ollama API: `lib/ai_git/ollama.rb`
