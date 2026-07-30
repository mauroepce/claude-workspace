#!/usr/bin/env bash
# Install the deterministic commit gate into ~/.claude/
#
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/mauroepce/claude-workspace/main/bin/install-hooks.sh)
#
# What it does:
#   1. Downloads hooks/commit-gate.sh to ~/.claude/hooks/commit-gate.sh
#   2. Merges a PreToolUse hook entry (matcher: Bash) into ~/.claude/settings.json
#      so the harness runs the gate before every Bash tool call.
#
# Idempotent: re-running updates the script and leaves settings.json unchanged
# if the entry already exists. The previous settings.json is backed up with a
# timestamped filename before writing (same pattern as apply-trust-defenses.sh).
#
# Why a hook and not a prompt: prompts are requests the model can miss; hooks
# are code the harness always runs. See docs/FRAMEWORK.md § Deterministic gates.

set -euo pipefail

REPO="mauroepce/claude-workspace"
BRANCH="main"
RAW="https://raw.githubusercontent.com/${REPO}/${BRANCH}"

HOOKS_DIR="$HOME/.claude/hooks"
HOOK_PATH="${HOOKS_DIR}/commit-gate.sh"
SETTINGS="$HOME/.claude/settings.json"

if ! command -v jq >/dev/null 2>&1; then
  echo "✗ jq is required (same dependency as apply-trust-defenses.sh)."
  echo "  Install it (macOS: brew install jq · Debian/Ubuntu: apt install jq) and re-run."
  exit 1
fi

echo ""
echo "→ Installing commit gate to: $HOOK_PATH"
mkdir -p "$HOOKS_DIR"

if curl -fsSL "${RAW}/hooks/commit-gate.sh" -o "$HOOK_PATH"; then
  chmod +x "$HOOK_PATH"
  echo "  ✓ hooks/commit-gate.sh"
else
  echo "  ✗ Failed to download commit-gate.sh"
  exit 1
fi

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
jq --arg cmd "$HOOK_PATH" '
  .hooks //= {}
  | .hooks.PreToolUse //= []
  | (if ([.hooks.PreToolUse[]? | .hooks[]? | select(.command == $cmd)] | length) > 0
     then .
     else .hooks.PreToolUse += [{"matcher": "Bash", "hooks": [{"type": "command", "command": $cmd}]}]
     end)
' "$SETTINGS" > "$tmp"
mv "$tmp" "$SETTINGS"

echo "  ✓ PreToolUse entry present in $SETTINGS (backup: $(basename "$backup"))"
echo ""
echo "The gate is active in NEW Claude Code sessions from now on:"
echo "  - 'git commit' is blocked unless /code-review wrote a receipt"
echo "    (.claude/review-passed) hashing the exact staged diff."
echo "  - Human override: SKIP_REVIEW_GATE=1 git commit ..."
echo ""
echo "To uninstall: remove the PreToolUse entry from $SETTINGS and delete $HOOK_PATH"
echo ""
