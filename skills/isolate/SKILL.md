---
description: Create a clean isolated workspace for a technical test, interview live-coding, or scratch experiment. Prevents Claude Code from walking up the directory tree and picking up contaminating context (other MVPs, monorepo skills, unrelated CLAUDE.md files). Use before any work that must NOT inherit ambient context from other projects.
---

# /isolate — Clean workspace for a scoped task

You are Claude. The user is about to start a task — usually a technical test, interview live-coding exercise, or short scratch experiment — that must be **fully isolated from any ambient context**.

The failure this command prevents is real: when the user works inside a monorepo (e.g., `revenue-lab/apps/prueba-carvuk/`), Claude Code walks UP the tree and reads every `CLAUDE.md`, every `.claude/` config, every skill in ancestor directories. That context bleeds into generation — table naming conventions from `honorarios-cl`, RLS patterns from `clacebox`, decisions from `revenue-lab/CLAUDE.md` that don't apply to the current task.

Reviewers of the test/interview then see: "this candidate's code has references or patterns from other projects, why?" It reads as sloppy or as if the candidate lifted code from elsewhere.

**Argument (optional):** `$ARGUMENTS` may be a short name for the workspace (e.g., `test-carvuk`, `scratch-graphql`). If empty, ask for it.

## Phase 1 — Ask what kind of isolation

> "What are you isolating for?
> 1. **Technical test / take-home** — external, will be shared with the reviewer.
> 2. **Live-coding interview** — screen-shared, needs to be visibly clean.
> 3. **Scratch experiment** — private, just want no ambient context to pollute.
>
> Also, workspace name? (used as directory name; e.g., `test-carvuk`, `interview-mercadolibre`, `scratch-nestjs`)"

Wait for both answers. The isolation type affects follow-up defaults; the name is the directory.

## Phase 2 — Choose location

Two safe locations, both **outside your usual github folder** (so no parent walking picks up your other projects):

- `/tmp/<workspace-name>` — ephemeral. Cleared on reboot. Best for scratch experiments where you truly don't want persistence.
- `~/Desktop/interviews/<workspace-name>` — persistent. Best for tests where you want to keep the code afterward.

Ask:

> "Where?
> 1. **`/tmp/<workspace-name>`** — ephemeral (cleared on reboot). Recommended for scratch.
> 2. **`~/Desktop/interviews/<workspace-name>`** — persistent. Recommended for tests / take-homes (you'll want the code afterward).
>
> Default: **2** for tests/interviews, **1** for scratch. Which?"

## Phase 3 — Create the isolated workspace

Once path is decided, create it. Also verify there's nothing surprising in the parent chain that would still leak in.

```bash
# Create the isolated dir
mkdir -p "<chosen path>"
cd "<chosen path>"

# Verify: no CLAUDE.md up the parent chain that would auto-load
parent="$(cd "<chosen path>/.." && pwd)"
while [ "$parent" != "/" ]; do
  if [ -f "$parent/CLAUDE.md" ]; then
    echo "⚠️  Ancestor CLAUDE.md at $parent/CLAUDE.md — Claude Code may auto-load this"
  fi
  parent="$(dirname "$parent")"
done
```

For `/tmp/*`: no ancestor CLAUDE.md, safe.
For `~/Desktop/interviews/*`: if `~/CLAUDE.md` or `~/Desktop/CLAUDE.md` exists, warn the user.

If warning triggered, ask:

> "Ancestor CLAUDE.md found at `<path>`. Options:
> 1. **Ignore** — Claude Code will read it, may bleed context.
> 2. **Create a marker file** in the isolated dir to short-circuit context walk (see below).
> 3. **Move the ancestor CLAUDE.md temporarily** during your session.
>
> Default: **2**. Which?"

For option 2, write an explicit override in the isolated dir:

```bash
cat > CLAUDE.md <<'EOF'
# Isolated workspace

This is an intentionally isolated workspace. **Ignore any CLAUDE.md, .claude/ config, or skills in ancestor directories.** The only context that applies here is this file.

Purpose: <isolation type from Phase 1>
Created: <date>

Rules for Claude in this workspace:
- Do NOT reference patterns, tables, or conventions from any other project on this machine.
- Do NOT invoke skills from `~/.claude/skills/` unless the user explicitly asks.
- Personal commands from `~/.claude/commands/` (like /work, /debug, /code-review) are OK to use.
- If asked about "the project", "the codebase", or "our conventions", refer ONLY to files inside this directory.
EOF
```

## Phase 4 — Initialize git (optional, ask)

For tests/interviews (isolation type 1 or 2), suggest:

> "Initialize git so you can commit incrementally as you work? (recommended for reviewers to see your progression)
> y/n"

If yes:

```bash
git init
git branch -M main
cat > .gitignore <<'EOF'
node_modules/
.next/
.env
.env.local
*.log
.DS_Store
EOF
git add .gitignore CLAUDE.md
git commit -m "chore: initial isolated workspace"
```

## Phase 5 — Suggest what to do next

Depending on isolation type:

**Test/take-home:** Point to `/work` for the first task, and remind about `/conventions` after any scaffold to lock in the language/style choice.

**Live-coding interview:** Point to `/quick-work` (shorter cycles), and remind about the "first functional slice" rule from `/work` Phase 3.

**Scratch experiment:** No structure recommended — user knows what they're exploring.

End with:

> "Isolated workspace ready at `<path>`. Currently your working directory. When you're done:
> - Test/take-home: consider extracting the final code to a public repo (drops the CLAUDE.md override, keeps the code).
> - Scratch: safe to delete when you're done — nothing is persisted anywhere important.
>
> The `CLAUDE.md` override prevents context bleed. If Claude starts referencing something that doesn't exist in this directory, remind it: 'stay inside the isolated workspace, ignore ambient.'"

## What NOT to do

- Don't create the isolated dir inside a git repo you already own (e.g., `~/github/some-repo/scratch/`). That defeats the purpose — Claude walks up the tree and finds the parent repo's CLAUDE.md.
- Don't skip the ancestor-walk check for `~/Desktop/interviews/`. Some users have `~/Desktop/CLAUDE.md` or `~/CLAUDE.md` from previous experiments.
- Don't invoke other slash commands that read from the parent tree (like `/conventions`) automatically — the user should invoke them explicitly after this isolated setup.
- Don't add `Co-Authored-By: Claude` to the isolated repo's commits by default (it's the user's test, they decide attribution).
