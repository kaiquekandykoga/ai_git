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