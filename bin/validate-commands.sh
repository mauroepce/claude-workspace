#!/usr/bin/env bash
# Sanity check for skills/*/SKILL.md files.
# Verifies frontmatter is well-formed and required fields exist.
#
# Usage:
#   bin/validate-commands.sh
#
# Exits 0 if all skills are valid, 1 if any fails.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="${REPO_ROOT}/skills"

if [ ! -d "$SKILLS_DIR" ]; then
  echo "✗ skills/ not found"
  exit 1
fi

errors=0
warnings=0
checked=0

echo ""
echo "→ Validating skills/ in $REPO_ROOT"
echo ""

for skill_dir in "$SKILLS_DIR"/*/; do
  skill_name="$(basename "$skill_dir")"
  skill_file="${skill_dir}SKILL.md"
  checked=$((checked + 1))

  # Check 0: SKILL.md exists in the skill directory
  if [ ! -f "$skill_file" ]; then
    echo "  ✗ /${skill_name}: skills/${skill_name}/ has no SKILL.md"
    errors=$((errors + 1))
    continue
  fi

  # Check 1: starts with frontmatter delimiter
  if ! head -1 "$skill_file" | grep -q "^---$"; then
    echo "  ✗ /${skill_name}: missing opening frontmatter (---)"
    errors=$((errors + 1))
    continue
  fi

  # Check 2: has closing frontmatter delimiter within first 10 lines
  if ! head -10 "$skill_file" | tail -n +2 | grep -q "^---$"; then
    echo "  ✗ /${skill_name}: missing closing frontmatter (---)"
    errors=$((errors + 1))
    continue
  fi

  # Check 3: has description: field in frontmatter (drives auto-invocation)
  if ! head -10 "$skill_file" | grep -q "^description:"; then
    echo "  ✗ /${skill_name}: missing 'description:' field in frontmatter"
    errors=$((errors + 1))
    continue
  fi

  # Check 4: description is not empty
  desc_line=$(head -10 "$skill_file" | grep "^description:" | head -1)
  desc_content=$(echo "$desc_line" | sed 's/^description://' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
  if [ -z "$desc_content" ]; then
    echo "  ✗ /${skill_name}: 'description:' field is empty"
    errors=$((errors + 1))
    continue
  fi

  # Check 5: description length is reasonable (not too short, not too long)
  desc_length=${#desc_content}
  if [ $desc_length -lt 30 ]; then
    echo "  ⚠ /${skill_name}: description very short (${desc_length} chars, expected ≥30)"
    warnings=$((warnings + 1))
  fi
  if [ $desc_length -gt 500 ]; then
    echo "  ⚠ /${skill_name}: description very long (${desc_length} chars, expected ≤500)"
    warnings=$((warnings + 1))
  fi

  # Find the line number of the closing frontmatter delimiter (second "---")
  fm_close_line=$(awk '/^---$/{count++; if(count==2){print NR; exit}}' "$skill_file")
  if [ -z "$fm_close_line" ]; then
    fm_close_line=10
  fi
  body_start=$((fm_close_line + 1))

  # Check 6: has at least one H1 header in the body (after frontmatter)
  if ! tail -n +"$body_start" "$skill_file" | grep -q "^# "; then
    echo "  ⚠ /${skill_name}: no H1 header found in body"
    warnings=$((warnings + 1))
  fi

  # Check 7: skill name in body matches directory name
  if ! tail -n +"$body_start" "$skill_file" | grep -q "/${skill_name}"; then
    echo "  ⚠ /${skill_name}: skill name '/${skill_name}' not referenced in body"
    warnings=$((warnings + 1))
  fi

  if [ $errors -eq 0 ] && [ $warnings -eq 0 ]; then
    echo "  ✓ /${skill_name}"
  fi
done

echo ""

# Check 8: install-personal.sh references all skills
INSTALL_SCRIPT="${REPO_ROOT}/bin/install-personal.sh"
if [ -f "$INSTALL_SCRIPT" ]; then
  echo "→ Cross-check with install-personal.sh"
  for skill_dir in "$SKILLS_DIR"/*/; do
    skill_name="$(basename "$skill_dir")"
    if ! grep -q "\"${skill_name}\"" "$INSTALL_SCRIPT"; then
      echo "  ⚠ /${skill_name}: skill exists but NOT in PERSONAL_SKILLS array of install script"
      warnings=$((warnings + 1))
    fi
  done

  # Reverse: PERSONAL_SKILLS array lists skills that don't have files
  # Extract only from the PERSONAL_SKILLS=( ... ) block, not STALE_COMMANDS or TEMPLATES.
  script_skills=$(awk '
    /^PERSONAL_SKILLS=\(/{flag=1; next}
    /^\)/{if(flag) {flag=0; exit}}
    flag && /^[[:space:]]*"/ {gsub(/[[:space:]"]/, ""); print}
  ' "$INSTALL_SCRIPT")

  while IFS= read -r script_skill; do
    [ -z "$script_skill" ] && continue
    if [ ! -f "${SKILLS_DIR}/${script_skill}/SKILL.md" ]; then
      echo "  ✗ /${script_skill}: listed in PERSONAL_SKILLS but skills/${script_skill}/SKILL.md is missing"
      errors=$((errors + 1))
    fi
  done <<< "$script_skills"
fi

echo ""
echo "Summary: ${checked} skills checked, ${errors} errors, ${warnings} warnings"

if [ $errors -gt 0 ]; then
  exit 1
fi

exit 0
