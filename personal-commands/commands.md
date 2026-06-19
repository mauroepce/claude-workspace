---
description: List all installed personal slash commands with their descriptions, install dates, and a quick reference for what each does. Use when you're new to the toolkit, returning after a break, or just want to see what's available without browsing the filesystem.
---

# /commands — Self-discovery of the toolkit

You are Claude. The user wants to see what personal slash commands they have installed and what each does.

This is the self-documentation command. Useful when:
- You've been away from the toolkit for weeks and forgot the names
- You just installed the toolkit on a new machine
- You're not sure which command to invoke for a task

## Phase 1 — Scan installed commands

```bash
ls -t ~/.claude/commands/*.md 2>/dev/null
```

If the directory is empty or doesn't exist, output:

> "No personal commands installed. Run:
>
> curl -fsSL https://raw.githubusercontent.com/mauroepce/claude-workspace/main/bin/install-personal.sh | bash
>
> to install Mauricio's toolkit."

If commands exist, proceed.

## Phase 2 — Extract metadata

For each `.md` file, read the frontmatter and get the `description:` field. Note the file's modified date (the install date or last update).

Group commands by category:

| Category | Commands |
|---|---|
| **Task framework** | `/work`, `/quick-work`, `/todo`, `/issue` |
| **Codebase understanding** | `/conventions`, `/architecture`, `/journeys`, `/onboard` |
| **Debugging & decisions** | `/debug`, `/decision` |
| **Code review & commit** | `/code-review`, `/safe-commit`, `/safe-push` |
| **Scaffolding** | `/scaffold` |
| **Meta** | `/commands` (this one) |

If a command doesn't fit any category, list it under "Other".

## Phase 3 — Output

Present in this format (don't make this fancy — clarity over aesthetics):

```
PERSONAL COMMANDS INSTALLED (~/.claude/commands/)

Task framework
  /work         — spec → generate → review → iterate framework
  /quick-work   — lite /work for small tasks
  /todo         — persistent task tracking (cross-session)
  /issue <N>    — pull a GitHub issue and structure context

Codebase understanding
  /conventions  — scan codebase for style/patterns (persists to .claude/conventions.md)
  /architecture — scan codebase structure (persists to .claude/architecture-map.md)
  /journeys     — Mermaid sequence diagrams of user flows
  /onboard      — orchestrate the above three for day-one ramp-up

Debugging & decisions
  /debug        — hypothesis-driven debugging
  /decision     — capture a technical decision with confidence level

Code review & commit
  /code-review  — atomic quality review of staged/specified changes
  /safe-commit  — runs /code-review + /security-review + commit with confirm
  /safe-push    — full-branch review + push (refuses main without OK)

Scaffolding
  /scaffold     — pick a template from ~/.claude/templates/ and insert it

Meta
  /commands     — this command — list everything installed

Last update: <most recent file mtime>
Total: <count> commands installed
```

## Phase 4 — Offer next step

End with:

> "All command source files live at ~/.claude/commands/. To see a command's full prompt, just `cat ~/.claude/commands/<name>.md`.
>
> To update or reinstall: curl -fsSL https://raw.githubusercontent.com/mauroepce/claude-workspace/main/bin/install-personal.sh | bash"

## What NOT to do

- Don't show stale commands. If a command exists in `~/.claude/commands/` but is no longer in the official PERSONAL_COMMANDS list, flag it: *"⚠ /<name> is installed but not in the official toolkit anymore — consider running install-personal.sh to remove it."*
- Don't fabricate descriptions. If the frontmatter is missing or malformed, show "(no description — file may be corrupt)" instead of inventing.
- Don't add explanation about how each command works in detail — that's `docs/FRAMEWORK.md`. This is just the index.
