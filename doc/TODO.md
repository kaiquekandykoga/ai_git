# Production Readiness TODO

Remaining work for taking `ai_git` from a working prototype to a gem that can be
recommended to strangers. Ordered by priority: **P0** blocks a confident 1.0,
**P3** is polish.

Current state: 79 tests passing, RuboCop clean, CI on Ubuntu/macOS/FreeBSD,
version 1.0.0. The P0 correctness and safety work is
done: `sanitize` no longer eats message bodies, git reads are checked, empty
model responses fail loudly, and committing is gated behind a confirmation
prompt plus `--dry-run` / `--no-push` / `--yes` / `--force`.

---

## P1 — Robustness

- **Redact detected secrets instead of only refusing.** `Secrets.scan` blocks
  the run when a `.env`, private key or token-shaped string is staged, but the
  diff is still sent verbatim once `--force` is passed. Mask the matched values
  in the prompt.
- **Bound the prompt size.** The whole diff is interpolated into the prompt with
  no cap. A large refactor silently overruns the model's context and yields a
  garbage message. Truncate per-file with a clear marker, skip binary files, and
  skip/summarize lockfiles and generated files.
- **Send `max_tokens`.** No output cap is requested, so a rambling model can
  burn the full 120s read timeout.
- **Verify the push target before generating.** `push_current_branch` is
  hardcoded to `origin HEAD`, but the README promises "the current branch's
  upstream". Either honor the real upstream or fix the docs — and check the
  remote exists *before* spending a model call.
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
  `UI.error` writes to `$stderr` — colors are wrong when only one stream is
  redirected.
- **Handle flags after a subcommand.** `ai_git config --help` is silently
  ignored, and an unknown leading flag like `--foo` falls through to the default
  command and gets swallowed.

## P1 — Configuration

- **Extend the config file.** `~/.ai_git/config.yml` now carries `model_name`,
  `base_url` and `no_color`. Add timeouts and push policy, an in-repo
  `.ai_git.yml` for per-project overrides, and a flag-level override for the
  settings that need one per run.
- **Support an API key.** `Config` has no auth concept at all. Any
  OpenAI-compatible server behind a token is currently unusable. Read it from
  the config file; never log it, and never print it in `ai_git config`.
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
- **Add coverage measurement** (SimpleCov) with a floor enforced in CI.

## P2 — CI/CD & release

- **Test more than one Ruby version.** The matrix pins `'4.0'` only. Add the
  supported range so `required_ruby_version` (below) means something.
- **Turn on `bundler-cache: true`** in both workflows; installs are uncached
  today.
- **Add a `gem build` + install smoke job** so packaging breaks are caught in
  CI, not at push time.
- **Finish the release automation setup.** `.github/workflows/release.yml`
  publishes on a `v*` tag via RubyGems trusted publishing (OIDC); it stays inert
  until the trusted publisher is registered on rubygems.org for this repo,
  workflow file, and the `release` environment.
- **Add Dependabot** for Bundler and GitHub Actions.
- **Add `bundler-audit`** to CI for advisory scanning.
- **Pin action versions.** `actions/checkout` is `v7` in `ci.yml` but `v6` in
  `freebsd15.yml` — inconsistent.

## P2 — Packaging

- **Set `required_ruby_version`.** It is absent, and
  `Gemspec/RequiredRubyVersion` is explicitly disabled in `.rubocop.yml` to hide
  that. Users on older Rubies get a runtime crash instead of a clean resolver
  error.
- **Add `spec.email`** — RubyGems shows no contact for the author.
- **Add `changelog_uri`** to gemspec metadata (needs a CHANGELOG first).
- **Ship `CHANGELOG.md` in `spec.files`.**
- **Replace the C/CMake `.gitignore`.** It carries `*.o`, `*.so`,
  `CMakeCache.txt`, and `cmake_install.cmake` from another project and is
  missing Ruby entries (`/pkg`, `/coverage`, `.bundle`, `/doc/api`).
- **Add `.ruby-version`** so contributors and CI agree on a version.
- **Decide on `Gemfile.lock`.** It is committed; gems conventionally gitignore
  it. Keep it deliberately (for reproducible CI) or drop it — just make it a
  decision.

## P3 — Documentation

- **Fix the push claim.** The README says `ai_git` "pushes to the current
  branch's upstream"; the code always pushes to `origin HEAD`.
- **Write `CHANGELOG.md`** (Keep a Changelog format), starting with the 0.1.0 →
  1.0.0 history.
- **Write `CONTRIBUTING.md`** — setup, `bundle exec rake`, RuboCop, how to
  propose changes.
- **Write `SECURITY.md`** — how to report a vulnerability, and an explicit
  statement about what diff data is sent where.
- **Document the privacy model in the README.** State plainly that the staged
  diff is sent to the configured server and that the default is local-only.
- **Document a troubleshooting section**: server not running, wrong model name,
  404s, slow first token while the model loads.
- **Add GitHub issue and PR templates.**

## P3 — Polish

- Add `--verbose` / `--debug` to print the resolved request and the raw model
  response.
- Add a spinner or elapsed-time indicator during generation — it currently
  prints "Generating commit message…" and blocks for up to 120s in silence.
- Add shell completions (bash/zsh) for subcommands and flags.
- Support amending (`--amend`) and staging-all (`-a`) as opt-in flags.
- Verify and document Windows support, or state that it is unsupported.
- Consider streaming the response so the message appears as it is written.
