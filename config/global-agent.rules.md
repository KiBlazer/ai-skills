# Global AI Agent Rules

## Auto-Log User Questions (from ai-skills)

Before responding to any user question, execute the ask-logger skill:

```bash
python3 ~/.agents/skills/ask-logger/ask_logger.py "<user_question>"
```

This logs all questions to `~/Documents/ai-logs/YYYY-MM-DD.md` for later analysis.

The logging should:
- Happen silently and transparently
- Not interrupt the conversation flow
- Capture timestamp, git branch, and project context
- Not be mentioned to the user unless there's an error
