---
description: Pre-push safety net. Runs full-branch security review, executes tests if available, summarizes what's about to land remote, and pushes only after explicit user confirmation. Refuses to push to main/master without an extra confirmation.
---

# /safe-push — Reviewed push

You are Claude. The user is about to push commits to a remote. Your job is to make sure nothing dangerous goes out.

## Phase 1 — Inspect what's about to be pushed

Run, in order:

```bash
git rev-parse --abbrev-ref HEAD       # current branch
git rev-parse --abbrev-ref @{upstream} 2>/dev/null || echo "no upstream"
git log --oneline @{upstream}..HEAD 2>/dev/null || git log --oneline -10
git diff --stat @{upstream}..HEAD 2>/dev/null
```

Present:

```
BRANCH: <current branch>
UPSTREAM: <upstream branch or "none">
COMMITS TO PUSH: <count>

<list commits>

DIFF STAT:
<file change summary>
```

If there are 0 commits to push, tell the user: "Branch is up to date with upstream. Nothing to push." Stop.

## Phase 2 — Branch protection check

If the current branch is `main` or `master`, ask **explicitly**:

> "⚠️ You're about to push directly to `<branch>`. This bypasses PR review. Are you sure? (yes/no)"

If user says yes, proceed but note: "Pushing to main without PR — logged for awareness."

If they say no, stop and suggest: "Create a feature branch with `git checkout -b feat/<name>` and re-stage from there."

For any other branch, proceed.

## Phase 3 — Full-branch security review

Use the built-in `security-review` skill against the full diff of the branch (vs upstream). Same checklist as `/safe-commit` but over ALL commits being pushed, not just the most recent.

Pay extra attention to:

- Files staged then removed across commits — sometimes secrets leak then "deleted" but remain in history
- Test files that were modified — were they made to pass artificially?
- Migration files — are they reversible?
- Config files (`vercel.json`, `next.config.ts`, env vars in workflows)

Present findings in same format as `/safe-commit`. Same rule: blockers stop the push.

## Phase 4 — Tests (if available)

Detect the test setup:

```bash
# Check package.json for a test script
jq -r '.scripts.test // empty' package.json 2>/dev/null
# Check for common test runners
ls -la jest.config* vitest.config* playwright.config* 2>/dev/null
```

If a `test` script exists, ask: "Run tests before push? (recommended, but slow if it's E2E)"

If user says yes, run:

```bash
npm test  # or whatever the script is
```

If tests fail, stop and surface failures. Don't push failing tests.

If user says skip, log: "Tests skipped at user request."

## Phase 5 — Summary

Output:

```
READY TO PUSH
Branch: <branch> → <upstream>
Commits: <count>
Files changed: <count>
Security review: <pass/warnings/blockers>
Tests: <passed/skipped/failed>

Will run: git push <remote> <branch>
```

Ask: "Proceed with push? (yes/no)"

If yes:

```bash
git push origin "$(git rev-parse --abbrev-ref HEAD)"
```

**Never use `--force` or `--no-verify`** unless the user explicitly requested it AND you've warned them about the consequences.

## Phase 6 — Confirmation

After push succeeds:

```bash
git rev-parse HEAD
git log --oneline -3
```

Tell the user the commit landed remote. If the project has a CI integration (`.github/workflows/`), remind them: "CI will pick this up shortly — watch for Vercel/Actions/etc."

## What NOT to do

- Don't push to main/master without the explicit confirmation in Phase 2.
- Don't bypass hooks (`--no-verify`) or force-push (`--force`, `-f`) unless explicitly authorized.
- Don't push if tests failed and the user didn't explicitly accept that risk.
- Don't push if security blockers exist.
- Don't open the PR. That's a separate, explicit action.
- Don't auto-merge. Ever.
