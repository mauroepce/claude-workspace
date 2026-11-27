#!/usr/bin/env bash
# Regression tests for the URL helpers embedded in ../SKILL.md.
# Extract the documented functions so tests exercise the skill's actual code.

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_FILE="$SKILL_DIR/SKILL.md"
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/add-repo-url-test.XXXXXX")
trap 'rm -rf "$TMP_DIR"' EXIT

if ! awk '
  $0 == "# BEGIN TESTED URL HELPERS — keep markers aligned with tests/normalize-git-url.test.sh" {
    if (found_start || found_end) { malformed=1; next }
    found_start=1; extracting=1; next
  }
  $0 == "# END TESTED URL HELPERS" {
    if (!extracting || found_end) { malformed=1; next }
    found_end=1; extracting=0; next
  }
  extracting { print }
  END { if (malformed || !found_start || !found_end || extracting) exit 1 }
' "$SKILL_FILE" > "$TMP_DIR/url-helpers.sh"; then
  echo "FAIL: URL-helper markers are missing, duplicated, or out of order in SKILL.md" >&2
  exit 1
fi

if [ ! -s "$TMP_DIR/url-helpers.sh" ]; then
  echo "FAIL: URL-helper markers did not enclose function definitions" >&2
  exit 1
fi

if ! bash -n "$TMP_DIR/url-helpers.sh"; then
  echo "FAIL: extracted URL helpers are not valid Bash" >&2
  exit 1
fi

# shellcheck disable=SC1091
source "$TMP_DIR/url-helpers.sh"

normalizer_passed=0
checker_passed=0

assert_result() {
  local expected_status=$1 expected_output=$2 input=$3 output status
  if output=$(normalize_git_url "$input" 2>/dev/null); then
    status=0
  else
    status=$?
  fi

  if [ "$status" -ne "$expected_status" ] || [ "$output" != "$expected_output" ]; then
    printf 'FAIL: %q => status=%s output=%q; expected status=%s output=%q\n' \
      "$input" "$status" "$output" "$expected_status" "$expected_output" >&2
    exit 1
  fi
  normalizer_passed=$((normalizer_passed + 1))
}

assert_result 0 'github.com/org/repo' 'https://github.com/org/repo'
assert_result 0 'github.com/org/repo' 'https://GitHub.com/ORG/Repo.GIT/'
assert_result 0 'github.com/org/repo' 'git@github.com:ORG/repo.git'
assert_result 0 'github.com/org/repo' 'ssh://git@github.com/org/repo.git'
assert_result 0 'github.com/org/repo' 'ssh://git@github.com/org/repo.git/'
assert_result 0 'github.com/org/repo' 'ssh://deploy@github.com/org/repo.git'
assert_result 0 'github.com/org/re@po' 'https://github.com/org/re@po.git'
assert_result 2 'github.com/org/repo' 'ssh://git@github.com:2222/org/repo.git'
assert_result 2 'github.com/org/repo' 'https://github.com:8443/org/repo.git'
assert_result 1 '' 'deploy@github.com:org/repo'

assert_result 1 '' 'https://github.com'
assert_result 1 '' 'https://github.com/'
assert_result 1 '' 'https://github.com/.git'
assert_result 1 '' 'ssh://github.com/'
assert_result 1 '' 'git@github.com:'
assert_result 1 '' 'git@github.com:/'
assert_result 1 '' 'file:///tmp/repo'
assert_result 1 '' '/tmp/repo'
assert_result 0 'github.com/org/repo' 'git@github.com:/ORG/repo.git'

WORKSPACE_ROOT="$TMP_DIR/build"
mkdir -p "$WORKSPACE_ROOT/normal" "$WORKSPACE_ROOT/custom-port"
WORKSPACE_ROOT=$(cd "$WORKSPACE_ROOT" && pwd -P)
git -C "$WORKSPACE_ROOT/normal" init -q
git -C "$WORKSPACE_ROOT/normal" remote add origin https://github.com/Org/Normal.git
git -C "$WORKSPACE_ROOT/normal" remote add credentialed https://user:secret@github.com/org/private.git
git -C "$WORKSPACE_ROOT/custom-port" init -q
git -C "$WORKSPACE_ROOT/custom-port" remote add origin ssh://git@github.com:2222/org/custom.git

assert_check() {
  local expected_status=$1 input=$2 expected_message=$3 output status
  if output=$(check_duplicate_url "$input" "$WORKSPACE_ROOT" 2>"$TMP_DIR/check.stderr"); then
    status=0
  else
    status=$?
  fi

  if [ "$status" -ne "$expected_status" ]; then
    printf 'FAIL: check_duplicate_url %q => status=%s; expected status=%s\n' \
      "$input" "$status" "$expected_status" >&2
    cat "$TMP_DIR/check.stderr" >&2
    exit 1
  fi
  if [ -n "$expected_message" ] && ! grep -Fq "$expected_message" "$TMP_DIR/check.stderr"; then
    printf 'FAIL: check_duplicate_url %q did not report %q\n' \
      "$input" "$expected_message" >&2
    cat "$TMP_DIR/check.stderr" >&2
    exit 1
  fi
  if grep -Fq 'secret' "$TMP_DIR/check.stderr"; then
    printf 'FAIL: check_duplicate_url %q leaked credentials in diagnostics\n' "$input" >&2
    exit 1
  fi
  checker_passed=$((checker_passed + 1))
}

assert_check 0 'https://github.com/org/new.git' ''
assert_check 1 'git@github.com:ORG/normal.git' "Already cloned at: $WORKSPACE_ROOT/normal"
assert_check 1 'git@github.com:/org/normal.git' "Already cloned at: $WORKSPACE_ROOT/normal"
assert_check 1 'ssh://git@github.com/org/normal.git' "Already cloned at: $WORKSPACE_ROOT/normal"
assert_check 1 'https://github.com/org/private.git' "Already cloned at: $WORKSPACE_ROOT/normal"
assert_check 2 'https://github.com/org/custom.git' 'Review custom-port remotes manually'
assert_check 2 'ssh://git@github.com:2222/org/new.git' 'Custom-port URL needs manual duplicate review'
assert_check 1 'https://user:secret@github.com/org/private.git' 'Do not use a URL with embedded credentials'
assert_check 1 'ssh://user:secret@github.com/org/private-ssh.git' 'Do not use a URL with embedded credentials'

printf 'PASS: %s normalize_git_url cases; %s check_duplicate_url cases\n' \
  "$normalizer_passed" "$checker_passed"
