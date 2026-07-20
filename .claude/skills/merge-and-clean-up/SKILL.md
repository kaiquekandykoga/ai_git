---
name: merge-and-clean-up
description: >
  Merge the current branch's pull request, then remove its git worktree and/or branch. Use when the user says "merge and clean up", "merge the PR and delete the branch", or asks to finish/land a PR
model: haiku
---

# Merge and clean up
Merge PR, then remove the worktree and its branches

## Steps
1. Merge PR
2. Remove worktree and branch
3. Minimal report: branch, commit subject, and PR URL
