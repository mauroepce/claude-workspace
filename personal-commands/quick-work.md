---
description: Lite version of /work for small tasks where the full spec ceremony would be overhead. Use for single-file edits, simple bug fixes, micro-refactors, or anything you'd estimate at <30 minutes. Trades structure for speed while keeping the critical review step.
---

# /quick-work — Lite framework for small tasks

You are Claude. The user has a small task — single-file edit, 1-2 function changes, a CSS tweak, a typo fix, a 3-line refactor — and the full `/work` spec ceremony is overkill.

`/quick-work` keeps the senior discipline (think before generate, review before commit) without the 5-question intake. Estimated total session: 5-15 minutes.

**When to use this vs `/work`:**

| Use `/quick-work` when... | Use `/work` when... |
|---|---|
| Change is <30 lines | Change touches multiple files or is non-trivial logic |
| You can articulate the task in 1 sentence | The task needs constraints written down (no new deps, must be backward-compat, etc.) |
| The failure mode is obvious or trivial | Failure modes need explicit thought (data integrity, race conditions, etc.) |
| You're not committing afterward (just exploring) | You'll commit and need the spec to anchor the commit message |

If in doubt, use `/work`. The full spec costs you 3 extra minutes but saves you debugging cycles. `/quick-work` is for when 3 minutes IS the entire task.

**Argument (optional):** `$ARGUMENTS` may be the task description. If empty, ask.

## Phase 1 — Restate

Read or ask for the task. Restate it in your own words:

> "Got it — you want me to [restated task]. Constraints I'm assuming: [stack from project files], no new deps unless asked, change scope limited to [obvious area]. Confirm or correct?"

Wait for confirmation. This is the only "ceremony" — it catches misunderstandings in 30 seconds.

## Phase 2 — Generate

Make the change. Show the diff inline (not just the new code).

If the change requires reading a file you don't have context on, read it first. Don't guess at structure.

## Phase 3 — Self-check (the discipline that survives)

Out loud, run these three quick checks:

1. **Does it solve the actual task?** (Read the diff against the restated task)
2. **Does it break anything obvious?** (Type errors, missing imports, undefined refs, mismatched function signatures)
3. **Edge cases worth noting?** (Empty input, null, etc. — call them out even if you don't handle them)

Output format:

```
SELF-CHECK
✓ Solves: <task restated>
✓ No obvious breakage: <X type checks fine, imports resolved, etc.>
⚠ Edge cases noted: <list any you're aware of but didn't handle, with reasoning>
```

If anything is ⚠ and the user might care, ask before considering this done.

## Phase 4 — Hand off

End with one of:

> "Done. Run `/safe-commit` if you want to commit this with the review gate, or just `git add + commit` directly if you're confident."

OR (if user mentioned a test):

> "Done. Run the test to verify before committing: `<command>`."

OR (if exploration, not committing):

> "Done. Diff is above — let me know if you want to iterate or commit."

## What `/quick-work` does NOT do

- No 5-question spec phase
- No formal plan generation
- No prediction of all failure modes upfront
- No saving spec to `/todo` for future sessions

If you find yourself doing 2+ `/quick-work` invocations on the same logical task, **switch to `/work`**. The compounding context cost exceeds the spec ceremony cost.

## What it DOES do

- Forces the restatement (catches 50% of misunderstandings)
- Forces the self-check (catches 80% of obvious bugs)
- Hands off cleanly to `/safe-commit` if needed

That's the senior discipline distilled to its irreducible minimum.
