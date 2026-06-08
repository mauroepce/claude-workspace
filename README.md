# Claude Workspace

> **Persistent context for AI agents.** Stop re-explaining your project every session.

A structured workspace template that gives Claude (or any AI agent) the context it needs to **resume your work across sessions** — instead of starting from zero every time.

---

## The problem this solves

| Without it | With it |
|------------|---------|
| 🔁 Every session starts from zero — you re-explain everything | 🧠 Claude reads your context automatically on day 1, day 30, day 365 |
| 🤔 "Why did I choose X over Y again?" | 📝 Decisions logged with the **why** — not just the choice |
| 📅 Picking up after 2 weeks = lose half a day re-orienting | ⏱️ Read `STATUS.md`, up to speed in 5 minutes |
| 🌀 Multiple projects bleeding context into each other | 📁 Per-subproject conventions, never confused |
| ⚠️ You forget to update notes / journal | 🤖 Claude maintains `STATUS.md` for you, automatically |

---

## Quick start (~90 seconds)

**Starting a new project:**

```bash
# Click "Use this template" on GitHub, or:
gh repo create my-workspace --template mauroepce/claude-workspace --public --clone
cd my-workspace
# Open in Claude Code, then in chat:  /setup
```

**Adding to an existing project:**

```bash
cd path/to/your/existing/project
curl -fsSL https://raw.githubusercontent.com/mauroepce/claude-workspace/main/bin/install.sh | bash
# Open in Claude Code, then in chat:  /setup
```

`/setup` interviews you (~7 questions, multi-language) and personalizes the workspace.

---

## What you get

🧠 **Persistent memory across sessions** — Claude auto-loads `CLAUDE.md` on every chat, so your context never resets.

📁 **Multiple subprojects without bleed** — each project has its own folder with its own `CLAUDE.md` and `STATUS.md`. Claude knows which one you're in.

✍️ **Claude maintains STATUS.md for you** — at the end of every productive session, the agent updates the live state automatically. No discipline required.

🌍 **Multi-language** — setup runs in English, Español, Português, Français, or any language. All generated files match.

🎨 **5 presets** — pick what fits: research, product portfolio, knowledge, consulting, or fully custom.

📦 **Versioned in git, no SaaS** — your context lives next to your code. Works offline. Survives any tool change.

---

## Use cases

| Preset | Best for | Subprojects live in |
|--------|----------|---------------------|
| 🔬 **Research** | Academic experiments, papers | `experiments/` |
| 📦 **Product** | MVP / startup portfolio | `apps/` |
| 📚 **Knowledge** | Personal notes, learning | `notes/` |
| 💼 **Consulting** | Multiple clients | `clients/` |
| 🛠️ **Custom** | Anything else (7-question wizard) | your choice |

Each preset comes with a tailored `STATUS.md` skeleton (e.g., research → hypothesis/method/results; product → lifecycle/TODOs/decisions).

---

## Commands

### Workspace commands (project-level, installed by `/setup`)

| Command | What it does |
|---------|--------------|
| `/setup` | First-run interview. Configures the workspace. |
| `/new-project <name>` | Add a new subproject with its `CLAUDE.md` and `STATUS.md`. |
| `/status` | Summary of all subprojects with their open TODOs. |
| `/checkpoint` | Force-update active subproject's `STATUS.md` mid-session. |

### Personal commands (user-level, install once, available everywhere)

These layer on top of any project, including team repos where you don't control the workspace setup. Install once with:

```bash
curl -fsSL https://raw.githubusercontent.com/mauroepce/claude-workspace/main/bin/install-personal.sh | bash
```

| Command | What it does |
|---------|--------------|
| `/work [task]` | Spec → generate → review → iterate framework. Forces structured intake before code generation. |
| `/issue <number>` | Pull a GitHub issue with `gh`, structure its context, hand off to `/work`. |
| `/debug` | Hypothesis-driven debugging: forces you to predict the cause, decide scope (in-spec vs separate), fix root cause not symptom, add regression test. |
| `/safe-commit` | Security review on staged changes + commit message tied to the spec. Refuses unsafe commits. |
| `/safe-push` | Full-branch security review + tests + push. Refuses to push to `main` without explicit OK. |

The methodology behind these four commands is documented in [`docs/FRAMEWORK.md`](./docs/FRAMEWORK.md).

---

<details>
<summary><b>📐 The architecture (4-file pattern)</b></summary>

<br>

