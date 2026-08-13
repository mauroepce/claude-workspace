# The Framework

> A short, opinionated methodology for working with AI agents on production code. Not theoretical — the sixteen `skills/` in this repo encode it.

## The thesis

The work has shifted. Writing code is no longer the senior skill — **directing the model is**. That requires:

1. **Spec before generation.** Define what success looks like, what the constraint set is, and what failure modes you expect. Skipping this is where bad code comes from.
2. **Critical review of every output.** Treat agent output like a junior pair's PR — verify behavior, read every line, don't merge what you don't understand.
3. **Persistent context.** Conventions, architecture, decisions, todos — all live in version-controlled files. Chat history doesn't survive between sessions; files do.
4. **Workflow as artifact.** When the same prompt is going to come up three times, codify it. Slash commands are how methodology compounds.
5. **Atomic commands compose.** Small commands you can invoke standalone, or chain into orchestrators. Unix philosophy applied to agent workflows.

This isn't novel philosophy. It's the practical operating model of senior engineers who have shipped real production code with agents in 2025–2026. The commands in this repo make it executable.

## The sixteen skills

Each skill is a folder `skills/<name>/SKILL.md` installed to `~/.claude/skills/`. Two invocation paths:

- **Manual** — type `/<name>`, exactly like the slash commands they evolved from. Nothing changes in daily muscle memory.
- **Automatic** — Claude reads every skill's `description` at session start (one line each; the body loads only on invocation) and activates the matching skill when the task calls for it. Landing in an unknown repo and asking for code triggers `/conventions` without you remembering it exists.

The descriptions are therefore contracts: they state *what the skill does and when to use it*. Write them carefully — they are what makes the methodology self-applying.

### Task framework

#### `/work` — spec → generate → review → iterate

Forces you through a structured intake before any code generation:

1. **Spec phase** — what, why, what does NOT change, success criteria, failure modes.
2. **Context phase** — which files to load, what conventions apply. Auto-loads `.claude/conventions.md` if it exists.
3. **Plan phase** — a 3–7 line plan you approve before generation starts.
4. **Implementation phase** — generation, with the agent pausing on judgment calls.
5. **Self-review phase** — verify the diff matches the spec, no scope drift, failure modes handled.
6. **Hand off to `/safe-commit`**.

The win: the spec and failure modes are written down BEFORE generation, so review has a clear baseline. You can't drift into "while I'm here, let me also..." without noticing.

#### `/quick-work` — lite framework for small tasks

For single-file edits, simple bug fixes, micro-refactors, or anything you'd estimate at <30 minutes. Trades the full spec ceremony for speed while keeping the critical review step.

The discipline distilled to its irreducible minimum: restate the task (catches 50% of misunderstandings), self-check (catches 80% of obvious bugs), hand off to `/safe-commit` if needed. Total session: 5–15 minutes.

If you find yourself doing 2+ `/quick-work` invocations on the same logical task, switch to `/work` — the compounding context cost exceeds the spec ceremony cost.

#### `/todo` — persistent task tracking with milestones

Manages tasks that span multiple sessions. Each task has a title, milestones (3–7 typically), optional notes, and a `[FOCUSED]` marker for the active one. Saves to `.claude/todos.md` (committed) or `.claude/todos.local.md` (gitignored).

Complements — does NOT replace — Claude Code's built-in `TodoWrite` tool:
- `TodoWrite` is **in-session** — the moment-to-moment task list while working
- `/todo` is **cross-session** — survives when you close Claude Code

Composition: when `/work` Phase 3 produces a plan with 3+ steps, it suggests persisting them as a `/todo` task. `/work` for the structured spec, `/todo` for the execution tracker that survives.

Actions: `new`, `done <N>`, `list`, `focus <task>`, `archive`, `delete`. Notes can be appended at any time to capture decisions/blockers/learnings — gold for the "where was I?" moment after a long break.

Two additions make it push instead of pull:

