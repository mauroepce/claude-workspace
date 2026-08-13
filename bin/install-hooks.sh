#!/usr/bin/env bash
# Install the deterministic hooks into ~/.claude/
#
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/mauroepce/claude-workspace/main/bin/install-hooks.sh)
#
# What it does:
#   1. Downloads hooks/commit-gate.sh and hooks/session-status.sh to ~/.claude/hooks/
#   2. Merges the hook entries into ~/.claude/settings.json:
#      - PreToolUse (matcher: Bash) -> commit-gate.sh  (blocks unreviewed commits)
#      - SessionStart               -> session-status.sh (surfaces the focused /todo task)
#
# Idempotent: re-running updates the scripts and leaves settings.json unchanged
# if the entries already exist. The previous settings.json is backed up with a
# timestamped filename before writing (same pattern as apply-trust-defenses.sh).
#
# Why hooks and not prompts: prompts are requests the model can miss; hooks
# are code the harness always runs. See docs/FRAMEWORK.md § Deterministic gates.

set -euo pipefail

REPO="mauroepce/claude-workspace"
BRANCH="main"
RAW="https://raw.githubusercontent.com/${REPO}/${BRANCH}"

HOOKS_DIR="$HOME/.claude/hooks"
SETTINGS="$HOME/.claude/settings.json"

if ! command -v jq >/dev/null 2>&1; then
  echo "✗ jq is required (same dependency as apply-trust-defenses.sh)."
  echo "  Install it (macOS: brew install jq · Debian/Ubuntu: apt install jq) and re-run."
  exit 1
fi

echo ""
echo "→ Installing hooks to: $HOOKS_DIR"
mkdir -p "$HOOKS_DIR"

for hook in commit-gate.sh session-status.sh; do
  # Download to a temp file and mv into place: a mid-transfer failure must not
  # leave a truncated (and, being fail-open, silently inert) hook behind.
  dl="$(mktemp)"
  if curl -fsSL "${RAW}/hooks/${hook}" -o "$dl"; then
    chmod +x "$dl"
    mv "$dl" "${HOOKS_DIR}/${hook}"
    echo "  ✓ hooks/${hook}"
  else
    rm -f "$dl"
    echo "  ✗ Failed to download ${hook}"
    exit 1
  fi
done

# Ensure settings.json exists and is valid JSON before merging.
if [ ! -f "$SETTINGS" ]; then
  echo "{}" > "$SETTINGS"
fi
if ! jq empty "$SETTINGS" 2>/dev/null; then
  echo "✗ $SETTINGS is not valid JSON. Fix it manually and re-run."
  exit 1
fi

backup="${SETTINGS}.backup-$(date +%Y%m%d%H%M%S)"
cp "$SETTINGS" "$backup"

tmp="$(mktemp)"
jq --arg gate "${HOOKS_DIR}/commit-gate.sh" --arg status "${HOOKS_DIR}/session-status.sh" '
  .hooks //= {}
  | .hooks.PreToolUse //= []
  | (if ([.hooks.PreToolUse[]? | .hooks[]? | select(.command == $gate)] | length) > 0
     then .
     else .hooks.PreToolUse += [{"matcher": "Bash", "hooks": [{"type": "command", "command": $gate}]}]
     end)
  | .hooks.SessionStart //= []
  | (if ([.hooks.SessionStart[]? | .hooks[]? | select(.command == $status)] | length) > 0
     then .
     else .hooks.SessionStart += [{"hooks": [{"type": "command", "command": $status}]}]
     end)
' "$SETTINGS" > "$tmp"
mv "$tmp" "$SETTINGS"

echo "  ✓ PreToolUse + SessionStart entries present in $SETTINGS (backup: $(basename "$backup"))"
echo ""
echo "Both hooks are active in NEW Claude Code sessions from now on:"
echo "  - Commit gate: 'git commit' is blocked unless /code-review wrote a receipt"
echo "    (.claude/review-passed) hashing the exact staged diff."
echo "    Human override: SKIP_REVIEW_GATE=1 git commit ..."
echo "  - Session status: if the project has a .claude/todos.md (the /todo skill),"
echo "    the focused task and its next milestone are pushed into context at"
echo "    session start — no need to remember to run /todo list."
echo ""
echo "To uninstall: remove the PreToolUse/SessionStart entries from $SETTINGS"
echo "and delete ${HOOKS_DIR}/commit-gate.sh ${HOOKS_DIR}/session-status.sh"
echo ""
