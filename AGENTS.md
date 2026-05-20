# AGENTS.md

## Run Commands

```bash
bundle exec rake test    # run tests
bundle exec rubocop     # lint
bundle exec rubocop -A  # format

gem build ai_git.gemspec  # build gem
gem install ./ai_git-*.gem  # install locally
```

## Notes

- Ruby 4.0 required (see CI matrix)
- Test framework: test-unit (not rspec/minitest)
- Default agent: `plan` (opencode.json)
- Requires a reachable provider for full functionality: local (`jan`, `ollama`, `llama_cpp`, `unsloth`) or hosted (`claude`, `grok` — need `AI_GIT_API_KEY`)
- `bin/ai_git` is the executable entry point
- HTTP requests to providers live in `lib/ai_git/ai_client.rb`; provider-specific knobs in `lib/ai_git/config.rb`
- Request formats dispatched in `ai_client.rb#complete`: `:ollama`, `:openai` (Jan/Grok/llama.cpp/Unsloth), `:anthropic` (Claude)

## References

- `README.md` - usage and environment variables
- `.rubocop.yml` - disabled metrics cops, double_quotes style
