# 共享 Agent Skills 目录

本目录被 **Cursor**、**Gemini CLI**、**Codex** 共同读取：

| 工具        | 实际读取路径              | 说明 |
|-------------|---------------------------|------|
| Codex       | `~/.agents/skills`         | 原生支持（USER 级） |
| Gemini CLI  | `~/.agents/skills` 或 `~/.gemini/skills` | 已通过 symlink 指向本目录 |
| Cursor      | `~/.cursor/skills`        | 已通过 symlink 指向本目录 |

**维护方式**：只在本目录（`~/.agents/skills/`）下增删改 skill，三个工具会自动共用。

每个 skill 为一个子目录，内含 `SKILL.md`（必选），可选 `scripts/`、`references/`、`assets/` 等。
