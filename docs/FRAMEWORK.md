# The Framework

> A short, opinionated methodology for working with AI agents on production code. Not theoretical — the four `personal-commands/` in this repo encode it.

## The thesis

The work has shifted. Writing code is no longer the senior skill — **directing the model is**. That requires:

1. **Spec before generation.** Define what success looks like, what the constraint set is, and what failure modes you expect. Skipping this is where bad code comes from.
2. **Critical review of every output.** Treat agent output like a junior pair's PR — verify behavior, read every line, don't merge what you don't understand.
3. **Workflow as artifact.** When the same prompt is going to come up three times, codify it. Slash commands, skills, and reference modules are how methodology compounds.

This isn't novel philosophy. It's the practical operating model of senior engineers who have shipped real production code with agents in 2025–2026. The four commands in this repo make it executable.

## The five commands

### `/work` — spec → generate → review → iterate

Forces you through a structured intake before any code generation:

1. **Spec phase** — what, why, what does NOT change, success criteria, failure modes.
2. **Context phase** — which files to load, what conventions apply.
3. **Plan phase** — a 3–7 line plan you approve before generation starts.
4. **Implementation phase** — generation, with the agent pausing on judgment calls.
5. **Self-review phase** — verify the diff matches the spec, no scope drift, failure modes handled.
6. **Hand off to `/safe-commit`**.

The win: the spec and failure modes are written down BEFORE generation, so review has a clear baseline. You can't drift into "while I'm here, let me also..." without noticing.

### `/issue <number>` — GitHub issue intake

Pulls an issue with `gh`, structures the context, surfaces what's NOT defined in the issue body, asks for additional context only you have, optionally creates a branch, and hands off to `/work`.

The win: stops you from interpreting issue bodies generously. The "what's not defined yet" section is where senior judgment adds value — you make implicit ambiguity explicit before generating anything.

### `/debug` — hypothesis-driven debugging

When a bug appears — during implementation, in a production log, in a CI alert, anywhere — the temptation is to paste the error and ask for a fix. That loop drives bugs into hiding instead of resolving them.

`/debug` enforces a 9-step discipline:

1. **Symptom capture** — exact error, full trace, where it appeared, what was expected.
2. **Reproduction** — minimum repro steps. No fix without repro (heisenbugs need more telemetry first).
3. **Your hypothesis** — your one-line guess of the cause, BEFORE the model investigates. Non-negotiable.
4. **Investigation** — confirm or refute your hypothesis by reading code, logs, tests, recent commits.
5. **Root cause** — the deeper reason, not the proximate cause. The fix should address the class of bugs, not the instance.
6. **Scope decision** — is this bug in-scope for your current `/work` task, or is it a separate discovery? If separate, log it and return to the original task. Resist scope drift.
7. **Minimal fix** — smallest change that addresses the root cause. No "while I'm here" cleanup.
8. **Regression test** — a test that would have caught this. Without it, the bug recurs.
9. **Hand off** to `/safe-commit` (in-scope) or new task (separate).

The win: stops the "paste error → first fix → next error" loop that accumulates hacks. Your hypothesis matching the diagnosis is also the calibration signal — if you were wildly wrong, the bug points to a deeper misunderstanding worth investigating.

### `/conventions` — codebase convention detection (persistent)

Scans an unfamiliar codebase (config files + 3-5 sampled source files) and produces a structured report of:
- Import style (ESM vs CJS, path aliases, default vs named)
- Quoting and formatting (single vs double quotes, semicolons, indentation)
- Naming conventions (file names, components, constants)
- File organization (where types live, where tests live, reference modules)
- Error handling pattern (throw vs Result vs null)
- Async patterns, test framework, documentation style
- Anti-pattern audit and honest gaps

**Critical: the report is persisted to a file**, not just printed to chat. By default it writes to `.claude/conventions.md` (committed to the repo, team benefits). Other options:
- `CONVENTIONS.md` at root — committed, more visible
- `.claude/conventions.local.md` — gitignored, personal-only (good for client repos, interview prep)
- Chat-only (only useful for one-shot exploration)

This persistence is what makes `/work` aware of conventions across sessions. Without it, every new conversation would have to re-detect from scratch — wasted time and inconsistent results.

The 60 seconds spent on `/conventions` save 20 minutes of style-drift fixes later in a long session. When you join a new codebase (interview, new team, new client), run this BEFORE any code generation.

