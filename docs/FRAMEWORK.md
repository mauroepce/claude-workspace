# The Framework

> A short, opinionated methodology for working with AI agents on production code. Not theoretical — the fifteen `personal-commands/` in this repo encode it.

## The thesis

The work has shifted. Writing code is no longer the senior skill — **directing the model is**. That requires:

1. **Spec before generation.** Define what success looks like, what the constraint set is, and what failure modes you expect. Skipping this is where bad code comes from.
2. **Critical review of every output.** Treat agent output like a junior pair's PR — verify behavior, read every line, don't merge what you don't understand.
3. **Persistent context.** Conventions, architecture, decisions, todos — all live in version-controlled files. Chat history doesn't survive between sessions; files do.
4. **Workflow as artifact.** When the same prompt is going to come up three times, codify it. Slash commands are how methodology compounds.
5. **Atomic commands compose.** Small commands you can invoke standalone, or chain into orchestrators. Unix philosophy applied to agent workflows.

This isn't novel philosophy. It's the practical operating model of senior engineers who have shipped real production code with agents in 2025–2026. The commands in this repo make it executable.

## The fifteen commands

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

## The mental model

Three principles that survive any change in tooling:

### 1. Specs are the deliverable. Code is the implementation.

A good spec written by you can be implemented by anyone or anything (you, a junior dev, an agent). A bad spec produces bad code regardless of who writes it. Invest in specs.

### 2. Agent output is a junior's PR. Review it that way.

Read every line. Verify behavior with at least one test. Don't merge what you don't understand. Don't accept "the agent said it works" as evidence — the agent is confidently wrong sometimes.

### 3. When a prompt repeats, codify it.

The third time you find yourself typing roughly the same context-setting prompt, it becomes a slash command. The third time you find yourself catching the same kind of bug, it becomes a check in your review checklist. Methodology compounds when you treat it as code.

## Where the commands live

**User-level (`~/.claude/commands/`).** Installed once with `bin/install-personal.sh`. Available in every project you open. Doesn't require team consent — these are YOUR commands.

When you join a team or are handed a repo:

```bash
git clone <team-repo>
cd <team-repo>
# Your personal commands already work — no team setup required
# If the team has their own CLAUDE.md and commands, they layer on top
```

If the team independently defines `/work` or `/safe-commit`, the project-level version wins. Conflict-free.

## How to extend this

The `personal-commands/` directory in this repo is the source of truth. To add a new personal command:

1. Write `personal-commands/<name>.md` following the format of the existing ones.
2. Add `<name>` to the `PERSONAL_COMMANDS` array in `bin/install-personal.sh`.
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
