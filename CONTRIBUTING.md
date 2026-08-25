# Contributing

Thanks for looking at this. Before you invest time, read this page — it will save both of us a rejected PR.

## What this repo is

A **personal toolkit**, opinionated by design. It encodes one person's workflow, publicly, so others can install it or steal ideas from it. It is not a community framework aiming to cover every use case, and it is **not maintained for backwards compatibility** (renames happen; users re-run the installer to migrate).

That context sets the contribution policy:

## Issues

- **Bug reports: very welcome.** A skill that misbehaves, a script that fails on your platform, a doc that contradicts the code — file it. Include how you installed (plugin or curl), your Claude Code version, and what you expected vs what happened.
- **Questions:** fine as issues too. If the answer is "the docs didn't say it", that's a docs bug and worth keeping.
- **Feature ideas:** open an issue **before** writing code. The toolkit stays deliberately small; most feature PRs that arrive without prior discussion will be declined, not because they're bad, but because they don't fit the philosophy (see `docs/FRAMEWORK.md`, "What this is not").

## Pull requests

- **Small fixes** (typos, broken commands, portability of a script): PR directly, no prior issue needed.
- **Behavior changes and new skills**: issue first, PR after agreement.
- Every PR gets reviewed line by line before merging. `main` is what the installer and the plugin serve, so anything merged goes live to every user immediately. Expect slow, careful review rather than fast merges.

### PR checklist

Mirror of the repo's own working rules (`CLAUDE.md`):

- [ ] `bin/validate-commands.sh` passes
- [ ] If a skill's behavior changed: `docs/FRAMEWORK.md` updated
- [ ] If a description changed: README quick-reference table updated
- [ ] If files were added/removed: `bin/install-personal.sh` arrays updated
- [ ] Conventional commit style (`feat:`, `fix:`, `refactor:`, `docs:`, `chore:`)
- [ ] No emojis in source files

### Changes that get extra scrutiny

Anything under `bin/` or `hooks/` is **code that runs on users' machines** (the installer via `curl | bash`, the hooks on every session). PRs touching those paths are reviewed as security-sensitive: every line, no exceptions, and merges there may take longer. Please keep diffs to those directories minimal and separate from unrelated changes.

## Security issues

If you find a vulnerability (in the installer, the hooks, or anything that executes), **do not open a public issue**. Use GitHub's private vulnerability reporting ("Security" tab → "Report a vulnerability") so it can be fixed before it's public.

## Attribution

Merged contributions get credited in the commit message. This repo's own commits carry `Co-Authored-By: Claude` — transparency about AI authorship is part of the point here; your PRs don't need to.
