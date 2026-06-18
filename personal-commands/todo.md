---
description: Manage persistent todos/milestones for current work. Unlike Claude Code's built-in TodoWrite (which is session-only), these survive across sessions in .claude/todos.md. Create tasks with milestones, mark them done, see current focus. Use when a task is big enough to span multiple sessions, or when you need to remember "where was I?".
---

# /todo — Persistent task tracking with milestones

You are Claude. The user wants to manage tasks (with multiple milestones each) that survive across Claude Code sessions.

This complements — does NOT replace — the built-in `TodoWrite` tool. Use TodoWrite for in-session tracking (the in-the-moment task list you maintain while working). Use `/todo` to PERSIST those todos to a file so they survive when the session ends.

**Argument (optional):** `$ARGUMENTS` may be an action keyword. If empty, show the menu.

## Phase 1 — Read current state

First, always load the existing todos file (or create if missing):

```bash
# Check for existing todos file
test -f .claude/todos.md && echo "found .claude/todos.md"
test -f .claude/todos.local.md && echo "found .claude/todos.local.md"
test -f TODOS.md && echo "found TODOS.md"
```

If none exists yet, the user is creating their first task. Skip to "Action: new" below.

If one exists, read it fully so you have context on all active tasks before doing anything.

## Phase 2 — Determine intent

Parse `$ARGUMENTS` to determine action:

| Argument starts with | Action |
|---|---|
| `new`, `add`, `create` | Create a new task with milestones |
| `done`, `complete`, `check` | Mark a milestone as completed |
| `list`, `status`, `show`, empty | Show current state of all tasks |
| `focus`, `switch` | Switch active task (when multiple are in-progress) |
| `archive`, `clean` | Move fully-completed tasks to archive section |
| `delete`, `remove`, `cancel` | Remove a task entirely (rare — usually archive is better) |

If `$ARGUMENTS` doesn't match clearly, ask:

> "What do you want to do?
> 1. **new** — create a new task with milestones
> 2. **done <N>** — mark milestone N done on focused task
> 3. **list** — show all current tasks and their progress
> 4. **focus <task>** — switch which task is the focused one
> 5. **archive** — move fully-completed tasks to archive
>
> Or just describe what you need."

## Action: new

Ask the user, one at a time:

### Q1 — Task title (one line)

> "What's the task in one line? (e.g., 'Build user dashboard with charts')"

Save as the task title. Generate a kebab-case slug for internal use.

### Q2 — Break into milestones

