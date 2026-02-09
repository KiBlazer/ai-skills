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

## Usage

To use a skill, read its `SKILL.md` file for detailed instructions:

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