### Composition with `/work`

`/work` Phase 2 (Context) automatically looks for `.claude/conventions.local.md`, `.claude/conventions.md`, or `CONVENTIONS.md`. If any is found, it's loaded and respected for any code generated downstream. The user doesn't have to re-paste the report — the file is the persistent context.

If you're starting a fresh project where conventions don't exist yet, `/work` skips this lookup and conventions come from the explicit constraints articulated in the spec phase. As the project grows, you can run `/conventions` at some point and then future `/work` invocations auto-pick it up.

### `/architecture-map` — codebase cheat sheet

Scans an entire codebase and produces `architecture-map.md`: stack (from package.json), directory structure, database schema (Prisma / Drizzle / Supabase migrations), API routes (Next.js App Router / Express / NestJS controllers), auth pattern, external integrations, and 5-10 critical files identified.

Complements `/conventions`: `/conventions` tells you what the code looks like (style), `/architecture-map` tells you what the code does (structure). Together they give you both.

Use when joining an unfamiliar repo, returning to your own code after months, or preparing for an interview where you'll be questioned on a system you wrote a while ago. Honest about gaps — sections that can't be derived from code are marked "TBD: fill from memory" instead of fabricated.

### `/decision` — capture a technical decision

Walks the user through 4 questions (decision, alternative, why this won, confidence level 🟢🟡🔴), with an optional 5th about trade-offs. Appends to `decisions-log.md` so the rationale persists across sessions.

Decisions made in chat evaporate when the session ends — by writing them to a file, they become part of the codebase's tribal knowledge. Useful both during `/work` (capture choices as you make them) and retroactively (document past decisions from memory).

The confidence level is the most senior part: a 🔴 documented honestly is worth more than a fabricated 🟢. Future-you reading the log knows which decisions are stable and which are worth revisiting.

### `/code-review` — quality review (atomic, reusable)

Quality-focused code review: naming, complexity, pattern adherence, test coverage, edge cases, error handling, performance traps. Output is tiered: must-fix / should-fix / nice-to-have / strengths.

Use standalone when:
- Iterating on quality mid-implementation, before deciding commit boundary
- Reviewing unstaged work or files on a different branch
- Reviewing a specific file outside the staged context
- Doing a pre-PR sanity check on a branch before push

`/safe-commit` invokes this internally as Phase 2 — that's composition, not duplication. The atomic command and the orchestrator coexist: invoke the atom when you only need quality feedback, invoke the orchestrator when you're ready for the full commit gate.

### `/safe-commit` — review before commit

Runs the built-in `security-review` skill on staged changes, scans for hardcoded secrets and other risky patterns, verifies the commit maps to your `/work` spec, generates a commit message that explains the **why**, and only commits after explicit confirmation. Never bypasses git hooks.

The win: catches the obvious failure modes (secret leaks, unintentional auth changes, suspicious diff patterns) before they enter history. Plus commit messages that have business value, not "update files".

### `/safe-push` — review before push

Inspects the full branch diff (not just the latest commit), runs security review across all commits being pushed, optionally runs the test suite, and refuses to push to `main`/`master` without an extra explicit confirmation. Never force-pushes or skips hooks.

The win: the difference between a senior engineer and a fast one is what happens between `git commit` and `git push`. This command makes that gap deliberate.

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

1. Write `personal-commands/<name>.md` following the format of the existing four.
2. Add `<name>` to the `PERSONAL_COMMANDS` array in `bin/install-personal.sh`.
3. Re-run `bin/install-personal.sh` on your machine (or anyone you've shared this with).

Possible future additions:
- `/spike <topic>` — time-boxed exploration with explicit "this is throwaway" framing
- `/postmortem <incident>` — structured post-incident review and write-up
- `/onboard <repo>` — first-day reading list for a new codebase

## What this is not

- **Not a productivity hack.** It's intentionally slower at the start because spec-first beats generate-first over the whole task lifetime, not per-prompt.
- **Not framework worship.** If a task is small enough that ceremony is overhead, skip the commands and just type. `/work` for a 5-line CSS fix is wrong.
- **Not autopilot.** Every command pauses for user confirmation at decision points. The agent never commits or pushes without explicit OK.

## Closing

If you're reading this because someone handed you the repo and said "this is how I work" — the commands and this doc are everything. Read the four `personal-commands/*.md` files. They are short. The format teaches itself.
