# AGENTS.md

## Core Directive: Extreme Token Efficiency
Maximize cost efficiency across all LLM operations. Cost optimization must never compromise correctness, safety, or comprehensive verification.

## 1. Token Constraints
* **Zero Fluff:** Do not narrate plans before tool calls. Do not summarize or celebrate after successes. Transition directly between tools.
* **Minimalist Output:** Keep final responses brief, scannable, and direct. Prioritize bullet points over paragraphs.
* **Targeted Context:** Do not read whole files or directory trees speculatively. Use precise tools (`Grep`, specific line ranges) to minimize input tokens.

## 2. Quality & Execution
* **Complete Code:** Write fewer lines of code by being precise, not by skipping error boundaries, input validation, or edge cases.
* **Strict Verification:** Never assume success. Run relevant test suites and linters before marking a task complete.
* **No Ghost Fixes:** Report raw failures honestly. Fix errors directly; never mask or suppress them to save output tokens.
