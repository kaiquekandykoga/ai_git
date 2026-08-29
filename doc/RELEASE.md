# Release

`ai_git` is published to [RubyGems](https://rubygems.org/gems/ai_git) by
`.github/workflows/release.yml`, which runs on every `v*` tag. The workflow
authenticates with [trusted publishing](https://guides.rubygems.org/trusted-publishing/):
GitHub mints a short-lived OIDC token, RubyGems exchanges it for a single-use
API key scoped to this gem. No API key is stored in the repository, and the
push satisfies the `rubygems_mfa_required` flag set in `ai_git.gemspec` without
an interactive MFA prompt.

## One-time setup

1. **RubyGems** — profile → the `ai_git` gem → *Trusted publishers* → *Create*:

   | Field | Value |
   |-------|-------|
   | Repository owner | `kaiquekandykoga` |
   | Repository name | `ai_git` |
   | Workflow filename | `release.yml` |
   | Environment | `release` |

2. **GitHub** — Settings → Environments → `release`. It is created on the first
   workflow run; add required reviewers there to gate each publish behind a
   manual approval.

The values must match the workflow exactly. Renaming the workflow file or the
environment invalidates the publisher and the push is rejected.

## Cutting a release

1. Bump `AIGit::VERSION` in `lib/ai_git/version.rb`.
2. Commit the bump and push it to `master`.
3. Tag and push the tag:

   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

The tag must be `v` followed by the version — that is the tag name
`rake release` looks for. Because the tag already exists when the workflow
runs, the release task skips tagging and goes straight to the gem push.

## What the workflow does

1. Checks out the tag and installs the bundle on Ruby 4.0.
2. Fails if the tag does not match `AIGit::VERSION` — a mismatch would publish
   the version in `version.rb`, not the one named by the tag.
3. Runs `rake test` and `rubocop`.
4. Runs `rubygems/release-gem@v1`, which configures the OIDC credentials, runs
   `bundle exec rake release` (build, `guard_clean`, `gem push`), attaches a
   sigstore attestation, and waits for the version to appear on RubyGems.

A failure before step 4 publishes nothing; fix it, delete and re-push the tag.

## Verifying

`bin/check_release` compares `AIGit::VERSION` against the versions published on
RubyGems and exits non-zero when the local version is missing:

```bash
bin/check_release
```

## Publishing by hand

Only needed if the workflow is unavailable. This is the path that prompts for
MFA:

```bash
gem build ai_git.gemspec
gem push ai_git-1.0.0.gem
```
