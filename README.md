# AI Git

AI-powered Git commit messages using a local LLM

`ai_git` is a Ruby command-line tool that writes your commit messages for you.
Stage your changes, run `ai_git`, and it reads the staged diff, asks a local
[llama.cpp](https://github.com/ggml-org/llama.cpp) server for a commit message,
shows it to you, and — once you accept — commits and pushes to `origin`.

The generated message follows the conventional shape of a good commit: a short
imperative title under 72 characters, a blank line, then plain prose explaining
why the change was necessary and what problem it solves, rather than restating
the diff.

## Why a local model

The full staged diff goes to whatever `base_url` you configure, and the default
is your own machine (`http://127.0.0.1:8080`), so nothing leaves it and no API
key is needed. Point it at another host and ai_git warns before every run; plain
`http://` to a non-loopback host is refused outright. Before generating, it also
screens the staged change for credentials — `.env` files, private keys,
AWS/GitHub/Slack-shaped tokens — and refuses to send them without `--force`.

## Quick start

```bash
gem install ai_git

./llama-server --port 8080   # any OpenAI-compatible local server
git add <files>
ai_git
```

```
Commit this message? [A]ccept / [e]dit / [r]egenerate / [q]uit:
```

Accept it, open it in `$EDITOR`, ask for another one, or quit. The prompt only
appears on a terminal, so piped and scripted runs stay unattended. Use
`--dry-run` to see the message without committing, or `--no-push` to commit
locally.

## Documentation

- [Usage](doc/USAGE.md) — requirements, install, configuration, flags, and privacy
- [Release](doc/RELEASE.md) — how a version is tagged and published to RubyGems
