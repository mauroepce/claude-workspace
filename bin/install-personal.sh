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
#   /issue <N>    — pull GitHub issue, structure context, hand off to /work
#   /debug        — hypothesis-driven debugging, root cause over symptom
#   /conventions  — scan unfamiliar codebase for its conventions
#   /code-review  — quality review of staged or specified changes
#   /safe-commit  — /code-review + /security-review + commit with confirmation
#   /safe-push    — full-branch review + push (refuses main without OK)
#   /scaffold     — pick a template and insert it adapted to current context
#
# Templates (~/.claude/templates/):
#   backend/      express-endpoint, nest-controller, next-api-route
#   frontend/     next-page, react-form
#   utils/        async-retry, result-type, zod-helpers
#   tests/        vitest-setup
#
# Existing files with the same names are backed up to *.bak before being replaced.

set -euo pipefail

REPO="mauroepce/claude-workspace"
BRANCH="main"
RAW="https://raw.githubusercontent.com/${REPO}/${BRANCH}"

PERSONAL_COMMANDS=(
  "work"
  "todo"
  "issue"
  "debug"
  "conventions"
  "architecture-map"
  "journeys-diagram"
  "decision"
  "code-review"
  "safe-commit"
  "safe-push"
  "scaffold"
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
  echo "✅ ${count_installed} files installed, ${count_backed_up} backed up"
else
  echo "⚠️  ${count_installed} installed, ${count_backed_up} backed up, ${count_failed} failed"
  exit 1
fi

echo ""
echo "Available now in ANY Claude Code session, any project:"
echo ""
echo "  /work             — spec-first task framework"
echo "  /todo             — persistent tasks with milestones (cross-session)"
echo "  /issue <num>      — pull a GitHub issue and structure its context"
echo "  /debug            — hypothesis-driven debugging"
echo "  /conventions      — scan codebase for style conventions (persists to file)"
echo "  /architecture-map — produce a structured map of the entire codebase"
echo "  /journeys-diagram — produce Mermaid sequence diagrams of main user flows"
echo "  /decision         — capture a technical decision (decision/alt/why/confidence)"
echo "  /code-review      — quality review of staged changes"
echo "  /safe-commit      — runs /code-review + /security-review + commit with confirmation"
echo "  /safe-push        — branch review + push (blocks main without OK)"
echo "  /scaffold         — pick a template from ~/.claude/templates/ and insert it"
echo ""
echo "Templates browseable: ls ~/.claude/templates/"
echo ""
echo "To update: re-run this script."
echo "To uninstall: rm -rf ~/.claude/commands/{work,todo,issue,debug,conventions,architecture-map,journeys-diagram,decision,code-review,safe-commit,safe-push,scaffold}.md ~/.claude/templates/"
echo ""
