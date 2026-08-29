# AGENTS.md

## Core Directive: Extreme Token Efficiency
Maximize cost efficiency across all LLM operations. Cost optimization must never compromise correctness, safety, or comprehensive verification.

## 1. Token Constraints
* **Zero Fluff:** Do not narrate plans before tool calls. Do not summarize or celebrate after successes. Transition directly between tools.
* **Minimalist Output:** Keep final responses brief, scannable, and direct. Prioritize bullet points over paragraphs.
* **Targeted Context:** Do not read whole files or directory trees speculatively. Use precise tools (`Grep`, specific line ranges) to minimize input tokens.

## 2. Quality & Execution
* **Complete Code:** Write fewer lines of code by being precise, not by skipping error boundaries, input validation, or edge cases.
* **Comments:** See section 3. Section 3 is the complete rule; do not infer additional comment conventions from surrounding code.
* **Strict Verification:** Never assume success. Run relevant test suites and linters before marking a task complete.
* **No Ghost Fixes:** Report raw failures honestly. Fix errors directly; never mask or suppress them to save output tokens.

## 3. Comments

### 3.1 Which files carry a header
**Required** — these and nothing else:
* every `*.rb` under `lib/` and `test/`
* every executable under `bin/` (`bin/ai_git`, `bin/check_release`)
* `Rakefile`, `Gemfile`, and `ai_git.gemspec`

**Exempt — do not add a header:**
* Formats with no comment syntax: `*.json`, `*.lock`, `Gemfile.lock`, `.claude/settings.json`.
* Prose: every `*.md`, including `README.md`, `doc/TODO.md`, and this file, plus `LICENSE`. A Markdown document states its own subject in its title and opening lines; a header would duplicate it.
* Repo and CI config: `.gitignore`, `.rubocop.yml`, `.claude/**`, `.github/**`.

A path that falls outside both lists is exempt. Do not extend either list by analogy.

### 3.2 When to write one
Write the header when you create a required file. Update it when you change the behavior, exports, dependencies, or side effects of a required file you are already editing. Do not retrofit headers into files you are not otherwise touching, and never make a commit whose only content is added headers.

### 3.3 Format
At the very top of the file — after a shebang and any `# frozen_string_literal: true`, before the first `require` — followed by one blank line:

```
# lib/ai_git/git.rb
#
# @purpose      Wrap the git porcelain this tool drives: inspect the staged
#               tree, then commit and push on the user's behalf.
# @exports      AIGit::Git: NOT_A_REPOSITORY, MAX_ERROR_DETAIL, .repository?,
#               .ensure_repository!, .staged_files, .diff, .current_branch,
#               .detached_head?, .commit_with_message, .push_current_branch.
# @dependencies git: every operation shells out to the binary;
#               open3: captures stdout, stderr, and exit status together;
#               tempfile: holds the commit message passed to `git commit -F`.
# @sideEffects  Spawns git subprocesses; writes a tempfile; mutates the
#               repository and the remote on commit and push.
# @notes        Raises a bare string message; bin/ai_git renders it and exits 1.
```

* Use the file's native comment marker (`#` for Ruby, Rakefile, gemspec, and Gemfile).
* First line: the path exactly as it appears on disk, repo-relative, with no `@` tag.
* Second line: the bare comment marker.
* Tags start at column 3. Values start at column 17. Continuation lines are blank to column 17. Wrap at 80 columns.
* The block above is the reference implementation of this format; match it exactly.

### 3.4 Field content
Fields appear in this order and no other.

* `@purpose` — required. 1–2 sentences on why the file exists and its single responsibility.
* `@exports` — the public contract: constants, modules, classes, methods, rake tasks, CLI subcommands and flags. Name them; do not explain them. Private helpers are not exports. For a test file, name the subject under test rather than the individual test methods. Omit the field only when the file defines nothing another file or the CLI can reach.
* `@dependencies` — `name: purpose/interaction` pairs separated by `;`. Internal modules, gems, and external binaries only. Omit stdlib requires unless the interaction is non-obvious. Omit the field when there are none.
* `@sideEffects` — required. Filesystem writes, network calls, subprocess spawns, environment mutation, global state, signal handlers, `exit`. Write `None.` when the file is pure — the absence of side effects is information worth stating.
* `@notes` — non-obvious constraints, deliberate design choices, edge-case handling. Omit the field rather than padding it.

### 3.5 No body comments
No inline or block comment inside a module, class, or method body, and none between top-level statements. Commented-out code is never permitted.

One inline comment, one line, is allowed only when the line implements a mathematical algorithm whose derivation is unreadable from the code, or works around a documented bug in an external tool. Name that reason in the comment.

### 3.6 Keep it true
The header is part of the file. When behavior, exports, dependencies, or side effects change, update the affected lines in the same edit and delete any line that no longer holds. A stale header is a defect in that file.
