---
name: subagent-supervisor
description: When the user wants to parallelize work into multiple Codex subagents (via `codex --yolo exec`), use this skill to plan tasks, spawn subagents, and merge their outputs. Do NOT use for simple single-step tasks.
---

You are the supervisor. Split the work into 3-6 parallel subagent tasks.

For each task, spawn a headless subagent by running:
  codex --yolo exec "<TASK PROMPT>"

Rules:
- Keep each subagent prompt self-contained: goal, files to inspect, exact outputs.
- Avoid unescaped shell interpolation: no backticks, no $().
- Each subagent must write findings to a file under ./_agent_reports/ as markdown.
- Prefer deterministic outputs: bullet lists, file paths, and concrete actions.

Workflow:
1) Create ./_agent_reports/ if missing.
2) Spawn subagents (can be parallel).
3) After all subagents finish, read the reports.
4) Produce a merged final answer + next actions.
