#!/usr/bin/env bash
# Verify that Claude Code is configured to preserve framework guarantees.
#
# Background: In Claude Code v2.1.198-199 (July 2026), Anthropic silently
# introduced an "efficiency bypass" that made AskUserQuestion auto-continue
# after 60 seconds. That broke the blocking-confirmation assumption that
# this framework's slash commands rely on (/work, /safe-commit, /safe-push,
# /debug all pause for explicit user confirmation at decision points).
#
# See: https://www.olafalders.com/2026/07/17/claude-code-anatomy-of-a-misfeature/
#
# Anthropic reverted in v2.1.200+ (default is now `never` again), but the
# episode revealed a class of risk: a silent change in the platform can
# silently degrade every safety gate built on top of it. This script
# codifies the defense.
#
# Usage:
#   bin/verify-claude-config.sh
#
# Exit codes:
#   0 — all checks passed
#   1 — warnings only (recommend action, not blocking)
#   2 — critical issues found (framework guarantees are at risk)

set -uo pipefail

SETTINGS_FILE="${HOME}/.claude/settings.json"
SETTINGS_LOCAL_FILE="${HOME}/.claude/settings.local.json"

errors=0
warnings=0
checked=0

# ─── Color helpers (fall back to plain text if not a TTY) ────────────────────
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

pass() { echo "  ${GREEN}✓${RESET} $1"; checked=$((checked + 1)); }
warn() { echo "  ${YELLOW}⚠${RESET} $1"; warnings=$((warnings + 1)); checked=$((checked + 1)); }
fail() { echo "  ${RED}✗${RESET} $1"; errors=$((errors + 1));   checked=$((checked + 1)); }
info() { echo "    ${BLUE}→${RESET} $1"; }

echo ""
echo "${BOLD}→ Verifying Claude Code trust configuration${RESET}"
echo ""

# ─── Check 1: Claude Code version ────────────────────────────────────────────
echo "${BOLD}[1/6] Claude Code version${RESET}"

version=""
# Try the AI_AGENT env var first (VS Code extension exposes it)
if [ -n "${AI_AGENT:-}" ]; then
  # Format: claude-code_2-1-179_agent → 2.1.179
  version=$(echo "$AI_AGENT" | sed -n 's/^claude-code_\([0-9-]*\)_agent$/\1/p' | tr '-' '.')
fi

