# Changelog

All notable changes to `ai_git` are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0] - 2026-09-11

### Added

- `ai_git help [subcommand]` documents every subcommand and flag.
- Dependabot watches Bundler and GitHub Actions weekly.
- `CHANGELOG.md`, `.ruby-version`, `spec.email`, `required_ruby_version`, and
  the `homepage_uri` / `documentation_uri` / `changelog_uri` gem metadata.

### Changed

- **Breaking:** every action is now named. `ai_git commit` is the only path
  that writes, and a bare `ai_git` does nothing; scripts that relied on the
  implicit commit must call `ai_git commit`.
- `required_ruby_version` is `>= 3.1`, and CI runs the suite on 3.1, 3.2, 3.3,
  3.4 and 4.0 across Ubuntu and macOS.
- Command handling moved into dedicated `AIGit::Commands` modules.
- `.gitignore` replaced the inherited C/CMake rules with Ruby ones.
- `Gemfile.lock` is no longer tracked; the gem resolves fresh on every install.

### Fixed

- Real commit titles and non-UTF-8 diffs are no longer dropped.
- The stricter RuboCop configuration and the offenses it surfaced.

## [1.0.1] - 2026-08-29

### Added

- `~/.ai_git/config.yml` holds `model_name`, `base_url`, and `no_color`.
- Release automation: pushing a `lib/ai_git/version.rb` bump to `master` tags
  the release and publishes to RubyGems via trusted publishing (OIDC).
- `doc/USAGE.md` and file headers across the source tree.

### Changed

- Configuration moved from environment variables to the YAML config file.

### Removed

- The `NO_COLOR` environment variable, superseded by the config file.

## 1.0.0 - 2026-08-29

### Added

- Brakes on the write path: a confirmation prompt plus `--dry-run`,
  `--no-push`, `--yes`, and `--force`.
- Staged-secret scanning that blocks the run when a `.env`, private key, or
  token-shaped string is staged.

### Fixed

- Correctness bugs in git reads, which are now checked, and in empty model
  responses, which now fail loudly.

Releases before 1.0.0 predate this changelog; see the git history for them.

[Unreleased]: https://github.com/kaiquekandykoga/ai_git/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/kaiquekandykoga/ai_git/compare/v1.0.1...v2.0.0
[1.0.1]: https://github.com/kaiquekandykoga/ai_git/releases/tag/v1.0.1
