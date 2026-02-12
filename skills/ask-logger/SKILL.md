---
name: ask-logger
description: Automatically captures and logs user questions with timestamp and git context to daily markdown files
---

# Ask Logger Skill

## Purpose
This skill automatically captures every user question at the start of a conversation and logs it to a daily markdown file with contextual metadata (timestamp, git branch, project name).

## How It Works

When invoked, this skill:
1. Reads the user's question text from **stdin** (tool-agnostic; no quoting issues)
2. Records the current time in `YYYY-MM-DD HH:mm:ss` format
3. Optionally records a session ID if passed via `--session-id=...`
4. Detects the current git branch (if in a git repository)
5. Identifies the current project name (folder name)
6. Appends all this information to a markdown file named `YYYY-MM-DD.md` in the `ask-logs/` directory

## Usage

### Input contract (multi-tool support)
- **Question content:** Passed **only via stdin**. Works the same in Cursor, Codex, Windsurf, or any AI Coding tool.
- **Session ID** (for “one session per conversation”): (1) CLI `--session-id=UUID`, or (2) env `ASK_LOGGER_SESSION_ID` / `AI_SESSION_ID`. Priority: CLI over env. To get **one unique session per tab/chat** when the host does not provide it: the agent can reuse a stable ID from the conversation—e.g. look for a line `Ask-Logger-Session: <uuid>` in prior assistant messages and pass that `<uuid>` to `--session-id=`; if none exists (first turn), generate a UUID, pass it, and append `Ask-Logger-Session: <uuid>` to the reply so the next turn reuses it. Same conversation → same ID; different conversation → different ID.

### Automatic Invocation (Recommended)
Configure your AI assistant to run ask-logger at the start of every turn: pipe the user's message to stdin, e.g.:

```
Before responding to any user question, pipe the exact user message to ask-logger via stdin, then proceed with your response.
```

### Manual Invocation
Pass the question via stdin (recommended):

```bash
printf '%s' "Your question here" | python3 ~/.agents/skills/ask-logger/ask_logger.py
# With optional session ID:
printf '%s' "Your question" | python3 ~/.agents/skills/ask-logger/ask_logger.py --session-id=my-session-uuid
```

From a file:

```bash
python3 ~/.agents/skills/ask-logger/ask_logger.py < question.txt
```

## Implementation Details

### Storage Location
- **Directory:** `~/Documents/ask-logs/` (or fallback under `/tmp/ai-ask-logs` if needed)
- **File naming:** `YYYY-MM-DD.md` (e.g., `2026-02-11.md`)
- **Write mode:** Append (never overwrites existing entries)

### Log Entry Format
Each entry follows this machine-readable format for AI analysis:

```markdown
**Time:** 2026-02-11 19:45:10
**Session:** optional-uuid-if-provided
**Status:**
**Type:**
**Branch:** feature/auth
**Project:** rivu
**Question:** How do I implement user authentication?

---
```

### Error Handling
- Silent failure mode: If logging fails, it won't interrupt the main workflow
- Cross-platform compatible (Windows/WSL2/Ubuntu)
- Handles missing git repositories gracefully

## Integration (any AI Coding tool)

Use stdin for the question so the same contract works everywhere (Cursor, Codex, Windsurf, etc.):

**Cursor / global rules:**  
`printf '%s' "<user message>" | python3 ~/.agents/skills/ask-logger/ask_logger.py`

**Codex / Windsurf / other:**  
Same: pipe the current user message to `ask_logger.py`; add `--session-id=...` if the tool provides a conversation ID.

**From code (e.g. Python runner):**

```python
import subprocess
subprocess.run(
    ['python3', '~/.agents/skills/ask-logger/ask_logger.py'],
    input=user_question_text.encode('utf-8'),
    check=False,
)
```

The script runs silently and won't block or interfere with your response.

## File Structure

```
.agents/skills/ask-logger/
├── SKILL.md          # This file
└── ask_logger.py     # Core logging script
```

## Dependencies
- Python 3.x (standard library only)
- Git (optional, for branch detection)

## Notes
- All timestamps use the system's local time in `YYYY-MM-DD HH:mm:ss` (no dependency on filename for date).
- **Status** and **Type** are reserved for later tagging (by scripts or AI); leave empty if not set.
- **One session per conversation (e.g. per Cursor tab):** If the host does not set a per-chat session (e.g. Cursor does not set `ASK_LOGGER_SESSION_ID` per tab), rules can require the agent to pass `--session-id=` and to keep it stable within the same chat: from conversation history, reuse the last `Ask-Logger-Session: <uuid>` from a previous assistant message; on the first turn, generate a UUID and append `Ask-Logger-Session: <uuid>` to the reply so the next turn reuses it. That way the same tab uses one session_id and different tabs use different ones.
- Log files are human-readable markdown, compatible with Typora.
- Each day gets its own file for easy organization.
- No product-specific env names; optional generic `ASK_LOGGER_SESSION_ID` / `AI_SESSION_ID`. Works with any AI Coding tool.
