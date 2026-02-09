# AI Skills

A collection of reusable AI skills that extend AI assistant capabilities for specialized tasks.

## What are Skills?

Skills are modular extensions that provide AI assistants with domain-specific capabilities. Each skill contains:
- **SKILL.md**: Instructions and documentation
- **scripts/**: Helper scripts and utilities
- **examples/**: Reference implementations

## Available Skills

### 📝 [ask-logger](skills/ask-logger)
Automatically captures and logs user questions with contextual metadata to daily markdown files.

**Key Features:**
- Automatic question logging with timestamps
- Git branch and project context tracking
- Daily markdown files (`YYYY-MM-DD.md`)
- Silent execution, no workflow interruption
- Cross-platform compatible



**Use Case:** Track all AI interactions for later analysis, pattern recognition, and knowledge management.

## Installation

This project provides an out-of-box deployment system. Simply clone and sync:

```bash
# Clone the repository
git clone <repo-url> ai-skills
cd ai-skills

# Run sync script (one command!)
./sync_skills.sh
```

**What happens automatically:**
- Skills synced to `~/.agents/skills/`
- Global rules installed to `~/.gemini/GEMINI.md` (for Antigravity)

The sync script is **idempotent** and **non-destructive**. It uses `config/global-agent.rules.md` as the single source of truth for global rules.

### For Cursor Users

Since Cursor configuration is project-based (or stored in a local database for global rules), you need to configure it manually to use ask-logger in **all your projects**:

1. Open Cursor
2. Go to **Settings** -> **General** -> **Rules for AI**
3. Copy the content from [`config/global-agent.rules.md`](config/global-agent.rules.md) in this repo
4. Paste it into the "Rules for AI" text box
5. **Important**: Ensure your Agent mode is set to **"Run Everything"** (or similar "YOLO" mode) to allow the script to execute silently without asking for permission every time.

Once done, `ask-logger` will work globally in any project you open with Cursor.

## Usage

Skills are now automatically available to your AI assistant. For ask-logger specifically, all your questions will be automatically logged to `~/Documents/ai-logs/YYYY-MM-DD.md`.

To view skill documentation:

```bash
# View skill documentation
cat skills/<skill-name>/SKILL.md
```

AI assistants can automatically invoke skills by reading the SKILL.md instructions and executing the provided scripts.

## Contributing

To add a new skill:
1. Create a directory under `skills/`
2. Add a `SKILL.md` with YAML frontmatter (name, description) and instructions
3. Include any necessary scripts or resources
4. Update this README

## License

MIT
