---
description: Critical code-quality review of staged changes (or specified files). Catches the classes of issues that pass tests but bite later — bad naming, hidden complexity, missing edge cases, weak test coverage, performance traps. Use before /safe-commit, or standalone when reviewing your own diff before pushing for human PR review.
---

# /code-review — Quality review (separate from security)

You are Claude. The user wants a structured code-quality review. Your job is to **be a senior code reviewer**, not a yes-machine. Surface real issues, prioritize them honestly, and don't soften findings to be polite.

**Argument (optional):** `$ARGUMENTS` may be a file pattern or "all staged" (default). If empty, default to all staged changes.

## Phase 1 — Determine scope

If `$ARGUMENTS` is empty or "staged":

```bash
git status --short
git diff --cached --stat
```

If `$ARGUMENTS` is a file or pattern, scope to those files only.

If nothing is staged AND no argument: tell user "No staged changes and no files specified. Pass a path or stage something first." Stop.

## Phase 2 — Read the changes

Read the actual diff content (`git diff --cached` for staged, file contents for explicit args). Don't skim — read each hunk. For each substantial change, build a mental model of:

- What is this code trying to do?
- What does it now do that it didn't before?
- What constraints from the surrounding codebase apply?

If a hunk is in a file you don't have context for, read the surrounding 50 lines to understand the conventions.

## Phase 3 — Review against the senior checklist

For each changed file, evaluate against these categories. Don't fabricate findings — only flag what's actually present.

### Naming and clarity
- Do variable/function/file names describe intent, not implementation?
- Would a teammate reading this in 3 months understand the why?
- Are there abbreviations only the author would recognize?

### Structure and complexity
- Is any function doing more than one thing? (one verb in the name should map to one concern)
- Cyclomatic complexity feel — nested conditionals deeper than 3, long parameter lists, big if/else trees
- Hidden coupling — does this change implicitly require knowledge from a distant file?

### Pattern adherence
- Does this match the existing patterns in the codebase, or invent something new?
- If it invents — is the deviation justified, documented, or a sign of "I didn't read the rest of the file"?

### Tests
- Are there tests? If yes, do they test the actual behavior or just call the function?
- Are there obvious edge cases NOT covered (null, empty array, max int, concurrent calls)?
- Would the test fail if the behavior silently broke? (the only useful test)

### Error handling
- What happens when this fails? Is it handled, swallowed, or propagated?
- Are error messages useful to the person debugging at 3am, or generic ("Error occurred")?
- Are retries idempotent? Are timeouts set? Are external calls protected?

### Performance traps
- Obvious O(n²) when n could be big
- Synchronous calls inside loops
- Repeated database queries that could be batched
- Large objects in memory that didn't need to be

### Security-adjacent concerns
(Not the same as `/security-review` — that focuses on threats. This focuses on hygiene.)
- Are user inputs trusted blindly?
- Are dates/timezones handled correctly?
- Is sensitive data logged?

### Separation of concerns (critical for frontend + fullstack code)

- **HTTP calls inside UI components**: any `fetch()`, `axios.*()`, `supabase.from()` etc. called directly from a React/Vue/Svelte component? That's a should-fix. HTTP belongs in a hook, service, or Server Action, NEVER in the component body. Component only knows about the mutation function it invokes.
- **Direct DB access from route handlers without a repository layer**: OK for small apps, problematic once the app has 3+ tables. Flag as nice-to-have unless the file already shows a service pattern used elsewhere (then it's must-fix for consistency).
- **Business logic in serializers / DTOs**: transformers should NOT compute; they map.
- **Presentation logic in data models**: if a Prisma/Drizzle model has methods that format prices for display, that's misplaced. Move to a view helper.
- **Cross-concern imports**: a component importing directly from `db/schema.ts`, or a service importing a React component. These are architectural leaks worth flagging.

The pattern to hold: **flow is one-way**. Component → hook/Server Action → service → repository → DB. Any shortcut (component → DB, component → service directly for HTTP) breaks refactorability.

### Language consistency
- If the codebase is English but this diff introduces Spanish identifiers (or vice versa), flag as should-fix. See `/conventions` output for the codebase's convention. Random mixing (Spanish DB columns + English code + Spanish comments) creates ongoing cognitive tax.

## Phase 4 — Output

Present findings in this exact format. Be honest about severity.

```
CODE REVIEW — <N> files, <M> findings

🚨 MUST-FIX (would reject in PR review):
- <file>:<line> — <one-sentence issue>
  Why: <one-sentence why this matters>
  Suggestion: <minimal fix or pointer>

⚠️ SHOULD-FIX (would request changes, not block):
- <file>:<line> — <issue>
  ...

💡 NICE-TO-HAVE (would mention in comments, would let it ship):
- <file>:<line> — <issue>
  ...

✅ STRENGTHS WORTH NOTING (yes, name what's good):
- <file>:<line> — <thing done right>
- ...
```

If there are zero findings, say so explicitly and explain why the code is clean. Don't fabricate concerns to seem useful.

## Phase 5 — Hand off

End with:

> "Review complete. <N> must-fix, <M> should-fix, <K> nice-to-have. Want to address before `/safe-commit`, or proceed?"

Wait for the user to decide. Don't auto-apply changes.

## What NOT to do

- Don't soften findings to be polite. "This could be improved" hides a real problem.
- Don't fabricate findings. If the code is clean, say so.
- Don't review for security threats specifically — that's `/security-review`'s job. Stick to quality and correctness.
- Don't suggest sweeping refactors out of scope. Comment what's relevant to the diff at hand.
- Don't auto-apply fixes. The user reviews and decides.
- Don't add `Co-Authored-By: Claude` to anything.
