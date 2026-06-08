---
description: Pull a GitHub issue by number, structure its context, and hand off to the spec → generate → review framework (/work). Use to start work that was filed as an issue.
---

# /issue — GitHub issue intake

You are Claude. The user invoked `/issue $ARGUMENTS` to start work from a GitHub issue. Your job is to fetch the issue, surface what matters, and hand off to the structured workflow.

**Argument required:** issue number (e.g., `47`). If `$ARGUMENTS` is empty, ask: "Issue number?"

## Phase 1 — Fetch

Run, in order:

```bash
gh issue view $ARGUMENTS --json title,body,labels,state,assignees,comments,url
```

If this fails because `gh` is not authenticated, tell the user to run `gh auth login` and try again. Don't proceed with partial info.

## Phase 2 — Structure

From the JSON, present a structured summary in this exact format:

```
ISSUE #<number> — <title>
Status: <open / closed>
Labels: <labels or "none">
URL: <url>

PROBLEM (the body, summarized to 3-5 lines max):
<your summary>

EXPLICIT REQUIREMENTS (extracted from the body — lists, checkboxes, code blocks):
- <req 1>
- <req 2>
- ...

OPEN QUESTIONS RAISED IN COMMENTS:
- <comment author> (<date>): <key point>
- ...

WHAT'S NOT DEFINED YET (your reading of the gaps):
- <gap 1>
- <gap 2>
- ...
```

The "What's not defined yet" section is critical. Read between the lines and surface ambiguity that the framework will need to resolve.

## Phase 3 — Additional context (this is the user's job)

Ask:

> "Anything you know that's not in the issue? E.g., a teammate told you X, you saw Y in a related PR, you know the customer's actual use case is Z."

Wait for the answer. Append to a notes section.

## Phase 4 — Branch setup (optional, ask)

Ask:

> "Want me to create a branch for this issue? Suggested name: `issue-<number>-<slug-of-title>`. Or are you working on an existing branch?"

If yes, run:

```bash
git checkout -b issue-$ARGUMENTS-<slug>
```

Use a kebab-case slug from the title (max 5 words).

## Phase 5 — Hand off to /work

Output:

> "Issue context loaded. Spec for `/work` ready. Invoke `/work` now and use this issue summary as your input to Phase 1."

Save the structured issue summary + your additional notes to a temporary working memory the user can reference. The user invokes `/work` next.

## What NOT to do

- Don't start implementing. This command is intake only.
- Don't trust the issue body uncritically. The "what's not defined" section is where your judgment adds value.
- Don't auto-create the branch unless the user agrees.
- Don't comment on the GitHub issue from this command. That happens later when the work is shipped.
