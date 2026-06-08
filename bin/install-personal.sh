#!/usr/bin/env bash
# Install Mauricio's personal slash commands into ~/.claude/commands/
# These are USER-LEVEL commands — available in any project, regardless of team config.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/mauroepce/claude-workspace/main/bin/install-personal.sh | bash
#
# What gets installed:
#   /work         — spec → generate → review → iterate framework
#   /issue <N>    — pull GitHub issue, structure context, hand off to /work
#   /safe-commit  — security review + commit message + confirm before commit
#   /safe-push    — security review + tests + confirm before push (refuses main without explicit OK)
#
# Existing files with the same names are backed up to *.bak before being replaced.

set -euo pipefail

REPO="mauroepce/claude-workspace"
BRANCH="main"
RAW="https://raw.githubusercontent.com/${REPO}/${BRANCH}"

PERSONAL_COMMANDS=(
  "work"
  "issue"
  "debug"
  "safe-commit"
  "safe-push"
)

TARGET_DIR="$HOME/.claude/commands"

echo ""
echo "→ Installing personal slash commands to: $TARGET_DIR"
echo ""

mkdir -p "$TARGET_DIR"

count_installed=0
count_backed_up=0

for cmd in "${PERSONAL_COMMANDS[@]}"; do
  src="${RAW}/personal-commands/${cmd}.md"
  dest="${TARGET_DIR}/${cmd}.md"

  if [ -f "$dest" ]; then
    mv "$dest" "${dest}.bak"
    echo "  ⚠ /${cmd} existed → backed up to ${cmd}.md.bak"
    count_backed_up=$((count_backed_up + 1))
  fi

  if curl -fsSL "$src" -o "$dest"; then
    echo "  ✓ /${cmd}"
    count_installed=$((count_installed + 1))
  else
    echo "  ✗ Failed to download /${cmd}"
    exit 1
  fi
done

echo ""
echo "✅ ${count_installed} commands installed, ${count_backed_up} backed up"
echo ""
echo "Available now in ANY Claude Code session, any project:"
echo ""
echo "  /work          — start a task with the spec-first framework"
echo "  /issue <num>   — pull a GitHub issue and structure its context"
echo "  /debug         — systematic debugging: hypothesis before fix, root cause over symptom"
echo "  /safe-commit   — review staged changes + commit safely"
echo "  /safe-push     — review branch diff + push safely (blocks main without OK)"
echo ""
echo "These are personal — they layer on top of whatever team config exists."
echo "If a project commits its own /work or /safe-commit, the project version wins."
echo ""
echo "To update: re-run this script. To uninstall: rm ~/.claude/commands/{work,issue,debug,safe-commit,safe-push}.md"
echo ""