> "How do you want to break this into milestones? Two options:
> 1. **I tell you the milestones** (you list them, comma-separated or one per line)
> 2. **You propose milestones** (I'll suggest 3-7 based on the task description; you accept or revise)
>
> Which?"

If user picks option 1: capture the list.
If user picks option 2: propose 3-7 concrete milestones based on the task. Each should be:
- Specific (verb + object: "Define API contract" not "Plan API")
- Actionable (someone could start working on it without further definition)
- Verifiable (you can tell when it's done)
- Independent enough to ship/test in isolation (when possible)

Example for "Build user dashboard with charts":
1. Spec the dashboard data model (what charts, what data sources, what filters)
2. Build API endpoint(s) for chart data
3. Add Recharts dependency and base layout
4. Implement the 3 chart components
5. Wire filtering UI to API
6. Add empty/loading/error states
7. Write tests for API and 1 representative chart

### Q3 — Estimated effort (optional)

> "Total estimated effort? (Optional. Helps calibrate later. e.g., 'half a day', '2 sessions', '1 week')"

If user skips, that's fine. Skip it.

### Q4 — Active status

> "Is this the focused task right now (the one you're actively working on)? Y/n"

Default Y. If Y, mark this task as `[FOCUSED]` and unmark any other previously focused task.

### Save the new task

Append to `.claude/todos.md` (default), or write the file if it doesn't exist. Format:

\`\`\`markdown
## <task-slug> — <Task title> [FOCUSED]

*Started: <YYYY-MM-DD> | Estimated effort: <effort or "TBD">*

### Milestones

- [ ] 1. <Milestone 1>
- [ ] 2. <Milestone 2>
- [ ] 3. <Milestone 3>
...

### Notes

*(empty — populated as work progresses, with decisions made, blockers hit, etc.)*

---
\`\`\`

If the file is empty, first add a header:

\`\`\`markdown
# Tasks

Personal task tracking. Each task has milestones, optional notes, and a focus marker.

\[FOCUSED\] marks the active task (only one at a time, by convention).

When tasks are fully done, run \`/todo archive\` to move them to the Archive section.

---

\`\`\`

After saving, output:

> "Task created: '<title>'. <N> milestones. <Path> updated.
>
> When you make progress, run `/todo done <N>` to mark milestones complete.
> When the session ends and you return tomorrow, run `/todo list` to remember where you were."

## Action: done <N>

Identify the focused task from the file (the one marked `[FOCUSED]`).

Update milestone N from `- [ ]` to `- [x]` and append `(done: <today's date>)` after the milestone text.

Check if ALL milestones are now done:
- If yes, ask: "Task '<title>' is now fully complete. Run `/todo archive` to move it to the archive section?"
- If no, output: "Marked milestone <N> done. <X>/<Y> milestones complete on '<title>'."

If `$ARGUMENTS` doesn't include a number, ask: *"Which milestone? (number from the focused task)"*. Show the current focused task's milestones so the user can pick.

## Action: list

Read the file. Output a clean summary:

```
ACTIVE TASKS

[FOCUSED] honorarios-prep — Study honorarios-cl for Carvuk interview
  Progress: 3/5 milestones complete (60%)
  Started 2026-06-18, focused since 2026-06-19
  Latest milestone done: "Read 5 critical files" (2026-06-19)
  Next: Fill decisions-log.md

other-task — Build user dashboard with charts
  Progress: 1/7 milestones (14%)
  Started 2026-06-15

ARCHIVE (5 tasks, last archived 2026-06-10)
```

If notes exist for the focused task, append:

```
Notes on focused task:
- <recent note 1>
- <recent note 2>
```

## Action: focus <task>

Find the task whose slug matches `$ARGUMENTS` (after "focus "). Mark it `[FOCUSED]`, remove the marker from any other task.

Output:
> "Focused task is now '<title>'. <N>/<M> milestones complete. Next: '<first unchecked milestone>'."

## Action: archive

Find all tasks where 100% of milestones are checked. Move them to the Archive section (create if missing). Add archive date.

Output:
> "Archived <N> completed tasks. <M> still active."

## Action: delete (rare)

Confirm with user before deleting:

> "Delete '<title>' completely? Usually you want `archive` instead — that preserves history. Confirm with 'yes delete' or cancel."

If confirmed, remove from file entirely.

## Adding notes to a task

If during the conversation the user articulates a decision, blocker, or learning relevant to the focused task, ask:

> "Want me to add a note to the focused task?
>   Note: <quote the user's words>"

If yes, append to the "Notes" section of that task with today's date.

Notes are gold for the "where was I?" moment after a long break.

## Composition with `/work`

When `/work` is invoked and produces a plan with 3+ steps in Phase 3, suggest at the end:

> "This plan has <N> steps. Want to persist it as a `/todo` task so it survives the session?"

If user accepts, invoke `/todo new` flow with the work's spec title and the plan steps as milestones.

This is the bridge: `/work` for the structured spec, `/todo` for the persistent execution tracker.

## What NOT to do

- Don't auto-mark milestones as done just because the user mentions them in passing. Wait for explicit `/todo done`.
- Don't write the file without showing the user what's being saved.
- Don't replace Claude Code's built-in TodoWrite. They serve different scopes (TodoWrite = in-session, `/todo` = cross-session).
- Don't keep all archived tasks forever. Suggest cleanup periodically: *"Archive section has 50 tasks. Trim to last 10?"*
- Don't add `Co-Authored-By: Claude` to the file.
