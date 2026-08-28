# Production Readiness TODO

Tracking list for taking `ai_git` from a working prototype to a gem that can be
recommended to strangers. Ordered by priority: **P0** blocks a confident 1.0,
**P3** is polish.

Current state: 40 tests passing, RuboCop clean, CI on Ubuntu/macOS/FreeBSD,
version 0.3.0 published on RubyGems.

---

## P0 — Correctness & data-loss bugs

- [ ] **`AIClient.sanitize` silently deletes valid commit body lines.**
      `OUTPUT_NOISE_PREFIXES` rejects *any* line beginning with `Here`,
      `Output`, `Generated`, `Based on`, or `The changes`. Verified:
      `"Fix parser crash\n\nThe changes to the lexer were needed.\nBased on
      profiling, we cache tokens."` sanitizes down to `"Fix parser crash"` —
      the entire body is destroyed. Restrict stripping to the *first* line (or
      to a leading preamble block) instead of filtering every line.
- [ ] **`sanitize` corrupts code-like content.** `gsub(/\\n/, "\n")` rewrites a
      literal backslash-n anywhere in the message. Verified: `"Use \\n in the
      format string."` becomes a real line break mid-sentence. Only unescape
      when the whole response is a single escaped line, or drop the rule.
- [ ] **Empty model responses commit a lie.** If `choices[0].message.content`
      is missing or the model returns whitespace, `generate_commit_message`
      falls back to `"chore: update code"` and commits + pushes it without
      telling anyone. Fail loudly instead, or at minimum warn and require
      confirmation.
- [ ] **Git read commands ignore failure.** `Git.staged_files`, `Git.diff`, and
      `Git.current_branch` use backticks and never inspect `$?`. Outside a git
      repo they return `""`, and the user gets
      `"Error: No staged files. Use \`git add\` first."` instead of "not a git
      repository". Route them through `Open3.capture3` and raise on non-zero.
- [ ] **Detached HEAD produces a nonsense branch name.** `current_branch`
      returns the literal string `HEAD`; the success line then prints
      `Pushed to origin/HEAD.` Detect and handle detached HEAD explicitly.
- [ ] **`run_command`'s single-String arg path splits on whitespace.**
      `args.first.split` breaks any path or value containing a space. It exists
      only for backward compatibility and is exercised by
      `test_run_command_legacy_string_args`. Remove it and pass argv arrays
      everywhere.

## P0 — Safety: this tool commits and pushes with no brakes

- [ ] **Add a confirmation step before committing.** `ai_git` currently
      generates, commits, and pushes in one unattended shot. Add an interactive
      accept / edit / regenerate / abort prompt when stdin is a TTY.
- [ ] **Add `--dry-run`** (print the message, touch nothing) — the single most
      important flag for trust-building on first use.
- [ ] **Add `--no-push`** so committing locally does not imply publishing.
- [ ] **Add `--yes` / `-y`** to opt back into today's unattended behavior for
      scripts and CI.
- [ ] **Diff content leaves the machine unreviewed.** The full staged diff is
      posted to `AI_GIT_BASE_URL`. That default is localhost, but the variable
      accepts any host with no warning and no scheme check. Warn loudly when
      the base URL is not loopback, and consider refusing plain `http://` to a
      non-local host.
- [ ] **Add secret redaction (or at least a guard).** Staging a `.env`,
      `id_rsa`, or a credentials file ships it verbatim in the prompt. Detect
      high-risk paths and known key patterns; warn or require `--force`.

## P1 — Robustness

- [ ] **Bound the prompt size.** The whole diff is interpolated into the
      prompt with no cap. A large refactor silently overruns the model's
      context and yields a garbage message. Truncate per-file with a clear
      marker, skip binary files, and skip/summarize lockfiles and generated
      files.
- [ ] **Send `max_tokens`.** No output cap is requested, so a rambling model
      can burn the full 120s read timeout.
- [ ] **Verify the push target before generating.** `push_current_branch` is
      hardcoded to `origin HEAD`, but the README promises "the current
      branch's upstream". Either honor the real upstream or fix the docs — and
      check the remote exists *before* spending a model call.
- [ ] **Make timeouts configurable.** `READ_TIMEOUT_SECONDS = 120` and
      `OPEN_TIMEOUT_SECONDS = 10` are constants; slow local hardware needs an
      env override.
- [ ] **Add jitter to the retry backoff.** `retry_delay` is deterministic
      exponential; add jitter and honor a `Retry-After` header on 429/503.
- [ ] **Unify the error path.** `Commands::Default` mixes `abort` (immediate
      exit) with `raise` (caught by `bin/ai_git`). Pick exceptions everywhere
      so the top-level handler owns all exit codes.
- [ ] **Define and document exit codes.** Today everything is `1` except
      `Interrupt` → `130`. Distinguish "no staged changes", "server
      unreachable", "git failed", "user aborted".
- [ ] **Show output from git hooks.** `run_command` discards stdout, so
      `pre-commit` / `commit-msg` hook output vanishes; only stderr survives
      inside the raised message.
- [ ] **Pass `--cleanup=whitespace` to `git commit`.** Defaults are fine today
      (verified: `#` lines survive `-F`), but a user's `commit.cleanup` config
      can silently mangle the generated message.
- [ ] **Colorize stderr off stderr.** `UI.color?` checks `$stdout.tty?`, yet
      `UI.error` writes to `$stderr` — colors are wrong when only one stream is
      redirected.
