# Claude Workspace Template

A structured workspace that lets Claude (or any AI agent) **resume context across sessions** without you having to re-explain everything every time.

Useful for:
- 🔬 **Academic research** — experiments, papers, results
- 📦 **Product / startup portfolio** — MVPs with their lifecycle
- 📚 **Knowledge management** — notes, ideas, references
- 💼 **Consulting** — clients, engagements, deliverables
- 🛠️ **Any workspace** with multiple sub-projects

---

## How it works

The template applies a 3-file pattern:

| File | Purpose |
|------|---------|
| Root **`CLAUDE.md`** | Global workspace conventions. Claude auto-loads it. |
| **`<subproject>/CLAUDE.md`** | Subproject-specific conventions. Auto-loaded when working there. |
| **`<subproject>/STATUS.md`** | Live state of the subproject. TODOs, decisions, blockers. |
| Root **`INDEX.md`** | Birds-eye view of all subprojects. |

More detail on the pattern in [`docs/ARCHITECTURE.md`](./docs/ARCHITECTURE.md).

---

## How to use it

There are two ways depending on whether you're starting fresh or adding this to an existing project.

> **TL;DR:** Flow A is like "buy a model house from a kit" — fresh start, plan picked, everything assembled. Flow B is like "add a security system to a house you already have" — installed without touching your furniture.

---

### A) New workspace (start from scratch)

For when you want to start a fully new project using this template as the base.

#### Step 1 — "Use this template" on GitHub

When a GitHub repo is marked as a template (configured in repo Settings), a green button appears in the top-right that says **"Use this template"**.

When you click it, GitHub asks you:
- A name for **your** new repo (e.g., `phd-thesis`)
- Public or private

GitHub then **clones the entire template content into a brand-new repo** under your account. It's like a fork but without the history — your repo starts clean.

You end up with: `github.com/your-user/phd-thesis` with all the template files inside.

#### Step 2 — Clone and open in Claude Code

```bash
git clone https://github.com/your-user/phd-thesis.git
cd phd-thesis
```

Open the folder in Claude Code (or VSCode with the Claude extension).

#### Step 3 — Type `/setup` in Claude's chat

In the chat, type `/setup`. Claude runs the interview:
- "What language do you want to work in?" → e.g., "Español"
- "Workspace name?" → e.g., "phd-thesis"
- "What kind of work is this?" → e.g., "Research"
- ...and a few more.

At the end, Claude **personalizes all files** based on your answers: the root `CLAUDE.md` gets your conventions, the subproject templates fit your domain, etc.

#### Step 4 — Create your first subproject

```
/new-project my-first-experiment
```

Done.

---

### B) Add to an existing project

For when you **already have a project on your machine** (a folder with code, notes, papers, whatever) and want to **layer the pattern on top** without losing anything you already have.

Example: you already have `~/research/` with several papers in progress, code, notes. You don't want to clone a new repo — you want to add the system to that folder.

#### Step 1 — Go to your existing project

```bash
cd ~/research
```

(`cd` = "change directory" — opens a terminal and moves into your project's folder.)

#### Step 2 — Run the install command

```bash
curl -fsSL https://raw.githubusercontent.com/mauroepce/claude-workspace/main/bin/install.sh | bash
```

What this command does, **piece by piece**:

| Piece | Meaning |
|-------|---------|
| `curl` | A program that downloads things from the internet via the terminal |
| `-fsSL` | Curl flags: silent, follow redirects, fail on error |
| `https://raw.githubusercontent.com/.../install.sh` | URL of the `install.sh` file inside the template repo |
| `\|` (pipe) | "Pipe" — passes what was downloaded to the next command |
| `bash` | Runs the downloaded script |

In plain English: **"Download the `install.sh` script from the repo and run it right here."**

**What the script does:**
- Creates `.claude/commands/` with the 3 commands (setup, new-project, status)
- Creates `_templates/` with the presets and templates
- Creates `docs/ARCHITECTURE.md`
- If you **don't have** a `CLAUDE.md` yet → creates one (the bootstrap version)
- If you **already have** a `CLAUDE.md` → **leaves it alone** (doesn't touch what you already wrote)
- If there are conflicts in other files → makes `.bak` and puts the new ones in place

**Important:** the script **doesn't touch your existing code**. It only adds the system files.

#### Step 3 — Open Claude and run `/setup`

Same as flow A. The difference is that this time `/setup` detects you already have a `CLAUDE.md` and asks:

> "I see you already have a CLAUDE.md with content. Want me to (a) prepend the workspace conventions at the top, (b) append at the bottom, (c) replace entirely (with backup), or (d) leave your CLAUDE.md alone and just configure the rest?"

---

Setup takes ~90 seconds either way.

**Multi-language**: setup asks you what language you want to work in (English, Español, Português, Français, etc.). All generated files are translated accordingly.

---

## Commands

- **`/setup`** — first run: configure the workspace.
- **`/new-project <name>`** — adds a new subproject with its `CLAUDE.md` and `STATUS.md`.
- **`/status`** — summary of all subprojects and their open TODOs.

---

## Presets in `/setup`

| Preset | Use case | Defaults |
|--------|----------|----------|
| **Research** | Academic research | `experiments/`, STATUS with hypothesis/method/results |
| **Product** | MVP / startup portfolio | `apps/`, STATUS with 14-day lifecycle |
| **Knowledge** | Personal notes & projects | `notes/`, STATUS with summary/links |
| **Consulting** | Multiple clients | `clients/`, STATUS with engagement/scope |
| **Custom** | Anything else | 7 guided questions |

---

## Philosophy

The problem: you work with an AI agent for weeks. Each new session the agent remembers nothing and you have to re-explain context. This template solves it with versioned files the agent loads automatically.

It's not magic — just discipline + conventions + Claude Code's built-in features.

---

## License

MIT.
