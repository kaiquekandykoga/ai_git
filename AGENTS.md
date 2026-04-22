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
- Requires Jan AI or Ollama running locally for full functionality
- `bin/ai_git` is the executable entry point

## References

- `README.md` - usage and environment variables
- `.rubocop.yml` - disabled metrics cops, double_quotes style
