---
name: add-repo
description: Add a repository to a multi-repo workspace. Inspects the existing layout and INDEX.md, proposes a destination (repos/<domain>/<name> or the current flat layout), checks for collisions and duplicates, and clones only after explicit confirmation. Use when asked to clone a repo into the workspace, add a new service, or decide where a repo should live.
---

# /add-repo — add a repository to the workspace

You are Claude. The user wants a repo inside this workspace, and the workspace has a shape: an `INDEX.md`, maybe a `repos/` container, maybe domain folders. Your job is to put the clone where the existing map says it belongs — and to stop before writing anything until the user confirms.

This is the explicit counterpart to discovery. `/onboard` reads the tree; `/add-repo` changes it. Do **not** intercept `git clone` globally: a hook that guesses the destination from a URL is how a repo lands in the wrong team's folder. One command, one inspected destination, one confirmation.

## Phase 1 — Confirm the workspace root

```bash
pwd
candidate=$PWD
while [ "$candidate" != "/" ]; do
  if [ -f "$candidate/INDEX.md" ]; then
    printf '%s\n' "$candidate/INDEX.md"
    break
  fi
  candidate=$(dirname "$candidate")
done
```

Use the nearest ancestor that contains the workspace `INDEX.md` as `WORKSPACE_ROOT`; confirm it is the intended workspace before proceeding. The workspace may itself live inside a parent Git repo (for example, docs and `INDEX.md` at the root with clones under `repos/`). That is valid: do not reject it just because `git rev-parse` finds the outer repo. If there is no `INDEX.md`, ask whether this is the workspace root or a single repo; `repos/` by itself is not enough to distinguish them. Never clone into an unrelated repo's root just because the command was run there. Run the Bash snippets in `bash` because they use process substitution.

If the user has not supplied the repository URL, ask for it; do not infer a URL from a repository name. Keep the exact URL in `URL` and the confirmed absolute path in `WORKSPACE_ROOT` for the checks below.

Use `git rev-parse --show-toplevel` only to understand the containing Git repo, not to decide whether the workspace is valid. If that path equals `WORKSPACE_ROOT`, it is the outer workspace container and is allowed. If the current directory is inside a child repo below `WORKSPACE_ROOT`, switch to `WORKSPACE_ROOT` before proposing a destination.

## Phase 2 — Read the existing shape

1. Read `INDEX.md`'s Repos table. The paths tell you the convention already in use: `cep/x`, `repos/cep/x`, or flat names.
2. If `repos/` exists, list its first two levels to see the domains.
3. List every `.git` below `WORKSPACE_ROOT`. Worktrees and submodules are included on purpose: they share the same history, so a duplicate remote there is still a duplicate. Keep this prune list aligned with `/onboard`'s discovery list.

```bash
find "$WORKSPACE_ROOT/." \
  \( -name node_modules -o -name .venv -o -name venv -o -name vendor \
     -o -name dist -o -name build -o -name target -o -name .next \
     -o -name .turbo \) -prune -o \
  -name .git \( -type d -o -type f \) -print -prune 2>/dev/null \
| while IFS= read -r dotgit; do printf '%s\n' "${dotgit%/.git}"; done | sort
```

The search intentionally includes `WORKSPACE_ROOT` itself if it has `.git`: its remotes also count as already-cloned repositories.

4. Compare the requested URL with every remote URL already listed. Normalize SSH and HTTPS forms to a case-insensitive `host/org/repo` key (strip scheme, optional user from the authority, trailing slash, and `.git`). For example, `git@github.com:org/repo.git`, `ssh://git@github.com/org/repo.git`, and `https://github.com/org/repo/` all become `github.com/org/repo`. The scp-style form supports the `git@host:path` login; if another SSH username is required, use `ssh://user@host/path`. Then list the `.git` entries and inspect all remotes; compare normalized keys:

