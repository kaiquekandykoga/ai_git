# Production Readiness TODO

Remaining work for taking `ai_git` from a working prototype to a gem that can be
recommended to strangers. Ordered by priority: **P0** blocks a confident 1.0,
**P3** is polish.

Current state: 85 tests passing, RuboCop clean, CI on Ubuntu/macOS/FreeBSD,
Dependabot watching Bundler and Actions, release automation wired to
`AIGit::VERSION`, version 1.0.0. Committing is gated behind a confirmation
prompt plus `--dry-run` / `--no-push` / `--yes` / `--force`, git reads are
checked, and empty model responses fail loudly. Both P0 correctness defects
are fixed; nothing blocks a 1.0 today.

---

## P0 — Correctness

None outstanding. Fixed:

- ~~**`sanitize` deleted a legitimate title.**~~ `strip_preamble` matched a bare
  leading word, so `"Output the resolved settings\n\nBody."` sanitized down to
  `"Body."`. Preamble detection now requires a whole announcing sentence
  (`LABELLED_PREAMBLE`, `BARE_LANGUAGE_TAG`, `ANNOUNCING_PREAMBLE`) and never
  strips a reply down to nothing.
- ~~**A diff that was not valid UTF-8 crashed the run.**~~ `git diff --cached`
  on a Latin-1 file returned bytes tagged UTF-8 but invalid, and `body.to_json`
  raised `JSON::GeneratorError`. `Git.capture` now scrubs every captured
  stream to valid UTF-8 at the source.

## P1 — Robustness

- **Redact detected secrets instead of only refusing.** `Secrets.scan` blocks
  the run when a `.env`, private key or token-shaped string is staged, but the
  diff is still sent verbatim once `--force` is passed. Mask the matched values
  in the prompt.
- **Scan the whole diff, not only added lines.** `Secrets.added_lines` keeps
  lines starting with `+`, but the model receives the entire diff — including
  the three context lines around every hunk. A secret sitting next to an edited
  line is sent and never flagged. Scan added lines for blocking, and context
  lines at least for a warning.
- **Bound the prompt size.** The whole diff is interpolated into the prompt with
  no cap. A large refactor silently overruns the model's context and yields a
  garbage message. Truncate per-file with a clear marker, skip binary files, and
  skip/summarize lockfiles and generated files.
- **Move the diff to the end of the prompt.** `standard_prompt` puts the diff
  before the rules and the two worked examples, so the long static tail differs
  in position on every run and llama.cpp's prefix cache never hits. Ordering the
  prompt as instructions → rules → examples → diff makes the constant part a
  reusable prefix and cuts time-to-first-token on every run after the first.
- **Send `max_tokens`.** No output cap is requested, so a rambling model can
  burn the full 120s read timeout.
- **Make regenerate actually regenerate.** `resolve_message` re-runs the same
  prompt at the same hardcoded `temperature: 0.3`. On a server with a fixed seed
  the user gets the identical message back and the loop is useless. Vary the
  temperature (or pass a fresh seed) on each retry, and consider feeding the
  rejected message back as "not this one".
- **Re-check the staged set before committing.** `staged_files` and `diff` are
  read once, then the prompt can sit open indefinitely; `git commit -F` commits
  whatever is staged at that later moment. Someone who stages another file
  mid-prompt commits work the message never described. Snapshot the staged tree
  and re-verify (or commit the recorded pathspec) before writing the commit.
- **Verify the push target before generating.** `push_current_branch` is
  hardcoded to `git push -u origin HEAD`, but the README promises "the current
  branch's upstream". Worse, `-u` silently rewrites the branch's tracking config
  to `origin` even when it deliberately tracked something else. Honor the real
  upstream (or drop `-u`), and check the remote exists *before* spending a model
  call.
- **Make timeouts configurable.** `READ_TIMEOUT_SECONDS = 120` and
  `OPEN_TIMEOUT_SECONDS = 10` are constants; slow local hardware needs a
  config-file override.
- **Add jitter to the retry backoff.** `retry_delay` is deterministic
  exponential; add jitter and honor a `Retry-After` header on 429/503.
