---
description: Joining an unfamiliar codebase. Runs /conventions + /architecture + /journeys in sequence and produces an onboarding package — three persistent files plus a 5-minute "where to start reading" summary. Use on day one of a new project, a client handoff, or returning to your own code after long absence. Workspace folders with multiple repos get a root INDEX.md plus per-repo packages; team repos with committed .claude/ get *.local.md artifacts kept out of git status.
---

# /onboard — Codebase onboarding package

You are Claude. The user just opened an unfamiliar codebase and wants the full context dump fast: how it looks, what it is, and how it behaves. Your job is to orchestrate three commands and produce a unified onboarding summary.

This is the meta-command that ties `/conventions`, `/architecture`, and `/journeys` together. Used by senior devs in their first 30 minutes in a new repo.

**Argument (optional):** `$ARGUMENTS` may be a brief context note (e.g., "joining as full-stack hire, focus on backend"). Used to bias the prioritization in step 5.

## Phase 0 — Detect the terrain

Two checks BEFORE the sanity check, because they change where everything gets written:

```bash
# A. Workspace root? Ask about THIS directory only, then count child repos.
# `test -e .git` not `git rev-parse`: rev-parse answers about the whole work
# tree, so it says "is a repo" in every subdirectory of a parent repo and the
# workspace check never fires. `-e` not `-d` because a worktree's .git is a FILE.
test -e .git && echo "this dir is a repo" || echo "not a repo"
ls -d */.git 2>/dev/null | wc -l          # how many direct children are repos

# B. Team-owned tooling? (the repo commits .claude/ content or a CLAUDE.md)
git ls-files .claude CLAUDE.md 2>/dev/null | head -5
```

Note for `zsh` users: an unmatched glob aborts the command instead of returning nothing. Run these in `bash`, or `setopt NULL_GLOB` first.

**Case A — no `.git` in THIS directory but 2+ child directories are git repos** → this is a workspace folder, not a codebase. Jump to "Workspace mode" below. Do NOT stop with "not a git repo".

A workspace can live *inside* a repo — a parent repo that holds docs and skills, with the actual projects cloned into `repos/`. Case A still applies to that inner folder: run workspace mode there, and treat the outer repo as one more repo, not as the workspace.

**Case B — tracked `.claude/` files or a CLAUDE.md exist** → this repo belongs to a team, and your onboarding artifacts are personal notes, not team deliverables. Announce it:

> "This repo has team-owned Claude tooling (committed `.claude/` or CLAUDE.md). I'll write the onboarding package as `*.local.md` files and keep them out of `git status` so nothing personal shows up in the team's diff."

Then for this entire run: use the `.local.md` variant of every output (`conventions.local.md`, `architecture-map.local.md`, `journeys-diagram.local.md`, `onboarding.local.md`) and offer to exclude them locally:

```bash
# `**/` matches zero or more directories, so this one line covers both
# .claude/conventions.local.md and .claude/lessons/mistakes/*.local.md.
grep -qF '.claude/**/*.local.md' .git/info/exclude 2>/dev/null || \
  printf '# personal claude-workspace artifacts\n.claude/**/*.local.md\n' >> .git/info/exclude
```

Why `.git/info/exclude` and not `.gitignore`: `.gitignore` is a committed, shared file — editing it puts YOUR tooling in THEIR diff, which is exactly what this mode avoids. `.git/info/exclude` behaves identically but never leaves your machine.

If neither case applies, continue to Phase 1 — the classic single-repo flow.

## Phase 1 — Sanity check

Confirm the user is in a git-tracked codebase that's NOT trivially empty:

```bash
test -d .git || echo "Not a git repo"
test -f package.json || test -f Cargo.toml || test -f pyproject.toml || test -f go.mod || echo "Unknown project type"
find . -type f -name "*.ts" -o -name "*.tsx" -o -name "*.py" -o -name "*.go" -o -name "*.rs" 2>/dev/null | grep -v node_modules | head -1
```

