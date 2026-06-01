---
name: go
description: Implement a Claude Code implementation plan and then run "/simplify"
user-invocable: true
argument-hint: "[plan-file-path]"
model: opus
---

You are the implement agent. Your task is to implement a Claude Code implementation plan and then run the "/simplify" slash command.

## 1. Locate the plan file

Use the first available option in this priority order:

### Option A: User-provided argument

If the user provided a plan file path as an argument to this skill, use that path.

### Option B: Plan from current context

Check if the conversation context contains a plan file path. Look for system reminders or recent messages mentioning:

- "Write [plan]"
- "plan file at [path]"
- "create your plan at [path]"
- "Plan File Info:" followed by a plan file path

If found, use that plan file path.

### Option C: Most recent plan (fallback)

Find the most recent plan file:

```bash
ls -t ~/.claude/plans/*.md | head -1
```

Verify the file exists. If not, show an error with the absolute path you tried.

## 2. Execute the implementation plan

1. Read the implementation plan at the specified path.
2. Follow the plan carefully, executing all steps outlined to complete the implementation. Make all necessary code changes.

## 3. Simplify

Launch three review agents **in parallel** (single message, three Agent tool calls), passing the full diff as context. Agent specs (matching `/simplify`):

- **Reuse agent** — Look for existing utilities, helpers, components, or patterns in the codebase that could replace newly written code. Identify duplicated logic, parallel inline paths where a shared helper already exists, and reinvented wheels.
- **Quality agent** — Flag redundant state, parameter sprawl, copy-paste, leaky abstractions, stringly-typed code, unnecessary nesting, nested conditionals, and unnecessary comments. Prefer simplicity and readability.
- **Efficiency agent** — Flag redundant work, missed concurrency, hot-path bloat, recurring no-op updates, unnecessary existence checks, memory waste, and overly broad operations (e.g. fetching more data than needed).

Each agent should report concrete findings with file paths and line numbers, not vague suggestions. Brief each agent like a smart colleague who just walked in: include the full diff, the goal (catch issues before the prod tag goes out), and ask for a punch list.

## 4. Commit changes

Draft a 1-2 sentence commit, with an industry standard commit message that focuses on the "why" rather than the "what".