- [ ] **Handle flags after a subcommand.** `ai_git config --help` is silently
      ignored, and an unknown leading flag like `--foo` falls through to the
      default command and gets swallowed.

## P1 — Configuration

- [ ] **Support a config file.** `~/.config/ai_git/config.yml` (or
      `.ai_git.yml` in-repo) for model, base URL, timeouts, and push policy.
      Env vars stay the highest-precedence override.
- [ ] **Support an API key.** `Config` has no auth concept at all. Any
      OpenAI-compatible server behind a token is currently unusable. Read from
      an env var; never log it, and never print it in `ai_git config`.
- [ ] **Allow overriding the prompt template** for teams with commit
      conventions (Conventional Commits, ticket-ID prefixes, line-length rules).

## P2 — Testing

- [ ] **No test covers the HTTP layer.** `post_json`, `perform_request`, and
      the retry loop are entirely untested. Add a stub server (WEBrick or a
      `Net::HTTP` stub) covering success, 4xx, transient-then-success, and
      exhausted retries.
- [ ] **No test covers `Commands::Default.call`** — the whole end-to-end path.
      Add an integration test that builds a scratch repo, stages a file, stubs
      the client, and asserts a commit lands.
- [ ] **`test_git.rb` runs against the real working directory.** It asserts on
      the *actual* repo's staged files and branch, so results depend on the
      developer's uncommitted state. Run these in an isolated temp repo.
- [ ] **Add regression tests for the two `sanitize` bugs above** before fixing
      them.
- [ ] **Add coverage measurement** (SimpleCov) with a floor enforced in CI.
- [ ] **Test the FreeBSD skip.** `freebsd?` disables
      `test_current_branch_returns_string` with no explanation of why; confirm
      the underlying issue still exists or delete the guard.

## P2 — CI/CD & release

- [ ] **Test more than one Ruby version.** The matrix pins `'4.0'` only. Add
      the supported range so `required_ruby_version` (below) means something.
- [ ] **Turn on `bundler-cache: true`** in both workflows; installs are
      uncached today.
- [ ] **Add a `gem build` + install smoke job** so packaging breaks are caught
      in CI, not at push time.
- [ ] **Automate releases** with a tag-triggered workflow using RubyGems
      trusted publishing (OIDC). `bin/check_release` currently only *reports*
      drift and requires a manual `gem push`.
- [ ] **Add Dependabot** for Bundler and GitHub Actions.
- [ ] **Add `bundler-audit`** to CI for advisory scanning.
- [ ] **Pin action versions.** `actions/checkout` is `v7` in `ci.yml` but `v6`
      in `freebsd15.yml` — inconsistent.

## P2 — Packaging

- [ ] **Set `required_ruby_version`.** It is absent, and
      `Gemspec/RequiredRubyVersion` is explicitly disabled in `.rubocop.yml` to
      hide that. Users on older Rubies get a runtime crash instead of a clean
      resolver error.
- [ ] **Add `spec.email`** — RubyGems shows no contact for the author.
- [ ] **Add `changelog_uri`** to gemspec metadata (needs a CHANGELOG first).
- [ ] **Ship `CHANGELOG.md` in `spec.files`.**
- [ ] **Replace the C/CMake `.gitignore`.** It carries `*.o`, `*.so`,
      `CMakeCache.txt`, and `cmake_install.cmake` from another project and is
      missing Ruby entries (`/pkg`, `/coverage`, `.bundle`, `/doc/api`).
- [ ] **Add `.ruby-version`** so contributors and CI agree on a version.
- [ ] **Decide on `Gemfile.lock`.** It is committed; gems conventionally
      gitignore it. Keep it deliberately (for reproducible CI) or drop it —
      just make it a decision.

## P3 — Documentation

- [ ] **`AI_GIT_NO_COLOR` is implemented but undocumented.** `UI.color?`
      honors it; neither the README table nor `USAGE` mentions it.
- [ ] **Fix the push claim.** The README says `ai_git` "pushes to the current
      branch's upstream"; the code always pushes to `origin HEAD`.
- [ ] **Write `CHANGELOG.md`** (Keep a Changelog format), starting with the
      0.1.0 → 0.3.0 history.
- [ ] **Write `CONTRIBUTING.md`** — setup, `bundle exec rake`, RuboCop, how to
      propose changes.
- [ ] **Write `SECURITY.md`** — how to report a vulnerability, and an explicit
      statement about what diff data is sent where.
- [ ] **Document the privacy model in the README.** State plainly that the
      staged diff is sent to the configured server and that the default is
      local-only.
- [ ] **Document a troubleshooting section**: server not running, wrong model
      name, 404s, slow first token while the model loads.
- [ ] **Add GitHub issue and PR templates.**

## P3 — Polish

- [ ] Add `--verbose` / `--debug` to print the resolved request and the raw
      model response.
- [ ] Add a spinner or elapsed-time indicator during generation — it currently
      prints "Generating commit message…" and blocks for up to 120s in silence.
- [ ] Add shell completions (bash/zsh) for subcommands and flags.
- [ ] Support amending (`--amend`) and staging-all (`-a`) as opt-in flags.
- [ ] Verify and document Windows support, or state that it is unsupported.
- [ ] Consider streaming the response so the message appears as it is written.
