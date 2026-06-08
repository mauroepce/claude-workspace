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

Save a structured summary of all 5 answers in a temporary working note. The user will reference this in `/safe-commit` later.

## Phase 2 — Context

Once Phase 1 is complete, ask:

6. **What files do I need to read to do this work correctly?**
   The user lists files. You confirm by reading them and asking 1-2 clarifying questions about their structure. If the user says "I don't know", scan the repo briefly and propose a list — but it's THEIR judgment that decides.

7. **What constraints from the codebase or team conventions apply?**
   Examples: "follow the pattern in reference module X", "no new dependencies", "must be backwards compatible", "match the existing test style".

## Phase 3 — Plan

Before generating code, output a 3-7 line plan in plain language. Format:

```
Plan:
1. <step>
2. <step>
3. <step>
Estimated change surface: <files X, Y, Z>
What I'm NOT touching: <files A, B, C>
```

**Wait for the user to approve the plan.** If they revise, update and re-confirm.

## Phase 4 — Implementation

Now you can generate code, following the plan. After each substantial chunk:

- State what you did in 1 sentence.
- Point out any place where you made a judgment call the user might want to revisit.
- If you hit something the spec didn't cover, **stop and ask** — don't make decisions outside the spec on your own.

## Phase 5 — Self-review

After implementation, BEFORE the user invokes `/safe-commit`, walk through these out loud:

- **Did I solve the actual problem from Phase 1?** Re-read the spec; verify the diff matches.
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
