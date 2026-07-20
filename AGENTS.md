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
- Requires a local [llama.cpp](https://github.com/ggml-org/llama.cpp) server (`./llama-server --port 8080`); it's the only supported provider, needs no API key
- `bin/ai_git` is the executable entry point; `AIGit.start` (in `lib/ai_git.rb`) routes subcommands and passes remaining argv to each command's `call(argv)`
- Subcommands: `default`, `review`, `config` (registered in `lib/ai_git.rb`)
- CLI flags parsed by `AIGit::OptionsParser.parse` in `lib/ai_git/options.rb` (per-command flag sets)
- Terminal output/colors/prompt/$EDITOR helpers in `lib/ai_git/ui.rb` (colors auto-off when not a TTY or `NO_COLOR` is set)
- HTTP requests to the local llama.cpp server live in `lib/ai_git/ai_client.rb` (retries transient failures with exponential backoff); model/base URL/endpoint defaults in `lib/ai_git/config.rb`
- `ai_client.rb#complete` posts a single OpenAI-format chat completions request (`openai_complete`) — no other request formats or API keys involved
- Tests must stay non-destructive: never call `Git.stage_all`/`commit_with_message`/`push_*` against the working repo — assert on parameters or use read-only helpers

## References

- `README.md` - usage and environment variables
- `.rubocop.yml` - disabled metrics cops, double_quotes style