- **In-prose markers** — `TODO: <text>`, `blocker: <text>`, `done: <text>`, `checkpoint` written mid-conversation are explicit todo-file operations; no need to invoke `/todo` formally. A marker is a line the user wrote, not a topic they mentioned.
- **The session-status hook** (optional, `bin/install-hooks.sh`) reads the todos file at session start and pushes the focused task + next milestone into context. See § Deterministic status below.

Workspace-aware: in a parent folder holding multiple repos (no root `.git`, 2+ child git repos), the todos file lives at the workspace root and tasks carry a `Repo:` tag.

#### `/issue <number>` — GitHub issue intake

Pulls an issue with `gh`, structures the context, surfaces what's NOT defined in the issue body, asks for additional context only you have, optionally creates a branch, and hands off to `/work`.

The win: stops you from interpreting issue bodies generously. The "what's not defined yet" section is where senior judgment adds value — you make implicit ambiguity explicit before generating anything.

### Codebase understanding

#### `/conventions` — codebase style detection (persistent)

Scans an unfamiliar codebase (config files + 3–5 sampled source files) and produces a structured report of: import style, formatting, naming conventions, file organization, error handling, async patterns, test framework, documentation style.

**The report is persisted to a file**, not just printed to chat. By default it writes to `.claude/conventions.md` (committed). Other options: `CONVENTIONS.md` at root, `.claude/conventions.local.md` (gitignored), or chat-only.

This persistence is what makes `/work` aware of conventions across sessions. Without it, every new conversation would re-detect from scratch.

#### `/architecture` — codebase structure cheat sheet

Scans an entire codebase and produces `architecture-map.md`: stack (from package.json), directory structure, database schema (Prisma / Drizzle / Supabase migrations), API routes, auth pattern, external integrations, and 5–10 critical files identified.

Complements `/conventions`: `/conventions` tells you what the code looks like (style), `/architecture` tells you what the code does (structure). Together they give you both.

Honest about gaps — sections that can't be derived from code are marked "TBD: fill from memory" instead of fabricated.

#### `/journeys` — visual flow documentation

Detects user journeys in a codebase (auth flows, payment flows, main feature actions, webhook processing) and produces Mermaid `sequenceDiagram` for each. Outputs `journeys-diagram.md`.

Why Mermaid: renders natively in GitHub, VS Code with the Mermaid extension, and most modern markdown viewers. No external tool needed. Versions in git just like code.

Why journey diagrams: they answer "when a user does X, what actually happens through the stack?" — the highest-leverage artifact for explaining behavior to humans. Architecture maps show the parts; journeys show how the parts cooperate over time.

#### `/onboard` — joining a new codebase

Orchestrates `/conventions` + `/architecture` + `/journeys` in sequence and produces an onboarding summary at `.claude/onboarding.md` with the suggested reading order, top 5 files to read first, and a mental model of the system.

Use on day one in a new repo (interview prep, new team, client handoff) or when returning to your own code after a long absence. Total ramp time after running: ~15 minutes of focused reading.

This is the meta-command. The three sub-commands stay atomic and invokable independently, but for the day-one experience this single invocation is the right entry point.

Two detection modes (Phase 0) handle the non-trivial terrains:

- **Team repos** — if the repo commits `.claude/` content or a CLAUDE.md, the onboarding artifacts are personal notes in someone else's house: every output switches to its `*.local.md` variant and the skill offers `.git/info/exclude` (never `.gitignore`, which is a shared file) so nothing personal appears in the team's `git status`.
- **Workspace folders** — a parent directory whose children are git repos (client workspaces, multi-repo products) gets a cheap root `INDEX.md` (repo | what it is | stack | last activity | onboarding link) plus full per-repo packages on demand, instead of one muddled cross-stack report.

On the first onboard of a repo it also asks one setup question — should commits here carry the `Co-Authored-By: Claude` trailer? — and records the answer in the conventions file, where `/safe-commit` reads it. Asked once, skipped when the repo's CLAUDE.md already states a rule.

#### `/isolate` — clean workspace for tests and interviews

Creates an isolated workspace (`/tmp/<name>` or `~/Desktop/interviews/<name>`) with a CLAUDE.md override that prevents Claude Code from walking up the directory tree and picking up context from unrelated projects.

