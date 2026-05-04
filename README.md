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

### A) New workspace (start from scratch)

1. **Click "Use this template"** on GitHub → create your own repo from this one.
2. Clone it locally and open in Claude Code (or VSCode + Claude).
3. In Claude's chat, type **`/setup`**.
4. Claude interviews you (language, workspace type, rules) and generates the files.
5. Then use **`/new-project <name>`** to create each subproject.

### B) Add to an existing project

If you already have a project (a research repo, a monorepo, a notes folder…) and want to layer this pattern on top:

```bash
cd path/to/your/existing/project
curl -fsSL https://raw.githubusercontent.com/mauroepce/claude-workspace-template/main/bin/install.sh | bash
```

The installer:
- Adds `.claude/commands/`, `_templates/`, `docs/ARCHITECTURE.md` to your project.
- **Doesn't touch your code.**
- Preserves your existing `CLAUDE.md` if you have one. `/setup` will ask later whether to merge or replace it.
- Backs up any conflicting files in `.claude/commands/` to `*.bak`.

Then in Claude's chat, type `/setup` and follow the interview.

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