# Fall back to executable if CLI is installed
if [ -z "$version" ] && command -v claude >/dev/null 2>&1; then
  version=$(claude --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
fi

# Fall back to parsing CLAUDE_CODE_EXECPATH
if [ -z "$version" ] && [ -n "${CLAUDE_CODE_EXECPATH:-}" ]; then
  version=$(echo "$CLAUDE_CODE_EXECPATH" | grep -oE 'claude-code-[0-9]+\.[0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
fi

if [ -z "$version" ]; then
  warn "Could not detect Claude Code version (no CLAUDE_CODE_EXECPATH, AI_AGENT, or claude in PATH)"
  info "Cannot check for known-bad versions. Set the config explicitly (see Check 2)."
else
  # Parse major.minor.patch
  major=$(echo "$version" | cut -d. -f1)
  minor=$(echo "$version" | cut -d. -f2)
  patch=$(echo "$version" | cut -d. -f3)

  # Danger zone: 2.1.198 and 2.1.199 silently auto-continue AskUserQuestion
  if [ "$major" = "2" ] && [ "$minor" = "1" ] && ([ "$patch" = "198" ] || [ "$patch" = "199" ]); then
    fail "Claude Code $version — KNOWN DANGER ZONE"
    info "Versions 2.1.198 and 2.1.199 auto-continue AskUserQuestion after 60s"
    info "This silently breaks /work, /safe-commit, /safe-push, /debug confirmation gates"
    info "Update to 2.1.200+ ASAP, or explicitly set CLAUDE_AFK_TIMEOUT_MS to a huge value"
  elif [ "$major" = "2" ] && [ "$minor" = "1" ] && [ "$patch" -ge 200 ]; then
    pass "Claude Code $version (post-fix — default is 'never' unless overridden)"
    info "Still recommend explicit askUserQuestionTimeout: 'never' in settings.json"
  elif [ "$major" = "2" ] && [ "$minor" = "1" ] && [ "$patch" -lt 198 ]; then
    pass "Claude Code $version (pre-misfeature — the auto-continue bug does not exist in your version)"
    info "When you update, verify you land on 2.1.200+ (skip 198-199) or apply defenses first"
  else
    pass "Claude Code $version"
    info "Version is outside the known danger range. Still recommend explicit config."
  fi
fi

echo ""

# ─── Check 2: askUserQuestionTimeout setting ─────────────────────────────────
echo "${BOLD}[2/6] askUserQuestionTimeout in settings.json${RESET}"

check_setting_file() {
  local file="$1"
  local label="$2"

  if [ ! -f "$file" ]; then
    return 2
  fi

  local timeout_val
  timeout_val=$(jq -r '.askUserQuestionTimeout // "unset"' "$file" 2>/dev/null || echo "invalid-json")

  if [ "$timeout_val" = "invalid-json" ]; then
    fail "$label exists but is not valid JSON"
    return 1
  elif [ "$timeout_val" = "unset" ]; then
    return 2
  elif [ "$timeout_val" = "never" ]; then
    pass "$label sets askUserQuestionTimeout: 'never' explicitly"
    return 0
  else
    fail "$label sets askUserQuestionTimeout: '$timeout_val' (framework requires 'never')"
    info "Change to \"askUserQuestionTimeout\": \"never\" or delete the key entirely"
    return 1
  fi
}

# Local overrides global — check local first, then global
check_setting_file "$SETTINGS_LOCAL_FILE" "settings.local.json"
local_result=$?

check_setting_file "$SETTINGS_FILE" "settings.json"
global_result=$?

if [ $local_result -eq 2 ] && [ $global_result -eq 2 ]; then
  warn "askUserQuestionTimeout is not set explicitly in either settings file"
  info "On Claude Code 2.1.200+, default is 'never' (safe), but explicit is better"
  info "Run bin/apply-trust-defenses.sh to add the recommended settings"
fi

echo ""

# ─── Check 3: CLAUDE_AFK_TIMEOUT_MS env var ──────────────────────────────────
echo "${BOLD}[3/6] CLAUDE_AFK_TIMEOUT_MS env var${RESET}"

if [ -n "${CLAUDE_AFK_TIMEOUT_MS:-}" ]; then
  # Check that it's a very large number (billions of ms = years)
  if [ "$CLAUDE_AFK_TIMEOUT_MS" -ge 999999999 ] 2>/dev/null; then
    pass "CLAUDE_AFK_TIMEOUT_MS=$CLAUDE_AFK_TIMEOUT_MS (huge — effectively never)"
  elif [ "$CLAUDE_AFK_TIMEOUT_MS" -gt 0 ] 2>/dev/null; then
    warn "CLAUDE_AFK_TIMEOUT_MS=$CLAUDE_AFK_TIMEOUT_MS ms (~$((CLAUDE_AFK_TIMEOUT_MS / 1000))s timeout is active)"
    info "This overrides askUserQuestionTimeout config. Set to a huge value to disable."
  else
    fail "CLAUDE_AFK_TIMEOUT_MS='$CLAUDE_AFK_TIMEOUT_MS' is not a valid positive integer"
  fi
else
  warn "CLAUDE_AFK_TIMEOUT_MS is not set (belt-and-suspenders defense missing)"
  info "Recommend adding to settings.json env block. Value: 9999999999 (huge)"
fi

echo ""

# ─── Check 4: DISABLE_AUTOUPDATER env var ────────────────────────────────────
echo "${BOLD}[4/6] DISABLE_AUTOUPDATER env var${RESET}"

if [ -n "${DISABLE_AUTOUPDATER:-}" ] && [ "$DISABLE_AUTOUPDATER" = "1" ]; then
  pass "DISABLE_AUTOUPDATER=1 (Claude Code will not auto-update — you control version bumps)"
else
  warn "DISABLE_AUTOUPDATER is not set to '1'"
  info "Without this, Claude Code may auto-update through danger versions during your session"
  info "Recommend setting DISABLE_AUTOUPDATER=1 for control over version transitions"
fi

echo ""

# ─── Check 5: Framework commands are installed ───────────────────────────────
echo "${BOLD}[5/6] Framework commands${RESET}"

if [ -d "${HOME}/.claude/commands" ]; then
  cmd_count=$(find "${HOME}/.claude/commands" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$cmd_count" -ge 15 ]; then
    pass "$cmd_count personal commands installed at ~/.claude/commands/"
  elif [ "$cmd_count" -gt 0 ]; then
    warn "$cmd_count personal commands installed (expected 16+)"
    info "Some commands may be missing. Re-run bin/install-personal.sh."
  else
    fail "No personal commands found at ~/.claude/commands/"
    info "Run: curl -fsSL https://raw.githubusercontent.com/mauroepce/claude-workspace/main/bin/install-personal.sh | bash"
  fi
else
  fail "~/.claude/commands/ directory does not exist"
  info "Run: curl -fsSL https://raw.githubusercontent.com/mauroepce/claude-workspace/main/bin/install-personal.sh | bash"
fi

echo ""

# ─── Check 6: Templates are installed ────────────────────────────────────────
echo "${BOLD}[6/6] Framework templates${RESET}"

if [ -d "${HOME}/.claude/templates" ]; then
  tpl_count=$(find "${HOME}/.claude/templates" -type f \( -name "*.ts" -o -name "*.tsx" \) 2>/dev/null | wc -l | tr -d ' ')
  if [ "$tpl_count" -ge 9 ]; then
    pass "$tpl_count code templates installed at ~/.claude/templates/"
  elif [ "$tpl_count" -gt 0 ]; then
    warn "$tpl_count code templates installed (expected 9+)"
    info "Some templates may be missing. Re-run bin/install-personal.sh."
  else
    fail "Templates directory exists but is empty"
  fi
else
  warn "~/.claude/templates/ directory does not exist (templates missing)"
  info "Run: curl -fsSL https://raw.githubusercontent.com/mauroepce/claude-workspace/main/bin/install-personal.sh | bash"
fi

echo ""

# ─── Summary ─────────────────────────────────────────────────────────────────
echo "${BOLD}Summary${RESET}"
echo "  Checked: $checked"
echo "  ${GREEN}Passed:${RESET} $((checked - errors - warnings))"
echo "  ${YELLOW}Warnings:${RESET} $warnings"
echo "  ${RED}Errors:${RESET} $errors"
echo ""

if [ $errors -gt 0 ]; then
  echo "${RED}${BOLD}Critical issues found.${RESET} Framework safety gates are at risk."
  echo ""
  echo "Recommended action: run ${BOLD}bin/apply-trust-defenses.sh${RESET} to apply recommended config."
  exit 2
elif [ $warnings -gt 0 ]; then
  echo "${YELLOW}${BOLD}Warnings only.${RESET} Framework works but is missing belt-and-suspenders defenses."
  echo ""
  echo "Recommended action: run ${BOLD}bin/apply-trust-defenses.sh${RESET} to strengthen configuration."
  exit 1
else
  echo "${GREEN}${BOLD}All checks passed.${RESET} Framework safety gates are protected."
  exit 0
fi
