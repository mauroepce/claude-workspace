#!/usr/bin/env bash
# Sanity check for personal-commands/*.md files.
# Verifies frontmatter is well-formed and required fields exist.
#
# Usage:
#   bin/validate-commands.sh
#
# Exits 0 if all commands are valid, 1 if any fails.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
COMMANDS_DIR="${REPO_ROOT}/personal-commands"

if [ ! -d "$COMMANDS_DIR" ]; then
  echo "✗ personal-commands/ not found"
  exit 1
fi

errors=0
warnings=0
checked=0

echo ""
echo "→ Validating personal-commands/ in $REPO_ROOT"
echo ""

for cmd_file in "$COMMANDS_DIR"/*.md; do
  cmd_name="$(basename "$cmd_file" .md)"
  checked=$((checked + 1))

  # Check 1: starts with frontmatter delimiter
  if ! head -1 "$cmd_file" | grep -q "^---$"; then
    echo "  ✗ /${cmd_name}: missing opening frontmatter (---)"
    errors=$((errors + 1))
    continue
  fi

  # Check 2: has closing frontmatter delimiter within first 10 lines
  if ! head -10 "$cmd_file" | tail -n +2 | grep -q "^---$"; then
    echo "  ✗ /${cmd_name}: missing closing frontmatter (---)"
    errors=$((errors + 1))
    continue
  fi

  # Check 3: has description: field in frontmatter
  if ! head -10 "$cmd_file" | grep -q "^description:"; then
    echo "  ✗ /${cmd_name}: missing 'description:' field in frontmatter"
    errors=$((errors + 1))
    continue
  fi

  # Check 4: description is not empty
  desc_line=$(head -10 "$cmd_file" | grep "^description:" | head -1)
  desc_content=$(echo "$desc_line" | sed 's/^description://' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
  if [ -z "$desc_content" ]; then
    echo "  ✗ /${cmd_name}: 'description:' field is empty"
    errors=$((errors + 1))
    continue
  fi

  # Check 5: description length is reasonable (not too short, not too long)
  desc_length=${#desc_content}
  if [ $desc_length -lt 30 ]; then
    echo "  ⚠ /${cmd_name}: description very short (${desc_length} chars, expected ≥30)"
    warnings=$((warnings + 1))
  fi
  if [ $desc_length -gt 500 ]; then
    echo "  ⚠ /${cmd_name}: description very long (${desc_length} chars, expected ≤500)"
    warnings=$((warnings + 1))
  fi

  # Find the line number of the closing frontmatter delimiter (second "---")
  fm_close_line=$(awk '/^---$/{count++; if(count==2){print NR; exit}}' "$cmd_file")
  if [ -z "$fm_close_line" ]; then
    fm_close_line=10
  fi
  body_start=$((fm_close_line + 1))

  # Check 6: has at least one H1 header in the body (after frontmatter)
  if ! tail -n +"$body_start" "$cmd_file" | grep -q "^# "; then
    echo "  ⚠ /${cmd_name}: no H1 header found in body"
    warnings=$((warnings + 1))
  fi

  # Check 7: command name in body matches filename
  if ! tail -n +"$body_start" "$cmd_file" | grep -q "/${cmd_name}"; then
    echo "  ⚠ /${cmd_name}: command name '/${cmd_name}' not referenced in body"
    warnings=$((warnings + 1))
  fi

  if [ $errors -eq 0 ] && [ $warnings -eq 0 ]; then
    echo "  ✓ /${cmd_name}"
  fi
done

echo ""

# Check 8: install-personal.sh references all command files
INSTALL_SCRIPT="${REPO_ROOT}/bin/install-personal.sh"
if [ -f "$INSTALL_SCRIPT" ]; then
  echo "→ Cross-check with install-personal.sh"
  for cmd_file in "$COMMANDS_DIR"/*.md; do
    cmd_name="$(basename "$cmd_file" .md)"
    if ! grep -q "\"${cmd_name}\"" "$INSTALL_SCRIPT"; then
      echo "  ⚠ /${cmd_name}: file exists but NOT in PERSONAL_COMMANDS array of install script"
      warnings=$((warnings + 1))
    fi
  done

  # Reverse: PERSONAL_COMMANDS array lists commands that don't have files
  # Extract only from the PERSONAL_COMMANDS=( ... ) block, not STALE_COMMANDS or TEMPLATES.
  script_cmds=$(awk '
    /^PERSONAL_COMMANDS=\(/{flag=1; next}
    /^\)/{if(flag) {flag=0; exit}}
    flag && /^[[:space:]]*"/ {gsub(/[[:space:]"]/, ""); print}
  ' "$INSTALL_SCRIPT")

  while IFS= read -r script_cmd; do
    [ -z "$script_cmd" ] && continue
    if [ ! -f "${COMMANDS_DIR}/${script_cmd}.md" ]; then
      echo "  ✗ /${script_cmd}: listed in PERSONAL_COMMANDS but file is missing"
      errors=$((errors + 1))
    fi
  done <<< "$script_cmds"
fi

echo ""
echo "Summary: ${checked} commands checked, ${errors} errors, ${warnings} warnings"

if [ $errors -gt 0 ]; then
  exit 1
fi

exit 0
