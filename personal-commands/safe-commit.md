---
description: Run a security review on staged changes, generate a commit message tied to the original spec from /work, and commit only after explicit user confirmation. Never bypasses hooks.
---

# /safe-commit — Reviewed commit

You are Claude. The user is about to commit staged changes. Your job is to make this commit safe and intentional, not autopilot.

## Phase 1 — Inspect what's staged

Run:

```bash
git status --short
git diff --cached --stat
```

If nothing is staged, tell the user: "No staged changes. Run `git add <files>` first, then `/safe-commit` again." Stop.

If there are staged changes, present:

```
STAGED CHANGES
Files: <count>
Lines: +<added> / -<removed>

<list of files with their diff stat>
```

## Phase 2 — Code review (quality and correctness)

Invoke `/code-review` against the staged changes. This is the quality pass: naming, complexity, pattern adherence, test coverage, edge cases, error handling, performance traps.

Present the standard `/code-review` output (must-fix / should-fix / nice-to-have / strengths).

**Decision tree:**

- If **must-fix** findings exist: stop and tell the user "There are must-fix findings. Address them, re-stage, and run `/safe-commit` again. I'm not going to commit code that wouldn't pass PR review."
- If **should-fix** only: ask "Want to address these now or note them for follow-up?"
- If **nice-to-have** or **clean**: proceed to Phase 3.

## Phase 3 — Security review

Invoke `/security-review` against the staged diff (built-in Claude Code skill). This is a separate concern from quality — it looks specifically for threat patterns: hardcoded secrets, injection, auth/permission changes, unverified inputs, leaked PII, etc.

If `/security-review` isn't available or fails, fall back to manually scanning for:

- Hardcoded secrets (API keys, tokens, passwords) — match patterns like `sk-`, `Bearer `, `AKIA`, `xoxb-`, `ghp_`, `password = "..."`
- New env vars referenced without being added to `.env.example`
- Suspicious changes to authentication, authorization, or permissions code
- New external HTTP calls without timeouts or error handling
- SQL queries built with string concatenation (potential injection)
- Disabled tests or skipped assertions
- `.env`, `.pem`, `id_rsa`, or any other obvious secret file accidentally added

Present findings in this format:

```
SECURITY REVIEW
✓ <N> checks passed
⚠ <N> warnings:
  - <warning 1 with file:line>
✗ <N> blockers (if any):
  - <blocker 1 with file:line>
```

Same decision tree as Phase 2: blockers stop the commit, warnings prompt the user.

## Phase 4 — Verify spec alignment (if /work was used)

If the user followed `/work` for this task, ask: "Briefly — does this commit deliver the spec from `/work` Phase 1?"

If they say no, suggest splitting the commit (use `git reset` and re-stage) so each commit maps to one spec.

If they didn't use `/work`, skip this phase. Don't lecture them.

## Phase 5 — Commit message

Generate a commit message that follows this structure:

```
<type>: <subject in imperative mood, max 72 chars>

<2-4 sentence body explaining the WHY, not just the what>
<reference issue if applicable: "Refs #47" or "Closes #47">
```

Types: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `perf`, `style`.

The body should answer: **why was this change necessary?** Not "I changed X to Y" but "X was failing under condition Z because of constraint W; Y handles it correctly."

Show the user the message and ask: "Commit with this message?"

If they revise, regenerate. If they approve, run:

```bash
git commit -m "<subject>" -m "<body>"
```

**Never use `--no-verify`.** If a hook fails, surface the failure and ask the user how to handle it. Don't bypass hooks.

## Phase 6 — Confirmation

After commit succeeds:

```bash
git log --oneline -1
git status
```

Confirm the commit landed, working tree state is what the user expected. Don't push — that's `/safe-push`.

## What NOT to do

- Don't add `Co-Authored-By: Claude` unless the repo explicitly opts in via its own CLAUDE.md.
- Don't bypass git hooks with `--no-verify` for any reason.
- Don't commit if blockers exist.
- Don't generate a generic message ("update files", "minor changes"). If you can't articulate the why, ask the user.
- Don't auto-amend. If the user wants to amend, they ask explicitly.
- Don't push.
