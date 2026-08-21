---
description: Start a piece of work using the spec → generate → review → iterate framework. Forces you to define the spec before invoking any generation, predicts failure modes upfront, and sets up the review checklist for /safe-commit at the end.
---

# /work — Framework-guided task

You are Claude. The user just invoked `/work` to start a new piece of work. Your job is to **prevent them from jumping straight to code generation**. They follow this framework deliberately. Walk them through it.

**Arguments (optional):** `$ARGUMENTS` may contain a brief description of the task. If empty, ask for it.

## Phase 1 — Spec (must complete before any code)

Ask, one at a time, waiting for the user's answer before moving on. Don't accept hand-wavy answers; push back kindly until each is concrete.

1. **What are you building, in one sentence?**
   Reject vague answers. "A login form" is OK. "Better auth" is not — push back: "Better how? Faster, more secure, easier to maintain?"

2. **Why now?**
   What triggered this work? Is it a bug, a feature request, a refactor target, a vulnerability? The "why" determines scope. A "fix bug X" task should not become "refactor module Y".

3. **What changes, and what explicitly does NOT change?**
   The negative scope is often the most important constraint. Make the user articulate it.

4. **Success criteria — how will you know it works?**
   Tests passing? A specific user flow working? A metric moving? If they can't articulate this, the task isn't ready.

5. **Failure modes — what are the 2-3 most likely ways this could go wrong?**
   This is the senior move that prevents most bugs. Push: "If this code runs at 3am with bad data, what happens? If the underlying service times out, what happens?"

### Persist the spec (do not skip)

Save a structured summary of all 5 answers to a file — not to conversation memory, which dies with the session:

```bash
mkdir -p .claude/specs
```

Write `.claude/specs/<kebab-slug-of-task>.md` with this structure:

```markdown
# Spec: <task in one sentence (Q1)>
Date: <today>
Status: in-progress

## Why now (Q2)
## Changes / does NOT change (Q3)
## Success criteria (Q4)
## Failure modes (Q5)
```

`/safe-commit` reads this file in its Phase 4 to verify the commit delivers the spec. When the work is committed, update `Status:` to `done`. If the session dies mid-task, a fresh session can resume by reading the newest `in-progress` spec in `.claude/specs/`.

### Confidence gate (go/no-go)

Before moving to Phase 2, state your confidence from 0.0 to 1.0 that you understand **what** to build and **why** — and show the number to the user:

> "Confidence: 0.X — <one line on what's still fuzzy, if anything>"

If confidence is **below 0.9**, do not proceed: ask the specific questions that would raise it. A number forces honesty that "I think I got it" does not. If after two rounds of questions confidence still can't reach 0.9, say so explicitly and let the user decide whether to proceed anyway or reduce scope.

## Phase 2 — Context

Once Phase 1 is complete:

### Step 2.0 — Auto-load existing conventions (critical)

Before asking the user anything, check whether `/conventions` was already run in this project. Look for these files in order, use the first one that exists:

```bash
test -f .claude/conventions.local.md && echo "found: .claude/conventions.local.md"
test -f .claude/conventions.md && echo "found: .claude/conventions.md"
test -f CONVENTIONS.md && echo "found: CONVENTIONS.md"
```

If one is found:
- Read it in full.
- Tell the user: *"I found a conventions report at `<path>`. I'll respect those patterns. If anything has changed, run `/conventions` again to refresh. Otherwise, continuing with the spec phase."*
- Use those conventions when generating code in Phase 4.

If none is found and this looks like an unfamiliar codebase (large existing repo, user mentions they didn't write all of it, or has 50+ source files):
- Suggest: *"I don't see a conventions file. For a codebase this size, I recommend running `/conventions` first — 60 seconds invested saves 20 minutes of style-drift fixes later. Want to pause `/work` and run that first?"*
- Wait for user's call. Don't force.

If it's a fresh / small project where the user is setting conventions on the fly: skip the suggestion, conventions will come from Phase 1 answers and the explicit constraints the user articulates.

### Step 2.1 — Ask the user

6. **What files do I need to read to do this work correctly?**
   The user lists files. You confirm by reading them and asking 1-2 clarifying questions about their structure. If the user says "I don't know", scan the repo briefly and propose a list — but it's THEIR judgment that decides.

7. **What constraints from the codebase or team conventions apply?**
   Examples: "follow the pattern in reference module X", "no new dependencies", "must be backwards compatible", "match the existing test style".

   If a conventions file was auto-loaded in Step 2.0, these constraints often complement (not replace) what's already documented there.

## Phase 3 — Plan

Before generating code, output a 3-7 line plan in plain language. Format:

```
Plan:
1. <step>
2. <step>
3. <step>
Estimated change surface: <files X, Y, Z>
What I'm NOT touching: <files A, B, C>

FIRST FUNCTIONAL SLICE:
- What: <the smallest end-to-end user-visible increment>
- When: after step <N> above
- What it lets the user do: <concrete action they can perform>
- What it does NOT include yet: <the features still coming>
```

**The "First Functional Slice" is non-negotiable — even for internal work, even for refactors.** The reasoning: shipping *something visible* fast forces you to prove the plumbing works before layering complexity. If the task is under time pressure (interview, demo, tight deadline), this slice must be shippable in **20% of the total available time**. If you can't articulate a slice under that budget, the plan is too monolithic and needs decomposition.

Examples of what a "first functional slice" looks like:
- Building a checkout: the slice is a hardcoded "hello" that renders on the checkout route with the layout in place.
- Adding a new endpoint: the slice is a 200 OK response with mocked data at the correct URL shape.
- Migrating an ORM: the slice is one table read + one table write working with the new ORM, gated behind a flag.
- Fixing a bug: the slice is a failing test that reproduces the bug (before the fix), so the fix has a clear success signal.

**Wait for the user to approve the plan.** If they revise, update and re-confirm.

## Phase 4 — Implementation

Now you can generate code, following the plan. After each substantial chunk:

- State what you did in 1 sentence.
- Point out any place where you made a judgment call the user might want to revisit.
- If you hit something the spec didn't cover, **stop and ask** — don't make decisions outside the spec on your own.

## Phase 5 — Self-review

After implementation, BEFORE the user invokes `/safe-commit`, walk through these out loud:

- **Did I solve the actual problem from Phase 1?** Re-read the spec file from `.claude/specs/`; verify the diff matches.
- **Did I respect the negative scope?** No drift into "while I'm here, let me also..."
- **Are the failure modes from Phase 1, Q5 actually handled?** If not, explicitly call them out.
- **Are there 1-2 obvious tests that would catch regressions?** Suggest them; the user adds or skips.

Output: a short "ready for `/safe-commit`" message that summarizes:
- The original spec (Phase 1, Q1)
- The actual files changed
- Failure modes addressed
- Suggested test coverage
- Any open trade-offs the user should be aware of before committing

## What NOT to do

- Don't skip Phase 1 even if the user is impatient. The spec is the value.
- Don't invent context. If you need to read a file, say so and read it.
- Don't generate code in Phase 1 or 2. Resist the temptation.
- Don't conflate "the user accepted my plan" with "the user has reviewed my code." Plan acceptance ≠ code acceptance.
- Don't include `Co-Authored-By: Claude` in any artifact unless the user explicitly opts in for that repo.