```
your-workspace/
├── CLAUDE.md              ← Global conventions. Auto-loaded by Claude.
├── INDEX.md               ← One-line index of all subprojects.
└── apps/
    ├── project-a/
    │   ├── CLAUDE.md      ← Conventions for this subproject. Auto-loaded.
    │   └── STATUS.md      ← Live state. Maintained by Claude.
    └── project-b/
        ├── CLAUDE.md
        └── STATUS.md
```

**Two layers of `CLAUDE.md`** — root for global, subproject for local. Both auto-loaded based on where you're working.

**`STATUS.md` is the live journal** — current TODOs, decisions with the *why*, blockers waiting on input. Mutable.

**`INDEX.md` is the bird's-eye view** — one row per subproject, links to its `STATUS.md`.

Full details in [`docs/ARCHITECTURE.md`](./docs/ARCHITECTURE.md).

</details>

<details>
<summary><b>🚀 Setup walkthrough — new project (Flow A)</b></summary>

<br>

#### Step 1 — "Use this template" on GitHub

Click the green button on the repo page → enter your repo name → GitHub clones the template into your account.

You end up with `github.com/your-user/<your-repo>` containing all template files.

#### Step 2 — Clone and open

```bash
git clone https://github.com/your-user/<your-repo>.git
cd <your-repo>
```

Open in Claude Code (or VSCode + Claude extension).

#### Step 3 — Type `/setup`

The interview asks ~7 questions:
- Language → "Español"
- Workspace name → "phd-thesis"
- Type → "Research / Product / Knowledge / Consulting / Custom"
- Subproject directory → defaulted by preset
- Subproject noun → "experiment", "MVP", "client"…
- Custom rules → free text
- Extra commands → optional

Claude personalizes all files based on your answers.

#### Step 4 — Create your first subproject

```
/new-project my-first-thing
```

Done. Start working.

</details>

<details>
<summary><b>🔧 Setup walkthrough — existing project (Flow B)</b></summary>

<br>

For when you already have a project on disk and want to layer the pattern on top, **without losing anything**.

#### Step 1 — Go to your project

```bash
cd ~/path/to/existing/project
```

#### Step 2 — Run the installer

```bash
curl -fsSL https://raw.githubusercontent.com/mauroepce/claude-workspace/main/bin/install.sh | bash
```

Piece by piece:

| Piece | Meaning |
|-------|---------|
| `curl` | Downloads files from the internet via terminal |
| `-fsSL` | Silent, follow redirects, fail on error |
| `\|` (pipe) | Passes the downloaded content to the next command |
| `bash` | Runs the script |

In plain English: **"Download the install script and run it here."**

The script:
- Adds `.claude/commands/`, `_templates/`, `docs/ARCHITECTURE.md`
- Creates `CLAUDE.md` and `INDEX.md` only if you don't have them already
- **Doesn't touch your existing code**
- Backs up any conflicts to `*.bak`

#### Step 3 — Type `/setup`

If you already had a `CLAUDE.md`, the setup detects it and asks:

> "I see you already have a CLAUDE.md with content. Want me to (a) prepend workspace conventions, (b) append, (c) replace (with backup), or (d) skip — leave it alone and just configure the rest?"

</details>

<details>
<summary><b>💡 Philosophy & honest limitations</b></summary>

<br>

### Why this works

The pattern combines:
- **Anthropic's `CLAUDE.md` convention** — auto-loaded by Claude Code based on the directory you're in.
- **Slash commands** in `.claude/commands/` — to encode workflows as reusable scripts.
- **Discipline of "decisions with the *why*"** — the most valuable thing in long-running projects.

### Limitations (be honest with yourself)

- **Not magic.** Claude updates `STATUS.md` proactively, but if no meaningful work happened, nothing gets logged. You still need to *do* the work.
- **Overhead for tiny things.** If you're writing a 50-line script you'll finish in an hour, this is overkill.
- **Tied to Claude Code semantics.** The `CLAUDE.md` filename is Anthropic's convention. If you switch agents, files still work but auto-loading depends on the new tool.
- **You're still in control.** The agent maintains state, but decisions are yours. The workspace is a memory aid, not autopilot.

### When NOT to use it

- One-off scripts or quick prototypes.
- Single-file projects.
- When you genuinely want a fresh context every time (rare, but valid for some kinds of brainstorming).

</details>

---

## License

MIT — see [`LICENSE`](./LICENSE).

Made by [@mauroepce](https://github.com/mauroepce). Issues and PRs welcome.
