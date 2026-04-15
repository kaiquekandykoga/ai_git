# AI Git

AI-powered git commit and push tool using Ollama.

## Build

```bash
mkdir build && cd build
cmake ..
make
```

The executable will be at `build/ai_git`.

## Run

1. Ensure you have staged files:
   ```bash
   git add <files>
   ```

2. Ensure Ollama is running with `llama3.2:3b`:
   ```bash
   ollama pull llama3.2:3b
   ollama serve
   ```

3. Run the app:
   ```bash
   ./build/ai_git
   ```

The app will generate a commit message using Ollama, commit your staged changes, and push to the remote.
