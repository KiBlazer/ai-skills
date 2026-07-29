---
name: backlog-triage
description: Turn messy review notes, bug lists, TODOs, meeting notes, or scattered requirements into structured executable backlog tasks. Use when the user wants to classify issues, create tickets, prepare AI-executable tasks, or convert unstructured feedback into a workspace backlog file. This skill does not implement code changes.
---

# Backlog Triage

## Purpose

Convert messy input into clear, bounded, AI-executable backlog tasks and save them into the current workspace.

This skill is for triage only:

- Do not fix code.
- Do not start implementation.
- Do not expand scope beyond the provided input.
- Produce a backlog file that another AI or coding session can execute later.

## When to Use

Use this skill when the user provides:

- Review feedback
- Bug lists
- Product requests
- TODO lists
- Meeting notes
- Mixed technical or product issues
- Requests to organize items into tasks, backlog, or tickets

## Workflow

### 1. Normalize Input

Preserve every original item. Do not drop anything.

If an item is ambiguous, keep it and mark it as `Blocked` or `Investigation`.

### 2. Classify Each Item

Assign these fields:

- `Type`: `UI` / `Bug` / `Feature` / `Infra` / `Investigation` / `TechDebt` / `Doc` / `Test` / `Done`
- `Priority`: `P0` / `P1` / `P2` / `P3`
- `Area`: affected module, page, service, or workflow
- `Status`: `Inbox` / `Ready` / `Blocked` / `Investigation` / `Done`

Default priority rules:

- `P0`: production outage, data loss, security risk, or blocked core workflow
- `P1`: important user-facing bug or required high-value feature
- `P2`: normal feature, improvement, infrastructure enhancement, or non-critical bug
- `P3`: polish, cleanup, documentation, or low-risk optimization

Default status rules:

- `Ready`: scope and acceptance criteria are clear enough to execute
- `Blocked`: missing key decision, unclear requirement, or external dependency
- `Investigation`: analysis is required before implementation
- `Done`: explicitly marked as completed
- `Inbox`: recorded but not triaged enough

### 3. Merge or Split

Merge items when all conditions are true:

- same area, page, module, or workflow
- same type of change
- low implementation risk
- can be verified together

Split items when any condition is true:

- crosses frontend, backend, infrastructure, or external services
- changes data model, workflow, scheduler, storage, permissions, or integrations
- has unclear requirements
- requires investigation before implementation
- has independent acceptance criteria

### 4. Produce Executable Tickets

Each ticket must use this format:

```markdown
### TASK-XXX: Short title

- Type:
- Priority:
- Status:
- Area:
- Source:
- Scope:
- Out of Scope:
- Acceptance Criteria:
- Dependencies:
- Original Items:
```

Rules:

- `Scope` must state exactly what should be done.
- `Out of Scope` must prevent unrelated changes.
- `Acceptance Criteria` must be checkable.
- `Original Items` must reference the raw input numbers or text.

### 5. Write to Workspace Files

Use a batch-file plus active-index model.

Create or update these files in the current workspace:

```text
.ai/backlog.md
.ai/backlog/YYYY-MM-DD-short-topic.md
```

Rules:

- `.ai/backlog/YYYY-MM-DD-short-topic.md` stores the full triage result for one input batch.
- `.ai/backlog.md` is the active backlog index used by coding agents.
- Do not overwrite existing batch files unless the user explicitly asks.
- If a file name already exists, append a numeric suffix, for example `YYYY-MM-DD-short-topic-2.md`.
- If `.ai/` or `.ai/backlog/` does not exist, create it.
- Use the current local date for `YYYY-MM-DD`.
- Use a short kebab-case topic derived from the input, for example `review-feedback`, `sprint-review`, or `bug-list`.

Batch file structure:

```markdown
# Backlog Batch: YYYY-MM-DD short topic

## Source

Briefly describe where the input came from.

## Ready

## Investigation

## Blocked

## Done

## Raw Input Mapping
```

Active index structure:

```markdown
# AI Backlog Index

## Active Ready

- [ ] TASK-XXX: title — `.ai/backlog/YYYY-MM-DD-short-topic.md`

## Active Investigation

- [ ] TASK-XXX: title — `.ai/backlog/YYYY-MM-DD-short-topic.md`

## Active Blocked

- [ ] TASK-XXX: title — `.ai/backlog/YYYY-MM-DD-short-topic.md`

## Completed

## Batches

- YYYY-MM-DD: short topic — `.ai/backlog/YYYY-MM-DD-short-topic.md`
```

When updating `.ai/backlog.md`:

- Add new executable tickets to the appropriate Active section.
- Add the batch file to `## Batches`.
- Preserve existing content.
- Do not move completed or old items unless the user asks.

### 6. Final Response

Keep the final response short. Include only:

- where the backlog was written
- how many tickets were created
- the suggested next prompt for execution

Example:

```text
Backlog written to .ai/backlog.md. Created 6 tickets.
Next prompt: Read .ai/backlog.md and execute one Status=Ready ticket at a time.
```

## Execution Prompt Template

When the user wants a coding AI to execute tasks, suggest this prompt:

```text
Read .ai/backlog.md and select one ticket with Status=Ready and the highest Priority.
Rules: process only one ticket at a time; modify only the Scope; verify after completion; if new issues are found, create new tickets instead of fixing them immediately.
```
