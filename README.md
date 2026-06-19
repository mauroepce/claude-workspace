# claude-workspace

> Mauricio's personal toolkit for working with Claude Code at senior level.

12 slash commands + a curated templates library, installable into your `~/.claude/` with one curl command. Layer on top of any project — new or existing, personal or team-owned — without touching the project's repo.

## What it is

A codified senior workflow with five core principles:

1. **Spec before generation** — every task starts with a structured spec, not "hey claude write me X"
2. **Critical review of agent output** — never accept a first response, treat output like a junior's PR
3. **Persistent context** — conventions, architecture, decisions, todos all live in version-controlled files, not in chat history
4. **Workflow as artifact** — when a prompt repeats 3 times, it becomes a slash command
5. **Atomic commands compose** — small commands you can invoke standalone, or chain into orchestrators like `/safe-commit`

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/mauroepce/claude-workspace/main/bin/install-personal.sh | bash
```

This installs:
- 12 slash commands to `~/.claude/commands/`
- 9 code templates to `~/.claude/templates/`

Idempotent — re-run anytime to update. Backs up your modified files to `*.bak` before replacing.

## Quick reference

| Command | What it does |
|---|---|
| `/work` | Spec-first task framework: spec → context → plan → implement → review |
| `/quick-work` | Lite version of `/work` for small tasks (single-file edits, fixes) |
| `/todo` | Persistent task tracking with milestones, survives across sessions |
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
| `/onboard` | Joining a new codebase: runs `/conventions` + `/architecture` + `/journeys` |
| `/commands` | List all installed personal commands with their descriptions |

Full methodology and command details in [`docs/FRAMEWORK.md`](./docs/FRAMEWORK.md).

## How layering works

Personal commands live in `~/.claude/commands/`. They're available in **any project you open with Claude Code** — your own repos, client repos, team repos where you don't control configuration.

If a project has its own `.claude/commands/` with a same-named command, **the project version wins**. Your personal commands fill the gaps without overriding team conventions.

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
rm -rf ~/.claude/commands/{work,quick-work,todo,issue,debug,conventions,architecture,journeys,decision,code-review,safe-commit,safe-push,scaffold,onboard,commands}.md
rm -rf ~/.claude/templates/
```

## License

[MIT](./LICENSE) — use freely. If you find the methodology useful, fork and adapt to your own style.

## Why this exists

In 2026 the bottleneck of senior engineering is no longer typing speed — it's **directing the model with judgment**. That requires repeatable workflows, explicit reasoning, persistent context, and atomic tools that compose.

This toolkit is my attempt at that. It's opinionated. It's a personal style, not a universal best practice. But it's been refined through real work — production code at TeselaGen Biotechnology, a SaaS factory (Revenue Lab), portfolio pieces at [mauroepce.dev](https://mauroepce.dev), and weekly job application screens.

If you've felt the gap between "I use Cursor" and "I have a workflow," this is what closing that gap can look like.

— [@mauroepce](https://github.com/mauroepce)
