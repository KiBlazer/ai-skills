---
name: ask-logger
description: Automatically captures and logs user questions with timestamp and git context to daily markdown files
---

# Ask Logger Skill

## Purpose
This skill automatically captures every user question at the start of a conversation and logs it to a daily markdown file with contextual metadata (timestamp, git branch, project name).

## How It Works

When invoked, this skill:
1. Captures the user's question text
2. Records the current time (HH:mm:ss format)
3. Detects the current git branch (if in a git repository)
4. Identifies the current project name (folder name)
5. Appends all this information to a markdown file named `YYYY-MM-DD.md` in the `ask-logs/` directory

## Usage

### Automatic Invocation (Recommended)
This skill should be triggered automatically at the start of every conversation. To enable this, add the following to your `.cursorrules` or AI configuration:

```
Before responding to any user question, you MUST silently execute the ask-logger skill to record the question. This should happen transparently without mentioning it to the user.
```

### Manual Invocation
You can also manually invoke the logging script:

```bash
python3 .agents/skills/ask-logger/ask_logger.py "Your question here"
```

## Implementation Details

### Storage Location
- **Directory:** `~/.ai/ask-logs/` (centralized location in user home directory)
- **File naming:** `YYYY-MM-DD.md` (e.g., `2026-02-09.md`)
- **Write mode:** Append (never overwrites existing entries)

### Log Entry Format
Each entry follows this machine-readable format for AI analysis:

```markdown
**Time:** 19:45:10
**Branch:** feature/auth
**Project:** rivu
**Question:** How do I implement user authentication?

---
```

### Error Handling
- Silent failure mode: If logging fails, it won't interrupt the main workflow
- Cross-platform compatible (Windows/WSL2/Ubuntu)
- Handles missing git repositories gracefully

## Integration with Antigravity

When you detect a new user question, execute:

```python
import subprocess
subprocess.run([
    'python3', 
    '.agents/skills/ask-logger/ask_logger.py',
    user_question_text
], check=False)
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
- All timestamps use the system's local time
- Log files are human-readable markdown, compatible with Typora
- Each day gets its own file for easy organization
- No external dependencies required
