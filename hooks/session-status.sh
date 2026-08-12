#!/usr/bin/env bash
# session-status.sh — surface the focused /todo task at session start.
#
# Registered as a Claude Code SessionStart hook by bin/install-hooks.sh (and
# pre-wired for plugin installs in hooks/hooks.json). The harness runs this
# script when a session starts (startup / resume / clear); anything printed to
# stdout is added to Claude's context before the first user message.
#
# What it does: if the project has a persistent todos file (written by the
# /todo skill), print the [FOCUSED] task, its progress, and the next unchecked
# milestone. This turns /todo from pull (you remember to run `/todo list`)
# into push (the session opens already knowing where you were) — the same move
# the commit gate made for reviews: a prompt is a request the model can miss;
# a hook is code the harness always runs.
#
# Design decisions:
# - Fail-open and silent: no todos file, no [FOCUSED] task, unparseable
#   payload — print nothing, exit 0. This hook must never break or noise up
#   a session start.
# - Pure bash + awk for the parsing. jq is only used to read the payload's
#   cwd and degrades gracefully when missing (falls back to the hook's own
#   working directory, which the harness sets to the project dir anyway).
# - Read-only: this hook never writes anything. State changes belong to the
#   /todo skill in-session.

set -uo pipefail

input=$(cat 2>/dev/null) || input=""

# Prefer the payload cwd (works even if the harness launches hooks elsewhere).
if command -v jq >/dev/null 2>&1 && [ -n "$input" ]; then
  cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
  if [ -n "$cwd" ] && [ -d "$cwd" ]; then
    cd "$cwd" 2>/dev/null || exit 0
  fi
fi

# Same lookup order as the /todo skill's Phase 1.
todos=""
for candidate in .claude/todos.md .claude/todos.local.md TODOS.md; do
  if [ -f "$candidate" ]; then
    todos="$candidate"
    break
  fi
done
[ -n "$todos" ] || exit 0

awk -v file="$todos" '
  /^## .*\[FOCUSED\]/ {
    # Single [FOCUSED] task is a convention, not a guarantee. If a hand-edit
    # leaves two, reset all state so the output reflects the LAST block only —
    # never a chimera of both.
    infocus = 1
    done = 0; open = 0; next_ms = ""; meta = ""
    title = $0
    sub(/^## +/, "", title)
    sub(/ *\[FOCUSED\] *$/, "", title)
    next
  }
  infocus && /^## / { infocus = 0 }
  infocus && /^\*Started:/ { meta = $0 }
  infocus && /^- \[x\]/ { done++ }
  infocus && /^- \[ \]/ {
    open++
    if (next_ms == "") {
      next_ms = $0
      sub(/^- \[ \] +/, "", next_ms)
    }
  }
  END {
    if (title == "") exit 0
    total = done + open
    printf "[claude-workspace /todo] Focused task: %s\n", title
    if (total > 0) printf "Progress: %d/%d milestones done.", done, total
    if (next_ms != "") printf " Next: %s", next_ms
    if (total > 0 || next_ms != "") printf "\n"
    if (meta != "") { gsub(/^\*|\*$/, "", meta); printf "%s\n", meta }
    printf "Full state: %s — manage with /todo (list, done <N>, focus <slug>).\n", file
  }
' "$todos" 2>/dev/null

exit 0
