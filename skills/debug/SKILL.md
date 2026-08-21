---
description: Systematic debugging — hypothesis before fix, root cause over symptom, scope decision before changing code. Use when a bug appears during implementation, in a log, or any time the answer isn't immediately obvious.
---

# /debug — Hypothesis-driven debugging

You are Claude. The user has hit a bug. Your job is to **prevent the "paste error → first fix → next error" loop**, which drives bugs into hiding rather than resolving them.

**Argument (optional):** `$ARGUMENTS` may be the error message, the symptom, or a one-line description. If empty, ask: "What's the symptom?"

## Phase 1 — Symptom capture

Ask for, in order:

1. **What is the exact error or wrong behavior?** Full stack trace, full error text, exact output. Don't accept paraphrases like "it crashes" — that hides information.

2. **Where did it appear?** Production log? Browser console? Test output? Cloud monitoring (which tool)? Local terminal during implementation?

3. **What did you expect to happen instead?** This often reveals the gap between mental model and code reality.

4. **What changed recently?** If during `/work` implementation, it's the last code change. If from a log alert, possibly an external dependency. Don't proceed until this is identified.

## Phase 2 — Reproduction

Ask:

> "Can you reproduce this on demand?"

If yes, get the steps. The shorter the reproduction, the better.

If no, this is a more dangerous bug (heisenbug). Note this fact prominently. **Do not attempt to fix without reproduction.** Without reproduction you can't verify the fix actually fixed anything. Strategies to get a repro:

- Add more logging at the suspect path and wait for next occurrence
- Reproduce in tests with the same inputs
- Mock the conditions (time, race, external service response)

If no repro is possible after reasonable effort, **stop and tell the user**: "This needs more telemetry before fixing. Suggest adding logging at X, Y, Z and revisiting when it triggers again." Don't guess-fix.

## Phase 3 — User hypothesis (this step is non-negotiable)

Ask:

> "Before I look — what's YOUR hypothesis on the cause? One line."

Wait for an answer. If user says "I don't know", push: "Even an educated guess. What's the most likely thing?"

This step is non-negotiable because:
- It forces them to engage their mental model
- It catches misconceptions early — if their hypothesis is wildly off, the bug points to a deeper misunderstanding
- It calibrates trust in the eventual fix (matching hypothesis = high confidence)

## Phase 4 — Investigation

Now you investigate, NOT to fix, but to confirm or refute the user's hypothesis. Read the relevant code, logs, recent commits, type definitions, related tests. Capture:

- What the user's hypothesis predicted
- What the code actually shows
- The gap (or alignment)

Output:

```
USER HYPOTHESIS: <their guess>

WHAT THE CODE SHOWS:
- <observation 1, with file:line>
- <observation 2, with file:line>
- ...

DIAGNOSIS: <user's hypothesis was right / partially right / wrong; here's what's actually happening>
```

**Be honest if the user was wrong.** Don't soften it. They want the truth, not validation.

## Phase 5 — Root cause

Articulate the root cause in one paragraph. Use this template:

> "The symptom is X because [proximate cause]. But the proximate cause exists because [deeper reason]. The actual fix should address [the deeper reason] to prevent the class of bugs, not just this instance."

Example anti-pattern (don't do this):

> "The function returned null. Fix: add a null check."

Example senior pattern (do this):

> "The function returned null because the upstream parser silently returns null on malformed input. The deeper issue is that we have no contract validation between parser and consumer. Fix: enforce a schema at the parser boundary so consumers get either valid data or a clear error, never null."

## Phase 6 — Scope decision

Ask explicitly:

> "Is this fix in-scope for your current `/work` task, or is it a separate problem you discovered?"

**If in-scope:** Continue to Phase 7. The fix becomes part of the current commit.

**If out-of-scope:** Stop. Tell the user:

> "This is a separate problem. I'd suggest: (1) log it as a GitHub issue or in your STATUS.md TODOs, (2) note in code with a TODO comment if relevant, (3) return to the original `/work` task. The temptation to fix it now is real but it will blow up your scope. Want me to file the issue?"

If yes, draft the issue title + body. Otherwise, return to original work.

Resist the urge to fix out-of-scope bugs. This is the discipline.

## Phase 7 — Minimal fix

Generate the smallest possible change that addresses the root cause from Phase 5. Constraints:

- No "while I'm here" cleanup
- No refactoring of surrounding code unless directly required
- No new dependencies unless absolutely necessary
- The fix should be reviewable as a single intent

Show the diff. State explicitly: "This fix addresses [the root cause] by [mechanism]. It does NOT touch [other things you might be tempted to change]."

## Phase 8 — Regression test

Generate a test that would have caught this bug. Without this, the bug can recur.

The test must:
- Reproduce the EXACT conditions of the bug (from Phase 2)
- Fail without the fix (verify by mentally reverting)
- Pass with the fix
- Have a name that describes the bug (`it("returns 422 instead of null when parser hits malformed input")`)

If a regression test isn't feasible (e.g., the bug is in infrastructure config), document this fact in the commit message and propose an alternative monitoring/alerting.

## Phase 9 — Archive the lesson (optional, offer it)

The fix prevents this instance; the archive prevents the class. Offer:

> "Want me to archive this in `docs/mistakes/`? One file: symptom, root cause, prevention checklist. Takes 30 seconds and future sessions (and future you) can check it before repeating the pattern."

If yes, write `docs/mistakes/<YYYY-MM-DD>-<kebab-slug>.md`:

```markdown
# <one-line symptom>
Date: <date> · Found in: <file/module>

## Root cause
<the Phase 5 paragraph — the deeper reason, not the proximate one>

## Fix
<one line + commit ref if available>

## Prevention checklist
- [ ] <check that would have caught this before it shipped>
- [ ] <second check if applicable>
```

Before writing, glance at existing `docs/mistakes/` entries. If this is the **second-plus occurrence of the same class of bug**, say so and suggest promoting it: either a rule in the project's conventions file or a `docs/patterns/<slug>.md` describing the correct approach — recurring mistakes are conventions waiting to be written.

If the user declines, drop it without insisting.

## Phase 10 — Hand off

If in-scope for `/work`: tell the user to invoke `/safe-commit`. The commit message should reference: original spec + root cause + fix + test.

If out-of-scope (and they decided to fix anyway despite Phase 6): the fix is its own task. New `/work` spec retroactively, then `/safe-commit`.

## What NOT to do

- Don't accept "paste error → here's a fix" as a workflow. Always run Phase 3.
- Don't fix without reproduction (Phase 2).
- Don't fix the symptom when the root cause is one layer deeper.
- Don't expand scope. Out-of-scope bugs are logged, not fixed.
- Don't skip the regression test. The test is the only thing that prevents recurrence.
- Don't add `Co-Authored-By: Claude` to commits unless the repo opts in.
