# Working in claude-workspace

Rules for Claude when working IN this repository (the toolkit itself, not when using the toolkit).

## What this repo is

This repository is **Mauricio's personal claude-code toolkit** — slash commands installed to `~/.claude/commands/` and code templates installed to `~/.claude/templates/`. NOT a workspace template for new projects, NOT a project scaffolder, NOT a general framework. **Personal toolkit only.**

The audience is Mauricio and anyone who finds the methodology useful enough to install it.

## Structure

```
claude-workspace/
├── personal-commands/      Source of truth for the slash commands
├── templates/              Source of truth for the code templates
├── bin/install-personal.sh Idempotent installer (downloads from this repo to ~/.claude/)
├── bin/validate-commands.sh Sanity check (frontmatter is well-formed)
├── docs/FRAMEWORK.md       Canonical doc — methodology + every command explained
├── README.md               Brief intro for visitors, install instructions
└── CLAUDE.md               This file — rules for working ON the toolkit
```

## When modifying a command

1. Edit `personal-commands/<name>.md` directly. This is the source of truth.
2. Run `bin/validate-commands.sh` to verify frontmatter is well-formed.
3. Update `docs/FRAMEWORK.md` if the command's behavior or composition changed.
4. Update `README.md`'s quick reference table if the description changed.
5. Update `bin/install-personal.sh` if you added/removed a command.
6. Commit with a `feat:` or `fix:` prefix and a clear description.
7. Push. The installer pulls from `main` directly, so changes are live immediately.

## When adding a new command

1. Decide the name. Single-word preferred. Multi-word OK if the name carries meaning (e.g., `safe-commit` — the `safe-` prefix is intentional).
2. Write `personal-commands/<name>.md` following the format of the existing commands (frontmatter with `description:`, then markdown body with Phases).
3. Add the command name to `PERSONAL_COMMANDS=()` array in `bin/install-personal.sh`.
4. Add the description to the `echo` block at the end of the installer.
5. Update the uninstall command in `bin/install-personal.sh` to include the new file.
6. Add a row to `docs/FRAMEWORK.md`.
7. Add a row to the quick reference table in `README.md`.

## When adding a new template

1. Write `templates/<category>/<name>.<ext>` (.ts, .tsx, .prisma, etc.) — must be a working file that compiles or parses.
2. Add a top comment block explaining: purpose, dependencies, file layout (if multi-file pattern).
3. Add a row to `templates/README.md` under the right category.
4. Add the path to the `TEMPLATES=()` array in `bin/install-personal.sh`.

## Style rules for this repo

- **No emojis in source files** unless the user explicitly requests them.
- **Commit messages**: conventional commit style. `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`.
- **Markdown files**: prefer GitHub-flavored markdown features. Mermaid diagrams in fences. Tables for lists with multiple attributes.
- **Co-Authored-By: Claude**: include in commits TO THIS REPO (this is Mauricio's personal toolkit, transparency about AI authorship is the point). Do NOT include in commits to other repos he works on (those have their own rules).

## Trust boundary with Claude Code as a dependency

This framework's slash commands (`/work`, `/safe-commit`, `/safe-push`, `/debug`, etc.) depend on Claude Code's `AskUserQuestion` tool blocking indefinitely until the user responds. Any silent change in that behavior degrades framework guarantees.

Two scripts codify the defense:

- `bin/verify-claude-config.sh` — read-only check of current Claude Code config
- `bin/apply-trust-defenses.sh` — idempotent config setter (adds `askUserQuestionTimeout: never`, huge `CLAUDE_AFK_TIMEOUT_MS`, `DISABLE_AUTOUPDATER: 1`)

`bin/install-personal.sh` offers to run `apply-trust-defenses.sh` opt-in at the end of install.

When editing anything related to `AskUserQuestion` behavior expectations, cross-reference `docs/FRAMEWORK.md § Trust boundaries with Claude Code as a dependency`.

## What this repo is NOT

- Not a generic claude-code workflow template (it's opinionated to Mauricio's style)
- Not a SaaS or service (no backend, no API, no servers)
- Not a documentation hub (it's a toolkit; the docs explain the toolkit, not general Claude Code usage)
- Not maintained for backwards compatibility (renames happen; users re-run the installer to migrate)
