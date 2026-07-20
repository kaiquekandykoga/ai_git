---
name: commit-and-push-changes
description: >
  Commit and push the changes made during this session, then ensure a pull request exists. Use when the user says "commit and push", "ship this", "open a PR", or asks to save/publish session work to git. Uses git worktrees
model: haiku
---

# Commit and push changes
Commit session changes in a worktree, push, and ensure a PR exists

## Steps
1. If on `main`/`master` branch, use a worktree at `.claude/worktrees/<name>`. Create it only if it does not exist yet: `git worktree add .claude/worktrees/<name> -b claude/<name>`. If that path already exists, reuse it (`cd` into it) instead of creating a new one.
2. Move the changed files into the worktree (do not copy) so `main`/`master` is left clean: for each changed file, overwrite the worktree copy with the working-tree version, then restore it on `main`/`master` with `git restore <file>` (use `git stash -u` / `git stash pop` in the worktree for many files).
3. Commit and push changes: `git commit -am "" && git push -u origin HEAD`
4. Minimal report: branch, commit subject, and PR URL
