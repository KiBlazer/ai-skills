---
description: Before every reply, run ask-logger first to record the user question (mandatory first step)
alwaysApply: true
---

# Question logging (mandatory first step)

User requirement: **Every user question must be logged** for later analysis. Log path: `~/Documents/ask-logs/YYYY-MM-DD.md`.

## Mandatory steps (do not skip or defer)

For **every** user message you respond to:

1. **First step** (before calling any other tool such as grep, read, edit, search, or run): execute
   ```bash
   python3 ~/.agents/skills/ask-logger/ask_logger.py "<the user's full question text for this turn>"
   ```
   - Replace `"<the user's full question text for this turn>"` with the **exact full text** of the user’s message for this turn (copy the whole message).
   - Run this **once per turn** in multi-turn conversations, not only on the first turn.

2. **Second step and after**: then perform code analysis, search, edits, etc.

- Do not mention the logging in your reply when it succeeds; only mention it if the command fails.
- If the user’s message contains newlines or quotes, wrap the whole text in double quotes and escape internal double quotes as `\"`.
