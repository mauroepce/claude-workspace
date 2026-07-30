#!/usr/bin/env bash
# Install Mauricio's personal skills + templates into ~/.claude/
# These are USER-LEVEL — available in any project, regardless of team config.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/mauroepce/claude-workspace/main/bin/install-personal.sh | bash
#
# What gets installed:
#
# Skills (~/.claude/skills/<name>/SKILL.md). Each one is invokable manually as
# /<name> (same as the old slash commands) AND auto-invocable: Claude reads the
# description and activates the skill when the task matches, without being asked.
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
# Legacy slash-command files (~/.claude/commands/<name>.md) from pre-skills
# versions are removed automatically — the skill replaces them 1:1.

set -euo pipefail

REPO="mauroepce/claude-workspace"
BRANCH="main"
RAW="https://raw.githubusercontent.com/${REPO}/${BRANCH}"

PERSONAL_SKILLS=(
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

# Subagents: separate Claude instances with their own context and restricted
# tools. code-reviewer has NO write tools — structural separation of powers.
AGENTS=(
  "code-reviewer"
)

COMMANDS_DIR="$HOME/.claude/commands"
SKILLS_DIR="$HOME/.claude/skills"
TEMPLATES_DIR="$HOME/.claude/templates"
AGENTS_DIR="$HOME/.claude/agents"

echo ""
echo "→ Installing skills to:    $SKILLS_DIR"
echo "→ Installing templates to: $TEMPLATES_DIR"
echo "→ Installing agents to:    $AGENTS_DIR"
echo ""

mkdir -p "$SKILLS_DIR" "$TEMPLATES_DIR" "$AGENTS_DIR"

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

# Remove stale (renamed) commands + legacy slash-command files replaced by skills
echo "Cleaning up legacy command files:"
for stale in "${STALE_COMMANDS[@]}"; do
  stale_path="${COMMANDS_DIR}/${stale}.md"
  if [ -f "$stale_path" ]; then
    rm "$stale_path"
    echo "  ✗ /${stale} (renamed, removed)"
    count_removed=$((count_removed + 1))
  fi
done
for skill in "${PERSONAL_SKILLS[@]}"; do
  legacy_path="${COMMANDS_DIR}/${skill}.md"
  if [ -f "$legacy_path" ]; then
    rm "$legacy_path"
    echo "  ✗ /${skill} (legacy command file — replaced by the skill)"
    count_removed=$((count_removed + 1))
  fi
done

echo ""
echo "Skills:"
for skill in "${PERSONAL_SKILLS[@]}"; do
  install_file "${RAW}/skills/${skill}/SKILL.md" "${SKILLS_DIR}/${skill}/SKILL.md" "/${skill}"
done

echo ""
echo "Templates:"
for tpl in "${TEMPLATES[@]}"; do
  install_file "${RAW}/templates/${tpl}" "${TEMPLATES_DIR}/${tpl}" "templates/${tpl}"
done

echo ""
echo "Agents:"
for agent in "${AGENTS[@]}"; do
  install_file "${RAW}/agents/${agent}.md" "${AGENTS_DIR}/${agent}.md" "agent:${agent}"
done

echo ""
if [ $count_failed -eq 0 ]; then
  echo "✅ ${count_installed} files installed, ${count_backed_up} backed up, ${count_removed} stale removed"
else
  echo "⚠️  ${count_installed} installed, ${count_backed_up} backed up, ${count_failed} failed, ${count_removed} stale removed"
  exit 1
fi

echo ""
echo "Available now in ANY Claude Code session, any project."
echo "Each skill works two ways: invoke it manually (/name), or let Claude"
echo "auto-activate it when your request matches its description."
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
echo "Subagents installed (~/.claude/agents/):"
echo "  code-reviewer — clean-context reviewer with NO write tools;"
echo "  /code-review delegates to it when available"
echo ""

# ─── Offer to apply trust-boundary defenses ──────────────────────────────────
# The framework's slash commands (/work, /safe-commit, /safe-push, /debug) rely
# on Claude Code's AskUserQuestion tool blocking indefinitely for user input.
# Claude Code v2.1.198-199 broke that assumption silently. To defend against
# future silent changes, apply explicit config + env var overrides.
# See docs/FRAMEWORK.md § "Trust boundaries with Claude Code as a dependency".

echo "─────────────────────────────────────────────────────────────────────────"
echo "Optional: apply trust-boundary defenses to ~/.claude/settings.json"
echo ""
echo "The framework's confirmation gates (/work, /safe-commit, /safe-push, /debug)"
echo "assume AskUserQuestion blocks until you respond. This applies explicit"
echo "config to defend against silent changes in Claude Code's default behavior."
echo ""
echo "Changes: askUserQuestionTimeout='never', CLAUDE_AFK_TIMEOUT_MS=huge,"
echo "DISABLE_AUTOUPDATER=1. Backs up existing settings.json first."
echo "─────────────────────────────────────────────────────────────────────────"

# Only prompt if we have a TTY (skip in headless CI installs)
if [ -t 0 ] && [ -t 1 ] && [ -e /dev/tty ]; then
  read -r -p "Apply trust-boundary defenses now? (y/N) " apply_reply < /dev/tty || apply_reply="n"
  case "$apply_reply" in
    [yY]|[yY][eE][sS])
      # Download and run the apply script (idempotent, safe)
      apply_url="${RAW}/bin/apply-trust-defenses.sh"
      tmp_apply="$(mktemp)"
      if curl -fsSL "$apply_url" -o "$tmp_apply"; then
        chmod +x "$tmp_apply"
        "$tmp_apply" --yes
        rm -f "$tmp_apply"
      else
        echo "  ⚠ Failed to download apply-trust-defenses.sh. Skipping."
        echo "  You can run it manually later: bash <(curl -fsSL $apply_url) --yes"
      fi
      ;;
    *)
      echo "  Skipped. Run later with: bash <(curl -fsSL ${RAW}/bin/apply-trust-defenses.sh) --yes"
      ;;
  esac
else
  echo "  (Non-interactive install detected — skipping. Run manually to apply.)"
fi

echo ""
echo "Verify at any time: bash <(curl -fsSL ${RAW}/bin/verify-claude-config.sh)"
echo ""
echo "To update: re-run this script."
echo "To uninstall: rm -rf ~/.claude/skills/{work,quick-work,todo,issue,debug,conventions,architecture,journeys,decision,code-review,safe-commit,safe-push,scaffold,onboard,isolate,commands} ~/.claude/templates/ ~/.claude/agents/code-reviewer.md"
echo ""