- **Unify the error path.** `Commands::Default` mixes `abort` (immediate exit)
  with `raise` (caught by `bin/ai_git`). Pick exceptions everywhere so the
  top-level handler owns all exit codes.
- **Define and document exit codes.** Today everything is `1` except `Interrupt`
  → `130`. Distinguish "no staged changes", "server unreachable", "git failed",
  "user aborted".
- **Show output from git hooks.** `run_command` discards stdout, so `pre-commit`
  / `commit-msg` hook output vanishes; only stderr survives inside the raised
  message.
- **Pass `--cleanup=whitespace` to `git commit`.** Defaults are fine today
  (verified: `#` lines survive `-F`), but a user's `commit.cleanup` config can
  silently mangle the generated message.
- **Colorize stderr off stderr.** `UI.color?` checks `$stdout.tty?`, yet
  `UI.error` and `UI.warning` write to `$stderr` — colors are wrong when only
  one stream is redirected.
- **Honor `NO_COLOR` and add `--no-color`.** `no_color` is config-file only.
  The de-facto `NO_COLOR` environment variable is ignored, and there is no
  per-run flag to turn color off.
- **Handle flags after a subcommand.** `ai_git config --help` is silently
  ignored (`Commands::Config.call` takes `_argv`), and an unknown leading flag
  like `--foo` falls through to the default command and gets swallowed.
- **Accept combined and terminated flags.** The hand-rolled `Options.parse`
  rejects `-ny`, `--` and `--flag=value`, all of which a user reasonably
  expects. Either document the limitation or move to `OptionParser`.

## P1 — Configuration

- **Extend the config file.** `~/.ai_git/config.yml` now carries `model_name`,
  `base_url` and `no_color`. Add timeouts, temperature and push policy, an
  in-repo `.ai_git.yml` for per-project overrides, and a flag-level override for
  the settings that need one per run.
- **Support environment overrides.** Nothing can be set without editing a file
  in `$HOME`, which makes CI runs and one-off experiments awkward. Read
  `AI_GIT_BASE_URL` / `AI_GIT_MODEL_NAME` (and a `--config` path flag) with a
  documented precedence: flag → env → file → default.
- **Honor `XDG_CONFIG_HOME`.** `config_dir` is hardcoded to `~/.ai_git`;
  `$XDG_CONFIG_HOME/ai_git` should win when it is set.
- **Support an API key.** `Config` has no auth concept at all. Any
  OpenAI-compatible server behind a token is currently unusable. Read it from
  the config file; never log it, and never print it in `ai_git config`.
- **Print every resolved setting.** `Commands::Config.resolved_rows` omits
  `no_color` and the open timeout, so `ai_git config` cannot answer "why is my
  output plain?".
- **Allow overriding the prompt template** for teams with commit conventions
  (Conventional Commits, ticket-ID prefixes, line-length rules).

## P2 — Testing

- **No test covers the HTTP layer.** `post_json`, `perform_request`, and the
  retry loop are entirely untested. Add a stub server (WEBrick or a `Net::HTTP`
  stub) covering success, 4xx, transient-then-success, and exhausted retries.
- **No test covers `Commands::Default.call`** — the whole end-to-end path. The
  guards (`check_base_url!`, `check_secrets!`) and message generation are
  covered, but not `call` itself. Add an integration test that builds a scratch
  repo, stages a file, stubs the client, and asserts a commit lands.
- **No test covers the confirmation prompt.** `Prompt.ask_action` and
  `Prompt.edit` are exercised by hand over a PTY only.
- **Assert the docs match the parser.** `USAGE`, the flag table in
  `doc/USAGE.md` and `Options` are three hand-maintained lists of the same
  flags. A test that walks `Options.parse` would stop them drifting.
- **Add coverage measurement** (SimpleCov) with a floor enforced in CI.

## P2 — CI/CD & release

- **Test more than one Ruby version.** The matrix pins `'4.0'` only. Add the
  supported range so `required_ruby_version` (below) means something.
- **Turn on `bundler-cache: true`** in all three workflows; installs are
  uncached today.
- **Add a `gem build` + install smoke job** so packaging breaks are caught in
  CI, not at push time.