The failure this prevents: when a technical test lives inside a monorepo (e.g., `revenue-lab/apps/prueba-carvuk/`), Claude Code auto-loads every `CLAUDE.md` and `.claude/` config in ancestor directories. That leaks patterns, naming conventions, and skills from unrelated projects into the test output. Reviewers then see "why does this candidate's take-home reference tables from another project?" and it reads as sloppy.

Use when:
- Starting a technical take-home for a company
- Preparing for a live-coding interview
- Any scratch experiment where ambient context would confuse output

Also initializes git (optional) and warns about ancestor CLAUDE.md files that might still leak in even in the isolated location.

### Debugging and decisions

#### `/debug` — hypothesis-driven debugging

When a bug appears, the temptation is to paste the error and ask for a fix. That loop drives bugs into hiding instead of resolving them.

`/debug` enforces a 9-step discipline:

1. **Symptom capture** — exact error, full trace, where it appeared, what was expected.
2. **Reproduction** — minimum repro steps. No fix without repro.
3. **Your hypothesis** — your one-line guess of the cause, BEFORE the model investigates. Non-negotiable.
4. **Investigation** — confirm or refute your hypothesis by reading code, logs, tests.
5. **Root cause** — the deeper reason, not the proximate cause.
6. **Scope decision** — in-scope for current `/work` task, or separate? Resist scope drift.
7. **Minimal fix** — smallest change that addresses the root cause.
8. **Regression test** — a test that would have caught this.
9. **Hand off** to `/safe-commit` (in-scope) or new task (separate).

The win: stops the "paste error → first fix → next error" loop. Your hypothesis matching the diagnosis is the calibration signal — if you were wildly wrong, the bug points to a deeper misunderstanding worth investigating.

#### `/decision` — capture a technical decision

Walks the user through 4 questions (decision, alternative, why this won, confidence level 🟢🟡🔴), with an optional 5th about trade-offs. Appends to `decisions-log.md` so the rationale persists across sessions.

Decisions made in chat evaporate when the session ends — by writing them to a file, they become part of the codebase's tribal knowledge. Useful both during `/work` and retroactively.

The confidence level is the most senior part: a 🔴 documented honestly is worth more than a fabricated 🟢. Future-you reading the log knows which decisions are stable and which are worth revisiting.

### Code review and commit

#### `/code-review` — quality review (atomic, reusable)

Quality-focused code review: naming, complexity, pattern adherence, test coverage, edge cases, error handling, performance traps. Output tiered: must-fix / should-fix / nice-to-have / strengths.

Use standalone when:
- Iterating on quality mid-implementation, before deciding commit boundary
- Reviewing unstaged work or files on a different branch
- Pre-PR sanity check on a branch before push

`/safe-commit` invokes this internally as Phase 2 — that's composition, not duplication.

#### `/safe-commit` — review before commit

Two-phase review (quality via `/code-review` + security via `/security-review`), verifies the commit maps to your `/work` spec, generates a commit message that explains the **why**, commits only after explicit confirmation. Never bypasses git hooks.

The win: catches the obvious failure modes (secret leaks, unintentional auth changes, suspicious diff patterns) before they enter history. Plus commit messages that have business value, not "update files".

