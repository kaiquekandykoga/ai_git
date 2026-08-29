# Release

`ai_git` is published to [RubyGems](https://rubygems.org/gems/ai_git) by
`.github/workflows/release.yml`, which runs on every push to `master` that
touches `lib/ai_git/version.rb`. The workflow authenticates with
[trusted publishing](https://guides.rubygems.org/trusted-publishing/): GitHub
mints a short-lived OIDC token, RubyGems exchanges it for a single-use API key
scoped to this gem. No API key is stored in the repository, and the push
satisfies the `rubygems_mfa_required` flag set in `ai_git.gemspec` without an
interactive MFA prompt.

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

That is the whole procedure. The push starts the workflow, which tags and
publishes on its own — there is no tag to create by hand.

## What the workflow does

1. Checks out `master` with its full history and tags, on Ruby 4.0.
2. Reads `AIGit::VERSION` and looks for the matching `v<version>` tag. If the
   tag already exists the version was not bumped — the change to `version.rb`
   was a comment or a header edit — and every later step is skipped, so the
   run is a no-op rather than a failure.
3. Installs the bundle, then runs `rake test` and `rubocop`. A failure here
   stops the run before anything is tagged or published.
4. Creates the annotated `v<version>` tag and pushes it.
5. Runs `rubygems/release-gem@v1`, which configures the OIDC credentials, runs
   `bundle exec rake release` (build, `guard_clean`, `gem push`), attaches a
   sigstore attestation, and waits for the version to appear on RubyGems. The
   tag from step 4 already exists, so the release task skips tagging and goes
   straight to the gem push.

A failure before step 5 publishes nothing. If the run fails after the tag is
pushed, delete the tag (`git push origin :refs/tags/v1.0.0`) and re-run the
workflow from the Actions tab — `workflow_dispatch` is enabled for exactly
that case.

## Verifying

The gem is live when the version shows up on
[rubygems.org/gems/ai_git/versions](https://rubygems.org/gems/ai_git/versions),
which the last step of the workflow waits for. Locally:

```bash
gem list -r ai_git --all
```

## Publishing by hand

Only needed if the workflow is unavailable. This is the path that prompts for
MFA:

```bash
gem build ai_git.gemspec
gem push ai_git-1.0.0.gem
```