- **Restrict workflow token permissions.** `ci.yml` and `freebsd15.yml` declare
  no `permissions:` block, so each job gets the repository default. Set
  `permissions: contents: read` on both.
- **Add a `concurrency` group** so a new push cancels the superseded run
  instead of paying for a FreeBSD VM that no longer matters.
- **Pin action versions.** `actions/checkout` is `v7` in `ci.yml` but `v6` in
  `freebsd15.yml` — inconsistent. In `release.yml`, which holds publishing
  rights, pin to commit SHAs rather than floating tags.
- **Lint on FreeBSD too, or say why not.** `freebsd15.yml` runs `rake test`
  only, so a platform-specific RuboCop failure is invisible there.
- **Finish the release automation setup.** `.github/workflows/release.yml`
  tags and publishes whenever a push to `master` bumps `AIGit::VERSION`, via
  RubyGems trusted publishing (OIDC); it stays inert until the trusted
  publisher is registered on rubygems.org for this repo, workflow file, and the
  `release` environment.
- **Add `bundler-audit`** to CI for advisory scanning.

## P2 — Packaging

- **Set `required_ruby_version`.** It is absent, and
  `Gemspec/RequiredRubyVersion` is explicitly disabled in `.rubocop.yml` to hide
  that. Users on older Rubies get a runtime crash instead of a clean resolver
  error.
- **Add `spec.email`** — RubyGems shows no contact for the author.
- **Add `homepage_uri`, `documentation_uri` and `changelog_uri`** to gemspec
  metadata (the last needs a CHANGELOG first).
- **Ship `CHANGELOG.md` in `spec.files`.**
- **Replace the C/CMake `.gitignore`.** It carries `*.o`, `*.so`,
  `CMakeCache.txt`, and `cmake_install.cmake` from another project, and its
  `Makefile` and `*.cmake` entries would silently swallow a real file if one is
  ever added. It is also missing the Ruby entries (`/pkg`, `/coverage`,
  `.bundle`, `/doc/api`).
- **Remove the stray `ai_git-1.0.0.gem` at the repo root.** It is untracked and
  hidden by the `*.gem` rule, but it is a stale hand-built artifact; `rake
  build` writes to `pkg/`.
- **Add `.ruby-version`** so contributors and CI agree on a version.
- **Decide on `Gemfile.lock`.** It is committed; gems conventionally gitignore
  it. Keep it deliberately (for reproducible CI) or drop it — just make it a
  decision.

## P3 — Documentation

- **Fix the push claim.** The README says `ai_git` "pushes to the current
  branch's upstream"; the code always pushes to `origin HEAD` and sets tracking.
- **Write `CHANGELOG.md`** (Keep a Changelog format), starting with the 0.1.0 →
  1.0.0 history.
- **Write `CONTRIBUTING.md`** — setup, `bundle exec rake`, RuboCop, the
  `AGENTS.md` file-header convention, and how to propose changes.
- **Write `SECURITY.md`** — how to report a vulnerability, and an explicit
  statement about what diff data is sent where.
- **Document the privacy model in the README.** State plainly that the staged
  diff is sent to the configured server and that the default is local-only.
- **Document a troubleshooting section**: server not running, wrong model name,
  404s, slow first token while the model loads.
- **Add CI and gem-version badges** to the README.
- **Add GitHub issue and PR templates.**

## P3 — Polish

- Add `--verbose` / `--debug` to print the resolved request and the raw model
  response.
- Add a spinner or elapsed-time indicator during generation — it currently
  prints "Generating commit message…" and blocks for up to 120s in silence.
- Add shell completions (bash/zsh) for subcommands and flags.
- Support amending (`--amend`) and staging-all (`-a`) as opt-in flags, plus
  `--no-verify` and `--signoff` passthrough to `git commit`.
- Fall back to git's own editor setting. `Prompt.edit` reads `$VISUAL` and
  `$EDITOR` only, so a user who configured `core.editor` (or `$GIT_EDITOR`) is
  told to "set $EDITOR or $VISUAL first" despite having an editor configured.
- Verify and document Windows support, or state that it is unsupported.
- Consider streaming the response so the message appears as it is written.
