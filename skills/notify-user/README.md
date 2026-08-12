# notify-user

Agent-decided semantic desktop notifications. The agent itself decides **when** to notify —
only after a fully completed and verified user-requested task, at a genuinely independent
milestone, when blocked or awaiting user approval/response, or on a material failure. This
package is a self-contained [Agent Skills](https://agentskills.io) skill: `SKILL.md` plus a
portable `scripts/notify-user` helper, with no plugin or server dependency.

## Purpose and non-goals

**Purpose:** a single, auditable way for an agent to alert a human at exactly the moments
that matter (finished-and-verified work, a real milestone, a blocker, or a material failure),
with silent, platform-native notifications and an accurate delivery disposition.

**Non-goals:**

- No automatic notifications on tool completion, partial work, background worker completion,
  intermediate tests, or generic "done" events. The agent decides; this package only delivers.
- No sound/audio of any kind.
- No GUI, daemon, or always-on service.
- No telemetry, analytics, or network calls (except the local OS notifier itself).
- Not a substitute for `sent` = visually confirmed: see [Limitations](#limitations).

## Platform and dependency matrix

| Platform | Transport | Notes |
| --- | --- | --- |
| WSL2 / Windows | silent Windows Toast via `powershell.exe` | Windows support is **WSL2-only**; native Windows is not supported |
| macOS | `osascript` | foreground |
| Linux | `notify-send` when available | foreground; otherwise `skipped` |
| anything else / missing notifier | none | reports `skipped`, exit 0 (graceful no-op) |

Runtime requirements: **bash** and **Python 3** (required on every host), plus the platform
notifier above. The agent needs ordinary shell permission to execute the helper. Notifications
are silent on every platform.

## Install

From a Git clone of this repository:

```bash
git clone <repo-url> ai-skills
cd ai-skills
```

### Codex

Codex reads skills from `~/.agents/skills/`. Copy or symlink the skill there:

```bash
cp -r skills/notify-user ~/.agents/skills/notify-user
# or: ln -s "$(pwd)/skills/notify-user" ~/.agents/skills/notify-user
```

### OpenCode

OpenCode auto-loads `~/.agents/skills/<name>/SKILL.md` as an external skill, so the Codex
install above also covers OpenCode. Alternatively copy the skill under
`~/.config/opencode/skills/notify-user/`.

### Claude Code

Claude Code reads skills from `~/.claude/skills/` (by default). Make the skill reachable
there — a local symlink works with typical installs:

```bash
ln -s "$(pwd)/skills/notify-user" ~/.claude/skills/notify-user
```

If a Claude Code installation does not follow the symlink, copy the directory instead.
Discovery is **not** universal or automatic across agents — check your agent's own skill
discovery rules.

## Usage

Invoke the bundled helper directly. Arguments are length-limited and character-safe; only the
first nonempty body line is delivered (later lines are discarded on every platform).

```bash
<skill-dir>/scripts/notify-user <complete|milestone|blocked|error> '<title>' '[body]'
```

Examples:

```bash
.../scripts/notify-user complete 'Login timeout fix verified' 'rivu - main'
.../scripts/notify-user milestone 'Migration phase 1 complete' 'rivu - legacy-v2'
.../scripts/notify-user blocked 'Awaiting approval: create PR' 'Approve to continue'
.../scripts/notify-user error 'Release build failed' 'Decide: roll back or retry'
```

Conventions:

- `scripts/notify-user` is a **relative bundle reference** resolved from the directory
  containing `SKILL.md`, never from the project working directory — do not run
  `./scripts/notify-user` from the project root.
- Title/body are wrapped in single quotes to prevent shell expansion.
- The working directory is captured automatically (see Workspace privacy); agents must not
  pass it in the title or body.

Environment variables:

| Variable | Values | Default | Purpose |
| --- | --- | --- | --- |
| `NOTIFY_USER_WORKSPACE` | `off`, `basename`, `full` | `basename` | How much of the working directory is disclosed |
| `NOTIFY_USER_PLATFORM` | `wsl`, `macos`, `linux`, `unsupported` | auto-detect | Test hook that forces platform dispatch |

## Output and exit status contract

| Outcome | stdout | stderr | exit |
| --- | --- | --- | --- |
| delivered | exactly one line: `notify-user: sent - <title>` | (empty) | 0 |
| skipped (no notifier) | exactly one line: `notify-user: skipped - <reason>` | (empty) | 0 |
| delivery/sanitization failure | (empty) | `notify-user: failed - <diagnostic>` | 1 |
| invalid arguments | (empty) | usage error | 2 |

Callers must check the exit status and read the appropriate stream, and must never claim
delivery when the exit is nonzero. Child notifier stdout is suppressed so the helper's
stdout stays exactly one line; notifier diagnostics remain visible on stderr.

## Workspace privacy

Desktop notifications can be seen by people near the screen and can persist in notification
centers. `NOTIFY_USER_WORKSPACE` controls disclosure of the invocation working directory:

- `off` — no workspace line at all. Recommended for sensitive locations.
- `basename` — only the final directory name, e.g. `Workspace: rivu`. **Default.**
- `full` — full path with home abbreviated as `~` and left truncation, e.g.
  `Workspace: ~/projects/rivu`. Most convenient on personal machines; discloses the path.

## Limitations

- **`sent` means the notification was accepted by the platform API, not that a human saw
  it.** It does not confirm visual delivery, focus, or that anyone was at the screen.
- WSL2 rendering depends on Windows notification settings (Do Not Disturb can suppress
  toasts); macOS `osascript` notifications can be blocked by Focus modes; Linux depends on a
  running notification daemon (hence `skipped` or `failed` otherwise).
- No audio by design; do not rely on sound to attract attention.
- The helper requires Python 3; it exits `failed` if python3 is unavailable.

## Security notes

- Title/body/workspace text is escaped before being embedded in any transport payload and is
  never injected into PowerShell/AppleScript source.
- On WSL2, each invocation writes a unique, randomly named toast file (race-safe `mktemp`)
  that is removed after use; cleanup is scoped to the invoking process.
- No secrets, tokens, or session identifiers are ever included; the helper performs no
  network calls and has no dependency on any plugin or third-party service.

## Tests

No external test framework is required:

```bash
bash tests/test-notify-user.sh
```

The suite uses PATH mocks and the documented `NOTIFY_USER_PLATFORM` / `NOTIFY_USER_WORKSPACE`
hooks to cover argument validation, the sent/failed/skipped protocol and streams, single-body-
line behavior, workspace privacy modes, WSL preflight failure, XML escaping, and concurrent
unique temp-file handling. It leaves no artifacts behind.

## Upgrade and remove

Upgrade by re-copying/symlinking the skill from a fresh clone (the helper and `SKILL.md` are
self-contained). Remove by deleting the skill directory you installed (for example
`~/.agents/skills/notify-user`, `~/.config/opencode/skills/notify-user`, or
`~/.claude/skills/notify-user`) and any symlink pointing at it.

## License

MIT — see [LICENSE](LICENSE).
