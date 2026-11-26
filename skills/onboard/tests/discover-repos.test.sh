#!/usr/bin/env bash
# Regression tests for the workspace discovery snippets embedded in SKILL.md.
# Exercise both discovery copies and the Phase 0 candidate counter.

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_FILE="$SKILL_DIR/SKILL.md"
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/onboard-discovery-test.XXXXXX")
trap 'rm -rf "$TMP_DIR"' EXIT

extract_one() {
  local begin_marker=$1 end_marker=$2 output_file=$3
  if ! awk -v begin="$begin_marker" -v end="$end_marker" '
    $0 == begin {
      if (started || finished) malformed=1
      else { started=1; extracting=1 }
      next
    }
    $0 == end {
      if (!extracting || finished) malformed=1
      else { extracting=0; finished=1 }
      next
    }
    extracting { print }
    END { if (malformed || !started || !finished || extracting) exit 1 }
  ' "$SKILL_FILE" > "$output_file"; then
    echo "FAIL: missing, duplicate or out-of-order marker: $begin_marker" >&2
    exit 1
  fi
  if [ ! -s "$output_file" ] || ! bash -n "$output_file"; then
    echo "FAIL: extracted block is empty or invalid Bash: $begin_marker" >&2
    exit 1
  fi
}

extract_discovery_copies() {
  local output_dir=$1
  if ! awk -v outdir="$output_dir" '
    $0 == "# BEGIN TESTED REPO DISCOVERY — keep both copies aligned with tests/discover-repos.test.sh" {
      if (extracting || count >= 2) { malformed=1; next }
      count++; extracting=1; output=outdir "/discovery-" count ".sh"; next
    }
    $0 == "# END TESTED REPO DISCOVERY" {
      if (!extracting) { malformed=1; next }
      extracting=0; close(output); next
    }
    extracting { print > output }
    END { if (malformed || count != 2 || extracting) exit 1 }
  ' "$SKILL_FILE"; then
    echo "FAIL: expected exactly two tested repo-discovery blocks in SKILL.md" >&2
    exit 1
  fi

  for file in "$output_dir"/discovery-*.sh; do
    if [ ! -s "$file" ] || ! bash -n "$file"; then
      echo "FAIL: empty or invalid discovery block: $file" >&2
      exit 1
    fi
  done
}

extract_one \
  '# BEGIN TESTED REPO COUNTER — keep this copy aligned with tests/discover-repos.test.sh' \
  '# END TESTED REPO COUNTER' \
  "$TMP_DIR/counter.sh"
extract_discovery_copies "$TMP_DIR"
if ! cmp -s "$TMP_DIR/discovery-1.sh" "$TMP_DIR/discovery-2.sh"; then
  echo "FAIL: the two repo-discovery function copies have drifted" >&2
  diff -u "$TMP_DIR/discovery-1.sh" "$TMP_DIR/discovery-2.sh" >&2 || true
  exit 1
fi

WORKSPACE_ROOT="$TMP_DIR/workspace"
mkdir -p \
  "$WORKSPACE_ROOT/flat/.git" \
  "$WORKSPACE_ROOT/flat/vendor/ignored/.git" \
  "$WORKSPACE_ROOT/outer/.git" \
  "$WORKSPACE_ROOT/outer/nested/.git" \
  "$WORKSPACE_ROOT/outer/embedded" \
  "$WORKSPACE_ROOT/outer/registered/.git" \
  "$WORKSPACE_ROOT/worktree" \
  "$WORKSPACE_ROOT/repos/domain/one/.git" \
  "$WORKSPACE_ROOT/repos/domain/two/.git" \
  "$WORKSPACE_ROOT/repos/my domain/repo one/.git"

printf '[submodule "embedded"]\n\tpath = embedded\n\turl = https://example.invalid/embedded.git\n[submodule "registered"]\n\tpath = registered\n\turl = https://example.invalid/registered.git\n' \
  > "$WORKSPACE_ROOT/outer/.gitmodules"
