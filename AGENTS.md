# AGENTS.md

## Core Directive: Extreme Token Efficiency
Maximize cost efficiency across all LLM operations. Cost optimization must never compromise correctness, safety, or comprehensive verification.

## Public Repository: No Sensitive Data
This repository is open source and ships to RubyGems as the `ai_git` gem. Every commit, tag, workflow log, and released file is world-readable, and published history cannot be taken back.

* **Never commit or push secrets:** API keys, tokens, passwords, private keys, `.env` files, or credentials of any kind — including in tests, fixtures, examples, and workflow files. CI credentials belong in GitHub Actions secrets; a user's own settings belong in `~/.ai_git/config.yml`, which lives outside the repo.
* **Never commit private material:** real staged diffs, prompts, or LLM output captured from a user's work; internal hostnames or URLs; personal data; absolute paths that expose a home directory or machine name. Write examples against invented values.
* **Assume publication:** anything written here is public the moment it is pushed. Treat a `git push` to `master` as a publication, and the release workflow as a publication to RubyGems.
* **If sensitive data reaches the tree:** stop, report it, and do not push. If it was already pushed, say so plainly — rotating the secret and rewriting the published history is the user's call, not a fix to apply silently.

## 1. Token Constraints
* **Zero Fluff:** Do not narrate plans before tool calls. Do not summarize or celebrate after successes. Transition directly between tools.
* **Minimalist Output:** Keep final responses brief, scannable, and direct. Prioritize bullet points over paragraphs.
* **Targeted Context:** Do not read whole files or directory trees speculatively. Use precise tools (`Grep`, specific line ranges) to minimize input tokens.

## 2. Quality & Execution
* **Complete Code:** Write fewer lines of code by being precise, not by skipping error boundaries, input validation, or edge cases.
* **Readable Code:** Clear names and single-responsibility methods carry the meaning; comments cover what the code cannot say. Section 3 is the complete rule; do not infer additional comment conventions from surrounding code.
* **Strict Verification:** Never assume success. Run relevant test suites and linters before marking a task complete.
* **No Ghost Fixes:** Report raw failures honestly. Fix errors directly; never mask or suppress them to save output tokens.

## 3. Comments
Comments are allowed anywhere they earn their place. The first tool for making code understandable is the code, so a comment is what remains after the code itself has been made clear.

### 3.1 Readable code first
Before writing a comment, spend the effort on the code:

* **Name things for what they are.** `staged_files`, `insecure_remote_base_url?`, `retry_delay` — a name that states the meaning removes the need to explain it. Avoid abbreviations, single letters outside a short block, and names that describe a type rather than a role.
* **One responsibility per method.** A method does one thing at one level of abstraction, short enough to read at a glance. When a comment would be needed to mark where a method changes subject, extract that part into a method whose name says what the comment would have said.
* **Make the structure carry the meaning.** Guard clauses over nesting, a well-named predicate over an inline condition, a named constant over a literal.

The payoff is fewer comments: readable code needs little explanation, and there is nothing to keep in sync.

### 3.2 When to comment
Write a comment where the code cannot explain itself, however well written:

* Logic whose derivation is not visible — a formula, an algorithm, a non-obvious regex or bit of parsing.
* A workaround for the behavior of an external tool, service, or format, naming what forced it.
* A deliberate choice whose reason lives outside the file — a safety or security rule, an ordering constraint, an edge case a reader would otherwise take for a mistake.
* A file whose purpose is not obvious from its name and contents: a short comment at the top, in prose, saying what it is for.

Explain the *why*, not the *what*: a comment that restates the line above it is noise, and it rots. Keep it short — one or two lines is usually enough — and delete it when the code it describes is gone.

### 3.3 Not permitted
* Commented-out code. Delete it; git remembers.
* Comments that paraphrase the code, mark obvious sections, or decorate the file with banners and rule-off lines.
* Structured tag headers (`@purpose`, `@exports`, `@dependencies`, `@sideEffects`) — the project dropped them in favor of readable code and targeted comments. Do not reintroduce them, and do not add a header to a file just because other files have one.

Machine-read comments are not comments for this purpose: the shebang, `# frozen_string_literal: true`, and directives such as `# rubocop:disable` / `# rubocop:enable` are always allowed wherever the tool requires them.

### 3.4 Keep it true
A comment is part of the code around it. When that code changes, update the comment in the same edit and delete it if it no longer holds. A stale comment is a defect in the file that carries it: fix it in a file you are already editing, and report one you notice elsewhere rather than opening the file for it.

## 4. Markdown file names
Every `*.md` file in this repository is named in upper case: the stem is all capitals, words separated by `_`, and the extension stays lower-case `.md` — `README.md`, `AGENTS.md`, `doc/USAGE.md`, `CODE_OF_CONDUCT.md`. Directory names are unaffected; `doc/` stays lower-case.

Create a new Markdown file under this rule, and rename one that arrives in any other case with `git mv`, updating every reference to it in the same change.
