# claude-workspace

> Mauricio's personal toolkit for working with Claude Code at senior level.

16 skills + a curated templates library, installable into your `~/.claude/` with one curl command. Layer on top of any project — new or existing, personal or team-owned — without touching the project's repo.

Each skill works two ways: invoke it manually (`/work`, `/conventions`, ...) exactly like the slash commands they evolved from, or let Claude **auto-activate** it — Claude reads each skill's description and applies the matching one when your request calls for it, without being asked. The methodology applies itself even when you forget to invoke it.

## What it is

A codified senior workflow with five core principles:

1. **Spec before generation** — every task starts with a structured spec, not "hey claude write me X"
2. **Critical review of agent output** — never accept a first response, treat output like a junior's PR
3. **Persistent context** — conventions, architecture, decisions, todos all live in version-controlled files, not in chat history
4. **Workflow as artifact** — when a prompt repeats 3 times, it becomes a slash command
5. **Atomic commands compose** — small commands you can invoke standalone, or chain into orchestrators like `/safe-commit`

## Install

### Option A — as a plugin (recommended for new installs)

Inside any Claude Code session:

```
/plugin marketplace add mauroepce/claude-workspace
/plugin install claude-workspace@mauroepce
```

This repo is its own [plugin marketplace](./.claude-plugin/marketplace.json). The plugin ships the 16 skills, the `code-reviewer` subagent AND the full hook set (commit gate, session-start status push, post-edit self-check, session-close check) as one managed unit — versioned installs, one-command updates (`/plugin marketplace update mauroepce`), clean uninstall from `/plugin`.

Trade-offs vs the curl installer:
- Plugin skills are namespaced: `/claude-workspace:work` instead of `/work` (auto-invocation by description works identically either way).
- Code templates are NOT part of the plugin — get them with the curl installer below or copy `templates/` manually.

### Option B — curl installer (bare `/name` commands + templates)

```bash
curl -fsSL https://raw.githubusercontent.com/mauroepce/claude-workspace/main/bin/install-personal.sh | bash
```

This installs:
- 16 skills to `~/.claude/skills/<name>/SKILL.md` (invoked as bare `/work`, `/conventions`, ...)
- 9 code templates + 1 CI workflow template to `~/.claude/templates/`
- The `code-reviewer` subagent to `~/.claude/agents/`

Pick ONE option — installing both gives you every skill twice (`/work` and `/claude-workspace:work`).

Idempotent — re-run anytime to update. Backs up your modified files to `*.bak` before replacing. Legacy slash-command files from pre-skills versions (`~/.claude/commands/<name>.md`) are cleaned up automatically.

### Optional: the deterministic hooks

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/mauroepce/claude-workspace/main/bin/install-hooks.sh)
```

Registers two hooks (requires `jq`):

- **Commit gate** (`PreToolUse`) — **physically blocks `git commit`** unless `/code-review` reviewed the exact staged diff (it writes a hash receipt to `.claude/review-passed`). The framework's "never commit unreviewed code" rule stops being a prompt the model follows and becomes code the harness enforces. Details in [`docs/FRAMEWORK.md`](./docs/FRAMEWORK.md#deterministic-gates-the-commit-hook).
- **Session status** (`SessionStart`) — if the project has a `.claude/todos.md` (the `/todo` skill), the focused task and its next milestone are **pushed into context when the session opens**. "Where was I?" stops being a question you remember to ask; same principle as the gate, applied to continuity instead of review.

## Quick reference

| Command | What it does |
|---|---|
| `/work` | Spec-first task framework: spec → context → plan → implement → review |
| `/quick-work` | Lite version of `/work` for small tasks (single-file edits, fixes) |
| `/todo` | Persistent task tracking with milestones, survives across sessions; in-prose markers (`TODO:`/`blocker:`/`done:`); workspace-aware |
| `/issue <N>` | Pull a GitHub issue, structure its context, hand off to `/work` |
| `/debug` | Hypothesis-driven debugging: root cause over symptom |
| `/conventions` | Scan codebase for style patterns, persist to `.claude/conventions.md` |
| `/architecture` | Scan codebase structure, persist to `.claude/architecture-map.md` |
| `/journeys` | Detect user flows, produce Mermaid sequence diagrams |
| `/decision` | Capture a technical decision with alternatives + confidence level |
| `/code-review` | Quality review of staged changes (atomic, reusable) |
| `/safe-commit` | `/code-review` + `/security-review` + commit with confirmation |
| `/safe-push` | Full-branch review + push (refuses main without OK) |
| `/scaffold` | Pick from curated code templates, insert adapted to context |
| `/onboard` | Joining a new codebase: runs `/conventions` + `/architecture` + `/journeys`; multi-repo workspaces get a root `INDEX.md`; team repos get `*.local.md` artifacts |
| `/commands` | List all installed personal commands with their descriptions |

Full methodology and command details in [`docs/FRAMEWORK.md`](./docs/FRAMEWORK.md).

## How layering works

Personal skills live in `~/.claude/skills/`. They're available in **any project you open with Claude Code** — your own repos, client repos, team repos where you don't control configuration.

If a project has its own `.claude/skills/` (or `.claude/commands/`) with a same-named entry, **the project version wins**. Your personal skills fill the gaps without overriding team conventions.

This means:
- Use my framework freely in new projects
- Inherit your personal workflow when joining team repos
- Zero friction: nothing to commit to a team's repo just to use my toolkit

## Templates

The `~/.claude/templates/` library contains 9 working code files with my conventions baked in (TypeScript strict, Zod validation at boundaries, error class hierarchies, async retry with jitter, Result types, etc.).

Use them via `/scaffold` or read directly:

```bash
ls ~/.claude/templates/
cat ~/.claude/templates/backend/nest-controller.ts
```

Templates include teaching comments by default — they explain the WHY of each pattern. Strip them once you've internalized the pattern.

## Update

Re-run the install command to pull the latest version of all commands and templates:

```bash
curl -fsSL https://raw.githubusercontent.com/mauroepce/claude-workspace/main/bin/install-personal.sh | bash
```

Your modified files get backed up to `*.bak`. New/changed files get installed.

## Uninstall

```bash
rm -rf ~/.claude/skills/{work,quick-work,todo,issue,debug,conventions,architecture,journeys,decision,code-review,safe-commit,safe-push,scaffold,onboard,isolate,commands}
rm -rf ~/.claude/templates/
```

## License

[MIT](./LICENSE) — use freely. If you find the methodology useful, fork and adapt to your own style.

## Why this exists

In 2026 the bottleneck of senior engineering is no longer typing speed — it's **directing the model with judgment**. That requires repeatable workflows, explicit reasoning, persistent context, and atomic tools that compose.

This toolkit is my attempt at that. It's opinionated. It's a personal style, not a universal best practice. But it's been refined through real work — production code at TeselaGen Biotechnology, a SaaS factory (Revenue Lab), portfolio pieces at [mauroepce.dev](https://mauroepce.dev), and weekly job application screens.

If you've felt the gap between "I use Cursor" and "I have a workflow," this is what closing that gap can look like.

— [@mauroepce](https://github.com/mauroepce)
