#!/usr/bin/env bash
# Apply trust-boundary defenses to ~/.claude/settings.json.
#
# Idempotent: safe to run multiple times. Backs up existing settings before
# any change. Uses jq to merge — does NOT overwrite unrelated fields.
#
# What this applies:
#   1. askUserQuestionTimeout: "never" (explicit, defends against future default changes)
#   2. env.CLAUDE_AFK_TIMEOUT_MS: "9999999999" (belt-and-suspenders — env overrides config)
#   3. env.DISABLE_AUTOUPDATER: "1" (user controls when to update, no surprise version bumps)
#
# Why these? See docs/FRAMEWORK.md § "Trust boundaries with Claude Code as a dependency"
# and https://www.olafalders.com/2026/07/17/claude-code-anatomy-of-a-misfeature/
#
# Usage:
#   bin/apply-trust-defenses.sh [--yes]
#
# Flags:
#   --yes    Skip confirmation prompt (for CI or scripted install)
#
# Exit codes:
#   0 — defenses applied (or already in place)
#   1 — user declined or jq not installed
#   2 — write error

set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"

AUTO_YES=0
if [ "${1:-}" = "--yes" ] || [ "${1:-}" = "-y" ]; then
  AUTO_YES=1
fi

# ─── Colors ──────────────────────────────────────────────────────────────────
if [ -t 1 ]; then
  RED=$'\033[0;31m'
  YELLOW=$'\033[0;33m'
  GREEN=$'\033[0;32m'
  BLUE=$'\033[0;34m'
  BOLD=$'\033[1m'
  RESET=$'\033[0m'
else
  RED="" YELLOW="" GREEN="" BLUE="" BOLD="" RESET=""
fi

# ─── Preflight ───────────────────────────────────────────────────────────────
if ! command -v jq >/dev/null 2>&1; then
  echo "${RED}✗ jq is required but not installed.${RESET}" >&2
  echo "  Install: brew install jq   (or: apt install jq / yum install jq)" >&2
  exit 1
fi

mkdir -p "$CLAUDE_DIR"

echo ""
echo "${BOLD}→ Applying trust-boundary defenses to Claude Code${RESET}"
echo ""

# ─── Prepare the defense values ──────────────────────────────────────────────
# askUserQuestionTimeout: "never" prevents auto-continue on AskUserQuestion.
# CLAUDE_AFK_TIMEOUT_MS: env var override (redundant with config, defends against
#   future silent default changes).
# DISABLE_AUTOUPDATER: user controls version transitions.
DEFENSE_JSON='{
  "askUserQuestionTimeout": "never",
  "env": {
    "CLAUDE_AFK_TIMEOUT_MS": "9999999999",
    "DISABLE_AUTOUPDATER": "1"
  }
}'

# ─── Read current state, compute diff ────────────────────────────────────────
if [ -f "$SETTINGS_FILE" ]; then
  # Validate that it's valid JSON first
  if ! jq empty "$SETTINGS_FILE" 2>/dev/null; then
    echo "${RED}✗ $SETTINGS_FILE exists but is not valid JSON.${RESET}" >&2
    echo "  Cannot safely merge. Fix the file first or move it aside." >&2
    exit 2
  fi
  current_json=$(cat "$SETTINGS_FILE")
else
  echo "  ${BLUE}→${RESET} $SETTINGS_FILE does not exist. Will create it with defense settings."
  current_json='{}'
fi

# Merge defense into current (defense wins for the fields it defines).
# jq's * operator does a recursive merge with the right-hand side winning.
merged=$(echo "$current_json" | jq --argjson defense "$DEFENSE_JSON" '. * $defense')

# Check if anything actually changed
current_normalized=$(echo "$current_json" | jq -S '.')
merged_normalized=$(echo "$merged" | jq -S '.')

if [ "$current_normalized" = "$merged_normalized" ]; then
  echo "${GREEN}✓${RESET} All defenses already in place. No changes needed."
  echo ""
  exit 0
fi

# ─── Show the user what will change ──────────────────────────────────────────
echo "${BOLD}Changes to $SETTINGS_FILE:${RESET}"
echo ""
echo "  ${BOLD}Field${RESET}                        ${BOLD}Current${RESET}          ${BOLD}After apply${RESET}"
echo "  ────────────────────────────────────────────────────────────────"

current_timeout=$(echo "$current_json" | jq -r '.askUserQuestionTimeout // "unset"')
current_afk=$(echo "$current_json" | jq -r '.env.CLAUDE_AFK_TIMEOUT_MS // "unset"')
current_upd=$(echo "$current_json" | jq -r '.env.DISABLE_AUTOUPDATER // "unset"')

new_timeout=$(echo "$merged" | jq -r '.askUserQuestionTimeout')
new_afk=$(echo "$merged" | jq -r '.env.CLAUDE_AFK_TIMEOUT_MS')
new_upd=$(echo "$merged" | jq -r '.env.DISABLE_AUTOUPDATER')

printf "  %-28s %-16s %s\n" "askUserQuestionTimeout" "$current_timeout" "$new_timeout"
printf "  %-28s %-16s %s\n" "env.CLAUDE_AFK_TIMEOUT_MS" "$current_afk" "$new_afk"
printf "  %-28s %-16s %s\n" "env.DISABLE_AUTOUPDATER" "$current_upd" "$new_upd"
echo ""

# ─── Confirm ─────────────────────────────────────────────────────────────────
if [ $AUTO_YES -ne 1 ]; then
  read -r -p "Apply these changes? (y/N) " reply < /dev/tty || reply="n"
  case "$reply" in
    [yY]|[yY][eE][sS])
      ;;
    *)
      echo "${YELLOW}Cancelled by user. No changes made.${RESET}"
      exit 1
      ;;
  esac
fi

# ─── Backup and write ────────────────────────────────────────────────────────
if [ -f "$SETTINGS_FILE" ]; then
  timestamp=$(date -u +"%Y%m%dT%H%M%SZ")
  backup="${SETTINGS_FILE}.backup-${timestamp}"
  cp "$SETTINGS_FILE" "$backup"
  echo "  ${BLUE}→${RESET} Backed up existing settings to $(basename "$backup")"
fi

# Write with pretty formatting for human readability
echo "$merged" | jq -S '.' > "$SETTINGS_FILE"

echo "  ${GREEN}✓${RESET} Wrote updated settings to $SETTINGS_FILE"
echo ""

echo "${BOLD}Applied defenses:${RESET}"
echo "  ${GREEN}✓${RESET} askUserQuestionTimeout: 'never' (config-level, survives version updates)"
echo "  ${GREEN}✓${RESET} CLAUDE_AFK_TIMEOUT_MS: 9999999999 (env-level, overrides config if platform changes)"
echo "  ${GREEN}✓${RESET} DISABLE_AUTOUPDATER: 1 (no surprise version bumps mid-session)"
echo ""

echo "${BOLD}Next step:${RESET} restart your Claude Code session for the env vars to take effect."
echo ""
echo "To verify: run ${BOLD}bin/verify-claude-config.sh${RESET} in a new terminal."
echo ""

exit 0
