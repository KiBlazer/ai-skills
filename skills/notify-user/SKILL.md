---
name: notify-user
description: 'Agent-decided semantic desktop notifications. Send only when a user-requested task is fully completed and verified, a genuinely independent milestone is finished, work is blocked or awaiting user approval/response, or a material failure needs immediate attention. Trigger terms: notify the user, send notification, desktop toast, completion reminder, awaiting approval, needs your response, notify, notification. Never notify for individual tool completions, partial work, background worker completion, intermediate tests, or generic done events.'
compatibility: 'Requires bash and Python 3. Transports: WSL2/Windows - silent Windows Toast via powershell.exe; macOS - osascript; Linux - notify-send when available; unsupported host or missing notifier - graceful no-op. Silent on every platform. Windows support is WSL2-only (no native Windows). Reports exactly one result line on stdout with exit 0, or a failure diagnostic on stderr with nonzero exit. Workspace disclosure is privacy-controlled: off | basename (default) | full. Works with Codex, OpenCode, and Claude Code.'
allowed-tools: 'Bash(${CLAUDE_SKILL_DIR}/scripts/notify-user *)'
---

# notify-user (AI Semantic Notification)

notify-user lets an agent decide for itself whether to notify the user, by sending a
semantic desktop notification. This skill is a self-contained Agent Skills package: the
executable helper is bundled at `scripts/notify-user`, and the skill depends on no plugin,
server, or repository code. After a Git clone it is independently usable.

Sending a notification must be a **deliberate final workflow step** — performed after final
verification and only when a condition below clearly applies. It is not an automatic behavior
on every tool completion.

## When to notify

Notify when **at least one** of these conditions holds:

1. **Complete verified work**: everything the user asked for is done, and you have finished
   final verification (for example: all verification commands pass, tests pass, no open
   issues you are expected to resolve).
2. **Genuinely independent milestone**: a well-defined milestone is finished and the remaining
   work is clearly separated and independently continuable (for example: migration phase 1 is
   done and phase 2 is a distinct follow-up; a core module refactor is complete and peripheral
   cleanup is a separate task).
3. **Blocked / awaiting user**: work is blocked, needs approval, or must wait for an essential
   user response to continue (for example: waiting for approval, the user must provide
   information, or an external dependency is pending).
4. **Material failure**: a real failure needs the user's immediate attention (for example:
   build/deploy failure, risk of data corruption) and you cannot resolve it within the current
   session.

Satisfying more than one condition at once is fine — still send only **one** notification per
final outcome. Do not send a second notification merely because another condition also holds.

## When never to notify

Notification is **forbidden** in these cases:

- an individual tool completion, or a test run finishing without a "verification passed"
  conclusion;
- partial implementation (work is not finished, or any part of the user's request remains
  undone);
- background worker (subagent) completion — unless the result falls under "complete verified
  work" or "material failure" above;
- intermediate tests, intermediate build success, or fragmentary mini-milestones;
- notifying about an already-finished subpart while the user's current request still has
  remaining work;
- ambiguous situations with no firm conclusion — prefer not to notify.

## Prerequisites and portability

This is an **Agent Skills package**: it can be reused across hosts and agents. The helper
itself has real runtime requirements that vary by host:

- **bash** and **Python 3** are required everywhere (the helper refuses to run without
  python3).
- The agent needs **ordinary shell permission** to execute the bundled script.
- **Windows** support is **WSL2-only** — it renders a silent Windows Toast through
  `powershell.exe`; native Windows is not supported.
- **macOS** uses `osascript`; **Linux** uses `notify-send` when available.
- On hosts with no usable notifier the helper reports `skipped` (exit 0) — a graceful no-op.

Claude Code specifics — the `${CLAUDE_SKILL_DIR}` variable and the `allowed-tools` frontmatter
entry — are **conveniences for Claude Code only**; other agents ignore them. Discovery is not
universal or automatic: Codex reads `~/.agents/skills/`, OpenCode auto-loads
`~/.agents/skills/<name>/SKILL.md`, and Claude Code may need a local symlink or install under
`~/.claude/skills/` before it finds this skill. Check your agent's own skill discovery rules
rather than assuming every agent shares one directory.

## Path resolution (important)

`scripts/notify-user` is an **Agent Skills relative bundle reference**: it is relative to the
directory containing this SKILL.md (the skill bundle root), **not** to the project working
directory. Do not run a literal `./scripts/notify-user` from the project root — that path
does not exist and is not CWD-safe.

- **Codex / OpenCode**: resolve the absolute sibling path from the discovered SKILL.md
  location, e.g. `<directory-that-contains-SKILL.md>/scripts/notify-user`. Grant the agent
  normal shell permission to execute the helper.
