#!/usr/bin/env bash
# Install claude-workspace into an existing project.
# Usage:  curl -fsSL https://raw.githubusercontent.com/mauroepce/claude-workspace-template/main/bin/install.sh | bash
#
# This script:
#   - Adds .claude/commands/, _templates/, docs/ARCHITECTURE.md to your project.
#   - Installs root CLAUDE.md and INDEX.md ONLY if they don't already exist.
#   - Backs up any existing files in .claude/commands/ or _templates/ to *.bak.
#   - Prints next steps so you can run /setup in Claude Code.
#
# Safe to run inside a non-empty git repo. Doesn't touch your code.

set -euo pipefail

REPO="mauroepce/claude-workspace-template"
BRANCH="main"
RAW="https://raw.githubusercontent.com/${REPO}/${BRANCH}"

# Files we always install (with backup-if-conflict)
ALWAYS_INSTALL=(
  ".claude/commands/setup.md"
  ".claude/commands/new-project.md"
  ".claude/commands/status.md"
  "_templates/presets/research.md"
  "_templates/presets/product.md"
  "_templates/presets/knowledge.md"
  "_templates/presets/consulting.md"
  "_templates/presets/custom.md"
  "_templates/root-CLAUDE.md.tmpl"
  "_templates/subproject-CLAUDE.md.tmpl"
  "_templates/subproject-STATUS.md.tmpl"
  "docs/ARCHITECTURE.md"
)

# Files we install ONLY if they don't already exist (avoid clobbering user content)
INSTALL_IF_MISSING=(
  "CLAUDE.md"
  "INDEX.md"
)

echo ""
echo "→ Installing claude-workspace into: $(pwd)"
echo ""

count_installed=0
count_backed_up=0
count_preserved=0

for file in "${ALWAYS_INSTALL[@]}"; do
  if [ -f "$file" ]; then
    mv "$file" "${file}.bak"
    echo "  ⚠ ${file} exists → backed up to ${file}.bak"
    count_backed_up=$((count_backed_up + 1))
  fi
  mkdir -p "$(dirname "$file")"
  if curl -fsSL "${RAW}/${file}" -o "$file"; then
    echo "  ✓ ${file}"
    count_installed=$((count_installed + 1))
  else
    echo "  ✗ Failed to download ${file}"
    exit 1
  fi
done

for file in "${INSTALL_IF_MISSING[@]}"; do
  if [ -f "$file" ]; then
    echo "  → ${file} preserved (will be handled by /setup)"
    count_preserved=$((count_preserved + 1))
  else
    if curl -fsSL "${RAW}/${file}" -o "$file"; then
      echo "  ✓ ${file}"
      count_installed=$((count_installed + 1))
    fi
  fi
done

echo ""
echo "✅ ${count_installed} files installed, ${count_backed_up} backed up, ${count_preserved} preserved"
echo ""
echo "Next steps:"
echo "  1. Open this project in Claude Code (or VSCode + Claude)"
echo "  2. In the chat, type:  /setup"
echo "  3. Answer the questions — Claude will configure your workspace"
echo ""
if [ $count_preserved -gt 0 ]; then
  echo "Note: an existing CLAUDE.md was preserved. /setup will ask whether"
  echo "to merge workspace conventions into it or replace it."
  echo ""
fi