The `Co-Authored-By: Claude` trailer is resolved per repo: the repo's own CLAUDE.md rule wins; otherwise the conventions file's `GIT ETIQUETTE` preference (recorded by `/onboard`'s first-run question) applies; otherwise no trailer.

#### `/safe-push` — review before push

Inspects the full branch diff, runs security review across all commits being pushed, optionally runs the test suite, and refuses to push to `main`/`master` without an extra explicit confirmation. Never force-pushes or skips hooks.

The win: the difference between a senior engineer and a fast one is what happens between `git commit` and `git push`. This command makes that gap deliberate.

### Scaffolding and meta

#### `/scaffold` — insert a curated template

Lists templates from `~/.claude/templates/` and inserts the chosen one adapted to current context. Templates encode senior conventions (Zod validation at boundaries, error class hierarchies, async retry with jitter, Result types).

Pick by keyword (`endpoint`, `form`, `retry`), by path (`backend/nest-controller`), or browse with `/scaffold` no args. Companion files (loading.tsx, error.tsx, tests) are suggested when relevant.

#### `/commands` — self-discovery

Lists all installed personal commands with their descriptions, grouped by category. Use when you've forgotten the names, just installed on a new machine, or aren't sure which command to invoke for a task.

It's the index. Not a replacement for `docs/FRAMEWORK.md` — just the quick "what's available?" reference.

## How commands compose

Some overlaps look like redundancy but are intentional. The atomic commands stay invokable standalone; orchestrators chain them into common workflows.

### `/code-review` vs `/work` Phase 5 (Self-review)

These are different scopes:
- **`/work` Phase 5** — does the diff match the SPEC from Phase 1? Did scope drift? Are the failure modes I predicted in Q5 actually handled? It's project-level review of the task at hand.
- **`/code-review`** — file-level quality (naming, complexity, tests, edge cases). Doesn't know the spec; just looks at the code as code.

You use both because they catch different things. `/work` Phase 5 might pass (the spec is satisfied) while `/code-review` flags a poorly-named helper variable.

### `/decision` vs `/work` Phase 1 Q5 (Failure modes)

- **`/work` Phase 1 Q5** — failure modes specific to THIS task. Disposable context that helps generation be defensive.
- **`/decision`** — durable architectural choices that outlive the task. Goes into the decisions log for future reference.

Use `/work` Q5 for "this implementation might race with X" (specific to current work). Use `/decision` for "we chose Lemon Squeezy over Stripe because Y" (you'll re-read this in 6 months).

### `/safe-commit` invokes `/code-review` + `/security-review`

This is the orchestrator pattern. `/safe-commit` runs the two reviews as Phases 2 and 3, then handles the commit. But `/code-review` and `/security-review` stay invokable standalone — when you want quality feedback without committing, or security check without staging.

You can build your own orchestrators following this pattern (e.g., a `/release` command that runs `/code-review` + `/safe-push` + creates a release tag).

### `/onboard` orchestrates `/conventions` + `/architecture` + `/journeys`

Same composition pattern: `/onboard` is the day-one ramp-up entry point that runs all three. The three commands stay independently invokable because:
- You might re-run only `/conventions` after a big refactor changed the patterns
- You might want `/journeys` to document a single new flow without re-running architecture
- You might want `/architecture` alone for documentation updates

The orchestrator and the atoms coexist. Use the atom when you need surgical feedback, the orchestrator when you need the package.

### `/work` auto-loads `/conventions`

`/work` Phase 2 (Context) automatically reads `.claude/conventions.md` if it exists. You don't need to invoke `/conventions` every time you start a task — once it's persisted, it acts as ambient context for the project.

The implicit rule: persist your codebase artifacts (conventions, architecture, journeys, decisions) once, and they ambient-flow into subsequent work. That's the persistence-as-context-engineering idea distilled.

## Trust boundaries with Claude Code as a dependency

The framework is a **layer built on top of Claude Code**. Every safety gate — `/work` Phase 1 spec questions, `/safe-commit` confirmation, `/safe-push` production checks, `/debug` hypothesis capture — depends on Claude Code's `AskUserQuestion` tool blocking indefinitely until the user responds.

### The failure mode this section defends against

In July 2026, Claude Code versions 2.1.198 and 2.1.199 shipped an undocumented change: `AskUserQuestion` would **auto-continue after 60 seconds of user silence**, using the model's best-guess answer instead of blocking. The feature had:

- No entry in the release notes
- No opt-out setting exposed in `/config`
- An off-switch (`CLAUDE_AFK_TIMEOUT_MS` env var) that was undocumented and discovered only through community discussion

Anthropic reverted the default in 2.1.200+ (auto-continue is now opt-in via `askUserQuestionTimeout` config, default `never`), but the episode revealed a class of risk that cannot be ignored: **a silent change in the platform can silently degrade every safety gate built on top of it.**

Attribution: this class of risk was documented in detail by Olaf Alders in [Claude Code: Anatomy of a Misfeature](https://www.olafalders.com/2026/07/17/claude-code-anatomy-of-a-misfeature/) (2026-07-17). The framework's defense is a direct response to that analysis.

### The three defenses this framework applies

To make the layer beneath the framework predictable regardless of future platform changes:

**1. Explicit config (defends against future default drift)**

```json
{ "askUserQuestionTimeout": "never" }
```

Written into `~/.claude/settings.json`. Even if Anthropic changes the default in a future version, an explicit value in the user's config wins.

**2. Env var override (belt-and-suspenders)**

```json
{ "env": { "CLAUDE_AFK_TIMEOUT_MS": "9999999999" } }
```

Env vars in `settings.json` override config settings in Claude Code's precedence order. If a future version renames the config field or changes its type, the env var still holds the line.

**3. Disable auto-updates (control the transition)**

```json
{ "env": { "DISABLE_AUTOUPDATER": "1" } }
```

Prevents Claude Code from auto-updating mid-session through a known-bad or known-changed version. The user chooses when to update and can verify config after each version bump.

### Two scripts codify this

**`bin/verify-claude-config.sh`** — read-only diagnostic

Runs six checks: Claude Code version (warns on 2.1.198-199), the three defense values, and framework install integrity (commands + templates). Exit code 0 if all pass, 1 for warnings, 2 for critical issues. Safe to run in CI or as a pre-work sanity check.

**`bin/apply-trust-defenses.sh`** — idempotent config setter

Reads current `~/.claude/settings.json`, merges the three defenses using `jq` (preserves all other fields — permissions, model, effortLevel, etc.), backs up the original with a timestamped filename, and writes atomically. Safe to run multiple times.

`bin/install-personal.sh` offers to run `apply-trust-defenses.sh` at the end of the install flow. It is opt-in — the user must confirm at a `y/N` prompt. Non-interactive installs (CI) skip the prompt.

### Ongoing discipline

- After every Claude Code version update, run `bin/verify-claude-config.sh` in a fresh terminal
- After every install of the framework on a new machine, run both scripts
- If Anthropic ships a new version-specific bug that affects framework guarantees, add a new check to `verify-claude-config.sh` and a new default to `apply-trust-defenses.sh` — this file will grow over time; treat it like a security advisory log

### The generalizable principle

The failure in July 2026 was not "Anthropic shipped a bad feature." It was "a silent change in the platform silently broke user-visible guarantees." Any framework built on top of a platform inherits this risk. The defenses are the framework's answer:

- **Explicit over implicit** — pin every value the framework depends on, in a versioned file
- **Multi-layer defense** — config + env var + auto-update disabled, so no single change vector can silently break the guarantees
- **Automated verification** — a check script prevents drift from going undetected
- **Documented rationale** — this section exists so future maintainers understand why the config looks paranoid

The same principle scales to any critical vendor dependency: databases, payment providers, auth services. The framework as of July 2026 codifies it for Claude Code specifically.

## Deterministic gates: the commit hook

The trust-boundary section above defends the framework's gates against *platform* changes. This section removes a weaker link: the gates themselves were prompts, and a prompt is a request the model can miss. A hook is code the harness always runs.

**The gate:** `hooks/commit-gate.sh`, registered as a `PreToolUse` hook (matcher: `Bash`) in `~/.claude/settings.json` by `bin/install-hooks.sh`. Before executing any Bash tool call, the harness pipes the call's JSON to the script. If the command is a `git commit`, the script verifies a review receipt:

- `/code-review` Phase 6 writes `.claude/review-passed` containing the hash of the exact staged diff it reviewed (`git diff --cached | git hash-object --stdin`).
- The gate recomputes the hash at commit time. Receipt missing, or hash mismatch (something was staged after the review) → exit code 2 → the commit is **blocked** and the error message is fed back to Claude, which then runs `/code-review` instead of committing blind.

**Properties:**

- *Deterministic* — "never commit unreviewed code" no longer depends on the model following instructions. The check runs on every Bash call, in every session, in every project.
- *Precise* — the receipt is tied to the diff content, not to a timestamp. Reviewing, then sneaking in one more staged change, invalidates the receipt.
- *Fail-open* — no jq, not a git repo, nothing staged: the gate allows the action. It defends against forgetting review, not against an adversary with shell access.
- *Human escape hatch* — `SKIP_REVIEW_GATE=1 git commit ...` bypasses the gate. It exists for humans in emergencies; `/safe-commit` explicitly forbids the model from using it.

Install: `bash <(curl -fsSL https://raw.githubusercontent.com/mauroepce/claude-workspace/main/bin/install-hooks.sh)` — idempotent, backs up `settings.json` before merging the entries (it registers both hooks).

## Deterministic status: the session-start hook

The commit gate applied "a hook is code the harness always runs" to reviews. This section applies the same principle to continuity. `/todo` persists tasks across sessions, but reading the file back was pull — it depended on the user remembering to run `/todo list` at the start of every session. A status system that depends on your memory to stay useful is the exact problem it was built to solve.

**The hook:** `hooks/session-status.sh`, registered as a `SessionStart` hook by `bin/install-hooks.sh` (and pre-wired in `hooks/hooks.json` for plugin installs). When a session starts, the harness runs it; whatever it prints is added to Claude's context before the first user message. If the project has a todos file (`.claude/todos.md`, `.claude/todos.local.md`, or `TODOS.md` — same lookup order as the skill), it prints the `[FOCUSED]` task, its milestone progress, and the next unchecked milestone.

**Properties:**

- *Push, not pull* — the session opens already knowing where you were. "Where was I?" stops being a question you remember to ask.
- *Fail-open and silent* — no todos file, no focused task, unreadable payload: it prints nothing and exits 0. It can never break or noise up a session start.
- *Read-only* — the hook never writes. State changes stay in the `/todo` skill, in-session, where the user can see them.
- *Workspace-aware for free* — it reads the todos file at the session's root, so a workspace-root todos file (multi-repo tracking) is surfaced exactly like a single-repo one.

Together the two hooks bracket a session: session-status pushes context in at the start; the commit gate blocks unreviewed work at the end.

## Separation of powers: the reviewer subagent

The framework's principle 2 says "treat agent output like a junior's PR" — but until now the reviewer was the same Claude that wrote the code, reviewing itself with a prompt. It knows its own justifications and tends to validate them, exactly like a dev reviewing their own PR.

`agents/code-reviewer.md` (installed to `~/.claude/agents/`) makes the separation structural instead of rhetorical:

- **Clean context** — a subagent starts with an empty context window. It has no memory of how the code was implemented or why, so it reviews the diff the way an outside reviewer would.
- **No write tools** — its frontmatter grants `Read, Grep, Glob, Bash` only. It physically cannot "fix while reviewing"; author and reviewer stay different roles by construction, not by convention.
- **Composed, not parallel** — `/code-review` Phase 0 delegates to the subagent when installed and falls back to inline review when not. The receipt (Phase 6) is still written by the main session after findings are resolved. Note: subagents don't run in parallel within a session — the win here is isolation, not speed.

The pipeline after this piece: implement (main session, `/work`) → review (subagent, clean context, read-only) → gate (hook, deterministic) → commit. Each role with exactly the powers it needs.

## The framework in CI

Everything above runs on your machine, which means it only exists while you are at the keyboard. A rushed merge from the GitHub UI, a collaborator without the toolkit, a commit from a phone — none of it passes through `/code-review` or the commit gate.

`templates/ci/claude-review.yml` closes that hole: a GitHub Actions workflow (using the official `anthropics/claude-code-action@v1`) that runs the `/code-review` checklist on every pull request and posts tiered findings (must-fix / should-fix / nice-to-have / strengths) as a PR comment.

Setup per repo: copy the template to `.github/workflows/claude-review.yml`, add `ANTHROPIC_API_KEY` to the repo's Actions secrets, open a PR. Same pattern as any cron/CI you already run — the methodology becomes infrastructure instead of discipline.

The layering, complete:

| Layer | Where it runs | What it guarantees |
|---|---|---|
| Skills | your session | methodology auto-applies while you work |
| Reviewer subagent | your session | review without author bias or write access |
| Commit gate (hook) | your machine, every session | no unreviewed diff enters history locally |
| CI review | GitHub, every PR | no unreviewed diff merges, even without you |

## Distribution: the repo is a plugin and its own marketplace

`.claude-plugin/plugin.json` declares this repo as a Claude Code **plugin** (skills, the reviewer subagent, and the commit-gate hook, auto-discovered from `skills/`, `agents/` and `hooks/hooks.json`). `.claude-plugin/marketplace.json` makes the same repo a **marketplace** — a git repo listing installable plugins; no central store involved.

Install UX for anyone (including future-you on a new machine):

```
/plugin marketplace add mauroepce/claude-workspace
/plugin install claude-workspace@mauroepce
```

Compared to the curl installer: versioned installs, one-command updates, clean uninstall, and the hook ships wired (no `bin/install-hooks.sh` needed — `hooks/hooks.json` references the script via `${CLAUDE_PLUGIN_ROOT}`). The trade-offs: plugin skills are namespaced (`/claude-workspace:work` instead of bare `/work` — auto-invocation is unaffected), and code templates stay outside the plugin (curl installer or manual copy).

Both paths remain supported. The curl installer is the muscle-memory path (bare `/name`, templates included); the plugin is the managed path.

## The mental model

Three principles that survive any change in tooling:

### 1. Specs are the deliverable. Code is the implementation.

A good spec written by you can be implemented by anyone or anything (you, a junior dev, an agent). A bad spec produces bad code regardless of who writes it. Invest in specs.

### 2. Agent output is a junior's PR. Review it that way.

Read every line. Verify behavior with at least one test. Don't merge what you don't understand. Don't accept "the agent said it works" as evidence — the agent is confidently wrong sometimes.

### 3. When a prompt repeats, codify it.

The third time you find yourself typing roughly the same context-setting prompt, it becomes a slash command. The third time you find yourself catching the same kind of bug, it becomes a check in your review checklist. Methodology compounds when you treat it as code.

## Where the skills live

**User-level (`~/.claude/skills/<name>/SKILL.md`).** Installed once with `bin/install-personal.sh`. Available in every project you open. Doesn't require team consent — these are YOUR skills.

When you join a team or are handed a repo:

```bash
git clone <team-repo>
cd <team-repo>
# Your personal skills already work — no team setup required
# If the team has their own CLAUDE.md and skills, they layer on top
```

If the team independently defines `/work` or `/safe-commit`, the project-level version wins. Conflict-free.

## How to extend this

The `skills/` directory in this repo is the source of truth. To add a new personal skill:

1. Write `skills/<name>/SKILL.md` following the format of the existing ones. The `description` frontmatter doubles as the auto-invocation trigger. Supporting files can live next to SKILL.md; Claude loads them only when needed (progressive disclosure).
2. Add `<name>` to the `PERSONAL_SKILLS` array in `bin/install-personal.sh`.
3. Add a description to the echo block + uninstall line in the same script.
4. Run `bin/validate-commands.sh` to verify the frontmatter is well-formed.
5. Add a section to this doc.
6. Add a row to the quick reference table in `README.md`.
7. Re-run `bin/install-personal.sh` on your machine (or anyone you've shared this with).

Possible future additions:
- `/spike <topic>` — time-boxed exploration with explicit "this is throwaway" framing
- `/postmortem <incident>` — structured post-incident review and write-up
- `/changelog` — auto-generate CHANGELOG.md entries from git log + decisions log

## What this is not

- **Not a productivity hack.** It's intentionally slower at the start because spec-first beats generate-first over the whole task lifetime, not per-prompt.
- **Not framework worship.** If a task is small enough that ceremony is overhead, skip the commands and just type. `/work` for a 5-line CSS fix is wrong — that's why `/quick-work` exists.
- **Not autopilot.** Every command pauses for user confirmation at decision points. The agent never commits or pushes without explicit OK.

## Closing

If you're reading this because someone handed you the repo and said "this is how I work" — the commands and this doc are everything. Read the `personal-commands/*.md` files. They are short. The format teaches itself.
