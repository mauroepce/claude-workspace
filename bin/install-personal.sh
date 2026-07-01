#!/usr/bin/env bash
# Install Mauricio's personal slash commands + templates into ~/.claude/
# These are USER-LEVEL — available in any project, regardless of team config.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/mauroepce/claude-workspace/main/bin/install-personal.sh | bash
#
# What gets installed:
#
# Slash commands (~/.claude/commands/):
#   /work         — spec → generate → review → iterate framework
#   /quick-work   — lite /work for small tasks (single-file edits, fixes)
#   /todo         — persistent task tracking with milestones
#   /issue <N>    — pull GitHub issue, structure context, hand off to /work
#   /debug        — hypothesis-driven debugging, root cause over symptom
#   /conventions  — scan codebase for style/patterns (persists to file)
#   /architecture — scan codebase structure (persists to architecture-map.md)
#   /journeys     — detect user flows, Mermaid sequence diagrams
#   /decision     — capture technical decision with confidence level
#   /code-review  — quality review of staged or specified changes
#   /safe-commit  — /code-review + /security-review + commit with confirmation
#   /safe-push    — full-branch review + push (refuses main without OK)
#   /scaffold     — pick a template and insert it adapted to current context
#   /onboard      — joining a new codebase: runs conventions + architecture + journeys
#   /commands     — list all installed personal commands with descriptions
#
# Templates (~/.claude/templates/):
#   backend/      express-endpoint, nest-controller, next-api-route
#   frontend/     next-page, react-form
#   utils/        async-retry, result-type, zod-helpers
#   tests/        vitest-setup
#
# Existing files with the same names are backed up to *.bak before being replaced.
# Stale renamed files (architecture-map.md, journeys-diagram.md) are removed automatically.

set -euo pipefail

REPO="mauroepce/claude-workspace"
BRANCH="main"
RAW="https://raw.githubusercontent.com/${REPO}/${BRANCH}"

PERSONAL_COMMANDS=(
  "work"
  "quick-work"
  "todo"
  "issue"
  "debug"
  "conventions"
  "architecture"
  "journeys"
  "decision"
  "code-review"
  "safe-commit"
  "safe-push"
  "scaffold"
  "onboard"
  "isolate"
  "commands"
)

# Stale command files from previous versions — remove on install to avoid confusion.
STALE_COMMANDS=(
  "architecture-map"
  "journeys-diagram"
)

TEMPLATES=(
  "README.md"
  "backend/express-endpoint.ts"
  "backend/nest-controller.ts"
  "backend/next-api-route.ts"
  "frontend/next-page.tsx"
  "frontend/react-form.tsx"
  "utils/async-retry.ts"
  "utils/result-type.ts"
  "utils/zod-helpers.ts"
  "tests/vitest-setup.ts"
)

COMMANDS_DIR="$HOME/.claude/commands"
TEMPLATES_DIR="$HOME/.claude/templates"

echo ""
echo "→ Installing slash commands to: $COMMANDS_DIR"
echo "→ Installing templates to:      $TEMPLATES_DIR"
echo ""

mkdir -p "$COMMANDS_DIR" "$TEMPLATES_DIR"

count_installed=0
count_backed_up=0
count_failed=0
count_removed=0

install_file() {
  local src_url="$1"
  local dest_path="$2"
  local label="$3"

  if [ -f "$dest_path" ]; then
    mv "$dest_path" "${dest_path}.bak"
    echo "  ⚠ ${label} existed → backed up to *.bak"
    count_backed_up=$((count_backed_up + 1))
  fi

  mkdir -p "$(dirname "$dest_path")"

  if curl -fsSL "$src_url" -o "$dest_path"; then
    echo "  ✓ ${label}"
    count_installed=$((count_installed + 1))
  else
    echo "  ✗ Failed to download ${label}"
    count_failed=$((count_failed + 1))
  fi
}

# Remove stale (renamed) commands
echo "Cleaning up renamed commands:"
for stale in "${STALE_COMMANDS[@]}"; do
  stale_path="${COMMANDS_DIR}/${stale}.md"
  if [ -f "$stale_path" ]; then
    rm "$stale_path"
    echo "  ✗ /${stale} (renamed, removed)"
    count_removed=$((count_removed + 1))
  fi
done

echo ""
echo "Slash commands:"
for cmd in "${PERSONAL_COMMANDS[@]}"; do
  install_file "${RAW}/personal-commands/${cmd}.md" "${COMMANDS_DIR}/${cmd}.md" "/${cmd}"
done

echo ""
echo "Templates:"
for tpl in "${TEMPLATES[@]}"; do
  install_file "${RAW}/templates/${tpl}" "${TEMPLATES_DIR}/${tpl}" "templates/${tpl}"
done

echo ""
if [ $count_failed -eq 0 ]; then
  echo "✅ ${count_installed} files installed, ${count_backed_up} backed up, ${count_removed} stale removed"
else
  echo "⚠️  ${count_installed} installed, ${count_backed_up} backed up, ${count_failed} failed, ${count_removed} stale removed"
  exit 1
fi

echo ""
echo "Available now in ANY Claude Code session, any project:"
echo ""
echo "  /work         — spec-first task framework"
echo "  /quick-work   — lite /work for small tasks"
echo "  /todo         — persistent task tracking (cross-session)"
echo "  /issue <num>  — pull a GitHub issue and structure its context"
echo "  /debug        — hypothesis-driven debugging"
echo "  /conventions  — scan codebase for style conventions"
echo "  /architecture — scan codebase structure"
echo "  /journeys     — Mermaid sequence diagrams of user flows"
echo "  /decision     — capture a technical decision with confidence"
echo "  /code-review  — quality review of staged changes"
echo "  /safe-commit  — runs /code-review + /security-review + commit"
echo "  /safe-push    — branch review + push (blocks main without OK)"
echo "  /scaffold     — pick a template and insert it"
echo "  /onboard      — joining a new codebase (conventions + architecture + journeys)"
echo "  /isolate      — clean workspace for tests/interviews (prevents context bleed)"
echo "  /commands     — list installed personal commands"
echo ""
echo "Templates browseable: ls ~/.claude/templates/"
echo ""
echo "To update: re-run this script."
echo "To uninstall: rm -rf ~/.claude/commands/{work,quick-work,todo,issue,debug,conventions,architecture,journeys,decision,code-review,safe-commit,safe-push,scaffold,onboard,isolate,commands}.md ~/.claude/templates/"
echo ""