- **Claude Code**: `${CLAUDE_SKILL_DIR}/scripts/notify-user` is expanded by Claude Code to the
  skill directory (Claude-specific convenience).

## Platform behavior and output contract

The helper chooses the transport itself. **Successes and skips print exactly one line on
stdout with exit 0**: `notify-user: sent - <title>` or `notify-user: skipped - <reason>`.
**Invalid arguments and delivery failures print a `notify-user: failed - <diagnostic>` or
usage error on stderr and exit nonzero** (2 for argument errors, 1 for sanitization or
delivery failures). Child notifier stdout is suppressed so the helper's stdout stays exactly
one line; useful diagnostics remain on stderr. Callers must check the exit status and read
the appropriate stream, and must never claim delivery when the exit is nonzero.

## Workspace privacy

The helper automatically records its invocation working directory. How much of it is shown is
controlled by `NOTIFY_USER_WORKSPACE`:

- `off` — no workspace line at all.
- `basename` — only the final directory name (for example `Workspace: rivu`). **This is the
  default** and the recommended setting for sensitive locations.
- `full` — the full path, with the home directory abbreviated as `~` and left truncation for
  very long paths (for example `Workspace: ~/projects/rivu`).

**Agents must not include the working directory in the title or body themselves** — the
helper adds the workspace line automatically according to the mode. Desktop notifications can
be visible to people near the screen and can persist in notification centers, so prefer
`basename` or `off` when the working directory is sensitive. The `full` mode is the most
convenient for your own personal machines, but it discloses the full path.

## Notification message format

Construct the message from a title plus ONE optional compact context/action line:

- **Title** (required, ≤70 chars): concise outcome/decision.
  Examples: `Login timeout fix verified`, `Awaiting approval: create PR`, `Release build failed`.
- **Body** (optional, ≤70 chars): one compact context/action line.
  Examples: `rivu - main`, `Approve to continue`, `Decide: roll back or retry`.
- **Workspace line** (automatic): a `Workspace: <path>` line controlled by
  `NOTIFY_USER_WORKSPACE` (see above).

Only the **first nonempty body line** is delivered; any additional supplied body lines are
**discarded on every platform**. WSL2 renders the toast as at most three lines — title, the
single body line, and the Workspace line (when enabled). macOS and Linux show the body line
alongside the Workspace line (when enabled).

**Never include** in a notification: UUID/session IDs, raw prompts, secrets or tokens, long
logs, or a generic "done".

## How to send

Use the bundled helper — a single command; arguments are length-limited and character-safe.
See "Path resolution" above to pick the correct invocation for your agent.

```bash
# Claude Code
${CLAUDE_SKILL_DIR}/scripts/notify-user <complete|milestone|blocked|error> '<title>' '[body]'

# Codex / OpenCode (absolute sibling path of the discovered SKILL.md)
<directory-that-contains-SKILL.md>/scripts/notify-user <complete|milestone|blocked|error> '<title>' '[body]'
```

Examples:

```bash
# fully completed and verified
.../scripts/notify-user complete 'Login timeout fix verified' 'rivu - main'

# genuinely independent milestone
.../scripts/notify-user milestone 'Migration phase 1 complete' 'rivu - legacy-v2'

# blocked - needs user response (body states the action)
.../scripts/notify-user blocked 'Awaiting approval: create PR' 'Approve to continue'

# material failure
.../scripts/notify-user error 'Release build failed' 'Decide: roll back or retry'
```

Notes:

- Wrap title and body in single quotes to prevent shell expansion.
- Re-check the category before sending: `complete`/`milestone` for success, `blocked` when
  waiting on the user, `error` for failure.
- The helper never plays audio (silent toast / silent notification on every platform).
- The working directory is captured automatically per `NOTIFY_USER_WORKSPACE` — do not add it
  to the title or body yourself.
- Read the helper's exit status and disposition, and repeat the actual result accurately in
  your final answer; never claim delivery on error. The helper requires Python 3.

## Final-response disclosure

Using notify-user is a deliberate final workflow step. After invoking the helper, check its
exit status and read the appropriate stream, then state the **actual result** in your final
answer — `sent` or `skipped` — never blindly claim "sent", and never claim delivery when the
exit was nonzero. Examples:

> Completed and verified; notification delivered via notify-user (sent - complete - rivu - main).

> Notification skipped: no desktop notifier available on this host (skipped).

> Notification failed: the notifier reported an error (failed).

This keeps notification behavior visible and auditable, and prevents claiming delivery that
did not happen.
