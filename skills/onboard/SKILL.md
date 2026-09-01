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
# A. Workspace root? (not a repo itself, but 2+ direct children are git repos)
# rev-parse instead of `test -d .git`: worktrees have a .git FILE, not a dir.
git rev-parse --is-inside-work-tree >/dev/null 2>&1 && echo "is a repo" || ls -d */.git 2>/dev/null | wc -l

# B. Team-owned tooling? (the repo commits .claude/ content or a CLAUDE.md)
git ls-files .claude CLAUDE.md 2>/dev/null | head -5
```

**Case A — no `.git` here but 2+ child directories are git repos** → this is a workspace folder, not a codebase. Jump to "Workspace mode" below. Do NOT stop with "not a git repo".

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

The problem it solves, measured on a real workspace: grepping for a repo's **directory name** `tg-oss` finds 6 files. Grepping for the name it actually publishes under, `@teselagen/ui`, finds 1011. Same real dependency, 168x apart. An agent that greps directory names concludes there is no edge. **You can grep for what a repo calls; you cannot grep for what it is called** — so the name is the one thing worth writing to disk.

Write `<repo>/.claude/handles.md` (or `handles.local.md` in a team repo — the existing `.claude/**/*.local.md` exclude already covers it, nothing new to add):

```
repo: tg-oss
aka: ove | open vector editor

serves:
- @teselagen/ove           :: packages/ove/
- @teselagen/ui            :: packages/ui/
- @teselagen/bio-parsers   :: packages/bio-parsers/

scanned: <date>
```

Read `serves` as: *these are the strings another repo would contain if it talked to me, and here is what implements each one.* Two header keys, one block, one date. No nesting, no prose — a file you can see all of is a file whose wrongness is visible.

**Where the handles come from**, cheapest first:

```bash
# published package names (skip private + example/demo packages)
git ls-files '*package.json' | grep -v node_modules
# service names in deployment manifests
git ls-files 'docker-compose*' '*.yaml' '*.yml' | grep -iE 'compose|k8s|deploy'
# the env var peers use to reach this repo, if it is committed anywhere
git grep -hoE '[A-Z][A-Z0-9_]*_(URL|URI|HOST|ENDPOINT)' -- '*.env.example' '*.yaml' '*.yml'
```

**A handle must be at least 4 characters AND contain one of `@ / _ - .`** — verified necessary: the bare handle `j5` matched 139,790 times in one repo (15,383 of them JSON data files), which is not routing, it is noise. Bare short words are not handles; use the qualified form (`blast-ms`, not `blast`). If a repo has no distinctive name, say so and leave `serves:` empty rather than inventing one.

### 2. INDEX.md — the roll-up, with derived routing

Light scan per child repo for the table — name and description, stack hints, branch, last commit date. No deep reading. Everything below "Repos" is **generated output**, not hand-written:

```markdown
# <folder name> — workspace index

*Repo table by `/onboard`. Everything below "Routing" is DERIVED — regenerated <date>.
Do not hand-edit it: fix the repo's .claude/handles.md and re-run the join below.*

## Routing — read this before opening any repo

1. Look up every proper noun in the task under "Names". That maps task vocabulary
   ("the wallet balance", "the ICE import") onto a repo AND a path inside it.
2. Read the "Edges" rows for the repos you hit. One hop. Stop.
3. Open only those repos, starting at the paths "Names" gave you.
4. A name absent from "Names" is not in this workspace. Say so; do not go looking.
5. If the date above is old, re-run the join — it costs seconds, and a stale edge
   is worse than no edge.

## Repos

| Repo | What it is | Stack | Last activity | Onboarding |
|---|---|---|---|---|
| `<dir>/` | <one line> | <stack> | <date> on `<branch>` | [package](<dir>/.claude/onboarding.md) or — |

## Names
<every handle, grouped by the repo that serves it, with its path>

## Edges — derived <date>, counts are matches
| From | To | Matched handle | Hits |
|---|---|---|---|

## Inbound — inverted from Edges. Never authored.
<repo <- callers>

## Unmatched — references pointing outside this workspace
<name (repo, hits) -> what it probably is: uncloned repo, or external vendor>

## Known blind spots — not detectable by this method
<dependencies dispatched through a registry or service discovery leave no static
trace; list the ones you know about so their absence is not read as evidence>
```

**The join** — one batched grep per repo, run from the workspace root:

```bash
HANDLES=$(awk -F' :: ' '/^- /{sub(/^- /,"");gsub(/ +$/,"",$1);print $1}' */.claude/handles*.md \
  | sort -u | grep -E '^.{4,}$' | grep -E '[@/_.-]' | sed 's/[.[\*^$]/\\&/g' | paste -sd'|' -)

for d in */; do
  [ -d "$d/.git" ] || continue
  git -C "$d" grep -hoIE "$HANDLES" \
      -- '*.ts' '*.tsx' '*.js' '*.jsx' '*.py' '*.go' '*.yaml' '*.yml' 'Dockerfile*' 2>/dev/null \
    | sort | uniq -c | sed "s|^|${d%/} |"
done
```

Drop self-matches (a repo hitting its own handles) and anything under 2 hits. What remains is the edge set. **Do not add `*.json` to that glob** — in one real workspace it turned a 8s scan into 34s and buried the signal under data files.

**The second pass, which is where the value shows up.** Find what each repo reaches for that no handle claims:

```bash
git -C "$d" grep -hoE '[A-Z][A-Z0-9_]*_(URL|URI|HOST|ENDPOINT)' \
    -- '*.ts' '*.js' '*.py' '*.go' '*.yaml' '*.yml' 2>/dev/null | sort | uniq -c | sort -rn
```

Anything here that matches no repo's handles is either a repo that is not cloned or an external vendor. Put it under "Unmatched" with which one you think it is. This is the section that earns the feature: on a real workspace it surfaced a live five-endpoint dependency that the team's own hand-written 29 KB service catalog had been missing for four months.

**Be honest about the miss rate.** On that same workspace, three of eleven hand-documented dependencies had 0, 0 and 1 static traces because they are dispatched through a registry. This method would not have found them. That is what "Known blind spots" is for: a place to record that detection failed, so a gap is never mistaken for an absence.

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