If it's not a real codebase (and Phase 0 didn't route to Workspace mode), stop: *"I don't see a recognizable project structure here. Run `/onboard` inside a project root (where package.json / Cargo.toml / etc. lives), or in a workspace folder containing your repos."*

## Phase 1.5 — First-run preference: commit attribution

Only on the FIRST onboard of a repo (no `.claude/onboarding.md` or `.local` variant exists yet). Skip entirely on re-runs. Runs AFTER the sanity check on purpose: never interrogate the user in a folder that Phase 1 is about to reject.

First check whether the repo already legislates this (CLAUDE.md only — a `GIT ETIQUETTE` line in the conventions file is a recorded preference, not repo law, and must not short-circuit this check):

```bash
grep -i "co-authored-by" CLAUDE.md 2>/dev/null | head -3
```

If a rule exists, announce it — *"This repo's CLAUDE.md already states a commit-attribution rule; respecting it"* — and move on without asking. Otherwise ask, once:

> "One repo preference, asked only on this first onboard: when I commit here, should commit messages include the `Co-Authored-By: Claude` trailer?
> 1. **Yes** — transparent AI attribution in the git history (what this toolkit's own repo does)
> 2. **No** — clean history, or the team hasn't decided a policy
>
> I'll record the answer in the conventions file so `/safe-commit` and future sessions honor it without re-asking."

Carry the answer into Phase 2: when `/conventions` writes its report, append this section to that same file:

```markdown
## GIT ETIQUETTE

- Co-Authored-By: Claude trailer in commits: <YES|NO> (set on first /onboard, <date>)
```

Precedence downstream: an explicit rule in the repo's own CLAUDE.md always wins over this recorded preference.

## Phase 2 — Run /conventions

Invoke `/conventions` as if the user did. Use the default save location (`.claude/conventions.md`) unless they specify otherwise.

After it completes, capture the result. Note the high-level patterns found (import style, naming, error handling, test framework).

## Phase 3 — Run /architecture

Invoke `/architecture` as if the user did. Default save location is `.claude/architecture-map.md`.

Capture what was found: stack, schema, API surface, auth pattern, integrations.

## Phase 4 — Run /journeys

Invoke `/journeys` as if the user did. Default save location is `.claude/journeys-diagram.md`.

For the journeys selection step, **suggest 3-5 most important ones** automatically (don't make the user pick from 10). Auth flow, payment flow if applicable, and 1-2 main feature flows. Tell the user which you're picking and why.

## Phase 5 — Produce the onboarding summary

Create `.claude/onboarding.md` (or `.claude/onboarding.local.md` if `.gitignore` covers it, or always when Phase 0 flagged team-owned tooling) with this exact format:

```markdown
# Onboarding — <project name>

*Generated by `/onboard` on <date>. The three files referenced below are your cheat sheet.*

## What this is (1 line)

<inferred from package.json description + README + code shape>

## The three persistent artifacts

| File | What it tells you |
|---|---|
| [`conventions.md`](./conventions.md) | How the code looks: import style, naming, error patterns, test framework |
| [`architecture-map.md`](./architecture-map.md) | What the parts are: stack, schema, API routes, auth, integrations |
| [`journeys-diagram.md`](./journeys-diagram.md) | What the code does: visual flow diagrams of <N> main user journeys |

Open them in this order. Read each in 3-5 minutes. Total ramp time: ~15 min.

## Top 5 files to read first

Based on the architecture scan, these are the files that will most often answer "where does this happen?":

1. **`<path>`** — <why important: 1 sentence>
2. **`<path>`** — <why>
3. **`<path>`** — <why>
4. **`<path>`** — <why>
5. **`<path>`** — <why>

If the user passed context in `$ARGUMENTS` (e.g., "focus on backend"), prioritize files matching that focus.

## Mental model for the system

In 3-5 sentences, describe the system's flow at the highest level. Example:

> "This is a Next.js SaaS for X. Users sign up via Supabase Auth (PKCE flow), and a Postgres trigger provisions their profile. The main feature is Y, which lives in `<files>`. Payments flow through Lemon Squeezy webhooks (idempotent via dedup table). Analytics fire to PostHog. Telegram alerts notify the operator on key events."

This is meant to be the kind of explanation you'd give a new hire on day one.

## What to ask the team / read in the wiki

Things the code didn't tell us, that you'd want to know on day one:

- <gap 1, e.g., "What's the deployment process? I see Vercel hooks but no deploy.yml">
- <gap 2, e.g., "Are there staging/test environments? Couldn't find env config for them">
- <gap 3>
- ...

## What's NOT documented (honest gaps from the scan)

- <list anything the three scans marked as TBD>
```

## Phase 6 — Hand off

Output:

> "Onboarding package ready in `.claude/`:
> - `conventions.md` (style)
> - `architecture-map.md` (structure)
> - `journeys-diagram.md` (flows)
> - `onboarding.md` (the summary + suggested reading order)

(Use the `*.local.md` names throughout when Phase 0 Case B applied.)
>
> Total ramp time: ~15 min to read all four. After that, you'll have a working mental model of the system.
>
> When you're ready to make changes, run `/work` — it'll auto-load the conventions file as context. Or `/quick-work` for small edits."

## Workspace mode (parent folder with multiple repos)

The folder is not a codebase — it's a workspace: each child directory with `.git` is its own project, with its own stack, conventions, and team. Onboarding it as ONE codebase would blend incompatible conventions into a muddled report, so don't. Produce two artifacts instead:

### 1. handles.md — what each repo answers to (this is what makes routing possible)

Do this before the INDEX, because the INDEX is derived from it.

The problem it solves, measured on a real workspace: grepping for a repo's **directory name** `tg-oss` finds 6 files. Grepping for the name it publishes under, `@teselagen/ui`, finds 1011. Same dependency, 168x apart. **You can grep for what a repo calls; you cannot grep for what it is called** — so the name is the one thing worth writing to disk.

Write `<repo>/.claude/handles.local.md` in **every** repo, team-owned or not. These are your personal routing notes, never a team deliverable, so they are always the `.local` variant. Add the exclude line in each repo — do not assume it is already there, it usually is not:

```bash
grep -qF '.claude/**/*.local.md' .git/info/exclude 2>/dev/null || \
  printf '# personal claude-workspace artifacts\n.claude/**/*.local.md\n' >> .git/info/exclude
```

Format — two header keys, one block, one date, no nesting:

```
repo: tg-oss
aka: ove | open vector editor

serves:
- @teselagen/ove   :: packages/ove/
- @teselagen/ui    :: packages/ui/

scanned: <date>
```

Read `serves` as: *these are the strings another repo would contain if it talked to me, and here is what implements each one.*

**Where handles come from**, in descending order of reliability:

1. **Published package names.** `git ls-files '*package.json' 'pyproject.toml'` — take the `name` field. Skip anything private, and skip vendored upstream code and example/demo packages: a repo that vendors a framework will otherwise claim that framework's name. Check `private` loosely — it appears as both `true` and `"true"` in the wild.
2. **Deployable names in your own manifests.** `git ls-files 'docker-compose*' 'k8s/**/*.yaml' 'Dockerfile*'`. Only count a name if **this repo builds it** — a deploy repo's manifests name everyone's services, and claiming them makes that repo appear to serve half the platform.
3. **The env var peers use to reach you.** This one is backwards by default and needs care: the `*_URL` variables inside a repo are overwhelmingly the ones it **consumes**, not the ones it answers to. `lims` contains `WALLET_API_URL` because it *calls* the wallet, not because it *is* the wallet. Only claim such a variable as a handle if you can see this repo **serving** that address — it appears in this repo's own deploy manifest as its published host, or its value points at this repo's service. When in doubt leave it out; a wrongly claimed variable invents an inbound edge that does not exist.

For the `:: path` on an env-var handle, point at the directory that answers the requests (`server/`, `gateway/`), not at a file that merely mentions the name. If you cannot tell, write `::` with the repo root and say so in the INDEX.

**Which strings are usable as handles:**

- At least 3 characters.
- **Never** a generic name that half the ecosystem uses. Blocklist, non-negotiable: `API_URL`, `BASE_URL`, `HOST_URL`, `DATABASE_URL`, `DB_HOST`, `REDIS_URL`, `PORT`, `GATEWAY_URL`, `BACKEND_URL`, `FRONTEND_URL`, `SERVICE_URL`, `WEBHOOK_URL`, and anything equally unqualified. Measured: five of these alone carried 693 hits across one workspace and would have fabricated an edge between nearly every pair of repos.
- A short bare name like `piston` or `qdrant` **is** allowed, because the join matches on word boundaries (below). Before boundary matching it was not: the bare handle `j5` matched 139,790 times, and the rule that banned it also banned legitimate Kubernetes service names.

If a repo has no distinctive name, leave `serves:` empty and say so. An empty block is honest; an invented handle is not.

### 2. INDEX.md — the roll-up, with derived routing

Light scan per child repo for the table. Everything below "Repos" is **generated output**:

```markdown
# <folder name> — workspace index

*Repo table by `/onboard`. Everything below "Routing" is DERIVED — regenerated <date>.
Do not hand-edit it: fix the repo's .claude/handles.local.md and re-run the join at the bottom.*

## Routing — read this before opening any repo

1. Look up every proper noun in the task under "Names". That maps task vocabulary
   onto a repo AND a path inside it.
2. Read the "Edges" rows for the repos you hit. One hop. Stop.
3. Open only those repos, starting at the paths "Names" gave you.
4. A name absent from "Names" is not necessarily absent from the workspace —
   check "Unmatched" before concluding anything.
5. If the date above is old, re-run the join at the bottom of this file.

## Repos
| Repo | What it is | Stack | Last activity | Onboarding |
|---|---|---|---|---|

## Names
<handles grouped by the repo that serves them, with paths>

## Edges — derived <date>, counts are matches
| From | To | Matched handle | Hits |
|---|---|---|---|

## Inbound — inverted from Edges. Never authored.

## Unmatched — references no handle claims
<by category, see below>

## Known blind spots — not detectable by this method

## Join — the command that regenerates the three sections above
<paste the exact script, so the file carries its own instructions>
```

**The join.** Run from the workspace root, in `bash`:

```bash
# Word-boundary matching is the whole difference between signal and noise.
# git grep here has no PCRE, and \b does NOT help: a hyphen is a non-word
# character, so `tg-app\b` still matches tg-app-dev. Capture the neighbouring
# character instead and strip it afterwards.
HANDLES=$(awk -F' :: ' '/^- /{sub(/^- /,"");gsub(/ +$/,"",$1);print $1}' */.claude/handles*.md \
  | sort -u | grep -E '^.{3,}$' | sed 's/[.[\*^$]/\\&/g' | paste -sd'|' -)

for d in */; do
  [ -e "$d/.git" ] || continue
  # skip worktrees: their .git is a FILE and their content duplicates the parent
  [ -d "$d/.git" ] || { echo "skipped worktree: ${d%/}" >&2; continue; }
  git -C "$d" grep -hoIE "(^|[^A-Za-z0-9_-])($HANDLES)([^A-Za-z0-9_-]|\$)" \
      -- '*.ts' '*.tsx' '*.js' '*.jsx' '*.py' '*.go' '*.yaml' '*.yml' 'Dockerfile*' 2>/dev/null \
    | sed -E 's/^[^A-Za-z0-9_@]//; s/[^A-Za-z0-9_-]$//' \
    | sort | uniq -c | sed "s|^|${d%/} |"
done
```

Drop self-matches and anything under 2 hits. Expect roughly 10 seconds across six repos when the largest holds ~31,000 files.

**Do not add `*.json` to that glob.** In one real repo 15,922 JSON data files carried a handle string against a few hundred source files, and including them tripled the scan time while burying the signal.

**Report what the filter removed.** After building `$HANDLES`, print the handles that were dropped for being too short or blocklisted, and after the join print the handles with **zero** hits anywhere. Both are silent failures otherwise: a handle someone wrote by hand that never participates looks identical to a handle that has no callers. In one real run, 25 of 108 handles were dead weight and nothing said so.

**Unmatched — five categories, not two.** Run the second pass to find what each repo reaches for:

```bash
git -C "$d" grep -hoE '[A-Z][A-Z0-9_]*_(URL|URI|HOST|ENDPOINT)' \
    -- '*.ts' '*.js' '*.py' '*.go' '*.yaml' '*.yml' 2>/dev/null | sort | uniq -c | sort -rn
```

Sort every result that matches no handle into:

- **A repo not cloned here.** The highest-value rows. Name the repo you think it is and quote the value that told you (a deploy manifest usually holds it).
- **A repo that IS here, but no handle covers.** The category most likely to be missed, and the one that shows the method's limit: `GATEWAY_URL` inside a client file is a real edge to the gateway repo, but no handle matches because the variable name does not carry the repo's name. Read the value or the surrounding call to place it.
- **An external vendor.** Stripe, an IdP, a public API. Not routable, but worth listing.
- **Own infrastructure.** Database, cache, queue, tunnel. Not a service dependency.
- **Not a dependency at all.** Test constants, regex fragments, and prefixes the pattern truncated (`ARTIFACT_URI` cut out of `ARTIFACT_URI_SCHEME`). Say so rather than inventing an edge.

**Known blind spots.** Record what this method structurally cannot see, so a gap is never read as an absence. The recurring ones: a call made on a relative path against a host held in a shared client object; dispatch through a registry or a slug; a shared URI scheme or route contract that no handle names; and every file type outside the join's glob.

### 3. Full onboarding — per repo, on demand

Don't run three deep scans times N repos unprompted. Ask:

> "Workspace indexed: <N> repos, <M> edges between them. Run the full onboarding (conventions + architecture + journeys) on one of them now? <list, most recently active first>. Each takes a few minutes — the others can be onboarded later by running `/onboard` inside them."

For each chosen repo: `cd` into it and run Phases 0–6 normally. Phase 0 matters here — client repos inside a workspace usually hit Case B (team-owned tooling), so their packages land as `*.local.md` automatically.

After per-repo runs complete, update the INDEX.md "Onboarding" column to link each generated package.

The workspace root usually isn't a git repo, so `INDEX.md` is invisible to every child repo's `git status` — nothing to exclude. If the root IS a repo, apply the Phase 0 Case B rules to it.

## Composition

`/onboard` is the orchestrator. The three commands it runs (`/conventions`, `/architecture`, `/journeys`) are still atomic and invokable independently — you don't NEED to use `/onboard` to get them. But for the day-one experience, this single command is the right entry point.

In workspace mode it also pairs with `/todo`: a workspace root is where a cross-repo `.claude/todos.md` lives (tasks tagged per repo), and the optional session-status hook surfaces the focused task from that same root at session start.

## What NOT to do

- Don't skip any of the three sub-commands if they fail. If `/conventions` couldn't parse the codebase, surface that error — don't pretend success.
- Don't fabricate the mental model section. If the code didn't tell you what the product does, leave it as `<unclear — ask the team>`.
- Don't suggest more than 5 files to read first. Six is too many for "day one".
- Don't add `Co-Authored-By: Claude` to any generated file.
