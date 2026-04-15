# AI Git

AI-powered git commit and push tool using Ollama.

## Requirements

- Ruby 4.0+
- Ollama running with `llama3.2:3b` model

## Setup

1. Pull the Ollama model (if not already done):
   ```bash
   ollama pull llama3.2:3b
   ```

2. Start Ollama:
   ```bash
   ollama serve
   ```

## Run

1. Stage your files:
   ```bash
   git add <files>
   ```

2. Run the app:
   ```bash
   ./bin/ai_git
   ```

The app will generate a commit message using Ollama, commit your staged changes, and push to the remote.

## Development

1. Build the gem:
   ```bash
   gem build ai_git.gemspec
   ```

2. Install locally:
   ```bash
   gem install ./ai_git-0.1.0.gem
   ```

## Publishing

1. Push to RubyGems:
   ```bash
   gem push ai_git-0.1.0.gem
   ```