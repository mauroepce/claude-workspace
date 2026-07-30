#!/usr/bin/env bash
# commit-gate.sh — deterministic review gate for git commits.
#
# Registered as a Claude Code PreToolUse hook (matcher: Bash) by
# bin/install-hooks.sh. The harness runs this script BEFORE executing any Bash
# tool call. If the call is a `git commit`, the gate verifies that a review
# receipt exists and covers the EXACT staged diff about to be committed:
#
#   .claude/review-passed   (at the repo root of the project being committed)
#     line 1: `git diff --cached | git hash-object --stdin` at review time
#     line 2: UTC timestamp (informational)
#
# /code-review writes that receipt as its final phase. If the receipt is
# missing, or the staged diff changed after the review, the commit is blocked
# (exit 2) and the error message is fed back to Claude so it can run the
# review instead of committing blind.
#
# Design decisions:
# - Fail-open: anything unexpected (no jq, not a git repo, nothing staged,
#   unparseable input) allows the commit. The gate defends against FORGETTING
#   review, not against an adversary with shell access.
# - Diff hashing uses `git hash-object` (always present where git is) instead
#   of shasum/sha256sum (platform-dependent).
# - Human escape hatch: prefix the command with SKIP_REVIEW_GATE=1.

set -uo pipefail

input=$(cat)

# jq is required to parse the hook payload. Without it, fail open (warn only).
if ! command -v jq >/dev/null 2>&1; then
  echo "commit-gate: jq not installed, gate skipped" >&2
  exit 0
fi

cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
[ -n "$cmd" ] || exit 0

# Only gate git commit invocations.
case "$cmd" in
  *"git commit"*) ;;
  *) exit 0 ;;
esac

# Human escape hatch (documented in FRAMEWORK.md): SKIP_REVIEW_GATE=1 git commit ...
case "$cmd" in
  *SKIP_REVIEW_GATE=1*) exit 0 ;;
esac

# Evaluate in the directory the tool call runs in.
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
if [ -n "$cwd" ] && [ -d "$cwd" ]; then
  cd "$cwd" 2>/dev/null || exit 0
fi

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0

staged_hash=$(git diff --cached | git hash-object --stdin 2>/dev/null) || exit 0
empty_hash=$(printf '' | git hash-object --stdin)

# Nothing staged: message-only --amend, or a commit that fails on its own.
[ "$staged_hash" = "$empty_hash" ] && exit 0

receipt="${repo_root}/.claude/review-passed"

if [ ! -f "$receipt" ]; then
  echo "COMMIT GATE: no review receipt found (.claude/review-passed)." >&2
  echo "Run /code-review on the staged changes first — it writes the receipt when the review passes." >&2
  echo "Human override for emergencies: SKIP_REVIEW_GATE=1 git commit ..." >&2
  exit 2
fi

reviewed_hash=$(head -1 "$receipt" | tr -d '[:space:]')

if [ "$staged_hash" != "$reviewed_hash" ]; then
  echo "COMMIT GATE: staged changes differ from the last reviewed diff." >&2
  echo "The receipt in .claude/review-passed covers a different staged state." >&2
  echo "Re-run /code-review so the review matches exactly what is about to be committed." >&2
  exit 2
fi

exit 0
