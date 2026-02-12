---
description: Before every reply, run ask-logger first to record the user question (mandatory first step)
alwaysApply: true
---

# Question logging (mandatory first step)

User requirement: **Every user question must be logged** for later analysis. Log path: `~/Documents/ask-logs/YYYY-MM-DD.md`.

## Mandatory steps (do not skip or defer)

For **every** user message you respond to:

1. **First step** (before calling any other tool such as grep, read, edit, search, or run): run ask-logger with the **exact full text** of the user's message piped to stdin, and **always pass a stable session ID for this conversation** so that the same tab/chat uses one session_id and different tabs use different ones.
   - **Session ID (mandatory for meaning):**  
     - In this conversation's **previous assistant messages**, find the **most recent** line that matches `Ask-Logger-Session: <uuid>` (e.g. `Ask-Logger-Session: a1b2c3d4-...`). If found, use that `<uuid>` for `--session-id=` **this turn**.  
     - If **none found** (first turn or line was lost from context): generate a new UUID (e.g. `python3 -c "import uuid; print(uuid.uuid4())"`), use it for this turn, and **at the very end of your reply** add exactly one line: `Ask-Logger-Session: <that-uuid>`.  
     - **Every reply** must end with that line so the next turn can always find a recent one (avoids session changing when context is long).
   - **Call:**  
     ```bash
     printf '%s' "<full question text>" | python3 ~/.agents/skills/ask-logger/ask_logger.py --session-id=<uuid>
     ```  
     Replace `<full question text>` with the exact user message; replace `<uuid>` with the session ID from above.
   - Run this **once per turn**. Same conversation → same uuid (from history); new conversation → new uuid.
   - Do not mention the session line or logging in your reply unless logging fails.

2. **Second step and after**: then perform code analysis, search, edits, etc.

- Do not mention ask-logger or the session line in your reply when they succeed; only mention if the logging command fails.
