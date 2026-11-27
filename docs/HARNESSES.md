# Using the toolkit outside Claude Code

The methodology is harness-agnostic; the installation is not. This page gives the supported skill locations and a verification step for each harness, and states plainly what does not carry over. Locations below were checked against the vendor documentation on 2026-11-26; individual IDE and cloud-agent support can vary by version.

## The portable unit: `SKILL.md`

Every skill is a folder with a `SKILL.md` whose frontmatter carries `name` and `description`. That is the [Agent Skills](https://github.com/agentskills/agentskills) open standard, read by Claude Code, GitHub Copilot, and OpenCode. The body is plain Markdown and bash; the workspace skills (`/onboard`, `/add-repo`) are self-contained and do not depend on files outside the skill.

`name` is not decoration: Copilot requires it, and a skill without it fails to load **silently**. `bin/validate-commands.sh` now checks that `name` exists and matches the directory.

## Claude Code

| What | Where |
|---|---|
| Personal skills | `~/.claude/skills/<name>/SKILL.md` |
| Project skills | `.claude/skills/<name>/SKILL.md` |
| Instructions | `CLAUDE.md` (project), `~/.claude/CLAUDE.md` (personal) |
| Hooks | `~/.claude/settings.json`, or the plugin's `hooks/hooks.json` |

Install (pick one):

```bash
# Curl installer: bare /name commands, templates, code-reviewer agent
curl -fsSL https://raw.githubusercontent.com/mauroepce/claude-workspace/main/bin/install-personal.sh | bash

# Or the plugin, inside a Claude Code session:
# /plugin marketplace add mauroepce/claude-workspace
# /plugin install claude-workspace@mauroepce
```

Verify:

```bash
ls ~/.claude/skills/add-repo/SKILL.md
```

Then run `/commands` (lists what is installed) or invoke `/add-repo` directly. Auto-invocation is by description: ask "where should I clone this repo into the workspace?" and the skill should be offered.

Hooks are Claude Code-specific. The curl installer adds the commit gate (`PreToolUse`) and session-status hook (`SessionStart`) via `bin/install-hooks.sh`; the plugin ships all four hooks.

## GitHub Copilot

| What | Where |
|---|---|
| Project skills | `.github/skills/<name>/SKILL.md` (recommended), `.claude/skills/`, `.agents/skills/` |
| Personal skills | `~/.copilot/skills/<name>/SKILL.md` (recommended), `~/.agents/skills/` |
| Instructions | `.github/copilot-instructions.md`, `AGENTS.md`, `.github/instructions/*.instructions.md` |

GitHub's docs list two personal locations: `~/.copilot/skills` and `~/.agents/skills`. VS Code also reads `~/.claude/skills`; treat that as a VS Code behavior, not a guarantee for Copilot cloud sessions. For a skill that must work everywhere, use `~/.copilot/skills`.

Install from an existing Claude Code install:

```bash
mkdir -p ~/.copilot/skills
cp -R ~/.claude/skills/. ~/.copilot/skills/
```

Or put one skill in a repo, where the whole team gets it:

```bash
mkdir -p .github/skills
cp -R ~/.claude/skills/add-repo .github/skills/
```

Verify: open Copilot Chat and ask "where should I clone this repo into the workspace?". Copilot decides from the description; in VS Code, type `/` in the chat input and check whether `add-repo` appears in the skill picker (slash support depends on the IDE version).

Copilot has no equivalent of Claude Code's `PreToolUse`/`SessionStart` contract. The commit gate is not portable. What does carry over is the skill's own confirmation step plus Copilot's tool-approval settings — a prompt-level gate, not a hash-checked one.

## OpenCode

| What | Where |
|---|---|
| Project skills | `.opencode/skills/<id>/SKILL.md` |
| Global skills | `~/.config/opencode/skills/<id>/SKILL.md` |
| Global compatibility | `~/.claude/skills`, `~/.agents/skills` |
| Project compatibility | `.claude/skills`, `.agents/skills` |
| Instructions | `AGENTS.md`, `opencode.json` |

OpenCode reads `~/.claude/skills` as a compatibility source, so the curl installer's output works with **no extra step**. If you installed through the Claude Code plugin, the skills live in the plugin cache, not in `~/.claude/skills`; copy them explicitly:

```bash
mkdir -p ~/.config/opencode/skills
cp -R ~/.claude/skills/. ~/.config/opencode/skills/
```

Verify: start `opencode` and ask "where should I clone this repo into the workspace?". The skill should be advertised; load it explicitly with `@add-repo`.

OpenCode has a plugin API, not shell hooks with Claude Code's lifecycle names. The commit gate is not portable; the skill's confirmation step and OpenCode's permission model are the enforcement.

## What does not carry over

- **Hook names and payloads.** `PreToolUse` and `SessionStart` are Claude Code contracts. Do not assume another harness fires them, or fires them with the same JSON.
- **The blocking `AskUserQuestion` assumption.** The framework's gates assume Claude Code's question tool waits indefinitely. In another harness, a confirmation step is an instruction the model follows, not a hard gate.
- **Plugin namespacing.** `/claude-workspace:work` is a Claude Code plugin convention. Copilot and OpenCode use the path-derived name (`work`; OpenCode can load it as `@work`).
- **Paths outside the skill.** `/scaffold` reads `~/.claude/templates/`, which only exists after the curl installer. The workspace skills do not have this dependency.

If a harness cannot load a skill, the fallback is the text: paste the relevant `SKILL.md` into the conversation, or copy it into the harness's instructions file. The method lives in the body, not in the loader.

## Verification matrix

| Harness | Skill visible | Manual invoke | Auto-invoke |
|---|---|---|---|
| Claude Code | `/commands`, or `ls ~/.claude/skills` | `/add-repo` | ask a matching question |
| Copilot (VS Code) | skill picker, `~/.copilot/skills` | ask for it by name (slash picker depends on version) | ask a matching question |
| OpenCode | advertised skill list | `@add-repo` | ask a matching question |

If the skill is not visible, check the three things that actually break it: the file is named `SKILL.md`, the frontmatter has `name` matching the directory, and the harness is reading that location (the tables above are the source of truth).
