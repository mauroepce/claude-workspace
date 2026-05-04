---
description: Configure this freshly-cloned claude-workspace by interviewing the user and generating customized files.
---

# /setup — Workspace setup interview

You are Claude. The user has just cloned the **claude-workspace-template** and ran `/setup`. Your job is to interview the user, then generate a customized workspace.

## Phase 1 — Interview

Ask these questions **one at a time**, waiting for the user's answer before the next. Be friendly and concise.

### Q1 — Language

> Which language do you want to work in? (English / Español / Português / Français / other)

Save the answer as `LANG`. All subsequent questions and all generated files MUST be in that language. If the user says "English" or you can't tell, default to English.

### Q2 — Workspace name

> What's the name of this workspace? (e.g., `research-cs`, `my-startups`, `phd-thesis`)

Save as `WORKSPACE_NAME`. Use kebab-case. If the user gives a name with spaces, normalize it.

### Q3 — Preset

> What kind of work is this? Pick one:
> 1. **Research** — academic experiments, papers, results
> 2. **Product** — MVP/startup portfolio with lifecycle tracking
> 3. **Knowledge** — personal notes, ideas, references
> 4. **Consulting** — multiple clients with engagements
> 5. **Custom** — I'll guide you with extra questions

Save as `PRESET`. Read the corresponding file in `_templates/presets/<preset>.md` to get the defaults for that preset.

### Q4 — Subproject directory

Default suggestion based on preset (e.g., `experiments/` for research, `apps/` for product). Confirm or let the user change:

> Subprojects will live under `<DEFAULT_DIR>/`. OK or different?

Save as `SUBPROJECT_DIR`.

### Q5 — Subproject naming

> What do you call your subprojects in your domain? (singular noun: "experiment", "MVP", "client", "note", "paper", etc.)

Save as `SUBPROJECT_NOUN`. Used in the generated text.

### Q6 — Custom rules

> Any specific rules or conventions you want enforced? (free text. Examples: "always document negative results", "ship in 48h", "every paper needs a hypothesis section", or "no rules" if you don't have any yet)

Save as `CUSTOM_RULES`.

### Q7 — Extra commands (only for Custom preset)

If `PRESET == "Custom"`:

> Want any extra slash commands beyond `/new-project` and `/status`? (e.g., `/cite`, `/log-result`, `/new-paper`. Or "none")

For other presets, the preset file already lists suggested commands. Show them and ask:

> The "<preset>" preset suggests these extra commands: <list>. Keep them all? Drop some? Add more?

Save as `EXTRA_COMMANDS`.

## Phase 2 — Generation

Once you have all answers, generate these files in this order:

### 2.1 — Root `CLAUDE.md` (handle fresh OR existing-project case)

First, **check if `CLAUDE.md` already exists and whether it's the bootstrap version or real content**:

- If it exists and matches the bootstrap (mentions "Workspace not configured yet") → **overwrite** with the new generated content.
- If it exists and has **real content** (user installed via `bin/install.sh` into an existing project that already had a CLAUDE.md):
  - Show the user the first 20 lines of their existing CLAUDE.md.
  - Ask: "Detected existing CLAUDE.md with content. Want me to: (a) **prepend** workspace conventions at the top, (b) **append** at the bottom, (c) **replace** entirely (will back up to CLAUDE.md.bak), or (d) **skip** — leave your CLAUDE.md alone and just install commands?"
  - Apply the user's choice.
- If it doesn't exist → create from template.

Use `_templates/root-CLAUDE.md.tmpl` as the structure. Translate to `LANG`. Fill in:
- Workspace name and purpose (derived from preset description)
- Convention: subprojects live in `SUBPROJECT_DIR/`
- Pattern reference: each subproject has its own `CLAUDE.md` and `STATUS.md`
- Custom rules section with `CUSTOM_RULES` content
- Available commands list

### 2.2 — Root `INDEX.md`

Empty index ready to receive subprojects. Translated. With a "How to use" line at top.

### 2.3 — `_templates/subproject-CLAUDE.md.tmpl`

Subproject conventions template. Includes the preset's specific structure (e.g., for research: hypothesis section, references, dataset location). Translated.

### 2.4 — `_templates/subproject-STATUS.md.tmpl`

Subproject state template with the preset's structure:
- **Research**: hypothesis / method / status / experiments run / results / next
- **Product**: lifecycle phase / what works / TODOs / decisions / blockers
- **Knowledge**: summary / sources / open questions / next
- **Consulting**: engagement scope / current phase / deliverables / open items
- **Custom**: just status / TODOs / decisions / blockers (generic)

All translated.

### 2.5 — Extra command files

For each command in `EXTRA_COMMANDS`, create a stub at `.claude/commands/<name>.md` with:
- A short description (in `LANG`)
- Instructions to Claude on what to do when invoked

Example for `/new-experiment` (research preset):
```markdown
---
description: Create a new experiment in experiments/ with its CLAUDE.md and STATUS.md
---

When the user runs /new-experiment <name>:
1. Create directory `experiments/<name>/`
2. Copy `_templates/subproject-CLAUDE.md.tmpl` to `experiments/<name>/CLAUDE.md` and fill in the name
3. Copy `_templates/subproject-STATUS.md.tmpl` to `experiments/<name>/STATUS.md`. For research: pre-fill the hypothesis section by asking the user "What's the hypothesis?"
4. Add a row to root `INDEX.md`
5. Confirm to user with the path created
```

### 2.6 — Cleanup

Delete `_templates/presets/` (no longer needed after setup) — but keep `_templates/subproject-*.tmpl` (used by `/new-project`).

Delete this very file (`/setup` command) — setup only runs once.

### 2.7 — First commit

Create a git commit with the message:
`chore: workspace configured via /setup (preset: <PRESET>)`

## Phase 3 — Confirm and next steps

Print to the user (in `LANG`):

```
✅ Workspace configured.

Next steps:
1. Read CLAUDE.md to verify the conventions match what you wanted.
2. Create your first <SUBPROJECT_NOUN>:
     /new-project <name>
3. Use /status anytime to see all <SUBPROJECT_NOUN>s and their TODOs.

Tip: at the end of every productive session, update the STATUS.md of the
<SUBPROJECT_NOUN> you worked on. That's what makes this system work.
```

## Important rules for you (Claude)

- ASK questions one at a time. Don't dump all 7 at once.
- USE `LANG` for everything user-facing.
- DO NOT skip the interview — you need real answers, not assumptions.
- DO NOT generate files until you have all answers.
- IF the user gives a vague answer, confirm before proceeding.
- AT THE END, the workspace must be functionally complete and the user must be able to immediately run `/new-project`.
