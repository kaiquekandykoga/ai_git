# AGENTS.md

## Build & Install
```bash
gem build ai_git.gemspec
gem install ./ai_git-0.0.0.gem
```

## Development
- Requires Ruby 4.0+ (not 3.x)
- Requires Ollama running locally with `phi4:14b` model
- Override model: `export AI_GIT_MODEL_NAME="model_name"`
- Entry point: `bin/ai_git`

## Run
```bash
git add <files>
ai_git
```

This stages files, generates commit message via Ollama, commits, and pushes.