printf 'gitdir: %s\n' "$WORKSPACE_ROOT/outer/.git/modules/embedded" \
  > "$WORKSPACE_ROOT/outer/embedded/.git"
printf 'gitdir: %s\n' "$WORKSPACE_ROOT/outer/.git/worktrees/worktree" \
  > "$WORKSPACE_ROOT/worktree/.git"

cat > "$TMP_DIR/expected.txt" <<'EOF'
flat
outer
repos/domain/one
repos/domain/two
repos/my domain/repo one
EOF

run_discovery() {
  local definition=$1 diagnostic=$2
  (
    cd "$WORKSPACE_ROOT"
    # shellcheck disable=SC1090
    source "$definition"
    discover_repos
  ) 2> "$diagnostic"
}

run_discovery "$TMP_DIR/discovery-1.sh" "$TMP_DIR/diagnostics-1.txt" > "$TMP_DIR/members-1.txt"
run_discovery "$TMP_DIR/discovery-2.sh" "$TMP_DIR/diagnostics-2.txt" > "$TMP_DIR/members-2.txt"

if ! cmp -s "$TMP_DIR/expected.txt" "$TMP_DIR/members-1.txt"; then
  echo "FAIL: Phase 0 discovery returned unexpected repository members" >&2
  diff -u "$TMP_DIR/expected.txt" "$TMP_DIR/members-1.txt" >&2 || true
  exit 1
fi
if ! cmp -s "$TMP_DIR/members-1.txt" "$TMP_DIR/members-2.txt"; then
  echo "FAIL: Phase 0 and Join discovery copies disagree" >&2
  diff -u "$TMP_DIR/members-1.txt" "$TMP_DIR/members-2.txt" >&2 || true
  exit 1
fi

for diagnostic in "$TMP_DIR/diagnostics-1.txt" "$TMP_DIR/diagnostics-2.txt"; do
  grep -Fq 'WORKTREE worktree' "$diagnostic" || { echo "FAIL: worktree not diagnosed" >&2; exit 1; }
  grep -Fq 'SUBMODULE outer/embedded' "$diagnostic" || { echo "FAIL: .git-file submodule not diagnosed" >&2; exit 1; }
  grep -Fq 'SUBMODULE outer/registered (inside outer)' "$diagnostic" || { echo "FAIL: .gitmodules submodule path not diagnosed" >&2; exit 1; }
  grep -Fq 'NESTED outer/nested (inside outer)' "$diagnostic" || { echo "FAIL: nested repo not diagnosed" >&2; exit 1; }
  if grep -Fq 'vendor/ignored' "$diagnostic"; then
    echo "FAIL: pruned vendor repository was diagnosed" >&2
    exit 1
  fi
done

# shellcheck disable=SC1091
source "$TMP_DIR/counter.sh"

count=$(count_repos_below "$WORKSPACE_ROOT")
[ "$count" = 5 ] || { echo "FAIL: expected 5 repos below workspace, got $count" >&2; exit 1; }
count=$(count_repos_below "$WORKSPACE_ROOT/outer")
[ "$count" = 0 ] || { echo "FAIL: nested repos counted under a repo root ($count)" >&2; exit 1; }
count=$(count_repos_below "$WORKSPACE_ROOT/outer/")
[ "$count" = 0 ] || { echo "FAIL: trailing-slash repo root counted nested repos ($count)" >&2; exit 1; }
count=$(count_repos_below "$WORKSPACE_ROOT/worktree")
[ "$count" = 0 ] || { echo "FAIL: worktree-only directory counted as an independent repo ($count)" >&2; exit 1; }
count=$(count_repos_below "$WORKSPACE_ROOT/repos")
[ "$count" -ge 2 ] || { echo "FAIL: expected a workspace candidate with at least two repos, got $count" >&2; exit 1; }

echo "PASS: discovery copies match; worktree/submodule/nested diagnostics and candidate counts verified"