```bash
# BEGIN TESTED URL HELPERS — keep markers aligned with tests/normalize-git-url.test.sh
normalize_git_url() {
  local url=$1 authority path custom_port=0
  case "$url" in
    https://*|ssh://*)
      url=${url#*://}
      case "$url" in
        */*) authority=${url%%/*}; path=${url#*/} ;;
        *) echo "Git URL is missing a repository path." >&2; return 1 ;;
      esac
      case "${path%/}" in '' ) echo "Git URL is missing a repository path." >&2; return 1 ;; esac
      authority=${authority##*@}
      case "$authority" in
        *:*) authority=${authority%%:*}; url="$authority/$path"; custom_port=1 ;;
        *) url="$authority/$path" ;;
      esac
      ;;
    git@*:* )
      authority=${url%%:*}; path=${url#*:}; authority=${authority#git@}
      case "$path" in ''|/) echo "Git URL is missing a repository path." >&2; return 1 ;; esac
      while [[ "$path" == /* ]]; do path=${path#/}; done
      url="$authority/$path" ;;
    *) return 1 ;;
  esac
  url=$(printf '%s\n' "$url" | tr '[:upper:]' '[:lower:]')
  while [[ "$url" == */ ]]; do url=${url%/}; done
  url=${url%.git}
  while [[ "$url" == */ ]]; do url=${url%/}; done
  case "$url" in */*) path=${url#*/} ;; *) path="" ;; esac
  case "$path" in '' ) echo "Git URL is missing a repository path." >&2; return 1 ;; esac
  printf '%s\n' "$url"
  if [ "$custom_port" -eq 1 ]; then
    echo "Custom-port remote needs manual duplicate review." >&2
    return 2
  fi
}
check_duplicate_url() {
  local URL=$1 WORKSPACE_ROOT=$2 requested_authority userinfo REQUESTED EXISTING UNCERTAIN MATCH normalize_status dotgit repo remote remote_url key status

  case "$URL" in
    -*|*[[:space:]]*|*[[:cntrl:]]*|*\?*|*\#*) echo "Unsafe or malformed Git URL; stop." >&2; return 1 ;;
    https://*|ssh://*|git@*:* ) ;;
    *) echo "Unsupported Git URL form; ask before proceeding." >&2; return 1 ;;
  esac
  case "$URL" in
    https://*)
      requested_authority=${URL#*://}; requested_authority=${requested_authority%%/*}
      case "$requested_authority" in *@*) echo "Do not use a URL with embedded credentials; configure Git credentials separately." >&2; return 1 ;; esac ;;
    ssh://*)
      requested_authority=${URL#*://}; requested_authority=${requested_authority%%/*}
      case "$requested_authority" in
        *@*) userinfo=${requested_authority%%@*}; case "$userinfo" in *:*) echo "Do not use a URL with embedded credentials; configure SSH credentials separately." >&2; return 1 ;; esac ;;
      esac ;;
  esac
  if REQUESTED=$(normalize_git_url "$URL"); then
    normalize_status=0
  else
    normalize_status=$?
  fi
  if [ "$normalize_status" -eq 2 ]; then
    echo "Custom-port URL needs manual duplicate review before adding a clone." >&2
    return 2
  fi
  [ "$normalize_status" -eq 0 ] || { echo "Unsupported Git URL form; ask before proceeding." >&2; return 1; }
  EXISTING=$(while IFS= read -r dotgit; do
    repo=${dotgit%/.git}
    [ -d "$repo" ] || continue
    repo=$(cd "$repo" && pwd -P) || continue
    while IFS= read -r remote; do
      while IFS= read -r remote_url; do
        if key=$(normalize_git_url "$remote_url" 2>/dev/null); then
          status=0
        else
          status=$?
        fi
        if [ "$status" -eq 2 ]; then
          [ "$key" = "$REQUESTED" ] && printf 'CUSTOM_PORT\t%s\n' "$repo"
          continue
        fi
        [ "$status" -eq 0 ] || continue
        printf '%s\t%s\n' "$key" "$repo"
      done < <(git -C "$repo" remote get-url --all "$remote" 2>/dev/null)
    done < <(git -C "$repo" remote 2>/dev/null)
done < <(find "$WORKSPACE_ROOT/." \
  \( -name node_modules -o -name .venv -o -name venv -o -name vendor \
     -o -name dist -o -name build -o -name target -o -name .next \
     -o -name .turbo \) -prune -o \
  -name .git \( -type d -o -type f \) -print -prune 2>/dev/null))
  UNCERTAIN=$(awk -F '\t' '$1=="CUSTOM_PORT" {print $2}' <<< "$EXISTING")
  [ -z "$UNCERTAIN" ] || { echo "Review custom-port remotes manually before adding a clone:" >&2; printf '%s\n' "$UNCERTAIN" >&2; return 2; }
  MATCH=$(awk -F '\t' -v requested="$REQUESTED" '$1==requested {print $2; exit}' <<< "$EXISTING")
  [ -z "$MATCH" ] || { echo "Already cloned at: $MATCH" >&2; return 1; }
  return 0
}
# END TESTED URL HELPERS
check_duplicate_url "$URL" "$WORKSPACE_ROOT"
```

Run the check block in `bash`. If it returns non-zero, stop and resolve the URL or duplicate; do not continue to destination selection. This normalizer equates host/path for standard SSH and HTTPS URLs. A custom-port remote only triggers manual review when its normalized host/path matches the requested repo; custom-port requested URLs always require manual review. Local paths and `file://` remotes are not normalized and must be compared manually. HTTPS URLs with embedded credentials and SSH URLs with password-like userinfo are rejected so secrets are not printed; use Git's credential helper or SSH agent instead.

If the repo is already cloned, stop and point at the existing path. Do not clone a second copy. If the requested URL uses a different host or namespace, compare the repo identity with the user rather than assuming it is the same project. Normalization lowercases the path for GitHub-style host matching; on a case-sensitive Git host this can produce a false duplicate, so verify the provider's path semantics before stopping.

## Phase 3 — Propose a destination

Apply the first rule that matches:

| Workspace shape | Destination |
|---|---|
| `repos/` exists and the repo's domain is clear | `repos/<domain>/<name>` |
| `repos/` exists and no domain is clear | `repos/<name>` — flat inside the container, not an invented category |
| No `repos/`, existing repos are flat | `<name>` — match the current layout |
| No `repos/`, existing repos are grouped | `<group>/<name>` — match the group, or ask |

`<name>` is the last path segment of the URL after removing a trailing slash and then the `.git` suffix. Keep the remote's name; do not rename it to match a ticket or a product nickname. Validate the value before using it as a path component: it must match `^[A-Za-z0-9._-]+$` and must not be `.` or `..`. Apply the same rule to `<domain>` and every grouping component. A URL ending in `.`/`..` or producing an empty name is invalid; ask rather than guessing.

State the proposal in one line, with the reason:

> "Proposed: `repos/cep/APP02504-martech-core-api` — `repos/` exists and `cep/` already groups the Martech repos."

If the domain is ambiguous, present the two best options and ask. Do not pick a new domain name on your own; a wrong category is worse than a flat clone the user can move later.

## Phase 4 — Validate before cloning

Refuse the clone outright when any of these safety checks fail; do not offer an override that would bypass path or overwrite protection:

- **The destination exists** (file or directory). Never clone over it; `git clone` refuses a non-empty directory, but the check is yours, not git's error message.
- **The resolved destination escapes `WORKSPACE_ROOT`.** Resolve the parent and destination to absolute paths and require the destination to be strictly below `WORKSPACE_ROOT`; reject absolute paths, `..` path components, and symlinked parents that escape it.
- **The destination is inside a repo cloned beneath `WORKSPACE_ROOT`.** Check ancestors only back to `WORKSPACE_ROOT`: if a repo root strictly below the workspace root contains the destination, it would be nested. Do not treat `WORKSPACE_ROOT` itself — even if it is the outer Git repo — as a reason to block; `/onboard` intentionally supports a workspace container inside a parent repo.
- **A case-insensitive collision exists.** Compare the proposed final path component against sibling names without regard to case, even if the exact-case destination does not exist. This catches case-only names that can coexist on Linux but collide on a case-insensitive macOS or Windows filesystem.
- **The URL is already cloned elsewhere** (Phase 2.4). Point at the existing path.
- **The URL begins with `-`, contains whitespace/control characters, query/fragment text, or is not a supported Git URL** (`https://`, `ssh://`, or `git@host:path`). Ask before cloning from an unexpected host.

Say the destination path out loud, including its casing: macOS hides case-only collisions that Linux CI will not.

## Phase 5 — Confirm, then clone

Show the exact command:

```bash
git clone -- "$URL" "$DESTINATION"
```

Wait for an explicit yes. Then run it. If the clone fails, stop: do not create the directory by hand, do not retry with a different URL, and do not touch `INDEX.md`.

After it succeeds, verify:

```bash
git -C "<destination>" rev-parse --is-inside-work-tree
```

## Phase 6 — Update the index, not the graph

Add one row to the Repos table in `INDEX.md`:

- **Repo**: the relative path with a trailing `/`.
- **What it is**: one line from the repo's README or package metadata. If you cannot tell, write `<unclear — ask the team>`, not a guess.
- **Stack**: from the manifests.
- **Last activity**: `git -C "<destination>" log -1 --format=%ad --date=short`, plus the branch and `(clean)` when `git status --porcelain` is empty — match the format the existing rows already use.
- **Onboarding**: `—` until `/onboard` runs in that repo.

Do **not** invent `handles.local.md`, Names, or Edges. Those come from reading the repo, and a wrong handle misroutes every future task. Say the next step: "Run `/onboard` in `<path>` (or at the workspace root) to add its handles and edges."

If the INDEX has no Repos table, add the table with the same header the workspace already uses; do not restructure the file.

## What NOT to do

- Do not clone before the confirmation. "It was obvious" is how a repo lands in the wrong folder.
- Do not create a domain folder for a single repo. Flat inside `repos/` is honest; a category with one member is noise.
- Do not move or rename an existing clone to make the new one fit. That is a separate, explicit migration.
- Do not update Names or Edges by hand.
- Do not `git add`, commit, or push. The workspace index is usually untracked; if it is tracked, leave the change for the user to review.
